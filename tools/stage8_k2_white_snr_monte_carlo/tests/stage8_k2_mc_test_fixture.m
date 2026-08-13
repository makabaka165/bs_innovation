function fixture = stage8_k2_mc_test_fixture(context)
%STAGE8_K2_MC_TEST_FIXTURE Cache the complete deterministic registry.

persistent cached cached_hash
if ~isempty(cached) && strcmp(cached_hash, context.context_hash)
    fixture = cached;
    return;
end
registry = stage8_k2_mc_build_registry(context);
cached = struct('context', context, 'registry', registry, ...
    'registry_hash', stage8_k2_mc_stable_hash('REGISTRY', registry));
cached_hash = context.context_hash;
fixture = cached;
end
