function [rows, diagnostics] = stage8_compact_evaluate_trial(spec, context)
%STAGE8_COMPACT_EVALUATE_TRIAL Evaluate one indivisible K1 or K2 trial.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_compact_evaluate_trial:Spec', ...
        'spec must be one compact-registry row.');
end
if string(spec.trial_type) == "K1"
    [rows, diagnostics] = evaluate_k1_local(spec, context);
elseif string(spec.trial_type) == "K2"
    [rows, diagnostics] = evaluate_k2_local(spec, context);
else
    error('stage8_compact_evaluate_trial:TrialType', ...
        'Unsupported compact diagnostic trial type.');
end
end

function [rows, diagnostics] = evaluate_k1_local(spec, context)
pair = k1_pair_local(spec, context);
trial_clock = tic;
[source_rows, source_diagnostics] = stage8_1b_evaluate_common_trial( ...
    pair, context.plan, context.thresholds, struct('formal_run', false, ...
    'separation_formal_run', true, 'fit_options', struct(), ...
    'Bsep', 199, 'run_separation', true));
runtime_sec = toc(trial_clock);
cells = cell(height(source_rows), 1);
for index = 1:height(source_rows)
    source = source_rows(index, :);
    row = base_row_local(spec, source.measurement_config_id, ...
        index - 1, source.element_trial_hash);
    names = {'evaluation_row_index','pairing_key','center_az_deg', ...
        'center_el_deg','snr_db','threshold_calibration_hash', ...
        'threshold_artifact_hash','q_global','lambda_12','state', ...
        'false_split_flag','false_resolved_flag','K2_UNRESOLVED_flag', ...
        'SEARCH_NOT_CONVERGED_flag','NUMERIC_RANK_DEFICIENT_flag', ...
        'decision_available_flag','fit1_validity_status', ...
        'fit2_validity_status','separation_status'};
    for name_index = 1:numel(names)
        name = names{name_index};
        row.(name) = source.(name);
    end
    row.diagnostic_row_index = double(source.evaluation_row_index);
    row.diagnostic_state = string(source.state);
    row.valid_k1_fit_flag = ~ismember(string(source.state), ...
        ["SEARCH_NOT_CONVERGED","NUMERIC_RANK_DEFICIENT"]);
    row.valid_k2_fit_flag = row.valid_k1_fit_flag;
    row.lrt_split_detected_flag = isfinite(source.lambda_12) && ...
        source.lambda_12 > source.q_global;
    row.separation_evaluated_flag = ~startsWith( ...
        string(source.separation_status), "NOT_RUN");
    row.row_runtime_sec = runtime_sec / height(source_rows);
    cells{index} = row;
end
rows = struct2table(vertcat(cells{:}));
diagnostics = struct('diagnostic_trial_id', char(spec.diagnostic_trial_id), ...
    'element_trial_hash', char(source_diagnostics.element_trial_hash), ...
    'separation_trigger_count', ...
    double(source_diagnostics.separation_trigger_row_count), ...
    'truth_metrics', struct('trial_type', 'K1', ...
    'truth_used_in_fit_flag', false, ...
    'truth_used_in_classifier_flag', false), ...
    'runtime_class', ternary_local( ...
    source_diagnostics.separation_trigger_row_count > 0, ...
    'K1_SEPARATION_TRIGGERED', 'K1_NO_SEPARATION'));
end

function pair = k1_pair_local(spec, context)
registry = context.registry;
mask = registry.stratum_index == spec.stratum_index & ...
    registry.trial_index_within_stratum == 1;
pair = sortrows(registry(mask, :), 'evaluation_row_index');
if height(pair) ~= 2
    error('stage8_compact_evaluate_trial:K1Prototype', ...
        'Frozen K1 registry did not provide one configuration pair.');
end
pair.evaluation_row_index = ...
    (double(spec.row_start_index):double(spec.row_start_index) + 1).';
pair.common_trial_id(:) = string(spec.diagnostic_trial_id);
pair.pairing_key(:) = string(spec.diagnostic_trial_id);
pair.trial_index_within_stratum(:) = spec.trial_index_within_stratum;
pair.parameter_seed(:) = spec.parameter_seed;
pair.element_noise_seed(:) = spec.element_noise_seed;
pair.separation_auxiliary_seed(:) = spec.separation_auxiliary_seed;
end

function [rows, diagnostics] = evaluate_k2_local(spec, context)
[trial, generation_contract] = ...
    stage8_compact_generate_k2_trial(spec, context);
