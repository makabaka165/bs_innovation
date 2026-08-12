function result = test_stage8_k2_mc_rotated_beam_layout(fixture, ~)
%TEST_STAGE8_K2_MC_ROTATED_BEAM_LAYOUT Check common beam rotation.
reference = fixture.bundles(1,1).pool;
max_error = 0;
for index = 1:fixture.center_count
    center = fixture.centers(index);
    pool = fixture.bundles(index,1).pool;
    expected = reference.azimuth_beam_deg + center.rotation_delta_deg;
    max_error = max(max_error, max(abs(pool.azimuth_beam_deg - expected)));
end
pass = max_error <= 1e-12;
assert(pass, 'test_stage8_k2_mc_rotated_beam_layout:Failed');
result = struct('pass',pass,'max_beam_rotation_error_deg',max_error);
end
