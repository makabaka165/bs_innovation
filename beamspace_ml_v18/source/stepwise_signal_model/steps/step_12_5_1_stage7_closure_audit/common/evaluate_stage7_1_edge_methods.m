function [method_rows, runtime_rows] = evaluate_stage7_1_edge_methods( ...
    common_trial, method_models, finite, plan_group, opts)
%EVALUATE_STAGE7_1_EDGE_METHODS Apply exactly three physical subsets.

if nargin < 5 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
expected_method = ["FIXED_RECT_3X5";"GREEDY_ETA_080";"FULL_PARENT_5X5"];
expected_subset = ["RECT_E14_A31";"RECT_E28_A31";"RECT_E31_A31"];
plan_group = validate_plan_group_local(plan_group, ...
    expected_method, expected_subset);
method_models = order_models_local(method_models, ...
    expected_method, expected_subset);
validate_trial_local(common_trial);
if isfield(finite, 'finite'), finite = finite.finite; end
if ~(isstruct(finite) && isscalar(finite) && isfield(finite, 'context') && ...
        isfield(finite.context, 'plan') && ...
        isfield(finite.context.plan, 'pool') && ...
        isfield(finite.context.plan, 'success'))
    error('evaluate_stage7_1_edge_methods:Context', ...
        'A frozen finite-sample context is required.');
end
Z0 = finite.context.plan.pool.W0' * common_trial.Y_element;
rows = cell(3, 1);
runtime = cell(3, 1);
normalized_scores = NaN(3, 1);
for index = 1:3
    item = method_models(index);
    Z = item.model.T_I * Z0(item.channels, :);
    estimate = opts.solver_function(Z, item.G_bank, finite, ...
        plan_group.K(index));
    evaluation = evaluate_estimate_local(estimate, ...
        common_trial.target_angles_deg, finite.context.plan.success, ...
        common_trial.edge_diagnostic_domain_pass, Z);
    normalized_scores(index) = evaluation.normalized_score;
    row = struct();
    row.paired_group_id = string(common_trial.paired_group_id);
    row.paired_group_index = common_trial.paired_group_index;
    row.scenario_id = plan_group.scenario_id(index);
    row.element_snr_db = plan_group.element_snr_db(index);
    row.trial_index = common_trial.trial_index;
    row.trial_seed = common_trial.trial_seed;
    row.method_id = expected_method(index);
    row.subset_id = expected_subset(index);
    row.target1_az_deg = common_trial.target_angles_deg(1, 1);
    row.target1_el_deg = common_trial.target_angles_deg(1, 2);
    row.target2_az_deg = common_trial.target_angles_deg(2, 1);
    row.target2_el_deg = common_trial.target_angles_deg(2, 2);
    row.realized_element_snr_db = common_trial.realized_element_snr_db;
    row.historical_registered_domain_pass = ...
        common_trial.historical_registered_domain_pass;
    row.tolerant_registered_domain_pass = ...
        common_trial.tolerant_registered_domain_pass;
    row.boundary_numeric_disagreement_flag = ...
        common_trial.boundary_numeric_disagreement_flag;
    row.domain_tolerance_deg = common_trial.domain_tolerance_deg;
    row.edge_diagnostic_domain_pass = ...
        common_trial.edge_diagnostic_domain_pass;
    row.oracle_k_success = evaluation.success;
    row.azimuth_error_deg = evaluation.azimuth_error_deg;
    row.elevation_error_deg = evaluation.elevation_error_deg;
    row.pair_error_deg = evaluation.pair_error_deg;
    row.unconditional_penalized_error = evaluation.penalized_error;
    row.wrong_local_peak = evaluation.wrong_peak;
    row.converged = estimate.converged_flag;
    row.normalized_score = evaluation.normalized_score;
    row.normalized_score_gap_to_full_parent = NaN;
    row.score_calls = estimate.score_calls;
    row.SVD_calls = estimate.svd_calls;
    row.iterations = estimate.iterations;
    row.multi_start_count = estimate.multi_start_count;
    row.status = string(estimate.status);
    row.diagnostic_status = ...
        "POST_HOC_EDGE_SENSITIVITY_NOT_USED_FOR_SELECTION";
    row.selection_effect_status = ...
        "NOT_USED_FOR_STAGE7_SELECTION_OR_OPERATING_POINT";
    row.method_varying_objects = "W_I;C_I;T_I;G_BANK";
    row.common_trial_identity_hash = stage7_stable_hash( ...
        common_trial.trial_seed, common_trial.target_angles_deg, ...
        common_trial.Y_element);
    rows{index} = row;
    runtime{index} = struct('paired_group_id', row.paired_group_id, ...
        'trial_index', row.trial_index, 'method_id', row.method_id, ...
        'runtime_sec', estimate.runtime_sec);
end
full_score = normalized_scores(3);
for index = 1:3
    rows{index}.normalized_score_gap_to_full_parent = ...
        full_score - normalized_scores(index);
end
method_rows = struct2table(vertcat(rows{:}));
runtime_rows = struct2table(vertcat(runtime{:}));
validate_shared_output_local(method_rows, expected_method);
end

function plan_group = validate_plan_group_local( ...
    plan_group, expected_method, expected_subset)
if ~(istable(plan_group) && height(plan_group) == 3)
    error('evaluate_stage7_1_edge_methods:PlanGroup', ...
        'plan_group must contain exactly three method rows.');
