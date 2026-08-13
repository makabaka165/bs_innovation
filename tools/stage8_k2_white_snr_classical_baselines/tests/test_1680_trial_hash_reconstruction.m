function result = test_1680_trial_hash_reconstruction(fixture)
%TEST_1680_TRIAL_HASH_RECONSTRUCTION Rebuild every scientific trial identity.

registry = fixture.registry;
context = fixture.context;
maximum_error = 0;
for index = 1:height(registry)
    [trial, ~, identity] = stage8_k2_wcb_reconstruct_trial( ...
        registry(index, :), context);
    assert(trial.element_trial_hash == registry.element_trial_hash(index) && ...
        trial.measurement_hash == registry.measurement_hash(index), ...
        'test_1680_trial_hash_reconstruction:Hash', ...
        'A reconstructed trial identity changed.');
    maximum_error = max(maximum_error, identity.white_target_error_db);
    clear trial
    if mod(index, 240) == 0
        fprintf('T2 reconstruction %d/1680\n', index);
    end
end
assert(maximum_error <= context.constants.snr_db_tolerance, ...
    'test_1680_trial_hash_reconstruction:Target', ...
    'A reconstructed white-SNR target exceeded tolerance.');
result = struct('pass', true, 'match_count', height(registry), ...
    'maximum_white_target_error_db', maximum_error);
end
