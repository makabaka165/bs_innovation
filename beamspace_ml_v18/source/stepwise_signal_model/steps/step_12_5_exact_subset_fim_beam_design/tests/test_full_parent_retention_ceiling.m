function table_out = test_full_parent_retention_ceiling(context)
%TEST_FULL_PARENT_RETENTION_CEILING Verify the registered parent upper ceiling.

family = context.plan.subset_family;
row = family(family.elevation_mask_integer == 31 & ...
    family.azimuth_mask_integer == 31, :);
[summary, ~] = evaluate_stage7_subset(row, context, struct());
parent_eta = [context.scenarios(context.design_indices).eta_parent].';
expected = min(parent_eta(isfinite(parent_eta)));
match_error = abs(summary.eta_design - expected);
upper_excess = max(0, summary.eta_design - 1);
metric = [match_error;upper_excess];
table_out = stage7_test_table(["PARENT_MATCH";"ELEMENT_CEILING"], ...
    metric, [1e-12;1e-10], metric <= [1e-12;1e-10]);
end
