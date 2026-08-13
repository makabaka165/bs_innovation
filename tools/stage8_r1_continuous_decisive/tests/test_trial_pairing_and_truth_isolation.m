function tests = test_trial_pairing_and_truth_isolation
%TEST_TRIAL_PAIRING_AND_TRUTH_ISOLATION Verify M0/M1/M2 shared input.
tests = functiontests(localfunctions);
end

function test_fixture_has_one_shared_element_hash(testCase)
repo_dir = repository_root_local();
addpath(fullfile(repo_dir, 'tools', 'stage8_r1_continuous_decisive', 'matlab'));
context = stage8_r1_context(repo_dir, false);
fixtures = stage8_r1_build_registry(context, 'R2');
[rows, diagnostics] = stage8_r1_evaluate_trial(fixtures(2, :), context);
verifyEqual(testCase, height(rows), 3);
verifyEqual(testCase, numel(unique(rows.element_trial_hash)), 1);
verifyFalse(testCase, any(rows.truth_used_in_initialization_flag));
verifyFalse(testCase, any(rows.truth_used_in_fit_flag));
verifyFalse(testCase, any(rows.truth_used_in_lrt_flag));
verifyFalse(testCase, diagnostics.truth_used_in_initialization_flag);
verifyFalse(testCase, diagnostics.truth_used_in_fit_flag);
verifyFalse(testCase, diagnostics.truth_used_in_lrt_flag);
end

function root = repository_root_local()
[status, output] = system('git rev-parse --show-toplevel');
assert(status == 0);
root = strtrim(output);
end
