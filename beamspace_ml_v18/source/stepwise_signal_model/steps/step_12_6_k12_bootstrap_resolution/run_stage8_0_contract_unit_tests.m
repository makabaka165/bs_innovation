function report = run_stage8_0_contract_unit_tests()
%RUN_STAGE8_0_CONTRACT_UNIT_TESTS Run only small Stage8.0 code-only checks.

step_dir = fileparts(mfilename('fullpath'));
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
package_dir = fileparts(fileparts(project_dir));
repo_dir = fileparts(package_dir);
old_path = path;
path_cleanup = onCleanup(@() path(old_path));
addpath(fullfile(project_dir, 'core', 'config'));
addpath(fullfile(project_dir, 'core', 'array'));
addpath(fullfile(steps_dir, 'step_12_0_receive_model_correction', 'common'));
addpath(fullfile(steps_dir, 'step_12_1_sequential_dbf_model', 'common'));
addpath(fullfile(steps_dir, 'step_12_2_stable_dml_backend', 'common'));
addpath(fullfile(steps_dir, 'step_12_3_grouped_conditional_dml', 'common'));
addpath(fullfile(steps_dir, ...
    'step_12_4_near_pair_tangent_asymptotics', 'common'));
addpath(fullfile(steps_dir, ...
    'step_12_5_exact_subset_fim_beam_design', 'common'));
addpath(fullfile(step_dir, 'common'));
addpath(fullfile(step_dir, 'tests'));

cfg = sim_cfg();
assert(strcmp(version('-release'), '2022b') && ...
    cfg.beam.spatialPhaseFactor == 1, ...
    'run_stage8_0_contract_unit_tests:Runtime', ...
    'Stage8.0 tests require MATLAB R2022b and phase_factor=1.');

tests = struct();
tests.measurement_primary = ...
    test_stage8_measurement_matches_rect_e14_a31(cfg);
tests.measurement_parent = ...
    test_stage8_full_parent_sensitivity_identity(cfg);
tests.k1_noiseless = test_k1_fit_noiseless_single_target();
tests.k2_same_elevation = test_k2_fit_noiseless_same_elevation();
tests.k2_two_groups = test_k2_fit_noiseless_two_elevation_groups();
tests.k2_start_partition = test_k2_initialization_partition_completeness();
tests.k1_embedded = test_k1_embedded_start_contains_k1_column();
tests.nested_rss = test_nested_rss_nonincrease();
tests.lrt_dimension = test_lrt_uses_effective_whitening_dimension();
tests.lrt_loglik = test_lrt_matches_concentrated_loglik_difference();
tests.bootstrap_generation = test_bootstrap_sample_uses_fitted_k1();
tests.bootstrap_refits = test_each_bootstrap_sample_refits_k1_and_k2();
tests.global_threshold = test_global_threshold_is_max_cell_quantile();
tests.threshold_inputs = test_threshold_lookup_has_no_scene_inputs();
tests.label_matching = test_bootstrap_label_matching();
tests.zero_inside = test_separation_confidence_zero_inside();
tests.zero_excluded = test_separation_confidence_zero_excluded();
tests.engineering_gate = test_unresolved_when_engineering_halfwidth_fails();
tests.classifier_k1 = test_classifier_k1();
tests.classifier_resolved = test_classifier_k2_resolved();
tests.classifier_unresolved = test_classifier_k2_unresolved();
tests.no_hidden_truth = test_no_hidden_truth_model_mismatch_state();
tests.calibration_isolation = test_stage8_calibration_split_isolation();
tests.seed_isolation = test_stage8_validation_holdout_seed_isolation();
tests.plan_determinism = test_stage8_plan_hash_determinism(repo_dir, cfg);
tests.identity_runtime = ...
    test_stage8_stable_identity_excludes_runtime_head(repo_dir);
tests.no_chi_square_main = ...
    test_stage8_no_chi_square_main_threshold(step_dir);
tests.no_old_rules = test_stage8_no_c05_topk_gap_rules(step_dir);
tests.stage7_unchanged = ...
    test_stage8_no_stage7_selection_mutation(repo_dir);
tests.stage7_1_frozen = verify_stage7_1_frozen_evidence(package_dir);
tests.stage6_frozen = verify_stage6_frozen_evidence(package_dir);
tests.stage5_frozen = verify_stage5_frozen_results(package_dir);
tests.step11_frozen = verify_step11_frozen_results(package_dir);

