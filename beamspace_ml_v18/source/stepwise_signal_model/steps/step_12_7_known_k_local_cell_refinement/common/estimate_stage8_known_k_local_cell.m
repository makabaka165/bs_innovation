function result = estimate_stage8_known_k_local_cell( ...
    Y_element, model, local_domain, stage5_locked, noise_model, K, opts)
%ESTIMATE_STAGE8_KNOWN_K_LOCAL_CELL Public single-CPI known-K ML interface.

opts = validate_stage8_known_k_local_cell_input(Y_element, model, ...
    local_domain, stage5_locked, noise_model, K, opts);
path_before = path;
path_cleanup = onCleanup(@() path(path_before));
common_dir = fileparts(mfilename('fullpath'));
step_dir = fileparts(common_dir);
steps_dir = fileparts(step_dir);
frozen_step = fullfile(steps_dir, ...
    'step_12_6_k12_bootstrap_resolution');
addpath(frozen_step);
frozen_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>

clock = tic;
audit_available = exist('stage8_k2_tcc_audit_state', 'file') == 2;
audit_previous_stage = '';
if audit_available
    audit_previous_stage = stage8_k2_tcc_audit_state( ...
        'SET_QUERY_STAGE', sprintf('K%d_PUBLIC', K));
end
context_clock = audit_stage_start_local(audit_available, ...
    sprintf('K%d_CONTEXT', K));
context = build_stage8_known_k_local_context(Y_element, model, ...
    local_domain, stage5_locked, noise_model, opts);
audit_stage_stop_local(audit_available, sprintf('K%d_CONTEXT', K), ...
    context_clock);
core_clock = audit_stage_start_local(audit_available, ...
    sprintf('K%d_%s', K, opts.mode));
switch opts.mode
    case 'CORE_LITE'
        outcome = fit_stage8_core_lite(context, K);
    case 'CORE_PLUS'
        outcome = fit_stage8_core_plus(context, K);
    otherwise
        error('estimate_stage8_known_k_local_cell:Mode', ...
            'The normalized mode is unsupported.');
end
audit_stage_stop_local(audit_available, sprintf('K%d_%s', K, opts.mode), ...
    core_clock);
if audit_available
    stage8_k2_tcc_audit_state('SET_QUERY_STAGE', audit_previous_stage);
end

fit = outcome.selected.fit;
result = stage8_core_v2_2_result_template(K);
result.angles_hat_deg = fit.angles_hat_deg;
result.K = K;
result.mode = opts.mode;
result.fit_valid = logical(outcome.selected.fit_valid);
result.fit_status = char(string(outcome.selected.fit_status));
result.selected_source = char(string(outcome.selected_source));
result.selected_start_id = char(string(fit.initialization_id));
result.rss = fit.rss;
result.loglik_concentrated = fit.loglik_concentrated;
result.effective_rank = fit.effective_rank;
[score_calls, svd_calls] = total_cost_local(context.initialization, outcome);
result.score_call_count = score_calls;
result.svd_call_count = svd_calls;
result.runtime_sec = toc(clock);
if opts.return_diagnostics
    result.fixed_grid_candidate = candidate_summary_local(outcome.fixed_grid);
    if isfield(outcome, 'continuous') && ~isempty(fieldnames(outcome.continuous))
        result.continuous_candidate = candidate_summary_local(outcome.continuous);
    end
    result.diagnostics = struct('initialization', context.initialization, ...
        'selection', outcome.selection, ...
        'continuous_upgrade_flag', outcome.continuous_upgrade_flag, ...
        'fallback_flag', outcome.fallback_flag, ...
        'source_commits', struct( ...
        'r1_continuous_refinement', ...
        'd28e6774c1341a93a8c16ef8b6cb66d5d19de56f', ...
        'core_v2_center_difference_and_selection', ...
        'ca4f6ae7ad07f887fe0a820c8bab09d31c7e6d3c', ...
        'frozen_fixed_grid_backend', ...
        'bbe5f031698478ea4e8a57f0c6c9a741f5d6d637'), ...
        'truth_used_in_initialization_flag', false, ...
        'truth_used_in_fit_flag', false, ...
        'tracking_input_used_flag', false, ...
        'cross_cpi_data_used_flag', false);
end
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

function [score_calls, svd_calls] = total_cost_local(initialization, outcome)
score_calls = double(initialization.num_score_eval);
svd_calls = double(initialization.num_svd);
score_calls = score_calls + double(outcome.fixed_grid.fit.num_score_eval);
svd_calls = svd_calls + double(outcome.fixed_grid.fit.num_svd);
if isfield(outcome, 'continuous') && ~isempty(fieldnames(outcome.continuous))
    score_calls = score_calls + double(outcome.continuous.fit.num_score_eval);
    svd_calls = svd_calls + double(outcome.continuous.fit.num_svd);
end
end

function summary = candidate_summary_local(candidate)
fit = candidate.fit;
summary = struct('method_id', char(string(candidate.method_id)), ...
    'fit_valid', logical(candidate.fit_valid), ...
    'fit_status', char(string(candidate.fit_status)), ...
    'angles_hat_deg', fit.angles_hat_deg, ...
    'selected_start_id', char(string(fit.initialization_id)), ...
    'rss', fit.rss, 'loglik_concentrated', fit.loglik_concentrated, ...
    'effective_rank', fit.effective_rank, ...
    'solver_status', char(string(fit.solver_status)), ...
    'score_call_count', double(fit.num_score_eval), ...
    'svd_call_count', double(fit.num_svd), ...
    'runtime_sec', double(fit.runtime), ...
    'monotonicity_violation_count', ...
    double(fit.monotonicity_violation_count), ...
    'solver_contract_hash', char(string(fit.solver_contract_hash)));
end
