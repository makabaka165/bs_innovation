function table_out = test_projected_metric_properties(~, evidence)
%TEST_PROJECTED_METRIC_PROPERTIES Verify projector and real metric properties.

table_out = evidence.metric_table;
assert(all(table_out.pass_flag), ...
    'test_projected_metric_properties:Failed', ...
    'A projected-Jacobian metric property failed.');
end
