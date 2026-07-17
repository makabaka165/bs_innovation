function [result_table, context] = test_elevation_group_interfaces(cfg, el_beam_deg)
%TEST_ELEVATION_GROUP_INTERFACES Validate mapping and fixed-manifold derivative.

Zel = reshape(complex(1:24, 25:48), [3, 4, 2]);
[Zemmv, mapping, stack_info] = stack_elevation_mmv_data( ...
    struct('Zel', Zel, 'phase_factor', 1), struct());
stack_error = norm(Zemmv - reshape(Zel, 3, 8), 'fro');
expected_azimuth = repmat((1:4).', 2, 1);
expected_snapshot = repelem((1:2).', 4);
mapping_error_count = nnz(mapping.azimuth_column ~= expected_azimuth) + ...
    nnz(mapping.snapshot_index ~= expected_snapshot) + ...
    nnz(mapping.stacked_column ~= (1:8).');

[~, V] = form_elevation_dbf_cube( ...
    zeros(cfg.arr.Nel, cfg.beam.subNaz), el_beam_deg, cfg);
[T, whitening_info] = build_psd_whitener(V' * V);
model = struct('V', V, 'whitener', T, ...
    'z_el_m', (0:cfg.arr.Nel - 1).' * cfg.arr.dz, ...
    'lambda', cfg.arr.lambda, 'phase_factor', 1, ...
    'model_id', 'interface_derivative_check');
eta_deg = [9.3, 11.1];
[Ge, dGe, manifold_info] = build_elevation_group_manifold( ...
    eta_deg, model, struct());
h_rad = 2 ^ (-18);
dGe_fd = complex(zeros(size(dGe)));
for q = 1:numel(eta_deg)
    eta_plus = eta_deg;
    eta_minus = eta_deg;
    eta_plus(q) = eta_plus(q) + rad2deg(h_rad);
    eta_minus(q) = eta_minus(q) - rad2deg(h_rad);
    Gplus = build_elevation_group_manifold(eta_plus, model, struct());
    Gminus = build_elevation_group_manifold(eta_minus, model, struct());
    dGe_fd(:, q) = (Gplus(:, q) - Gminus(:, q)) / (2 * h_rad);
end
derivative_relative_error = norm(dGe - dGe_fd, 'fro') / norm(dGe, 'fro');
fixed_projection_error = norm(Ge - T * (V' * ...
    exp(1j * 2 * pi / cfg.arr.lambda * model.z_el_m * sind(eta_deg))), 'fro') / ...
    norm(Ge, 'fro');

case_name = ["mmv_stack_order"; "mmv_column_mapping"; ...
    "fixed_whitened_manifold"; "per_radian_derivative"];
metric_value = [stack_error; mapping_error_count; ...
    fixed_projection_error; derivative_relative_error];
registered_threshold = [0; 0; 5e-13; 5e-8];
pass_flag = metric_value <= registered_threshold;
phase_factor = ones(size(metric_value));
result_table = table(case_name, metric_value, registered_threshold, ...
    pass_flag, phase_factor);
assert(all(pass_flag), 'test_elevation_group_interfaces:Failed', ...
    'An elevation-group public-interface gate failed.');

context = struct();
context.mapping = mapping;
context.stack_info = stack_info;
context.manifold_info = manifold_info;
context.whitening_info = whitening_info;
context.derivative_relative_error = derivative_relative_error;
context.fixed_projection_error = fixed_projection_error;
end
