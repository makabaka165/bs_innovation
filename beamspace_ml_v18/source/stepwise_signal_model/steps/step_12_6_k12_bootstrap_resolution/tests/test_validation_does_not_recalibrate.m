function result = test_validation_does_not_recalibrate()
%TEST_VALIDATION_DOES_NOT_RECALIBRATE Scan the validation execution path.

source = lower(fileread(which('run_stage8_1_k1_validation')));
forbidden = 'calibrate_global_bootstrap_threshold';
pass = ~contains(source, forbidden) && ...
    contains(source, 'validate_stage8_locked_threshold_set') && ...
    contains(source, 'threshold_modification_flag'', false');
assert(pass, 'test_validation_does_not_recalibrate:Failed', ...
    'The K1 validation runner can recalibrate or mutate q_global.');
result = table(pass, 'VariableNames', {'pass_flag'});
end
