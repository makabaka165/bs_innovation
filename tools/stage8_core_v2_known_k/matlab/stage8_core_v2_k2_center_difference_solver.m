function [estimate, history, debug] = ...
    stage8_core_v2_k2_center_difference_solver( ...
    full_data, initial_angles_deg, local_domain, model, opts)
%STAGE8_CORE_V2_K2_CENTER_DIFFERENCE_SOLVER Optimize c and d without swaps.

if nargin < 5, opts = struct(); end
constants = stage8_core_v2_constants();
contract = constants.k2_solver_contract;
validate_options_local(opts, contract);
validate_inputs_local(full_data, initial_angles_deg, local_domain, model);
contract_hash = stage8_stable_hash( ...
    'STAGE8_CORE_V2_K2_CENTER_DIFFERENCE_SOLVER_CONTRACT_V2', contract);

clock = tic;
initial_sorted = sortrows(initial_angles_deg, [2, 1]);
c = mean(initial_sorted, 1);
d = initial_sorted(2, :) - initial_sorted(1, :);
if d(2) < -1e-12 || (abs(d(2)) <= 1e-12 && d(1) < 0)
    d = -d;
end
if abs(d(2)) <= 1e-12, d(2) = 0; end
parameters = [c(1), c(2), d(1), d(2)];
initial_parameters = parameters;
score_call_count = 0;
svd_call_count = 0;
monotonicity_violation_count = 0;
[current_score, initial_rss, initial_rank, current_valid] = ...
    score_parameters_local(parameters);
initial_score = current_score;
initial_full_rank = current_valid && initial_rank >= 2;
history_rows = cell(contract.max_sweeps, 1);
status = 'K2_CENTER_DIFFERENCE_NOT_OPERATIONAL';
sweeps_completed = 0;
last_relative_change = NaN;
last_endpoint_update = NaN;

if current_valid
    radii = [contract.center_radius_deg, contract.center_radius_deg, ...
        contract.delta_az_radius_deg, contract.delta_el_radius_deg];
    for sweep = 1:contract.max_sweeps
        sweep_start_endpoints = endpoints_local(parameters);
        sweep_start_score = current_score;
        accepted_update_count = 0;
        for coordinate = 1:4
            x0 = parameters(coordinate);
            [global_lower, global_upper] = ...
                global_bounds_local(parameters, coordinate, ...
                local_domain.domain_bounds_deg);
            lower = max(global_lower, x0 - radii(coordinate));
            upper = min(global_upper, x0 + radii(coordinate));
            if ~(isfinite(lower) && isfinite(upper) && lower <= upper)
                continue;
            end
            scan_nodes = linspace(lower, upper, contract.scan_point_count);
            scan_scores = -Inf(size(scan_nodes));
            for node = 1:numel(scan_nodes)
                candidate = parameters;
                candidate(coordinate) = scan_nodes(node);
                [scan_scores(node), ~, ~, valid_now] = ...
                    score_parameters_local(candidate);
                if ~valid_now, scan_scores(node) = -Inf; end
            end
            valid_scan = isfinite(scan_scores);
            if ~any(valid_scan), continue; end
            best_node = choose_tied_local(scan_nodes, scan_scores, x0);
            left_index = max(1, best_node - 1);
            right_index = min(numel(scan_nodes), best_node + 1);
            bracket = [scan_nodes(left_index), scan_nodes(right_index)];
            refined = scan_nodes(best_node);
            if bracket(2) > bracket(1)
                fopts = optimset('TolX', contract.fminbnd_TolX_deg, ...
                    'MaxFunEvals', contract.fminbnd_MaxFunEvals, ...
                    'Display', 'off');
                refined = fminbnd(@objective_local, bracket(1), ...
                    bracket(2), fopts);
            end
            values = unique([x0, scan_nodes(best_node), refined, bracket], ...
                'stable');
            scores = -Inf(size(values));
            for candidate_index = 1:numel(values)
                candidate = parameters;
                candidate(coordinate) = values(candidate_index);
                [scores(candidate_index), ~, ~, valid_now] = ...
                    score_parameters_local(candidate);
                if ~valid_now, scores(candidate_index) = -Inf; end
            end
            if ~any(isfinite(scores)), continue; end
            best = choose_tied_local(values, scores, x0);
            acceptance = numeric_tolerance_local(current_score);
            if scores(best) > current_score + acceptance
                before = current_score;
                parameters(coordinate) = values(best);
                current_score = scores(best);
                accepted_update_count = accepted_update_count + 1;
                if current_score + numeric_tolerance_local(before) < before
                    monotonicity_violation_count = ...
                        monotonicity_violation_count + 1;
                end
            end
        end
        sweeps_completed = sweep;
        final_endpoints = endpoints_local(parameters);
        last_endpoint_update = max(vecnorm( ...
            final_endpoints - sweep_start_endpoints, 2, 2));
        last_relative_change = abs(current_score - sweep_start_score) / ...
            max(1, abs(sweep_start_score));
        history_rows{sweep} = struct('sweep', sweep, ...
            'score_before', sweep_start_score, ...
            'score_after', current_score, ...
            'relative_score_change', last_relative_change, ...
            'max_endpoint_update_deg', last_endpoint_update, ...
            'accepted_update_count', accepted_update_count, ...
            'c_az', parameters(1), 'c_el', parameters(2), ...
            'd_az', parameters(3), 'd_el', parameters(4));
        if accepted_update_count == 0
            status = 'K2_CENTER_DIFFERENCE_STATIONARY';
            break;
        end
        if last_relative_change <= contract.relative_score_tolerance && ...
                last_endpoint_update <= ...
                contract.endpoint_update_tolerance_deg
            status = 'K2_CENTER_DIFFERENCE_CONVERGED';
            break;
        end
    end
