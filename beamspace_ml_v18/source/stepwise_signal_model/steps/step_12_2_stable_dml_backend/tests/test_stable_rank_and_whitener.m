function [result_table, context] = test_stable_rank_and_whitener()
%TEST_STABLE_RANK_AND_WHITENER Validate scale-relative rank and PSD whitening.

rng(120201, 'twister');
case_name = strings(7, 1);
object_type = strings(7, 1);
matrix_rows = zeros(7, 1);
matrix_cols = zeros(7, 1);
expected_rank = zeros(7, 1);
effective_rank = zeros(7, 1);
requested_rank = zeros(7, 1);
threshold = zeros(7, 1);
output_rows = zeros(7, 1);
whitening_error = NaN(7, 1);
min_eigenvalue = NaN(7, 1);
status = strings(7, 1);
finite_flag = false(7, 1);
pass_flag = false(7, 1);
phase_factor = ones(7, 1);

rank_scales = [1e-8, 1, 1e8];
for idx = 1:numel(rank_scales)
    sigma = rank_scales(idx) * [1; 1e-8; 0];
    [rank_now, tau_now] = stable_numeric_rank(sigma, [7, 3]);
    case_name(idx) = "stable_rank_scale_" + string(rank_scales(idx));
    object_type(idx) = "numeric_rank";
    matrix_rows(idx) = 7;
    matrix_cols(idx) = 3;
    expected_rank(idx) = 2;
    effective_rank(idx) = rank_now;
    requested_rank(idx) = 3;
    threshold(idx) = tau_now;
    output_rows(idx) = rank_now;
    status(idx) = "RANK_DEFICIENT";
    finite_flag(idx) = isfinite(tau_now);
    pass_flag(idx) = rank_now == expected_rank(idx) && finite_flag(idx);
end

B_sensor = 12;
B_beam = 5;
W = complex(randn(B_sensor, B_beam), randn(B_sensor, B_beam)) / sqrt(2);
W(:, 5) = W(:, 1) + 0.3 * W(:, 2) + 0.2 * W(:, 5);
C_nonorthogonal = W' * W;

W_rank_deficient = W;
W_rank_deficient(:, 5) = W_rank_deficient(:, 1) + ...
    0.3 * W_rank_deficient(:, 2);
C_rank_deficient = W_rank_deficient' * W_rank_deficient;

H = complex(randn(B_sensor), randn(B_sensor)) / sqrt(2 * B_sensor);
R_general_psd = H * H';
C_general_psd = W' * R_general_psd * W;
C_zero = zeros(B_beam);

covariances = {C_nonorthogonal, C_rank_deficient, C_general_psd, C_zero};
names = ["nonorthogonal_W_covariance", "rank_deficient_Cb", ...
    "general_psd_noise", "zero_psd_covariance"];
expected = [5, 4, 5, 0];
expected_status = ["OK", "RANK_DEFICIENT", "OK", "ZERO_RANK"];
whiteners = cell(4, 1);
infos = cell(4, 1);

for local_idx = 1:4
    row = local_idx + 3;
    C = covariances{local_idx};
    [T, info] = build_psd_whitener(C);
    whiteners{local_idx} = T;
    infos{local_idx} = info;
    case_name(row) = names(local_idx);
    object_type(row) = "psd_whitener";
    matrix_rows(row) = size(C, 1);
    matrix_cols(row) = size(C, 2);
    expected_rank(row) = expected(local_idx);
    effective_rank(row) = info.rank;
    requested_rank(row) = size(C, 1);
    threshold(row) = info.threshold;
    output_rows(row) = size(T, 1);
    whitening_error(row) = info.whitening_error;
    min_eigenvalue(row) = min(info.eigenvalues);
    status(row) = string(info.status);
    finite_flag(row) = all(isfinite(T(:))) && isfinite(info.whitening_error);
    pass_flag(row) = info.rank == expected(local_idx) && ...
        size(T, 1) == expected(local_idx) && size(T, 2) == size(C, 1) && ...
        info.whitening_error < 1e-12 && ...
        status(row) == expected_status(local_idx) && finite_flag(row);
end

result_table = table(case_name, object_type, matrix_rows, matrix_cols, ...
    expected_rank, effective_rank, requested_rank, threshold, output_rows, ...
    whitening_error, min_eigenvalue, status, finite_flag, pass_flag, phase_factor);
assert(all(pass_flag), 'test_stable_rank_and_whitener:Failed', ...
    'A stable-rank or effective-subspace whitening case failed.');

context = struct();
context.W = W;
context.R_general_psd = R_general_psd;
context.C_rank_deficient = C_rank_deficient;
context.T_rank_deficient = whiteners{2};
context.rank_deficient_info = infos{2};
end
