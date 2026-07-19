function result = test_calibration_resume_hash_mismatch_fails()
%TEST_CALIBRATION_RESUME_HASH_MISMATCH_FAILS Refuse stale checkpoint.

fixture = build_stage8_1a_mini_fixture();
cell_input = build_stage8_1a_mini_cell(fixture, 2);
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
checkpoint = fullfile(folder, 'cell.mat');
opts = options_local(checkpoint);
run_stage8_1_calibration_cell(cell_input, fixture.domain, ...
    fixture.registry, fixture.stage5_locked, opts);
before_hash = stage8_sha256_file(checkpoint);
cell_input.source_identity = 'CHANGED_SOURCE_IDENTITY';
stage8_assert_error(@() run_stage8_1_calibration_cell( ...
    cell_input, fixture.domain, fixture.registry, fixture.stage5_locked, ...
    opts), 'run_stage8_1_calibration_cell:CheckpointIdentityMismatch');
after_hash = stage8_sha256_file(checkpoint);
pass = strcmp(before_hash, after_hash);
assert(pass, 'test_calibration_resume_hash_mismatch_fails:Failed', ...
    'A mismatched checkpoint was overwritten.');
result = table(pass, 'VariableNames', {'pass_flag'});
clear cleanup
end

function opts = options_local(checkpoint)
opts = struct('Bboot_per_cell', 2, 'checkpoint_path', checkpoint, ...
    'fit_callback', @stage8_1a_mock_fit_callback, ...
    'initialization_callback', @stage8_1a_mini_initialization_callback);
end
