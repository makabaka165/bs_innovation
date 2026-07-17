function fixture = build_stage5_physical_fixture(spec, cfg, locked)
%BUILD_STAGE5_PHYSICAL_FIXTURE Build one shared factor-1 stage-5 fixture.

validate_spec_local(spec);
validate_locked_local(locked);
array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
Nel = cfg.arr.Nel;
Nphi = cfg.beam.subNaz;
K = size(spec.target_angles_deg, 1);
L = size(spec.source_snapshots, 2);
[Rz, Rphi] = covariance_factors_local(spec.noise_kind, Nel, Nphi);
noise_elem = noise_local(Rz, Rphi, spec.noise_sigma, spec.seed, L);
[Yelem, receive_model] = generate_receive_only_element_snapshots( ...
    spec.target_angles_deg, spec.source_snapshots, noise_elem, cfg);
Ycanonical = reshape(Yelem, Nel * Nphi, L);

common_precompute_tic = tic;
[domain, domain_info] = build_common_registered_local_domain( ...
    locked.conventional_center_deg, locked.domain_options);
[~, V] = form_elevation_dbf_cube( ...
    complex(zeros(Nel, Nphi)), locked.el_beam_deg, cfg);
[~, Uset] = form_azimuth_dbf_cube( ...
    complex(zeros(numel(locked.el_beam_deg), Nphi)), ...
    locked.az_beam_deg, locked.el_beam_deg, cfg);
Uset = apply_aperture_local(Uset, spec.aperture_index, Nphi);
[Wseq, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta);
if any(strcmp(char(spec.noise_kind), {'none','white'}))
    Rn_elem = kron(sparse(Rphi), sparse(Rz));
else
    Rn_elem = kron(Rphi, Rz);
end
[full_data, full_model, full_debug] = prepare_full_sequential_dml_data( ...
    Ycanonical, Wseq, Rn_elem, struct('array_meta', array_meta, ...
    'lambda', cfg.arr.lambda, 'phase_factor', 1));
common_precompute_runtime_sec = toc(common_precompute_tic);

stage4_precompute_tic = tic;
aperture_index = spec.aperture_index(:).';
Yselected = Yelem(:, aperture_index, :, :);
[Zel4, Vstage4] = form_elevation_dbf_cube( ...
    Yselected, locked.el_beam_deg, cfg);
Zel_raw = reshape(Zel4, numel(locked.el_beam_deg), ...
    numel(aperture_index), L);
C_row = Vstage4' * Rz * Vstage4;
Rphi_selected = Rphi(aperture_index, aperture_index);
[T_row, T_col, whitening_info] = ...
    build_separable_mmv_whiteners(C_row, Rphi_selected, struct());
observation_regime = regime_local(spec.noise_kind, spec.noise_sigma);
[stage4_data, stage4_data_info] = prepare_elevation_group_mmv_data( ...
    Zel_raw, T_row, T_col, struct('phase_factor', 1, ...
    'observation_regime', observation_regime, ...
    'column_covariance_model', covariance_name_local(spec.noise_kind)));
group_model = struct('V', Vstage4, 'whitener', T_row, ...
    'z_el_m', (0:Nel - 1).' * cfg.arr.dz, 'lambda', cfg.arr.lambda, ...
    'phase_factor', 1, ...
    'model_id', 'stage5_fixed_row_whitened_elevation_beams');

Q = max(spec.group_index);
[eta_true_deg, oracle_Kq] = group_metadata_local( ...
    spec.target_angles_deg, spec.group_index, Q);
stage4_precompute_runtime_sec = toc(stage4_precompute_tic);
stage4_tic = tic;
[stage4_est, stage4_search_debug] = estimate_elevation_groups_dml( ...
    stage4_data, Q, domain.el_grid_deg, group_model, struct());
stage4_runtime_sec = toc(stage4_tic);

