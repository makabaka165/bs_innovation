function fixture = build_stage4_physical_fixture(spec, cfg, el_beam_deg)
%BUILD_STAGE4_PHYSICAL_FIXTURE Form separably whitened elevation MMV data.

K = size(spec.target_angles_deg, 1);
L = size(spec.source_snapshots, 2);
Nphi_full = cfg.beam.subNaz;
Nel = cfg.arr.Nel;
if size(spec.source_snapshots, 1) ~= K || numel(spec.group_index) ~= K
    error('build_stage4_physical_fixture:SourceShape', ...
        'Target, source, and group definitions are inconsistent.');
end

[noise_elem, Rz, Rphi] = make_noise_local( ...
    spec.noise_kind, spec.noise_sigma, spec.seed, Nel, Nphi_full, L);
[Yelem_full, receive_model] = generate_receive_only_element_snapshots( ...
    spec.target_angles_deg, spec.source_snapshots, noise_elem, cfg);
aperture_index = spec.aperture_index(:).';
Yelem = Yelem_full(:, aperture_index, :, :);
Nphi = numel(aperture_index);

[Zel_raw4, V] = form_elevation_dbf_cube(Yelem, el_beam_deg, cfg);
Bphys = size(V, 2);
Zel_raw = reshape(Zel_raw4, Bphys, Nphi, L);
C_row = V' * Rz * V;
Rphi_selected = Rphi(aperture_index, aperture_index);
[T_row, T_col, whitening_info] = ...
    build_separable_mmv_whiteners(C_row, Rphi_selected, struct());
[observation_regime, column_covariance_model] = ...
    regime_metadata_local(spec.noise_kind);
prepare_opts = struct('phase_factor', 1, ...
    'observation_regime', observation_regime, ...
    'column_covariance_model', column_covariance_model);
[data, data_info] = prepare_elevation_group_mmv_data( ...
    Zel_raw, T_row, T_col, prepare_opts);

group_model = struct();
group_model.V = V;
group_model.whitener = T_row;
group_model.z_el_m = (0:Nel - 1).' * cfg.arr.dz;
group_model.lambda = cfg.arr.lambda;
group_model.phase_factor = 1;
group_model.model_id = 'stage4_fixed_row_whitened_elevation_beams';

Q = max(spec.group_index);
eta_true_deg = zeros(1, Q);
for q = 1:Q
    target_rows = find(spec.group_index == q);
    group_elevations = spec.target_angles_deg(target_rows, 2);
    if any(group_elevations ~= group_elevations(1))
        error('build_stage4_physical_fixture:GroupElevation', ...
            'Every target in one oracle group must share one elevation.');
    end
    eta_true_deg(q) = group_elevations(1);
end
if any(diff(eta_true_deg) <= 0)
    error('build_stage4_physical_fixture:GroupOrder', ...
        'Oracle groups must be ordered by strictly increasing elevation.');
end
[Ge_true, ~] = build_elevation_group_manifold( ...
    eta_true_deg, group_model, struct());

Ce_true_recovery = complex(zeros(Q, Nphi * L));
for k = 1:K
    A_now = reshape(receive_model.A_canonical(:, k), Nel, Nphi_full);
    circumferential_response = A_now(1, aperture_index);
    q = spec.group_index(k);
    for ell = 1:L
        columns = (ell - 1) * Nphi + (1:Nphi);
        Ce_true_recovery(q, columns) = ...
            Ce_true_recovery(q, columns) + ...
            circumferential_response * spec.source_snapshots(k, ell);
    end
end
Ce_true_score = right_whiten_coefficients_local( ...
    Ce_true_recovery, T_col, Nphi, L);
Xphi_true = coefficient_groups_local(Ce_true_recovery, Nphi, L);

Ysignal_full = reshape(receive_model.A_canonical * spec.source_snapshots, ...
    Nel, Nphi_full, 1, L);
Ysignal = Ysignal_full(:, aperture_index, :, :);
[Zsignal_raw4, ~] = form_elevation_dbf_cube(Ysignal, el_beam_deg, cfg);
Zsignal_raw = reshape(Zsignal_raw4, Bphys, Nphi, L);
[signal_data, ~] = prepare_elevation_group_mmv_data( ...
    Zsignal_raw, T_row, T_col, struct('phase_factor', 1, ...
    'observation_regime', 'NOISELESS_STRUCTURAL', ...
    'column_covariance_model', column_covariance_model));
truth_recovery_model_relative_residual = norm( ...
    signal_data.Z_recovery_mmv - Ge_true * Ce_true_recovery, 'fro') / ...
    max(norm(signal_data.Z_recovery_mmv, 'fro'), ...
    realmin(class(signal_data.Z_recovery_mmv)));
truth_score_model_relative_residual = norm( ...
    signal_data.Z_score_mmv - Ge_true * Ce_true_score, 'fro') / ...
    max(norm(signal_data.Z_score_mmv, 'fro'), ...
    realmin(class(signal_data.Z_score_mmv)));

[T_element, element_whitening_info] = build_psd_whitener(Rz);
element_model = struct();
element_model.V = eye(Nel);
element_model.whitener = T_element;
element_model.z_el_m = group_model.z_el_m;
element_model.lambda = cfg.arr.lambda;
element_model.phase_factor = 1;
element_model.model_id = 'vertical_element_domain_reference';
[element_data, element_data_info] = prepare_elevation_group_mmv_data( ...
    reshape(Yelem, Nel, Nphi, L), T_element, T_col, prepare_opts);

