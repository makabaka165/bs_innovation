function result = test_stage8_k2_tfbc_72_trial_semantics(runtime_root)
%TEST_STAGE8_K2_TFBC_72_TRIAL_SEMANTICS Verify formal correctness output.

path_now = fullfile(runtime_root, 'correctness', 'correctness_output.mat');
loaded = load(path_now, 'output');
output = loaded.output;
pass = output.trial_count == 72 && output.semantic_pass_count == 72 && ...
    strcmp(output.full_checksum_status, 'FULL_CHECKSUM_72_OF_72_MATCH') && ...
    strcmp(output.trajectory_status, 'FULL_TRAJECTORY_72_OF_72_MATCH');
assert(pass, 'test_stage8_k2_tfbc_72_trial_semantics:Failed');
result = struct('pass',pass, 'trial_count',output.trial_count, ...
    'semantic_pass_count',output.semantic_pass_count);
end
