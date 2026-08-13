function value = stage8_k2_tp_axis_error_deg(direction_hat, direction_true)
%STAGE8_K2_TP_AXIS_ERROR_DEG Return the unoriented 2-D axis error.

if ~(isnumeric(direction_hat) && isreal(direction_hat) && ...
        numel(direction_hat) == 2 && all(isfinite(direction_hat(:))) && ...
        norm(direction_hat) > 0 && isnumeric(direction_true) && ...
        isreal(direction_true) && numel(direction_true) == 2 && ...
        all(isfinite(direction_true(:))) && norm(direction_true) > 0)
    error('stage8_k2_tp_axis_error_deg:Input', ...
        'Both directions must be finite, real, nonzero 2-D vectors.');
end
u_hat = direction_hat(:) / norm(direction_hat);
u_true = direction_true(:) / norm(direction_true);
cosine = abs(dot(u_hat, u_true));
cosine = min(1, max(0, cosine));
value = acosd(cosine);
if ~(isscalar(value) && isfinite(value) && value >= 0 && value <= 90)
    error('stage8_k2_tp_axis_error_deg:Numeric', ...
        'The computed axis error is outside [0,90] degrees.');
end
end
