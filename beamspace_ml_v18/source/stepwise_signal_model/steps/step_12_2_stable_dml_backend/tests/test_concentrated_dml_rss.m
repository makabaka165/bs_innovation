function [result_table, context] = test_concentrated_dml_rss()
%TEST_CONCENTRATED_DML_RSS Validate effective-dimension ML variance scaling.

rng(120203, 'twister');
B = 5;
L = 8;
[Q, ~] = qr(complex(randn(B), randn(B)), 0);
C = Q * diag([4, 1, 0.2, 0, 0]) * Q';
[T, whitening_info] = build_psd_whitener(C);
Zraw = complex(randn(B, L), randn(B, L)) / sqrt(2);
Graw = complex(randn(B, 2), randn(B, 2)) / sqrt(2);
Zw = T * Zraw;
Gw = T * Graw;

case_name = ["rank_deficient_whitening_full_G"; ...
    "rank_deficient_whitening_duplicate_G"];
G_cases = {Gw, [Gw(:, 1), Gw(:, 1)]};
num_cases = numel(case_name);
rC = repmat(size(T, 1), num_cases, 1);
num_snapshots = repmat(L, num_cases, 1);
requested_K = repmat(2, num_cases, 1);
effective_rank = zeros(num_cases, 1);
rss = zeros(num_cases, 1);
sigma2_hat = zeros(num_cases, 1);
expected_sigma2_hat = zeros(num_cases, 1);
sigma2_relative_error = zeros(num_cases, 1);
loglik_concentrated = zeros(num_cases, 1);
status = strings(num_cases, 1);
pass_flag = false(num_cases, 1);
phase_factor = ones(num_cases, 1);

for idx = 1:num_cases
    opts = struct('requested_rank', requested_K(idx));
    [~, rss(idx), sigma2_hat(idx), loglik_concentrated(idx), ...
        effective_rank(idx), debug] = concentrated_dml_rss( ...
        Zw, G_cases{idx}, opts);
    expected_sigma2_hat(idx) = rss(idx) / (rC(idx) * L);
    sigma2_relative_error(idx) = abs(sigma2_hat(idx) - ...
        expected_sigma2_hat(idx)) / max(expected_sigma2_hat(idx), eps);
    status(idx) = string(debug.status);
    if idx == 1
        structural_pass = effective_rank(idx) == 2 && status(idx) == "OK";
    else
        structural_pass = effective_rank(idx) == 1 && ...
            status(idx) == "RANK_DEFICIENT";
    end
    pass_flag(idx) = sigma2_relative_error(idx) < 1e-14 && ...
        isfinite(loglik_concentrated(idx)) && structural_pass && ...
        debug.effective_whitening_dimension == whitening_info.rank;
end

result_table = table(case_name, rC, num_snapshots, requested_K, ...
    effective_rank, rss, sigma2_hat, expected_sigma2_hat, ...
    sigma2_relative_error, loglik_concentrated, status, pass_flag, phase_factor);
assert(all(pass_flag), 'test_concentrated_dml_rss:Failed', ...
    'The concentrated DML ML-variance or rank-status test failed.');

context = struct();
context.num_svd_calls = num_cases;
context.whitening_rank = whitening_info.rank;
context.whitening_output_rows = size(T, 1);
context.max_sigma2_relative_error = max(sigma2_relative_error);
end
