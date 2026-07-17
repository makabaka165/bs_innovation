function fixture = build_stage4_structural_fixture(cfg, el_beam_deg)
%BUILD_STAGE4_STRUCTURAL_FIXTURE Construct an explicit rank(Ce)<Q MMV case.

Nel = cfg.arr.Nel;
[~, V] = form_elevation_dbf_cube( ...
    zeros(Nel, cfg.beam.subNaz), el_beam_deg, cfg);
[T, whitening_info] = build_psd_whitener(V' * V);
group_model = struct('V', V, 'whitener', T, ...
    'z_el_m', (0:Nel - 1).' * cfg.arr.dz, ...
    'lambda', cfg.arr.lambda, 'phase_factor', 1, ...
    'model_id', 'stage4_structural_counterexample');
eta_true_deg = [9.5, 11.0];
[Ge_true, ~] = build_elevation_group_manifold( ...
    eta_true_deg, group_model, struct());

Nphi = 8;
L = 1;
c = exp(1j * 0.31 * (0:Nphi - 1));
Ce_true = [c; exp(1j * 0.47) * c];
Zemmv_direct = Ge_true * Ce_true;
Zel = reshape(Zemmv_direct, size(Zemmv_direct, 1), Nphi, L);
[Zemmv, mapping, stack_info] = stack_elevation_mmv_data(Zel, struct());

element_model = group_model;
element_model.V = eye(Nel);
element_model.whitener = eye(Nel);
element_model.model_id = 'vertical_element_structural_counterexample';
[Ge_element, ~] = build_elevation_group_manifold( ...
    eta_true_deg, element_model, struct());

fixture = struct();
fixture.scenario = 'structural_rank_ce_deficient_l1';
fixture.K = 2;
fixture.Q = 2;
fixture.Nphi = Nphi;
fixture.L = L;
fixture.noise_kind = 'none_structural_mmv';
fixture.noise_sigma = 0;
fixture.aperture_index = 1:Nphi;
fixture.search_grid_deg = [9.0, 9.5, 10.0, 10.5, 11.0, 11.5];
fixture.angle_gate_deg = NaN;
fixture.recovery_gate = NaN;
fixture.expected_status = 'GROUP_UNIDENTIFIABLE';
fixture.Zemmv = Zemmv;
fixture.Zsignal_mmv = Zemmv;
fixture.mapping = mapping;
fixture.stack_info = stack_info;
fixture.group_model = group_model;
fixture.Ge_true = Ge_true;
fixture.Ce_true = Ce_true;
fixture.eta_true_deg = eta_true_deg;
fixture.truth_model_relative_residual = norm(Zemmv - Ge_true * Ce_true, 'fro') / ...
    norm(Zemmv, 'fro');
fixture.whitening_info = whitening_info;
fixture.Zel_raw = V' * ...
    exp(1j * 2 * pi / cfg.arr.lambda * ...
    ((0:Nel - 1).' * cfg.arr.dz) * sind(eta_true_deg)) * Ce_true;
fixture.el_beam_deg = el_beam_deg;
fixture.Zelement_mmv = Ge_element * Ce_true;
fixture.element_mapping = mapping;
fixture.element_model = element_model;
fixture.element_whitening_info = struct('rank', Nel);
fixture.Rphi_selected = eye(Nphi);
fixture.fixture_kind = 'explicit_mmv_structural_counterexample';
end
