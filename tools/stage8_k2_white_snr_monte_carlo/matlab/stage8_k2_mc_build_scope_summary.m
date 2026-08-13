function summary = stage8_k2_mc_build_scope_summary( ...
    method_rows, scope_type, scope_value, constants, allow_p90)
%STAGE8_K2_MC_BUILD_SCOPE_SUMMARY Build method and paired rows for one scope.

if nargin < 5
    allow_p90 = true;
end
targets = unique(method_rows.white_beamspace_snr_target_db);
if numel(targets) ~= 1
    error('stage8_k2_mc_build_scope_summary:Target', ...
        'One scope summary must contain exactly one white-SNR target.');
end
rows = repmat(template_local(), 5, 1);
for method_index = 1:numel(constants.method_ids)
    method_id = constants.method_ids(method_index);
    subset = method_rows(method_rows.method_id == method_id, :);
    valid = subset.fit_valid;
    row = template_local();
    row.row_type = "METHOD";
    row.scope_type = string(scope_type);
    row.scope_value = string(scope_value);
    row.white_beamspace_snr_target_db = double(targets(1));
    row.method_id = method_id;
    row.total_count = height(subset);
    row.valid_count = nnz(valid);
    row.valid_rate = nnz(valid) / max(1, height(subset));
    metrics = {'joint_RMSE_deg','center_error_deg', ...
        'direction_axis_error_deg','rho_error_deg','rho_relative_error', ...
        'separation_vector_error_deg','runtime_sec'};
    names = {'joint_RMSE_deg','center_error_deg','axis_error_deg', ...
        'rho_error_deg','rho_relative_error', ...
        'separation_vector_error_deg','runtime_sec'};
    for metric_index = 1:numel(metrics)
        values = subset.(metrics{metric_index})(valid);
        row.(['median_', names{metric_index}]) = finite_median_local(values);
        if allow_p90
            row.(['p90_', names{metric_index}]) = ...
                stage8_k2_mc_percentile(values, 90);
        end
    end
    row.upgrade_rate = mean(double(subset.upgrade_flag));
    row.fallback_rate = mean(double(subset.fallback_flag));
    row.mean_score_call_count = mean(double(subset.score_call_count));
    row.mean_SVD_call_count = mean(double(subset.SVD_call_count));
    rows(method_index) = row;
end
for reference_index = 1:2
    reference = constants.method_ids(reference_index);
    tangent = method_rows( ...
        method_rows.method_id == "TANGENT_PROFILE_SAFE", :);
    baseline = method_rows(method_rows.method_id == reference, :);
    tangent = sortrows(tangent, 'trial_id');
    baseline = sortrows(baseline, 'trial_id');
    if height(tangent) ~= height(baseline) || ...
            any(tangent.trial_id ~= baseline.trial_id)
        error('stage8_k2_mc_build_scope_summary:Pairing', ...
            'Paired method rows lost trial identity.');
    end
    common = tangent.fit_valid & baseline.fit_valid & ...
        isfinite(tangent.joint_RMSE_deg) & ...
        isfinite(baseline.joint_RMSE_deg);
    delta = tangent.joint_RMSE_deg(common) - ...
        baseline.joint_RMSE_deg(common);
    row = template_local();
    row.row_type = "PAIRWISE";
    row.scope_type = string(scope_type);
    row.scope_value = string(scope_value);
    row.white_beamspace_snr_target_db = double(targets(1));
    row.method_id = "TANGENT_PROFILE_SAFE";
    row.reference_method_id = reference;
    row.comparison_id = "TANGENT_VS_" + reference;
    row.paired_count = nnz(common);
    row.wins = nnz(delta < -constants.paired_tie_tolerance_deg);
    row.ties = nnz(abs(delta) <= constants.paired_tie_tolerance_deg);
    row.losses = nnz(delta > constants.paired_tie_tolerance_deg);
    row.non_tie_win_rate = row.wins / max(1, row.wins + row.losses);
    row.median_paired_delta_deg = finite_median_local(delta);
    if allow_p90
        row.p90_paired_delta_deg = stage8_k2_mc_percentile(delta, 90);
    end
    rows(3 + reference_index) = row;
end
summary = struct2table(rows);
end

function row = template_local()
row = struct('row_type', "", 'scope_type', "", 'scope_value', "", ...
    'white_beamspace_snr_target_db', NaN, 'method_id', "", ...
    'reference_method_id', "", 'comparison_id', "", ...
    'total_count', 0, 'valid_count', 0, 'valid_rate', NaN, ...
    'median_joint_RMSE_deg', NaN, 'p90_joint_RMSE_deg', NaN, ...
    'median_center_error_deg', NaN, 'p90_center_error_deg', NaN, ...
    'median_axis_error_deg', NaN, 'p90_axis_error_deg', NaN, ...
    'median_rho_error_deg', NaN, 'p90_rho_error_deg', NaN, ...
    'median_rho_relative_error', NaN, ...
    'p90_rho_relative_error', NaN, ...
    'median_separation_vector_error_deg', NaN, ...
    'p90_separation_vector_error_deg', NaN, ...
    'upgrade_rate', NaN, 'fallback_rate', NaN, ...
    'mean_score_call_count', NaN, 'mean_SVD_call_count', NaN, ...
    'median_runtime_sec', NaN, 'p90_runtime_sec', NaN, ...
    'paired_count', 0, 'wins', 0, 'ties', 0, 'losses', 0, ...
    'non_tie_win_rate', NaN, 'median_paired_delta_deg', NaN, ...
    'p90_paired_delta_deg', NaN);
end

function value = finite_median_local(values)
values = double(values(isfinite(values)));
if isempty(values)
    value = NaN;
else
    value = median(values);
end
end
