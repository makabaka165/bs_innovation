function table_out = test_secant_tangent_nondegenerate(~, evidence)
%TEST_SECANT_TANGENT_NONDEGENERATE Verify every registered primary tail.

table_out = evidence.tail_table;
assert(height(table_out) == 144 && all(table_out.pass_flag), ...
    'test_secant_tangent_nondegenerate:Failed', ...
    'A registered nondegenerate asymptotic tail failed.');
end