constants = stage8_compact_constants();
config_ids = string(constants.primary_measurement_config_id);
if logical(spec.sentinel_flag)
    config_ids(end + 1, 1) = string( ...
        constants.sensitivity_measurement_config_id);
end
cells = cell(numel(config_ids), 1);
separation_count = 0;
for index = 1:numel(config_ids)
    config_id = config_ids(index);
    model = resolve_stage8_measurement_model( ...
        context.plan.measurement_model_registry, config_id, ...
        spec.noise_profile_id);
    if ~strcmp(model.noise_factorization.factorization_hash, ...
            trial.base_model.noise_factorization.factorization_hash)
        error('stage8_compact_evaluate_trial:PairedNoise', ...
            'K2 sentinel configurations must share element covariance.');
    end
    full_data = build_stage8_full_data_from_element( ...
        trial.Y_element, model, struct('diagnostic_parameter_seed', ...
        spec.parameter_seed, 'diagnostic_element_noise_seed', ...
        spec.element_noise_seed, 'data_role', ...
        'STAGE8_COMPACT_K2_DIAGNOSTIC'));
    threshold = threshold_local(context.thresholds, config_id);
    row_clock = tic;
    evaluation = evaluate_k2_method_local(full_data, model, ...
        context.plan.local_domain, threshold, ...
        build_stage8_stage5_locked_config(), spec, trial.targets_deg);
    row_runtime_sec = toc(row_clock);
    row = base_row_local(spec, config_id, index - 1, ...
        trial.element_trial_hash);
    row.center_az_deg = trial.center_deg(1);
    row.center_el_deg = trial.center_deg(2);
    row.snr_db = spec.snr_db;
    row.secondary_power_db = spec.secondary_power_db;
    row.correlation_magnitude = spec.correlation_magnitude;
    row.correlation_phase_rad = trial.correlation_phase_rad;
    row.true_separation_deg = spec.separation_deg;
    row.direction_deg = spec.direction_deg;
    row.threshold_calibration_hash = string(threshold.calibration_hash);
    row.threshold_artifact_hash = string(threshold.threshold_artifact_hash);
    row.q_global = threshold.q_global;
    names = fieldnames(evaluation);
    for name_index = 1:numel(names)
        name = names{name_index};
        if isfield(row, name), row.(name) = evaluation.(name); end
    end
    row.row_runtime_sec = row_runtime_sec;
    cells{index} = row;
    separation_count = separation_count + ...
        double(evaluation.separation_evaluated_flag);
end
rows = struct2table(vertcat(cells{:}));
generation_contract.targets_deg = trial.targets_deg;
generation_contract.source_info = trial.source_info;
diagnostics = struct('diagnostic_trial_id', char(spec.diagnostic_trial_id), ...
    'element_trial_hash', trial.element_trial_hash, ...
    'separation_trigger_count', separation_count, ...
    'truth_metrics', generation_contract, ...
    'runtime_class', runtime_class_local(spec, separation_count));
end

function evaluation = evaluate_k2_method_local(data, model, domain, ...
    threshold, locked, spec, targets)
evaluation = empty_k2_evaluation_local(targets);
[initialization, ~] = build_stage8_initialization_context_from_data( ...
    data, model, domain, locked, model.noise_factorization, struct());
[fit1, ~] = fit_local_model_k(data, 1, domain, model, ...
    initialization, struct());
[valid1, validity1] = validate_stage8_fit_for_lrt(fit1, 1, ...
    struct('fixed_measurement_hash', model.fixed_measurement_hash, ...
    'local_domain_hash', domain.domain_hash));
evaluation.fit1_validity_status = string(validity1.status);
evaluation.valid_k1_fit_flag = valid1;
evaluation.score_call_count = fit1.num_score_eval;
evaluation.svd_call_count = fit1.num_svd;
if ~valid1
    evaluation = failure_evaluation_local(evaluation, validity1.status);
    return;
end
evaluation.k1_estimate_az_deg = fit1.angles_hat_deg(1, 1);
evaluation.k1_estimate_el_deg = fit1.angles_hat_deg(1, 2);
initialization.k1_fit = fit1;
[fit2, fit2_debug] = fit_local_model_k(data, 2, domain, model, ...
    initialization, struct());
[valid2, validity2] = validate_stage8_fit_for_lrt(fit2, 2, ...
    identity_from_fit_local(fit1));
evaluation.fit2_validity_status = string(validity2.status);
evaluation.valid_k2_fit_flag = valid2;
evaluation.score_call_count = evaluation.score_call_count + ...
    fit2.num_score_eval;
