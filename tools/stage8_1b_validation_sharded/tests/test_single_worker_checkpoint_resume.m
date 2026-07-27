function result = test_single_worker_checkpoint_resume()
%TEST_SINGLE_WORKER_CHECKPOINT_RESUME Valid checkpoints are skip-only.

[protocol, checkpoint, expected_rows] = build_checkpoint_fixture();
root = tempname;
mkdir(root);
cleanup = onCleanup(@() rmdir(root, 's'));
path_now = fullfile(root, 'K1V_TEST_T0001.mat');
save(path_now, 'checkpoint', '-mat');
first = stage8_1b_validate_checkpoint(path_now, protocol, expected_rows);
before_hash = stage8_sha256_file(path_now);
second = stage8_1b_validate_checkpoint(path_now, protocol, expected_rows);
after_hash = stage8_sha256_file(path_now);
assert(first.valid && second.valid);
assert(strcmp(first.content_hash, second.content_hash));
assert(strcmp(before_hash, after_hash));
result = struct('pass', true, 'skipped_valid_checkpoint_count', 1, ...
    'content_hash', first.content_hash);
clear cleanup
end
