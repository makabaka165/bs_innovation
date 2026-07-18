function table_out = test_stage7_rectangular_subset_count(context)
%TEST_STAGE7_RECTANGULAR_SUBSET_COUNT Verify the exact finite family.

family = context.plan.subset_family;
metric = [height(family); numel(unique(family.subset_id)); ...
    min(family.B_e); max(family.B_e); min(family.B_a); max(family.B_a)];
expected = [961;961;1;5;1;5];
table_out = stage7_test_table( ...
    ["ROW_COUNT";"UNIQUE_IDS";"MIN_BE";"MAX_BE";"MIN_BA";"MAX_BA"], ...
    abs(metric - expected), zeros(6, 1), metric == expected);
end
