function result = stage8_r1_worker(repo_dir, runtime_root, worker_id)
%STAGE8_R1_WORKER Run one deterministic modulo shard.

repo_dir = char(string(repo_dir));
runtime_root = char(string(runtime_root));
worker_id = double(worker_id);
tool_dir = fileparts(mfilename('fullpath'));
addpath(tool_dir);
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
protocol_path = fullfile(runtime_root, 'protocol.json');
if ~isfile(protocol_path)
    error('stage8_r1_worker:Protocol', 'protocol.json is missing.');
end
protocol = jsondecode(fileread(protocol_path));
worker_count = double(protocol.selected_worker_count);
if worker_id < 1 || worker_id > worker_count || worker_id ~= fix(worker_id)
    error('stage8_r1_worker:WorkerId', ...
        'worker_id is outside the selected execution mode.');
end
context = stage8_r1_context(repo_dir, true);
if ~strcmp(string(stage8_r1_source_hash(repo_dir)), ...
        string(protocol.protocol_source_tree_hash)) || ...
        ~strcmp(string(context.solver_contract_hash), ...
        string(protocol.solver_contract_hash))
    error('stage8_r1_worker:ProtocolIdentity', ...
        'Committed source or solver identity differs from protocol.');
end
registry = stage8_r1_build_registry(context, protocol.registry_kind);
selected = registry(ismember(registry.global_trial_index, ...
    double(protocol.trial_indices(:))), :);
assigned = mod(selected.global_trial_index - 1, worker_count) == worker_id - 1;
shard = selected(assigned, :);

attempt_id = char(java.util.UUID.randomUUID());
pid = feature('getpid');
started = utc_now_local();
status_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d_status.json', worker_id));
pid_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d.pid', worker_id));
lock_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d.current.lock', worker_id));
write_text_atomic_local(pid_path, sprintf('%d\n', pid));
state = struct('protocol_version', protocol.protocol_version, ...
    'worker_id', worker_id, 'pid', pid, 'attempt_id', attempt_id, ...
    'worker_state', 'STARTING', 'started_utc', started, ...
    'heartbeat_utc', started, 'current_trial_id', '', ...
    'current_trial_started_utc', '', ...
    'assigned_element_trial_count', height(shard), ...
    'completed_element_trial_count', 0, ...
    'remaining_element_trial_count', height(shard), ...
    'last_trial_runtime_sec', 0, 'last_checkpoint_utc', '', ...
    'last_error', '');
stage8_r1_write_json_atomic(status_path, state);
current_tmp = '';
try
    validate_existing_set_local(runtime_root, protocol, selected);
    existing = false(height(shard), 1);
    for index = 1:height(shard)
        checkpoint_path = checkpoint_path_local(runtime_root, shard.trial_id(index));
        if isfile(checkpoint_path)
            stage8_r1_validate_checkpoint(checkpoint_path, protocol, ...
                shard(index, :));
            existing(index) = true;
        end
    end
    state.completed_element_trial_count = nnz(existing);
    state.remaining_element_trial_count = height(shard) - nnz(existing);
    state.worker_state = 'RUNNING';
    state.heartbeat_utc = utc_now_local();
    stage8_r1_write_json_atomic(status_path, state);

    for index = 1:height(shard)
        spec = shard(index, :);
        checkpoint_path = checkpoint_path_local(runtime_root, spec.trial_id);
        if isfile(checkpoint_path), continue; end
        if isfile(fullfile(runtime_root, 'control', 'pause.request'))
            state.worker_state = 'PAUSED_SAFE';
            break;
        end
        state.current_trial_id = char(spec.trial_id);
        state.current_trial_started_utc = utc_now_local();
        state.heartbeat_utc = state.current_trial_started_utc;
        write_text_atomic_local(lock_path, sprintf( ...
            'attempt_id=%s\ntrial_id=%s\nstarted_utc=%s\n', ...
            attempt_id, state.current_trial_id, ...
            state.current_trial_started_utc));
        stage8_r1_write_json_atomic(status_path, state);

        trial_clock = tic;
        [rows, diagnostics] = stage8_r1_evaluate_trial(spec, context);
        runtime_sec = toc(trial_clock);
        checkpoint = checkpoint_local(protocol, spec, rows, diagnostics, ...
            runtime_sec, worker_id, pid, attempt_id);
        current_tmp = fullfile(runtime_root, 'tmp', ...
            [char(spec.trial_id), '.mat.tmp']);
        if isfile(checkpoint_path)
            error('stage8_r1_worker:Collision', ...
                'Assigned checkpoint was created by another writer.');
        end
        save(current_tmp, 'checkpoint', '-mat');
        stage8_r1_validate_checkpoint(current_tmp, protocol, spec);
        [moved, message] = movefile(current_tmp, checkpoint_path);
        if ~moved, error('stage8_r1_worker:AtomicMove', '%s', message); end
        current_tmp = '';
        stage8_r1_validate_checkpoint(checkpoint_path, protocol, spec);
        if isfile(lock_path), delete(lock_path); end
        existing(index) = true;
        append_history_local(runtime_root, checkpoint);
        state.completed_element_trial_count = nnz(existing);
        state.remaining_element_trial_count = height(shard) - nnz(existing);
        state.last_trial_runtime_sec = runtime_sec;
        state.last_checkpoint_utc = checkpoint.created_utc;
        state.current_trial_id = '';
        state.current_trial_started_utc = '';
        state.heartbeat_utc = utc_now_local();
        stage8_r1_write_json_atomic(status_path, state);
        maybe_request_gate_pause_local(runtime_root, protocol);
        if isfile(fullfile(runtime_root, 'control', 'pause.request'))
            state.worker_state = 'PAUSED_SAFE';
            break;
        end
    end
    state.current_trial_id = '';
    state.current_trial_started_utc = '';
    if state.remaining_element_trial_count == 0
        state.worker_state = 'COMPLETE';
    elseif isfile(fullfile(runtime_root, 'control', 'pause.request'))
        state.worker_state = 'PAUSED_SAFE';
    else
        error('stage8_r1_worker:IncompleteExit', ...
            'Worker exited before its shard was complete.');
    end
    state.heartbeat_utc = utc_now_local();
    stage8_r1_write_json_atomic(status_path, state);
    result = state;
