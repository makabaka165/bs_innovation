clc
clear
close all

step_dir = fileparts(mfilename('fullpath'));
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
package_dir = fileparts(fileparts(project_dir));
repo_dir = fileparts(package_dir);
common_dir = fullfile(step_dir, 'common');
tests_dir = fullfile(step_dir, 'tests');
result_dir = fullfile(step_dir, 'results');
figure_dir = fullfile(step_dir, 'figures');

addpath(fullfile(steps_dir, 'step_12_0_receive_model_correction', 'common'));
addpath(fullfile(steps_dir, 'step_12_1_sequential_dbf_model', 'common'));
addpath(fullfile(steps_dir, 'step_12_2_stable_dml_backend', 'common'));
addpath(fullfile(steps_dir, 'step_12_3_grouped_conditional_dml', 'common'));
addpath(common_dir);
addpath(tests_dir);
addpath(fullfile(project_dir, 'core', 'config'));
addpath(fullfile(project_dir, 'core', 'array'));
cd(repo_dir);

cfg = sim_cfg();
if cfg.beam.spatialPhaseFactor ~= 1
    error('run_step12_4:ActivePhaseFactor', ...
        'Stage 6 requires receive spatial phase_factor=1.');
end
validation_tic = tic;
context = prepare_stage6_context(cfg, step_dir, package_dir);
evidence = run_stage6_registered_experiments(context);

tests = struct();
tests.fixed_registry = test_stage6_fixed_measurement_registry(context, evidence);
tests.hash_freeze = test_stage6_measurement_hash_freeze(context, evidence);
tests.first_derivatives = test_stage6_first_derivatives(context, evidence);
tests.higher_derivatives = test_stage6_higher_directional_derivatives(context, evidence);
tests.metric = test_projected_metric_properties(context, evidence);
tests.exact_identity = test_two_column_exact_identity(context, evidence);
tests.nondegenerate = test_secant_tangent_nondegenerate(context, evidence);
tests.synthetic_null = test_synthetic_tangent_null(context, evidence);
tests.physical_null = test_physical_tangent_null(context, evidence);
tests.invariances = test_geometry_invariances(context, evidence);
tests.column_asymmetry = test_column_norm_asymmetry(context, evidence);
tests.scope = test_stage6_scope_rules(step_dir);
[tests.stage5_frozen, stage5_context] = verify_stage5_frozen_results(package_dir);
[tests.step11_frozen, step11_context] = verify_step11_frozen_results(package_dir);

[analyzer_count, analyzer_table] = code_analyzer_local(step_dir);
test_row_count = test_row_count_local(tests);
tests_pass = test_pass_local(tests);
scope_violation_count = nnz(~tests.scope.pass_flag);
overall_pass = evidence.mathematical_pass && tests_pass && ...
    analyzer_count == 0 && stage5_context.pass_flag && ...
    step11_context.pass_flag && scope_violation_count == 0;

validation = struct();
validation.context = context;
validation.test_row_count = test_row_count;
validation.tests_pass = tests_pass;
validation.analyzer_count = analyzer_count;
validation.analyzer_table = analyzer_table;
validation.scope_violation_count = scope_violation_count;
validation.stage5_file_count = stage5_context.file_count;
validation.stage5_hash_mismatch_count = stage5_context.hash_mismatch_count;
validation.stage5_frozen_pass = stage5_context.pass_flag;
validation.step11_file_count = step11_context.file_count;
validation.step11_hash_mismatch_count = step11_context.hash_mismatch_count;
validation.step11_frozen_pass = step11_context.pass_flag;
validation.overall_pass = overall_pass;
outputs = write_stage6_results_bundle( ...
    result_dir, figure_dir, context, evidence, validation);

[schema_pass, schema_message] = csv_schema_local(result_dir);
hash_consistency_pass = measurement_hash_consistency_local(evidence);
output_files_pass = all(structfun(@(path_now) exist(path_now, 'file') == 2, outputs));
overall_pass = overall_pass && schema_pass && hash_consistency_pass && output_files_pass;
validation.overall_pass = overall_pass;
if ~overall_pass
    write_stage6_results_bundle(result_dir, figure_dir, context, evidence, validation);
