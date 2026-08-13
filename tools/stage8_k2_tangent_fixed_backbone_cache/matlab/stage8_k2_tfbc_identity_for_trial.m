function identity = stage8_k2_tfbc_identity_for_trial(fixture, trial)
%STAGE8_K2_TFBC_IDENTITY_FOR_TRIAL Resolve one frozen provider identity.

hashes = string({fixture.identities.fixed_measurement_hash});
index = find(hashes == string(trial.model.fixed_measurement_hash), 1);
if isempty(index)
    error('stage8_k2_tfbc_identity_for_trial:Identity', ...
        'No provider matches the trial measurement identity.');
end
identity = fixture.identities(index);
end