catch exception
    if isfile(lock_path)
        movefile(lock_path, fullfile(runtime_root, 'incomplete', ...
            sprintf('worker_%02d_%s.current.lock', worker_id, attempt_id)));
    end
    if ~isempty(current_tmp) && isfile(current_tmp)
        movefile(current_tmp, fullfile(runtime_root, 'incomplete', ...
            sprintf('%s.%s.tmp', state.current_trial_id, attempt_id)));
    end
    state.current_trial_id = '';
    state.current_trial_started_utc = '';
    state.worker_state = 'ERROR_STOPPED';
    state.heartbeat_utc = utc_now_local();
    state.last_error = getReport(exception, 'extended', 'hyperlinks', 'off');
    stage8_r1_write_json_atomic(status_path, state);
    rethrow(exception);
end
clear path_cleanup
end

function checkpoint = checkpoint_local(protocol, spec, rows, diagnostics, ...
    runtime_sec, worker_id, pid, attempt_id)
checkpoint = struct('protocol_version', protocol.protocol_version, ...
    'checkpoint_contract_version', protocol.checkpoint_contract_version, ...
    'trial_id', char(spec.trial_id), ...
    'global_trial_index', double(spec.global_trial_index), ...
    'trial_type', char(spec.trial_type), 'rows', rows, ...
    'element_trial_hash', char(string(diagnostics.element_trial_hash)), ...
    'solver_contract_hash', char(string(protocol.solver_contract_hash)), ...
    'protocol_source_tree_hash', ...
    char(string(protocol.protocol_source_tree_hash)), ...
    'completion_status', 'COMPLETE_PASS', ...
    'scientific_content_hash', '', 'runtime_sec', double(runtime_sec), ...
    'worker_id', double(worker_id), 'pid', double(pid), ...
    'attempt_id', attempt_id, 'created_utc', utc_now_local());
checkpoint.scientific_content_hash = stage8_r1_checkpoint_hash(checkpoint);
end

function validate_existing_set_local(root, protocol, selected)
files = dir(fullfile(root, 'checkpoints', '*.mat'));
for index = 1:numel(files)
    trial_id = erase(string(files(index).name), '.mat');
    match = find(selected.trial_id == trial_id);
    if numel(match) ~= 1
        error('stage8_r1_worker:UnexpectedCheckpoint', ...
            'Checkpoint is outside protocol registry: %s.', trial_id);
    end
    stage8_r1_validate_checkpoint(fullfile(files(index).folder, ...
        files(index).name), protocol, selected(match, :));
end
end

function maybe_request_gate_pause_local(root, protocol)
threshold = double(protocol.pause_after_checkpoint_count);
request = fullfile(root, 'control', 'pause.request');
if threshold < 0 || isfile(request), return; end
count = numel(dir(fullfile(root, 'checkpoints', '*.mat')));
if count >= threshold
    write_text_atomic_local(request, sprintf( ...
        'requested_utc=%s\nrequested_by=GATE_R2\n', utc_now_local()));
end
end

function append_history_local(root, checkpoint)
path_now = fullfile(root, 'logs', sprintf( ...
    'worker_%02d_checkpoint_history.csv', checkpoint.worker_id));
row = table(string(checkpoint.created_utc), checkpoint.worker_id, ...
    string(checkpoint.trial_id), checkpoint.global_trial_index, ...
    string(checkpoint.trial_type), height(checkpoint.rows), ...
    checkpoint.runtime_sec, string(checkpoint.scientific_content_hash), ...
    'VariableNames', {'created_utc','worker_id','trial_id', ...
    'global_trial_index','trial_type','row_count','runtime_sec', ...
    'scientific_content_hash'});
if isfile(path_now)
    writetable(row, path_now, 'WriteMode', 'append', ...
        'WriteVariableNames', false);
else
    writetable(row, path_now);
end
end

function path_now = checkpoint_path_local(root, trial_id)
path_now = fullfile(root, 'checkpoints', [char(string(trial_id)), '.mat']);
end

function write_text_atomic_local(path_now, text_value)
temporary = [path_now, '.tmp'];
fid = fopen(temporary, 'w', 'n', 'UTF-8');
if fid < 0, error('stage8_r1_worker:Write', 'Cannot write %s.', temporary); end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, text_value, 'char');
clear cleanup
movefile(temporary, path_now, 'f');
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
