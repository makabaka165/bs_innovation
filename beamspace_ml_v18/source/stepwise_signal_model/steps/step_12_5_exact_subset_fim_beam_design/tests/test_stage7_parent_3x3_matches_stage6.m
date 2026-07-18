function table_out = test_stage7_parent_3x3_matches_stage6(context)
%TEST_STAGE7_PARENT_3X3_MATCHES_STAGE6 Check the frozen center bank columnwise.

cfg = context.cfg;
pool = context.plan.pool;
[~, V] = form_elevation_dbf_cube( ...
    complex(zeros(cfg.arr.Nel, cfg.beam.subNaz)), [9.6,10.0,10.4], cfg);
[~, Uset] = form_azimuth_dbf_cube(complex(zeros(3, cfg.beam.subNaz)), ...
    [7.4,8.0,8.6], [9.6,10.0,10.4], cfg);
[W_stage6, ~] = build_sequential_beam_matrix(V, Uset, pool.array_meta);
channels = reshape((2:4).' + ((2:4) - 1) * 5, 1, []);
error_value = norm(pool.W0(:, channels) - W_stage6, 'fro') / ...
    norm(W_stage6, 'fro');
table_out = stage7_test_table("CENTER_3X3_COLUMNWISE", ...
    error_value, 1e-14, error_value <= 1e-14);
end
