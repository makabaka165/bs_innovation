function result = test_threshold_source_identity_mismatch_fails()
%TEST_THRESHOLD_SOURCE_IDENTITY_MISMATCH_FAILS Reject stale source identity.

[artifact, contract] = build_stage8_1a_threshold_fixture("MINI_PRIMARY");
contract.stage8_stable_code_identity_hash = 'OTHER_SOURCE';
stage8_assert_error(@() lookup_locked_lrt_threshold( ...
    'MINI_PRIMARY', artifact, contract), ...
    'lookup_locked_lrt_threshold:ProvenanceMismatch');
pass = true;
result = table(pass, 'VariableNames', {'pass_flag'});
end
