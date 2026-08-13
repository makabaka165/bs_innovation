function identity = stage8_k2_tecs_identity_fixture(fixture, identity_hash)
%STAGE8_K2_TECS_IDENTITY_FIXTURE Select exactly one frozen identity.

target = char(string(identity_hash));
matches = arrayfun(@(item) strcmp(item.fixed_measurement_hash, target), ...
    fixture.identities);
if nnz(matches) ~= 1
    error('stage8_k2_tecs_identity_fixture:Identity', ...
        'Exactly one frozen identity must match %s.', target);
end
identity = fixture.identities(find(matches, 1));
end
