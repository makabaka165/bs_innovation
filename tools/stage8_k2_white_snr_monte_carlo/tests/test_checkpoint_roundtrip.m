function result = test_checkpoint_roundtrip(fixture)
%TEST_CHECKPOINT_ROUNDTRIP Verify atomic write, validation, load, and skip.

root = tempname;
mkdir(root);
mkdir(fullfile(root, 'checkpoints'));
cleanup = onCleanup(@() cleanup_local(root));
spec = fixture.registry(1, :);
[trial, metrics] = stage8_k2_mc_generate_trial(spec, fixture.context);
snr_row = stage8_k2_mc_snr_row(spec, trial, metrics);
methods = stage8_k2_mc_test_method_rows(spec);
[written, path_now] = stage8_k2_mc_checkpoint_write(root, spec, trial, ...
    snr_row, methods, fixture.context, fixture.registry_hash, 1.25);
loaded = stage8_k2_mc_checkpoint_load(path_now, spec, ...
    fixture.context, fixture.registry_hash);
scan = stage8_k2_mc_scan_checkpoints(root, spec, ...
    fixture.context, fixture.registry_hash);
assert(scan.completed_count == 1 && scan.remaining_count == 0 && ...
        strcmp(written.scientific_hash, loaded.scientific_hash) && ...
        ~isfile([path_now, '.tmp']), ...
    'test_checkpoint_roundtrip:RoundTrip', ...
    'Checkpoint write/load/scan did not preserve one valid checkpoint.');
result = struct('pass', true, 'valid_checkpoint_count', 1, ...
    'skip_count_on_restart', 1, ...
    'scientific_hash', string(loaded.scientific_hash));
clear cleanup
cleanup_local(root);
end

function cleanup_local(root)
if isfolder(root)
    rmdir(root, 's');
end
end
