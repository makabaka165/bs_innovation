function [matched_estimate_deg, result] = match_target_sets( ...
    estimate_angles_deg, reference_angles_deg, opts)
%MATCH_TARGET_SETS Match target sets for evaluation only.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~(isstruct(opts) && isscalar(opts) && isempty(fieldnames(opts)))
    error('match_target_sets:Options', ...
        'No search-affecting options are accepted by the evaluation matcher.');
end
validate_angles_local(estimate_angles_deg, reference_angles_deg);
K = size(reference_angles_deg, 1);
if K > 8
    error('match_target_sets:TargetCount', ...
        'The exact evaluation matcher is registered only for K<=8.');
end

delta_az = estimate_angles_deg(:, 1) - reference_angles_deg(:, 1).';
delta_el = estimate_angles_deg(:, 2) - reference_angles_deg(:, 2).';
cost_matrix = delta_az .^ 2 + delta_el .^ 2;
permutation_bank = perms(1:K);
total_cost = zeros(size(permutation_bank, 1), 1);
for idx = 1:size(permutation_bank, 1)
    linear = sub2ind([K, K], permutation_bank(idx, :).', (1:K).');
    total_cost(idx) = sum(cost_matrix(linear));
end
[best_cost, best_index] = min(total_cost);
permutation = permutation_bank(best_index, :);
matched_estimate_deg = estimate_angles_deg(permutation, :);
error_deg = matched_estimate_deg - reference_angles_deg;

result = struct();
result.permutation = permutation;
result.total_squared_2d_cost = best_cost;
result.per_target_error_deg = error_deg;
result.azimuth_rmse_deg = sqrt(mean(error_deg(:, 1) .^ 2));
result.elevation_rmse_deg = sqrt(mean(error_deg(:, 2) .^ 2));
result.pair_rmse_deg = sqrt(mean(sum(error_deg .^ 2, 2)));
result.evaluation_only_flag = true;
result.search_influence_flag = false;
result.statistical_calibration_status = 'NOT_CALIBRATED_STAGE5';
result.phase_factor = 1;
end

function validate_angles_local(estimate, reference)
if ~(isnumeric(estimate) && isnumeric(reference) && ...
        ismatrix(estimate) && ismatrix(reference) && ...
        size(estimate, 2) == 2 && isequal(size(estimate), size(reference)) && ...
        ~isempty(estimate) && all(isfinite(estimate(:))) && ...
        all(isfinite(reference(:))))
    error('match_target_sets:Angles', ...
        'Both inputs must be finite K-by-2 angle matrices of equal size.');
end
end
