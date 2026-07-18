function table_out = test_fim_nested_subset_monotonicity(context)
%TEST_FIM_NESTED_SUBSET_MONOTONICITY Check exact nested subset order.

scenario_index = context.design_indices(5);
scenario = context.scenarios(scenario_index);
[F_small, ~] = stage7_subset_fim_for_scenario(context, scenario_index, 14, 14);
[F_large, ~] = stage7_subset_fim_for_scenario(context, scenario_index, 31, 31);
minimum_eigenvalue = min(real(eig(F_large.F - F_small.F, 'vector')));
eta_small = relative_fim_retention(scenario.F_element, F_small.F, ...
    struct('expected_rank', 4));
eta_large = relative_fim_retention(scenario.F_element, F_large.F, ...
    struct('expected_rank', 4));
eta_difference = eta_large.eta - eta_small.eta;
scale = max(norm(F_large.F, 2), norm(F_small.F, 2));
tolerance = 4096 * 4 * eps * scale;
metric = [-minimum_eigenvalue;-eta_difference];
table_out = stage7_test_table(["FIM_PSD_ORDER";"ETA_ORDER"], ...
    metric, [tolerance;1e-12], ...
    [minimum_eigenvalue >= -tolerance;eta_difference >= -1e-12]);
end
