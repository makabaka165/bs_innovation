function report = run_stage7_1_closure_unit_tests()
%RUN_STAGE7_1_CLOSURE_UNIT_TESTS Run code-only closure tests without results.

step_dir = fileparts(mfilename('fullpath'));
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
package_dir = fileparts(fileparts(project_dir));
repo_dir = fileparts(package_dir);
stage7_dir = fullfile(steps_dir, ...
    'step_12_5_exact_subset_fim_beam_design');
result_dir = fullfile(stage7_dir, 'results');
old_path = path;
addpath(fullfile(step_dir, 'common'));
addpath(fullfile(step_dir, 'tests'));
addpath(fullfile(stage7_dir, 'common'));
path_cleanup = onCleanup(@() path(old_path));
temporary_dir = tempname;
mkdir(temporary_dir);
temp_cleanup = onCleanup(@() remove_temp_local(temporary_dir));

tests = struct();
tests.sequential_semantics = test_sequential_3by5_semantics();
tests.alias_detection = test_method_subset_alias_detection(result_dir);
tests.minimum_cost = test_minimum_cost_feasible_set(result_dir);
tests.same_cost_dominance = test_same_cost_dominance_detection(result_dir);
tests.pareto_sensitivity = ...
    test_existing_method_pareto_sensitivity(result_dir);
tests.complexity = test_complexity_accounting_correction(result_dir);
tests.edge_plan = test_edge_diagnostic_plan_freeze(result_dir);
tests.no_algorithm_mutation = test_stage7_1_no_algorithm_mutation(repo_dir);
tests.stage7_unchanged = verify_stage7_results_unchanged(repo_dir);
[tests.stage6_frozen, tests.stage6_context] = ...
    verify_stage6_frozen_evidence(package_dir);
[tests.stage5_frozen, tests.stage5_context] = ...
    verify_stage5_frozen_results(package_dir);
[tests.step11_frozen, tests.step11_context] = ...
    verify_step11_frozen_results(package_dir);

[analyzer_count, analyzer_table] = code_analyzer_local(step_dir, stage7_dir);
if analyzer_count > 0
    disp(analyzer_table);
end
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
scope_violation_count = sum(tests.no_algorithm_mutation.actual_count);
technical_pass = all_tests_pass && analyzer_count == 0 && ...
    scope_violation_count == 0;
summary = table(assertion_count, analyzer_count, scope_violation_count, ...
    all_tests_pass, technical_pass);
writetable(summary, fullfile(temporary_dir, ...
    'stage7_1_closure_unit_test_summary.csv'));

fprintf(['Stage7.1A closure tests: %d assertions; analyzer/scope ', ...
    'violations %d/%d; PASS=%d.\n'], assertion_count, analyzer_count, ...
    scope_violation_count, technical_pass);
assert(technical_pass, 'run_stage7_1_closure_unit_tests:Failed', ...
    'At least one Stage7.1A closure gate failed.');
report = struct('summary', summary, 'tests', tests, ...
    'code_analyzer_table', analyzer_table, ...
    'temporary_output_only', true, ...
    'formal_result_file_count', 0);
clear temp_cleanup path_cleanup
end

function [count, table_out] = code_analyzer_local(step_dir, stage7_dir)
files = dir(fullfile(step_dir, '**', '*.m'));
paths = string(fullfile({files.folder}, {files.name})).';
stage7_relative = [ ...
    "run_stage7_provenance_unit_tests.m"; ...
    "tests/test_stage7_provenance_ancestor_contract.m"; ...
    "tests/test_stage7_clean_tree_guard.m"; ...
    "tests/test_stage7_source_manifest_determinism.m"; ...
    "tests/private/is_stage7_git_status_clean.m"; ...
    "tests/private/read_stage7_git_provenance.m"; ...
    "tests/private/hash_stage7_git_blob_manifest.m"; ...
    "tests/private/build_stage7_git_blob_manifest.m"; ...
    "tests/private/collect_stage7_source_scope.m"; ...
    "tests/private/build_stage7_provenance_contract.m"; ...
    "tests/private/build_stage7_locked_plan.m"; ...
    "tests/private/write_stage7_plan_artifacts.m"];
for index = 1:numel(stage7_relative)
    paths(end + 1, 1) = fullfile(stage7_dir, ...
        strrep(stage7_relative(index), '/', filesep)); %#ok<AGROW>
end
rows = cell(0, 1);
for file_index = 1:numel(paths)
    messages = checkcode(char(paths(file_index)), '-id');
    for message_index = 1:numel(messages)
        rows{end + 1, 1} = struct('file', paths(file_index), ...
            'line', messages(message_index).line, ...
            'message_id', string(messages(message_index).id), ...
            'message', string(messages(message_index).message)); %#ok<AGROW>
    end
end
count = numel(rows);
if count == 0
    table_out = table();
else
    table_out = struct2table(vertcat(rows{:}));
end
end

function remove_temp_local(path_now)
if exist(path_now, 'dir') == 7
    rmdir(path_now, 's');
end
end
