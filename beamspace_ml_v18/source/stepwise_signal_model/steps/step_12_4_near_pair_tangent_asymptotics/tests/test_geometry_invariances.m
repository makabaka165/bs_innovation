function table_out = test_geometry_invariances(~, evidence)
%TEST_GEOMETRY_INVARIANCES Verify unitary, scale, and phase-gauge cases.

table_out = evidence.invariance_table;
assert(height(table_out) == 12 && all(table_out.pass_flag), ...
    'test_geometry_invariances:Failed', ...
    'A registered geometry invariance failed.');
end
