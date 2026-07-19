function result = test_cross_noise_cells_use_distinct_fixed_measurement_hash( ...
    registry)
%TEST_CROSS_NOISE_CELLS_USE_DISTINCT_FIXED_MEASUREMENT_HASH Check identities.

if nargin < 1
    registry = build_stage8_measurement_registry(sim_cfg(), struct());
end
configs = unique(registry.table.measurement_config_id);
pass = true;
for config_index = 1:numel(configs)
    hashes = registry.table.fixed_measurement_hash( ...
        registry.table.measurement_config_id == configs(config_index));
    pass = pass && numel(unique(hashes)) == 2;
end
assert(pass, ...
    'test_cross_noise_cells_use_distinct_fixed_measurement_hash:Failed', ...
    'WHITE and correlated cells share a fixed measurement hash.');
result = table(pass, 'VariableNames', {'pass_flag'});
end
