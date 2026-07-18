function summary = run_stage7_provenance_unit_tests()
%RUN_STAGE7_PROVENANCE_UNIT_TESTS Run only the Stage 7 contract tests.

step_dir = fileparts(mfilename('fullpath'));
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
package_dir = fileparts(fileparts(project_dir));
repo_dir = fileparts(package_dir);
old_path = path;
addpath(fullfile(step_dir, 'common'));
addpath(fullfile(step_dir, 'tests'));
cleanup = onCleanup(@() path(old_path));

tests = { ...
    'ancestor_contract', @() test_stage7_provenance_ancestor_contract(repo_dir); ...
    'clean_tree_guard', @() test_stage7_clean_tree_guard(repo_dir); ...
    'source_manifest', @() test_stage7_source_manifest_determinism(repo_dir)};
rows = cell(size(tests, 1), 1);
for index = 1:size(tests, 1)
    started = tic;
    result = tests{index, 2}();
    rows{index} = struct('test_id', string(tests{index, 1}), ...
        'assertion_count', height(result), 'runtime_sec', toc(started), ...
        'pass_flag', all(result.pass_flag));
end
summary = struct2table(vertcat(rows{:}));
fprintf('Stage 7 provenance unit tests: %d/%d PASS, %d assertions.\n', ...
    nnz(summary.pass_flag), height(summary), sum(summary.assertion_count));
disp(summary);
assert(all(summary.pass_flag), 'run_stage7_provenance_unit_tests:Failed', ...
    'At least one Stage 7 provenance unit test failed.');
clear cleanup
end
