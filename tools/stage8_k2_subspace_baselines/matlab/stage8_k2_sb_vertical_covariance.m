function [R_vertical, info] = stage8_k2_sb_vertical_covariance( ...
    Y_element, noise_factors, constants)
%STAGE8_K2_SB_VERTICAL_COVARIANCE Azimuth-whiten and pool vertical snapshots.

if nargin < 3 || isempty(constants)
    constants = stage8_k2_sb_constants();
end
cube = stage8_k2_sb_reshape_element_snapshots(Y_element, ...
    constants.N_el, constants.N_az);
L = size(cube, 3);
R_vertical = complex(zeros(constants.N_el));
for snapshot = 1:L
    X = cube(:, :, snapshot);
    X_az_white = X * noise_factors.W_az.';
    R_vertical = R_vertical + X_az_white * X_az_white';
end
R_vertical = R_vertical / (L * constants.N_az);
R_vertical = 0.5 * (R_vertical + R_vertical');
if any(~isfinite(R_vertical(:)))
    error('stage8_k2_sb_vertical_covariance:Finite', ...
        'Vertical covariance contains nonfinite values.');
end
info = struct('L', L, 'N_el', constants.N_el, ...
    'N_az', constants.N_az, 'az_whitening_error', ...
    noise_factors.az_whitening_error, ...
    'hermitian_residual', norm(R_vertical - R_vertical', 'fro') / ...
    max(1, norm(R_vertical, 'fro')), ...
    'score_call_count', 0, 'svd_call_count', 0, ...
    'eig_call_count', 0);
end