end

history_rows = history_rows(1:sweeps_completed);
if isempty(history_rows), history = table(); ...
else, history = struct2table(vertcat(history_rows{:})); end
[final_score, final_rss, final_rank, final_valid] = ...
    score_parameters_local(parameters);
current_score = final_score;
if current_valid && sweeps_completed == contract.max_sweeps && ...
        strcmp(status, 'K2_CENTER_DIFFERENCE_NOT_OPERATIONAL')
    recent_ok = height(history) >= 3 && all( ...
        history.relative_score_change(end-2:end) <= ...
        contract.usable_relative_tolerance);
    if recent_ok && last_endpoint_update <= ...
            contract.usable_endpoint_tolerance_deg && ...
            monotonicity_violation_count == 0 && final_valid && ...
            final_rank >= 2 && isfinite(final_score) && isfinite(final_rss)
        status = 'K2_CENTER_DIFFERENCE_MAX_SWEEPS_USABLE';
    end
end
usable = any(strcmp(status, { ...
    'K2_CENTER_DIFFERENCE_STATIONARY', ...
    'K2_CENTER_DIFFERENCE_CONVERGED', ...
    'K2_CENTER_DIFFERENCE_MAX_SWEEPS_USABLE'})) && ...
    final_valid && monotonicity_violation_count == 0;
angles = endpoints_local(parameters);
estimate = struct('angles_hat_deg', angles, ...
    'initial_angles_deg', initial_sorted, ...
    'initial_parameters', initial_parameters, ...
    'final_parameters', parameters, 'initial_score', initial_score, ...
    'final_score', current_score, 'initial_rss', initial_rss, ...
    'final_rss', final_rss, 'status', status, ...
    'estimate_returned_flag', final_valid, ...
    'converged_flag', usable, 'usable_flag', usable, ...
    'sweeps_completed', sweeps_completed, ...
    'relative_score_change', last_relative_change, ...
    'max_endpoint_update_deg', last_endpoint_update, ...
    'score_call_count', score_call_count, ...
    'svd_call_count', svd_call_count, ...
    'monotonicity_violation_count', monotonicity_violation_count, ...
    'solver_contract_hash', contract_hash, 'runtime_sec', toc(clock));
