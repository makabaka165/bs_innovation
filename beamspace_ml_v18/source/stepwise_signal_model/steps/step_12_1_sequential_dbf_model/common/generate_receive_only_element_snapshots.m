function [Yelem, model, info] = generate_receive_only_element_snapshots( ...
    target_angles_deg, source_snapshots, noise_elem, cfg)
%GENERATE_RECEIVE_ONLY_ELEMENT_SNAPSHOTS Build factor-1 narrowband snapshots.

if cfg.beam.spatialPhaseFactor ~= 1
    error('generate_receive_only_element_snapshots:PhaseFactor', ...
        'The active receive snapshot model must use spatialPhaseFactor=1.');
end
if ~isnumeric(target_angles_deg) || size(target_angles_deg, 2) ~= 2 || ...
        isempty(target_angles_deg) || any(~isfinite(target_angles_deg(:)))
    error('generate_receive_only_element_snapshots:Angles', ...
        'target_angles_deg must be a finite K-by-2 [az_deg,el_deg] matrix.');
end
K = size(target_angles_deg, 1);
if ~isnumeric(source_snapshots) || size(source_snapshots, 1) ~= K || ...
        isempty(source_snapshots) || any(~isfinite(source_snapshots(:)))
    error('generate_receive_only_element_snapshots:Sources', ...
        'source_snapshots must be a finite K-by-N_snapshot matrix.');
end
N_snapshot = size(source_snapshots, 2);

array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
layout = derive_cyl_array_layout(array_meta);
A_canonical = complex(zeros(layout.N_elem, K));
for k = 1:K
    a_legacy = build_receive_cyl_steering_vec( ...
        array_meta.XAct, array_meta.YAct, array_meta.ZAct, ...
        target_angles_deg(k, 1), target_angles_deg(k, 2), cfg.arr.lambda);
    a_matrix = reshape_cyl_vector_to_matrix(a_legacy, array_meta);
    A_canonical(:, k) = a_matrix(:);
end

noise_canonical = normalize_noise_local(noise_elem, layout, N_snapshot);
Y_canonical = A_canonical * source_snapshots + noise_canonical;
Yelem = reshape(Y_canonical, layout.N_el, layout.N_az, 1, N_snapshot);

model = struct();
model.phase_factor = 1;
model.target_angles_deg = target_angles_deg;
model.source_snapshots = source_snapshots;
model.A_canonical = A_canonical;
model.noise_canonical = noise_canonical;
model.Y_canonical = Y_canonical;
model.array_meta = array_meta;

info = layout;
info.phase_factor = 1;
info.num_targets = K;
info.num_snapshots = N_snapshot;
info.output_size = [layout.N_el, layout.N_az, 1, N_snapshot];
info.model = 'Yelem=A_receive_times_S_plus_N';
info.manifold_builder = 'build_receive_cyl_steering_vec';
info.legacy_echo_dependency = false;
end

function noise_canonical = normalize_noise_local(noise_elem, layout, N_snapshot)
if isempty(noise_elem)
    noise_canonical = complex(zeros(layout.N_elem, N_snapshot));
    return;
end
if ~isnumeric(noise_elem) || any(~isfinite(noise_elem(:)))
    error('generate_receive_only_element_snapshots:Noise', ...
        'noise_elem must be empty or a finite numeric array.');
end
if ismatrix(noise_elem) && isequal(size(noise_elem), [layout.N_elem, N_snapshot])
    noise_canonical = noise_elem;
    return;
end
sz = size(noise_elem);
if sz(1) ~= layout.N_el || sz(2) ~= layout.N_az
    error('generate_receive_only_element_snapshots:NoiseShape', ...
        'Noise must be canonical [N_elem,N_snapshot] or start with [N_el,N_az].');
end
if ndims(noise_elem) == 3 && sz(3) == N_snapshot
    noise_canonical = reshape(noise_elem, layout.N_elem, N_snapshot);
elseif ndims(noise_elem) == 4 && sz(3) == 1 && sz(4) == N_snapshot
    noise_canonical = reshape(noise_elem, layout.N_elem, N_snapshot);
else
    error('generate_receive_only_element_snapshots:NoiseShape', ...
        'Noise tensor must be [N_el,N_az,N_snapshot] or [N_el,N_az,1,N_snapshot].');
end
end
