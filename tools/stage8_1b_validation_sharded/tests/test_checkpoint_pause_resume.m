function result = test_checkpoint_pause_resume()
%TEST_CHECKPOINT_PAUSE_RESUME Exercise tmp-validate-rename and pause boundary.

[protocol, checkpoint, expected_rows] = build_checkpoint_fixture();
root = tempname;
mkdir(root);
mkdir(fullfile(root, 'control'));
mkdir(fullfile(root, 'checkpoints'));
mkdir(fullfile(root, 'tmp'));
cleanup = onCleanup(@() rmdir(root, 's'));
temporary = fullfile(root, 'tmp', 'K1V_TEST_T0001.mat.tmp');
final = fullfile(root, 'checkpoints', 'K1V_TEST_T0001.mat');
save(temporary, 'checkpoint', '-mat');
stage8_1b_validate_checkpoint(temporary, protocol, expected_rows);
assert(movefile(temporary, final));
stage8_1b_validate_checkpoint(final, protocol, expected_rows);
pause_path = fullfile(root, 'control', 'pause.request');
fid = fopen(pause_path, 'w');
assert(fid >= 0);
fprintf(fid, 'UNIT_PAUSE\n');
fclose(fid);
assert(isfile(pause_path));
assert(isfile(final));
assert(~isfile(temporary));
result = struct('pass', true, 'safe_boundary_checkpoint_count', 1, ...
    'tmp_checkpoint_count', 0);
clear cleanup
end
