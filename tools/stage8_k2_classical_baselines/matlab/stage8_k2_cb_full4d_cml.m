function result = stage8_k2_cb_full4d_cml( ...
    data_white, model, local_domain, observation_domain, whitening, constants)
%STAGE8_K2_CB_FULL4D_CML Deterministic bounded four-coordinate CML fit.

if nargin < 6 || isempty(constants)
    constants = stage8_k2_cb_constants();
end
mode = upper(string(observation_domain));
if ~ismember(mode, ["BEAMSPACE", "ELEMENT"])
    error('stage8_k2_cb_full4d_cml:Mode', ...
        'observation_domain must be BEAMSPACE or ELEMENT.');
end
if ~(isnumeric(data_white) && ismatrix(data_white) && ...
        ~isempty(data_white) && all(isfinite(data_white(:))))
    error('stage8_k2_cb_full4d_cml:Data', ...
        'Whitened observations must be finite and nonempty.');
end
if mode == "ELEMENT" && ...
        ~(isstruct(whitening) && isfield(whitening, 'whitener'))
    error('stage8_k2_cb_full4d_cml:Whitening', ...
        'Element CML requires a verified whitener.');
end

clock = tic;
score_call_count = 0;
svd_call_count = 0;
evaluation_cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
points = local_domain.candidate_points_deg;
pair_count = size(points, 1) * (size(points, 1) - 1) / 2;
coarse = repmat(coarse_template_local(), pair_count, 1);
pair_index = 0;
for first = 1:size(points, 1)-1
    for second = first+1:size(points, 1)
        pair_index = pair_index + 1;
        angles = sortrows(points([first, second], :), [2, 1]);
        parameters = parameters_from_angles_local(angles);
        evaluation = score_parameters_local(parameters);
        coarse(pair_index) = struct('pair_index', pair_index, ...
            'first_point_index', first, 'second_point_index', second, ...
            'start_id', string(sprintf('GRID_PAIR_%03d_%03d', ...
            first, second)), 'parameters', parameters, ...
            'evaluation', evaluation);
    end
end
if pair_index ~= pair_count
    error('stage8_k2_cb_full4d_cml:CoarseCount', ...
        'The complete unordered grid-pair enumeration failed.');
end

valid_indices = find(arrayfun(@(x) x.evaluation.valid, coarse));
result = empty_result_local(mode, pair_count);
if isempty(valid_indices)
    result.fit_status = 'FULL4D_CML_NO_VALID_COARSE_PAIR';
    result.optimizer_status = result.fit_status;
    result.score_call_count = score_call_count;
    result.svd_call_count = svd_call_count;
    result.runtime_sec = toc(clock);
    return;
end
ranking = zeros(numel(valid_indices), 6);
for index = 1:numel(valid_indices)
    item = coarse(valid_indices(index));
    angles = item.evaluation.angles_deg;
    ranking(index, :) = [-item.evaluation.loglik, ...
        angles(1, 1), angles(1, 2), angles(2, 1), angles(2, 2), ...
        item.pair_index];
end
[~, order] = sortrows(ranking, 1:6);
start_count = min(constants.top_start_count, numel(order));
selected_coarse = valid_indices(order(1:start_count));
result.best_coarse_loglik = ...
    coarse(selected_coarse(1)).evaluation.loglik;
result.continuous_start_count = start_count;

starts = repmat(start_template_local(), start_count, 1);
for index = 1:start_count
    item = coarse(selected_coarse(index));
    starts(index) = optimize_start_local(item.parameters, item.start_id);
end
valid_starts = find([starts.valid]);
if isempty(valid_starts)
    result.fit_status = 'FULL4D_CML_NO_VALID_CONTINUOUS_START';
    result.optimizer_status = result.fit_status;
    result.score_call_count = score_call_count;
    result.svd_call_count = svd_call_count;
    result.runtime_sec = toc(clock);
    return;
