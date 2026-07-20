function result = test_real_full_parent_white_mean_identity(fixture)
%TEST_REAL_FULL_PARENT_WHITE_MEAN_IDENTITY Check real parent/WHITE cells.

result = verify_stage8_1a5_real_mean_cases( ...
    fixture, 'SENSITIVITY_FULL_PARENT_5X5', 'WHITE');
end
