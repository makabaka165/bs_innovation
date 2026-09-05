function result = stage8_k2_rtc_projected_direction(T_input, Ct_input, constants)
%STAGE8_K2_RTC_PROJECTED_DIRECTION Solve the stable 2-D generalized problem.

if ~(isnumeric(T_input) && isreal(T_input) && ...
        isequal(size(T_input), [2, 2]) && all(isfinite(T_input(:))) && ...
        isnumeric(Ct_input) && isreal(Ct_input) && ...
        isequal(size(Ct_input), [2, 2]) && all(isfinite(Ct_input(:))))
    error('stage8_k2_rtc_projected_direction:Input', ...
        'T and Ct must be finite real 2-by-2 matrices.');
end
T = 0.5 * (T_input + T_input.');
Ct = 0.5 * (Ct_input + Ct_input.');
[V, lambda] = eig(T, 'vector');
[lambda, order] = sort(real(lambda), 'ascend');
V = real(V(:, order));
negative_tolerance = 64 * max(size(T)) * eps(class(T)) * ...
    max(norm(T, 2), realmin(class(T)));
if any(lambda < -negative_tolerance)
    error('stage8_k2_rtc_projected_direction:IndefiniteMetric', ...
        'T has a negative eigenvalue beyond roundoff.');
end
lambda_nonnegative = max(lambda, 0);
[metric_rank, rank_threshold] = stable_numeric_rank( ...
    lambda_nonnegative, size(T), constants.rank_multiplier);
condition_value = Inf;
if metric_rank == 2
    condition_value = max(lambda_nonnegative) / min(lambda_nonnegative);
end
result = struct('valid', false, ...
    'status', 'TANGENT_METRIC_RANK_DEFICIENT', ...
    'direction_hat', [], 'metric_rank', double(metric_rank), ...
    'metric_condition', double(condition_value), ...
    'metric_eigenvalues', lambda, ...
    'metric_rank_threshold', double(rank_threshold), ...
    'generalized_eigenvalues', [NaN; NaN]);
if metric_rank ~= 2
    return;
end

Q = V * diag(1 ./ sqrt(lambda_nonnegative));
M = Q.' * Ct * Q;
M = 0.5 * (M + M.');
[W, mu] = eig(M, 'vector');
[mu, mu_order] = sort(real(mu), 'ascend');
W = real(W(:, mu_order));
direction = Q * W(:, end);
direction_norm = norm(direction);
if ~(isfinite(direction_norm) && direction_norm > 0 && ...
        all(isfinite(direction)))
    result.status = 'TANGENT_DIRECTION_NUMERIC_INVALID';
    return;
end
direction = direction / direction_norm;
if direction(2) < -constants.direction_sign_tolerance || ...
        (abs(direction(2)) <= constants.direction_sign_tolerance && ...
        direction(1) < 0)
    direction = -direction;
end
result.valid = true;
result.status = 'TANGENT_DIRECTION_VALID';
result.direction_hat = direction;
result.generalized_eigenvalues = mu;
end


