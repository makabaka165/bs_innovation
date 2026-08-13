function result = stage8_core_v2_worker(repo_dir, runtime_root, worker_id)
%STAGE8_CORE_V2_WORKER Run one deterministic checkpoint shard.

repo_dir = char(string(repo_dir));
runtime_root = char(string(runtime_root));
worker_id = double(worker_id);
tool_dir = fileparts(mfilename('fullpath'));
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(tool_dir); addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
protocol_path = fullfile(runtime_root, 'protocol.json');
if ~isfile(protocol_path)
    error('stage8_core_v2_worker:Protocol', 'protocol.json is missing.');
end
protocol = jsondecode(fileread(protocol_path));
worker_count = double(protocol.selected_worker_count);
if worker_id < 1 || worker_id > worker_count || worker_id ~= fix(worker_id)
    error('stage8_core_v2_worker:WorkerId', ...
        'worker_id is outside the selected execution mode.');
end
context = stage8_core_v2_context(repo_dir, true);
if ~strcmp(string(stage8_core_v2_source_hash(repo_dir)), ...
        string(protocol.protocol_source_tree_hash)) || ...
        ~strcmp(string(context.k1_solver_contract_hash), ...
        string(protocol.k1_solver_contract_hash)) || ...
        ~strcmp(string(context.k2_solver_contract_hash), ...
        string(protocol.k2_solver_contract_hash))
    error('stage8_core_v2_worker:ProtocolIdentity', ...
        'Committed source or solver identity differs from protocol.');
end
registry = stage8_core_v2_registry(context, protocol.registry_kind);
selected = registry(ismember(registry.global_trial_index, ...
    double(protocol.trial_indices(:))), :);
assigned = mod(selected.global_trial_index - 1, worker_count) == worker_id - 1;
shard = selected(assigned, :);

status_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d_status.json', worker_id));
lock_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d.current.lock', worker_id));
state = struct('worker_id', worker_id, 'pid', feature('getpid'), ...
    'worker_state', 'STARTING', 'current_trial_id', '', ...
    'assigned_element_trial_count', height(shard), ...
    'completed_element_trial_count', 0, ...
    'remaining_element_trial_count', height(shard), ...
    'last_error', '', 'heartbeat_utc', utc_now_local());
stage8_core_v2_write_json_atomic(status_path, state);
current_tmp = '';
try
    existing = false(height(shard), 1);
    for index = 1:height(shard)
        checkpoint_path = checkpoint_path_local(runtime_root, ...
            shard.trial_id(index));
        if isfile(checkpoint_path)
            stage8_core_v2_validate_checkpoint(checkpoint_path, ...
                protocol, shard(index, :));
            existing(index) = true;
        end
    end
    state.completed_element_trial_count = nnz(existing);
    state.remaining_element_trial_count = height(shard) - nnz(existing);
    state.worker_state = 'RUNNING';
    state.heartbeat_utc = utc_now_local();
    stage8_core_v2_write_json_atomic(status_path, state);
    for index = 1:height(shard)
        if existing(index), continue; end
        if isfile(fullfile(runtime_root, 'control', 'pause.request'))
            state.worker_state = 'PAUSED_SAFE';
            break;
        end
        spec = shard(index, :);
        checkpoint_path = checkpoint_path_local(runtime_root, spec.trial_id);
        state.current_trial_id = char(spec.trial_id);
        state.heartbeat_utc = utc_now_local();
        write_text_local(lock_path, sprintf('trial_id=%s\n', ...
            state.current_trial_id));
        stage8_core_v2_write_json_atomic(status_path, state);
        [rows, diagnostics] = stage8_core_v2_evaluate_trial(spec, context);
        checkpoint = checkpoint_local(protocol, spec, rows, diagnostics);
        current_tmp = fullfile(runtime_root, 'tmp', ...
            [char(spec.trial_id), '.mat.tmp']);
        if isfile(checkpoint_path)
            error('stage8_core_v2_worker:Collision', ...
                'Assigned checkpoint was created by another writer.');
        end
        save(current_tmp, 'checkpoint', '-mat');
        stage8_core_v2_validate_checkpoint(current_tmp, protocol, spec);
        [moved, message] = movefile(current_tmp, checkpoint_path);
        if ~moved, error('stage8_core_v2_worker:AtomicMove', '%s', message); end
        current_tmp = '';
        stage8_core_v2_validate_checkpoint(checkpoint_path, protocol, spec);
        if isfile(lock_path), delete(lock_path); end
        existing(index) = true;
        state.completed_element_trial_count = nnz(existing);
        state.remaining_element_trial_count = height(shard) - nnz(existing);
        state.current_trial_id = '';
        state.heartbeat_utc = utc_now_local();
        stage8_core_v2_write_json_atomic(status_path, state);
    end
    state.current_trial_id = '';
    if state.remaining_element_trial_count == 0
        state.worker_state = 'COMPLETE';
    elseif isfile(fullfile(runtime_root, 'control', 'pause.request'))
        state.worker_state = 'PAUSED_SAFE';
    else
        error('stage8_core_v2_worker:IncompleteExit', ...
            'Worker exited before its shard was complete.');
    end
    state.heartbeat_utc = utc_now_local();
    stage8_core_v2_write_json_atomic(status_path, state);
    result = state;
catch exception
    if isfile(lock_path), delete(lock_path); end
    if ~isempty(current_tmp) && isfile(current_tmp), delete(current_tmp); end
    state.current_trial_id = '';
    state.worker_state = 'ERROR_STOPPED';
    state.heartbeat_utc = utc_now_local();
    state.last_error = getReport(exception, 'extended', 'hyperlinks', 'off');
    stage8_core_v2_write_json_atomic(status_path, state);
    rethrow(exception);
end
clear path_cleanup
end

function checkpoint = checkpoint_local(protocol, spec, rows, diagnostics)
identity = struct('protocol_version', protocol.protocol_version, ...
    'checkpoint_contract_version', protocol.checkpoint_contract_version, ...
    'trial_id', char(spec.trial_id), ...
    'global_trial_index', double(spec.global_trial_index), ...
    'truth_K', double(spec.truth_K), ...
    'element_trial_hash', char(string(diagnostics.element_trial_hash)), ...
    'k1_solver_contract_hash', protocol.k1_solver_contract_hash, ...
    'k2_solver_contract_hash', protocol.k2_solver_contract_hash, ...
    'protocol_source_tree_hash', protocol.protocol_source_tree_hash);
checkpoint = struct('identity', identity, 'rows', rows, ...
    'scientific_content_hash', '', 'completion_status', 'COMPLETE_PASS');
checkpoint.scientific_content_hash = ...
    stage8_core_v2_checkpoint_hash(checkpoint);
end

function path_now = checkpoint_path_local(root, trial_id)
path_now = fullfile(root, 'checkpoints', [char(string(trial_id)), '.mat']);
end

function write_text_local(path_now, value)
fid = fopen(path_now, 'w', 'n', 'UTF-8');
if fid < 0, error('stage8_core_v2_worker:Lock', 'Cannot write lock.'); end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, value, 'char');
clear cleanup
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