evaluation.svd_call_count = evaluation.svd_call_count + fit2.num_svd;
if ~valid2
    evaluation = failure_evaluation_local(evaluation, validity2.status);
    return;
end
[lrt, ~] = nested_dml_likelihood_ratio(fit1, fit2, struct());
if ~strcmp(lrt.lrt_status, 'OK')
    evaluation = failure_evaluation_local(evaluation, lrt.lrt_status);
    return;
end
evaluation.lambda_12 = lrt.lambda_12;
evaluation.lrt_split_detected_flag = lrt.lambda_12 > threshold.q_global;
evaluation.decision_available_flag = true;
evaluation.k2_selected_start_id = string(fit2.initialization_id);
selected_index = double(fit2_debug.selected_start_index);
initial_angles = fit2.all_start_results(selected_index).initial_angles_deg;
[matched_initial, ~, ~] = match_bootstrap_target_labels( ...
    initial_angles, targets);
[matched_final, ~, ~] = match_bootstrap_target_labels( ...
    fit2.angles_hat_deg, targets);
evaluation = add_truth_metrics_local( ...
    evaluation, targets, matched_initial, matched_final);

if ~evaluation.lrt_split_detected_flag
    evaluation.state = "K1_FAVORED_MISSED_SPLIT";
    evaluation.diagnostic_state = evaluation.state;
    evaluation.separation_status = ...
        "NOT_RUN_LRT_DID_NOT_EXCEED_THRESHOLD";
elseif logical(spec.sentinel_flag)
    [separation, ~] = bootstrap_separation_confidence( ...
        fit2, domain, model, struct('Bsep', 199, ...
        'seed', spec.separation_auxiliary_seed, 'formal_run', true, ...
        'stage5_locked_config', locked, 'fit_options', struct()));
    decision = classify_local_cluster_state( ...
        fit1, fit2, lrt, threshold, separation, struct());
    evaluation.state = string(decision.state);
    evaluation.diagnostic_state = evaluation.state;
    evaluation.separation_status = string(separation.confidence_status);
    evaluation.separation_evaluated_flag = true;
else
    evaluation.state = "K2_LRT_DETECTED_SEPARATION_NOT_RUN";
    evaluation.diagnostic_state = evaluation.state;
    evaluation.separation_status = "NOT_RUN_NON_SENTINEL_DIAGNOSTIC";
end
end

function evaluation = empty_k2_evaluation_local(targets)
evaluation = stage8_compact_row_template();
evaluation = rmfield(evaluation, setdiff(fieldnames(evaluation), { ...
    'lambda_12','state','diagnostic_state','decision_available_flag', ...
    'lrt_split_detected_flag','separation_evaluated_flag', ...
    'fit1_validity_status','fit2_validity_status','separation_status', ...
    'valid_k1_fit_flag','valid_k2_fit_flag','k1_estimate_az_deg', ...
    'k1_estimate_el_deg','k2_selected_start_id', ...
    'initial_target1_az_deg','initial_target1_el_deg', ...
    'initial_target2_az_deg','initial_target2_el_deg', ...
    'final_target1_az_deg','final_target1_el_deg', ...
    'final_target2_az_deg','final_target2_el_deg','azimuth_rmse_deg', ...
    'elevation_rmse_deg','joint_2d_rmse_deg', ...
    'initial_joint_2d_rmse_deg','joint_refinement_improved_flag', ...
    'true_separation_az_deg','true_separation_el_deg', ...
    'estimated_separation_az_deg','estimated_separation_el_deg', ...
    'separation_vector_error_deg','score_call_count','svd_call_count', ...
    'truth_target1_az_deg','truth_target1_el_deg', ...
    'truth_target2_az_deg','truth_target2_el_deg'}));
evaluation.truth_target1_az_deg = targets(1, 1);
evaluation.truth_target1_el_deg = targets(1, 2);
evaluation.truth_target2_az_deg = targets(2, 1);
evaluation.truth_target2_el_deg = targets(2, 2);
evaluation.state = "SEARCH_NOT_CONVERGED";
evaluation.diagnostic_state = evaluation.state;
evaluation.fit1_validity_status = "NOT_RUN";
evaluation.fit2_validity_status = "NOT_RUN";
evaluation.separation_status = "NOT_RUN_INVALID_LRT_FIT";
evaluation.score_call_count = 0;
evaluation.svd_call_count = 0;
end

