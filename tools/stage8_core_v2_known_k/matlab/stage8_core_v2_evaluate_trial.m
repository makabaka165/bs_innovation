function [rows, diagnostics] = stage8_core_v2_evaluate_trial(spec, context)
%STAGE8_CORE_V2_EVALUATE_TRIAL Evaluate B0/B1/B2 at the known truth K.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_core_v2_evaluate_trial:Spec', ...
        'spec must be one registry row.');
end
trial_clock = tic;
trial = stage8_r1_generate_trial(spec, context);
validate_historical_hash_local(spec, trial.element_trial_hash, ...
    context.repo_dir);
full_data = build_stage8_full_data_from_element( ...
    trial.Y_element, trial.model, struct('data_role', ...
    'STAGE8_CORE_V2_SHARED_ELEMENT_OBSERVATION'));
domain = context.plan.local_domain;
model = trial.model;
initialization_clock = tic;
[initialization, initialization_debug] = ...
    build_stage8_initialization_context_from_data(full_data, model, ...
    domain, context.stage5_locked, model.noise_factorization, struct());
shared_runtime = toc(initialization_clock);

[b0, b0_cost] = run_b0_local(full_data, initialization, domain, model, ...
    spec.truth_K);
[b1, b1_cost] = run_b1_local(full_data, initialization, domain, model, ...
    spec.truth_K);
[b2, b2_cost] = run_b2_local(full_data, initialization, domain, model, ...
    spec.truth_K);
methods = {b0, b1, b2};
costs = {b0_cost, b1_cost, b2_cost};
cells = cell(3, 1);
for index = 1:3
    row = build_row_local(spec, trial, methods{index}, ...
        trial.truth_angles_deg);
    row.score_calls = double(initialization.num_score_eval) + ...
        costs{index}.score_calls + methods{index}.fit.num_score_eval;
    row.SVD_calls = double(initialization.num_svd) + ...
        costs{index}.svd_calls + methods{index}.fit.num_svd;
    row.runtime_sec = shared_runtime + costs{index}.runtime_sec + ...
        methods{index}.fit.runtime;
    cells{index} = row;
end
rows = struct2table(vertcat(cells{:}));
if height(rows) ~= 3 || numel(unique(rows.element_trial_hash)) ~= 1 || ...
        any(rows.truth_used_in_initialization_flag) || ...
        any(rows.truth_used_in_fit_flag) || ...
        ~all(rows.shared_element_data_flag)
    error('stage8_core_v2_evaluate_trial:Isolation', ...
        'Shared-data or truth-isolation contract failed.');
end
diagnostics = struct('trial_id', char(spec.trial_id), ...
    'global_trial_index', double(spec.global_trial_index), ...
    'truth_K', double(spec.truth_K), ...
    'element_trial_hash', trial.element_trial_hash, ...
    'truth_angles_deg', trial.truth_angles_deg, ...
    'shared_y_element_hash', stage8_stable_hash(trial.Y_element), ...
    'initialization_factory_hash', initialization.factory_invocation_hash, ...
    'initialization_debug_hash', stage8_stable_hash(initialization_debug), ...
    'method_row_count', height(rows), 'runtime_sec', toc(trial_clock));
end

function [method, cost] = run_b0_local(data, initialization, domain, model, K)
clock = tic;
if K == 1
    [fit, ~] = fit_local_model_k(data, 1, domain, model, ...
        initialization, struct());
    helper_score = 0; helper_svd = 0;
else
    [helper, ~] = fit_local_model_k(data, 1, domain, model, ...
        initialization, struct());
    context2 = initialization;
    context2.k1_fit = helper;
    [fit, ~] = fit_local_model_k(data, 2, domain, model, context2, struct());
    helper_score = helper.num_score_eval;
    helper_svd = helper.num_svd;
end
[valid, validity] = validate_stage8_fit_for_lrt(fit, K, struct());
fit.selected_initial_angles_deg = selected_initial_local(fit, K);
fit.solver_status = 'REGISTERED_STAGE8_FIXED_GRID_BASELINE';
fit.monotonicity_violation_count = 0;
method = struct('method_id', 'B0_FIXED_GRID_KNOWN_K', 'fit', fit, ...
    'fit_valid', valid, 'fit_status', validity.status);
