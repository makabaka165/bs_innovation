function [R_fb, R_noise_subarray, info] = ...
    stage8_k2_sb_fbss_covariance(R_vertical, R_el, constants)
%STAGE8_K2_SB_FBSS_COVARIANCE Fixed P=2 vertical forward/backward smoothing.

if nargin < 3 || isempty(constants)
    constants = stage8_k2_sb_constants();
end
N = constants.N_el;
M = constants.smoothing_length;
P = constants.smoothing_subarray_count;
if ~(isequal(size(R_vertical), [N, N]) && all(isfinite(R_vertical(:))) && ...
        isequal(size(R_el), [N, N]) && all(isfinite(R_el(:))) && ...
        M == N - constants.K + 1 && P == N - M + 1)
    error('stage8_k2_sb_fbss_covariance:Contract', ...
        'Covariance dimensions or frozen smoothing parameters are invalid.');
end
R_forward = complex(zeros(M));
for offset = 0:P-1
    selected = (1:M) + offset;
    R_forward = R_forward + R_vertical(selected, selected);
end
R_forward = R_forward / P;
R_fb = 0.5 * (R_forward + rot90(conj(R_forward), 2));
R_fb = 0.5 * (R_fb + R_fb');
R_noise_subarray = R_el(1:M, 1:M);
R_noise_subarray = 0.5 * ...
    (R_noise_subarray + R_noise_subarray');
info = struct('smoothing_length', M, 'subarray_count', P, ...
    'forward_covariance', R_forward, ...
    'hermitian_residual', norm(R_fb - R_fb', 'fro') / ...
    max(1, norm(R_fb, 'fro')), ...
    'forward_backward_residual', norm(R_fb - ...
    rot90(conj(R_fb), 2), 'fro') / max(1, norm(R_fb, 'fro')));
end