debug = struct('solver_contract', contract, ...
    'solver_contract_hash', contract_hash, ...
    'initial_c', initial_parameters(1:2), ...
    'initial_d', initial_parameters(3:4), ...
    'final_c', parameters(1:2), 'final_d', parameters(3:4), ...
    'initial_full_rank_flag', initial_full_rank, ...
    'final_full_rank_flag', final_valid && final_rank >= 2, ...
    'score_call_count', score_call_count, ...
    'svd_call_count', svd_call_count, ...
    'monotonicity_violation_count', monotonicity_violation_count);

    function objective = objective_local(value)
        candidate = parameters;
        candidate(coordinate) = value;
        [score_now, ~, ~, valid_now] = score_parameters_local(candidate);
        if valid_now, objective = -score_now; ...
        else, objective = realmax('double') / 16; end
    end

    function [score_now, rss_now, rank_now, valid_now] = ...
            score_parameters_local(candidate)
        endpoints = endpoints_local(candidate);
        valid_now = feasible_local(candidate, endpoints, ...
            local_domain.domain_bounds_deg, contract.minimum_separation_deg);
        score_now = -Inf;
        rss_now = Inf;
        rank_now = 0;
        if ~valid_now, return; end
        [G, ~, manifold_info] = build_full_sequential_local_manifold( ...
            endpoints, model, struct('rank_multiplier', ...
            contract.rank_multiplier));
        svd_call_count = svd_call_count + manifold_info.num_svd;
        rank_now = manifold_info.rank_Gseq;
        if rank_now < 2, valid_now = false; return; end
        [score_now, rss_now, ~, ~, effective_rank] = ...
            concentrated_dml_rss(full_data.Zseq_white, G, struct( ...
            'requested_rank', 2, 'rank_multiplier', ...
            contract.rank_multiplier, 'compute_projector_checks', false));
        score_call_count = score_call_count + 1;
        svd_call_count = svd_call_count + 1;
        rank_now = min(rank_now, effective_rank);
        valid_now = rank_now >= 2 && isfinite(score_now) && ...
            isfinite(rss_now) && rss_now >= 0;
    end
end

function validate_options_local(opts, contract)
if ~(isstruct(opts) && isscalar(opts))
    error('stage8_core_v2_k2_center_difference_solver:Options', ...
        'opts must be a scalar struct.');
end
names = fieldnames(opts);
allowed = fieldnames(contract);
if ~all(ismember(names, allowed))
    error('stage8_core_v2_k2_center_difference_solver:Options', ...
        'Unknown solver option.');
end
for index = 1:numel(names)
    if ~isequal(opts.(names{index}), contract.(names{index}))
        error('stage8_core_v2_k2_center_difference_solver:FrozenContract', ...
            'The K2 solver contract is fixed by the protocol.');
    end
end
end

function validate_inputs_local(data, angles, domain, model)
valid_data = isstruct(data) && isscalar(data) && ...
    isfield(data, 'Zseq_white') && isnumeric(data.Zseq_white) && ...
    all(isfinite(data.Zseq_white(:)));
valid_angles = isnumeric(angles) && isequal(size(angles), [2, 2]) && ...
    all(isfinite(angles(:)));
valid_contract = isstruct(domain) && isfield(domain, 'domain_bounds_deg') && ...
    isstruct(model) && isfield(model, 'phase_factor') && ...
    model.phase_factor == 1;
if ~(valid_data && valid_angles && valid_contract)
    error('stage8_core_v2_k2_center_difference_solver:Input', ...
        'Data, K2 angles, domain, or model is invalid.');
end
end

function endpoints = endpoints_local(parameters)
c = parameters(1:2);
d = parameters(3:4);
endpoints = [c - d / 2; c + d / 2];
end

function valid = feasible_local(parameters, endpoints, bounds, minimum)
d = parameters(3:4);
valid = d(2) >= 0 && ~(abs(d(2)) <= 1e-12 && d(1) < 0) && ...
    norm(d) >= minimum && ...
    all(endpoints(:, 1) >= bounds(1) & endpoints(:, 1) <= bounds(2) & ...
    endpoints(:, 2) >= bounds(3) & endpoints(:, 2) <= bounds(4));
end

function [lower, upper] = global_bounds_local(parameters, coordinate, bounds)
c_az = parameters(1); c_el = parameters(2);
d_az = parameters(3); d_el = parameters(4);
switch coordinate
    case 1
        lower = bounds(1) + abs(d_az) / 2;
        upper = bounds(2) - abs(d_az) / 2;
    case 2
        lower = bounds(3) + d_el / 2;
        upper = bounds(4) - d_el / 2;
    case 3
        extent = 2 * min(c_az - bounds(1), bounds(2) - c_az);
        lower = -extent; upper = extent;
    case 4
        lower = 0;
        upper = 2 * min(c_el - bounds(3), bounds(4) - c_el);
    otherwise
        error('stage8_core_v2_k2_center_difference_solver:Coordinate', ...
            'Coordinate index is invalid.');
end
end

function index = choose_tied_local(values, scores, current)
valid = isfinite(scores);
maximum = max(scores(valid));
tolerance = numeric_tolerance_local(maximum);
tied = find(valid & scores >= maximum - tolerance);
key = [abs(values(tied).' - current), values(tied).'];
[~, order] = sortrows(key, [1, 2]);
index = tied(order(1));
end

function value = numeric_tolerance_local(score)
value = 64 * eps(max(1, abs(score)));
end
