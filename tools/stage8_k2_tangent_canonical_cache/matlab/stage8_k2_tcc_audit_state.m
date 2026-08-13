function varargout = stage8_k2_tcc_audit_state(action, varargin)
%STAGE8_K2_TCC_AUDIT_STATE Task-specific diagnostic audit accumulator.
%
% The helper is inert until CONFIGURE selects TIMING_STAGE or QUERY.  No
% value returned by this helper is consumed by the production estimator.

persistent state
if isempty(state)
    state = initial_state_local();
end
action = upper(char(string(action)));
switch action
    case 'RESET'
        state = initial_state_local();
    case 'CONFIGURE'
        state = configure_local(varargin{1});
    case 'MODE'
        varargout{1} = state.mode;
    case 'STAGE_ENABLED'
        varargout{1} = strcmp(state.mode, 'TIMING_STAGE');
    case 'QUERY_ENABLED'
        varargout{1} = strcmp(state.mode, 'QUERY');
    case 'STAGE_START'
        if strcmp(state.mode, 'TIMING_STAGE')
            varargout{1} = tic;
        else
            varargout{1} = [];
        end
    case 'STAGE_STOP'
        if strcmp(state.mode, 'TIMING_STAGE') && ~isempty(varargin{2})
            elapsed = toc(varargin{2});
            state = add_stage_time_local(state, varargin{1}, elapsed);
            if nargout > 0
                varargout{1} = elapsed;
            end
        elseif nargout > 0
            varargout{1} = NaN;
        end
    case 'GET_TIMING'
        varargout{1} = timing_output_local(state);
    case 'SET_QUERY_STAGE'
        previous = state.query_stage;
        state.query_stage = char(string(varargin{1}));
        varargout{1} = previous;
    case 'GET_QUERY_STAGE'
        varargout{1} = state.query_stage;
    case 'RECORD_QUERY'
        if strcmp(state.mode, 'QUERY')
            [state, detail] = record_query_local(state, varargin{1});
        else
            detail = struct();
        end
        if nargout > 0
            varargout{1} = detail;
        end
    case 'RECORD_AGGREGATE'
        if strcmp(state.mode, 'QUERY')
            state = record_aggregate_local(state, varargin{1}, varargin{2});
        end
    case 'BEGIN_CANDIDATE_GROUP'
        if strcmp(state.mode, 'QUERY')
            state = begin_candidate_group_local(state, varargin{1});
        end
    case 'END_CANDIDATE_GROUP'
        if strcmp(state.mode, 'QUERY')
            [state, comparison] = end_candidate_group_local( ...
                state, varargin{1});
        else
            comparison = struct();
        end
        if nargout > 0
            varargout{1} = comparison;
        end
    case 'RECORD_FIT_SNAPSHOT'
        if strcmp(state.mode, 'QUERY')
            state = record_fit_snapshot_local(state, varargin{1});
        end
    case 'RECORD_NESTED'
        if strcmp(state.mode, 'QUERY')
            state = record_nested_local(state, varargin{1});
        end
    case 'RECORD_FINAL_SELECTOR'
        if strcmp(state.mode, 'QUERY')
            state = record_final_selector_local(state, varargin{1});
        end
    case 'RECORD_INITIALIZATION_SNAPSHOT'
        if strcmp(state.mode, 'QUERY')
            state = record_initialization_snapshot_local( ...
                state, varargin{1});
        end
    case 'GET_QUERY'
        varargout{1} = query_output_local(state);
    otherwise
        error('stage8_k2_tcc_audit_state:Action', ...
            'Unsupported audit action: %s.', action);
end
end

function state = initial_state_local()
state = struct('mode', 'OFF', 'config', struct(), ...
    'query_stage', 'NOT_APPLICABLE', 'stage_times', struct(), ...
    'stage_call_counts', struct(), 'query_stages', struct(), ...
    'active_group', struct(), 'candidate_groups', struct([]), ...
    'fit_snapshots', struct([]), 'nested_records', struct([]), ...
    'selector_records', struct([]), ...
    'initialization_snapshots', struct([]), ...
    'truth_used_in_fit_flag', false, ...
    'cache_truth_used_flag', false, ...
    'placement_truth_used_flag', false);