end
best = valid_starts(1);
for index = valid_starts(2:end)
    tolerance = numeric_tolerance_local(starts(best).loglik);
    if starts(index).loglik > starts(best).loglik + tolerance
        best = index;
    end
end
selected = starts(best);
result.fit_valid = true;
result.fit_status = 'FULL4D_CML_VALID';
result.optimizer_status = selected.optimizer_status;
result.angles_hat_deg = selected.angles_deg;
result.rss = selected.rss;
result.loglik_concentrated = selected.loglik;
result.effective_rank = selected.effective_rank;
result.selected_start_id = selected.start_id;
result.start_id = selected.start_id;
result.sweep_count = selected.sweep_count;
result.score_call_count = score_call_count;
result.svd_call_count = svd_call_count;
result.runtime_sec = toc(clock);
result.truth_used_in_fit_flag = false;
result.profile_used_in_fit_flag = false;
result.tangent_used_in_start_flag = false;
result.core_used_in_start_flag = false;
result.full_manifold_used_flag = true;

    function start = optimize_start_local(initial_parameters, start_id)
        parameters = initial_parameters;
        current = score_parameters_local(parameters);
        start = start_template_local();
        start.start_id = start_id;
        if ~current.valid
            start.optimizer_status = "INITIAL_CANDIDATE_INVALID";
            return;
        end
        status = "FULL4D_CML_MAX_SWEEPS_VALID";
        sweeps = 0;
        for sweep = 1:constants.max_sweeps
            sweep_start_angles = current.angles_deg;
            sweep_start_loglik = current.loglik;
            accepted = 0;
            for coordinate = 1:4
                current_value = parameters(coordinate);
                [lower_bound, upper_bound] = global_bounds_local( ...
                    parameters, coordinate, ...
                    local_domain.domain_bounds_deg);
                if ~(isfinite(lower_bound) && isfinite(upper_bound) && ...
                        lower_bound <= upper_bound)
                    continue;
                end
                scan_values = linspace(lower_bound, upper_bound, ...
                    constants.scan_nodes_per_coordinate);
                scan_evaluations = repmat(evaluation_template_local(), ...
                    numel(scan_values), 1);
                for node = 1:numel(scan_values)
                    candidate = parameters;
                    candidate(coordinate) = scan_values(node);
                    scan_evaluations(node) = score_parameters_local(candidate);
                end
                valid_scan = find([scan_evaluations.valid]);
                if isempty(valid_scan)
                    continue;
                end
                best_scan = choose_evaluation_local( ...
                    scan_values, scan_evaluations, valid_scan, current_value);
                left = max(1, best_scan - 1);
                right = min(numel(scan_values), best_scan + 1);
                bracket = [scan_values(left), scan_values(right)];
                refined = scan_values(best_scan);
                if bracket(2) > bracket(1)
                    fopts = optimset('TolX', constants.fminbnd_TolX_deg, ...
                        'MaxFunEvals', constants.fminbnd_MaxFunEvals, ...
                        'Display', 'off');
                    refined = fminbnd(@(value) objective_local( ...
                        value, parameters, coordinate), bracket(1), ...
                        bracket(2), fopts);
                end
                values = unique([current_value, scan_values(best_scan), ...
                    bracket, refined], 'stable');
                candidates = repmat(evaluation_template_local(), ...
                    numel(values), 1);
                for candidate_index = 1:numel(values)
                    candidate = parameters;
                    candidate(coordinate) = values(candidate_index);
                    candidates(candidate_index) = ...
                        score_parameters_local(candidate);
                end
                valid_candidates = find([candidates.valid]);
                if isempty(valid_candidates)
                    continue;
                end
                choice = choose_evaluation_local(values, candidates, ...
                    valid_candidates, current_value);
                tolerance = numeric_tolerance_local(current.loglik);
                if candidates(choice).loglik > current.loglik + tolerance
                    parameters(coordinate) = values(choice);
                    current = candidates(choice);
                    accepted = accepted + 1;
                end
            end
            sweeps = sweep;
            endpoint_update = max(vecnorm( ...
                current.angles_deg - sweep_start_angles, 2, 2));
            relative_change = abs(current.loglik - sweep_start_loglik) / ...
                max(1, abs(sweep_start_loglik));
            if accepted == 0
                status = "FULL4D_CML_STATIONARY";
                break;
            end
            if relative_change <= constants.relative_score_tolerance && ...
                    endpoint_update <= ...
                    constants.endpoint_update_tolerance_deg
                status = "FULL4D_CML_CONVERGED";
                break;
            end
        end
        final = score_parameters_local(parameters);
        start.valid = final.valid;
        start.optimizer_status = status;
        start.start_id = start_id;
        start.sweep_count = sweeps;
        start.angles_deg = final.angles_deg;
        start.rss = final.rss;
        start.loglik = final.loglik;
        start.effective_rank = final.effective_rank;
    end

    function objective = objective_local(value, base, coordinate)
        candidate = base;
        candidate(coordinate) = value;
        evaluation = score_parameters_local(candidate);
        if evaluation.valid
            objective = -evaluation.loglik;
        else
            objective = realmax('double') / 16;
        end
    end

    function evaluation = score_parameters_local(parameters)
        cache_key = sprintf('%.17g|%.17g|%.17g|%.17g', parameters);
        if isKey(evaluation_cache, cache_key)
            evaluation = evaluation_cache(cache_key);
            return;
        end
        evaluation = evaluation_template_local();
        angles = endpoints_local(parameters);
        evaluation.angles_deg = angles;
        if ~feasible_local(parameters, angles, ...
                local_domain.domain_bounds_deg, ...
                constants.minimum_separation_deg)
            evaluation.status = "INFEASIBLE_ENDPOINTS";
            evaluation_cache(cache_key) = evaluation;
            return;
        end
        manifold_svd = 0;
        if mode == "BEAMSPACE"
            [G, ~, manifold_info] = build_full_sequential_local_manifold( ...
                angles, model, struct('rank_multiplier', ...
                constants.rank_multiplier));
            manifold_svd = manifold_info.num_svd;
            if manifold_info.rank_Gseq < 2
                svd_call_count = svd_call_count + manifold_svd;
                evaluation.status = "MANIFOLD_RANK_DEFICIENT";
                evaluation_cache(cache_key) = evaluation;
                return;
            end
        else
            G = stage8_k2_cb_build_element_manifold( ...
                angles, model, whitening);
        end
        [score, rss, sigma2_hat, loglik, effective_rank] = ...
            concentrated_dml_rss(data_white, G, struct( ...
            'requested_rank', 2, 'rank_multiplier', ...
            constants.rank_multiplier, 'compute_projector_checks', false));
        score_call_count = score_call_count + 1;
        svd_call_count = svd_call_count + manifold_svd + 1;
        evaluation.score = score;
        evaluation.rss = rss;
        evaluation.sigma2_hat = sigma2_hat;
        evaluation.loglik = loglik;
        evaluation.effective_rank = effective_rank;
        evaluation.valid = effective_rank >= 2 && isfinite(score) && ...
            isfinite(rss) && rss >= 0 && isfinite(sigma2_hat) && ...
            sigma2_hat >= 0 && isfinite(loglik);
        if evaluation.valid
            evaluation.status = "VALID";
        else
            evaluation.status = "NUMERIC_INVALID";
        end
        evaluation_cache(cache_key) = evaluation;
    end
