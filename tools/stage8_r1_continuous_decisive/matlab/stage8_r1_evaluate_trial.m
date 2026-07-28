function [rows, diagnostics] = stage8_r1_evaluate_trial(spec, context)
%STAGE8_R1_EVALUATE_TRIAL Evaluate M0, M1, and M2 on one shared dataset.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_r1_evaluate_trial:Spec', ...
        'spec must be one registry row.');
end
trial_clock = tic;
trial = stage8_r1_generate_trial(spec, context);
full_data = build_stage8_full_data_from_element( ...
    trial.Y_element, trial.model, struct('data_role', ...
    'STAGE8_R1_SHARED_ELEMENT_OBSERVATION'));
domain = context.plan.local_domain;
model = trial.model;

initialization_clock = tic;
[initialization, initialization_debug] = ...
    build_stage8_initialization_context_from_data(full_data, model, ...
    domain, context.stage5_locked, model.noise_factorization, struct());
shared_initialization_runtime = toc(initialization_clock);

[m0, m0_cost] = run_m0_local(full_data, initialization, domain, model);
[m1, m1_cost] = run_m1_local(full_data, initialization, domain, model);
[m2, m2_cost] = run_m2_local(full_data, initialization, domain, model);
methods = {m0, m1, m2};
costs = {m0_cost, m1_cost, m2_cost};
cells = cell(3, 1);
for index = 1:3
    row = base_row_local(spec, trial, methods{index}.method_id);
    row = add_fit_results_local(row, methods{index});
    row = add_known_k_metrics_local(row, methods{index}, ...
        trial.truth_angles_deg, spec.truth_K);
    row.shared_initialization_runtime_sec = shared_initialization_runtime;
    row.initialization_runtime_sec = costs{index}.initialization_runtime_sec;
    row.refinement_runtime_sec = costs{index}.refinement_runtime_sec;
    row.runtime_sec = shared_initialization_runtime + ...
        costs{index}.initialization_runtime_sec + ...
        costs{index}.refinement_runtime_sec;
    row.score_call_count = double(initialization.num_score_eval) + ...
        costs{index}.additional_initialization_score_count + ...
        methods{index}.fit1.num_score_eval + methods{index}.fit2.num_score_eval;
    row.svd_call_count = double(initialization.num_svd) + ...
        costs{index}.additional_initialization_svd_count + ...
        methods{index}.fit1.num_svd + methods{index}.fit2.num_svd;
    cells{index} = row;
end
rows = struct2table(vertcat(cells{:}));
if numel(unique(rows.element_trial_hash)) ~= 1 || ...
        any(rows.truth_used_in_initialization_flag) || ...
        any(rows.truth_used_in_fit_flag) || any(rows.truth_used_in_lrt_flag)
    error('stage8_r1_evaluate_trial:TruthIsolation', ...
        'Shared data or truth-isolation contract failed.');
end
diagnostics = struct('trial_id', char(spec.trial_id), ...
    'global_trial_index', double(spec.global_trial_index), ...
    'element_trial_hash', trial.element_trial_hash, ...
    'method_row_count', height(rows), ...
    'shared_y_element_hash', stage8_stable_hash(trial.Y_element), ...
    'initialization_factory_hash', initialization.factory_invocation_hash, ...
    'initialization_debug_hash', stage8_stable_hash(initialization_debug), ...
    'optimizer_audit', optimizer_audit_local(m1, m2), ...
    'truth_used_in_initialization_flag', false, ...
    'truth_used_in_fit_flag', false, 'truth_used_in_lrt_flag', false, ...
    'runtime_sec', toc(trial_clock));
end

function [method, cost] = run_m0_local(data, initialization, domain, model)
clock = tic;
[fit1, debug1] = fit_local_model_k( ...
    data, 1, domain, model, initialization, struct());
context2 = initialization;
context2.k1_fit = fit1;
[fit2, debug2] = fit_local_model_k( ...
    data, 2, domain, model, context2, struct());
method = method_local('M0_FIXED_GRID_REGISTERED_STAGE8', fit1, fit2, ...
    debug1, debug2);
