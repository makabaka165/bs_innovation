function labels = stage8_k2_va_pair_label(delta_joint_rmse_deg, tolerance_deg)
%STAGE8_K2_VA_PAIR_LABEL Apply the reporting-only paired tolerance.

if nargin < 2 || isempty(tolerance_deg)
    tolerance_deg = 1e-6;
end
if ~(isscalar(tolerance_deg) && isfinite(tolerance_deg) && ...
        tolerance_deg >= 0)
    error('stage8_k2_va_pair_label:Tolerance', ...
        'The paired tolerance must be a finite nonnegative scalar.');
end
labels = strings(size(delta_joint_rmse_deg));
finite_delta = isfinite(delta_joint_rmse_deg);
labels(~finite_delta) = "INVALID";
labels(finite_delta & delta_joint_rmse_deg < -tolerance_deg) = "WIN";
labels(finite_delta & abs(delta_joint_rmse_deg) <= tolerance_deg) = "TIE";
labels(finite_delta & delta_joint_rmse_deg > tolerance_deg) = "LOSS";
end
