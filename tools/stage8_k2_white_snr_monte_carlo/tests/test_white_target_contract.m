function result = test_white_target_contract(fixture)
%TEST_WHITE_TARGET_CONTRACT Cover every registered factor and target.

registry = fixture.registry;
selected = registry.replicate_id == 1;
specs = registry(selected, :);
errors = zeros(height(specs), 1);
for index = 1:height(specs)
    [~, metrics] = stage8_k2_mc_generate_trial( ...
        specs(index, :), fixture.context);
    errors(index) = abs(metrics.white_beam_snr_expected_db - ...
        specs.white_beamspace_snr_target_db(index));
end
assert(height(specs) == 168 && ...
    max(errors) <= fixture.context.constants.snr_db_tolerance, ...
    'test_white_target_contract:Tolerance', ...
    'The 168-factor target fixture missed a white-SNR target.');
result = struct('pass', true, 'case_count', height(specs), ...
    'max_error_db', max(errors));
end
