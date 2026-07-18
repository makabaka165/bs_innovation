function table_out = test_fim_target_permutation(context)
%TEST_FIM_TARGET_PERMUTATION Verify target relabeling congruence.

scenario = context.scenarios(context.design_indices(1));
model = context.parent_models{scenario.noise_index};
G = model.T_I * scenario.raw_G0;
dG = struct('azimuth', model.T_I * scenario.raw_dG0_az, ...
    'elevation', model.T_I * scenario.raw_dG0_el);
original = effective_deterministic_fim(G, dG, scenario.S, 1, struct());
permuted = effective_deterministic_fim(G(:, [2,1]), struct( ...
    'azimuth', dG.azimuth(:, [2,1]), ...
    'elevation', dG.elevation(:, [2,1])), ...
    scenario.S([2,1], :), 1, struct());
expected = original.F([3,4,1,2], [3,4,1,2]);
error_value = norm(permuted.F - expected, 'fro') / norm(expected, 'fro');
table_out = stage7_test_table("TARGET_PERMUTATION", ...
    error_value, 1e-12, error_value <= 1e-12);
end