Xphi_hat = cell(0, 1);
Ce_hat = complex(zeros(0, size(stage4_data.Z_recovery_mmv, 2)));
recovery_debug = empty_recovery_debug_local();
noise_model = empty_noise_model_local(Q, Rphi_selected);
noise_debug = struct('num_svd', 0);
recovery_noise_tic = tic;
if stage4_est.estimate_returned_flag && stage4_est.structural_gate_pass_flag
    [Xphi_hat, Ce_hat, recovery_debug] = recover_group_azimuth_data( ...
        stage4_data, stage4_est.Ge_hat, struct());
    [noise_model, noise_debug] = propagate_group_recovery_noise( ...
        stage4_est.Ge_hat, Rphi_selected, struct());
end
recovery_noise_runtime_sec = toc(recovery_noise_tic);
Xphi_true = true_group_data_local(receive_model.A_canonical, ...
    spec.source_snapshots, spec.group_index, aperture_index, Nel, Nphi, Q);

fixture = struct();
fixture.spec = spec;
fixture.locked = locked;
fixture.cfg = cfg;
fixture.K = K;
fixture.Q = Q;
fixture.oracle_Kq = oracle_Kq;
fixture.eta_true_deg = eta_true_deg;
fixture.array_meta = array_meta;
fixture.aperture_index = aperture_index;
fixture.Rz = Rz;
fixture.Rphi = Rphi;
fixture.Rphi_selected = Rphi_selected;
fixture.Rn_elem = Rn_elem;
fixture.Yelem = Yelem;
fixture.Ycanonical = Ycanonical;
fixture.receive_model = receive_model;
fixture.V = V;
fixture.Uset = Uset;
fixture.Wseq = Wseq;
fixture.beam_meta = beam_meta;
fixture.domain = domain;
fixture.domain_info = domain_info;
fixture.full_data = full_data;
fixture.full_model = full_model;
fixture.full_debug = full_debug;
fixture.stage4_data = stage4_data;
fixture.stage4_data_info = stage4_data_info;
fixture.group_model = group_model;
fixture.stage4_est = stage4_est;
fixture.stage4_search_debug = stage4_search_debug;
fixture.stage4_runtime_sec = stage4_runtime_sec;
fixture.common_precompute_runtime_sec = common_precompute_runtime_sec;
fixture.stage4_precompute_runtime_sec = stage4_precompute_runtime_sec;
fixture.recovery_noise_runtime_sec = recovery_noise_runtime_sec;
fixture.Xphi_hat = Xphi_hat;
fixture.Ce_hat = Ce_hat;
fixture.recovery_debug = recovery_debug;
fixture.noise_model = noise_model;
fixture.noise_debug = noise_debug;
fixture.Xphi_true = Xphi_true;
fixture.whitening_info = whitening_info;
fixture.observation_regime = observation_regime;
fixture.phase_factor = 1;
end

function validate_locked_local(locked)
required = {'conventional_center_deg','domain_options', ...
    'el_beam_deg','az_beam_deg'};
if ~(isstruct(locked) && isscalar(locked) && all(isfield(locked, required)))
    error('build_stage5_physical_fixture:LockedConfig', ...
        'locked is missing a registered stage-5 configuration field.');
end
end

function validate_spec_local(spec)
required = {'name','data_split','target_angles_deg','source_snapshots', ...
    'group_index','noise_kind','noise_sigma','seed','aperture_index'};
if ~(isstruct(spec) && isscalar(spec) && all(isfield(spec, required)))
    error('build_stage5_physical_fixture:Spec', ...
        'spec is missing a required field.');
end
if size(spec.target_angles_deg, 1) ~= size(spec.source_snapshots, 1) || ...
        numel(spec.group_index) ~= size(spec.target_angles_deg, 1)
    error('build_stage5_physical_fixture:SpecShape', ...
        'Target, source, and group dimensions are inconsistent.');
end
end

