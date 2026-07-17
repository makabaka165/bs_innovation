function table_out = test_stage6_higher_directional_derivatives(~, evidence)
%TEST_STAGE6_HIGHER_DIRECTIONAL_DERIVATIVES Verify second/third derivatives.

table_out = evidence.higher_derivative_table;
assert(all(table_out.pass_flag) && all(table_out.derivative_unit == "per_radian"), ...
    'test_stage6_higher_directional_derivatives:Failed', ...
    'A registered higher-directional-derivative case failed.');
end
