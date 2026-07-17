function [score, rss, info] = finalize_projection_score(Z, U_r, opts)
%FINALIZE_PROJECTION_SCORE Compute energy score and enforce RSS policy.

projected = U_r' * Z;
score = real(norm(projected, 'fro') ^ 2);
total_energy = real(norm(Z, 'fro') ^ 2);
rss_raw = total_energy - score;
dimension_factor = max([size(Z, 1), size(Z, 2), size(U_r, 2), 1]);
energy_scale = max(total_energy, realmin(class(Z)));
rss_negative_tolerance = opts.rss_tolerance_multiplier * ...
    dimension_factor * eps(class(Z)) * energy_scale;

if rss_raw < -rss_negative_tolerance
    error('stable_dml:MaterialNegativeRSS', ...
        'RSS is negative beyond the scale-relative roundoff tolerance.');
end
rss_clipped = rss_raw < 0;
rss = max(rss_raw, 0);

if isempty(U_r)
    basis_orthogonality_error = 0;
else
    identity_r = eye(size(U_r, 2), 'like', Z);
    basis_orthogonality_error = norm(U_r' * U_r - identity_r, 'fro');
end
projection_idempotence_error = NaN;
projection_hermitian_error = NaN;
if opts.compute_projector_checks
    projector = U_r * U_r';
    projection_idempotence_error = norm(projector * projector - projector, 'fro');
    projection_hermitian_error = norm(projector' - projector, 'fro');
end

info = struct();
info.score = score;
info.rss = rss;
info.rss_raw = rss_raw;
info.rss_clipped = rss_clipped;
info.rss_negative_tolerance = rss_negative_tolerance;
info.total_energy = total_energy;
info.projection_energy = score;
info.basis_orthogonality_error = basis_orthogonality_error;
info.projection_idempotence_error = projection_idempotence_error;
info.projection_hermitian_error = projection_hermitian_error;
end
