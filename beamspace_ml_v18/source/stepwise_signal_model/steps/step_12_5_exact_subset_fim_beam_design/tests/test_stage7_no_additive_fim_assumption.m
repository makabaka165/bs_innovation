function table_out = test_stage7_no_additive_fim_assumption(context)
%TEST_STAGE7_NO_ADDITIVE_FIM_ASSUMPTION Demonstrate nonadditivity after nuisance elimination.

manifold = build_stage7_element_manifold([8,10], ...
    context.plan.pool, context.cfg);
[S, ~] = construct_deterministic_source_matrix(1, 4, 0, 0, 0, 'K1');
noise = context.noise_models{2};
channels = [8,13,18];
model = build_exact_subset_model(context.plan.pool, channels, noise, struct());
raw_G = context.plan.pool.W0' * manifold.A;
raw_daz = context.plan.pool.W0' * manifold.dA_az;
raw_del = context.plan.pool.W0' * manifold.dA_el;
combined = effective_deterministic_fim( ...
    model.T_I * raw_G(channels, :), struct( ...
    'azimuth', model.T_I * raw_daz(channels, :), ...
    'elevation', model.T_I * raw_del(channels, :)), S, 1, struct());
additive = zeros(2);
for index = 1:numel(channels)
    one = build_exact_subset_model(context.plan.pool, channels(index), noise, struct());
    fim = effective_deterministic_fim(one.T_I * raw_G(channels(index), :), ...
        struct('azimuth', one.T_I * raw_daz(channels(index), :), ...
        'elevation', one.T_I * raw_del(channels(index), :)), S, 1, struct());
    additive = additive + fim.F;
end
difference = norm(combined.F - additive, 'fro') / norm(combined.F, 'fro');
table_out = stage7_test_table("NONADDITIVE_NUISANCE_FIM", ...
    difference, 0.5, difference > 0.5);
end
