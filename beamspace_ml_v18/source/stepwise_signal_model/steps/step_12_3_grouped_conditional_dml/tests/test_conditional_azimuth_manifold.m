function [result_table, context] = test_conditional_azimuth_manifold(cfg)
%TEST_CONDITIONAL_AZIMUTH_MANIFOLD Check geometry, cos(eta), and derivatives.

array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
eta_deg = 10.0;
[Uq, bank_info] = build_fixed_conditional_azimuth_beam_bank( ...
    [7.4, 8.0, 8.6], eta_deg, array_meta, ...
    struct('lambda', cfg.arr.lambda));
X = complex(ones(cfg.beam.subNaz, 2));
prepare_opts = options_local(eta_deg, bank_info, cfg);
[~, model] = prepare_conditional_azimuth_data( ...
    X, Uq, eye(cfg.beam.subNaz), 1, prepare_opts);
candidate_deg = [7.6, 8.4];
[G, dG, info] = build_conditional_azimuth_manifold( ...
    candidate_deg, model, struct());

x = bank_info.array_coordinates(:, 1);
y = bank_info.array_coordinates(:, 2);
k0 = 2 * pi / cfg.arr.lambda;
A = complex(zeros(numel(x), 2));
for idx = 1:2
    A(:, idx) = exp(1j * k0 * cosd(eta_deg) * ...
        (x * cosd(candidate_deg(idx)) + y * sind(candidate_deg(idx))));
end
G_reference = model.Tphi_q * model.Uq' * A;
formula_error = norm(G - G_reference, 'fro') / norm(G_reference, 'fro');

h_rad = 1e-6;
dG_fd = complex(zeros(size(dG)));
for idx = 1:2
    plus = candidate_deg;
    minus = candidate_deg;
    plus(idx) = plus(idx) + rad2deg(h_rad);
    minus(idx) = minus(idx) - rad2deg(h_rad);
    G_plus = build_conditional_azimuth_manifold(plus, model, struct());
    G_minus = build_conditional_azimuth_manifold(minus, model, struct());
    dG_fd(:, idx) = (G_plus(:, idx) - G_minus(:, idx)) / (2 * h_rad);
end
derivative_error = norm(dG - dG_fd, 'fro') / norm(dG_fd, 'fro');

eta_zero = 0;
[Uzero, zero_info] = build_fixed_conditional_azimuth_beam_bank( ...
    [7.4, 8.0, 8.6], eta_zero, array_meta, ...
    struct('lambda', cfg.arr.lambda));
[~, zero_model] = prepare_conditional_azimuth_data(X, Uzero, ...
    eye(cfg.beam.subNaz), 1, options_local(eta_zero, zero_info, cfg));
G_zero = build_conditional_azimuth_manifold(candidate_deg, zero_model, struct());
cos_eta_change = norm(G - G_zero, 'fro') / norm(G_zero, 'fro');
pass_flag = formula_error < 1e-12 && derivative_error <= 1e-6 && ...
    cos_eta_change > 1e-4 && info.cos_elevation_dependence_flag && ...
    info.rank_Gphi == 2;

metric = ["full_geometry_relative_error"; ...
    "radian_derivative_relative_error"; "cos_elevation_nonzero_change"];
value = [formula_error; derivative_error; cos_eta_change];
registered_gate = [1e-12; 1e-6; 1e-4];
pass_column = [formula_error < registered_gate(1); ...
    derivative_error <= registered_gate(2); cos_eta_change > registered_gate(3)];
statistical_calibration_status = repmat("NOT_CALIBRATED_STAGE5", 3, 1);
phase_factor = ones(3, 1);
result_table = table(metric, value, registered_gate, ...
    statistical_calibration_status, pass_column, phase_factor, ...
    'VariableNames', {'metric','value','registered_gate', ...
    'statistical_calibration_status','pass_flag','phase_factor'});
assert(pass_flag, 'test_conditional_azimuth_manifold:Failed', ...
    'The conditional-azimuth manifold validation failed.');
context = struct('formula_error', formula_error, ...
    'derivative_error', derivative_error, ...
    'cos_eta_change', cos_eta_change, 'rank_Gphi', info.rank_Gphi);
end

function opts = options_local(eta_deg, info, cfg)
opts = struct('eta_condition_deg', eta_deg, ...
    'condition_source', 'DESIGN', ...
    'upstream_group_support_status', 'GROUP_REGISTERED_MODEL_CERTIFIED', ...
    'estimate_returned_flag', true, 'structural_gate_pass_flag', true, ...
    'array_coordinates', info.array_coordinates, ...
    'lambda', cfg.arr.lambda, 'beam_bank_hash', info.beam_bank_hash);
end
