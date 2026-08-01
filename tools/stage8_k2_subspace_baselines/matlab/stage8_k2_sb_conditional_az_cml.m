function result = stage8_k2_sb_conditional_az_cml( ...
    Y_element_white, elevations_hat_deg, model, whitening, constants)
%STAGE8_K2_SB_CONDITIONAL_AZ_CML Full-element CML over two azimuths.

if nargin < 5 || isempty(constants)
    constants = stage8_k2_sb_constants();
end
result = empty_result_local();
if ~(isnumeric(Y_element_white) && ismatrix(Y_element_white) && ...
        size(Y_element_white, 1) == size(model.Rn_elem, 1) && ...
        all(isfinite(Y_element_white(:))) && ...
        isnumeric(elevations_hat_deg) && ...
        isequal(size(elevations_hat_deg), [1, 2]) && ...
        all(isfinite(elevations_hat_deg)))
    error('stage8_k2_sb_conditional_az_cml:Inputs', ...
        'Whitened data and two finite elevations are required.');
end
if ~(isstruct(whitening) && isfield(whitening, 'whitener'))
    error('stage8_k2_sb_conditional_az_cml:Whitening', ...
        'A verified full-element whitener is required.');
end
elevations_hat_deg = sort(elevations_hat_deg);
if abs(diff(elevations_hat_deg)) <= ...
        constants.elevation_distinct_tolerance_deg
    result.fit_status = "CONDITIONAL_AZ_CML_REPEATED_ELEVATION";
    return;
end

clock = tic;
score_call_count = 0;
svd_call_count = 0;
cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
grid = constants.azimuth_grid_deg;
grid_count = numel(grid);
pair_count = grid_count ^ 2;
result.coarse_candidate_count = pair_count;

angles_first = [grid(:), repmat(elevations_hat_deg(1), grid_count, 1)];
angles_second = [grid(:), repmat(elevations_hat_deg(2), grid_count, 1)];
dictionary_first = stage8_k2_cb_build_element_manifold( ...
    angles_first, model, whitening);
dictionary_second = stage8_k2_cb_build_element_manifold( ...
    angles_second, model, whitening);

coarse = repmat(coarse_template_local(), pair_count, 1);
pair_index = 0;
for first = 1:grid_count
    for second = 1:grid_count
        pair_index = pair_index + 1;
        azimuths = [grid(first), grid(second)];
        G = [dictionary_first(:, first), dictionary_second(:, second)];
        evaluation = score_prebuilt_local(azimuths, G);
        coarse(pair_index) = struct('pair_index', pair_index, ...
            'start_id', string(sprintf('AZ_GRID_%02d_%02d', ...
            first, second)), 'azimuths_deg', azimuths, ...
            'evaluation', evaluation);
    end
end
if pair_index ~= pair_count
    error('stage8_k2_sb_conditional_az_cml:CoarseCount', ...
        'The complete ordered azimuth grid was not enumerated.');
end

valid_indices = find(arrayfun(@(item) item.evaluation.valid, coarse));
if isempty(valid_indices)
    result.fit_status = "CONDITIONAL_AZ_CML_NO_VALID_COARSE_PAIR";
    result.optimizer_status = result.fit_status;
    finish_local();
    return;
end
ranking = zeros(numel(valid_indices), 4);
for index = 1:numel(valid_indices)
    item = coarse(valid_indices(index));
    ranking(index, :) = [-item.evaluation.loglik, ...
        item.azimuths_deg, item.pair_index];
end
[~, order] = sortrows(ranking, [1, 2, 3, 4]);
start_count = min(constants.top_start_count, numel(order));
selected = valid_indices(order(1:start_count));
result.continuous_start_count = start_count;
result.best_coarse_loglik = coarse(selected(1)).evaluation.loglik;

starts = repmat(start_template_local(), start_count, 1);
for index = 1:start_count
    starts(index) = optimize_start_local( ...
        coarse(selected(index)).azimuths_deg, ...
        coarse(selected(index)).start_id);
end
valid_starts = find([starts.valid]);
if isempty(valid_starts)
    result.fit_status = "CONDITIONAL_AZ_CML_NO_VALID_CONTINUOUS_START";
    result.optimizer_status = result.fit_status;
    finish_local();
    return;
