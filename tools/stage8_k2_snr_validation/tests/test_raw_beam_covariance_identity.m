function result = test_raw_beam_covariance_identity(context)
%TEST_RAW_BEAM_COVARIANCE_IDENTITY Verify C_I=W_I^H R_e W_I.

fixture = stage8_k2_snr_test_fixture(context);
residuals = cellfun(@(item) item.raw_covariance_residual, ...
    fixture.original_metrics);
assert(max(residuals) <= context.constants.raw_covariance_tolerance, ...
    'test_raw_beam_covariance_identity:Tolerance', ...
    'A raw sequential covariance violates the frozen identity.');
result = struct('pass', true, 'max_residual', max(residuals));
end
