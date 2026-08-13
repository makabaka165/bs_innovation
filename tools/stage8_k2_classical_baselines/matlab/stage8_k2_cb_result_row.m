function row = stage8_k2_cb_result_row( ...
    spec, trial, result, method_source, raw_tangent_loglik, constants)
%STAGE8_K2_CB_RESULT_ROW Add evaluation-only truth metrics to one fit result.

if nargin < 6 || isempty(constants)
    constants = stage8_k2_cb_constants();
end
row = stage8_k2_cb_row_template();
row.global_trial_index = double(spec.global_trial_index);
row.trial_id = string(spec.trial_id);
row.method_id = string(result.method_id);
row.method_source = string(method_source);
row.observation_domain = string(result.observation_domain);
row.noise_profile_id = string(spec.noise_profile_id);
row.L = double(spec.L);
row.SNR = double(spec.snr_db);
row.snr_db = double(spec.snr_db);
row.profile_id = string(spec.profile_id);
row.source_seed = double(spec.source_seed);
row.noise_seed = double(spec.noise_seed);
row.element_trial_hash = string(trial.element_trial_hash);
row.element_hash_match_flag = logical(trial.element_hash_match_flag);
row.applicable = logical(result.applicable);
row.applicability_status = string(result.applicability_status);
row.fit_valid = logical(result.fit_valid);
row.fit_status = string(result.fit_status);
row.optimizer_status = string(get_local(result, 'optimizer_status', ...
    'NOT_APPLICABLE'));
row.selected_source = string(get_local(result, 'selected_source', ...
    result.method_id));
row.selected_start_id = string(get_local(result, 'selected_start_id', ''));
row.angles_hat_deg = string(mat2str(result.angles_hat_deg, 17));
row.rss = double(get_local(result, 'rss', NaN));
row.loglik = double(get_local(result, 'loglik_concentrated', NaN));
row.effective_rank = double(get_local(result, 'effective_rank', 0));
row.score_call_count = double(get_local(result, 'score_call_count', 0));
row.svd_call_count = double(get_local(result, 'svd_call_count', 0));
row.eig_call_count = double(get_local(result, 'eig_call_count', 0));
row.runtime_sec = double(get_local(result, 'runtime_sec', 0));
row.online_runtime_sec = double(get_local(result, ...
    'online_runtime_sec', row.runtime_sec));
row.precompute_runtime_sec_amortized = double(get_local(result, ...
    'precompute_runtime_sec_amortized', 0));
row.coarse_candidate_count = double(get_local(result, ...
    'coarse_candidate_count', 0));
row.continuous_start_count = double(get_local(result, ...
    'continuous_start_count', 0));
row.sweep_count = double(get_local(result, 'sweep_count', 0));
row.local_peak_count = double(get_local(result, 'local_peak_count', 0));
row.raw_tangent_loglik_reference = double(raw_tangent_loglik);
row.truth_used_in_fit_flag = logical(get_local(result, ...
    'truth_used_in_fit_flag', false));
row.profile_used_in_fit_flag = logical(get_local(result, ...
    'profile_used_in_fit_flag', false));
row.tangent_used_in_start_flag = logical(get_local(result, ...
    'tangent_used_in_start_flag', false));
row.core_used_in_start_flag = logical(get_local(result, ...
    'core_used_in_start_flag', false));
row.full_manifold_used_flag = logical(get_local(result, ...
    'full_manifold_used_flag', false));
if row.fit_valid
    metrics = stage8_k2_cb_metrics(result.angles_hat_deg, ...
        trial.truth_angles_deg, constants);
    names = {'joint_RMSE_deg','azimuth_RMSE_deg', ...
        'elevation_RMSE_deg','center_error_deg','axis_error_deg', ...
        'separation_true_deg','separation_hat_deg', ...
        'separation_error_deg','separation_vector_error_deg'};
    for index = 1:numel(names)
        row.(names{index}) = metrics.(names{index});
    end
end
end

function value = get_local(input, field, default)
if isfield(input, field)
    value = input.(field);
else
    value = default;
end
end
