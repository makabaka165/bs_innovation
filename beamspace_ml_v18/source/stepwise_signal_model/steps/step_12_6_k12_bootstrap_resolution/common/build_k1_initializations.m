function [starts, debug] = build_k1_initializations( ...
    local_domain, init_context, opts)
%BUILD_K1_INITIALIZATIONS Return the two registered K1 starts.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isempty(fieldnames(opts))
    error('build_k1_initializations:UnknownOption', ...
        'K1 initialization has no configurable options.');
end
starts = repmat(empty_start_local(), 2, 1);
starts(1) = context_start_local('K1_GROUPED_Q1_KQ1', ...
    'grouped_q1_kq1_angles_deg', init_context, local_domain);
starts(2) = context_start_local('K1_CONVENTIONAL_SINGLETON_PEAK', ...
    'conventional_singleton_peak_deg', init_context, local_domain);
debug = struct('registered_start_ids', string({starts.initialization_id}).', ...
    'registered_start_count', 2, ...
    'available_start_count', nnz([starts.available_flag]), ...
    'scenario_dependent_start_count', 0, 'num_score_eval', 0, ...
    'num_svd', 0, 'phase_factor', 1);
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
if ~(isnumeric(angles) && isequal(size(angles), [1, 2]) && ...
        all(isfinite(angles(:))) && in_domain_local(angles, domain))
    start.initialization_status = 'INITIALIZATION_INPUT_INVALID';
    return;
end
start.angles_deg = angles;
start.available_flag = true;
start.initialization_status = 'INITIALIZATION_READY';
end

function pass = in_domain_local(angles, domain)
bounds = domain.domain_bounds_deg;
pass = all(angles(:, 1) >= bounds(1) & angles(:, 1) <= bounds(2) & ...
    angles(:, 2) >= bounds(3) & angles(:, 2) <= bounds(4));
end

function start = empty_start_local()
start = struct('initialization_id', '', 'source_field', '', ...
    'angles_deg', NaN(1, 2), 'available_flag', false, ...
    'initialization_status', 'INITIALIZATION_NOT_BUILT', ...
    'nested_column_error', NaN, 'initial_rss', NaN, ...
    'nested_rss_tolerance', NaN, 'nested_rss_pass', false, ...
    'anchor_metric_distance', NaN, 'anchor_selection_rule', 'NOT_APPLICABLE');
end
