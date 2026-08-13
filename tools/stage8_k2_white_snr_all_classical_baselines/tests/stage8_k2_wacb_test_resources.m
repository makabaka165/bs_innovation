function resources = stage8_k2_wacb_test_resources(context, noise_id)
%STAGE8_K2_WACB_TEST_RESOURCES Keep at most one full dictionary in memory.

persistent cached_hash cached_noise cached_resources
noise_id = string(noise_id);
if isempty(cached_resources) || string(cached_hash) ~= ...
        string(context.context_hash) || string(cached_noise) ~= noise_id
    cached_resources = [];
    java.lang.System.gc();
    cached_resources = stage8_k2_wacb_prepare_noise_resources( ...
        context, noise_id);
    cached_hash = context.context_hash;
    cached_noise = noise_id;
end
resources = cached_resources;
end
