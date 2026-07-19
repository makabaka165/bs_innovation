function result = test_cell_resolves_correct_noise_model(registry)
%TEST_CELL_RESOLVES_CORRECT_NOISE_MODEL Resolve all four model objects.

if nargin < 1
    registry = build_stage8_measurement_registry(sim_cfg(), struct());
end
pass = true;
for row_index = 1:height(registry.table)
    row = registry.table(row_index, :);
    model = resolve_stage8_measurement_model(registry, ...
        row.measurement_config_id, row.noise_profile_id);
    pass = pass && string(model.model_key) == row.model_key && ...
        string(model.fixed_measurement_hash) == row.fixed_measurement_hash && ...
        strcmp(model.noise_profile_id, char(row.noise_profile_id));
end
assert(pass, 'test_cell_resolves_correct_noise_model:Failed', ...
    'A config/noise cell resolved the wrong measurement model.');
result = table(pass, height(registry.table), ...
    'VariableNames', {'pass_flag','model_count'});
end
