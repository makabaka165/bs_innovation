function result = stage8_k2_sb_ls_esprit(R_fb, model, constants)
%STAGE8_K2_SB_LS_ESPRIT White-noise vertical FBSS LS-ESPRIT elevation fit.

if nargin < 3 || isempty(constants)
    constants = stage8_k2_sb_constants();
end
method_id = "ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML";
result = empty_result_local(method_id);
M = constants.smoothing_length;
if ~(isequal(size(R_fb), [M, M]) && all(isfinite(R_fb(:))))
    error('stage8_k2_sb_ls_esprit:Covariance', ...
        'R_fb must be a finite frozen-size covariance.');
end

clock = tic;
R_fb = 0.5 * (R_fb + R_fb');
[vectors, values] = eig(R_fb, 'vector');
values = real(values);
[values, order] = sort(values, 'descend');
vectors = vectors(:, order);
result.eig_call_count = 1;
result.signal_eigenvalues = values(1:constants.K).';
U_signal = vectors(:, 1:constants.K);
S1 = U_signal(1:end-1, :);
S2 = U_signal(2:end, :);
[U, S, V] = svd(S1, 'econ');
result.svd_call_count = 1;
singular_values = diag(S);
threshold = max(size(S1)) * eps(max(1, max(singular_values)));
numeric_rank = nnz(singular_values > threshold);
result.shift_matrix_rank = numeric_rank;
if numeric_rank < constants.K
    result.fit_status = "ESPRIT_SHIFT_MATRIX_RANK_DEFICIENT";
    result.runtime_sec = toc(clock);
    return;
end
Psi = V(:, 1:numeric_rank) * diag(1 ./ singular_values(1:numeric_rank)) * ...
    U(:, 1:numeric_rank)' * S2;
eigenvalues = eig(Psi);
result.eig_call_count = result.eig_call_count + 1;
result.esprit_eigenvalues = eigenvalues.';
result.eigenvalue_moduli = abs(eigenvalues).';
if numel(eigenvalues) ~= constants.K || ...
        any(~isfinite(real(eigenvalues)) | ~isfinite(imag(eigenvalues)))
    result.fit_status = "ESPRIT_EIGENVALUES_NONFINITE";
    result.runtime_sec = toc(clock);
    return;
end
k0_dz = 2 * pi / model.lambda * ...
    model.array_configuration.arr.dz;
theta_hat = asind(angle(eigenvalues) / k0_dz).';
domain = constants.elevation_domain_deg;
tolerance = 64 * eps(max(abs(domain)));
if any(~isfinite(theta_hat)) || any(theta_hat < domain(1) - tolerance) || ...
        any(theta_hat > domain(2) + tolerance)
    result.fit_status = "ESPRIT_ELEVATION_OUTSIDE_LOCAL_DOMAIN";
    result.runtime_sec = toc(clock);
    return;
end
theta_hat = sort(theta_hat);
if abs(diff(theta_hat)) <= constants.elevation_distinct_tolerance_deg
    result.fit_status = "ESPRIT_REPEATED_ELEVATION_ESTIMATE";
    result.runtime_sec = toc(clock);
    return;
end
result.fit_valid = true;
result.fit_status = "ESPRIT_TWO_ELEVATIONS_VALID";
result.elevations_hat_deg = theta_hat;
result.selection_values = result.eigenvalue_moduli;
result.runtime_sec = toc(clock);
end

function result = empty_result_local(method_id)
result = struct('method_id', method_id, 'applicable', true, ...
    'applicability_status', "APPLICABLE", 'fit_valid', false, ...
    'fit_status', "NOT_RUN", 'elevations_hat_deg', [NaN, NaN], ...
    'selection_values', [NaN, NaN], ...
    'signal_eigenvalues', [NaN, NaN], ...
    'esprit_eigenvalues', [NaN, NaN], ...
    'eigenvalue_moduli', [NaN, NaN], 'shift_matrix_rank', 0, ...
    'score_call_count', 0, 'svd_call_count', 0, ...
    'eig_call_count', 0, 'runtime_sec', 0, ...
    'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false);
end
