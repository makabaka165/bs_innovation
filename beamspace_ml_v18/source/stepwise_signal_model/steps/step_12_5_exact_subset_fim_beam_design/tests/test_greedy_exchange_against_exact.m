function table_out = test_greedy_exchange_against_exact(context)
%TEST_GREEDY_EXCHANGE_AGAINST_EXACT Bound greedy by a 3x3 exact fixture.

small = stage7_small_fim_context(context, 4);
family = context.plan.subset_family;
fixture = family(family.elevation_mask_integer <= 7 & ...
    family.azimuth_mask_integer <= 7, :);
rows = cell(height(fixture), 1);
for index = 1:height(fixture)
    [rows{index}, ~] = evaluate_stage7_subset(fixture(index, :), small, struct());
end
enumeration = struct2table(vertcat(rows{:}));
eta0 = 0.5 * max(enumeration.eta_design);
feasible = enumeration(enumeration.eta_design >= eta0, :);
feasible = sortrows(feasible, {'MAC_total','B_out','subset_id'}, ...
    {'ascend','ascend','ascend'});
exact = feasible(1, :);
[greedy, ~] = greedy_exchange_exact_subset_design(eta0, small, struct( ...
    'initial_elevation_mask', 2, 'initial_azimuth_mask', 2, ...
    'available_elevation_indices', 1:3, 'available_azimuth_indices', 1:3));
metric = [greedy.MAC_total - exact.MAC_total;eta0 - greedy.eta_design; ...
    double(greedy.greedy_evaluation_count <= 0)];
pass = [metric(1) >= 0;metric(2) <= 1e-12;metric(3) == 0];
table_out = stage7_test_table( ...
    ["COST_GAP_NONNEGATIVE";"GREEDY_FEASIBLE";"EVALUATIONS_CHARGED"], ...
    metric, [Inf;1e-12;0], pass);
end
