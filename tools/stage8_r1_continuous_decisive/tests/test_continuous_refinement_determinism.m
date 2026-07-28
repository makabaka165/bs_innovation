function tests = test_continuous_refinement_determinism
%TEST_CONTINUOUS_REFINEMENT_DETERMINISM R1 F2 reproducibility fixture.
tests = functiontests(localfunctions);
end

function test_fixture_is_bitwise_scientific_equal(testCase)
repo_dir = repository_root_local();
addpath(fullfile(repo_dir, 'tools', 'stage8_r1_continuous_decisive', 'matlab'));
context = stage8_r1_context(repo_dir, false);
fixtures = stage8_r1_build_registry(context, 'R2');
[left, ~] = stage8_r1_evaluate_trial(fixtures(2, :), context);
[right, ~] = stage8_r1_evaluate_trial(fixtures(2, :), context);
left = zero_runtime_local(left);
right = zero_runtime_local(right);
verifyEqual(testCase, stage8_stable_hash('R1_TEST', left), ...
    stage8_stable_hash('R1_TEST', right));
end

function rows = zero_runtime_local(rows)
names = {'runtime_sec','shared_initialization_runtime_sec', ...
    'initialization_runtime_sec','refinement_runtime_sec'};
for index = 1:numel(names), rows.(names{index})(:) = 0; end
end

function root = repository_root_local()
[status, output] = system('git rev-parse --show-toplevel');
assert(status == 0);
root = strtrim(output);
end