cost = cost_local(0, 0, 0, toc(clock));
end

function [method, cost] = run_m1_local(data, initialization, domain, model)
initialization_clock = tic;
start1 = context_start_local('M1_K1_CONVENTIONAL_SINGLETON_PEAK', ...
    initialization.conventional_singleton_peak_deg, ...
    initialization.conventional_singleton_status, domain);
initialization_runtime = toc(initialization_clock);
refinement_clock = tic;
[fit1, debug1] = stage8_r1_fit_continuous_method( ...
    data, 1, start1, domain, model, struct());
refinement_runtime = toc(refinement_clock);

initialization_clock = tic;
[direct, direct_debug] = stage8_r1_build_direct_grid_pair_start( ...
    data, domain, model);
[all_k2_starts, nested_debug] = build_k2_initializations( ...
    data, domain, model, initialization, fit1, struct('rank_multiplier', 1));
nested = all_k2_starts(3);
nested = context_start_local('M1_K2_K1_EMBEDDED_FISHER_ANCHOR', ...
    nested.angles_deg, nested.initialization_status, domain);
starts2 = [direct;nested];
initialization_runtime = initialization_runtime + toc(initialization_clock);
refinement_clock = tic;
[fit2, debug2] = stage8_r1_fit_continuous_method( ...
    data, 2, starts2, domain, model, struct());
refinement_runtime = refinement_runtime + toc(refinement_clock);
method = method_local( ...
    'M1_CONVENTIONAL_CONTINUOUS_FULL_SEQUENTIAL_DML', ...
    fit1, fit2, debug1, debug2);
cost = cost_local(direct_debug.num_score_eval + ...
    nested_debug.num_score_eval, direct_debug.num_svd + ...
    nested_debug.num_svd, initialization_runtime, refinement_runtime);
end

function [method, cost] = run_m2_local(data, initialization, domain, model)
initialization_clock = tic;
start1 = context_start_local('M2_K1_GROUPED_Q1_KQ1', ...
    initialization.grouped_q1_kq1_angles_deg, ...
    initialization.grouped_q1_kq1_status, domain);
start2a = context_start_local('M2_K2_GROUPED_Q1_KQ2', ...
    initialization.grouped_q1_kq2_angles_deg, ...
    initialization.grouped_q1_kq2_status, domain);
start2b = context_start_local('M2_K2_GROUPED_Q2_KQ1_PLUS_KQ1', ...
    initialization.grouped_q2_kq1_plus_kq1_angles_deg, ...
    initialization.grouped_q2_kq1_plus_kq1_status, domain);
initialization_runtime = toc(initialization_clock);
refinement_clock = tic;
[fit1, debug1] = stage8_r1_fit_continuous_method( ...
    data, 1, start1, domain, model, struct());
[fit2, debug2] = stage8_r1_fit_continuous_method( ...
    data, 2, [start2a;start2b], domain, model, struct());
refinement_runtime = toc(refinement_clock);
method = method_local( ...
    'M2_GROUPED_CONDITIONAL_CONTINUOUS_FULL_SEQUENTIAL_DML', ...
    fit1, fit2, debug1, debug2);
cost = cost_local(0, 0, initialization_runtime, refinement_runtime);
end

function method = method_local(id, fit1, fit2, debug1, debug2)
[valid1, validity1] = validate_stage8_fit_for_lrt(fit1, 1, struct());
expected = identity_local(fit1);
[valid2, validity2] = validate_stage8_fit_for_lrt(fit2, 2, expected);
lrt = struct('lambda_12', NaN, 'lrt_status', 'NOT_RUN_INVALID_FIT');
if valid1 && valid2
    [lrt, ~] = nested_dml_likelihood_ratio(fit1, fit2, struct());
end
method = struct('method_id', id, 'fit1', fit1, 'fit2', fit2, ...
    'fit1_valid', valid1, 'fit2_valid', valid2, ...
    'fit1_validity', validity1, 'fit2_validity', validity2, ...
    'debug1', debug1, 'debug2', debug2, 'lrt', lrt);