end

function result = empty_result_local(mode, pair_count)
if mode == "BEAMSPACE"
    method_id = "FULL4D_BEAMSPACE_CML_MULTISTART";
else
    method_id = "FULL4D_ELEMENT_CML_MULTISTART";
end
result = struct('method_id', method_id, 'observation_domain', mode, ...
    'applicable', true, 'applicability_status', "APPLICABLE", ...
    'fit_valid', false, 'fit_status', "NOT_RUN", ...
    'optimizer_status', "NOT_RUN", 'angles_hat_deg', NaN(2, 2), ...
    'rss', NaN, 'loglik_concentrated', NaN, 'effective_rank', 0, ...
    'selected_start_id', "", 'start_id', "", 'sweep_count', 0, ...
    'score_call_count', 0, 'svd_call_count', 0, 'eig_call_count', 0, ...
    'runtime_sec', 0, 'online_runtime_sec', NaN, ...
    'coarse_candidate_count', pair_count, 'continuous_start_count', 0, ...
    'best_coarse_loglik', NaN, 'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false, ...
    'tangent_used_in_start_flag', false, ...
    'core_used_in_start_flag', false, ...
    'full_manifold_used_flag', false);
end

function item = coarse_template_local()
item = struct('pair_index', 0, 'first_point_index', 0, ...
    'second_point_index', 0, 'start_id', "", ...
    'parameters', NaN(1, 4), 'evaluation', evaluation_template_local());
