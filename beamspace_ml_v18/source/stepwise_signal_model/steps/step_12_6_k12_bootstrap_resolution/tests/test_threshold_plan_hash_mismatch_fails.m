function result = test_threshold_plan_hash_mismatch_fails()
%TEST_THRESHOLD_PLAN_HASH_MISMATCH_FAILS Reject another Stage8 plan.

[artifact, contract] = build_stage8_1a_threshold_fixture("MINI_PRIMARY");
contract.stage8_plan_hash = 'OTHER_STAGE8_PLAN';
stage8_assert_error(@() lookup_locked_lrt_threshold( ...
    'MINI_PRIMARY', artifact, contract), ...
    'lookup_locked_lrt_threshold:ProvenanceMismatch');
pass = true;
result = table(pass, 'VariableNames', {'pass_flag'});
end