fixture = struct();
fixture.scenario = spec.name;
fixture.K = K;
fixture.Q = Q;
fixture.Nphi = Nphi;
fixture.L = L;
fixture.noise_kind = spec.noise_kind;
fixture.noise_sigma = spec.noise_sigma;
fixture.observation_regime = observation_regime;
fixture.coefficient_rank_evidence_kind = coefficient_rank_kind_local( ...
    observation_regime);
fixture.column_covariance_model = column_covariance_model;
fixture.aperture_index = aperture_index;
fixture.search_grid_deg = spec.search_grid_deg;
fixture.search_domain_source = 'pre_registered_local_fixture_grid';
fixture.truth_on_registered_grid_flag = on_registered_grid_local( ...
    eta_true_deg, spec.search_grid_deg);
fixture.angle_gate_deg = spec.angle_gate_deg;
fixture.recovery_gate = spec.recovery_gate;
fixture.expected_estimate_status = 'ESTIMATE_RETURNED';
if strcmp(observation_regime, 'NOISELESS_STRUCTURAL')
    fixture.expected_support_status = 'GROUP_REGISTERED_MODEL_CERTIFIED';
else
    fixture.expected_support_status = ...
        'GROUP_REGISTERED_MODEL_SUPPORTED_UNCALIBRATED';
end
fixture.data = data;
fixture.data_info = data_info;
fixture.signal_data = signal_data;
fixture.group_model = group_model;
fixture.Ge_true = Ge_true;
fixture.Ce_true_recovery = Ce_true_recovery;
fixture.Ce_true_score = Ce_true_score;
fixture.Xphi_true = Xphi_true;
fixture.eta_true_deg = eta_true_deg;
fixture.truth_recovery_model_relative_residual = ...
    truth_recovery_model_relative_residual;
fixture.truth_score_model_relative_residual = ...
    truth_score_model_relative_residual;
fixture.T_row = T_row;
fixture.T_col = T_col;
fixture.row_whitening_rank = whitening_info.row_rank;
fixture.column_whitening_rank = whitening_info.column_rank;
fixture.row_whitening_error = whitening_info.row_whitening_error;
fixture.column_whitening_error = whitening_info.column_whitening_error;
fixture.whitening_info = whitening_info;
fixture.C_row = C_row;
fixture.Rphi_selected = Rphi_selected;
fixture.Zel_raw = Zel_raw;
fixture.el_beam_deg = el_beam_deg;
fixture.element_data = element_data;
fixture.element_data_info = element_data_info;
fixture.element_model = element_model;
fixture.element_whitening_info = element_whitening_info;
fixture.fixture_kind = 'physical_factor1_separable_matrix_normal_mmv';
end

function Ce_score = right_whiten_coefficients_local(Ce, T_col, Nphi, L)
Q = size(Ce, 1);
r_col = size(T_col, 1);
Ce_score = complex(zeros(Q, r_col * L, 'like', Ce));
for ell = 1:L
    physical_columns = (ell - 1) * Nphi + (1:Nphi);
    score_columns = (ell - 1) * r_col + (1:r_col);
    Ce_score(:, score_columns) = Ce(:, physical_columns) * T_col';
end
end

function Xphi = coefficient_groups_local(Ce, Nphi, L)
Q = size(Ce, 1);
Xphi = cell(Q, 1);
for q = 1:Q
    Xphi{q} = reshape(Ce(q, :), Nphi, L);
end
end

function [regime, model] = regime_metadata_local(noise_kind)
switch char(noise_kind)
    case 'none'
        regime = 'NOISELESS_STRUCTURAL';
        model = 'identity';
    case 'white'
        regime = 'NOISY_UNCALIBRATED';
        model = 'identity';
    case 'correlated_rows_and_columns'
        regime = 'NOISY_UNCALIBRATED';
        model = 'selected_toeplitz_matrix_normal_column_covariance';
    otherwise
        error('build_stage4_physical_fixture:NoiseKindMetadata', ...
            'Unknown noise kind: %s', char(noise_kind));
end
end

function kind = coefficient_rank_kind_local(regime)
if strcmp(regime, 'NOISELESS_STRUCTURAL')
    kind = 'NOISELESS_EXACT_DATA';
else
    kind = 'NOISY_DIAGNOSTIC_ONLY';
end
end

function flag = on_registered_grid_local(eta_deg, grid_deg)
grid_deg = grid_deg(:);
scale = max(1, max(abs(grid_deg)));
tolerance = max(numel(grid_deg), 1) * eps(class(grid_deg)) * scale;
flag = true;
for idx = 1:numel(eta_deg)
    flag = flag && min(abs(grid_deg - eta_deg(idx))) <= tolerance;
end
end

function [noise_elem, Rz, Rphi] = make_noise_local( ...
    noise_kind, sigma, seed, Nel, Nphi, L)
switch char(noise_kind)
    case 'none'
        Rz = eye(Nel);
        Rphi = eye(Nphi);
        noise_elem = [];
        return;
    case 'white'
        Rz = eye(Nel);
        Rphi = eye(Nphi);
    case 'correlated_rows_and_columns'
        Rz = toeplitz(0.45 .^ (0:Nel - 1));
        Rphi = toeplitz(0.70 .^ (0:Nphi - 1));
    otherwise
        error('build_stage4_physical_fixture:NoiseKind', ...
            'Unknown noise kind: %s', char(noise_kind));
end
rng(seed, 'twister');
Lz = chol(Rz, 'lower');
Lphi = chol(Rphi, 'lower');
noise_elem = complex(zeros(Nel, Nphi, 1, L));
for ell = 1:L
    E = complex(randn(Nel, Nphi), randn(Nel, Nphi)) / sqrt(2);
    noise_elem(:, :, 1, ell) = sigma * Lz * E * Lphi';
end
end
