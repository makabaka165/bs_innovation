function out = compute_tangent_null_sixth_order( ...
    g0, g1, g2, g3, g_minus, g_plus, separation_rad)
%COMPUTE_TANGENT_NULL_SIXTH_ORDER Evaluate the registered null candidate.

inputs = {g0, g1, g2, g3, g_minus, g_plus};
if any(cellfun(@(x) ~isnumeric(x) || ~iscolumn(x) || ...
        numel(x) ~= numel(g0) || any(~isfinite(x)), inputs))
    error('compute_tangent_null_sixth_order:Inputs', ...
        'All manifold inputs must be finite columns of the same length.');
end
validateattributes(separation_rad, {'numeric'}, ...
    {'real','finite','positive','scalar'}, mfilename, 'separation_rad');
g_energy = g0' * g0;
if real(g_energy) <= 0
    error('compute_tangent_null_sixth_order:ZeroCenter', ...
        'g0 must be nonzero.');
end
P = eye(numel(g0), 'like', g0) - g0 * g0' / g_energy;
alpha = (g0' * g1) / g_energy;
v3_eff = P * (g3 / 24 - alpha * g2 / 8);
singular_values = svd([g_minus, g_plus], 'econ');
if numel(singular_values) < 2
    sigma2_sq = 0;
else
    sigma2_sq = singular_values(2) ^ 2;
end
prediction = 0.5 * separation_rad ^ 6 * norm(v3_eff) ^ 2;

out = struct();
out.alpha = alpha;
out.v3_eff = v3_eff;
out.v3_eff_norm = norm(v3_eff);
out.sigma2_sq = sigma2_sq;
out.null_sigma2_prediction = prediction;
out.null_sigma2_ratio = sigma2_sq / prediction;
out.projected_first_derivative_norm = norm(P * g1);
out.phase_factor = 1;
end
