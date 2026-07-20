function result = test_real_primary_white_mean_identity(fixture)
%TEST_REAL_PRIMARY_WHITE_MEAN_IDENTITY Check two real PRIMARY/WHITE cells.

result = verify_stage8_1a5_real_mean_cases( ...
    fixture, 'PRIMARY_RECT_E14_A31', 'WHITE');
end
