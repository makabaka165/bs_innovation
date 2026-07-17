function summary = run_stage6_provenance_unit_tests()
%RUN_STAGE6_PROVENANCE_UNIT_TESTS Run only the stage-6.1A contract tests.

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
    'baseline_ancestry', @() test_stage6_baseline_ancestry_contract(repo_dir); ...
    'source_manifest', @() test_stage6_source_manifest_determinism(); ...
    'dependency_manifest', @() test_stage6_dependency_manifest_contract(repo_dir); ...
    'runtime_head_exclusion', @() test_stage6_stable_hash_excludes_runtime_head(repo_dir); ...
    'clean_tree_guard', @() test_stage6_clean_tree_guard(); ...
    'artifact_registry', @() test_stage6_required_artifact_registry()};
rows = cell(size(tests, 1), 1);
for index = 1:size(tests, 1)
    started = tic;
    result = tests{index, 2}();
    rows{index} = struct('test_id', string(tests{index, 1}), ...
        'assertion_count', height(result), ...
        'runtime_sec', toc(started), 'pass_flag', all(result.pass_flag));
end
summary = struct2table(vertcat(rows{:}));
fprintf('Stage 6.1A provenance unit tests: %d/%d PASS, %d assertions.\n', ...
    nnz(summary.pass_flag), height(summary), sum(summary.assertion_count));
disp(summary);
assert(all(summary.pass_flag), 'run_stage6_provenance_unit_tests:Failed', ...
    'At least one stage-6 provenance unit test failed.');
end