end

function start = context_start_local(id, angles, status, domain)
available = isnumeric(angles) && ismatrix(angles) && ...
    size(angles, 2) == 2 && all(isfinite(angles(:)));
if available
    bounds = domain.domain_bounds_deg;
    available = all(angles(:, 1) >= bounds(1) & angles(:, 1) <= bounds(2) & ...
        angles(:, 2) >= bounds(3) & angles(:, 2) <= bounds(4));
end
start = struct('initialization_id', id, 'angles_deg', angles, ...
    'available_flag', logical(available), ...
    'initialization_status', char(string(status)));
end

function row = base_row_local(spec, trial, method_id)
row = stage8_r1_row_template();
names = {'global_trial_index','truth_K','trial_type', ...
    'support_or_difficulty','noise_profile_id','L','snr_db','noise_seed'};
row.trial_id = string(spec.trial_id);
for index = 1:numel(names), row.(names{index}) = spec.(names{index}); end
row.element_trial_hash = string(trial.element_trial_hash);
row.method_id = string(method_id);
end

function row = add_fit_results_local(row, method)
fit1 = method.fit1;
fit2 = method.fit2;
row.fit1_valid = method.fit1_valid;
row.fit2_valid = method.fit2_valid;
row.fit1_status = string(method.fit1_validity.status);
row.fit2_status = string(method.fit2_validity.status);
row.fit1_selected_start = string(fit1.initialization_id);
row.fit2_selected_start = string(fit2.initialization_id);
row.fit1_start_count = double(fit1.num_start);
row.fit2_start_count = double(fit2.num_start);
if method.fit1_valid
    row.rss1 = fit1.rss;
    row.k1_estimate_az_deg = fit1.angles_hat_deg(1, 1);
    row.k1_estimate_el_deg = fit1.angles_hat_deg(1, 2);
end
if method.fit2_valid
    row.rss2 = fit2.rss;
    row.k2_estimate_target1_az_deg = fit2.angles_hat_deg(1, 1);
    row.k2_estimate_target1_el_deg = fit2.angles_hat_deg(1, 2);
    row.k2_estimate_target2_az_deg = fit2.angles_hat_deg(2, 1);
    row.k2_estimate_target2_el_deg = fit2.angles_hat_deg(2, 2);
end
if method.fit1_valid && method.fit2_valid
    row.rss_gap = row.rss1 - row.rss2;
end
row.lrt_status = string(method.lrt.lrt_status);
if strcmp(method.lrt.lrt_status, 'OK')
    row.lambda_12 = method.lrt.lambda_12;
end
row.continuous_solver_status = solver_status_local(method);
row.monotonicity_violation_count = violation_count_local(fit1) + ...
    violation_count_local(fit2);
end

function row = add_known_k_metrics_local(row, method, truth, truth_K)
if truth_K == 1
    fit = method.fit1;
    valid = method.fit1_valid;
else
    fit = method.fit2;
    valid = method.fit2_valid;
end
if ~valid, return; end
estimate = fit.angles_hat_deg;
initial = selected_initial_angles_local(fit);
if truth_K == 2
    estimate = match_two_targets_local(estimate, truth);
    initial = match_two_targets_local(initial, truth);
end
error_now = estimate - truth;
initial_error = initial - truth;
row.known_K_azimuth_rmse_deg = sqrt(mean(error_now(:, 1) .^ 2));
row.known_K_elevation_rmse_deg = sqrt(mean(error_now(:, 2) .^ 2));
row.known_K_joint_rmse_deg = sqrt(mean(sum(error_now .^ 2, 2)));
row.initial_known_K_joint_rmse_deg = ...
    sqrt(mean(sum(initial_error .^ 2, 2)));
row.refinement_improved_flag = row.known_K_joint_rmse_deg <= ...
    row.initial_known_K_joint_rmse_deg;
if truth_K == 2
    row.known_K_separation_vector_error_deg = ...
        norm((estimate(2, :) - estimate(1, :)) - ...
        (truth(2, :) - truth(1, :)));
