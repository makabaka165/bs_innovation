function [trials, complexity] = run_stage7_finite_sample_validation(finite)
%RUN_STAGE7_FINITE_SAMPLE_VALIDATION Run all paired oracle-K holdouts.

plan_table = finite.context.plan.finite_sample_plan;
methods = finite.methods;
trial_count = sum(plan_table.Nmc) * height(methods);
trials = preallocate_trials_local(trial_count);
row_index = 0;
actual_score_calls = 0;
actual_svd_calls = 0;
start_tic = tic;
for scenario_index = 1:height(plan_table)
    plan_row = plan_table(scenario_index, :);
    noise_index = noise_index_local(plan_row.noise_covariance_id);
    unique_models = finite.method_models{noise_index};
    fprintf('Stage7 finite sample %s (%d/%d), Nmc=%d\n', ...
        char(plan_row.scenario_id), scenario_index, height(plan_table), plan_row.Nmc);
    for trial_index = 1:plan_row.Nmc
        common_trial = generate_stage7_finite_sample_trial( ...
            plan_row, finite, trial_index);
        Z0 = finite.context.plan.pool.W0' * common_trial.Y_element;
        unique_results = repmat(struct('subset_id', "", 'estimate', struct(), ...
            'evaluation', struct()), numel(unique_models), 1);
        for model_index = 1:numel(unique_models)
            item = unique_models(model_index);
            Z = item.model.T_I * Z0(item.channels, :);
            estimate = run_stage7_oracle_dml(Z, item.G_bank, finite, plan_row.K);
            evaluation = evaluate_estimate_local(estimate, ...
                common_trial.target_angles_deg, finite.context.plan.success, ...
                common_trial.registered_domain_pass, Z);
            unique_results(model_index) = struct('subset_id', item.subset_id, ...
                'estimate', estimate, 'evaluation', evaluation);
            actual_score_calls = actual_score_calls + estimate.score_calls;
            actual_svd_calls = actual_svd_calls + estimate.svd_calls;
        end
        full_index = find([unique_results.subset_id] == ...
            methods.subset_id(methods.method_id == "FULL_PARENT_5X5"), 1);
        full_score = unique_results(full_index).evaluation.normalized_score;
        for method_index = 1:height(methods)
            result_index = find([unique_results.subset_id] == ...
                methods.subset_id(method_index), 1);
            estimate = unique_results(result_index).estimate;
            evaluation = unique_results(result_index).evaluation;
            row_index = row_index + 1;
            method = methods(method_index, :);
            trials.data_split(row_index) = plan_row.data_split;
            trials.scenario_id(row_index) = plan_row.scenario_id;
            trials.method_id(row_index) = method.method_id;
            trials.method_class(row_index) = method.method_class;
            trials.subset_id(row_index) = method.subset_id;
            trials.trial_index(row_index) = trial_index;
            trials.seed(row_index) = common_trial.seed;
            trials.element_snr_db(row_index) = plan_row.element_snr_db;
            trials.realized_element_snr_db(row_index) = ...
                common_trial.realized_element_snr_db;
            trials.oracle_k_success(row_index) = evaluation.success;
            trials.azimuth_error_deg(row_index) = evaluation.azimuth_error_deg;
            trials.elevation_error_deg(row_index) = ...
                evaluation.elevation_error_deg;
            trials.pair_error_deg(row_index) = evaluation.pair_error_deg;
            trials.unconditional_penalized_error(row_index) = ...
                evaluation.penalized_error;
            trials.wrong_local_peak(row_index) = evaluation.wrong_peak;
            trials.converged(row_index) = estimate.converged_flag;
            trials.normalized_score(row_index) = evaluation.normalized_score;
            trials.normalized_score_gap_to_full_parent(row_index) = ...
                full_score - evaluation.normalized_score;
            trials.MAC_total(row_index) = method.MAC_total;
            trials.B_out(row_index) = method.B_out;
            trials.output_bytes(row_index) = 16 * method.B_out;
            trials.runtime_sec(row_index) = estimate.runtime_sec;
            trials.score_calls(row_index) = estimate.score_calls;
            trials.SVD_calls(row_index) = estimate.svd_calls;
            trials.iterations(row_index) = estimate.iterations;
            trials.multi_start_count(row_index) = estimate.multi_start_count;
            trials.status(row_index) = estimate.status;
        end
    end
