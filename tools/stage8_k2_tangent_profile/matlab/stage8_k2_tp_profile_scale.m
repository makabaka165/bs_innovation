function result = stage8_k2_tp_profile_scale( ...
    Z_white, model, center_deg, direction_hat, local_domain, constants)
%STAGE8_K2_TP_PROFILE_SCALE Profile exact K2 likelihood over one scale.

if nargin < 6 || isempty(constants)
    constants = stage8_k2_tp_constants();
end
validate_inputs_local(Z_white, center_deg, direction_hat, local_domain);
clock = tic;
direction_hat = direction_hat(:) / norm(direction_hat);
bounds = local_domain.domain_bounds_deg;
lower_distance = center_deg - [bounds(1), bounds(3)];
upper_distance = [bounds(2), bounds(4)] - center_deg;
rho_limits = Inf(1, 2);
for dimension = 1:2
    if abs(direction_hat(dimension)) > eps
        rho_limits(dimension) = 2 * min(lower_distance(dimension), ...
            upper_distance(dimension)) / abs(direction_hat(dimension));
    end
end
rho_max = min(rho_limits);
result = empty_result_local(rho_max);
if ~(isfinite(rho_max) && rho_max >= constants.rho_min_deg)
    result.status = 'TANGENT_PROFILE_NO_FEASIBLE_SCALE';
    result.runtime_sec = toc(clock);
    return;
end

evaluated_rho = zeros(0, 1);
evaluations = repmat(evaluation_template_local(), 0, 1);
score_calls = 0;
svd_calls = 0;
scan_nodes = linspace(constants.rho_min_deg, rho_max, ...
    constants.scan_node_count);
scan_evaluations = repmat(evaluation_template_local(), ...
    constants.scan_node_count, 1);
for index = 1:numel(scan_nodes)
    scan_evaluations(index) = evaluate_rho_local(scan_nodes(index));
end
scan_loglik = [scan_evaluations.loglik_concentrated];
valid_scan = [scan_evaluations.valid] & isfinite(scan_loglik);
if ~any(valid_scan)
    result.status = 'TANGENT_PROFILE_NO_VALID_SCAN_NODE';
    result.score_call_count = score_calls;
    result.svd_call_count = svd_calls;
    result.runtime_sec = toc(clock);
    return;
end
[~, best_relative] = max(scan_loglik(valid_scan));
valid_indices = find(valid_scan);
best_scan_index = valid_indices(best_relative);
left_index = max(1, best_scan_index - 1);
right_index = min(numel(scan_nodes), best_scan_index + 1);
bracket = [scan_nodes(left_index), scan_nodes(right_index)];
fmin_candidate = scan_nodes(best_scan_index);
if bracket(2) > bracket(1)
    fopts = optimset('TolX', constants.fminbnd_TolX_deg, ...
        'MaxFunEvals', constants.fminbnd_MaxFunEvals, 'Display', 'off');
    fmin_candidate = fminbnd(@objective_local, ...
        bracket(1), bracket(2), fopts);
end
candidate_rho = [scan_nodes(best_scan_index), bracket, fmin_candidate];
candidate_evaluations = repmat(evaluation_template_local(), ...
    numel(candidate_rho), 1);
for index = 1:numel(candidate_rho)
    candidate_evaluations(index) = evaluate_rho_local(candidate_rho(index));
end
candidate_loglik = [candidate_evaluations.loglik_concentrated];
candidate_valid = [candidate_evaluations.valid] & isfinite(candidate_loglik);
if ~any(candidate_valid)
    result.status = 'TANGENT_PROFILE_FINAL_CANDIDATE_INVALID';
    result.score_call_count = score_calls;
    result.svd_call_count = svd_calls;
    result.runtime_sec = toc(clock);
    return;
end
[~, best_relative] = max(candidate_loglik(candidate_valid));
valid_indices = find(candidate_valid);
selected = candidate_evaluations(valid_indices(best_relative));
result.valid = true;
result.status = 'TANGENT_PROFILE_VALID';
result.rho_hat_deg = selected.rho_deg;
result.angles_hat_deg = selected.angles_deg;
result.score = selected.score;
result.rss = selected.rss;
result.sigma2_hat = selected.sigma2_hat;
result.loglik_concentrated = selected.loglik_concentrated;
result.effective_rank = selected.effective_rank;
result.score_call_count = score_calls;
result.svd_call_count = svd_calls;
result.scan_nodes_deg = scan_nodes;
result.best_scan_node_deg = scan_nodes(best_scan_index);
result.bracket_deg = bracket;
result.fminbnd_candidate_deg = fmin_candidate;
result.endpoint_in_domain_flag = endpoints_in_domain_local( ...
    selected.angles_deg, bounds);
