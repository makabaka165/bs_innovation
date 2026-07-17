function [result_table, context] = test_old_vs_new_score_comparison()
%TEST_OLD_VS_NEW_SCORE_COMPARISON Compare stable scores with legacy formulas.

rng(120204, 'twister');
B = 6;
L = 9;
Z = complex(randn(B, L), randn(B, L)) / sqrt(2);
[Q, ~] = qr(complex(randn(B, 2), randn(B, 2)), 0);
Gbase = [Q(:, 1), 0.4 * Q(:, 1) + Q(:, 2)];
g1 = Q(:, 1);
h = Q(:, 2);
legacy_reg = 1e-10;

case_name = ["well_conditioned"; "near_rank_deficient"; ...
    "exact_duplicate"; "scale_1e-8"; "scale_1"; "scale_1e8"];
G_cases = {Gbase, [g1, g1 + 1e-12 * h], [g1, g1], ...
    Gbase * 1e-8, Gbase, Gbase * 1e8};
num_cases = numel(case_name);
new_svd_score = zeros(num_cases, 1);
pinv_score = zeros(num_cases, 1);
old_ridge_score = zeros(num_cases, 1);
old_fast_score = zeros(num_cases, 1);
old_fast_denominator = zeros(num_cases, 1);
new_pinv_relative_error = zeros(num_cases, 1);
old_ridge_pinv_relative_error = zeros(num_cases, 1);
old_fast_pinv_relative_error = zeros(num_cases, 1);
new_effective_rank = zeros(num_cases, 1);
new_status = strings(num_cases, 1);
new_finite_flag = false(num_cases, 1);
old_ridge_finite_flag = false(num_cases, 1);
old_fast_finite_flag = false(num_cases, 1);
pass_flag = false(num_cases, 1);
phase_factor = ones(num_cases, 1);
legacy_reg_column = repmat(legacy_reg, num_cases, 1);

for idx = 1:num_cases
    G = G_cases{idx};
    [new_svd_score(idx), ~, debug] = beamspace_dml_score_svd(Z, G);
    pinv_score(idx) = real(norm((G * pinv(G)) * Z, 'fro') ^ 2);
    old_ridge_score(idx) = old_ridge_score_local(Z, G, legacy_reg);
    [old_fast_score(idx), old_fast_denominator(idx)] = ...
        old_fast_score_local(Z, G, legacy_reg);
    new_pinv_relative_error(idx) = relative_error_local( ...
        new_svd_score(idx), pinv_score(idx));
    old_ridge_pinv_relative_error(idx) = relative_error_local( ...
        old_ridge_score(idx), pinv_score(idx));
    old_fast_pinv_relative_error(idx) = relative_error_local( ...
        old_fast_score(idx), pinv_score(idx));
    new_effective_rank(idx) = debug.effective_rank;
    new_status(idx) = string(debug.status);
    new_finite_flag(idx) = isfinite(new_svd_score(idx));
    old_ridge_finite_flag(idx) = isfinite(old_ridge_score(idx));
    old_fast_finite_flag(idx) = isfinite(old_fast_score(idx));
    structural_pass = idx ~= 3 || ...
        (new_effective_rank(idx) == 1 && new_status(idx) == "RANK_DEFICIENT");
    agreement_pass = idx == 2 || new_pinv_relative_error(idx) < 1e-10;
    pass_flag(idx) = new_finite_flag(idx) && agreement_pass && structural_pass;
end

result_table = table(case_name, legacy_reg_column, new_svd_score, ...
    pinv_score, old_ridge_score, old_fast_score, old_fast_denominator, ...
    new_pinv_relative_error, old_ridge_pinv_relative_error, ...
    old_fast_pinv_relative_error, new_effective_rank, new_status, ...
    new_finite_flag, old_ridge_finite_flag, old_fast_finite_flag, ...
    pass_flag, phase_factor);
if ~all(pass_flag)
    disp(result_table(~pass_flag, :));
end
assert(all(pass_flag), 'test_old_vs_new_score_comparison:Failed', ...
    'The stable score did not match the pinv reference.');

scale_rows = ismember(case_name, ["scale_1e-8", "scale_1", "scale_1e8"]);
context = struct();
context.num_svd_calls = num_cases;
context.max_well_conditioned_pinv_relative_error = ...
    max(new_pinv_relative_error([1, 3:6]));
context.near_rank_pinv_relative_difference = new_pinv_relative_error(2);
context.new_scale_relative_spread = relative_spread_local(new_svd_score(scale_rows));
context.old_ridge_scale_relative_spread = ...
    relative_spread_local(old_ridge_score(scale_rows));
context.old_fast_scale_relative_spread = ...
    relative_spread_local(old_fast_score(scale_rows));
end

function score = old_ridge_score_local(Z, G, reg)
projector = G / (G' * G + reg * eye(size(G, 2))) * G';
score = real(trace(projector * (Z * Z')));
end

function [score, denominator] = old_fast_score_local(Z, G, reg)
g1 = G(:, 1);
g2 = G(:, 2);
Rz = Z * Z';
s11 = real(g1' * g1) + reg;
s22 = real(g2' * g2) + reg;
s12 = g1' * g2;
q11 = real(g1' * Rz * g1);
q22 = real(g2' * Rz * g2);
q12 = g1' * Rz * g2;
q21 = g2' * Rz * g1;
denominator = s11 * s22 - abs(s12) ^ 2;
score = real((q11 * s22 + s11 * q22 - s12 * q21 - ...
    conj(s12) * q12) / denominator);
end

function value = relative_error_local(actual, reference)
value = abs(actual - reference) / max(abs(reference), eps);
end

function value = relative_spread_local(values)
value = (max(values) - min(values)) / max(abs(values));
end
