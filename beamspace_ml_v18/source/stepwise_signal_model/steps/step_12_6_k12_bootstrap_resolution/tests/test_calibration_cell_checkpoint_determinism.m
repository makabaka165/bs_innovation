function result = test_calibration_cell_checkpoint_determinism()
%TEST_CALIBRATION_CELL_CHECKPOINT_DETERMINISM Reuse matching checkpoint.

fixture = build_stage8_1a_mini_fixture();
cell_input = build_stage8_1a_mini_cell(fixture, 2);
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
checkpoint = fullfile(folder, 'cell.mat');
opts = options_local(checkpoint);
[first, first_debug] = run_stage8_1_calibration_cell( ...
    cell_input, fixture.domain, fixture.registry, fixture.stage5_locked, opts);
[second, second_debug] = run_stage8_1_calibration_cell( ...
    cell_input, fixture.domain, fixture.registry, fixture.stage5_locked, opts);
pass = ~first_debug.checkpoint_reused_flag && ...
    second_debug.checkpoint_reused_flag && ...
    strcmp(first.cell_artifact_hash, second.cell_artifact_hash);
assert(pass, 'test_calibration_cell_checkpoint_determinism:Failed', ...
    'A matching calibration checkpoint was not reused deterministically.');
result = table(pass, 'VariableNames', {'pass_flag'});
clear cleanup
end

function opts = options_local(checkpoint)
opts = struct('Bboot_per_cell', 2, 'checkpoint_path', checkpoint, ...
    'fit_callback', @stage8_1a_mock_fit_callback, ...
    'initialization_callback', @stage8_1a_mini_initialization_callback);
end
