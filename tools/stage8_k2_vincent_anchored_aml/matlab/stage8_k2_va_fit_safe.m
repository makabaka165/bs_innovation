function [result, diagnostics] = stage8_k2_va_fit_safe(Y_element, model, context)
%STAGE8_K2_VA_FIT_SAFE Fit one anchored AML candidate with fixed-grid fallback.

validate_inputs_local(Y_element, model, context);
clock = tic;
constants = context.constants;
domain = context.plan.local_domain;
noise_model = model.noise_factorization;
base_opts = struct('mode', 'CORE_LITE', 'return_diagnostics', true);
k1 = estimate_stage8_known_k_local_cell(Y_element, model, domain, ...
    context.stage5_locked, noise_model, 1, base_opts);
fixed = estimate_stage8_known_k_local_cell(Y_element, model, domain, ...
    context.stage5_locked, noise_model, 2, base_opts);
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
result.full_manifold_used_flag = true;
diagnostics.fallback_flag = true;
if ~k1.fit_valid || any(~isfinite(k1.angles_hat_deg(:)))
    diagnostics.axis_status = 'K1_CENTER_INVALID';
    diagnostics.fallback_reason = 'K1_CENTER_INVALID';
    finalize_local();
    return;
end

full_data = build_stage8_full_data_from_element(Y_element, model, ...
    struct('data_role', 'SINGLE_CPI_SINGLE_RANGE_DOPPLER_CELL'));
center = reshape(k1.angles_hat_deg, 1, 2);
[g, derivatives, manifold_info] = build_full_sequential_local_manifold( ...
    center, model, struct('rank_multiplier', constants.rank_multiplier));
