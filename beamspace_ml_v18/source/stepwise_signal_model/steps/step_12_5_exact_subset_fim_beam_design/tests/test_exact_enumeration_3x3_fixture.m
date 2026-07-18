function table_out = test_exact_enumeration_3x3_fixture(context)
%TEST_EXACT_ENUMERATION_3X3_FIXTURE Exhaust a 49-rectangle physical fixture.

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
metric = [height(enumeration) - 49;isempty(feasible); ...
    numel(unique(enumeration.subset_id)) - 49];
table_out = stage7_test_table( ...
    ["ENUMERATED_49";"FEASIBLE_EXISTS";"UNIQUE_49"], ...
    abs(metric), zeros(3, 1), metric == 0);
end
