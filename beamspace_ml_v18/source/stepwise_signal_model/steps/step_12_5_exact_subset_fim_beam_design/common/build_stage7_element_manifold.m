function manifold = build_stage7_element_manifold(target_angles_deg, pool, cfg)
%BUILD_STAGE7_ELEMENT_MANIFOLD Build factor-1 columns and radian derivatives.

if ~(isnumeric(target_angles_deg) && size(target_angles_deg, 2) == 2 && ...
        ~isempty(target_angles_deg) && all(isfinite(target_angles_deg(:))))
    error('build_stage7_element_manifold:Angles', ...
        'target_angles_deg must be a finite K-by-2 matrix.');
end
K = size(target_angles_deg, 1);
N = size(pool.W0, 1);
A = complex(zeros(N, K));
dA_az = complex(zeros(N, K));
dA_el = complex(zeros(N, K));
for target_index = 1:K
    [a_legacy, da_az_legacy, da_el_legacy] = ...
        build_receive_cyl_steering_with_derivatives( ...
        pool.array_meta.XAct, pool.array_meta.YAct, pool.array_meta.ZAct, ...
        target_angles_deg(target_index, 1), ...
        target_angles_deg(target_index, 2), cfg.arr.lambda);
    A(:, target_index) = canonicalize_local(a_legacy, pool.array_meta);
    dA_az(:, target_index) = canonicalize_local(da_az_legacy, pool.array_meta);
    dA_el(:, target_index) = canonicalize_local(da_el_legacy, pool.array_meta);
end
manifold = struct('A', A, 'dA_az', dA_az, 'dA_el', dA_el, ...
    'target_angles_deg', target_angles_deg, 'derivative_unit', 'radian', ...
    'phase_factor', 1);
end

function vector = canonicalize_local(legacy_vector, array_meta)
matrix = reshape_cyl_vector_to_matrix(legacy_vector, array_meta);
vector = matrix(:);
end
