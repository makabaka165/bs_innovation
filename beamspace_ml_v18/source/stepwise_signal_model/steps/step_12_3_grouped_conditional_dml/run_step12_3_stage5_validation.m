clc
clear
close all

script_dir = fileparts(mfilename('fullpath'));
step_dir = script_dir;
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
package_dir = fileparts(fileparts(project_dir));
common_dir = fullfile(step_dir, 'common');
tests_dir = fullfile(step_dir, 'tests');
result_dir = fullfile(step_dir, 'results_stage5');

addpath(fullfile(steps_dir, 'step_12_0_receive_model_correction', 'common'));
addpath(fullfile(steps_dir, 'step_12_1_sequential_dbf_model', 'common'));
addpath(fullfile(steps_dir, 'step_12_2_stable_dml_backend', 'common'));
addpath(common_dir);
addpath(tests_dir);
addpath(fullfile(project_dir, 'core', 'config'));
addpath(fullfile(project_dir, 'core', 'array'));
if exist(result_dir, 'dir') ~= 7
    mkdir(result_dir);
end

cfg = sim_cfg();
if cfg.beam.spatialPhaseFactor ~= 1
    error('run_step12_3_stage5:ActivePhaseFactor', ...
        'Stage 5 requires receive spatial phase_factor=1.');
end
validation_tic = tic;

[tests.group_noise_table, tests.group_noise_context] = ...
    test_group_noise_propagation();
[tests.manifold_table, tests.manifold_context] = ...
    test_conditional_azimuth_manifold(cfg);
[tests.fixed_table, tests.fixed_context] = ...
    test_conditional_azimuth_fixed_measurement(cfg);
[tests.noise_table, tests.noise_context] = ...
    test_conditional_azimuth_noise_whitening(cfg);
[tests.q1_k2_table, tests.q1_k2_context] = ...
    test_conditional_azimuth_q1_k2(cfg);
[tests.propagation_table, tests.propagation_context] = ...
    test_oracle_estimated_perturbed_elevation(cfg);
[tests.full_data_table, tests.full_data_context] = ...
    test_full_sequential_data_equivalence(cfg);
[tests.full_manifold_table, tests.full_manifold_context] = ...
    test_full_sequential_manifold(cfg);
[tests.monotonicity_table, tests.monotonicity_context] = ...
    test_joint_refinement_monotonicity(cfg);
[tests.canonical_table, tests.canonical_context] = ...
    test_joint_refinement_canonical_order(cfg);
tests.domain_table = test_no_truth_dependent_domain(step_dir);
[tests.gate_table, tests.gate_context] = test_upstream_group_gate(cfg);
tests.baseline_scope_table = test_baseline_status_scope(step_dir);
tests.scope_table = test_stage5_scope_rules(step_dir);
[tests.suite_table, tests.suite_context] = ...
    test_stage5_method_suite_design(cfg);

tests.total_test_rows = test_row_count_local(tests);
tests.all_tests_pass = test_pass_local(tests);
[~, frozen_context] = verify_step11_frozen_results(package_dir);
[analyzer_count, analyzer_summary] = run_code_analyzer_local(step_dir);

evidence = run_stage5_registered_experiments(cfg);
technical_pass = tests.all_tests_pass && analyzer_count == 0 && ...
    frozen_context.pass_flag && all(evidence.core_nmc_table.pass_flag) && ...
    all(evidence.trial_table.pass_flag) && ...
    all(evidence.trial_table.phase_factor == 1) && ...
    all(evidence.trial_table.statistical_calibration_status == ...
    "NOT_CALIBRATED_STAGE5") && ...
    tests.monotonicity_context.debug.monotonicity_violation_count == 0 && ...
    tests.monotonicity_context.normalized_score_gap <= 1e-10;
overall_pass = technical_pass && evidence.pareto.pareto_pass;

outputs = write_stage5_results_bundle(result_dir, cfg, evidence, tests, ...
    analyzer_count, frozen_context, overall_pass);
output_pass = validate_outputs_local(outputs);
overall_pass = overall_pass && output_pass;
if ~overall_pass
    write_stage5_results_bundle(result_dir, cfg, evidence, tests, ...
        analyzer_count, frozen_context, overall_pass);
end
validation_runtime_sec = toc(validation_tic);

fprintf('Step12.3D-E stage-5 validation: %s\n', pass_fail_local(overall_pass));
fprintf('Required/integration test rows: %d, analyzer messages: %d\n', ...
    tests.total_test_rows, analyzer_count);
