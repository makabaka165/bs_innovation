function outcome = fit_stage8_core_lite(context, K)
%FIT_STAGE8_CORE_LITE Fixed-grid K2 and safe conventional K1 refinement.

fixed_grid = fixed_grid_candidate_local(context, K);
if K == 2
    outcome = struct('fixed_grid', fixed_grid, 'continuous', struct(), ...
        'selected', fixed_grid, 'selected_source', ...
        'FIXED_GRID_CORE_LITE', 'continuous_upgrade_flag', false, ...
        'fallback_flag', false, 'selection', struct( ...
        'selection_truth_used_flag', false, ...
        'selection_rule', 'K2_CORE_LITE_FIXED_GRID_ONLY'));
    return;
end

start = context_start_local('B1_K1_CONVENTIONAL_SINGLETON_PEAK', ...
    context.initialization.conventional_singleton_peak_deg, ...
    context.initialization.conventional_singleton_status, ...
    context.local_domain, 1);
continuous_clock = audit_stage_start_local('K1_CONTINUOUS');
continuous = continuous_k1_candidate_local(context, start);
audit_stage_stop_local('K1_CONTINUOUS', continuous_clock);
selection_clock = audit_stage_start_local('K1_SELECTION');
[selected, selection] = select_stage8_safe_known_k_candidate( ...
    fixed_grid, continuous);
audit_stage_stop_local('K1_SELECTION', selection_clock);
outcome = struct('fixed_grid', fixed_grid, 'continuous', continuous, ...
    'selected', selected, 'selected_source', selection.selected_source, ...
    'continuous_upgrade_flag', selection.continuous_upgrade_flag, ...
    'fallback_flag', selection.fallback_flag, 'selection', selection);
end

function candidate = fixed_grid_candidate_local(context, K)
fixed_options = fixed_options_local(context);
if K == 1
    previous_stage = audit_set_query_stage_local('K1_FIXED_REFINEMENT');
    fit_clock = audit_stage_start_local('K1_FIXED_FIT');
    [fit, ~] = fit_local_model_k(context.full_data, 1, ...
        context.local_domain, context.model, context.initialization, ...
        fixed_options);
    audit_stage_stop_local('K1_FIXED_FIT', fit_clock);
    audit_restore_query_stage_local(previous_stage);
else
    previous_stage = audit_set_query_stage_local('K2_HELPER_K1');
    helper_clock = audit_stage_start_local('K2_HELPER_K1');
    [helper, ~] = fit_local_model_k(context.full_data, 1, ...
        context.local_domain, context.model, context.initialization, ...
        fixed_options);
    audit_stage_stop_local('K2_HELPER_K1', helper_clock);
    audit_restore_query_stage_local(previous_stage);
    init2 = context.initialization;
    init2.k1_fit = helper;
    previous_stage = audit_set_query_stage_local('K2_REGISTERED_REFINEMENT');
    [fit, ~] = fit_local_model_k(context.full_data, 2, ...
        context.local_domain, context.model, init2, fixed_options);
    audit_restore_query_stage_local(previous_stage);
end
[valid, validity] = validate_stage8_fit_for_lrt(fit, K, struct());
fit.selected_initial_angles_deg = selected_initial_local(fit, K);
fit.solver_status = 'REGISTERED_STAGE8_FIXED_GRID_BASELINE';
fit.monotonicity_violation_count = 0;
candidate = struct('method_id', 'B0_FIXED_GRID_KNOWN_K', 'fit', fit, ...
    'fit_valid', logical(valid), 'fit_status', char(string(validity.status)));
end

function options = fixed_options_local(context)
options = struct('fixed_manifold_mode', context.fixed_manifold_mode);
if ~isempty(context.fixed_registered_manifold_provider)
    options.fixed_registered_manifold_provider = ...
        context.fixed_registered_manifold_provider;
end
if isfield(context, 'fixed_registered_center_adapter') && ...
        ~isempty(context.fixed_registered_center_adapter)
    options.fixed_registered_center_adapter = ...
        context.fixed_registered_center_adapter;
end
end

function candidate = continuous_k1_candidate_local(context, start)
[fit, ~] = fit_k1_local(context.full_data, start, ...
    context.local_domain, context.model);
valid = logical(fit.estimate_returned_flag && fit.converged_flag && ...
    fit.effective_rank >= 1 && isfinite(fit.score) && ...
    isfinite(fit.rss) && fit.rss >= 0 && isfinite(fit.sigma2_hat) && ...
    isfinite(fit.loglik_concentrated) && ...
    fit.monotonicity_violation_count == 0);
candidate = struct('method_id', 'B1_DIRECT_CONTINUOUS_KNOWN_K', ...
    'fit', fit, 'fit_valid', valid, 'fit_status', fit.fit_status);
end

