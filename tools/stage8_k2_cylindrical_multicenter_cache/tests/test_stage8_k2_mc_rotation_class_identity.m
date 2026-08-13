function result = test_stage8_k2_mc_rotation_class_identity(fixture, ~)
%TEST_STAGE8_K2_MC_ROTATION_CLASS_IDENTITY Check one class per noise identity.
hashes = strings(fixture.center_count, numel(fixture.noise_profile_ids));
for noise_index = 1:numel(fixture.noise_profile_ids)
    for center_index = 1:fixture.center_count
        hashes(center_index,noise_index) = string( ...
            fixture.bundles(center_index,noise_index).identity.rotation_class_hash);
    end
end
pass = all(arrayfun(@(index) numel(unique(hashes(:,index))) == 1, ...
    1:size(hashes,2))) && all(string({fixture.providers.rotation_class_hash})' == ...
    hashes(1,:).');
assert(pass, 'test_stage8_k2_mc_rotation_class_identity:Failed');
result = struct('pass',pass,'unique_hash_count', ...
    size(unique(hashes,'rows'),1));
end
