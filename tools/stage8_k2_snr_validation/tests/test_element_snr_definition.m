function result = test_element_snr_definition(context)
%TEST_ELEMENT_SNR_DEFINITION Verify original labels are expected element SNR.

fixture = stage8_k2_snr_test_fixture(context);
errors = zeros(context.constants.trial_count, 1);
for index = 1:numel(fixture.original_metrics)
    errors(index) = abs( ...
        fixture.original_metrics{index}.element_snr_expected_db - ...
        context.original_registry.snr_db(index));
end
assert(max(errors) <= context.constants.snr_db_tolerance, ...
    'test_element_snr_definition:Tolerance', ...
    'Original expected element SNR does not equal its numeric label.');
result = struct('pass', true, 'max_error_db', max(errors));
end