end

function item = start_template_local()
item = struct('valid', false, 'optimizer_status', "NOT_RUN", ...
    'start_id', "", 'sweep_count', 0, 'angles_deg', NaN(2, 2), ...
    'rss', NaN, 'loglik', -Inf, 'effective_rank', 0);
end

function evaluation = evaluation_template_local()
evaluation = struct('valid', false, 'status', "NOT_RUN", ...
    'angles_deg', NaN(2, 2), 'score', -Inf, 'rss', Inf, ...
    'sigma2_hat', Inf, 'loglik', -Inf, 'effective_rank', 0);
end

function parameters = parameters_from_angles_local(angles)
angles = sortrows(angles, [2, 1]);
parameters = [mean(angles, 1), angles(2, :) - angles(1, :)];
end

function angles = endpoints_local(parameters)
center = parameters(1:2);
difference = parameters(3:4);
angles = [center - difference / 2; center + difference / 2];
end

function valid = feasible_local(parameters, angles, bounds, minimum)
difference = parameters(3:4);
tolerance = 64 * eps(max(1, max(abs(bounds))));
canonical = difference(2) >= -tolerance && ...
    ~(abs(difference(2)) <= tolerance && difference(1) < -tolerance);
valid = canonical && norm(difference) >= minimum && ...
    all(angles(:, 1) >= bounds(1) - tolerance & ...
    angles(:, 1) <= bounds(2) + tolerance & ...
    angles(:, 2) >= bounds(3) - tolerance & ...
    angles(:, 2) <= bounds(4) + tolerance);
end

function [lower, upper] = global_bounds_local(parameters, coordinate, bounds)
center_az = parameters(1);
center_el = parameters(2);
difference_az = parameters(3);
difference_el = parameters(4);
switch coordinate
    case 1
        lower = bounds(1) + abs(difference_az) / 2;
        upper = bounds(2) - abs(difference_az) / 2;
    case 2
        lower = bounds(3) + max(0, difference_el) / 2;
        upper = bounds(4) - max(0, difference_el) / 2;
    case 3
        extent = 2 * min(center_az - bounds(1), bounds(2) - center_az);
        lower = -extent;
        upper = extent;
    case 4
        lower = 0;
        upper = 2 * min(center_el - bounds(3), bounds(4) - center_el);
    otherwise
        error('stage8_k2_cb_full4d_cml:Coordinate', ...
            'Coordinate index is invalid.');
end
end

function choice = choose_evaluation_local(values, evaluations, valid, current)
loglik = [evaluations.loglik];
maximum = max(loglik(valid));
tolerance = numeric_tolerance_local(maximum);
tied = valid(loglik(valid) >= maximum - tolerance);
key = [abs(values(tied).' - current), values(tied).'];
[~, order] = sortrows(key, [1, 2]);
choice = tied(order(1));
end

function tolerance = numeric_tolerance_local(value)
tolerance = 64 * eps(max(1, abs(value)));
end
