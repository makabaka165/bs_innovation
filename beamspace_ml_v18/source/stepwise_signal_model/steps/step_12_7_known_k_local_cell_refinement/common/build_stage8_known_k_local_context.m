function context = build_stage8_known_k_local_context( ...
    Y_element, model, local_domain, stage5_locked, noise_model, opts)
%BUILD_STAGE8_KNOWN_K_LOCAL_CONTEXT Build only data-driven fixed context.

expected_stage5 = build_stage8_stage5_locked_config();
if ~strcmp(char(string(stage5_locked.configuration_hash)), ...
        char(string(expected_stage5.configuration_hash)))
    error('build_stage8_known_k_local_context:Stage5Identity', ...
        'stage5_locked differs from the frozen Stage5 configuration.');
end
audit_available = exist('stage8_k2_tcc_audit_state', 'file') == 2;
prefix = audit_public_prefix_local(audit_available);
full_clock = audit_stage_start_local(audit_available, ...
    [prefix, '_FULL_DATA']);
full_data = build_stage8_full_data_from_element(Y_element, model, ...
    struct('data_role', 'SINGLE_CPI_SINGLE_RANGE_DOPPLER_CELL'));
audit_stage_stop_local(audit_available, [prefix, '_FULL_DATA'], full_clock);
init_clock = audit_stage_start_local(audit_available, ...
    [prefix, '_INITIALIZATION_TOTAL']);
[initialization, initialization_debug] = ...
    build_stage8_initialization_context_from_data(full_data, model, ...
    local_domain, stage5_locked, noise_model, ...
    struct('rank_multiplier', opts.rank_multiplier));
audit_stage_stop_local(audit_available, [prefix, '_INITIALIZATION_TOTAL'], ...
    init_clock);
context = struct('full_data', full_data, 'model', model, ...
    'local_domain', local_domain, 'stage5_locked', stage5_locked, ...
    'noise_model', noise_model, 'initialization', initialization, ...
    'initialization_debug', initialization_debug, ...
    'truth_used_in_initialization_flag', false, ...
    'tracking_input_used_flag', false, ...
    'cross_cpi_data_used_flag', false);
audit_record_initialization_local(audit_available, prefix, full_data, ...
    initialization);
end

function prefix = audit_public_prefix_local(available)
prefix = 'K1';
if ~available
    return;
end
stage = upper(char(string(stage8_k2_tcc_audit_state( ...
    'GET_QUERY_STAGE'))));
if startsWith(stage, 'K2')
    prefix = 'K2';
end
end

function token = audit_stage_start_local(available, stage_id)
token = [];
if available && stage8_k2_tcc_audit_state('STAGE_ENABLED')
    token = stage8_k2_tcc_audit_state('STAGE_START', stage_id);
end
end

function audit_stage_stop_local(available, stage_id, token)
if available && ~isempty(token)
    stage8_k2_tcc_audit_state('STAGE_STOP', stage_id, token);
end
end

function audit_record_initialization_local(available, prefix, full_data, init)
if ~(available && stage8_k2_tcc_audit_state('QUERY_ENABLED'))
    return;
end
event = struct('role', [prefix, '_CONTEXT'], ...
    'full_data', full_data, 'initialization', init);
stage8_k2_tcc_audit_state('RECORD_INITIALIZATION_SNAPSHOT', event);
end
