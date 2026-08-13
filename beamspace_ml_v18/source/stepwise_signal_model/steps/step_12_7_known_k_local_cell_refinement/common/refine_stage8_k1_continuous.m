function [estimate, history, debug] = refine_stage8_k1_continuous( ...
    full_data, initial_angles_deg, local_domain, model, opts)
%REFINE_STAGE8_K1_CONTINUOUS Mechanical lift of the frozen R1 K1 solver.

if nargin < 5, opts = struct(); end
[contract, solver_hash] = solver_contract_local(opts);
validate_inputs_local(full_data, initial_angles_deg, local_domain, model);
clock = tic;
K = size(initial_angles_deg, 1);
angles = canonicalize_local(initial_angles_deg);
score_call_count = 0;
svd_call_count = 0;
monotonicity_violation_count = 0;
[current_score, current_valid] = score_angles_local(angles);
initial_score = current_score;
history_rows = cell(contract.max_sweeps, 1);
converged = false;
sweeps_completed = 0;
last_max_update = NaN;
last_relative_change = NaN;
if current_valid
    for sweep = 1:contract.max_sweeps
        sweep_start_angles = angles;
        sweep_start_score = current_score;
        accepted_update_count = 0;
        for target_index = 1:K
            for dimension_index = 1:2
                x0 = angles(target_index, dimension_index);
                [lower, upper] = coordinate_bounds_local( ...
                    x0, dimension_index, local_domain.domain_bounds_deg, ...
                    contract.coordinate_radius_deg);
                scan_nodes = linspace(lower, upper, ...
                    contract.scan_point_count);
                scan_scores = -Inf(size(scan_nodes));
                for node_index = 1:numel(scan_nodes)
                    candidate = angles;
                    candidate(target_index, dimension_index) = ...
                        scan_nodes(node_index);
                    [scan_scores(node_index), valid_now] = ...
                        score_angles_local(candidate);
                    if ~valid_now, scan_scores(node_index) = -Inf; end
                end
                valid_scan = isfinite(scan_scores);
                if ~any(valid_scan), continue; end
                maximum = max(scan_scores(valid_scan));
                score_tolerance = numeric_tolerance_local(maximum);
                tied = find(valid_scan & ...
                    scan_scores >= maximum - score_tolerance);
                tie_key = [abs(scan_nodes(tied).' - x0), ...
                    scan_nodes(tied).'];
                [~, tie_order] = sortrows(tie_key, [1, 2]);
                best_node_index = tied(tie_order(1));
                left_index = max(1, best_node_index - 1);
                right_index = min(numel(scan_nodes), best_node_index + 1);
                bracket = [scan_nodes(left_index), scan_nodes(right_index)];
                fmin_candidate = scan_nodes(best_node_index);
                if bracket(2) > bracket(1)
                    fopts = optimset('TolX', contract.fminbnd_TolX_deg, ...
                        'MaxFunEvals', contract.fminbnd_MaxFunEvals, ...
                        'Display', 'off');
                    fmin_candidate = fminbnd(@objective_local, ...
                        bracket(1), bracket(2), fopts);
                end
                candidate_values = [x0, scan_nodes(best_node_index), ...
                    fmin_candidate, bracket];
                candidate_values = unique(candidate_values, 'stable');
                candidate_scores = -Inf(size(candidate_values));
                for candidate_index = 1:numel(candidate_values)
                    candidate = angles;
                    candidate(target_index, dimension_index) = ...
                        candidate_values(candidate_index);
                    [candidate_scores(candidate_index), valid_now] = ...
                        score_angles_local(candidate);
                    if ~valid_now, candidate_scores(candidate_index) = -Inf; end
                end
                valid_candidate = isfinite(candidate_scores);
                if ~any(valid_candidate), continue; end
                maximum = max(candidate_scores(valid_candidate));
                score_tolerance = numeric_tolerance_local(maximum);
                tied = find(valid_candidate & ...
                    candidate_scores >= maximum - score_tolerance);
                tie_key = [abs(candidate_values(tied).' - x0), ...
                    candidate_values(tied).'];
                [~, tie_order] = sortrows(tie_key, [1, 2]);
                best = tied(tie_order(1));
                acceptance_tolerance = numeric_tolerance_local(current_score);
                if candidate_scores(best) > current_score + acceptance_tolerance
                    before = current_score;
                    angles(target_index, dimension_index) = ...
                        candidate_values(best);
                    angles = canonicalize_local(angles);
                    current_score = candidate_scores(best);
                    accepted_update_count = accepted_update_count + 1;
                    if current_score + numeric_tolerance_local(before) < before
                        monotonicity_violation_count = ...
                            monotonicity_violation_count + 1;
                    end
                end
            end
        end
        sweeps_completed = sweep;
        last_max_update = max(abs(angles(:) - sweep_start_angles(:)));
        last_relative_change = abs(current_score - sweep_start_score) / ...
            max(1, abs(sweep_start_score));
        history_rows{sweep} = struct('sweep', sweep, ...
            'score_before', sweep_start_score, ...
            'score_after', current_score, ...
            'relative_score_change', last_relative_change, ...
            'max_angle_update_deg', last_max_update, ...
            'accepted_update_count', accepted_update_count);
        if last_max_update <= contract.angle_update_tolerance_deg && ...
                last_relative_change <= contract.relative_score_tolerance
            converged = true;
            break;
        end
    end
end
history_rows = history_rows(1:sweeps_completed);
if isempty(history_rows), history = table(); ...
else, history = struct2table(vertcat(history_rows{:})); end
if ~current_valid
    status = 'CONTINUOUS_REFINEMENT_INITIAL_INVALID';
elseif converged
    status = 'CONTINUOUS_REFINEMENT_CONVERGED';
else
    status = 'CONTINUOUS_REFINEMENT_MAX_SWEEPS';
end
estimate = struct('angles_hat_deg', angles, ...
    'initial_angles_deg', initial_angles_deg, ...
    'initial_score', initial_score, 'final_score', current_score, ...
    'status', status, 'estimate_returned_flag', current_valid, ...
    'converged_flag', converged, ...
    'fit_valid_for_lrt', current_valid && converged, ...
    'sweeps_completed', sweeps_completed, ...
    'max_angle_update_deg', last_max_update, ...
    'relative_score_change', last_relative_change, ...
    'score_call_count', score_call_count, ...
    'svd_call_count', svd_call_count, ...
    'monotonicity_violation_count', monotonicity_violation_count, ...
    'solver_contract_hash', solver_hash, 'runtime_sec', toc(clock));
debug = struct('solver_contract', contract, ...
    'solver_contract_hash', solver_hash, ...
    'initial_full_rank_flag', current_valid || isfinite(initial_score), ...
    'final_full_rank_flag', current_valid, ...
    'score_call_count', score_call_count, ...
    'svd_call_count', svd_call_count, ...
    'monotonicity_violation_count', monotonicity_violation_count);

    function objective = objective_local(value)
        candidate = angles;
        candidate(target_index, dimension_index) = value;
        [score_now, valid_now] = score_angles_local(candidate);
        if valid_now
            objective = -score_now;
        else
            objective = realmax('double') / 16;
        end
    end

    function [score_now, valid_now] = score_angles_local(candidate)
        candidate = canonicalize_local(candidate);
        [G, ~, manifold_info] = build_full_sequential_local_manifold( ...
            candidate, model, struct('rank_multiplier', ...
            contract.rank_multiplier));
        svd_call_count = svd_call_count + manifold_info.num_svd;
        if manifold_info.rank_Gseq < K
            score_now = -Inf;
            valid_now = false;
            return;
        end
        [score_now, ~, ~, ~, effective_rank] = concentrated_dml_rss( ...
            full_data.Zseq_white, G, struct('requested_rank', K, ...
            'rank_multiplier', contract.rank_multiplier, ...
            'compute_projector_checks', false));
        score_call_count = score_call_count + 1;
        svd_call_count = svd_call_count + 1;
        valid_now = effective_rank >= K && isfinite(score_now);
    end
end

function [contract, digest] = solver_contract_local(opts)
contract = struct( ...
    'max_sweeps', 8, ...
    'coordinate_radius_deg', 0.20, ...
    'scan_point_count', 9, ...
    'fminbnd_TolX_deg', 1e-4, ...
    'fminbnd_MaxFunEvals', 80, ...
    'relative_score_tolerance', 1e-9, ...
    'angle_update_tolerance_deg', 1e-3, ...
    'rank_multiplier', 1, ...
    'update_order', 'TARGET_THEN_AZIMUTH_THEN_ELEVATION', ...
    'canonical_order', 'ELEVATION_THEN_AZIMUTH', ...
    'selection_rule', ...
    'MAXIMUM_CONCENTRATED_LOG_LIKELIHOOD_AMONG_VALID_STARTS', ...
    'phase_factor', 1);
if ~(isstruct(opts) && isscalar(opts))
    error('refine_stage8_k1_continuous:Options', ...
        'opts must be a scalar struct.');
end
unknown = setdiff(fieldnames(opts), fieldnames(contract));
if ~isempty(unknown)
    error('refine_stage8_k1_continuous:UnknownOption', ...
        'Unknown solver option: %s.', unknown{1});
end
names = fieldnames(opts);
for index = 1:numel(names)
    if ~isequal(opts.(names{index}), contract.(names{index}))
        error('refine_stage8_k1_continuous:FrozenValue', ...
            'The K1 solver contract is frozen.');
    end
end
digest = stage8_core_v2_2_stable_hash( ...
    'STAGE8_R1_CONTINUOUS_FULL_SEQUENTIAL_DML_SOLVER_V1', contract);
end

function validate_inputs_local(data, angles, domain, model)
if ~(isstruct(data) && isscalar(data) && ...
        isfield(data, 'Zseq_white') && all(isfinite(data.Zseq_white(:))))
    error('refine_stage8_k1_continuous:Data', ...
        'full_data must contain finite Zseq_white.');
end
if ~(isnumeric(angles) && isequal(size(angles), [1, 2]) && ...
        all(isfinite(angles(:))))
    error('refine_stage8_k1_continuous:Angles', ...
        'initial_angles_deg must be one finite K1 row.');
end
if ~(isstruct(domain) && isfield(domain, 'domain_bounds_deg') && ...
        isstruct(model) && model.phase_factor == 1)
    error('refine_stage8_k1_continuous:Contract', ...
        'Domain or model contract is incomplete.');
end
bounds = domain.domain_bounds_deg;
if any(angles(:, 1) < bounds(1) | angles(:, 1) > bounds(2) | ...
        angles(:, 2) < bounds(3) | angles(:, 2) > bounds(4))
    error('refine_stage8_k1_continuous:Domain', ...
        'Initial angles lie outside the local domain.');
end
end

function angles = canonicalize_local(angles)
angles = sortrows(angles, [2, 1]);
end

function [lower, upper] = coordinate_bounds_local(x0, dimension, bounds, radius)
if dimension == 1
    lower = max(bounds(1), x0 - radius);
    upper = min(bounds(2), x0 + radius);
else
    lower = max(bounds(3), x0 - radius);
    upper = min(bounds(4), x0 + radius);
end
end

function value = numeric_tolerance_local(score)
value = 64 * eps(max(1, abs(score)));
end