[analyzer_count, analyzer_table] = code_analyzer_local(step_dir);
[scope_violation_count, scope_table] = scope_scan_local(step_dir);
names = fieldnames(tests);
assertion_count = 0;
all_tests_pass = true;
for index = 1:numel(names)
    value = tests.(names{index});
    if istable(value) && ismember('pass_flag', value.Properties.VariableNames)
        assertion_count = assertion_count + height(value);
        all_tests_pass = all_tests_pass && all(value.pass_flag);
    end
end
technical_pass = all_tests_pass && analyzer_count == 0 && ...
    scope_violation_count == 0;
identity = build_stage8_code_identity(repo_dir, struct());
summary = table(assertion_count, analyzer_count, scope_violation_count, ...
    all_tests_pass, technical_pass, ...
    string(identity.stage8_source_tree_hash), ...
    string(identity.stage8_stable_code_identity_hash), ...
    'VariableNames', {'assertion_count','analyzer_count', ...
    'scope_violation_count','all_tests_pass','technical_pass', ...
    'stage8_source_tree_hash','stage8_stable_code_identity_hash'});
fprintf(['Stage8.0 code-only tests: %d assertions; analyzer/scope ', ...
    'violations %d/%d; PASS=%d.\n'], assertion_count, analyzer_count, ...
    scope_violation_count, technical_pass);
fprintf('Stage8 stable code identity: %s\n', ...
    identity.stage8_stable_code_identity_hash);
if analyzer_count > 0
    disp(analyzer_table);
end
if scope_violation_count > 0
    disp(scope_table);
end
assert(technical_pass, 'run_stage8_0_contract_unit_tests:Failed', ...
    'At least one Stage8.0 code-only gate failed.');
report = struct('summary', summary, 'tests', tests, ...
    'code_analyzer_table', analyzer_table, 'scope_table', scope_table, ...
    'identity', identity, 'formal_calibration_file_count', 0, ...
    'formal_validation_file_count', 0, 'formal_holdout_file_count', 0);
clear path_cleanup
end

function [analyzer_count, table_out] = code_analyzer_local(step_dir)
files = dir(fullfile(step_dir, '**', '*.m'));
messages_by_file = cell(numel(files), 1);
for file_index = 1:numel(files)
    path_now = fullfile(files(file_index).folder, files(file_index).name);
    messages_by_file{file_index} = checkcode(path_now, '-id');
end
analyzer_count = sum(cellfun(@numel, messages_by_file));
if analyzer_count == 0
    table_out = table();
    return;
end
file_column = strings(analyzer_count, 1);
line_column = zeros(analyzer_count, 1);
id_column = strings(analyzer_count, 1);
message_column = strings(analyzer_count, 1);
row_index = 0;
for file_index = 1:numel(files)
    path_now = fullfile(files(file_index).folder, files(file_index).name);
    messages = messages_by_file{file_index};
    for message_index = 1:numel(messages)
        row_index = row_index + 1;
        file_column(row_index) = string(path_now);
        line_column(row_index) = messages(message_index).line;
        id_column(row_index) = string(messages(message_index).id);
        message_column(row_index) = string(messages(message_index).message);
    end
end
table_out = table(file_column, line_column, id_column, message_column, ...
    'VariableNames', {'file','line','message_id','message'});
end

function [violation_count, table_out] = scope_scan_local(step_dir)
files = dir(fullfile(step_dir, 'common', '**', '*.m'));
forbidden = ["spatialphasefactor = 2";"fixed ridge";"score_gap"; ...
    "group_unidentifiable";"chi2inv";"truth-dependent"; ...
    "holdout-dependent"];
maximum_rows = numel(files) * numel(forbidden);
file_column = strings(maximum_rows, 1);
token_column = strings(maximum_rows, 1);
actual_count_column = zeros(maximum_rows, 1);
row_index = 0;
for file_index = 1:numel(files)
    path_now = fullfile(files(file_index).folder, files(file_index).name);
    text_now = lower(string(fileread(path_now)));
    for token_index = 1:numel(forbidden)
        occurrences = numel(strfind(char(text_now), ...
            char(forbidden(token_index))));
        if occurrences > 0
            row_index = row_index + 1;
            file_column(row_index) = string(path_now);
            token_column(row_index) = forbidden(token_index);
            actual_count_column(row_index) = occurrences;
        end
    end
end
violation_count = row_index;
if violation_count == 0
    table_out = table();
else
    table_out = table(file_column(1:row_index), token_column(1:row_index), ...
        actual_count_column(1:row_index), 'VariableNames', ...
        {'file','token','actual_count'});
end
end
