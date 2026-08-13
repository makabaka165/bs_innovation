function result = stage8_k2_sb_root_music(R_fb, model, constants)
%STAGE8_K2_SB_ROOT_MUSIC Standard white-noise vertical FBSS Root-MUSIC.

if nargin < 3 || isempty(constants)
    constants = stage8_k2_sb_constants();
end
method_id = "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML";
result = empty_result_local(method_id);
M = constants.smoothing_length;
if ~(isequal(size(R_fb), [M, M]) && all(isfinite(R_fb(:))))
    error('stage8_k2_sb_root_music:Covariance', ...
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
E_noise = vectors(:, constants.K + 1:end);
Q_noise = E_noise * E_noise';

degree_half = M - 1;
powers = -degree_half:degree_half;
coefficients_ascending = complex(zeros(1, numel(powers)));
for index = 1:numel(powers)
    coefficients_ascending(index) = sum(diag(Q_noise, powers(index)));
end
polynomial_descending = fliplr(coefficients_ascending);
scale = max(abs(polynomial_descending));
if ~(isfinite(scale) && scale > 0)
    result.fit_status = "ROOT_MUSIC_POLYNOMIAL_INVALID";
    result.runtime_sec = toc(clock);
    return;
end
polynomial_descending = polynomial_descending / scale;
all_roots = roots(polynomial_descending);
result.root_count = numel(all_roots);
result.score_call_count = numel(coefficients_ascending);

k0_dz = 2 * pi / model.lambda * ...
    model.array_configuration.arr.dz;
inside = isfinite(real(all_roots)) & isfinite(imag(all_roots)) & ...
    abs(all_roots) <= 1 + constants.root_unit_circle_tolerance & ...
    abs(all_roots) > 0;
candidate_roots = all_roots(inside);
candidate_theta = asind(angle(candidate_roots) / k0_dz);
domain = constants.elevation_domain_deg;
domain_tolerance = 64 * eps(max(abs(domain)));
registered = isfinite(candidate_theta) & ...
    candidate_theta >= domain(1) - domain_tolerance & ...
    candidate_theta <= domain(2) + domain_tolerance;
candidate_roots = candidate_roots(registered);
candidate_theta = candidate_theta(registered);
result.registered_root_count = numel(candidate_roots);
if isempty(candidate_roots)
    result.fit_status = "ROOT_MUSIC_FEWER_THAN_TWO_REGISTERED_ROOTS";
    result.runtime_sec = toc(clock);
    return;
end

ranking = [abs(1 - abs(candidate_roots)), candidate_theta, ...
    angle(candidate_roots), (1:numel(candidate_roots)).'];
[~, order] = sortrows(ranking, [1, 2, 3, 4]);
selected = zeros(0, 1);
for index = 1:numel(order)
    candidate = order(index);
    if isempty(selected) || all(abs(candidate_theta(candidate) - ...
            candidate_theta(selected)) > ...
            constants.root_duplicate_tolerance_deg)
        selected(end + 1, 1) = candidate; %#ok<AGROW>
    end
    if numel(selected) == constants.K
        break;
    end
end
if numel(selected) < constants.K
    result.fit_status = "ROOT_MUSIC_FEWER_THAN_TWO_DISTINCT_ELEVATIONS";
    result.runtime_sec = toc(clock);
    return;
end
theta_hat = candidate_theta(selected).';
roots_hat = candidate_roots(selected).';
[theta_hat, sort_order] = sort(theta_hat);
roots_hat = roots_hat(sort_order);
result.fit_valid = true;
result.fit_status = "ROOT_MUSIC_TWO_ELEVATIONS_VALID";
result.elevations_hat_deg = theta_hat;
result.selected_roots = roots_hat;
result.selected_root_moduli = abs(roots_hat);
result.selection_values = 1 - abs(roots_hat);
result.runtime_sec = toc(clock);
end

function result = empty_result_local(method_id)
result = struct('method_id', method_id, 'applicable', true, ...
    'applicability_status', "APPLICABLE", 'fit_valid', false, ...
    'fit_status', "NOT_RUN", 'elevations_hat_deg', [NaN, NaN], ...
    'selection_values', [NaN, NaN], 'selected_roots', [NaN, NaN], ...
    'selected_root_moduli', [NaN, NaN], ...
    'signal_eigenvalues', [NaN, NaN], 'root_count', 0, ...
    'registered_root_count', 0, 'score_call_count', 0, ...
    'svd_call_count', 0, 'eig_call_count', 0, 'runtime_sec', 0, ...
    'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false);
end
