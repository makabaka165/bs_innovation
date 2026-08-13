function result = test_stage8_k2_tfbc_registered_index(fixture)
%TEST_STAGE8_K2_TFBC_REGISTERED_INDEX Verify exact O(1) indexing.

provider = fixture.identities(1).provider_timed;
points = fixture.context.plan.local_domain.candidate_points_deg;
indices = stage8_k2_tfbc_registered_indices(points, provider);
off_grid_rejected = false;
try
    stage8_k2_tfbc_registered_indices(points(1, :) + [0.01, 0], provider);
catch exception
    off_grid_rejected = strcmp(exception.identifier, ...
        'stage8_k2_tfbc_registered_indices:OffGrid');
end
pass = numel(unique(indices)) == 21 && all(indices >= 1) && ...
    all(indices <= 21) && off_grid_rejected;
assert(pass, 'test_stage8_k2_tfbc_registered_index:Failed');
result = struct('pass',pass, 'index_count',numel(indices), ...
    'off_grid_rejected',off_grid_rejected);
end
