function [starts, debug] = build_k2_initializations( ...
    full_data, local_domain, model, init_context, k1_fit, opts)
%BUILD_K2_INITIALIZATIONS Return two grouped and one nested K2 start.

if nargin < 6 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'fixed_registered_manifold_provider')
    opts.fixed_registered_manifold_provider = [];
end
if ~isfield(opts, 'fixed_manifold_mode')
    opts.fixed_manifold_mode = 'LEGACY_FULL';
end
opts.fixed_manifold_mode = upper(char(string(opts.fixed_manifold_mode)));
unknown = setdiff(fieldnames(opts), {'rank_multiplier', ...
    'fixed_registered_manifold_provider','fixed_manifold_mode'});
if ~isempty(unknown)
    error('build_k2_initializations:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
starts = repmat(empty_start_local(), 3, 1);
starts(1) = context_start_local('K2_GROUPED_Q1_KQ2', ...
    'grouped_q1_kq2_angles_deg', init_context, local_domain);
starts(2) = context_start_local('K2_GROUPED_Q2_KQ1_PLUS_KQ1', ...
    'grouped_q2_kq1_plus_kq1_angles_deg', init_context, local_domain);
previous_stage = audit_set_query_stage_local('K2_NESTED_ANCHOR');
nested_clock = audit_stage_start_local('K2_NESTED_ANCHOR');
[starts(3), nested_debug] = nested_start_local( ...
    full_data, local_domain, model, k1_fit, opts);
audit_stage_stop_local('K2_NESTED_ANCHOR', nested_clock);
audit_restore_query_stage_local(previous_stage);
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
stage8_k2_tfbc_assert_registered_angles(angles, domain, id);
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
stage8_k2_tfbc_assert_registered_angles(k1_angle, domain, ...
    'K2_NESTED_K1_FIXED_ESTIMATE');
[g_center, derivatives, center_info] = build_full_sequential_local_manifold( ...
    k1_angle, model, struct('rank_multiplier', opts.rank_multiplier));
audit_record_query_local(k1_angle, g_center, center_info, -Inf, false, ...
    true, 'DERIVATIVES_REQUIRED', model, opts.rank_multiplier);
[metric, ~] = compute_projected_jacobian_metric(g_center, ...
    [derivatives.azimuth, derivatives.elevation], struct( ...
    'rank_multiplier', opts.rank_multiplier));
candidates = sortrows(domain.candidate_points_deg, [1, 2]);
stage8_k2_tfbc_assert_registered_angles(candidates, domain, ...
    'K2_NESTED_REGISTERED_CANDIDATES');
debug.num_anchor_candidates = size(candidates, 1);
distance = -Inf(size(candidates, 1), 1);
manifolds = cell(size(candidates, 1), 1);
for index = 1:size(candidates, 1)
    angles = [k1_angle;candidates(index, :)];
    [G_now, ~, info] = fixed_manifold_local( ...
        angles, model, domain, opts);
    audit_record_query_local(angles, G_now, info, -Inf, false, false, ...
        'G_ONLY_ELIGIBLE', model, opts.rank_multiplier);
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
audit_record_nested_score_local();
rss_tolerance = nested_tolerance_local(fit1.rss, initial_rss, ...
    numel(data.Zseq_white));
column_error = norm(G_nested(:, 1) - fit1.G_hat(:, 1)) / ...
    max(norm(fit1.G_hat(:, 1)), realmin);
nested_pass = initial_rss <= fit1.rss + rss_tolerance && ...
    column_error <= 64 * eps(max(size(G_nested))) && ...
    ~score_debug.is_rank_deficient;
start.angles_deg = [k1_angle;anchor];
stage8_k2_tfbc_assert_registered_angles(start.angles_deg, domain, ...
    'K2_NESTED_REGISTERED_START');
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
debug.anchor_index = anchor_index;
debug.anchor_metric_distance = distance(anchor_index);
debug.nested_column_error = column_error;
debug.nested_rss_pass = nested_pass;
audit_record_nested_replay_local(candidates, distance, anchor_index, ...
    k1_angle, fit1, data, model, initial_rss, nested_pass, ...
    rss_tolerance, column_error);
end

function [G, dG, info] = fixed_manifold_local(angles, model, domain, opts)
if strcmp(opts.fixed_manifold_mode, 'LEGACY_FULL') && ...
        isempty(opts.fixed_registered_manifold_provider)
    [G, dG, info] = build_full_sequential_local_manifold( ...
        angles, model, struct('rank_multiplier', opts.rank_multiplier));
    return;
end
[G, dG, info] = stage8_k2_tfbc_get_manifold( ...
    angles, model, domain, opts.fixed_registered_manifold_provider, ...
    struct('mode',opts.fixed_manifold_mode, ...
    'rank_multiplier',opts.rank_multiplier, ...
    'derivatives_required',false, 'allow_legacy_fallback',false));
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

function token = audit_stage_start_local(stage_id)
token = [];
if exist('stage8_k2_tcc_audit_state', 'file') == 2 && ...
        stage8_k2_tcc_audit_state('STAGE_ENABLED')
    token = stage8_k2_tcc_audit_state('STAGE_START', stage_id);
end
end

function audit_stage_stop_local(stage_id, token)
if exist('stage8_k2_tcc_audit_state', 'file') == 2 && ~isempty(token)
    stage8_k2_tcc_audit_state('STAGE_STOP', stage_id, token);
end
end

function previous = audit_set_query_stage_local(stage_id)
previous = '';
if exist('stage8_k2_tcc_audit_state', 'file') == 2
    previous = stage8_k2_tcc_audit_state('SET_QUERY_STAGE', stage_id);
end
end

function audit_restore_query_stage_local(previous)
if exist('stage8_k2_tcc_audit_state', 'file') == 2
    stage8_k2_tcc_audit_state('SET_QUERY_STAGE', previous);
end
end

function audit_record_query_local(angles, G, info, score, scored, ...
    derivatives_required, query_class, model, rank_multiplier)
if exist('stage8_k2_tcc_audit_state', 'file') ~= 2 || ...
        ~stage8_k2_tcc_audit_state('QUERY_ENABLED')
    return;
end
event = struct('stage_id', 'K2_NESTED_ANCHOR', ...
    'angles_deg', angles, 'G', G, 'direct_rank', info.rank_Gseq, ...
    'direct_score', score, 'score_evaluated', logical(scored), ...
    'derivatives_required', logical(derivatives_required), ...
    'query_class', query_class, 'expect_registered', true, ...
    'rank_multiplier', rank_multiplier);
stage8_k2_tcc_audit_state('RECORD_QUERY', event);
end

function audit_record_nested_score_local()
if exist('stage8_k2_tcc_audit_state', 'file') ~= 2 || ...
        ~stage8_k2_tcc_audit_state('QUERY_ENABLED')
    return;
end
stage8_k2_tcc_audit_state('RECORD_AGGREGATE', 'K2_NESTED_ANCHOR', ...
    struct('dml_score_count', 1));
end

function audit_record_nested_replay_local(candidates, distance, anchor_index, ...
    k1_angle, fit1, data, model, initial_rss, nested_pass, tolerance, ...
    column_error)
if exist('stage8_k2_tcc_audit_state', 'file') ~= 2 || ...
        ~stage8_k2_tcc_audit_state('QUERY_ENABLED')
    return;
end
event = struct('stage_id', 'K2_NESTED_ANCHOR', ...
    'candidates', candidates, 'distance', distance, ...
    'direct_anchor_index', anchor_index, 'k1_angle', k1_angle, ...
    'fit1', fit1, 'data', data, 'model', model, ...
    'direct_initial_rss', initial_rss, ...
    'direct_nested_pass', logical(nested_pass), ...
    'rss_tolerance', tolerance, ...
    'direct_first_column_error', column_error);
stage8_k2_tcc_audit_state('RECORD_NESTED', event);
end
