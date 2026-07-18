function table_out = test_fim_output_basis_invariance(context)
%TEST_FIM_OUTPUT_BASIS_INVARIANCE Verify invertible output reparameterization.

scenario_index = context.design_indices(3);
scenario = context.scenarios(scenario_index);
channels = [7,8,9,12,13,14,17,18,19];
model = build_exact_subset_model(context.plan.pool, channels, ...
    context.noise_models{scenario.noise_index}, struct());
G_raw = scenario.raw_G0(channels, :);
dG_raw_az = scenario.raw_dG0_az(channels, :);
dG_raw_el = scenario.raw_dG0_el(channels, :);
original = effective_deterministic_fim(model.T_I * G_raw, struct( ...
    'azimuth', model.T_I * dG_raw_az, ...
    'elevation', model.T_I * dG_raw_el), scenario.S, 1, struct());
R = diag(1 + (1:numel(channels)) / 20) + ...
    diag(0.05 * ones(numel(channels) - 1, 1), 1);
C_new = R' * model.C_I * R;
T_new = build_psd_whitener(C_new, struct());
changed = effective_deterministic_fim(T_new * R' * G_raw, struct( ...
    'azimuth', T_new * R' * dG_raw_az, ...
    'elevation', T_new * R' * dG_raw_el), scenario.S, 1, struct());
error_value = norm(changed.F - original.F, 'fro') / norm(original.F, 'fro');
table_out = stage7_test_table("INVERTIBLE_OUTPUT_BASIS", ...
    error_value, 1e-9, error_value <= 1e-9);
end
