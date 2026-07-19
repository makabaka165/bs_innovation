function result = test_shard_and_full_cell_input_hash_match()
%TEST_SHARD_AND_FULL_CELL_INPUT_HASH_MATCH Check shard-independent identity.

fixture = build_stage8_1a_mini_fixture();
plan = build_stage8_1a_mini_calibration_plan(fixture, 3);
args = {plan, fixture.domain, fixture.registry, fixture.stage5_locked};
[full_cells, ~] = materialize_stage8_calibration_cells(args{:}, struct( ...
    'cell_indices', (1:3).', 'source_identity', 'HASH_TEST_SOURCE'));
[shard_cell, ~] = materialize_stage8_calibration_cells(args{:}, struct( ...
    'formal_run', true, 'materialization_mode', 'FORMAL_SHARD', ...
    'cell_indices', 2, 'source_identity', 'HASH_TEST_SOURCE'));
pass = strcmp(full_cells(2).cell_input_hash, shard_cell.cell_input_hash);
assert(pass, 'test_shard_and_full_cell_input_hash_match:Failed', ...
    'A cell input hash changed with shard size or ordering.');
result = table(pass, string(shard_cell.cell_input_hash), ...
    'VariableNames', {'pass_flag','cell_input_hash'});
end
