function result = test_stage8_k2_mc_stage5_rotation_contract(fixture, ~)
%TEST_STAGE8_K2_MC_STAGE5_ROTATION_CONTRACT Check locked Stage5 identities.
max_delta_error = 0;
class_hashes = strings(fixture.center_count,1);
for index = 1:fixture.center_count
    center = fixture.centers(index);
    locked = fixture.bundles(index,1).stage5_locked;
    max_delta_error = max(max_delta_error,abs( ...
        locked.conventional_center_deg(1) - ...
        (fixture.spec.reference_stage5_config.conventional_center_deg(1) + ...
        center.rotation_delta_deg)));
    pass_hash = strcmp(build_stage5_configuration_hash(locked), ...
        locked.configuration_hash);
    if ~pass_hash, max_delta_error = Inf; end
    class_hashes(index) = string(locked.stage5_rotation_class_hash);
end
pass = max_delta_error <= 1e-12 && numel(unique(class_hashes)) == 1;
assert(pass, 'test_stage8_k2_mc_stage5_rotation_contract:Failed');
result = struct('pass',pass,'max_delta_error',max_delta_error);
end