end

function state = configure_local(config)
if ~(isstruct(config) && isscalar(config) && isfield(config, 'mode'))
    error('stage8_k2_tcc_audit_state:Config', ...
        'config must be a scalar struct with mode.');
end
mode = upper(char(string(config.mode)));
if ~ismember(mode, {'OFF','TIMING_STAGE','QUERY'})
    error('stage8_k2_tcc_audit_state:Mode', ...
        'mode must be OFF, TIMING_STAGE, or QUERY.');
end
state = initial_state_local();
state.mode = mode;
state.config = config;
if strcmp(mode, 'QUERY')
    required = {'dictionary','model','Zseq_white','trial_metadata'};
    if ~all(isfield(config, required))
        error('stage8_k2_tcc_audit_state:QueryConfig', ...
            'QUERY mode requires dictionary, model, Zseq_white, and metadata.');
    end
    if ~strcmp(config.dictionary.fixed_measurement_hash, ...
            config.model.fixed_measurement_hash)
        error('stage8_k2_tcc_audit_state:Identity', ...
            'The query dictionary and model identities differ.');
    end
end
end

function state = add_stage_time_local(state, stage_id, elapsed)
field = matlab.lang.makeValidName(upper(char(string(stage_id))));
if ~isfield(state.stage_times, field)
    state.stage_times.(field) = 0;
    state.stage_call_counts.(field) = 0;
end
state.stage_times.(field) = state.stage_times.(field) + double(elapsed);
state.stage_call_counts.(field) = state.stage_call_counts.(field) + 1;
end

function output = timing_output_local(state)
names = fieldnames(state.stage_times);
rows = repmat(struct('stage_id', "", 'inclusive_runtime_sec', 0, ...
    'call_count', 0), numel(names), 1);
for index = 1:numel(names)
    rows(index).stage_id = string(names{index});
    rows(index).inclusive_runtime_sec = state.stage_times.(names{index});
    rows(index).call_count = state.stage_call_counts.(names{index});
end
output = struct('mode', state.mode, 'stage_rows', rows, ...
    'truth_used_in_fit_flag', state.truth_used_in_fit_flag, ...
    'cache_truth_used_flag', state.cache_truth_used_flag, ...
    'placement_truth_used_flag', state.placement_truth_used_flag);
end

function [state, detail] = record_query_local(state, event)
event = normalize_event_local(event, state.query_stage);
[stage, field] = get_stage_local(state, event.stage_id);
K = size(event.angles_deg, 1);
stage.manifold_build_count = stage.manifold_build_count + 1;
stage.requested_column_count = stage.requested_column_count + K;
stage.dml_score_count = stage.dml_score_count + ...
    double(event.score_evaluated);
stage.derivatives_required_count = stage.derivatives_required_count + ...
    double(event.derivatives_required);
stage.single_count = stage.single_count + double(K == 1);
stage.pair_count = stage.pair_count + double(K == 2);

[shadow_G, lookup] = stage8_k2_tcc_registered_lookup( ...
    state.config.dictionary, event.angles_deg, state.config.model);
registered = lookup.cache_hit;
registered_columns = K - lookup.off_grid_count;
stage.registered_exact_column_count = ...
    stage.registered_exact_column_count + registered_columns;
stage.off_grid_column_count = stage.off_grid_column_count + ...
    lookup.off_grid_count;
for index = 1:numel(lookup.key_indices)
    if isfinite(lookup.key_indices(index))
        key_index = lookup.key_indices(index);
        stage.key_histogram(key_index) = stage.key_histogram(key_index) + 1;
    end
