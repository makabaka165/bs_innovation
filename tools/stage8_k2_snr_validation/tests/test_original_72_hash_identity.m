function result = test_original_72_hash_identity(context)
%TEST_ORIGINAL_72_HASH_IDENTITY Require exact evidence-31 reconstruction.

fixture = stage8_k2_snr_test_fixture(context);
hashes = strings(context.constants.trial_count, 1);
for index = 1:numel(fixture.original_trials)
    trial = fixture.original_trials{index};
    assert(trial.element_hash_match_flag, ...
        'test_original_72_hash_identity:Mismatch', ...
        'An original trial hash does not match evidence 31.');
    hashes(index) = trial.element_trial_hash;
end
assert(numel(unique(hashes)) == context.constants.trial_count, ...
    'test_original_72_hash_identity:Unique', ...
    'Original trial hashes must contain 72 unique identities.');
result = struct('pass', true, 'matched_count', numel(hashes));
end
