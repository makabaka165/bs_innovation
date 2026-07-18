function table_out = test_stage7_selection_matrix(context)
%TEST_STAGE7_SELECTION_MATRIX Verify canonical rectangle selection.

pool = context.plan.pool;
channels = [2,4,7,9,17,19];
selection = sparse(1:numel(channels), channels, 1, ...
    numel(channels), size(pool.W0, 2));
error_value = norm(pool.W0(:, channels) - pool.W0 * selection', 'fro');
table_out = stage7_test_table("SELECTION_MATRIX", error_value, 0, ...
    error_value == 0);
end
