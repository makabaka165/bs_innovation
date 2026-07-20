function report = run_stage8_1a5_contract_unit_tests()
%RUN_STAGE8_1A5_CONTRACT_UNIT_TESTS Run A5 backward-error regressions.

step_dir = fileparts(mfilename('fullpath'));
repo_dir = fileparts(fileparts(fileparts(fileparts(fileparts(step_dir)))));
addpath(step_dir);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
addpath(fullfile(step_dir, 'tests'));
cfg = sim_cfg();
plan = build_stage8_locked_plan(repo_dir, cfg, struct());
tests = run_stage8_1a5_test_set(plan);
names = fieldnames(tests);
assertion_count = 0;
all_tests_pass = true;
for index = 1:numel(names)
    value = tests.(names{index});
    assertion_count = assertion_count + height(value);
    all_tests_pass = all_tests_pass && all(value.pass_flag);
end
assert(all_tests_pass, 'run_stage8_1a5_contract_unit_tests:Failed', ...
    'At least one Stage8.1A5 regression failed.');
summary = table(assertion_count, all_tests_pass, ...
    string(plan.bootstrap_mean_identity_contract), ...
    string(plan.bootstrap_mean_identity_contract_hash), ...
    'VariableNames', {'assertion_count','all_tests_pass', ...
    'contract_version','contract_hash'});
fprintf('Stage8.1A5 tests: %d assertions; PASS=%d.\n', ...
    assertion_count, all_tests_pass);
report = struct('summary', summary, 'tests', tests, ...
    'stage8_plan_hash', plan.stage8_plan_hash, 'repo_dir', repo_dir);
clear path_cleanup
end
