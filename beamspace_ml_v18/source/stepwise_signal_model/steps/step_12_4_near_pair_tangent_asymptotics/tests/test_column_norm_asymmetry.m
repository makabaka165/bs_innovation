function table_out = test_column_norm_asymmetry(~, evidence)
%TEST_COLUMN_NORM_ASYMMETRY Ensure raw and normalized conditions stay separate.

table_out = evidence.asymmetry_table;
assert(height(table_out) == 1296 && all(table_out.pass_flag), ...
    'test_column_norm_asymmetry:Failed', ...
    'Column-norm asymmetry reporting is incomplete.');
end
