function [result_table, context] = test_svd_dml_matrix()
%TEST_SVD_DML_MATRIX Exercise full-rank, near-rank, scale, and B<K cases.

rng(120202, 'twister');
B = 6;
K = 2;
L = 7;
Z = complex(randn(B, L), randn(B, L)) / sqrt(2);
[Qbase, ~] = qr(complex(randn(B, K), randn(B, K)), 0);
Gbase = [Qbase(:, 1), 0.35 * Qbase(:, 1) + Qbase(:, 2)];
[Qnear, ~] = qr(complex(randn(B, K), randn(B, K)), 0);
g1 = Qnear(:, 1);
h = Qnear(:, 2);

case_name = ["random_full_rank"; "scale_1e-8"; "scale_1"; "scale_1e8"; ...
    "near_delta_1e-2"; "near_delta_1e-6"; "near_delta_1e-10"; ...
    "near_delta_1e-14"; "exact_duplicate"; "B_less_K"];
G_cases = {Gbase, Gbase * 1e-8, Gbase, Gbase * 1e8, ...
    [g1, g1 + 1e-2 * h], [g1, g1 + 1e-6 * h], ...
    [g1, g1 + 1e-10 * h], [g1, g1 + 1e-14 * h], ...
    [g1, g1], complex(randn(2, 3), randn(2, 3)) / sqrt(2)};
Z_cases = repmat({Z}, 10, 1);
Z_cases{10} = complex(randn(2, L), randn(2, L)) / sqrt(2);
manifold_scale = [1; 1e-8; 1; 1e8; ones(6, 1)];
column_delta = [NaN(4, 1); 1e-2; 1e-6; 1e-10; 1e-14; 0; NaN];

num_cases = numel(case_name);
matrix_rows = zeros(num_cases, 1);
requested_K = zeros(num_cases, 1);
num_snapshots = zeros(num_cases, 1);
effective_rank = zeros(num_cases, 1);
rank_threshold = zeros(num_cases, 1);
svd_score = zeros(num_cases, 1);
qr_score = zeros(num_cases, 1);
pinv_score = zeros(num_cases, 1);
svd_pinv_relative_error = zeros(num_cases, 1);
svd_qr_relative_error = zeros(num_cases, 1);
rss = zeros(num_cases, 1);
rss_raw = zeros(num_cases, 1);
rss_clipped_flag = false(num_cases, 1);
status = strings(num_cases, 1);
finite_flag = false(num_cases, 1);
pass_flag = false(num_cases, 1);
phase_factor = ones(num_cases, 1);

for idx = 1:num_cases
    G = G_cases{idx};
    Z_now = Z_cases{idx};
    opts = struct('requested_rank', size(G, 2), ...
        'compute_projector_checks', true);
    [svd_score(idx), rss(idx), svd_debug] = ...
        beamspace_dml_score_svd(Z_now, G, opts);
    [qr_score(idx), ~, qr_debug] = beamspace_dml_score_qr(Z_now, G, opts);
    projector_pinv = G * pinv(G);
    pinv_score(idx) = real(norm(projector_pinv * Z_now, 'fro') ^ 2);
    svd_pinv_relative_error(idx) = abs(svd_score(idx) - pinv_score(idx)) / ...
        max(abs(pinv_score(idx)), eps(class(Z_now)));
    svd_qr_relative_error(idx) = abs(svd_score(idx) - qr_score(idx)) / ...
        max(abs(svd_score(idx)), eps(class(Z_now)));
    matrix_rows(idx) = size(G, 1);
    requested_K(idx) = size(G, 2);
    num_snapshots(idx) = size(Z_now, 2);
    effective_rank(idx) = svd_debug.effective_rank;
    rank_threshold(idx) = svd_debug.rank_threshold;
    rss_raw(idx) = svd_debug.rss_raw;
    rss_clipped_flag(idx) = svd_debug.rss_clipped;
    status(idx) = string(svd_debug.status);
    finite_flag(idx) = all(isfinite([svd_score(idx), qr_score(idx), ...
        pinv_score(idx), rss(idx), svd_debug.rank_threshold])) && ...
        svd_debug.projection_idempotence_error < 1e-12 && ...
        qr_debug.projection_idempotence_error < 1e-12;

    if idx == 9
        structural_pass = effective_rank(idx) == 1 && ...
            status(idx) == "RANK_DEFICIENT";
    elseif idx == 10
        structural_pass = effective_rank(idx) == size(G, 1) && ...
            status(idx) == "RANK_DEFICIENT";
    else
        structural_pass = effective_rank(idx) == 2;
    end
    well_conditioned = idx <= 5;
    agreement_pass = ~well_conditioned || ...
        (svd_pinv_relative_error(idx) < 1e-10 && ...
         svd_qr_relative_error(idx) < 1e-10);
    pass_flag(idx) = finite_flag(idx) && rss(idx) >= 0 && ...
        structural_pass && agreement_pass;
end

result_table = table(case_name, matrix_rows, requested_K, num_snapshots, ...
    manifold_scale, column_delta, effective_rank, rank_threshold, ...
    svd_score, qr_score, pinv_score, svd_pinv_relative_error, ...
    svd_qr_relative_error, rss, rss_raw, rss_clipped_flag, status, ...
    finite_flag, pass_flag, phase_factor);
if ~all(pass_flag)
    disp(result_table(~pass_flag, :));
end
assert(all(pass_flag), 'test_svd_dml_matrix:Failed', ...
    'A stable SVD/QR DML matrix case failed.');

scale_rows = ismember(case_name, ["scale_1e-8", "scale_1", "scale_1e8"]);
scale_scores = svd_score(scale_rows);
context = struct();
context.num_svd_calls = num_cases;
context.num_qr_calls = num_cases;
context.scale_score_relative_spread = ...
    (max(scale_scores) - min(scale_scores)) / max(abs(scale_scores));
context.max_well_conditioned_pinv_error = ...
    max(svd_pinv_relative_error(1:5));
context.max_well_conditioned_qr_error = ...
    max(svd_qr_relative_error(1:5));
context.nonfinite_count = nnz(~finite_flag);
context.rss_clipped_count = nnz(rss_clipped_flag);
end