end
required = {'method_id','subset_id','K','scenario_id','element_snr_db'};
if ~all(ismember(required, plan_group.Properties.VariableNames))
    error('evaluate_stage7_1_edge_methods:PlanSchema', ...
        'plan_group is missing a required method field.');
end
order = zeros(3, 1);
for index = 1:3
    match = find(plan_group.method_id == expected_method(index) & ...
        plan_group.subset_id == expected_subset(index));
    if numel(match) ~= 1
        error('evaluate_stage7_1_edge_methods:MethodContract', ...
            'The frozen edge method/subset mapping changed.');
    end
    order(index) = match;
end
plan_group = plan_group(order, :);
if numel(unique(plan_group.scenario_id)) ~= 1 || ...
        numel(unique(plan_group.element_snr_db)) ~= 1 || ...
        any(plan_group.K ~= 2)
    error('evaluate_stage7_1_edge_methods:SharedPlan', ...
        'The three method rows do not share one frozen trial plan.');
end
end

function models = order_models_local(models, expected_method, expected_subset)
if ~(isstruct(models) && numel(models) == 3 && ...
        all(isfield(models, {'method_id','subset_id','channels','model','G_bank'})))
    error('evaluate_stage7_1_edge_methods:Models', ...
        'Exactly three fixed method models are required.');
end
ordered = models;
for index = 1:3
    match = find(string({models.method_id}) == expected_method(index) & ...
        string({models.subset_id}) == expected_subset(index));
    if numel(match) ~= 1
        error('evaluate_stage7_1_edge_methods:ModelIdentity', ...
            'A fixed edge method model is missing or duplicated.');
    end
    ordered(index) = models(match);
end
models = ordered;
end

function validate_trial_local(trial)
required = {'Y_element','target_angles_deg','paired_group_id', ...
    'paired_group_index','trial_index','trial_seed', ...
    'realized_element_snr_db','historical_registered_domain_pass', ...
    'tolerant_registered_domain_pass', ...
    'boundary_numeric_disagreement_flag','domain_tolerance_deg', ...
    'edge_diagnostic_domain_pass'};
if ~(isstruct(trial) && isscalar(trial) && all(isfield(trial, required)) && ...
        isequal(size(trial.target_angles_deg), [2,2]))
    error('evaluate_stage7_1_edge_methods:Trial', ...
        'The common element-domain trial schema is incomplete.');
end
end

function evaluation = evaluate_estimate_local(estimate, truth, gates, ...
    domain_pass, Z)
if ~estimate.estimate_returned_flag || ~domain_pass
    evaluation = struct('success', false, ...
        'azimuth_error_deg', gates.unconditional_penalty_deg, ...
        'elevation_error_deg', gates.unconditional_penalty_deg, ...
        'pair_error_deg', gates.unconditional_penalty_deg, ...
        'penalized_error', gates.unconditional_penalty_deg, ...
        'wrong_peak', false, 'normalized_score', NaN);
    return;
end
angles = estimate.angles_hat_deg;
first = angles - truth;
second = angles([2,1], :) - truth;
if norm(second, 'fro') < norm(first, 'fro'), errors = second; else, errors = first; end
azimuth_error = sqrt(mean(errors(:, 1) .^ 2));
elevation_error = sqrt(mean(errors(:, 2) .^ 2));
pair_error = sqrt(mean(sum(errors .^ 2, 2)));
success = all(abs(errors(:, 1)) <= gates.azimuth_gate_deg) && ...
    all(abs(errors(:, 2)) <= gates.elevation_gate_deg);
penalty = pair_error;
if ~success, penalty = gates.unconditional_penalty_deg; end
evaluation = struct('success', success, ...
    'azimuth_error_deg', azimuth_error, ...
    'elevation_error_deg', elevation_error, ...
    'pair_error_deg', pair_error, 'penalized_error', penalty, ...
    'wrong_peak', pair_error > gates.wrong_peak_pair_gate_deg, ...
    'normalized_score', estimate.score / max(norm(Z, 'fro') ^ 2, realmin));
end

function validate_shared_output_local(rows, expected_method)
shared = {'paired_group_id','trial_index','trial_seed', ...
    'target1_az_deg','target1_el_deg','target2_az_deg','target2_el_deg', ...
    'realized_element_snr_db','common_trial_identity_hash'};
pass = height(rows) == 3 && isequal(rows.method_id, expected_method);
for index = 1:numel(shared)
    pass = pass && numel(unique(rows.(shared{index}))) == 1;
end
if ~pass
    error('evaluate_stage7_1_edge_methods:SharedTrial', ...
        'The three method rows do not share one common trial identity.');
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('evaluate_stage7_1_edge_methods:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'unit_test_mode','solver_function'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('evaluate_stage7_1_edge_methods:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'unit_test_mode'), opts.unit_test_mode = false; end
if ~isfield(opts, 'solver_function')
    opts.solver_function = @run_stage7_oracle_dml;
elseif ~opts.unit_test_mode
    error('evaluate_stage7_1_edge_methods:SolverOverride', ...
        'Solver overrides are restricted to explicit unit-test mode.');
end
if ~(islogical(opts.unit_test_mode) && isscalar(opts.unit_test_mode) && ...
        isa(opts.solver_function, 'function_handle'))
    error('evaluate_stage7_1_edge_methods:OptionValue', ...
        'Invalid edge method evaluator options.');
end
end
