function result = test_stage8_k2_mc_center_adapter(fixture, ~)
%TEST_STAGE8_K2_MC_CENTER_ADAPTER Validate all lightweight adapters.
pass = true;
max_error = 0;
for noise_index = 1:numel(fixture.noise_profile_ids)
    provider = fixture.providers(noise_index);
    for center_index = 1:fixture.center_count
        info = stage8_k2_mc_validate_center_adapter( ...
            fixture.adapters(center_index,noise_index),provider, ...
            fixture.bundles(center_index,noise_index));
        pass = pass && info.pass;
        max_error = max(max_error, ...
            fixture.adapters(center_index,noise_index).certification_max_G_relative_error);
    end
end
assert(pass, 'test_stage8_k2_mc_center_adapter:Failed');
result = struct('pass',pass,'adapter_count', ...
    fixture.center_count*numel(fixture.noise_profile_ids), ...
    'max_G_error',max_error);
end
