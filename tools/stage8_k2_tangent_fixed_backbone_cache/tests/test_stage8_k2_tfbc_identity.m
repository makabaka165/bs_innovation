function result = test_stage8_k2_tfbc_identity(fixture)
%TEST_STAGE8_K2_TFBC_IDENTITY Verify validate-once and fail-closed identity.

identity = fixture.identities(1);
validation = stage8_k2_tfbc_validate_provider( ...
    identity.provider_timed, identity.model, ...
    fixture.context.plan.local_domain);
mutated = identity.provider_timed;
mutated.G_single_exact_shape(1, 1) = ...
    mutated.G_single_exact_shape(1, 1) + 1;
hash_rejected = false;
try
    stage8_k2_tfbc_validate_provider(mutated, identity.model, ...
        fixture.context.plan.local_domain);
catch exception
    hash_rejected = strcmp(exception.identifier, ...
        'stage8_k2_tfbc_validate_provider:Hash');
end
pass = strcmp(validation.status, 'VALIDATE_ONCE_COMPLETE') && hash_rejected;
assert(pass, 'test_stage8_k2_tfbc_identity:Failed');
result = struct('pass',pass, 'hash_rejected',hash_rejected, ...
    'provider_hash',validation.provider_hash);
end