end
end

function initial = selected_initial_angles_local(fit)
if isfield(fit, 'selected_initial_angles_deg') && ...
        all(isfinite(fit.selected_initial_angles_deg(:)))
    initial = fit.selected_initial_angles_deg;
    return;
end
initial = NaN(fit.K, 2);
if ~isfield(fit, 'all_start_results'), return; end
ids = string({fit.all_start_results.initialization_id});
index = find(ids == string(fit.initialization_id), 1);
if ~isempty(index), initial = fit.all_start_results(index).initial_angles_deg; end
end

function matched = match_two_targets_local(estimate, truth)
if ~isequal(size(estimate), [2, 2]) || any(~isfinite(estimate(:)))
    matched = estimate;
    return;
end
identity_cost = sum((estimate - truth) .^ 2, 'all');
swap_cost = sum((estimate([2, 1], :) - truth) .^ 2, 'all');
if swap_cost < identity_cost, matched = estimate([2, 1], :); ...
else, matched = estimate; end
end

function status = solver_status_local(method)
if startsWith(method.method_id, 'M0_')
    status = "REGISTERED_STAGE8_FIXED_GRID_BASELINE";
    return;
end
status1 = selected_solver_status_local(method.fit1);
status2 = selected_solver_status_local(method.fit2);
status = "K1:" + status1 + "|K2:" + status2;
end

function status = selected_solver_status_local(fit)
status = "NO_VALID_START";
if ~isfield(fit, 'all_start_results'), return; end
ids = string({fit.all_start_results.initialization_id});
index = find(ids == string(fit.initialization_id), 1);
if ~isempty(index)
    status = string(fit.all_start_results(index).continuous_solver_status);
end
end

function count = violation_count_local(fit)
if isfield(fit, 'monotonicity_violation_count')
    count = double(fit.monotonicity_violation_count);
else
    count = 0;
end
end

function identity = identity_local(fit)
identity = struct('fixed_measurement_hash', fit.fixed_measurement_hash, ...
    'local_domain_hash', fit.local_domain_hash, ...
    'solver_contract_hash', fit.solver_contract_hash, ...
    'observation_hash', fit.observation_hash);
end

function cost = cost_local(score_count, svd_count, init_runtime, refine_runtime)
cost = struct('additional_initialization_score_count', double(score_count), ...
    'additional_initialization_svd_count', double(svd_count), ...
    'initialization_runtime_sec', double(init_runtime), ...
    'refinement_runtime_sec', double(refine_runtime));
end

function audit = optimizer_audit_local(m1, m2)
methods = {m1, m2};
method_ids = ["M1_CONVENTIONAL_CONTINUOUS_FULL_SEQUENTIAL_DML"; ...
    "M2_GROUPED_CONDITIONAL_CONTINUOUS_FULL_SEQUENTIAL_DML"];
cells = cell(0, 1);
row_index = 0;
for method_index = 1:2
    fits = {methods{method_index}.fit1, methods{method_index}.fit2};
    for K = 1:2
        results = fits{K}.all_start_results;
        for start_index = 1:numel(results)
            row_index = row_index + 1;
            cells{row_index, 1} = struct( ... %#ok<AGROW>
                'method_id', method_ids(method_index), ...
                'K', K, 'start_index', start_index, ...
                'initialization_id', string(results(start_index).initialization_id), ...
                'initialization_available_flag', ...
                logical(results(start_index).initialization_available_flag), ...
                'initial_score', double(results(start_index).initial_score), ...
                'final_score', double(results(start_index).final_score), ...
                'continuous_solver_status', ...
                string(results(start_index).continuous_solver_status), ...
                'monotonicity_violation_count', ...
                double(results(start_index).monotonicity_violation_count), ...
                'initial_angles_deg', results(start_index).initial_angles_deg, ...
                'final_angles_deg', results(start_index).angles_hat_deg);
        end
    end
end
if isempty(cells), audit = struct([]); else, audit = vertcat(cells{:}); end
end
