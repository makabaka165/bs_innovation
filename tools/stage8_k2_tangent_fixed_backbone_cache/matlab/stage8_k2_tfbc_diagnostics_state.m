function output = stage8_k2_tfbc_diagnostics_state(action, varargin)
%STAGE8_K2_TFBC_DIAGNOSTICS_STATE Non-timed aggregate exposure counters.

persistent state
if isempty(state), state = empty_state_local(); end
action = upper(char(string(action)));
switch action
    case 'RESET'
        state = empty_state_local();
        output = state;
    case 'SNAPSHOT'
        output = state;
    case 'RECORD_HIT'
        K = double(varargin{1});
        state.eligible_registered_call_count = ...
            state.eligible_registered_call_count + 1;
        state.eligible_registered_column_count = ...
            state.eligible_registered_column_count + K;
        state.cache_hit_count = state.cache_hit_count + K;
        state = record_stage_local(state, K);
        output = [];
    case 'RECORD_MISS'
        K = double(varargin{1});
        off_grid = logical(varargin{2});
        state.cache_miss_count = state.cache_miss_count + K;
        state.identity_rejection_count = ...
            state.identity_rejection_count + double(~off_grid);
        state.off_grid_rejection_count = ...
            state.off_grid_rejection_count + double(off_grid);
        output = [];
    otherwise
        error('stage8_k2_tfbc_diagnostics_state:Action', ...
            'Unsupported diagnostics action: %s.', action);
end
end

function state = empty_state_local()
stage_ids = ["K1_INIT_CONVENTIONAL"; ...
    "K1_FIXED_REGISTERED_REFINEMENT"; ...
    "K1_FIXED_FINAL_CERTIFICATION"; ...
    "K2_INIT_CONVENTIONAL";"K2_HELPER_K1"; ...
    "K2_NESTED_ANCHOR";"K2_REGISTERED_REFINEMENT"; ...
    "K2_FINAL_CERTIFICATION";"UNCLASSIFIED"];
state = struct('eligible_registered_call_count',0, ...
    'eligible_registered_column_count',0, 'cache_hit_count',0, ...
    'cache_miss_count',0, 'fallback_count',0, ...
    'identity_rejection_count',0, 'off_grid_rejection_count',0, ...
    't4_cache_query_count',0, 'stage_ids',stage_ids, ...
    'stage_call_count',zeros(numel(stage_ids), 1), ...
    'stage_column_count',zeros(numel(stage_ids), 1));
end

function state = record_stage_local(state, K)
stage = "UNCLASSIFIED";
if exist('stage8_k2_tcc_audit_state', 'file') == 2
    candidate = string(stage8_k2_tcc_audit_state('GET_QUERY_STAGE'));
    if strlength(candidate) > 0, stage = candidate; end
end
if stage == "K1_PUBLIC"
    stage = "K1_INIT_CONVENTIONAL";
elseif stage == "K2_PUBLIC"
    stage = "K2_INIT_CONVENTIONAL";
end
index = find(state.stage_ids == stage, 1);
if isempty(index), index = numel(state.stage_ids); end
state.stage_call_count(index) = state.stage_call_count(index) + 1;
state.stage_column_count(index) = state.stage_column_count(index) + K;
if stage == "T4_PROFILE"
    state.t4_cache_query_count = state.t4_cache_query_count + 1;
end
end
