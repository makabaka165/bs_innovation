function fixture = build_stage4_physical_fixture(spec, cfg, el_beam_deg)
%BUILD_STAGE4_PHYSICAL_FIXTURE Form fixed-whitened sequential elevation data.

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
[T, whitening_info] = build_psd_whitener(V' * Rz * V);
Zel_white = reshape(T * reshape(Zel_raw, Bphys, []), ...
    size(T, 1), Nphi, L);
[Zemmv, mapping, stack_info] = stack_elevation_mmv_data( ...
    struct('Zel', Zel_white, 'phase_factor', 1), struct());

group_model = struct();
group_model.V = V;
group_model.whitener = T;
group_model.z_el_m = (0:Nel - 1).' * cfg.arr.dz;
group_model.lambda = cfg.arr.lambda;
group_model.phase_factor = 1;
group_model.model_id = 'stage4_fixed_elevation_beams';

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

Ce_true = complex(zeros(Q, Nphi * L));
for k = 1:K
    A_now = reshape(receive_model.A_canonical(:, k), Nel, Nphi_full);
    circumferential_response = A_now(1, aperture_index);
    q = spec.group_index(k);
    for ell = 1:L
        columns = (ell - 1) * Nphi + (1:Nphi);
        Ce_true(q, columns) = Ce_true(q, columns) + ...
            circumferential_response * spec.source_snapshots(k, ell);
    end
end

Ysignal_full = reshape(receive_model.A_canonical * spec.source_snapshots, ...
    Nel, Nphi_full, 1, L);
Ysignal = Ysignal_full(:, aperture_index, :, :);
[Zsignal_raw4, ~] = form_elevation_dbf_cube(Ysignal, el_beam_deg, cfg);
Zsignal_raw = reshape(Zsignal_raw4, Bphys, Nphi, L);
Zsignal_white = reshape(T * reshape(Zsignal_raw, Bphys, []), ...
    size(T, 1), Nphi, L);
[Zsignal_mmv, ~] = stack_elevation_mmv_data(Zsignal_white, struct());
truth_model_relative_residual = norm(Zsignal_mmv - Ge_true * Ce_true, 'fro') / ...
    max(norm(Zsignal_mmv, 'fro'), realmin(class(Zsignal_mmv)));

[Te, element_whitening_info] = build_psd_whitener(Rz);
Zelement_white = reshape(Te * reshape(Yelem, Nel, []), ...
    size(Te, 1), Nphi, L);
[Zelement_mmv, element_mapping] = stack_elevation_mmv_data( ...
    Zelement_white, struct());
element_model = struct();
element_model.V = eye(Nel);
element_model.whitener = Te;
element_model.z_el_m = group_model.z_el_m;
element_model.lambda = cfg.arr.lambda;
element_model.phase_factor = 1;
element_model.model_id = 'vertical_element_domain_reference';

fixture = struct();
fixture.scenario = spec.name;
fixture.K = K;
fixture.Q = Q;
fixture.Nphi = Nphi;
fixture.L = L;
fixture.noise_kind = spec.noise_kind;
fixture.noise_sigma = spec.noise_sigma;
fixture.aperture_index = aperture_index;
fixture.search_grid_deg = spec.search_grid_deg;
fixture.angle_gate_deg = spec.angle_gate_deg;
fixture.recovery_gate = spec.recovery_gate;
fixture.expected_status = 'GROUP_IDENTIFIABLE';
fixture.Zemmv = Zemmv;
fixture.Zsignal_mmv = Zsignal_mmv;
fixture.mapping = mapping;
fixture.stack_info = stack_info;
fixture.group_model = group_model;
fixture.Ge_true = Ge_true;
fixture.Ce_true = Ce_true;
fixture.eta_true_deg = eta_true_deg;
fixture.truth_model_relative_residual = truth_model_relative_residual;
fixture.whitening_info = whitening_info;
fixture.Zel_raw = Zel_raw;
fixture.el_beam_deg = el_beam_deg;
fixture.Zelement_mmv = Zelement_mmv;
fixture.element_mapping = element_mapping;
fixture.element_model = element_model;
fixture.element_whitening_info = element_whitening_info;
fixture.Rphi_selected = Rphi(aperture_index, aperture_index);
fixture.fixture_kind = 'physical_factor1_sequential_elevation_dbf';
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
