function result = test_real_primary_correlated_mean_identity(fixture)
%TEST_REAL_PRIMARY_CORRELATED_MEAN_IDENTITY Check correlated PRIMARY cells.

result = verify_stage8_1a5_real_mean_cases(fixture, ...
    'PRIMARY_RECT_E14_A31', 'STAGE5_TOEPLITZ_CORRELATED');
end
