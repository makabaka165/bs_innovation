function [starts, debug] = build_k2_initializations( ...
    full_data, local_domain, model, init_context, k1_fit, opts)
%BUILD_K2_INITIALIZATIONS Return two grouped and one nested K2 start.

if nargin < 6 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
unknown = setdiff(fieldnames(opts), {'rank_multiplier'});
if ~isempty(unknown)
    error('build_k2_initializations:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
starts = repmat(empty_start_local(), 3, 1);
starts(1) = context_start_local('K2_GROUPED_Q1_KQ2', ...
    'grouped_q1_kq2_angles_deg', init_context, local_domain);
starts(2) = context_start_local('K2_GROUPED_Q2_KQ1_PLUS_KQ1', ...
    'grouped_q2_kq1_plus_kq1_angles_deg', init_context, local_domain);
[starts(3), nested_debug] = nested_start_local( ...
    full_data, local_domain, model, k1_fit, opts);
debug = nested_debug;
debug.registered_start_ids = string({starts.initialization_id}).';
debug.registered_start_count = 3;
debug.available_start_count = nnz([starts.available_flag]);
debug.scenario_dependent_start_count = 0;
debug.phase_factor = 1;
end

function start = context_start_local(id, field, context, domain)
start = empty_start_local();
start.initialization_id = id;
start.source_field = field;
if ~(isstruct(context) && isscalar(context) && isfield(context, field))
    start.initialization_status = 'INITIALIZATION_INPUT_UNAVAILABLE';
    return;
end
angles = context.(field);
if ~(isnumeric(angles) && isequal(size(angles), [2, 2]) && ...
        all(isfinite(angles(:))) && in_domain_local(angles, domain))
    start.initialization_status = 'INITIALIZATION_INPUT_INVALID';
    return;
end
start.angles_deg = angles;
start.available_flag = true;
start.initialization_status = 'INITIALIZATION_READY';
end

function [start, debug] = nested_start_local(data, domain, model, fit1, opts)
start = empty_start_local();
start.initialization_id = 'K2_K1_EMBEDDED_NESTED_START';
start.source_field = 'best_k1_fit_and_registered_anchor';
debug = struct('num_anchor_candidates', 0, ...
    'num_full_rank_anchor_candidates', 0, 'num_score_eval', 0, ...
    'num_svd', 0, 'metric_id', 'STAGE6_PROJECTED_JACOBIAN_METRIC');
required = {'K','angles_hat_deg','G_hat','rss','estimate_returned_flag', ...
    'fixed_measurement_hash','local_domain_hash'};
if ~(isstruct(fit1) && isscalar(fit1) && all(isfield(fit1, required)) && ...
        fit1.K == 1 && fit1.estimate_returned_flag)
    start.initialization_status = 'K1_FIT_UNAVAILABLE';
    return;
end
if ~strcmp(fit1.fixed_measurement_hash, model.fixed_measurement_hash) || ...
        ~strcmp(fit1.local_domain_hash, domain.domain_hash)
    start.initialization_status = 'K1_CONTRACT_MISMATCH';
    return;
end
k1_angle = fit1.angles_hat_deg(1, :);
[g_center, derivatives] = build_full_sequential_local_manifold( ...
    k1_angle, model, struct('rank_multiplier', opts.rank_multiplier));
[metric, ~] = compute_projected_jacobian_metric(g_center, ...
    [derivatives.azimuth, derivatives.elevation], struct( ...
    'rank_multiplier', opts.rank_multiplier));
candidates = sortrows(domain.candidate_points_deg, [1, 2]);
debug.num_anchor_candidates = size(candidates, 1);
distance = -Inf(size(candidates, 1), 1);
manifolds = cell(size(candidates, 1), 1);
for index = 1:size(candidates, 1)
    angles = [k1_angle;candidates(index, :)];
    [G_now, ~, info] = build_full_sequential_local_manifold( ...
        angles, model, struct('rank_multiplier', opts.rank_multiplier));
    debug.num_svd = debug.num_svd + info.num_svd;
    if info.rank_Gseq == 2
        delta = deg2rad(candidates(index, :) - k1_angle).';
        distance(index) = real(delta.' * metric.T * delta);
        manifolds{index} = G_now;
    end
end
valid = isfinite(distance);
debug.num_full_rank_anchor_candidates = nnz(valid);
if ~any(valid)
    start.initialization_status = 'NO_FULL_RANK_REGISTERED_ANCHOR';
    return;
end
maximum_distance = max(distance(valid));
tolerance = 64 * eps(max(1, abs(maximum_distance)));
anchor_index = find(valid & distance >= maximum_distance - tolerance, 1, 'first');
anchor = candidates(anchor_index, :);
G_nested = manifolds{anchor_index};
[~, initial_rss, score_debug] = beamspace_dml_score_svd( ...
    data.Zseq_white, G_nested, struct('requested_rank', 2, ...
    'rank_multiplier', opts.rank_multiplier, ...
    'compute_projector_checks', false));
debug.num_score_eval = 1;
debug.num_svd = debug.num_svd + 1;
rss_tolerance = nested_tolerance_local(fit1.rss, initial_rss, ...
    numel(data.Zseq_white));
column_error = norm(G_nested(:, 1) - fit1.G_hat(:, 1)) / ...
    max(norm(fit1.G_hat(:, 1)), realmin);
nested_pass = initial_rss <= fit1.rss + rss_tolerance && ...
    column_error <= 64 * eps(max(size(G_nested))) && ...
    ~score_debug.is_rank_deficient;
start.angles_deg = [k1_angle;anchor];
start.available_flag = nested_pass;
start.initialization_status = ternary_local(nested_pass, ...
    'INITIALIZATION_READY', 'NESTED_INITIALIZATION_CONTRACT_FAILED');
start.nested_column_error = column_error;
start.initial_rss = initial_rss;
start.nested_rss_tolerance = rss_tolerance;
start.nested_rss_pass = nested_pass;
start.anchor_metric_distance = distance(anchor_index);
start.anchor_selection_rule = ...
    'MAX_PROJECTED_FISHER_DISTANCE_LEXICOGRAPHIC_FIRST_FULL_RANK';
debug.anchor_angles_deg = anchor;
debug.anchor_metric_distance = distance(anchor_index);
debug.nested_column_error = column_error;
debug.nested_rss_pass = nested_pass;
end

function value = nested_tolerance_local(rss1, rss2, count)
scale = max(abs([rss1,rss2]));
value = 64 * max(count, 1) * eps(scale);
end

function value = ternary_local(condition, yes_value, no_value)
if condition
    value = yes_value;
else
    value = no_value;
end
end

function pass = in_domain_local(angles, domain)
bounds = domain.domain_bounds_deg;
pass = all(angles(:, 1) >= bounds(1) & angles(:, 1) <= bounds(2) & ...
    angles(:, 2) >= bounds(3) & angles(:, 2) <= bounds(4));
end

function start = empty_start_local()
start = struct('initialization_id', '', 'source_field', '', ...
    'angles_deg', NaN(2, 2), 'available_flag', false, ...
    'initialization_status', 'INITIALIZATION_NOT_BUILT', ...
    'nested_column_error', NaN, 'initial_rss', NaN, ...
    'nested_rss_tolerance', NaN, 'nested_rss_pass', false, ...
    'anchor_metric_distance', NaN, 'anchor_selection_rule', 'NOT_APPLICABLE');
end