end
validation_runtime_sec = toc(validation_tic);

fprintf('Step12.4 tangent-asymptotic validation: %s\n', pass_fail_local(overall_pass));
fprintf('Theory status: %s\n', evidence.theory_status);
fprintf('Registered secant/test rows: %d/%d\n', ...
    height(evidence.secant_all_table), test_row_count);
fprintf('Analyzer messages/scope violations: %d/%d\n', ...
    analyzer_count, scope_violation_count);
fprintf('Stage5/Step11 frozen files: %d/%d, mismatches: %d/%d\n', ...
    stage5_context.file_count, step11_context.file_count, ...
    stage5_context.hash_mismatch_count, step11_context.hash_mismatch_count);
fprintf('Tail max errors sigma2/coherence/Gram: %.6g / %.6g / %.6g\n', ...
    max(evidence.tail_table.max_sigma2_ratio_error), ...
    max(evidence.tail_table.max_coherence_ratio_error), ...
    max(evidence.tail_table.max_normalized_gram_ratio_error));
fprintf('Synthetic null order: %.6f; physical null: %s\n', ...
    evidence.synthetic_table.fitted_order(1), evidence.physical_null_status);
fprintf('Schema/hash/output checks: %d/%d/%d\n', ...
    schema_pass, hash_consistency_pass, output_files_pass);
fprintf('Validation runtime: %.6f s\nResults: %s\nFigures: %s\n', ...
    validation_runtime_sec, result_dir, figure_dir);
if ~schema_pass, fprintf('Schema detail: %s\n', schema_message); end
if analyzer_count > 0, disp(analyzer_table); end
assert(overall_pass, 'run_step12_4:ValidationFailed', ...
    'Stage 6 failed at least one registered gate.');

function [count, table_out] = code_analyzer_local(step_dir)
files = dir(fullfile(step_dir, '**', '*.m'));
rows = cell(0, 1);
for file_index = 1:numel(files)
    path_now = fullfile(files(file_index).folder, files(file_index).name);
    messages = checkcode(path_now, '-id');
    for message_index = 1:numel(messages)
        rows{end + 1, 1} = struct('file', string(path_now), ...
            'line', messages(message_index).line, ...
            'message_id', string(messages(message_index).id), ...
            'message', string(messages(message_index).message)); %#ok<AGROW>
    end
end
count = numel(rows);
if count == 0, table_out = table(); else, table_out = struct2table(vertcat(rows{:})); end
end

function count = test_row_count_local(tests)
names = fieldnames(tests);
count = 0;
for index = 1:numel(names), count = count + height(tests.(names{index})); end
end

function flag = test_pass_local(tests)
names = fieldnames(tests);
flag = true;
for index = 1:numel(names), flag = flag && all(tests.(names{index}).pass_flag); end
end

function [pass, message] = csv_schema_local(result_dir)
files = dir(fullfile(result_dir, '*.csv'));
required = {'phase_factor','fixed_measurement_hash','stage6_controls_hash', ...
    'stage6_experiment_plan_hash','theory_status','prior_art_status','pass_flag'};
pass = numel(files) == 15;
message = '';
for index = 1:numel(files)
    table_now = readtable(fullfile(files(index).folder, files(index).name), ...
        'TextType', 'string');
    missing = setdiff(required, table_now.Properties.VariableNames);
    if ~isempty(missing)
        pass = false;
        message = sprintf('%s missing %s', files(index).name, strjoin(missing, ','));
        return;
    end
    if any(table_now.phase_factor ~= 1)
        pass = false; message = sprintf('%s has non-factor-1 rows', files(index).name); return;
    end
end
end

function pass = measurement_hash_consistency_local(evidence)
registry = evidence.measurement_hash_table;
pass = true;
for index = 1:height(registry)
    rows = evidence.secant_all_table.config_id == registry.config_id(index);
    if any(rows)
        pass = pass && all(evidence.secant_all_table.fixed_measurement_hash(rows) == ...
            registry.fixed_measurement_hash(index));
    end
end
end

function text = pass_fail_local(flag)
if flag, text = 'PASS'; else, text = 'FAIL'; end
end
