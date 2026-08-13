function payload = stage8_k2_wacb_representative_spectra( ...
    spec, rows, fit, resources, model)
%STAGE8_K2_WACB_REPRESENTATIVE_SPECTRA Freeze plot data for one trial.

constants = stage8_k2_wacb_constants();
payload = struct('included', true, 'trial_id', string(spec.trial_id), ...
    'global_trial_index', double(spec.global_trial_index), ...
    'noise_profile_id', string(spec.noise_profile_id), ...
    'profile_id', string(spec.profile_id), ...
    'white_snr_db', double(spec.white_beamspace_snr_target_db), ...
    'L', double(spec.L), 'replicate_id', double(spec.replicate_id), ...
    'element_music', struct(), 'gfbss', struct(), ...
    'root_music', struct(), 'esprit', struct());

covariance = fit.Y_element_white * fit.Y_element_white' / double(spec.L);
covariance = 0.5 * (covariance + covariance');
[vectors, values] = eig(covariance, 'vector');
[values, order] = sort(real(values), 'descend');
vectors = vectors(:, order);
signal = vectors(:, 1:constants.K);
dictionary = resources.music_entry.A_element_white;
denominator = max(real(sum(abs(dictionary).^2, 1) - ...
    sum(abs(signal' * dictionary).^2, 1)), realmin('double'));
spectrum = reshape(1 ./ denominator, resources.grid_size);
peaks = stage8_k2_cb_peak_picker(spectrum, ...
    resources.az_grid_deg, resources.el_grid_deg);
music_row = rows(rows.method_id == "ELEMENT_MUSIC_K2", :);
if logical(music_row.fit_valid) ~= logical(peaks.valid) || ...
        (peaks.valid && string(mat2str(peaks.angles_hat_deg, 17)) ~= ...
        string(music_row.angles_hat_deg))
    error('stage8_k2_wacb_representative_spectra:MusicConsistency', ...
        'Saved Element MUSIC spectrum does not reproduce the method row.');
end
normalized = 10 * log10(spectrum / max(spectrum(:)));
[top_values, top_angles] = top_grid_local(spectrum, ...
    resources.az_grid_deg, resources.el_grid_deg, 10);
payload.element_music = struct('applicable', true, ...
    'fit_valid', logical(music_row.fit_valid), ...
    'fit_status', string(music_row.fit_status), ...
    'az_grid_deg', resources.az_grid_deg, ...
    'el_grid_deg', resources.el_grid_deg, ...
    'normalized_spectrum_db', normalized, ...
    'sample_eigenvalues', values, ...
    'sample_rank', double(music_row.effective_rank), ...
    'local_peak_indices', selected_indices_local( ...
    peaks, resources.az_grid_deg, resources.el_grid_deg), ...
    'top10_peak_values', top_values, 'top10_peak_angles_deg', top_angles, ...
    'selected_peaks_deg', peaks.angles_hat_deg, ...
    'selected_status', peaks.status);

for index = 1:3
    item = fit.structured(index);
    method_id = item.method_id;
    if method_id == "ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML"
        if item.rule.applicable
            spectrum = item.elevation.elevation_spectrum;
            norm_db = 10 * log10(spectrum / max(spectrum));
        else
            spectrum = [];
            norm_db = [];
        end
        payload.gfbss = struct('applicable', item.rule.applicable, ...
            'applicability_status', item.rule.status, ...
            'elevation_grid_deg', constants.elevation_grid_deg, ...
            'normalized_elevation_spectrum_db', norm_db, ...
            'signal_eigenvalues', get_local(item.elevation, ...
            'signal_eigenvalues', [NaN, NaN]), ...
            'candidate_count', get_local(item.elevation, ...
            'elevation_candidate_count', 0), ...
            'selected_elevations_deg', item.elevation.elevations_hat_deg, ...
            'selected_status', item.elevation.fit_status);
    elseif method_id == "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML"
        payload.root_music = root_payload_local( ...
            item, fit.common, model, constants);
    else
        payload.esprit = esprit_payload_local( ...
            item, fit.common, model, constants);
    end
end
end

function value = root_payload_local(item, common, model, constants)
value = struct('applicable', item.rule.applicable, ...
    'applicability_status', item.rule.status, ...
    'polynomial_coefficients', [], 'all_roots', [], ...
    'registered_roots', [], 'selected_roots', [], ...
    'root_elevations_deg', [], 'selected_status', item.elevation.fit_status);
if ~item.rule.applicable
    return;
end
R = 0.5 * (common.R_fb + common.R_fb');
[vectors, values] = eig(R, 'vector');
[~, order] = sort(real(values), 'descend');
Q = vectors(:, order(constants.K + 1:end)) * ...
    vectors(:, order(constants.K + 1:end))';
M = constants.smoothing_length;
powers = -(M - 1):(M - 1);
ascending = complex(zeros(1, numel(powers)));
for index = 1:numel(powers)
    ascending(index) = sum(diag(Q, powers(index)));
end
coefficients = fliplr(ascending);
coefficients = coefficients / max(abs(coefficients));
all_roots = roots(coefficients);
k0_dz = 2 * pi / model.lambda * model.array_configuration.arr.dz;
inside = abs(all_roots) <= 1 + constants.root_unit_circle_tolerance & ...
    abs(all_roots) > 0;
theta = asind(angle(all_roots) / k0_dz);
registered = inside & theta >= constants.elevation_domain_deg(1) & ...
    theta <= constants.elevation_domain_deg(2);
value.polynomial_coefficients = coefficients;
value.all_roots = all_roots;
value.registered_roots = all_roots(registered);
value.root_elevations_deg = theta(registered);
value.selected_roots = get_local(item.elevation, ...
    'selected_roots', [NaN, NaN]);
end

function value = esprit_payload_local(item, common, model, constants)
value = struct('applicable', item.rule.applicable, ...
    'applicability_status', item.rule.status, 'S1_singular_values', [], ...
    'Psi_eigenvalues', [], 'moduli', [], 'phases', [], ...
    'estimated_elevations_deg', item.elevation.elevations_hat_deg, ...
    'selected_status', item.elevation.fit_status);
if ~item.rule.applicable
    return;
end
R = 0.5 * (common.R_fb + common.R_fb');
[vectors, values] = eig(R, 'vector');
[~, order] = sort(real(values), 'descend');
U = vectors(:, order(1:constants.K));
S1 = U(1:end-1, :);
S2 = U(2:end, :);
singular_values = svd(S1, 'econ');
Psi = pinv(S1) * S2;
eigenvalues = eig(Psi).';
k0_dz = 2 * pi / model.lambda * model.array_configuration.arr.dz;
value.S1_singular_values = singular_values;
value.Psi_eigenvalues = eigenvalues;
value.moduli = abs(eigenvalues);
value.phases = angle(eigenvalues);
value.reconstructed_elevations_deg = ...
    sort(asind(angle(eigenvalues) / k0_dz));
end

function [values, angles] = top_grid_local(spectrum, az, el, count)
[sorted, order] = sort(spectrum(:), 'descend');
order = order(1:min(count, numel(order)));
values = sorted(1:numel(order)).';
[row, column] = ind2sub(size(spectrum), order);
angles = [az(row).', el(column).'];
end

function indices = selected_indices_local(peaks, az, el)
indices = zeros(0, 2);
if ~peaks.valid
    return;
end
for index = 1:2
    row = find(abs(az - peaks.angles_hat_deg(index, 1)) <= 1e-12, 1);
    column = find(abs(el - peaks.angles_hat_deg(index, 2)) <= 1e-12, 1);
    indices(index, :) = [row, column]; %#ok<AGROW>
end
end

function value = get_local(input, field, default)
if isfield(input, field)
    value = input.(field);
else
    value = default;
end
end
