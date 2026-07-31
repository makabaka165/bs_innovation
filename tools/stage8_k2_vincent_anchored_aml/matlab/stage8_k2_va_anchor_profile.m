function profile = stage8_k2_va_anchor_profile( ...
    Z_white, model, center_deg, axis_hat, local_domain, constants)
%STAGE8_K2_VA_ANCHOR_PROFILE Search t and conditionally profile rho.

if nargin < 6 || isempty(constants)
    constants = stage8_k2_va_constants();
end
validate_inputs_local(Z_white, model, center_deg, axis_hat, local_domain, ...
    constants);
clock = tic;
center = reshape(double(center_deg), 1, 2);
axis = double(axis_hat(:)) / norm(axis_hat);
[t_min, t_max, line_status] = line_interval_local(center, axis, ...
    local_domain.domain_bounds_deg, constants.direction_sign_tolerance);
profile = profile_template_local(t_min, t_max, line_status);
if line_status ~= "LINE_INTERVAL_VALID"
    profile.status = char(line_status);
    profile.runtime_sec = toc(clock);
    return;
end
t_scan_max = t_max - constants.rho_min_deg;
if ~(isfinite(t_scan_max) && t_scan_max >= t_min)
    profile.status = 'ANCHOR_PROFILE_NO_FEASIBLE_ANCHOR';
    profile.runtime_sec = toc(clock);
    return;
end

R_Z = Z_white * Z_white';
scan_nodes = linspace(t_min, t_scan_max, ...
    constants.anchor_scan_node_count);
evaluated_t = zeros(0, 1);
evaluations = repmat(evaluation_template_local(), 0, 1);
score_calls = 0;
svd_calls = 0;
scan = repmat(evaluation_template_local(), numel(scan_nodes), 1);
for index = 1:numel(scan_nodes)
    scan(index) = evaluate_anchor_local(scan_nodes(index));
end
profile.anchor_scan_node_count = numel(scan_nodes);
profile.scan_nodes_deg = scan_nodes;
profile.raw_anchor_valid_count = nnz([scan.valid]);
profile.conditional_invalid_count = nnz(~[scan.conditional_valid]);
profile.q2_nonconcave_count = nnz(strcmp({scan.conditional_status}, ...
    'CONDITIONAL_RHO_NONCONCAVE'));
conditional_status = string({scan.conditional_status});
profile.rho_out_of_contract_count = nnz( ...
    contains(conditional_status, 'ABOVE_LINE_LIMIT') | ...
    contains(conditional_status, 'OUT_OF_CLOSE_CONTRACT') | ...
    contains(conditional_status, 'ABOVE_FEASIBLE_LIMIT'));

valid_scan = find([scan.valid] & isfinite([scan.loglik_concentrated]));
if isempty(valid_scan)
    profile.status = 'ANCHOR_PROFILE_NO_VALID_SCAN_NODE';
    profile.score_call_count = score_calls;
    profile.svd_call_count = svd_calls;
    profile.evaluated_t_deg = evaluated_t;
    profile.runtime_sec = toc(clock);
    return;
end
[~, best_relative] = max([scan(valid_scan).loglik_concentrated]);
best_scan_index = valid_scan(best_relative);
candidate_t = scan_nodes(best_scan_index);
bracket = [NaN, NaN];
fmin_candidate = NaN;
has_valid_bracket = best_scan_index > 1 && ...
    best_scan_index < numel(scan_nodes) && ...
    scan(best_scan_index - 1).valid && scan(best_scan_index + 1).valid;
if has_valid_bracket
    bracket = [scan_nodes(best_scan_index - 1), ...
        scan_nodes(best_scan_index + 1)];
    fopts = optimset('TolX', constants.anchor_fminbnd_TolX_deg, ...
        'MaxFunEvals', constants.anchor_fminbnd_MaxFunEvals, ...
        'Display', 'off');
    fmin_candidate = fminbnd(@objective_local, bracket(1), bracket(2), fopts);
    candidate_t = unique([candidate_t, bracket, fmin_candidate], 'stable');
end
candidate = repmat(evaluation_template_local(), numel(candidate_t), 1);
for index = 1:numel(candidate_t)
    candidate(index) = evaluate_anchor_local(candidate_t(index));
end
valid_candidate = find([candidate.valid] & ...
    isfinite([candidate.loglik_concentrated]));
if isempty(valid_candidate)
    profile.status = 'ANCHOR_PROFILE_FINAL_CANDIDATE_INVALID';
    profile.score_call_count = score_calls;
    profile.svd_call_count = svd_calls;
    profile.evaluated_t_deg = evaluated_t;
    profile.runtime_sec = toc(clock);
    return;