end
if K == 2
    stage.pair_exact_count = stage.pair_exact_count + double(registered);
    stage.pair_off_grid_count = stage.pair_off_grid_count + double(~registered);
    if registered && lookup.key_indices(1) == lookup.key_indices(2)
        stage.diagonal_pair_count = stage.diagonal_pair_count + 1;
    end
end

shadow_rank = NaN;
shadow_score = NaN;
G_rel_error = NaN;
if registered
    [shadow_rank, ~, ~] = stage8_k2_tcc_stable_matrix_rank( ...
        shadow_G, event.rank_multiplier);
    scale = max(norm(event.G, 'fro'), realmin);
    G_rel_error = norm(event.G - shadow_G, 'fro') / scale;
    stage.max_G_rel_error = max(stage.max_G_rel_error, G_rel_error);
    rank_mismatch = ~isequal(double(event.direct_rank), double(shadow_rank));
    stage.rank_mismatch_count = stage.rank_mismatch_count + ...
        double(rank_mismatch);
    if event.score_evaluated && shadow_rank == K
        shadow_score = beamspace_dml_score_svd( ...
            state.config.Zseq_white, shadow_G, struct( ...
            'requested_rank', K, 'rank_multiplier', event.rank_multiplier, ...
            'compute_projector_checks', false));
    elseif ~event.score_evaluated
        shadow_score = -Inf;
    end
else
    rank_mismatch = false;
end
key_mismatch = event.expect_registered && ~registered;
stage.key_mismatch_count = stage.key_mismatch_count + double(key_mismatch);
if strcmp(event.query_class, 'G_ONLY_ELIGIBLE')
    stage.g_only_eligible_build_count = stage.g_only_eligible_build_count + 1;
    if registered
        stage.registered_g_only_eligible_build_count = ...
            stage.registered_g_only_eligible_build_count + 1;
    end
end
state.query_stages.(field) = stage;

detail = struct('stage_id', event.stage_id, 'registered_exact', registered, ...
    'key_indices', lookup.key_indices, 'key_error_deg', ...
    lookup.key_error_deg, 'shadow_rank', shadow_rank, ...
    'shadow_score', shadow_score, 'G_rel_error', G_rel_error, ...
    'key_mismatch', key_mismatch, 'rank_mismatch', rank_mismatch);
if ~isempty(fieldnames(state.active_group)) && event.candidate_group_flag
    item = struct('candidate_index', event.candidate_index, ...
        'angles_deg', event.angles_deg, 'direct_score', event.direct_score, ...
        'direct_rank', event.direct_rank, 'shadow_score', shadow_score, ...
        'shadow_rank', shadow_rank, 'registered_exact', registered, ...
        'key_indices', lookup.key_indices);
    if isempty(state.active_group.candidates)
        state.active_group.candidates = item;
    else
        state.active_group.candidates(end + 1, 1) = item;
    end
end
end

function event = normalize_event_local(event, current_stage)
required = {'angles_deg','G','direct_rank','direct_score', ...
    'score_evaluated'};
if ~(isstruct(event) && isscalar(event) && all(isfield(event, required)))
    error('stage8_k2_tcc_audit_state:QueryEvent', ...
        'A query event is incomplete.');
end
defaults = struct('stage_id', current_stage, 'derivatives_required', false, ...
    'query_class', 'G_ONLY_ELIGIBLE', 'expect_registered', false, ...
    'candidate_group_flag', false, 'candidate_index', 0, ...
    'rank_multiplier', 1);
names = fieldnames(defaults);
for index = 1:numel(names)
    if ~isfield(event, names{index})
        event.(names{index}) = defaults.(names{index});
    end
end
event.stage_id = char(string(event.stage_id));
event.query_class = char(string(event.query_class));
end

function state = record_aggregate_local(state, stage_id, metrics)
[stage, field] = get_stage_local(state, stage_id);
numeric_fields = {'manifold_build_count','requested_column_count', ...
    'dml_score_count','derivatives_required_count','single_count', ...
    'pair_count','registered_exact_column_count','off_grid_column_count', ...
    'diagonal_pair_count','pair_exact_count','pair_off_grid_count', ...
    'g_only_eligible_build_count','registered_g_only_eligible_build_count'};
