function small = stage7_small_fim_context(context, scenario_count)
%STAGE7_SMALL_FIM_CONTEXT Return a deterministic design-only test fixture.

indices = context.design_indices(1:scenario_count);
small = context;
small.scenarios = context.scenarios(indices);
small.scenario_table = context.scenario_table(indices, :);
small.design_indices = 1:scenario_count;
small.validation_indices = 1:scenario_count;
small.holdout_indices = 1:scenario_count;
for index = 1:scenario_count
    small.scenarios(index).data_split = 'DESIGN';
end
end
