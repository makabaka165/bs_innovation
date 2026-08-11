function [result, diagnostics] = stage8_k2_tp_fit_safe(Y_element, model, context)
%STAGE8_K2_TP_FIT_SAFE Fit one data-only tangent candidate with fallback.

clock = tic;
audit_available = exist('stage8_k2_tcc_audit_state', 'file') == 2;
root_audit_clock = audit_stage_start_local(audit_available, ...
    'ROOT_TANGENT_PROFILE_SAFE');
if ~isempty(root_audit_clock)
    root_audit_cleanup = onCleanup(@() stage8_k2_tcc_audit_state( ...
        'STAGE_STOP', 'ROOT_TANGENT_PROFILE_SAFE', root_audit_clock)); %#ok<NASGU>
end
constants = context.constants;
domain = context.plan.local_domain;
noise_model = model.noise_factorization;
base_opts = struct('mode', 'CORE_LITE', 'return_diagnostics', true);
if isfield(context, 'fixed_registered_manifold_provider')
    base_opts.fixed_registered_manifold_provider = ...
        context.fixed_registered_manifold_provider;
end
if isfield(context, 'fixed_manifold_mode')
    base_opts.fixed_manifold_mode = context.fixed_manifold_mode;
end
k1_clock = audit_stage_start_local(audit_available, 'K1_PUBLIC');
k1 = estimate_stage8_known_k_local_cell(Y_element, model, domain, ...
    context.stage5_locked, noise_model, 1, base_opts);
audit_stage_stop_local(audit_available, 'K1_PUBLIC', k1_clock);
k2_clock = audit_stage_start_local(audit_available, 'K2_PUBLIC');
fixed = estimate_stage8_known_k_local_cell(Y_element, model, domain, ...
    context.stage5_locked, noise_model, 2, base_opts);
audit_stage_stop_local(audit_available, 'K2_PUBLIC', k2_clock);
score_calls = double(k1.score_call_count) + double(fixed.score_call_count);
svd_calls = double(k1.svd_call_count) + double(fixed.svd_call_count);
diagnostics = diagnostic_template_local(k1, fixed);
result = result_template_local();
result.score_call_count = score_calls;
result.svd_call_count = svd_calls;

if ~fixed.fit_valid || ~isfinite(fixed.loglik_concentrated)
    result.fit_status = 'FIXED_GRID_BASELINE_INVALID';
    result.selected_source = 'FIXED_GRID_FALLBACK';
    diagnostics.fallback_reason = 'FIXED_GRID_BASELINE_INVALID';
    result.runtime_sec = toc(clock);
    diagnostics.runtime_sec = result.runtime_sec;
    return;
end
result = copy_selected_local(result, fixed);
result.selected_source = 'FIXED_GRID_FALLBACK';
result.fit_status = 'KNOWN_K_FIT_VALID';
diagnostics.fallback_flag = true;
if ~k1.fit_valid || any(~isfinite(k1.angles_hat_deg(:)))
    diagnostics.fallback_reason = 'K1_CENTER_INVALID';
    result.score_call_count = score_calls;
    result.svd_call_count = svd_calls;
    result.runtime_sec = toc(clock);
    diagnostics.runtime_sec = result.runtime_sec;
    return;
end

tail_clock = audit_stage_start_local(audit_available, 'TAIL_FULL_DATA');
full_data = build_stage8_full_data_from_element(Y_element, model, ...
    struct('data_role', 'SINGLE_CPI_SINGLE_RANGE_DOPPLER_CELL'));
audit_stage_stop_local(audit_available, 'TAIL_FULL_DATA', tail_clock);
center = reshape(k1.angles_hat_deg, 1, 2);
center_clock = audit_stage_start_local(audit_available, ...
    'CENTER_MANIFOLD_DERIVATIVES');
[g, derivatives, manifold_info] = build_full_sequential_local_manifold( ...
    center, model, struct('rank_multiplier', constants.rank_multiplier));
audit_record_center_query_local(audit_available, center, g, ...
    manifold_info, model, constants.rank_multiplier);
