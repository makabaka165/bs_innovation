function result = test_threshold_measurement_registry_mismatch_fails()
%TEST_THRESHOLD_MEASUREMENT_REGISTRY_MISMATCH_FAILS Reject another registry.

[artifact, contract] = build_stage8_1a_threshold_fixture("MINI_PRIMARY");
contract.measurement_registry_hash = 'OTHER_MEASUREMENT_REGISTRY';
stage8_assert_error(@() lookup_locked_lrt_threshold( ...
    'MINI_PRIMARY', artifact, contract), ...
    'lookup_locked_lrt_threshold:ProvenanceMismatch');
pass = true;
result = table(pass, 'VariableNames', {'pass_flag'});
end
