function table_out = test_fim_data_processing_inequality(context)
%TEST_FIM_DATA_PROCESSING_INEQUALITY Check subset-parent-element PSD order.

scenario_indices = context.design_indices(1:8);
minimum_eigenvalues = zeros(numel(scenario_indices), 1);
for index = 1:numel(scenario_indices)
    scenario_index = scenario_indices(index);
    scenario = context.scenarios(scenario_index);
    [subset_fim, ~] = stage7_subset_fim_for_scenario( ...
        context, scenario_index, 14, 14);
    minimum_eigenvalues(index) = min([ ...
        min(real(eig(scenario.F_parent - subset_fim.F, 'vector'))), ...
        min(real(eig(scenario.F_element - scenario.F_parent, 'vector')))]);
end
scale = max(arrayfun(@(s) norm(s.F_element, 2), ...
    context.scenarios(scenario_indices)));
tolerance = 4096 * 4 * eps * scale;
table_out = stage7_test_table(string({context.scenarios(scenario_indices).scenario_id}), ...
    -minimum_eigenvalues, tolerance, minimum_eigenvalues >= -tolerance);
end