for index = 1:numel(numeric_fields)
    name = numeric_fields{index};
    if isfield(metrics, name)
        stage.(name) = stage.(name) + double(metrics.(name));
    end
end
if isfield(metrics, 'key_histogram') && ...
        numel(metrics.key_histogram) == numel(stage.key_histogram)
    stage.key_histogram = stage.key_histogram + ...
        reshape(double(metrics.key_histogram), 1, []);
end
state.query_stages.(field) = stage;
end

function state = begin_candidate_group_local(state, info)
if ~isempty(fieldnames(state.active_group))
    error('stage8_k2_tcc_audit_state:CandidateGroup', ...
        'Candidate groups may not be nested.');
end
required = {'stage_id','baseline_angles_deg','baseline_score', ...
    'baseline_rank','axis_value_count'};
if ~all(isfield(info, required))
    error('stage8_k2_tcc_audit_state:CandidateGroupInfo', ...
        'Candidate group information is incomplete.');
end
[baseline_score, baseline_rank, registered] = shadow_score_local( ...
    state, info.baseline_angles_deg, 1);
state.active_group = struct('stage_id', char(string(info.stage_id)), ...
    'baseline_angles_deg', info.baseline_angles_deg, ...
    'baseline_score', double(info.baseline_score), ...
    'baseline_rank', double(info.baseline_rank), ...
    'shadow_baseline_score', baseline_score, ...
    'shadow_baseline_rank', baseline_rank, ...
    'baseline_registered', registered, ...
    'axis_value_count', double(info.axis_value_count), ...
    'target_index', double(info.target_index), ...
    'dimension_index', double(info.dimension_index), ...
    'candidates', struct([]));
end

function [state, comparison] = end_candidate_group_local(state, production)
if isempty(fieldnames(state.active_group))
    error('stage8_k2_tcc_audit_state:CandidateGroup', ...
        'No candidate group is active.');
end
group = state.active_group;
items = group.candidates;
n = numel(items);
direct_score = [group.baseline_score; reshape([items.direct_score], [], 1)];
shadow_score = [group.shadow_baseline_score; ...
    reshape([items.shadow_score], [], 1)];
direct_rank = [group.baseline_rank; reshape([items.direct_rank], [], 1)];
shadow_rank = [group.shadow_baseline_rank; ...
    reshape([items.shadow_rank], [], 1)];