end
best = valid_starts(1);
for index = valid_starts(2:end)
    tolerance = numeric_tolerance_local(starts(best).loglik);
    if starts(index).loglik > starts(best).loglik + tolerance
        best = index;
    end
end
chosen = starts(best);
result.fit_valid = true;
result.fit_status = "CONDITIONAL_AZ_CML_VALID";
result.optimizer_status = chosen.optimizer_status;
result.azimuths_hat_deg = chosen.azimuths_deg;
result.angles_hat_deg = [chosen.azimuths_deg(1), elevations_hat_deg(1); ...
    chosen.azimuths_deg(2), elevations_hat_deg(2)];
result.rss = chosen.rss;
result.loglik_concentrated = chosen.loglik;
result.effective_rank = chosen.effective_rank;
result.selected_start_id = chosen.start_id;
result.sweep_count = chosen.sweep_count;
finish_local();

    function start = optimize_start_local(initial_azimuths, start_id)
        azimuths = initial_azimuths;
        current = score_pair_local(azimuths);
        start = start_template_local();
        start.start_id = start_id;
        if ~current.valid
            start.optimizer_status = "INITIAL_CANDIDATE_INVALID";
            return;
        end
        status = "CONDITIONAL_AZ_CML_MAX_SWEEPS_VALID";
        sweeps = 0;
        for sweep = 1:constants.max_sweeps
            start_azimuths = azimuths;
            start_loglik = current.loglik;
            accepted = 0;
            for coordinate = 1:2
                current_value = azimuths(coordinate);
                scan_values = linspace(constants.azimuth_domain_deg(1), ...
                    constants.azimuth_domain_deg(2), ...
                    constants.scan_nodes_per_coordinate);
                scans = repmat(evaluation_template_local(), ...
                    numel(scan_values), 1);
                for node = 1:numel(scan_values)
                    candidate = azimuths;
                    candidate(coordinate) = scan_values(node);
                    scans(node) = score_pair_local(candidate);
                end
                valid_scan = find([scans.valid]);
                if isempty(valid_scan)
                    continue;
                end
                best_scan = choose_local(scan_values, scans, ...
                    valid_scan, current_value);
                left = max(1, best_scan - 1);
                right = min(numel(scan_values), best_scan + 1);
                bracket = [scan_values(left), scan_values(right)];
                refined = scan_values(best_scan);
                if bracket(2) > bracket(1)
                    options = optimset('TolX', ...
                        constants.fminbnd_TolX_deg, 'MaxFunEvals', ...
                        constants.fminbnd_MaxFunEvals, 'Display', 'off');
                    refined = fminbnd(@(value) objective_local( ...
                        value, azimuths, coordinate), ...
                        bracket(1), bracket(2), options);
                end
                values = unique([current_value, scan_values(best_scan), ...
                    bracket, refined], 'stable');
                candidates = repmat(evaluation_template_local(), ...
                    numel(values), 1);
                for candidate_index = 1:numel(values)
                    candidate = azimuths;
                    candidate(coordinate) = values(candidate_index);
                    candidates(candidate_index) = score_pair_local(candidate);
                end
                valid_candidates = find([candidates.valid]);
                if isempty(valid_candidates)
                    continue;
                end
                choice = choose_local(values, candidates, ...
                    valid_candidates, current_value);
                tolerance = numeric_tolerance_local(current.loglik);
                if candidates(choice).loglik > current.loglik + tolerance
                    azimuths(coordinate) = values(choice);
                    current = candidates(choice);
                    accepted = accepted + 1;
                end
            end
            sweeps = sweep;
            relative_change = abs(current.loglik - start_loglik) / ...
                max(1, abs(start_loglik));
            coordinate_change = max(abs(azimuths - start_azimuths));
            if accepted == 0
                status = "CONDITIONAL_AZ_CML_STATIONARY";
                break;
            end
            if relative_change <= constants.relative_score_tolerance && ...
                    coordinate_change <= ...
                    constants.coordinate_update_tolerance_deg
                status = "CONDITIONAL_AZ_CML_CONVERGED";
                break;
            end
        end
        final = score_pair_local(azimuths);
        start.valid = final.valid;
        start.optimizer_status = status;
        start.start_id = start_id;
        start.sweep_count = sweeps;
        start.azimuths_deg = azimuths;
        start.rss = final.rss;
        start.loglik = final.loglik;
        start.effective_rank = final.effective_rank;
    end

    function objective = objective_local(value, base, coordinate)
        candidate = base;
        candidate(coordinate) = value;
        evaluation = score_pair_local(candidate);
        if evaluation.valid
            objective = -evaluation.loglik;
        else
            objective = realmax('double') / 16;
        end
    end

    function evaluation = score_pair_local(azimuths)
        key = key_local(azimuths);
        if isKey(cache, key)
            evaluation = cache(key);
            return;
        end
        angles = [azimuths(1), elevations_hat_deg(1); ...
            azimuths(2), elevations_hat_deg(2)];
        G = stage8_k2_cb_build_element_manifold( ...
            angles, model, whitening);
        evaluation = score_manifold_local(azimuths, G);
        cache(key) = evaluation;
    end

    function evaluation = score_prebuilt_local(azimuths, G)
        key = key_local(azimuths);
        if isKey(cache, key)
            evaluation = cache(key);
            return;
        end
        evaluation = score_manifold_local(azimuths, G);
        cache(key) = evaluation;
    end

    function evaluation = score_manifold_local(azimuths, G)
        evaluation = evaluation_template_local();
        evaluation.azimuths_deg = azimuths;
        [score, rss, sigma2_hat, loglik, effective_rank] = ...
            concentrated_dml_rss(Y_element_white, G, struct( ...
            'requested_rank', constants.K, ...
            'rank_multiplier', constants.rank_multiplier, ...
            'compute_projector_checks', false));
        score_call_count = score_call_count + 1;
        svd_call_count = svd_call_count + 1;
        evaluation.score = score;
        evaluation.rss = rss;
        evaluation.sigma2_hat = sigma2_hat;
        evaluation.loglik = loglik;
        evaluation.effective_rank = effective_rank;
        evaluation.valid = effective_rank >= constants.K && ...
            isfinite(score) && isfinite(rss) && rss >= 0 && ...
            isfinite(sigma2_hat) && sigma2_hat >= 0 && isfinite(loglik);
        if evaluation.valid
            evaluation.status = "VALID";
        else
            evaluation.status = "NUMERIC_INVALID";
        end
    end

    function finish_local()
        result.score_call_count = score_call_count;
        result.svd_call_count = svd_call_count;
        result.runtime_sec = toc(clock);
    end