svd_calls = svd_calls + manifold_info.num_svd;
g_energy = real(g' * g);
if ~(isfinite(g_energy) && g_energy > 0)
    diagnostics.axis_status = 'K1_CENTER_MANIFOLD_INVALID';
    diagnostics.fallback_reason = 'K1_CENTER_MANIFOLD_INVALID';
    finalize_local();
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
direction = stage8_k2_tp_projected_direction(T, Ct);
diagnostics.axis_status = direction.status;
diagnostics.metric_rank = direction.metric_rank;
diagnostics.metric_condition = direction.metric_condition;
diagnostics.metric_eigenvalues = direction.metric_eigenvalues;
diagnostics.metric_rank_threshold = direction.metric_rank_threshold;
if ~direction.valid
    diagnostics.fallback_reason = direction.status;
    finalize_local();
    return;
end
diagnostics.tangent_axis_hat = direction.direction_hat(:).';
profile = stage8_k2_va_anchor_profile(full_data.Zseq_white, model, ...
    center, direction.direction_hat, domain, constants);
score_calls = score_calls + profile.score_call_count;
svd_calls = svd_calls + profile.svd_call_count;
diagnostics = copy_profile_diagnostics_local(diagnostics, profile);
if profile.valid
    diagnostics.raw_candidate_valid = true;
    diagnostics.raw_candidate_angles = profile.angles_hat_deg;
    diagnostics.raw_candidate_loglik = profile.loglik_concentrated;
    diagnostics.raw_candidate_RSS = profile.rss;
end
if profile.valid && profile.loglik_concentrated >= fixed.loglik_concentrated
    result.angles_hat_deg = profile.angles_hat_deg;
    result.fit_valid = true;
    result.fit_status = 'KNOWN_K_FIT_VALID';
    result.selected_source = 'VINCENT_ANCHORED_AML_UPGRADE';
    result.selected_start_id = 'VINCENT_ANCHORED_PROJECTOR_AML_1D';
    result.rss = profile.rss;
    result.loglik_concentrated = profile.loglik_concentrated;
    result.effective_rank = profile.effective_rank;
    result.full_manifold_used_flag = true;
    diagnostics.upgrade_flag = true;
    diagnostics.fallback_flag = false;
    diagnostics.fallback_reason = 'NOT_APPLICABLE';
elseif ~profile.valid
    diagnostics.fallback_reason = profile.status;
else
    diagnostics.fallback_reason = 'ANCHOR_LOGLIK_BELOW_FIXED_GRID';
end
finalize_local();

    function finalize_local()
        result.score_call_count = score_calls;
        result.svd_call_count = svd_calls;
        result.runtime_sec = toc(clock);
        diagnostics.runtime_sec = result.runtime_sec;
        diagnostics.selection_truth_used_flag = false;
    end
end

function result = result_template_local()
result = struct('method_id', 'VINCENT_ANCHORED_PROJECTOR_AML_SAFE', ...
    'angles_hat_deg', NaN(2, 2), 'K', 2, ...
    'mode', 'VINCENT_ANCHORED_PROJECTOR_AML_SAFE', 'fit_valid', false, ...
    'fit_status', 'NOT_RUN', 'selected_source', 'NOT_RUN', ...
    'selected_start_id', '', 'rss', NaN, ...
    'loglik_concentrated', NaN, 'effective_rank', 0, ...
    'score_call_count', 0, 'svd_call_count', 0, 'runtime_sec', 0, ...
    'full_manifold_used_flag', false, 'single_cpi_flag', true, ...
    'same_range_doppler_cell_flag', true, ...
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
    'metric_rank_threshold', NaN, 'tangent_axis_hat', [NaN, NaN], ...
    'axis_status', 'NOT_RUN', 'line_t_min_deg', NaN, ...
    'line_t_max_deg', NaN, 'raw_anchor_valid_count', 0, ...
    'anchor_scan_node_count', 0, 'selected_t_deg', NaN, ...
    'selected_rho_deg', NaN, 'selected_alpha_deg', NaN, ...
    'q0', NaN, 'q1', NaN, 'q2', NaN, ...
    'curvature_valid_flag', false, 'B0_rank', 0, 'B0_condition', Inf, ...
    'projector_expansion_status', 'NOT_RUN', ...
    'conditional_status', 'NOT_RUN', 'conditional_invalid_count', 0, ...
    'q2_nonconcave_count', 0, 'rho_out_of_contract_count', 0, ...
    'raw_candidate_valid', false, 'raw_candidate_angles', NaN(2, 2), ...
    'raw_candidate_loglik', NaN, 'raw_candidate_RSS', NaN, ...
    'upgrade_flag', false, 'fallback_flag', false, ...
    'fallback_reason', 'NOT_RUN', ...
    'full_manifold_profile_used_flag', false, ...
    'selection_truth_used_flag', false, 'runtime_sec', 0);
end

function diagnostics = copy_profile_diagnostics_local(diagnostics, profile)
diagnostics.line_t_min_deg = profile.line_t_min_deg;
diagnostics.line_t_max_deg = profile.line_t_max_deg;
diagnostics.raw_anchor_valid_count = profile.raw_anchor_valid_count;
diagnostics.anchor_scan_node_count = profile.anchor_scan_node_count;
diagnostics.selected_t_deg = profile.selected_t_deg;
diagnostics.selected_rho_deg = profile.selected_rho_deg;
diagnostics.selected_alpha_deg = profile.selected_alpha_deg;
diagnostics.q0 = profile.q0;
diagnostics.q1 = profile.q1;
diagnostics.q2 = profile.q2;
diagnostics.curvature_valid_flag = profile.curvature_valid_flag;
diagnostics.B0_rank = profile.B0_rank;
diagnostics.B0_condition = profile.B0_condition;
diagnostics.projector_expansion_status = profile.projector_expansion_status;
diagnostics.conditional_status = profile.conditional_status;
diagnostics.conditional_invalid_count = profile.conditional_invalid_count;
diagnostics.q2_nonconcave_count = profile.q2_nonconcave_count;
diagnostics.rho_out_of_contract_count = profile.rho_out_of_contract_count;
diagnostics.full_manifold_profile_used_flag = ...
    profile.full_manifold_used_flag;
end

function validate_inputs_local(Y_element, model, context)
if ~(isnumeric(Y_element) && ismatrix(Y_element) && ~isempty(Y_element) && ...
        all(isfinite(Y_element(:))) && isstruct(model) && ...
        isstruct(context) && isfield(context, 'constants') && ...
        isfield(context, 'plan') && isfield(context, 'stage5_locked'))
    error('stage8_k2_va_fit_safe:Input', ...
        'The isolated known-K fitting contract is invalid.');
end
end