function [Rz, Rphi] = covariance_factors_local(kind, Nel, Nphi)
switch char(kind)
    case {'none','white'}
        Rz = eye(Nel);
        Rphi = eye(Nphi);
    case 'correlated'
        Rz = toeplitz(0.45 .^ (0:Nel - 1));
        Rphi = toeplitz(0.70 .^ (0:Nphi - 1));
    otherwise
        error('build_stage5_physical_fixture:NoiseKind', ...
            'Unknown noise kind: %s.', char(kind));
end
end

function noise = noise_local(Rz, Rphi, sigma, seed, L)
Nel = size(Rz, 1);
Nphi = size(Rphi, 1);
if sigma == 0
    noise = [];
    return;
end
rng(seed, 'twister');
Lz = chol(Rz, 'lower');
Lphi = chol(Rphi, 'lower');
noise = complex(zeros(Nel, Nphi, 1, L));
for ell = 1:L
    E = complex(randn(Nel, Nphi), randn(Nel, Nphi)) / sqrt(2);
    noise(:, :, 1, ell) = sigma * Lz * E * Lphi';
end
noise = reshape(noise, Nel * Nphi, L);
end

function Uset = apply_aperture_local(Uset, aperture_index, Nphi)
aperture_index = aperture_index(:);
if isempty(aperture_index) || any(aperture_index < 1) || ...
        any(aperture_index > Nphi) || any(aperture_index ~= fix(aperture_index))
    error('build_stage5_physical_fixture:Aperture', ...
        'aperture_index must contain valid circumferential indices.');
end
mask = false(Nphi, 1);
mask(aperture_index) = true;
for b = 1:size(Uset, 3)
    for c = 1:size(Uset, 2)
        weight = Uset(:, c, b);
        weight(~mask) = 0;
        Uset(:, c, b) = weight / norm(weight);
    end
end
end

function [eta, Kq] = group_metadata_local(angles, group_index, Q)
eta = zeros(1, Q);
Kq = zeros(1, Q);
for q = 1:Q
    rows = find(group_index == q);
    if isempty(rows) || any(angles(rows, 2) ~= angles(rows(1), 2))
        error('build_stage5_physical_fixture:GroupDefinition', ...
            'Each oracle group must be non-empty and share one elevation.');
    end
    eta(q) = angles(rows(1), 2);
    Kq(q) = numel(rows);
end
if any(diff(eta) <= 0)
    error('build_stage5_physical_fixture:GroupOrder', ...
        'Oracle elevation groups must be strictly ordered.');
end
end

function groups = true_group_data_local(A, S, group_index, aperture_index, ...
    Nel, Nphi, Q)
groups = cell(Q, 1);
for q = 1:Q
    groups{q} = complex(zeros(numel(aperture_index), size(S, 2)));
end
for k = 1:size(A, 2)
    matrix = reshape(A(:, k), Nel, Nphi);
    response = matrix(1, aperture_index).';
    groups{group_index(k)} = groups{group_index(k)} + response * S(k, :);
end
end

function regime = regime_local(kind, sigma)
if strcmp(kind, 'none') && sigma == 0
    regime = 'NOISELESS_STRUCTURAL';
else
    regime = 'NOISY_UNCALIBRATED';
end
end

function name = covariance_name_local(kind)
if strcmp(kind, 'correlated')
    name = 'selected_toeplitz_matrix_normal_column_covariance';
else
    name = 'identity';
end
end

function debug = empty_recovery_debug_local()
debug = struct('solve_status', ...
    'RECOVERY_NOT_RUN_UPSTREAM_GROUP_STAGE_UNCERTIFIED', ...
    'recovery_returned_flag', false, 'num_svd', 0);
end

function model = empty_noise_model_local(Q, Rphi)
model = struct('R_group', NaN(Q), 'group_noise_scale', NaN(Q, 1), ...
    'cross_group_noise_correlation', NaN(Q), ...
    'Rphi_selected', Rphi, 'rank_Ge', 0, 'phase_factor', 1, ...
    'num_svd', 0, 'status', 'UPSTREAM_GROUP_STAGE_UNCERTIFIED', ...
    'statistical_calibration_status', 'NOT_CALIBRATED_STAGE5');
end
