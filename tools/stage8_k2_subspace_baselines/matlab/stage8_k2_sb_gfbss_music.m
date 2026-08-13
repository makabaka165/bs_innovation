function result = stage8_k2_sb_gfbss_music( ...
    R_fb, R_noise_subarray, model, constants)
%STAGE8_K2_SB_GFBSS_MUSIC Generalized vertical FBSS-MUSIC elevation fit.

if nargin < 4 || isempty(constants)
    constants = stage8_k2_sb_constants();
end
method_id = "ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML";
result = empty_result_local(method_id);
M = constants.smoothing_length;
if ~(isequal(size(R_fb), [M, M]) && ...
        isequal(size(R_noise_subarray), [M, M]) && ...
        all(isfinite(R_fb(:))) && all(isfinite(R_noise_subarray(:))))
    error('stage8_k2_sb_gfbss_music:Covariance', ...
        'FBSS signal/noise covariance dimensions are invalid.');
end

clock = tic;
[L_noise, failure] = chol( ...
    0.5 * (R_noise_subarray + R_noise_subarray'), 'lower');
if failure ~= 0
    result.fit_status = "GFBSS_MUSIC_NOISE_COVARIANCE_NOT_PD";
    result.runtime_sec = toc(clock);
    return;
end
C = L_noise \ eye(M);
R_generalized = C * R_fb * C';
R_generalized = 0.5 * (R_generalized + R_generalized');
[vectors, values] = eig(R_generalized, 'vector');
values = real(values);
[values, order] = sort(values, 'descend');
vectors = vectors(:, order);
result.eig_call_count = 1;
result.signal_eigenvalues = values(1:constants.K).';
E_noise = vectors(:, constants.K + 1:end);

theta = constants.elevation_grid_deg;
k0_dz = 2 * pi / model.lambda * ...
    model.array_configuration.arr.dz;
mu = k0_dz * sind(theta);
steering = exp(1j * (0:M-1).' * mu);
steering_white = C * steering;
denominator = sum(abs(E_noise' * steering_white) .^ 2, 1);
spectrum = 1 ./ max(real(denominator), realmin('double'));
result.score_call_count = numel(theta);
peaks = peaks_local(spectrum, theta);
result.elevation_candidate_count = peaks.candidate_count;
result.local_peak_count = peaks.candidate_count;
result.peak_values = peaks.values;
result.elevation_spectrum = spectrum;
result.noise_whitening_error = norm(C * R_noise_subarray * C' - ...
    eye(M), 'fro') / sqrt(M);
result.runtime_sec = toc(clock);
if ~peaks.valid
    result.fit_status = ...
        "GFBSS_MUSIC_FEWER_THAN_TWO_ELEVATION_PEAKS";
    return;
end
result.fit_valid = true;
result.fit_status = "GFBSS_MUSIC_TWO_ELEVATIONS_VALID";
result.elevations_hat_deg = sort(peaks.elevations_deg);
result.selection_values = peaks.values;
end

function peaks = peaks_local(spectrum, grid)
candidate = false(size(spectrum));
for index = 1:numel(spectrum)
    left = -Inf;
    right = -Inf;
    if index > 1, left = spectrum(index - 1); end
    if index < numel(spectrum), right = spectrum(index + 1); end
    candidate(index) = isfinite(spectrum(index)) && ...
        spectrum(index) >= left && spectrum(index) >= right && ...
        (spectrum(index) > left || spectrum(index) > right);
end
indices = find(candidate);
peaks = struct('valid', false, 'candidate_count', numel(indices), ...
    'elevations_deg', [NaN, NaN], 'values', [NaN, NaN]);
if numel(indices) < 2
    return;
end
ranking = [-spectrum(indices).', grid(indices).', indices.'];
[~, order] = sortrows(ranking, [1, 2, 3]);
selected = indices(order(1:2));
peaks.valid = true;
peaks.elevations_deg = grid(selected);
peaks.values = spectrum(selected);
end

function result = empty_result_local(method_id)
result = struct('method_id', method_id, 'applicable', true, ...
    'applicability_status', "APPLICABLE", 'fit_valid', false, ...
    'fit_status', "NOT_RUN", 'elevations_hat_deg', [NaN, NaN], ...
    'selection_values', [NaN, NaN], 'signal_eigenvalues', [NaN, NaN], ...
    'elevation_candidate_count', 0, 'local_peak_count', 0, ...
    'peak_values', [NaN, NaN], 'elevation_spectrum', [], ...
    'noise_whitening_error', NaN, 'score_call_count', 0, ...
    'svd_call_count', 0, 'eig_call_count', 0, 'runtime_sec', 0, ...
    'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false);
end
