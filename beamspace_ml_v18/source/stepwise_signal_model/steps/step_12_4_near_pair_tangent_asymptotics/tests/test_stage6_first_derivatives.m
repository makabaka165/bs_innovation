function table_out = test_stage6_first_derivatives(~, evidence)
%TEST_STAGE6_FIRST_DERIVATIVES Verify analytic and stage-5 consistency.

table_out = evidence.first_derivative_table;
assert(all(table_out.pass_flag) && all(table_out.derivative_unit == "per_radian"), ...
    'test_stage6_first_derivatives:Failed', ...
    'A registered first-derivative case failed.');
end