cost = cost_local(helper_score, helper_svd, toc(clock) - fit.runtime);
end

function [method, cost] = run_b1_local(data, initialization, domain, model, K)
clock = tic;
if K == 1
    start = context_start_local('B1_K1_CONVENTIONAL_SINGLETON_PEAK', ...
        initialization.conventional_singleton_peak_deg, ...
        initialization.conventional_singleton_status, domain, 1);
    [fit, ~] = stage8_core_v2_fit_known_k( ...
        data, 1, start, domain, model, struct());
    extra_score = 0; extra_svd = 0;
else
    helper_start = context_start_local( ...
        'B1_K2_K1_HELPER_CONVENTIONAL_SINGLETON_PEAK', ...
        initialization.conventional_singleton_peak_deg, ...
        initialization.conventional_singleton_status, domain, 1);
    [helper, ~] = stage8_core_v2_fit_known_k( ...
        data, 1, helper_start, domain, model, struct());
    [direct, direct_debug] = stage8_r1_build_direct_grid_pair_start( ...
        data, domain, model);
    direct.initialization_id = 'B1_K2_DIRECT_GRID_PAIR_BEST';
    [registered, nested_debug] = build_k2_initializations( ...
        data, domain, model, initialization, helper, ...
        struct('rank_multiplier', 1));
    nested = registered(3);
    nested.initialization_id = 'B1_K2_K1_EMBEDDED_FISHER_ANCHOR';
    direct = simple_start_local(direct);
    nested = simple_start_local(nested);
    [fit, ~] = stage8_core_v2_fit_known_k( ...
        data, 2, [direct;nested], domain, model, struct());
    extra_score = helper.num_score_eval + direct_debug.num_score_eval + ...
        nested_debug.num_score_eval;
    extra_svd = helper.num_svd + direct_debug.num_svd + ...
        nested_debug.num_svd;
end
method = method_local('B1_DIRECT_CONTINUOUS_KNOWN_K', fit);
cost = cost_local(extra_score, extra_svd, toc(clock) - fit.runtime);
end

function output = simple_start_local(input)
output = struct('initialization_id', char(string(input.initialization_id)), ...
    'angles_deg', input.angles_deg, ...
    'available_flag', logical(input.available_flag), ...
    'initialization_status', char(string(input.initialization_status)));
end

function [method, cost] = run_b2_local(data, initialization, domain, model, K)
clock = tic;
if K == 1
    starts = context_start_local('B2_K1_GROUPED_Q1_KQ1', ...
        initialization.grouped_q1_kq1_angles_deg, ...
        initialization.grouped_q1_kq1_status, domain, 1);
else
    start1 = context_start_local('B2_K2_GROUPED_Q1_KQ2', ...
        initialization.grouped_q1_kq2_angles_deg, ...
        initialization.grouped_q1_kq2_status, domain, 2);
    start2 = context_start_local( ...
        'B2_K2_GROUPED_Q2_KQ1_PLUS_KQ1', ...
        initialization.grouped_q2_kq1_plus_kq1_angles_deg, ...
        initialization.grouped_q2_kq1_plus_kq1_status, domain, 2);
    starts = [start1;start2];
end
[fit, ~] = stage8_core_v2_fit_known_k( ...
    data, K, starts, domain, model, struct());
method = method_local('B2_GROUPED_CONTINUOUS_KNOWN_K', fit);
cost = cost_local(0, 0, toc(clock) - fit.runtime);
end

function method = method_local(id, fit)
method = struct('method_id', id, 'fit', fit, ...
    'fit_valid', logical(fit.estimate_returned_flag && ...
    fit.converged_flag && fit.effective_rank >= fit.K && ...
    isfinite(fit.score) && isfinite(fit.rss) && fit.rss >= 0 && ...
    isfinite(fit.sigma2_hat) && isfinite(fit.loglik_concentrated) && ...
    fit.monotonicity_violation_count == 0), ...
    'fit_status', fit.fit_status);
end