fprintf('Frozen Step11 files: %d, hash mismatches: %d\n', ...
    frozen_context.file_count, frozen_context.hash_mismatch_count);
fprintf('Experiment method rows: %d, holdout pairs: %d\n', ...
    height(evidence.trial_table), evidence.pareto.holdout_trial_count);
fprintf('Paired success difference 95%% interval: [%.6f, %.6f]\n', ...
    evidence.pareto.paired_success_difference_95_low, ...
    evidence.pareto.paired_success_difference_95_high);
fprintf('Score-call reduction versus direct/local full: %.2f%% / %.2f%%\n', ...
    100 * evidence.pareto.score_call_reduction_vs_direct, ...
    100 * evidence.pareto.score_call_reduction_vs_local_full);
fprintf('Pareto scheme 1/2: %d/%d\n', ...
    evidence.pareto.scheme1_complexity_benefit_pass, ...
    evidence.pareto.scheme2_performance_benefit_pass);
fprintf('Validation runtime: %.6f s\n', validation_runtime_sec);
fprintf('Results: %s\n', result_dir);
if analyzer_count > 0
    disp(analyzer_summary);
end
assert(overall_pass, 'run_step12_3_stage5:ValidationFailed', ...
    'Stage 5 failed at least one registered technical or Pareto gate.');

function count = test_row_count_local(tests)
names = {'group_noise_table','manifold_table','fixed_table','noise_table', ...
    'q1_k2_table','propagation_table','full_data_table', ...
    'full_manifold_table','monotonicity_table','canonical_table', ...
    'domain_table','gate_table','baseline_scope_table','scope_table', ...
    'suite_table'};
count = 0;
for idx = 1:numel(names)
    count = count + height(tests.(names{idx}));
end
end

function flag = test_pass_local(tests)
flag = all(tests.group_noise_table.pass_flag) && ...
    all(tests.manifold_table.pass_flag) && ...
    all(tests.fixed_table.hash_match & ...
    tests.fixed_table.fixed_objects_unchanged) && ...
    all(tests.noise_table.pass_flag) && all(tests.q1_k2_table.pass_flag) && ...
    all(tests.propagation_table.pass_flag) && ...
    all(tests.full_data_table.pass_flag) && ...
    all(tests.full_manifold_table.pass_flag) && ...
    all(tests.monotonicity_table.pass_flag) && ...
    all(tests.canonical_table.pass_flag) && ...
    all(tests.domain_table.pass_flag) && all(tests.gate_table.pass_flag) && ...
    all(tests.baseline_scope_table.pass_flag) && ...
    all(tests.scope_table.pass_flag) && all(tests.suite_table.pass_flag);
end

function [count, summary] = run_code_analyzer_local(step_dir)
files = dir(fullfile(step_dir, '**', '*.m'));
rows = cell(0, 1);
for file_index = 1:numel(files)
    path_now = fullfile(files(file_index).folder, files(file_index).name);
    messages = checkcode(path_now, '-id');
    for message_index = 1:numel(messages)
        rows{end + 1, 1} = struct( ...
            'file', string(path_now), ...
            'line', messages(message_index).line, ...
            'column', string(mat2str(messages(message_index).column)), ...
            'message_id', string(messages(message_index).id), ...
            'message', string(messages(message_index).message)); %#ok<AGROW>
    end
end
count = numel(rows);
if count == 0
    summary = table();
else
    summary = struct2table(vertcat(rows{:}));
end
end

function pass_flag = validate_outputs_local(outputs)
names = fieldnames(outputs);
pass_flag = true;
for idx = 1:numel(names)
    path_now = outputs.(names{idx});
    pass_flag = pass_flag && exist(path_now, 'file') == 2;
    [~, ~, extension] = fileparts(path_now);
    if strcmp(extension, '.csv')
        table_now = readtable(path_now, 'TextType', 'string');
        if ismember('phase_factor', table_now.Properties.VariableNames)
            pass_flag = pass_flag && all(table_now.phase_factor == 1);
        end
        if ismember('statistical_calibration_status', ...
                table_now.Properties.VariableNames)
            pass_flag = pass_flag && all( ...
                table_now.statistical_calibration_status == ...
                "NOT_CALIBRATED_STAGE5");
        end
    end
end
end

function text = pass_fail_local(flag)
if flag
    text = 'PASS';
else
    text = 'FAIL';
end
end