end

function key = key_local(azimuths)
key = sprintf('%.17g|%.17g', azimuths(1), azimuths(2));
end

function choice = choose_local(values, evaluations, valid, current)
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

function item = coarse_template_local()
item = struct('pair_index', 0, 'start_id', "", ...
    'azimuths_deg', [NaN, NaN], ...
    'evaluation', evaluation_template_local());
end

function item = start_template_local()
item = struct('valid', false, 'optimizer_status', "NOT_RUN", ...
    'start_id', "", 'sweep_count', 0, ...
    'azimuths_deg', [NaN, NaN], 'rss', NaN, ...
    'loglik', -Inf, 'effective_rank', 0);
end

function evaluation = evaluation_template_local()
evaluation = struct('valid', false, 'status', "NOT_RUN", ...
    'azimuths_deg', [NaN, NaN], 'score', -Inf, 'rss', Inf, ...
    'sigma2_hat', Inf, 'loglik', -Inf, 'effective_rank', 0);
end

function result = empty_result_local()
result = struct('applicable', true, 'applicability_status', "APPLICABLE", ...
    'fit_valid', false, 'fit_status', "NOT_RUN", ...
    'optimizer_status', "NOT_RUN", ...
    'azimuths_hat_deg', [NaN, NaN], ...
    'angles_hat_deg', NaN(2, 2), 'rss', NaN, ...
    'loglik_concentrated', NaN, 'effective_rank', 0, ...
    'selected_start_id', "", 'sweep_count', 0, ...
    'score_call_count', 0, 'svd_call_count', 0, ...
    'eig_call_count', 0, 'runtime_sec', 0, ...
    'coarse_candidate_count', 0, 'continuous_start_count', 0, ...
    'best_coarse_loglik', NaN, 'truth_used_in_fit_flag', false, ...
    'profile_used_in_fit_flag', false, ...
    'tangent_used_in_start_flag', false, ...
    'core_used_in_start_flag', false, ...
    'full_manifold_used_flag', true);
end
