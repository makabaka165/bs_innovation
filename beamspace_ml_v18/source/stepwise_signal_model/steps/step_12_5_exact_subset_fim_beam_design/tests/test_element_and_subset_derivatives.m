function table_out = test_element_and_subset_derivatives(context)
%TEST_ELEMENT_AND_SUBSET_DERIVATIVES Check per-radian analytic derivatives.

pool = context.plan.pool;
cfg = context.cfg;
angle = [8.1, 9.9];
h = 1e-6;
center = build_stage7_element_manifold(angle, pool, cfg);
plus_az = build_stage7_element_manifold(angle + [rad2deg(h),0], pool, cfg);
minus_az = build_stage7_element_manifold(angle - [rad2deg(h),0], pool, cfg);
plus_el = build_stage7_element_manifold(angle + [0,rad2deg(h)], pool, cfg);
minus_el = build_stage7_element_manifold(angle - [0,rad2deg(h)], pool, cfg);
fd_az = (plus_az.A - minus_az.A) / (2 * h);
fd_el = (plus_el.A - minus_el.A) / (2 * h);
element_errors = [norm(fd_az - center.dA_az) / norm(center.dA_az); ...
    norm(fd_el - center.dA_el) / norm(center.dA_el)];
model = build_exact_subset_model(pool, [7,8,9,12,13,14,17,18,19], ...
    context.noise_models{2}, struct());
P = model.T_I * model.W_I';
subset_errors = [norm(P * (fd_az - center.dA_az)) / norm(P * center.dA_az); ...
    norm(P * (fd_el - center.dA_el)) / norm(P * center.dA_el)];
metric = [element_errors; subset_errors];
table_out = stage7_test_table( ...
    ["ELEMENT_AZ";"ELEMENT_EL";"SUBSET_AZ";"SUBSET_EL"], ...
    metric, 1e-6, metric <= 1e-6);
end
