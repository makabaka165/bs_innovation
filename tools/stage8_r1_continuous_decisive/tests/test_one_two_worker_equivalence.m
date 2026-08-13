function tests = test_one_two_worker_equivalence
%TEST_ONE_TWO_WORKER_EQUIVALENCE Compare completed R3 gate roots.
tests = functiontests(localfunctions);
end

function test_gate_r3_result_is_present(testCase)
runtime = fullfile('E:', 'bs_innovation_runtime', ...
    'stage8_r1_continuous_refinement_decisive_v1_f6ec19f');
path_now = fullfile(runtime, 'gates', 'gate_r3_result.json');
assumeTrue(testCase, isfile(path_now), ...
    'Run the R1 Gates action before this integration test.');
result = jsondecode(fileread(path_now));
verifyTrue(testCase, logical(result.gate_r3_pass));
verifyTrue(testCase, isfield(result, 'selected_worker_count'));
end