function evaluation = failure_evaluation_local(evaluation, status)
if strcmp(status, 'NUMERIC_RANK_DEFICIENT')
    state = "NUMERIC_RANK_DEFICIENT";
else
    state = "SEARCH_NOT_CONVERGED";
end
evaluation.state = state;
evaluation.diagnostic_state = state;
evaluation.lambda_12 = NaN;
evaluation.separation_status = "NOT_RUN_INVALID_LRT_FIT";
end

function evaluation = add_truth_metrics_local( ...
    evaluation, targets, initial_angles, final_angles)
evaluation.initial_target1_az_deg = initial_angles(1, 1);
evaluation.initial_target1_el_deg = initial_angles(1, 2);
evaluation.initial_target2_az_deg = initial_angles(2, 1);
evaluation.initial_target2_el_deg = initial_angles(2, 2);
evaluation.final_target1_az_deg = final_angles(1, 1);
evaluation.final_target1_el_deg = final_angles(1, 2);
evaluation.final_target2_az_deg = final_angles(2, 1);
evaluation.final_target2_el_deg = final_angles(2, 2);
error_now = final_angles - targets;
initial_error = initial_angles - targets;
evaluation.azimuth_rmse_deg = sqrt(mean(error_now(:, 1) .^ 2));
evaluation.elevation_rmse_deg = sqrt(mean(error_now(:, 2) .^ 2));
evaluation.joint_2d_rmse_deg = sqrt(mean(sum(error_now .^ 2, 2)));
evaluation.initial_joint_2d_rmse_deg = ...
    sqrt(mean(sum(initial_error .^ 2, 2)));
evaluation.joint_refinement_improved_flag = ...
    evaluation.joint_2d_rmse_deg <= ...
    evaluation.initial_joint_2d_rmse_deg;
true_vector = targets(2, :) - targets(1, :);
estimated_vector = final_angles(2, :) - final_angles(1, :);
evaluation.true_separation_az_deg = true_vector(1);
evaluation.true_separation_el_deg = true_vector(2);
evaluation.estimated_separation_az_deg = estimated_vector(1);
evaluation.estimated_separation_el_deg = estimated_vector(2);
evaluation.separation_vector_error_deg = norm(estimated_vector - true_vector);
end

function row = base_row_local(spec, config_id, offset, element_hash)
row = stage8_compact_row_template();
row.diagnostic_row_index = double(spec.row_start_index) + offset;
row.evaluation_row_index = row.diagnostic_row_index;
row.diagnostic_trial_id = string(spec.diagnostic_trial_id);
row.common_trial_id = row.diagnostic_trial_id;
row.global_trial_index = double(spec.global_trial_index);
row.trial_type = string(spec.trial_type);
row.stratum_index = double(spec.stratum_index);
row.stratum_id = string(spec.stratum_id);
row.pairing_key = row.diagnostic_trial_id;
row.trial_index_within_stratum = double(spec.trial_index_within_stratum);
row.profile_id = double(spec.profile_id);
row.sentinel_flag = logical(spec.sentinel_flag);
row.measurement_config_id = string(config_id);
row.noise_profile_id = string(spec.noise_profile_id);
row.L = double(spec.L);
row.parameter_seed = double(spec.parameter_seed);
row.element_noise_seed = double(spec.element_noise_seed);
row.separation_auxiliary_seed = double(spec.separation_auxiliary_seed);
row.element_trial_hash = string(element_hash);
end

function threshold = threshold_local(thresholds, config_id)
matches = string({thresholds.measurement_config_id}) == string(config_id);
if nnz(matches) ~= 1
    error('stage8_compact_evaluate_trial:Threshold', ...
        'Committed threshold lookup did not return exactly one artifact.');
end
threshold = thresholds(matches);
end

function identity = identity_from_fit_local(fit)
identity = struct('fixed_measurement_hash', fit.fixed_measurement_hash, ...
    'local_domain_hash', fit.local_domain_hash, ...
    'solver_contract_hash', fit.solver_contract_hash, ...
    'observation_hash', fit.observation_hash);
end

function value = runtime_class_local(spec, separation_count)
if logical(spec.sentinel_flag)
    value = ternary_local(separation_count > 0, ...
        'K2_SENTINEL_SEPARATION_TRIGGERED', 'K2_SENTINEL_NO_SEPARATION');
else
    value = 'K2_NON_SENTINEL';
end
end

function value = ternary_local(condition, yes_value, no_value)
if condition, value = yes_value; else, value = no_value; end
end
