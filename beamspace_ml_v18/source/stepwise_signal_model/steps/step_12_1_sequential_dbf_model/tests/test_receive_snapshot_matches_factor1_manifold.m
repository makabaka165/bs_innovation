function result_table = test_receive_snapshot_matches_factor1_manifold(cfg)
%TEST_RECEIVE_SNAPSHOT_MATCHES_FACTOR1_MANIFOLD Validate active input physics.

target_angles_deg = [8.7, 13.1];
source_snapshots = exp(1j * [0.0, 0.3, -0.8, 1.1]);
[~, model] = generate_receive_only_element_snapshots( ...
    target_angles_deg, source_snapshots, [], cfg);
Y = model.Y_canonical;
a1 = model.A_canonical(:, 1);
residual1 = Y - a1 * ((a1' * Y) / (a1' * a1));
factor1_orthogonal_residual = norm(residual1, 'fro') / max(norm(Y, 'fro'), eps);

array_meta = model.array_meta;
a2_legacy = build_legacy_factor2_for_test_local( ...
    array_meta.XAct, array_meta.YAct, array_meta.ZAct, ...
    target_angles_deg(1), target_angles_deg(2), cfg.arr.lambda);
a2_matrix = reshape_cyl_vector_to_matrix(a2_legacy, array_meta);
a2 = a2_matrix(:);
residual2 = Y - a2 * ((a2' * Y) / (a2' * a2));
factor2_orthogonal_residual = norm(residual2, 'fro') / max(norm(Y, 'fro'), eps);

pass_flag = factor1_orthogonal_residual < 1e-12 && ...
    factor2_orthogonal_residual > 1e-2;
phase_factor = 1;
result_table = table(target_angles_deg(1), target_angles_deg(2), ...
    factor1_orthogonal_residual, factor2_orthogonal_residual, ...
    pass_flag, phase_factor, 'VariableNames', ...
    {'az_deg','el_deg','factor1_orthogonal_residual', ...
     'legacy_factor2_orthogonal_residual','pass_flag','phase_factor'});
assert(pass_flag, 'test_receive_snapshot_matches_factor1_manifold:Failed', ...
    'Receive-only snapshots did not uniquely match the factor-1 manifold.');
end

function a = build_legacy_factor2_for_test_local(x, y, z, az_deg, el_deg, lambda)
ux = cosd(el_deg) * cosd(az_deg);
uy = cosd(el_deg) * sind(az_deg);
uz = sind(el_deg);
phase = x(:) * ux + y(:) * uy + z(:) * uz;
a = exp(1j * 2 * (2*pi/lambda) * phase);
end