function [fit, debug] = fit_k1_local(data, start, domain, model)
clock = tic;
fit = empty_fit_local(data, domain, model);
result = empty_start_local();
result.initialization_id = char(string(start.initialization_id));
result.initial_angles_deg = start.angles_deg;
result.initialization_available_flag = logical(start.available_flag);
result.initialization_status = char(string(start.initialization_status));
if result.initialization_available_flag && ...
        isequal(size(result.initial_angles_deg), [1, 2]) && ...
        all(isfinite(result.initial_angles_deg(:)))
    [estimate, history, solver_debug] = refine_stage8_k1_continuous( ...
        data, result.initial_angles_deg, domain, model, struct());
    solver_status = char(string(estimate.status));
    solver_usable = strcmp(solver_status, ...
        'CONTINUOUS_REFINEMENT_CONVERGED');
    if strcmp(solver_status, 'CONTINUOUS_REFINEMENT_MAX_SWEEPS') && ...
            estimate.monotonicity_violation_count == 0 && ...
            isfinite(estimate.relative_score_change) && ...
            estimate.relative_score_change <= 1e-7 && ...
            isfinite(estimate.max_angle_update_deg) && ...
            estimate.max_angle_update_deg <= 2e-3
        solver_status = 'K1_CONTINUOUS_MAX_SWEEPS_USABLE';
        solver_usable = true;
    end
    result.angles_hat_deg = estimate.angles_hat_deg;
    result.solver_status = solver_status;
    result.initial_score = estimate.initial_score;
    result.final_score = estimate.final_score;
    result.score_call_count = estimate.score_call_count;
    result.svd_call_count = estimate.svd_call_count;
    result.monotonicity_violation_count = estimate.monotonicity_violation_count;
    result.solver_contract_hash = estimate.solver_contract_hash;
    result.history = history;
    result.solver_debug = solver_debug;
    if solver_usable && estimate.estimate_returned_flag && ...
            estimate.monotonicity_violation_count == 0
        [result, valid] = rebuild_fit_local(result, data, model);
        result.valid_for_selection_flag = valid;
    else
        result.fit_status = 'SOLVER_NOT_OPERATIONAL';
    end
end
fit.all_start_results = result;
fit.num_start = 1;
fit.valid_start_count = double(result.valid_for_selection_flag);
fit.num_score_eval = result.score_call_count;
fit.num_svd = result.svd_call_count;
fit.monotonicity_violation_count = result.monotonicity_violation_count;
fit.runtime = toc(clock);
if ~result.valid_for_selection_flag
    audit_record_continuous_local(fit);
    debug = struct('selected_start_index', 0, 'selected_start_id', '', ...
        'valid_start_count', 0, 'selection_rule', ...
        'MAXIMUM_CONCENTRATED_LOG_LIKELIHOOD_AMONG_VALID_STARTS');
    return;
end
fit = copy_result_local(result, fit);
fit.fit_status = 'KNOWN_K_FIT_VALID';
fit.estimate_returned_flag = true;
fit.converged_flag = true;
fit.initialization_id = result.initialization_id;
fit.selected_initial_angles_deg = result.initial_angles_deg;
fit.runtime = toc(clock);
audit_record_continuous_local(fit);
debug = struct('selected_start_index', 1, ...
    'selected_start_id', result.initialization_id, ...
    'valid_start_count', 1, 'selection_tolerance', 0, ...
    'selection_rule', ...
    'MAXIMUM_CONCENTRATED_LOG_LIKELIHOOD_AMONG_VALID_STARTS');
end

function [result, valid] = rebuild_fit_local(result, data, model)
[G, ~, manifold_info] = build_full_sequential_local_manifold( ...
    result.angles_hat_deg, model, struct('rank_multiplier', 1));
[score, rss, sigma2, loglik, rank_now] = concentrated_dml_rss( ...
    data.Zseq_white, G, struct('requested_rank', 1, ...
    'rank_multiplier', 1, 'compute_projector_checks', false));
[S, solve_info] = solve_fitted_source_coefficients( ...
    G, data.Zseq_white, struct('rank_multiplier', 1));
result.score_call_count = result.score_call_count + 1;
result.svd_call_count = result.svd_call_count + ...
    manifold_info.num_svd + 1 + solve_info.num_svd;
result.G_hat = G;
result.S_hat = S;
result.score = score;
result.rss = rss;
result.sigma2_hat = sigma2;
result.loglik_concentrated = loglik;
result.effective_rank = min(rank_now, solve_info.effective_rank);
valid = result.effective_rank >= 1 && isfinite(score) && ...
    isfinite(rss) && rss >= 0 && isfinite(sigma2) && sigma2 >= 0 && ...
    isfinite(loglik) && all(isfinite(S(:)));
if valid, result.fit_status = 'KNOWN_K_FIT_VALID'; ...
else, result.fit_status = 'FIT_NUMERIC_INVALID'; end
end

