function result = stage8_k2_cb_music( ...
    data_white, resource_entry, resources, observation_domain, L, constants)
%STAGE8_K2_CB_MUSIC Standard known-K=2 MUSIC on its applicable subset.

if nargin < 6 || isempty(constants)
    constants = stage8_k2_cb_constants();
end
mode = upper(string(observation_domain));
if mode == "BEAMSPACE"
    method_id = "BEAMSPACE_MUSIC_K2";
    dictionary = resource_entry.G_beamspace;
elseif mode == "ELEMENT"
    method_id = "ELEMENT_MUSIC_K2";
    dictionary = resource_entry.A_element_white;
else
    error('stage8_k2_cb_music:Mode', ...
        'observation_domain must be BEAMSPACE or ELEMENT.');
end
result = empty_result_local(method_id, mode);
if L == 1
    result.applicable = false;
    result.applicability_status = ...
        "NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK";
    result.fit_status = result.applicability_status;
    return;
end
if ~ismember(L, constants.music_applicable_L)
    error('stage8_k2_cb_music:Snapshots', ...
        'The registered MUSIC subset permits only L=1,4,8.');
end
if ~(isnumeric(data_white) && ismatrix(data_white) && ...
        size(data_white, 2) == L && size(data_white, 1) == ...
        size(dictionary, 1) && all(isfinite(data_white(:))))
    error('stage8_k2_cb_music:Data', ...
        'Whitened MUSIC data and fixed dictionary disagree.');
end

clock = tic;
covariance = data_white * data_white' / L;
covariance = 0.5 * (covariance + covariance');
[vectors, values] = eig(covariance, 'vector');
values = real(values);
[values, order] = sort(values, 'descend');
vectors = vectors(:, order);
rank_threshold = size(covariance, 1) * ...
    eps(max(1, max(abs(values))));
sample_rank = nnz(values > rank_threshold);
result.eig_call_count = 1;
result.effective_rank = sample_rank;
result.sample_eigenvalues = values;
result.sample_rank_threshold = rank_threshold;
if sample_rank < 2
    result.fit_status = "MUSIC_SIGNAL_SUBSPACE_RANK_DEFICIENT";
    result.online_runtime_sec = toc(clock);
    result.runtime_sec = result.online_runtime_sec;
    return;
end

signal_subspace = vectors(:, 1:2);
total_energy = sum(abs(dictionary) .^ 2, 1);
signal_energy = sum(abs(signal_subspace' * dictionary) .^ 2, 1);
denominator = max(real(total_energy - signal_energy), realmin('double'));
spectrum_vector = 1 ./ denominator;
spectrum = reshape(spectrum_vector, resources.grid_size);
peaks = stage8_k2_cb_peak_picker(spectrum, ...
    resources.az_grid_deg, resources.el_grid_deg);
result.score_call_count = resources.grid_point_count;
result.local_peak_count = peaks.local_peak_count;
result.peak_values = peaks.peak_values;
result.selected_plateau_sizes = peaks.selected_plateau_sizes;
result.online_runtime_sec = toc(clock);
applicable_per_noise = numel(constants.music_applicable_L) * ...
    numel(constants.snr_db_values) * numel(constants.profile_ids);
result.precompute_runtime_sec_amortized = ...
    resource_entry.standalone_precompute_runtime_sec / ...
    applicable_per_noise;
result.runtime_sec = result.online_runtime_sec + ...
    result.precompute_runtime_sec_amortized;
if ~peaks.valid
    result.fit_status = peaks.status;
    return;
end
result.fit_valid = true;
result.fit_status = "MUSIC_K2_VALID";
result.angles_hat_deg = peaks.angles_hat_deg;
result.truth_used_in_fit_flag = false;
result.full_manifold_used_flag = true;
end

function result = empty_result_local(method_id, mode)
result = struct('method_id', method_id, 'observation_domain', mode, ...
    'applicable', true, 'applicability_status', "APPLICABLE", ...
    'fit_valid', false, 'fit_status', "NOT_RUN", ...
    'optimizer_status', "NOT_APPLICABLE", ...
    'angles_hat_deg', NaN(2, 2), 'rss', NaN, ...
    'loglik_concentrated', NaN, 'effective_rank', 0, ...
    'selected_start_id', "", 'start_id', "", 'sweep_count', 0, ...
    'score_call_count', 0, 'svd_call_count', 0, 'eig_call_count', 0, ...
    'runtime_sec', 0, 'online_runtime_sec', 0, ...
    'precompute_runtime_sec_amortized', 0, ...
    'coarse_candidate_count', 0, 'continuous_start_count', 0, ...
    'local_peak_count', 0, 'peak_values', [NaN, NaN], ...
    'selected_plateau_sizes', [0, 0], ...
    'sample_eigenvalues', [], 'sample_rank_threshold', NaN, ...
    'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false, ...
    'tangent_used_in_start_flag', false, ...
    'core_used_in_start_flag', false, ...
    'full_manifold_used_flag', false);
end
