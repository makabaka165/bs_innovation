function fixture = build_stage4_structural_fixture(cfg, el_beam_deg)
%BUILD_STAGE4_STRUCTURAL_FIXTURE Construct an exact rank(Ce)<Q MMV case.

Nel = cfg.arr.Nel;
[~, V] = form_elevation_dbf_cube( ...
    zeros(Nel, cfg.beam.subNaz), el_beam_deg, cfg);
Nphi = 8;
L = 1;
C_row = V' * V;
C_col = eye(Nphi);
[T_row, T_col, whitening_info] = ...
    build_separable_mmv_whiteners(C_row, C_col, struct());
group_model = struct('V', V, 'whitener', T_row, ...
    'z_el_m', (0:Nel - 1).' * cfg.arr.dz, ...
    'lambda', cfg.arr.lambda, 'phase_factor', 1, ...
    'model_id', 'stage4_structural_counterexample');
eta_true_deg = [9.5, 11.0];
[Ge_true, ~] = build_elevation_group_manifold( ...
    eta_true_deg, group_model, struct());

c = exp(1j * 0.31 * (0:Nphi - 1));
Ce_true_recovery = [c; exp(1j * 0.47) * c];
Ce_true_score = Ce_true_recovery;
Az_true = exp(1j * 2 * pi / cfg.arr.lambda * ...
    ((0:Nel - 1).' * cfg.arr.dz) * sind(eta_true_deg));
Zel_raw = reshape(V' * Az_true * Ce_true_recovery, ...
    size(V, 2), Nphi, L);
prepare_opts = struct('phase_factor', 1, ...
    'observation_regime', 'NOISELESS_STRUCTURAL', ...
    'column_covariance_model', 'identity');
[data, data_info] = prepare_elevation_group_mmv_data( ...
    Zel_raw, T_row, T_col, prepare_opts);

T_element = eye(Nel);
element_model = group_model;
element_model.V = eye(Nel);
element_model.whitener = T_element;
element_model.model_id = 'vertical_element_structural_counterexample';
[element_data, element_data_info] = prepare_elevation_group_mmv_data( ...
    reshape(Az_true * Ce_true_recovery, Nel, Nphi, L), ...
    T_element, T_col, prepare_opts);

fixture = struct();
fixture.scenario = 'structural_rank_ce_deficient_l1';
fixture.K = 2;
fixture.Q = 2;
fixture.Nphi = Nphi;
fixture.L = L;
fixture.noise_kind = 'none_structural_mmv';
fixture.noise_sigma = 0;
fixture.observation_regime = 'NOISELESS_STRUCTURAL';
fixture.coefficient_rank_evidence_kind = 'NOISELESS_EXACT_DATA';
fixture.column_covariance_model = 'identity';
fixture.aperture_index = 1:Nphi;
fixture.search_grid_deg = [9.0, 9.5, 10.0, 10.5, 11.0, 11.5];
fixture.search_domain_source = 'pre_registered_local_fixture_grid';
fixture.truth_on_registered_grid_flag = true;
fixture.angle_gate_deg = NaN;
fixture.recovery_gate = NaN;
fixture.expected_estimate_status = ...
    'ESTIMATE_NOT_RUN_STRUCTURAL_RANK_FAILURE';
fixture.expected_support_status = 'GROUP_MMV_RANK_UNCERTIFIED';
fixture.data = data;
fixture.data_info = data_info;
fixture.signal_data = data;
fixture.group_model = group_model;
fixture.Ge_true = Ge_true;
fixture.Ce_true_recovery = Ce_true_recovery;
fixture.Ce_true_score = Ce_true_score;
fixture.Xphi_true = {reshape(Ce_true_recovery(1, :), Nphi, L); ...
    reshape(Ce_true_recovery(2, :), Nphi, L)};
fixture.eta_true_deg = eta_true_deg;
fixture.truth_recovery_model_relative_residual = norm( ...
    data.Z_recovery_mmv - Ge_true * Ce_true_recovery, 'fro') / ...
    norm(data.Z_recovery_mmv, 'fro');
fixture.truth_score_model_relative_residual = norm( ...
    data.Z_score_mmv - Ge_true * Ce_true_score, 'fro') / ...
    norm(data.Z_score_mmv, 'fro');
fixture.T_row = T_row;
fixture.T_col = T_col;
fixture.row_whitening_rank = whitening_info.row_rank;
fixture.column_whitening_rank = whitening_info.column_rank;
fixture.row_whitening_error = whitening_info.row_whitening_error;
fixture.column_whitening_error = whitening_info.column_whitening_error;
fixture.whitening_info = whitening_info;
fixture.C_row = C_row;
fixture.Rphi_selected = C_col;
fixture.Zel_raw = Zel_raw;
fixture.el_beam_deg = el_beam_deg;
fixture.element_data = element_data;
fixture.element_data_info = element_data_info;
fixture.element_model = element_model;
fixture.element_whitening_info = struct('rank', Nel, ...
    'whitening_error', 0);
fixture.fixture_kind = 'explicit_registered_mmv_structural_counterexample';
end
