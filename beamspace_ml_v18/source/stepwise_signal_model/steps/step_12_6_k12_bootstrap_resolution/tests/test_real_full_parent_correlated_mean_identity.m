function result = test_real_full_parent_correlated_mean_identity(fixture)
%TEST_REAL_FULL_PARENT_CORRELATED_MEAN_IDENTITY Check correlated parent cells.

result = verify_stage8_1a5_real_mean_cases(fixture, ...
    'SENSITIVITY_FULL_PARENT_5X5', 'STAGE5_TOEPLITZ_CORRELATED');
end
