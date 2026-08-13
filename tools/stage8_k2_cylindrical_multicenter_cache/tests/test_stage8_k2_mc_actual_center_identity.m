function result = test_stage8_k2_mc_actual_center_identity(fixture, ~)
%TEST_STAGE8_K2_MC_ACTUAL_CENTER_IDENTITY Check center placement uniqueness.
counts = zeros(1,numel(fixture.noise_profile_ids));
for noise_index = 1:numel(fixture.noise_profile_ids)
    % The explicit loop avoids relying on struct-to-string conversion.
    values = strings(fixture.center_count,1);
    for center_index = 1:fixture.center_count
        values(center_index) = string( ...
            fixture.bundles(center_index,noise_index).identity.actual_center_hash);
    end
    counts(noise_index) = numel(unique(values));
end
pass = all(counts == fixture.center_count);
assert(pass, 'test_stage8_k2_mc_actual_center_identity:Failed');
result = struct('pass',pass,'unique_counts',counts);
end