end
runtime = toc(start_tic);
if row_index ~= trial_count
    error('run_stage7_finite_sample_validation:TrialCount', ...
        'Expected %d method-trials but generated %d.', trial_count, row_index);
end
complexity = struct('trial_method_row_count', height(trials), ...
    'actual_unique_subset_score_calls', actual_score_calls, ...
    'actual_unique_subset_svd_calls', actual_svd_calls, ...
    'charged_method_score_calls', sum(trials.score_calls), ...
    'charged_method_svd_calls', sum(trials.SVD_calls), ...
    'runtime_sec', runtime);
end

function trials = preallocate_trials_local(n)
data_split = strings(n, 1);
scenario_id = strings(n, 1);
method_id = strings(n, 1);
method_class = strings(n, 1);
subset_id = strings(n, 1);
trial_index = zeros(n, 1);
seed = zeros(n, 1);
element_snr_db = NaN(n, 1);
realized_element_snr_db = NaN(n, 1);
oracle_k_success = false(n, 1);
azimuth_error_deg = NaN(n, 1);
elevation_error_deg = NaN(n, 1);
pair_error_deg = NaN(n, 1);
unconditional_penalized_error = NaN(n, 1);
wrong_local_peak = false(n, 1);
converged = false(n, 1);
normalized_score = NaN(n, 1);
normalized_score_gap_to_full_parent = NaN(n, 1);
MAC_total = zeros(n, 1);
B_out = zeros(n, 1);
output_bytes = zeros(n, 1);
runtime_sec = zeros(n, 1);
score_calls = zeros(n, 1);
SVD_calls = zeros(n, 1);
iterations = zeros(n, 1);
multi_start_count = zeros(n, 1);
status = strings(n, 1);
trials = table(data_split, scenario_id, method_id, method_class, ...
    subset_id, trial_index, seed, element_snr_db, ...
    realized_element_snr_db, oracle_k_success, azimuth_error_deg, ...
    elevation_error_deg, pair_error_deg, unconditional_penalized_error, ...
    wrong_local_peak, converged, normalized_score, ...
    normalized_score_gap_to_full_parent, MAC_total, B_out, output_bytes, ...
    runtime_sec, score_calls, SVD_calls, iterations, multi_start_count, status);
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
estimate_angles = estimate.angles_hat_deg;
if size(truth, 1) == 2
    errors_1 = estimate_angles - truth;
    errors_2 = estimate_angles([2,1], :) - truth;
    if norm(errors_2, 'fro') < norm(errors_1, 'fro')
        errors = errors_2;
    else
        errors = errors_1;
    end
else
    errors = estimate_angles - truth;
end
azimuth_error = sqrt(mean(errors(:, 1) .^ 2));
elevation_error = sqrt(mean(errors(:, 2) .^ 2));
pair_error = sqrt(mean(sum(errors .^ 2, 2)));
success = all(abs(errors(:, 1)) <= gates.azimuth_gate_deg) && ...
    all(abs(errors(:, 2)) <= gates.elevation_gate_deg);
if success
    penalty = pair_error;
else
    penalty = gates.unconditional_penalty_deg;
end
evaluation = struct('success', success, ...
    'azimuth_error_deg', azimuth_error, ...
    'elevation_error_deg', elevation_error, 'pair_error_deg', pair_error, ...
    'penalized_error', penalty, ...
    'wrong_peak', pair_error > gates.wrong_peak_pair_gate_deg, ...
    'normalized_score', estimate.score / max(norm(Z, 'fro') ^ 2, realmin));
end

function index = noise_index_local(noise_id)
if string(noise_id) == "WHITE", index = 1; else, index = 2; end
end
