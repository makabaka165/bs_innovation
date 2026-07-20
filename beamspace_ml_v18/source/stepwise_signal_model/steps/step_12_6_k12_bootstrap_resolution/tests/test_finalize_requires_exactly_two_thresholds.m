function result = test_finalize_requires_exactly_two_thresholds()
%TEST_FINALIZE_REQUIRES_EXACTLY_TWO_THRESHOLDS Reject incomplete final set.

config_ids = ["MINI_PRIMARY";"MINI_PARENT"];
[thresholds, contract] = build_stage8_1a_threshold_fixture(config_ids);
stage8_assert_error(@() validate_stage8_locked_threshold_set( ...
    config_ids, thresholds(1), contract), ...
    'validate_stage8_locked_threshold_set:ThresholdCount');
pass = true;
result = table(pass, 'VariableNames', {'pass_flag'});
end
