function tests = test_continuous_refinement_monotonicity
%TEST_CONTINUOUS_REFINEMENT_MONOTONICITY R1 F1 monotonic score fixture.
tests = functiontests(localfunctions);
end

function test_available_starts_never_decrease_score(testCase)
repo_dir = repository_root_local();
addpath(fullfile(repo_dir, 'tools', 'stage8_r1_continuous_decisive', 'matlab'));
context = stage8_r1_context(repo_dir, false);
fixtures = stage8_r1_build_registry(context, 'R2');
[~, diagnostics] = stage8_r1_evaluate_trial(fixtures(1, :), context);
audit = diagnostics.optimizer_audit;
available = [audit.initialization_available_flag];
initial = [audit.initial_score];
final = [audit.final_score];
scored = available & isfinite(initial) & isfinite(final);
verifyEqual(testCase, [audit.monotonicity_violation_count], ...
    zeros(size(audit)));
verifyGreaterThanOrEqual(testCase, final(scored), ...
    initial(scored) - 64 * eps(max(1, max(abs(initial(scored)))));
end

function root = repository_root_local()
[status, output] = system('git rev-parse --show-toplevel');
assert(status == 0);
root = strtrim(output);
end
