function audit = test_summary_fixed_grid_rmse_contract()
%TEST_SUMMARY_FIXED_GRID_RMSE_CONTRACT Verify numeric RMSE summarization.

k1_truth = [8.10, 10.10];
k1_fixed = [8.00, 10.20];
k1_rmse = rmse_local(k1_fixed, k1_truth);
assert(isfinite(k1_rmse));
assert(abs(k1_rmse - sqrt(0.02)) <= 16 * eps(1));

k2_truth = [7.90, 9.90; 8.10, 10.10];
k2_fixed_swapped = [8.11, 10.08; 7.88, 9.91];
k2_rmse = rmse_local(k2_fixed_swapped, k2_truth);
matched = k2_fixed_swapped([2, 1], :);
expected = sqrt(mean(sum((matched - k2_truth) .^ 2, 2)));
assert(isfinite(k2_rmse) && abs(k2_rmse - expected) <= 16 * eps(1));

step_dir = fileparts(fileparts(mfilename('fullpath')));
source = fileread(fullfile(step_dir, 'validation', ...
    'summarize_stage8_core_v2_2_final_validation.m'));
assert(contains(source, 'fixed_grid_joint_rmse_deg'));
assert(contains(source, ...
    'match_targets_local(fixed.angles_hat_deg, truth)'));
assert(contains(source, 'rows.fixed_grid_joint_rmse_deg'));
assert(isempty(regexp(source, '\<sscanf\s*\(', 'once')));
assert(isempty(regexp(source, '\<eval\s*\(', 'once')));
assert(isempty(regexp(source, '\<profile_truth_local\>', 'once')));
audit = struct('pass', true, ...
    'status', 'SUMMARY_FIXED_GRID_RMSE_CONTRACT_PASS', ...
    'k1_rmse_deg', k1_rmse, 'k2_permuted_rmse_deg', k2_rmse, ...
    'numeric_field_required', true, 'string_reparse_used', false);
end

function value = rmse_local(estimate, truth)
if size(estimate, 1) == 2
    identity_cost = sum((estimate - truth) .^ 2, 'all');
    swap_cost = sum((estimate([2, 1], :) - truth) .^ 2, 'all');
    if swap_cost < identity_cost
        estimate = estimate([2, 1], :);
    end
end
value = sqrt(mean(sum((estimate - truth) .^ 2, 2)));
end