function row = build_row_local(spec, trial, method, truth)
fit = method.fit;
row = stage8_core_v2_row_template();
row.trial_id = string(spec.trial_id);
row.global_trial_index = double(spec.global_trial_index);
row.truth_K = double(spec.truth_K);
row.support_or_difficulty = string(spec.support_or_difficulty);
row.noise = string(spec.noise_profile_id);
row.L = double(spec.L);
row.SNR = double(spec.snr_db);
row.noise_seed = double(spec.noise_seed);
row.element_trial_hash = string(trial.element_trial_hash);
row.method_id = string(method.method_id);
row.fit_valid = logical(method.fit_valid);
row.fit_status = string(method.fit_status);
row.solver_status = string(fit.solver_status);
row.selected_start_id = string(fit.initialization_id);
row.start_count = double(fit.num_start);
row.valid_start_count = double(fit.valid_start_count);
row.initial_angles = string(mat2str(fit.selected_initial_angles_deg, 17));
row.final_angles = string(mat2str(fit.angles_hat_deg, 17));
row.RSS = double(fit.rss);
row.loglik = double(fit.loglik_concentrated);
row.effective_rank = double(fit.effective_rank);
row.monotonicity_violation_count = ...
    double(fit.monotonicity_violation_count);
row.solver_contract_hash = string(fit.solver_contract_hash);
if ~method.fit_valid, return; end
estimate = fit.angles_hat_deg;
initial = fit.selected_initial_angles_deg;
if spec.truth_K == 2
    estimate = match_targets_local(estimate, truth);
    initial = match_targets_local(initial, truth);
end
row.estimate_target1_az_deg = estimate(1, 1);
row.estimate_target1_el_deg = estimate(1, 2);
if spec.truth_K == 2
    row.estimate_target2_az_deg = estimate(2, 1);
    row.estimate_target2_el_deg = estimate(2, 2);
end
error_now = estimate - truth;
initial_error = initial - truth;
row.known_K_azimuth_RMSE = sqrt(mean(error_now(:, 1) .^ 2));
row.known_K_elevation_RMSE = sqrt(mean(error_now(:, 2) .^ 2));
row.known_K_joint_RMSE = sqrt(mean(sum(error_now .^ 2, 2)));
row.initial_known_K_joint_RMSE = ...
    sqrt(mean(sum(initial_error .^ 2, 2)));
row.refinement_improved_flag = row.known_K_joint_RMSE <= ...
    row.initial_known_K_joint_RMSE;
if spec.truth_K == 2
    row.known_K_separation_vector_error = norm( ...
        (estimate(2, :) - estimate(1, :)) - ...
        (truth(2, :) - truth(1, :)));
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
if ~isfield(fit, 'all_start_results'), return; end
ids = string({fit.all_start_results.initialization_id});
index = find(ids == string(fit.initialization_id), 1);
if ~isempty(index)
    initial = fit.all_start_results(index).initial_angles_deg;
end
end

function matched = match_targets_local(estimate, truth)
identity_cost = sum((estimate - truth) .^ 2, 'all');
swap_cost = sum((estimate([2, 1], :) - truth) .^ 2, 'all');
if swap_cost < identity_cost, matched = estimate([2, 1], :); ...
else, matched = estimate; end
end

function cost = cost_local(score_calls, svd_calls, runtime_sec)
cost = struct('score_calls', double(score_calls), ...
    'svd_calls', double(svd_calls), ...
    'runtime_sec', max(0, double(runtime_sec)));
end

function validate_historical_hash_local(spec, actual_hash, repo_dir)
path_now = fullfile(repo_dir, 'innovation-mining', ...
    '24_stage8_r1_continuous_refinement_decisive_trials.csv');
historical = readtable(path_now, 'TextType', 'string');
subset = historical(historical.trial_id == string(spec.trial_id), :);
valid = height(subset) == 3 && ...
    numel(unique(subset.element_trial_hash)) == 1 && ...
    unique(subset.element_trial_hash) == string(actual_hash) && ...
    all(subset.noise_seed == spec.noise_seed) && ...
    all(subset.truth_K == spec.truth_K);
if ~valid
    error('stage8_core_v2_evaluate_trial:HistoricalIdentity', ...
        'STAGE8_CORE_V2_EXPERIMENT_INVALID: element trial changed.');
end
end