end
[~, selected_relative] = max([candidate(valid_candidate).loglik_concentrated]);
selected = candidate(valid_candidate(selected_relative));
profile.valid = true;
profile.status = 'ANCHOR_PROFILE_VALID';
profile.selected_t_deg = selected.t_deg;
profile.selected_rho_deg = selected.rho_deg;
profile.selected_alpha_deg = selected.t_deg + selected.rho_deg / 2;
profile.angles_hat_deg = selected.angles_deg;
profile.score = selected.score;
profile.rss = selected.rss;
profile.sigma2_hat = selected.sigma2_hat;
profile.loglik_concentrated = selected.loglik_concentrated;
profile.effective_rank = selected.effective_rank;
profile.q0 = selected.q0;
profile.q1 = selected.q1;
profile.q2 = selected.q2;
profile.curvature_valid_flag = selected.curvature_valid_flag;
profile.B0_rank = selected.B0_rank;
profile.B0_condition = selected.B0_condition;
profile.projector_expansion_status = selected.projector_expansion_status;
profile.conditional_status = selected.conditional_status;
profile.best_scan_node_deg = scan_nodes(best_scan_index);
profile.bracket_deg = bracket;
profile.fminbnd_candidate_deg = fmin_candidate;
profile.score_call_count = score_calls;
profile.svd_call_count = svd_calls;
profile.evaluated_t_deg = evaluated_t;
profile.full_manifold_used_flag = true;
profile.runtime_sec = toc(clock);

    function objective = objective_local(t_now)
        evaluation = evaluate_anchor_local(t_now);
        if evaluation.valid && isfinite(evaluation.loglik_concentrated)
            objective = -evaluation.loglik_concentrated;
        else
            objective = realmax('double') / 16;
        end
    end

    function evaluation = evaluate_anchor_local(t_now)
        existing = find(evaluated_t == t_now, 1, 'first');
        if ~isempty(existing)
            evaluation = evaluations(existing);
            return;
        end
        evaluation = evaluation_template_local();
        evaluation.t_deg = t_now;
        anchor = center + t_now * axis.';
        evaluation.anchor_deg = anchor;
        derivatives = stage8_k2_va_directional_derivatives( ...
            anchor, axis, model);
        expansion = stage8_k2_va_projector_expansion(derivatives, ...
            constants.rank_multiplier);
        svd_calls = svd_calls + expansion.num_svd;
        evaluation.B0_rank = expansion.B0_rank;
        evaluation.B0_condition = expansion.B0_condition;
        evaluation.projector_expansion_status = expansion.status;
        conditional = stage8_k2_va_conditional_rho(expansion, R_Z, ...
            t_max - t_now, constants);
        evaluation.q0 = conditional.q0;
        evaluation.q1 = conditional.q1;
        evaluation.q2 = conditional.q2;
        evaluation.rho_deg = conditional.rho_AML_deg;
        evaluation.conditional_valid = conditional.valid;
        evaluation.curvature_valid_flag = conditional.curvature_valid_flag;
        evaluation.conditional_status = conditional.status;
        if ~conditional.valid
            evaluation.status = conditional.status;
            store_evaluation_local();
            return;
        end
        angles = [anchor; center + (t_now + conditional.rho_AML_deg) * axis.'];
        evaluation.angles_deg = angles;
        if ~endpoints_in_domain_local(angles, ...
                local_domain.domain_bounds_deg)
            evaluation.status = 'ANCHOR_PROFILE_ENDPOINT_OUTSIDE_DOMAIN';
            store_evaluation_local();
            return;
        end
        [G, ~, manifold_info] = build_full_sequential_local_manifold( ...
            angles, model, struct('rank_multiplier', ...
            constants.rank_multiplier));
        svd_calls = svd_calls + manifold_info.num_svd;
        if manifold_info.rank_Gseq < 2
            evaluation.status = 'ANCHOR_PROFILE_MANIFOLD_RANK_DEFICIENT';
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
            evaluation.status = 'VALID_FULL_MANIFOLD_ANCHORED_SCORE';
        else
            evaluation.status = 'INVALID_FULL_MANIFOLD_ANCHORED_SCORE';
        end
        store_evaluation_local();

        function store_evaluation_local()
            evaluated_t(end + 1, 1) = t_now; %#ok<AGROW>
            evaluations(end + 1, 1) = evaluation; %#ok<AGROW>
        end
    end
end

function profile = profile_template_local(t_min, t_max, line_status)
profile = struct('valid', false, 'status', 'NOT_RUN', ...
    'line_status', char(line_status), 'line_t_min_deg', double(t_min), ...
    'line_t_max_deg', double(t_max), 'anchor_scan_node_count', 0, ...
    'scan_nodes_deg', [], 'raw_anchor_valid_count', 0, ...
    'conditional_invalid_count', 0, 'q2_nonconcave_count', 0, ...
    'rho_out_of_contract_count', 0, ...
    'selected_t_deg', NaN, 'selected_rho_deg', NaN, ...
    'selected_alpha_deg', NaN, 'angles_hat_deg', NaN(2, 2), ...
    'score', NaN, 'rss', NaN, 'sigma2_hat', NaN, ...
    'loglik_concentrated', NaN, 'effective_rank', 0, ...
    'q0', NaN, 'q1', NaN, 'q2', NaN, ...
    'curvature_valid_flag', false, 'B0_rank', 0, ...
    'B0_condition', Inf, 'projector_expansion_status', 'NOT_RUN', ...
    'conditional_status', 'NOT_RUN', 'best_scan_node_deg', NaN, ...
    'bracket_deg', [NaN, NaN], 'fminbnd_candidate_deg', NaN, ...
    'score_call_count', 0, 'svd_call_count', 0, ...
    'evaluated_t_deg', [], 'full_manifold_used_flag', false, ...
    'runtime_sec', 0);
end

function evaluation = evaluation_template_local()
evaluation = struct('valid', false, 'status', 'NOT_RUN', ...
    'conditional_valid', false, 'conditional_status', 'NOT_RUN', ...
    'curvature_valid_flag', false, 't_deg', NaN, 'anchor_deg', [NaN, NaN], ...
    'rho_deg', NaN, 'angles_deg', NaN(2, 2), 'q0', NaN, 'q1', NaN, ...
    'q2', NaN, 'B0_rank', 0, 'B0_condition', Inf, ...
    'projector_expansion_status', 'NOT_RUN', 'score', NaN, 'rss', NaN, ...
    'sigma2_hat', NaN, 'loglik_concentrated', -Inf, ...
    'effective_rank', 0);
end

function [t_min, t_max, status] = line_interval_local(center, axis, bounds, tolerance)
t_min = -Inf;
t_max = Inf;
for dimension = 1:2
    if abs(axis(dimension)) <= tolerance
        if center(dimension) < bounds(2 * dimension - 1) || ...
                center(dimension) > bounds(2 * dimension)
            status = "LINE_INTERVAL_CENTER_OUTSIDE_DOMAIN";
            return;
        end
        continue;
    end
    intersections = [(bounds(2 * dimension - 1) - center(dimension)) / ...
        axis(dimension), (bounds(2 * dimension) - center(dimension)) / ...
        axis(dimension)];
    t_min = max(t_min, min(intersections));
    t_max = min(t_max, max(intersections));
end
if ~(isfinite(t_min) && isfinite(t_max) && t_min <= t_max)
    status = "LINE_INTERVAL_INVALID";
else
    status = "LINE_INTERVAL_VALID";
end
end

function flag = endpoints_in_domain_local(angles, bounds)
tolerance = 64 * eps(max(1, max(abs(bounds))));
flag = all(angles(:, 1) >= bounds(1) - tolerance & ...
    angles(:, 1) <= bounds(2) + tolerance & ...
    angles(:, 2) >= bounds(3) - tolerance & ...
    angles(:, 2) <= bounds(4) + tolerance);
end

function validate_inputs_local(Z, model, center, axis, domain, constants)
required = {'domain_bounds_deg'};
if ~(isnumeric(Z) && ismatrix(Z) && ~isempty(Z) && all(isfinite(Z(:))) && ...
        isstruct(model) && isscalar(model) && isnumeric(center) && ...
        isreal(center) && numel(center) == 2 && all(isfinite(center(:))) && ...
        isnumeric(axis) && isreal(axis) && numel(axis) == 2 && ...
        all(isfinite(axis(:))) && norm(axis) > 0 && isstruct(domain) && ...
        all(isfield(domain, required)) && isstruct(constants) && ...
        isfield(constants, 'rho_min_deg') && ...
        isfield(constants, 'anchor_scan_node_count') && ...
        isfield(constants, 'rho_close_contract_max_deg'))
    error('stage8_k2_va_anchor_profile:Input', ...
        'Anchor-profile inputs violate the finite frozen contract.');
end
bounds = domain.domain_bounds_deg;
if center(1) < bounds(1) || center(1) > bounds(2) || ...
        center(2) < bounds(3) || center(2) > bounds(4)
    error('stage8_k2_va_anchor_profile:CenterDomain', ...
        'The K1 center lies outside the frozen local domain.');
end
end