function fit = empty_fit_local(data, domain, model)
r_C = size(data.Zseq_white, 1);
L = size(data.Zseq_white, 2);
fit = struct('K', 1, 'angles_hat_deg', NaN(1, 2), ...
    'G_hat', complex(NaN(r_C, 1)), 'S_hat', complex(NaN(1, L)), ...
    'score', NaN, 'rss', NaN, 'sigma2_hat', NaN, ...
    'loglik_concentrated', NaN, 'effective_rank', 0, ...
    'fit_status', 'NO_VALID_START', 'solver_status', 'NO_VALID_START', ...
    'estimate_returned_flag', false, 'converged_flag', false, ...
    'initialization_id', '', 'selected_initial_angles_deg', NaN(1, 2), ...
    'all_start_results', struct([]), 'num_start', 0, ...
    'valid_start_count', 0, 'num_score_eval', 0, 'num_svd', 0, ...
    'runtime', 0, 'monotonicity_violation_count', 0, ...
    'fixed_measurement_hash', model.fixed_measurement_hash, ...
    'local_domain_hash', domain.domain_hash, 'solver_contract_hash', '', ...
    'observation_hash', stage8_core_v2_2_stable_hash(data.Zseq_white), ...
    'effective_whitening_dimension', r_C, 'snapshot_count', L, ...
    'n_complex_observations', r_C * L, 'phase_factor', 1);
end

function result = empty_start_local()
result = struct('initialization_id', '', ...
    'initialization_available_flag', false, ...
    'initialization_status', 'INITIALIZATION_NOT_BUILT', ...
    'initial_angles_deg', NaN(1, 2), 'angles_hat_deg', NaN(1, 2), ...
    'score', NaN, 'rss', NaN, 'sigma2_hat', NaN, ...
    'loglik_concentrated', -Inf, 'effective_rank', 0, ...
    'G_hat', complex(NaN(0, 1)), 'S_hat', complex(NaN(1, 0)), ...
    'fit_status', 'INITIALIZATION_FAILED', 'solver_status', 'NOT_RUN', ...
    'initial_score', NaN, 'final_score', NaN, ...
    'valid_for_selection_flag', false, 'score_call_count', 0, ...
    'svd_call_count', 0, 'monotonicity_violation_count', 0, ...
    'solver_contract_hash', '', 'history', table(), ...
    'solver_debug', struct());
end

function output = copy_result_local(result, base)
output = base;
fields = {'angles_hat_deg','G_hat','S_hat','score','rss','sigma2_hat', ...
    'loglik_concentrated','effective_rank','solver_status', ...
    'solver_contract_hash'};
for index = 1:numel(fields)
    output.(fields{index}) = result.(fields{index});
end
end

function start = context_start_local(id, angles, status, domain, K)
available = isnumeric(angles) && isequal(size(angles), [K, 2]) && ...
    all(isfinite(angles(:)));
if available
    bounds = domain.domain_bounds_deg;
    available = all(angles(:, 1) >= bounds(1) & ...
        angles(:, 1) <= bounds(2) & angles(:, 2) >= bounds(3) & ...
        angles(:, 2) <= bounds(4));
end
start = struct('initialization_id', id, 'angles_deg', angles, ...
    'available_flag', logical(available), ...
    'initialization_status', char(string(status)));
end

function initial = selected_initial_local(fit, K)
initial = NaN(K, 2);
if ~isfield(fit, 'all_start_results') || isempty(fit.all_start_results)
    return;
end
ids = string({fit.all_start_results.initialization_id});
index = find(ids == string(fit.initialization_id), 1);
if ~isempty(index)
    initial = fit.all_start_results(index).initial_angles_deg;
end
end

function token = audit_stage_start_local(stage_id)
token = [];
if exist('stage8_k2_tcc_audit_state', 'file') == 2 && ...
        stage8_k2_tcc_audit_state('STAGE_ENABLED')
    token = stage8_k2_tcc_audit_state('STAGE_START', stage_id);
end
end

function audit_stage_stop_local(stage_id, token)
if exist('stage8_k2_tcc_audit_state', 'file') == 2 && ~isempty(token)
    stage8_k2_tcc_audit_state('STAGE_STOP', stage_id, token);
end
end

function previous = audit_set_query_stage_local(stage_id)
previous = '';
if exist('stage8_k2_tcc_audit_state', 'file') == 2
    previous = stage8_k2_tcc_audit_state('SET_QUERY_STAGE', stage_id);
end
end

function audit_restore_query_stage_local(previous)
if exist('stage8_k2_tcc_audit_state', 'file') == 2
    stage8_k2_tcc_audit_state('SET_QUERY_STAGE', previous);
end
end

function audit_record_continuous_local(fit)
if exist('stage8_k2_tcc_audit_state', 'file') ~= 2 || ...
        ~stage8_k2_tcc_audit_state('QUERY_ENABLED')
    return;
end
count = double(fit.num_score_eval);
metrics = struct('manifold_build_count', count, ...
    'requested_column_count', count, 'dml_score_count', count, ...
    'single_count', count, 'off_grid_column_count', count, ...
    'g_only_eligible_build_count', count);
stage8_k2_tcc_audit_state('RECORD_AGGREGATE', 'K1_CONTINUOUS', metrics);
end