result.full_manifold_used_flag = true;
result.evaluated_rho_deg = evaluated_rho;
result.runtime_sec = toc(clock);

    function objective = objective_local(rho)
        evaluation = evaluate_rho_local(rho);
        if evaluation.valid && isfinite(evaluation.loglik_concentrated)
            objective = -evaluation.loglik_concentrated;
        else
            objective = realmax('double') / 16;
        end
    end

    function evaluation = evaluate_rho_local(rho)
        existing = find(evaluated_rho == rho, 1, 'first');
        if ~isempty(existing)
            evaluation = evaluations(existing);
            return;
        end
        evaluation = evaluation_template_local();
        evaluation.rho_deg = rho;
        direction_row = direction_hat(:).';
        angles = [center_deg - rho * direction_row / 2; ...
            center_deg + rho * direction_row / 2];
        evaluation.angles_deg = sortrows(angles, [2, 1]);
        if ~endpoints_in_domain_local(evaluation.angles_deg, bounds)
            evaluation.status = 'ENDPOINT_OUTSIDE_DOMAIN';
            store_evaluation_local();
            return;
        end
        [G, ~, manifold_info] = build_full_sequential_local_manifold( ...
            evaluation.angles_deg, model, ...
            struct('rank_multiplier', constants.rank_multiplier));
        svd_calls = svd_calls + manifold_info.num_svd;
        if manifold_info.rank_Gseq < 2
            evaluation.status = 'K2_MANIFOLD_RANK_DEFICIENT';
            store_evaluation_local();
            return;
        end
        [score, rss, sigma2_hat, loglik, effective_rank] = ...
            concentrated_dml_rss(Z_white, G, struct( ...
            'requested_rank', 2, 'rank_multiplier', ...
            constants.rank_multiplier, 'compute_projector_checks', false));
        score_calls = score_calls + 1;
        svd_calls = svd_calls + 1;
        evaluation.score = score;
        evaluation.rss = rss;
        evaluation.sigma2_hat = sigma2_hat;
        evaluation.loglik_concentrated = loglik;
        evaluation.effective_rank = effective_rank;
        evaluation.valid = effective_rank >= 2 && isfinite(score) && ...
            isfinite(rss) && rss >= 0 && isfinite(sigma2_hat) && ...
            sigma2_hat >= 0 && isfinite(loglik);
        if evaluation.valid
            evaluation.status = 'VALID_FULL_MANIFOLD_K2_SCORE';
        else
            evaluation.status = 'INVALID_FULL_MANIFOLD_K2_SCORE';
        end
        store_evaluation_local();

        function store_evaluation_local()
            evaluated_rho(end + 1, 1) = rho; %#ok<AGROW>
            evaluations(end + 1, 1) = evaluation; %#ok<AGROW>
        end
    end
end

function result = empty_result_local(rho_max)
result = struct('valid', false, 'status', 'NOT_RUN', ...
    'rho_hat_deg', NaN, 'rho_max_deg', double(rho_max), ...
    'angles_hat_deg', NaN(2, 2), 'score', NaN, 'rss', NaN, ...
    'sigma2_hat', NaN, 'loglik_concentrated', NaN, ...
    'effective_rank', 0, 'score_call_count', 0, 'svd_call_count', 0, ...
    'scan_nodes_deg', [], 'best_scan_node_deg', NaN, ...
    'bracket_deg', [NaN, NaN], 'fminbnd_candidate_deg', NaN, ...
    'endpoint_in_domain_flag', false, ...
    'full_manifold_used_flag', false, 'evaluated_rho_deg', [], ...
    'runtime_sec', 0);
end

function evaluation = evaluation_template_local()
evaluation = struct('valid', false, 'status', 'NOT_RUN', ...
    'rho_deg', NaN, 'angles_deg', NaN(2, 2), 'score', NaN, ...
    'rss', NaN, 'sigma2_hat', NaN, 'loglik_concentrated', -Inf, ...
    'effective_rank', 0);
end

function flag = endpoints_in_domain_local(angles, bounds)
tolerance = 64 * eps(max(1, max(abs(bounds))));
flag = all(angles(:, 1) >= bounds(1) - tolerance & ...
    angles(:, 1) <= bounds(2) + tolerance & ...
    angles(:, 2) >= bounds(3) - tolerance & ...
    angles(:, 2) <= bounds(4) + tolerance);
end

function validate_inputs_local(Z, center, direction, domain)
if ~(isa(Z, 'double') && ismatrix(Z) && ~isempty(Z) && ...
        all(isfinite(Z(:))) && isnumeric(center) && isreal(center) && ...
        isequal(size(center), [1, 2]) && all(isfinite(center)) && ...
        isnumeric(direction) && isreal(direction) && numel(direction) == 2 && ...
        all(isfinite(direction(:))) && norm(direction) > 0 && ...
        isstruct(domain) && isfield(domain, 'domain_bounds_deg'))
    error('stage8_k2_tp_profile_scale:Input', ...
        'Profile inputs violate the finite full-manifold contract.');
end
bounds = domain.domain_bounds_deg;
if center(1) < bounds(1) || center(1) > bounds(2) || ...
        center(2) < bounds(3) || center(2) > bounds(4)
    error('stage8_k2_tp_profile_scale:CenterDomain', ...
        'The K1 center lies outside the frozen local domain.');
end
end