svd_calls = svd_calls + manifold_info.num_svd;
g_energy = real(g' * g);
if ~(isfinite(g_energy) && g_energy > 0)
    diagnostics.fallback_reason = 'K1_CENTER_MANIFOLD_INVALID';
    result.svd_call_count = svd_calls;
    audit_stage_stop_local(audit_available, ...
        'CENTER_MANIFOLD_DERIVATIVES', center_clock);
    result.runtime_sec = toc(clock);
    diagnostics.runtime_sec = result.runtime_sec;
    return;
end
Pg_perp = eye(numel(g), 'like', g) - (g * g') / g_energy;
Jg = [derivatives.azimuth, derivatives.elevation];
B = Pg_perp * Jg;
R = Pg_perp * full_data.Zseq_white;
T = real(B' * B);
T = 0.5 * (T + T.');
S_R = (R * R') / size(R, 2);
Ct = real(B' * S_R * B);
Ct = 0.5 * (Ct + Ct.');
audit_stage_stop_local(audit_available, ...
    'CENTER_MANIFOLD_DERIVATIVES', center_clock);
direction_clock = audit_stage_start_local(audit_available, ...
    'PROJECTED_DIRECTION');
direction = stage8_k2_tp_projected_direction(T, Ct);
audit_stage_stop_local(audit_available, 'PROJECTED_DIRECTION', ...
    direction_clock);
diagnostics.metric_rank = direction.metric_rank;
diagnostics.metric_condition = direction.metric_condition;
diagnostics.metric_eigenvalues = direction.metric_eigenvalues;
diagnostics.metric_rank_threshold = direction.metric_rank_threshold;
diagnostics.direction_status = direction.status;
if ~direction.valid
    diagnostics.fallback_reason = direction.status;
    result.svd_call_count = svd_calls;
    result.runtime_sec = toc(clock);
    diagnostics.runtime_sec = result.runtime_sec;
    return;
end
diagnostics.direction_hat = direction.direction_hat(:).';
t4_clock = audit_stage_start_local(audit_available, 'T4_PROFILE');
if isfield(context, 't4_manifold_provider') && ...
        ~isempty(context.t4_manifold_provider)
    profile = stage8_k2_tcc_profile_adapter(full_data.Zseq_white, model, ...
        center, direction.direction_hat, domain, constants, ...
        context.t4_manifold_provider);
elseif isfield(context, 'manifold_provider') && ...
        ~isempty(context.manifold_provider)
    % LEGACY_COMPATIBILITY_ONLY: new formal runners never use this field.
    profile = stage8_k2_tcc_profile_adapter(full_data.Zseq_white, model, ...
        center, direction.direction_hat, domain, constants, ...
        context.manifold_provider);
else
    profile = stage8_k2_tp_profile_scale(full_data.Zseq_white, model, ...
        center, direction.direction_hat, domain, constants);
end
audit_stage_stop_local(audit_available, 'T4_PROFILE', t4_clock);
score_calls = score_calls + profile.score_call_count;
svd_calls = svd_calls + profile.svd_call_count;
diagnostics.profile_status = profile.status;
diagnostics.rho_hat_deg = profile.rho_hat_deg;
diagnostics.rho_max_deg = profile.rho_max_deg;
diagnostics.endpoint_in_domain_flag = profile.endpoint_in_domain_flag;
diagnostics.full_manifold_profile_used_flag = ...
    profile.full_manifold_used_flag;
diagnostics.manifold_provider_mode = profile.manifold_provider_mode;
diagnostics.evaluated_rho_deg = profile.evaluated_rho_deg;
diagnostics.evaluated_loglik = profile.evaluated_loglik;
diagnostics.evaluated_valid = profile.evaluated_valid;
diagnostics.evaluated_status = profile.evaluated_status;
diagnostics.evaluated_column_sources = profile.evaluated_column_sources;
diagnostics.cache_hit_count = profile.cache_hit_count;
diagnostics.cache_miss_count = profile.cache_miss_count;
diagnostics.direct_fallback_count = profile.direct_fallback_count;
diagnostics.identity_rejection_count = profile.identity_rejection_count;
diagnostics.manifold_runtime_sec = profile.manifold_runtime_sec;
diagnostics.raw_tangent_candidate_valid = profile.valid;
diagnostics.raw_tangent_loglik = profile.loglik_concentrated;
diagnostics.raw_tangent_angles_deg = profile.angles_hat_deg;
selector_clock = audit_stage_start_local(audit_available, ...
    'FINAL_SAFE_SELECTOR');
if profile.valid && profile.loglik_concentrated >= ...
        fixed.loglik_concentrated
    result.angles_hat_deg = profile.angles_hat_deg;
    result.fit_valid = true;
    result.fit_status = 'KNOWN_K_FIT_VALID';
    result.selected_source = 'TANGENT_PROFILE_UPGRADE';
    result.selected_start_id = 'FISHER_TANGENT_PROFILE_1D';
    result.rss = profile.rss;
    result.loglik_concentrated = profile.loglik_concentrated;
    result.effective_rank = profile.effective_rank;
    diagnostics.upgrade_flag = true;
    diagnostics.fallback_flag = false;
    diagnostics.fallback_reason = 'NOT_APPLICABLE';
elseif ~profile.valid
    diagnostics.fallback_reason = profile.status;
else
    diagnostics.fallback_reason = 'TANGENT_LOGLIK_BELOW_FIXED_GRID';
end
audit_stage_stop_local(audit_available, 'FINAL_SAFE_SELECTOR', ...
    selector_clock);
audit_record_selector_local(audit_available, fixed, profile, result, model);
result.score_call_count = score_calls;
result.svd_call_count = svd_calls;
result.runtime_sec = toc(clock);
diagnostics.runtime_sec = result.runtime_sec;
diagnostics.selection_truth_used_flag = false;
end

function result = result_template_local()
result = struct('angles_hat_deg', NaN(2, 2), 'K', 2, ...
    'mode', 'TANGENT_PROFILE_SAFE', 'fit_valid', false, ...
    'fit_status', 'NOT_RUN', 'selected_source', 'NOT_RUN', ...
    'selected_start_id', '', 'rss', NaN, ...
    'loglik_concentrated', NaN, 'effective_rank', 0, ...
    'score_call_count', 0, 'svd_call_count', 0, 'runtime_sec', 0, ...
    'single_cpi_flag', true, 'same_range_doppler_cell_flag', true, ...
    'cross_cpi_data_used_flag', false, ...
    'tracking_input_used_flag', false, ...
    'K_estimated_inside_module_flag', false, ...
    'truth_used_in_fit_flag', false);
end

function result = copy_selected_local(result, selected)
fields = {'angles_hat_deg','fit_valid','fit_status','selected_start_id', ...
    'rss','loglik_concentrated','effective_rank'};
for index = 1:numel(fields)
    result.(fields{index}) = selected.(fields{index});
end
end

function diagnostics = diagnostic_template_local(k1, fixed)
diagnostics = struct('K1_center_deg', k1.angles_hat_deg, ...
    'K1_fit_valid', logical(k1.fit_valid), ...
    'fixed_grid_fit_valid', logical(fixed.fit_valid), ...
    'fixed_grid_loglik', double(fixed.loglik_concentrated), ...
    'metric_rank', 0, 'metric_condition', Inf, ...
    'metric_eigenvalues', [NaN; NaN], ...
    'metric_rank_threshold', NaN, 'direction_hat', [NaN, NaN], ...
    'direction_status', 'NOT_RUN', 'profile_status', 'NOT_RUN', ...
    'rho_hat_deg', NaN, 'rho_max_deg', NaN, ...
    'raw_tangent_candidate_valid', false, ...
    'raw_tangent_loglik', NaN, ...
    'raw_tangent_angles_deg', NaN(2, 2), ...
    'upgrade_flag', false, 'fallback_flag', true, ...
    'fallback_reason', 'NOT_RUN', 'endpoint_in_domain_flag', false, ...
    'full_manifold_profile_used_flag', false, ...
    'manifold_provider_mode', 'NOT_RUN', ...
    'evaluated_rho_deg', [], 'evaluated_loglik', [], ...
    'evaluated_valid', false(0, 1), ...
    'evaluated_status', strings(0, 1), ...
    'evaluated_column_sources', strings(0, 2), ...
    'cache_hit_count', 0, 'cache_miss_count', 0, ...
    'direct_fallback_count', 0, 'identity_rejection_count', 0, ...
    'manifold_runtime_sec', 0, ...
    'selection_truth_used_flag', false, 'runtime_sec', 0);
end

function token = audit_stage_start_local(available, stage_id)
token = [];
if available && stage8_k2_tcc_audit_state('STAGE_ENABLED')
    token = stage8_k2_tcc_audit_state('STAGE_START', stage_id);
end
end

function audit_stage_stop_local(available, stage_id, token)
if available && ~isempty(token)
    stage8_k2_tcc_audit_state('STAGE_STOP', stage_id, token);
end
end

function audit_record_center_query_local(available, angles, G, info, model, ...
    rank_multiplier)
if ~(available && stage8_k2_tcc_audit_state('QUERY_ENABLED'))
    return;
end
event = struct('stage_id', 'CENTER_MANIFOLD_DERIVATIVES', ...
    'angles_deg', angles, 'G', G, 'direct_rank', info.rank_Gseq, ...
    'direct_score', -Inf, 'score_evaluated', false, ...
    'derivatives_required', true, 'query_class', ...
    'DERIVATIVES_REQUIRED', 'expect_registered', false, ...
    'rank_multiplier', rank_multiplier);
stage8_k2_tcc_audit_state('RECORD_QUERY', event);
end

function audit_record_selector_local(available, fixed, profile, result, model)
if ~(available && stage8_k2_tcc_audit_state('QUERY_ENABLED'))
    return;
end
event = struct('fixed', fixed, 'profile', profile, ...
    'result', result, 'model', model);
stage8_k2_tcc_audit_state('RECORD_FINAL_SELECTOR', event);
end
