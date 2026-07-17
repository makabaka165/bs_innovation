function [Gseq, info] = build_sequential_beamspace_manifold( ...
    Wseq, target_angles_deg, array_meta, cfg)
%BUILD_SEQUENTIAL_BEAMSPACE_MANIFOLD Project the full factor-1 geometry.

if cfg.beam.spatialPhaseFactor ~= 1
    error('build_sequential_beamspace_manifold:PhaseFactor', ...
        'The active receive manifold must use spatialPhaseFactor=1.');
end
layout = derive_cyl_array_layout(array_meta);
if size(Wseq, 1) ~= layout.N_elem
    error('build_sequential_beamspace_manifold:WShape', ...
        'Wseq must have %d canonical element rows.', layout.N_elem);
end
if ~isnumeric(target_angles_deg) || size(target_angles_deg, 2) ~= 2 || ...
        isempty(target_angles_deg) || any(~isfinite(target_angles_deg(:)))
    error('build_sequential_beamspace_manifold:Angles', ...
        'target_angles_deg must be a finite K-by-2 [az_deg,el_deg] matrix.');
end

K = size(target_angles_deg, 1);
A_canonical = complex(zeros(layout.N_elem, K));
for k = 1:K
    a_legacy = build_receive_cyl_steering_vec( ...
        array_meta.XAct, array_meta.YAct, array_meta.ZAct, ...
        target_angles_deg(k, 1), target_angles_deg(k, 2), cfg.arr.lambda);
    a_matrix = reshape_cyl_vector_to_matrix(a_legacy, array_meta);
    A_canonical(:, k) = a_matrix(:);
end
Gseq = Wseq' * A_canonical;

info = struct();
info.phase_factor = 1;
info.target_angles_deg = target_angles_deg;
info.num_targets = K;
info.A_canonical = A_canonical;
info.Gseq_size = size(Gseq);
info.manifold_source = 'full_receive_cyl_geometry_not_separable_approximation';
info.element_vector_order = layout.canonical_order;
end