K = size(group.baseline_angles_deg, 1);
[direct_best, direct_tie] = select_group_local(direct_score, direct_rank, K);
[shadow_best, shadow_tie] = select_group_local(shadow_score, shadow_rank, K);
direct_candidate_index = direct_best - 1;
shadow_candidate_index = shadow_best - 1;
if isempty(direct_candidate_index), direct_candidate_index = 0; end
if isempty(shadow_candidate_index), shadow_candidate_index = 0; end
provided_best = double(production.best_candidate_index);
best_mismatch = shadow_candidate_index ~= provided_best;
direct_replay_mismatch = direct_candidate_index ~= provided_best;
tie_mismatch = ~isequal(direct_tie, shadow_tie);
candidate_indices = reshape([items.candidate_index], [], 1);
order_mismatch = n ~= group.axis_value_count || ...
    ~isequal(candidate_indices, (1:n).');
shadow_angles = group.baseline_angles_deg;
if shadow_candidate_index > 0
    shadow_angles = items(shadow_candidate_index).angles_deg;
end
shadow_accepted = shadow_candidate_index > 0;
accepted_mismatch = logical(production.accepted_update) ~= shadow_accepted;
trajectory_mismatch = ~isequal(shadow_angles, production.angles_after) || ...
    best_mismatch || accepted_mismatch || direct_replay_mismatch;

[stage, field] = get_stage_local(state, group.stage_id);
stage.candidate_order_mismatch_count = ...
    stage.candidate_order_mismatch_count + double(order_mismatch);
stage.tie_mismatch_count = stage.tie_mismatch_count + double(tie_mismatch);
stage.best_index_mismatch_count = stage.best_index_mismatch_count + ...
    double(best_mismatch || direct_replay_mismatch);
stage.accepted_update_mismatch_count = ...
    stage.accepted_update_mismatch_count + double(accepted_mismatch);
stage.trajectory_mismatch_count = stage.trajectory_mismatch_count + ...
    double(trajectory_mismatch);
state.query_stages.(field) = stage;
comparison = struct('stage_id', string(group.stage_id), ...
    'candidate_count', n, 'direct_best_candidate_index', ...
    direct_candidate_index, 'production_best_candidate_index', ...
    provided_best, 'shadow_best_candidate_index', shadow_candidate_index, ...
    'direct_tie_set', direct_tie, 'shadow_tie_set', shadow_tie, ...
    'candidate_order_mismatch', order_mismatch, ...
    'tie_mismatch', tie_mismatch, 'best_index_mismatch', best_mismatch, ...
    'accepted_update_mismatch', accepted_mismatch, ...
    'trajectory_mismatch', trajectory_mismatch, ...
    'target_index', group.target_index, ...
    'dimension_index', group.dimension_index);
if isempty(state.candidate_groups)
    state.candidate_groups = comparison;
else
    state.candidate_groups(end + 1, 1) = comparison;
end
state.active_group = struct();
end

function [best, tie] = select_group_local(score, ranks, K)
eligible = isfinite(score) & ranks == K;
if ~any(eligible)
    best = 1;
    tie = zeros(0, 1);
    return;
end
maximum = max(score(eligible));
tie = find(eligible & score == maximum) - 1;
best = find(eligible & score == maximum, 1, 'first');
end

function state = record_fit_snapshot_local(state, event)
required = {'role','fit','init_context','model','full_data'};
if ~all(isfield(event, required))
    error('stage8_k2_tcc_audit_state:FitSnapshot', ...
        'Fit snapshot event is incomplete.');
end
fit = event.fit;
selected_shadow = '';
selected_start_mismatch = false;
if ~isempty(fit.all_start_results)
    results = fit.all_start_results;
    shadow_loglik = -Inf(numel(results), 1);
    for index = 1:numel(results)
        if ~logical(results(index).valid_for_selection_flag)
            continue;
        end
        [G, lookup] = stage8_k2_tcc_registered_lookup( ...
            state.config.dictionary, results(index).angles_hat_deg, ...
            event.model);
        if ~lookup.cache_hit
            continue;
        end
        K = size(results(index).angles_hat_deg, 1);
        [rank_now, ~, ~] = stage8_k2_tcc_stable_matrix_rank(G, 1);
        if rank_now ~= K
            continue;
        end
        [~, ~, ~, shadow_loglik(index), effective_rank] = ...
            concentrated_dml_rss(event.full_data.Zseq_white, G, struct( ...
            'requested_rank', K, 'rank_multiplier', 1, ...
            'compute_projector_checks', false));
        if effective_rank ~= K
            shadow_loglik(index) = -Inf;
        end
    end
    eligible = find(isfinite(shadow_loglik));
    if ~isempty(eligible)
        [~, relative] = max(shadow_loglik(eligible));
        selected_shadow = char(string( ...
            results(eligible(relative)).initialization_id));
    end
    selected_start_mismatch = ~strcmp(selected_shadow, ...
        char(string(fit.initialization_id)));
end
role = char(string(event.role));
[stage, field] = get_stage_local(state, role);
stage.selected_start_mismatch_count = ...
    stage.selected_start_mismatch_count + double(selected_start_mismatch);
state.query_stages.(field) = stage;
snapshot = compact_fit_snapshot_local(event, selected_shadow, ...
    selected_start_mismatch);
if isempty(state.fit_snapshots)
    state.fit_snapshots = snapshot;
else
    state.fit_snapshots(end + 1, 1) = snapshot;
end
end

function snapshot = compact_fit_snapshot_local(event, selected_shadow, mismatch)
fit = event.fit;
factory_hash = '';
if isfield(event.init_context, 'factory_invocation_hash')
    factory_hash = char(string(event.init_context.factory_invocation_hash));
end
snapshot = struct('role', string(event.role), 'K', double(fit.K), ...
    'angles_deg', fit.angles_hat_deg, 'G', fit.G_hat, ...
    'rss', double(fit.rss), 'sigma2', double(fit.sigma2_hat), ...
    'loglik', double(fit.loglik_concentrated), ...
    'rank', double(fit.effective_rank), ...
    'selected_start', string(fit.initialization_id), ...
    'shadow_selected_start', string(selected_shadow), ...
    'selected_start_mismatch', logical(mismatch), ...
    'fixed_measurement_hash', string(fit.fixed_measurement_hash), ...
    'local_domain_hash', string(fit.local_domain_hash), ...
    'observation_hash', string(fit.observation_hash), ...
    'initialization_identity', string(factory_hash));
end

function state = record_nested_local(state, event)
required = {'stage_id','candidates','distance','direct_anchor_index', ...
    'k1_angle','fit1','data','model','direct_initial_rss', ...
    'direct_nested_pass','rss_tolerance','direct_first_column_error'};
if ~all(isfield(event, required))
    error('stage8_k2_tcc_audit_state:Nested', ...
        'Nested replay event is incomplete.');
end
count = size(event.candidates, 1);
shadow_full_rank = false(count, 1);
for index = 1:count
    angles = [event.k1_angle;event.candidates(index, :)];
    [G, lookup] = stage8_k2_tcc_registered_lookup( ...
        state.config.dictionary, angles, event.model);
    if lookup.cache_hit
        shadow_full_rank(index) = ...
            stage8_k2_tcc_stable_matrix_rank(G, 1) == 2;
    end
end
eligible = shadow_full_rank & isfinite(event.distance);
shadow_anchor = 0;
if any(eligible)
    maximum = max(event.distance(eligible));
    tolerance = 64 * eps(max(1, abs(maximum)));
    shadow_anchor = find(eligible & ...
        event.distance >= maximum - tolerance, 1, 'first');
end
anchor_match = shadow_anchor == event.direct_anchor_index;
shadow_initial_rss = Inf;
shadow_first_column_error = Inf;
shadow_pass = false;
if shadow_anchor > 0
    angles = [event.k1_angle;event.candidates(shadow_anchor, :)];
    G = stage8_k2_tcc_registered_lookup( ...
        state.config.dictionary, angles, event.model);
    [~, shadow_initial_rss, score_debug] = beamspace_dml_score_svd( ...
        event.data.Zseq_white, G, struct('requested_rank', 2, ...
        'rank_multiplier', 1, 'compute_projector_checks', false));
    shadow_first_column_error = norm(G(:, 1) - event.fit1.G_hat(:, 1)) / ...
        max(norm(event.fit1.G_hat(:, 1)), realmin);
    shadow_pass = shadow_initial_rss <= event.fit1.rss + ...
        event.rss_tolerance && shadow_first_column_error <= ...
        64 * eps(max(size(G))) && ~score_debug.is_rank_deficient;
end
nested_mismatch = ~anchor_match || ...
    shadow_pass ~= logical(event.direct_nested_pass);
[stage, field] = get_stage_local(state, event.stage_id);
stage.nested_pass_mismatch_count = stage.nested_pass_mismatch_count + ...
    double(nested_mismatch);
state.query_stages.(field) = stage;
record = struct('stage_id', string(event.stage_id), ...
    'helper_k1_angle', event.k1_angle, ...
    'direct_anchor_index', double(event.direct_anchor_index), ...
    'shadow_anchor_index', double(shadow_anchor), ...
    'selected_anchor_match', logical(anchor_match), ...
    'direct_initial_rss', double(event.direct_initial_rss), ...
    'shadow_initial_rss', double(shadow_initial_rss), ...
    'K1_rss', double(event.fit1.rss), ...
    'nested_rss_tolerance', double(event.rss_tolerance), ...
    'direct_nested_pass', logical(event.direct_nested_pass), ...
    'shadow_nested_pass', logical(shadow_pass), ...
    'direct_first_column_error', ...
    double(event.direct_first_column_error), ...
    'shadow_first_column_error', double(shadow_first_column_error), ...
    'anchor_metric_distance', ...
    double(event.distance(event.direct_anchor_index)), ...
    'nested_mismatch', logical(nested_mismatch));
if isempty(state.nested_records)
    state.nested_records = record;
else
    state.nested_records(end + 1, 1) = record;
end
end

function state = record_final_selector_local(state, event)
required = {'fixed','profile','result','model'};
if ~all(isfield(event, required))
    error('stage8_k2_tcc_audit_state:Selector', ...
        'Final selector event is incomplete.');
end
shadow_source = 'FIXED_GRID_FALLBACK';
shadow_fixed_loglik = NaN;
if event.fixed.fit_valid
    [G, lookup] = stage8_k2_tcc_registered_lookup( ...
        state.config.dictionary, event.fixed.angles_hat_deg, event.model);
    if lookup.cache_hit
        [~, ~, ~, shadow_fixed_loglik, rank_now] = ...
            concentrated_dml_rss(state.config.Zseq_white, G, struct( ...
            'requested_rank', 2, 'rank_multiplier', 1, ...
            'compute_projector_checks', false));
        if event.profile.valid && rank_now == 2 && ...
                event.profile.loglik_concentrated >= shadow_fixed_loglik
            shadow_source = 'TANGENT_PROFILE_UPGRADE';
        end
    end
end
mismatch = ~strcmp(shadow_source, char(string(event.result.selected_source)));
[stage, field] = get_stage_local(state, 'FINAL_SAFE_SELECTOR');
stage.final_selector_mismatch_count = ...
    stage.final_selector_mismatch_count + double(mismatch);
state.query_stages.(field) = stage;
record = struct('direct_source', string(event.result.selected_source), ...
    'shadow_source', string(shadow_source), ...
    'direct_fixed_loglik', double(event.fixed.loglik_concentrated), ...
    'shadow_fixed_loglik', double(shadow_fixed_loglik), ...
    'profile_loglik', double(event.profile.loglik_concentrated), ...
    'final_selector_mismatch', logical(mismatch));
if isempty(state.selector_records)
    state.selector_records = record;
else
    state.selector_records(end + 1, 1) = record;
end
end

function state = record_initialization_snapshot_local(state, event)
required = {'role','full_data','initialization'};
if ~all(isfield(event, required))
    error('stage8_k2_tcc_audit_state:InitializationSnapshot', ...
        'Initialization snapshot event is incomplete.');
end
initialization = event.initialization;
names = {'grouped_q1_kq1_angles_deg', ...
    'conventional_singleton_peak_deg','grouped_q1_kq2_angles_deg', ...
    'grouped_q2_kq1_plus_kq1_angles_deg', ...
    'grouped_q1_kq1_status','conventional_singleton_status', ...
    'grouped_q1_kq2_status','grouped_q2_kq1_plus_kq1_status', ...
    'fixed_measurement_hash','local_domain_hash','observation_hash', ...
    'factory_invocation_hash','phase_factor'};
signature = struct();
for index = 1:numel(names)
    if isfield(initialization, names{index})
        signature.(names{index}) = initialization.(names{index});
    end
end
snapshot = struct('role', string(event.role), ...
    'fixed_measurement_hash', ...
    string(event.full_data.fixed_measurement_hash), ...
    'observation_hash', string(initialization.observation_hash), ...
    'factory_invocation_hash', ...
    string(initialization.factory_invocation_hash), ...
    'full_data_hash', string(stage8_k2_tcc_stable_hash( ...
    event.full_data.Zseq_white)), ...
    'initialization_output_hash', ...
    string(stage8_k2_tcc_stable_hash(signature)), ...
    'signature', signature);
if isempty(state.initialization_snapshots)
    state.initialization_snapshots = snapshot;
else
    state.initialization_snapshots(end + 1, 1) = snapshot;
end
end

function [score, rank_now, registered] = shadow_score_local(state, angles, multiplier)
[G, lookup] = stage8_k2_tcc_registered_lookup( ...
    state.config.dictionary, angles, state.config.model);
registered = lookup.cache_hit;
score = -Inf;
rank_now = 0;
if ~registered
    return;
end
[rank_now, ~, ~] = stage8_k2_tcc_stable_matrix_rank(G, multiplier);
K = size(angles, 1);
if rank_now == K
    score = beamspace_dml_score_svd(state.config.Zseq_white, G, struct( ...
        'requested_rank', K, 'rank_multiplier', multiplier, ...
        'compute_projector_checks', false));
end
end

function [stage, field] = get_stage_local(state, stage_id)
stage_id = upper(char(string(stage_id)));
field = matlab.lang.makeValidName(stage_id);
if isfield(state.query_stages, field)
    stage = state.query_stages.(field);
    return;
end
stage = query_stage_template_local(stage_id);
end

function stage = query_stage_template_local(stage_id)
stage = struct('stage_id', string(stage_id), ...
    'manifold_build_count', 0, 'requested_column_count', 0, ...
    'dml_score_count', 0, 'derivatives_required_count', 0, ...
    'single_count', 0, 'pair_count', 0, ...
    'registered_exact_column_count', 0, 'off_grid_column_count', 0, ...
    'diagonal_pair_count', 0, 'pair_exact_count', 0, ...
    'pair_off_grid_count', 0, 'key_histogram', zeros(1, 21), ...
    'key_mismatch_count', 0, 'rank_mismatch_count', 0, ...
    'candidate_order_mismatch_count', 0, 'tie_mismatch_count', 0, ...
    'best_index_mismatch_count', 0, ...
    'accepted_update_mismatch_count', 0, ...
    'trajectory_mismatch_count', 0, ...
    'selected_start_mismatch_count', 0, ...
    'nested_pass_mismatch_count', 0, ...
    'final_selector_mismatch_count', 0, ...
    'g_only_eligible_build_count', 0, ...
    'registered_g_only_eligible_build_count', 0, ...
    'max_G_rel_error', 0);
end

function output = query_output_local(state)
names = fieldnames(state.query_stages);
rows = repmat(query_stage_template_local(''), numel(names), 1);
for index = 1:numel(names)
    rows(index) = state.query_stages.(names{index});
end
for index = 1:numel(names)
    unique_count = nnz(rows(index).key_histogram > 0);
    rows(index).unique_registered_key_count = unique_count;
    if unique_count > 0
        rows(index).reuse_multiplicity = ...
            rows(index).registered_exact_column_count / unique_count;
    else
        rows(index).reuse_multiplicity = NaN;
    end
    rows(index).key_histogram_json = string(jsonencode( ...
        rows(index).key_histogram));
end
output = struct('mode', state.mode, 'stage_rows', rows, ...
    'candidate_groups', state.candidate_groups, ...
    'fit_snapshots', state.fit_snapshots, ...
    'nested_records', state.nested_records, ...
    'selector_records', state.selector_records, ...
    'initialization_snapshots', state.initialization_snapshots, ...
    'trial_metadata', state.config.trial_metadata, ...
    'truth_used_in_fit_flag', state.truth_used_in_fit_flag, ...
    'cache_truth_used_flag', state.cache_truth_used_flag, ...
    'placement_truth_used_flag', state.placement_truth_used_flag);
end
