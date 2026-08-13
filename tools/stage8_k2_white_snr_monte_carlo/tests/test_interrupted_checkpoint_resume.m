function result = test_interrupted_checkpoint_resume(fixture)
%TEST_INTERRUPTED_CHECKPOINT_RESUME Ignore tmp and preserve valid finals.

root = tempname;
mkdir(root);
mkdir(fullfile(root, 'checkpoints'));
cleanup = onCleanup(@() cleanup_local(root));
registry = fixture.registry(1:2, :);

spec1 = registry(1, :);
[trial1, metrics1] = stage8_k2_mc_generate_trial(spec1, fixture.context);
snr1 = stage8_k2_mc_snr_row(spec1, trial1, metrics1);
methods1 = stage8_k2_mc_test_method_rows(spec1);
[checkpoint1, path1] = stage8_k2_mc_checkpoint_write(root, spec1, ...
    trial1, snr1, methods1, fixture.context, fixture.registry_hash, 1);

spec2 = registry(2, :);
temporary2 = [stage8_k2_mc_checkpoint_path(root, spec2), '.tmp'];
interrupted_fixture = struct('status', 'INTERRUPTED');
save(temporary2, 'interrupted_fixture', '-mat');
scan1 = stage8_k2_mc_scan_checkpoints(root, registry, ...
    fixture.context, fixture.registry_hash);
before_hash = stage8_k2_mc_file_sha256(path1);
assert(scan1.completed_count == 1 && scan1.tmp_count == 1 && ...
    scan1.completed_mask(1) && ~scan1.completed_mask(2), ...
    'test_interrupted_checkpoint_resume:InitialScan', ...
    'Interrupted temporary state was not ignored correctly.');

[trial2, metrics2] = stage8_k2_mc_generate_trial(spec2, fixture.context);
snr2 = stage8_k2_mc_snr_row(spec2, trial2, metrics2);
methods2 = stage8_k2_mc_test_method_rows(spec2);
stage8_k2_mc_checkpoint_write(root, spec2, trial2, snr2, methods2, ...
    fixture.context, fixture.registry_hash, 1);
scan2 = stage8_k2_mc_scan_checkpoints(root, registry, ...
    fixture.context, fixture.registry_hash);
after_hash = stage8_k2_mc_file_sha256(path1);
assert(scan2.completed_count == 2 && scan2.tmp_count == 0 && ...
        strcmp(before_hash, after_hash) && ...
        strcmp(checkpoint1.scientific_hash, ...
        scan2.checkpoints{1}.scientific_hash), ...
    'test_interrupted_checkpoint_resume:Resume', ...
    'Resume changed a valid checkpoint or failed to rerun the tmp trial.');
result = struct('pass', true, 'preserved_checkpoint_count', 1, ...
    'rerun_interrupted_trial_count', 1);
clear cleanup
cleanup_local(root);
end

function cleanup_local(root)
if isfolder(root)
    rmdir(root, 's');
end
end
