function result = stage8_compact_worker(repo_dir, runtime_root, worker_id)
%STAGE8_COMPACT_WORKER Run one deterministic modulo shard.

repo_dir = char(string(repo_dir));
runtime_root = char(string(runtime_root));
worker_id = double(worker_id);
tool_dir = fileparts(mfilename('fullpath'));
addpath(tool_dir);
addpath(fullfile(repo_dir, 'tools', 'stage8_1b_validation_sharded', 'matlab'));
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
protocol_path = fullfile(runtime_root, 'protocol.json');
if ~isfile(protocol_path)
    error('stage8_compact_worker:Protocol', 'protocol.json is missing.');
end
protocol = jsondecode(fileread(protocol_path));
worker_count = double(protocol.selected_worker_count);
if worker_id < 1 || worker_id > worker_count || worker_id ~= fix(worker_id)
    error('stage8_compact_worker:WorkerId', ...
        'worker_id is outside selected execution mode.');
end

attempt_id = char(java.util.UUID.randomUUID());
pid = feature('getpid');
started = utc_now_local();
status_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d_status.json', worker_id));
pid_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d.pid', worker_id));
lock_path = fullfile(runtime_root, 'workers', ...
    sprintf('worker_%02d.current.lock', worker_id));
attempt_path = fullfile(runtime_root, 'workers', ...
    sprintf('attempt_%02d_%s.json', worker_id, attempt_id));
write_text_atomic_local(pid_path, sprintf('%d\n', pid));
attempt = struct('attempt_id', attempt_id, 'worker_id', worker_id, ...
    'pid', pid, 'started_utc', started, 'ended_utc', '', ...
    'completion_status', 'RUNNING');
stage8_1b_write_json_atomic(attempt_path, attempt);
state = initial_state_local(protocol, worker_id, pid, attempt_id, started);
stage8_1b_write_json_atomic(status_path, state);
current_tmp = '';
try
    context = stage8_compact_context(repo_dir, true);
    stage8_compact_verify_protocol(protocol, context);
    registry = context.compact_registry;
    selected = registry(ismember(registry.global_trial_index, ...
        double(protocol.trial_indices(:))), :);
    assigned = mod(selected.global_trial_index - 1, worker_count) == ...
        worker_id - 1;
    shard = selected(assigned, :);
    validate_existing_set_local(runtime_root, protocol, selected);
    archive_stale_local(runtime_root, shard.diagnostic_trial_id, attempt_id);
    existing = false(height(shard), 1);
    for index = 1:height(shard)
        path_now = checkpoint_path_local(runtime_root, ...
            shard.diagnostic_trial_id(index));
        if isfile(path_now)
            stage8_compact_validate_checkpoint(path_now, protocol, ...
                shard(index, :));
            existing(index) = true;
        end
    end
    write_history_from_existing_local(runtime_root, protocol, shard, worker_id);
    state.assigned_element_trial_count = height(shard);
    state.completed_element_trial_count = nnz(existing);
    state.skipped_valid_checkpoint_count = nnz(existing);
    state.remaining_element_trial_count = height(shard) - nnz(existing);
    state.worker_state = 'RUNNING';
    state.heartbeat_utc = utc_now_local();
    stage8_1b_write_json_atomic(status_path, state);

    for index = 1:height(shard)
        spec = shard(index, :);
        checkpoint_path = checkpoint_path_local( ...
            runtime_root, spec.diagnostic_trial_id);
        if isfile(checkpoint_path), continue; end
        if isfile(fullfile(runtime_root, 'control', 'pause.request'))
            state.worker_state = 'PAUSED_SAFE';
            break;
        end
        state.current_trial_id = char(spec.diagnostic_trial_id);
        state.current_trial_type = char(spec.trial_type);
        state.current_stratum_id = char(spec.stratum_id);
        state.current_profile_id = double(spec.profile_id);
        state.current_trial_started_utc = utc_now_local();
        state.heartbeat_utc = state.current_trial_started_utc;
        write_text_atomic_local(lock_path, sprintf( ...
            'attempt_id=%s\ntrial_id=%s\nstarted_utc=%s\n', ...
            attempt_id, state.current_trial_id, ...
            state.current_trial_started_utc));
        stage8_1b_write_json_atomic(status_path, state);

        trial_clock = tic;
        [rows, diagnostics] = stage8_compact_evaluate_trial(spec, context);
        runtime_sec = toc(trial_clock);
        checkpoint = checkpoint_local(protocol, spec, rows, diagnostics, ...
            runtime_sec, worker_id, pid, attempt_id);
        current_tmp = fullfile(runtime_root, 'tmp', ...
            [char(spec.diagnostic_trial_id), '.mat.tmp']);
        if isfile(checkpoint_path)
            error('stage8_compact_worker:Collision', ...
                'Assigned checkpoint was created by another writer.');
        end
        save(current_tmp, 'checkpoint', '-mat');
        stage8_compact_validate_checkpoint(current_tmp, protocol, spec);
        [moved, message] = movefile(current_tmp, checkpoint_path);
        if ~moved
            error('stage8_compact_worker:AtomicMove', '%s', message);
        end
        current_tmp = '';
        stage8_compact_validate_checkpoint(checkpoint_path, protocol, spec);
        if isfile(lock_path), delete(lock_path); end
        existing(index) = true;
        append_history_local(runtime_root, checkpoint, diagnostics.runtime_class);
        state.completed_element_trial_count = nnz(existing);
        state.remaining_element_trial_count = height(shard) - nnz(existing);
        state.last_trial_runtime_sec = runtime_sec;
        state.last_checkpoint_utc = checkpoint.created_utc;
        state.separation_trigger_count = state.separation_trigger_count + ...
            checkpoint.separation_trigger_count;
        state.current_trial_id = '';
        state.current_trial_type = '';
        state.current_stratum_id = '';
        state.current_profile_id = 0;
        state.current_trial_started_utc = '';
        state.heartbeat_utc = utc_now_local();
        stage8_1b_write_json_atomic(status_path, state);
        if isfield(protocol, 'inter_trial_grace_sec') && ...
                double(protocol.inter_trial_grace_sec) > 0
            pause(double(protocol.inter_trial_grace_sec));
        end
        if isfile(fullfile(runtime_root, 'control', 'pause.request'))
            state.worker_state = 'PAUSED_SAFE';
            break;
        end
    end
    state = clear_current_local(state);
    if state.remaining_element_trial_count == 0
        state.worker_state = 'COMPLETE';
    elseif isfile(fullfile(runtime_root, 'control', 'pause.request'))
        state.worker_state = 'PAUSED_SAFE';
    else
        error('stage8_compact_worker:IncompleteExit', ...
            'Worker exited before its shard was complete.');
    end
    state.heartbeat_utc = utc_now_local();
    stage8_1b_write_json_atomic(status_path, state);
    attempt.ended_utc = utc_now_local();
    attempt.completion_status = state.worker_state;
    stage8_1b_write_json_atomic(attempt_path, attempt);
    result = state;
catch exception
    failed_id = state.current_trial_id;
    if isfile(lock_path)
        movefile(lock_path, fullfile(runtime_root, 'incomplete', ...
            sprintf('worker_%02d_%s.current.lock', worker_id, attempt_id)));
    end
    if ~isempty(current_tmp) && isfile(current_tmp)
        movefile(current_tmp, fullfile(runtime_root, 'incomplete', ...
            sprintf('%s.%s.tmp', failed_id, attempt_id)));
    end
    state = clear_current_local(state);
    state.worker_state = 'ERROR_STOPPED';
    state.heartbeat_utc = utc_now_local();
    state.last_error = getReport(exception, 'extended', ...
        'hyperlinks', 'off');
    stage8_1b_write_json_atomic(status_path, state);
    attempt.ended_utc = utc_now_local();
    attempt.completion_status = 'ERROR_STOPPED';
    attempt.last_error = state.last_error;
    stage8_1b_write_json_atomic(attempt_path, attempt);
    rethrow(exception);
end
clear path_cleanup
end

function checkpoint = checkpoint_local(protocol, spec, rows, diagnostics, ...
    runtime_sec, worker_id, pid, attempt_id)
constants = stage8_compact_constants();
checkpoint = struct( ...
    'protocol_version', char(string(protocol.protocol_version)), ...
    'checkpoint_contract_version', ...
    char(string(protocol.checkpoint_contract_version)), ...
    'diagnostic_trial_id', char(spec.diagnostic_trial_id), ...
    'global_trial_index', double(spec.global_trial_index), ...
    'trial_type', char(spec.trial_type), 'stratum_id', char(spec.stratum_id), ...
    'profile_id', double(spec.profile_id), 'rows', rows, ...
    'truth_metrics', diagnostics.truth_metrics, ...
    'seeds', struct('parameter_seed', double(spec.parameter_seed), ...
    'element_noise_seed', double(spec.element_noise_seed), ...
    'separation_auxiliary_seed', ...
    double(spec.separation_auxiliary_seed)), ...
    'element_trial_hash', char(string(diagnostics.element_trial_hash)), ...
    'stage8_stable_code_identity_hash', ...
    char(string(protocol.stage8_stable_code_identity_hash)), ...
    'stage8_plan_hash', char(string(protocol.stage8_plan_hash)), ...
    'stage8_calibration_plan_hash', ...
    char(string(protocol.stage8_calibration_plan_hash)), ...
    'stage8_validation_plan_hash', ...
    char(string(protocol.stage8_validation_plan_hash)), ...
    'measurement_registry_hash', ...
    char(string(protocol.measurement_registry_hash)), ...
    'calibration_evidence_bundle_hash', ...
    char(string(protocol.calibration_evidence_bundle_hash)), ...
    'threshold_set_hash', char(string(protocol.threshold_set_hash)), ...
    'threshold_artifact_hashes', string({ ...
    constants.primary_threshold_artifact_hash, ...
    constants.sensitivity_threshold_artifact_hash}), ...
    'diagnostic_protocol_source_hash', ...
    char(string(protocol.diagnostic_protocol_source_hash)), ...
    'runtime_sec', double(runtime_sec), ...
    'separation_trigger_count', ...
    double(diagnostics.separation_trigger_count), ...
    'completion_status', 'COMPLETE_PASS', ...
    'scientific_content_hash', '', 'worker_id', double(worker_id), ...
    'pid', double(pid), 'attempt_id', attempt_id, ...
    'created_utc', utc_now_local());
checkpoint.scientific_content_hash = ...
    stage8_compact_checkpoint_hash(checkpoint);
end

function validate_existing_set_local(root, protocol, selected)
files = dir(fullfile(root, 'checkpoints', '*.mat'));
for index = 1:numel(files)
    trial_id = erase(string(files(index).name), '.mat');
    match = find(selected.diagnostic_trial_id == trial_id);
    if numel(match) ~= 1
        error('stage8_compact_worker:UnexpectedCheckpoint', ...
            'Checkpoint is outside protocol registry: %s.', trial_id);
    end
    stage8_compact_validate_checkpoint(fullfile(files(index).folder, ...
        files(index).name), protocol, selected(match, :));
end
end

function archive_stale_local(root, assigned_ids, attempt_id)
files = dir(fullfile(root, 'tmp', '*.tmp'));
for index = 1:numel(files)
    trial_id = erase(string(files(index).name), '.mat.tmp');
    if ~ismember(trial_id, assigned_ids), continue; end
    movefile(fullfile(files(index).folder, files(index).name), ...
        fullfile(root, 'incomplete', sprintf('%s.%s.stale.tmp', ...
        trial_id, attempt_id)));
end
end

function path_now = checkpoint_path_local(root, trial_id)
path_now = fullfile(root, 'checkpoints', [char(string(trial_id)), '.mat']);
end

function state = initial_state_local(protocol, worker_id, pid, attempt_id, started)
state = struct('protocol_version', char(string(protocol.protocol_version)), ...
    'worker_id', worker_id, 'pid', pid, 'attempt_id', attempt_id, ...
    'worker_state', 'STARTING', 'started_utc', started, ...
    'heartbeat_utc', started, 'current_trial_id', '', ...
    'current_trial_type', '', 'current_stratum_id', '', ...
    'current_profile_id', 0, 'current_trial_started_utc', '', ...
    'assigned_element_trial_count', 0, ...
    'completed_element_trial_count', 0, ...
    'skipped_valid_checkpoint_count', 0, ...
    'remaining_element_trial_count', 0, 'separation_trigger_count', 0, ...
    'last_trial_runtime_sec', 0, 'last_checkpoint_utc', '', ...
    'last_error', '');
end

function state = clear_current_local(state)
state.current_trial_id = '';
state.current_trial_type = '';
state.current_stratum_id = '';
state.current_profile_id = 0;
state.current_trial_started_utc = '';
end

function append_history_local(root, checkpoint, runtime_class)
path_now = fullfile(root, 'logs', sprintf( ...
    'worker_%02d_checkpoint_history.csv', checkpoint.worker_id));
states = strjoin(string(checkpoint.rows.diagnostic_state), '|');
row = table(string(checkpoint.created_utc), checkpoint.worker_id, ...
    string(checkpoint.diagnostic_trial_id), checkpoint.global_trial_index, ...
    string(checkpoint.trial_type), string(checkpoint.stratum_id), ...
    checkpoint.profile_id, height(checkpoint.rows), checkpoint.runtime_sec, ...
    checkpoint.separation_trigger_count, string(runtime_class), states, ...
    string(checkpoint.scientific_content_hash), 'VariableNames', ...
    {'created_utc','worker_id','diagnostic_trial_id','global_trial_index', ...
    'trial_type','stratum_id','profile_id','row_count','runtime_sec', ...
    'separation_trigger_count','runtime_class','states', ...
    'scientific_content_hash'});
if isfile(path_now)
    writetable(row, path_now, 'WriteMode', 'append', ...
        'WriteVariableNames', false);
else
    writetable(row, path_now);
end
end

function write_history_from_existing_local(root, protocol, shard, worker_id)
path_now = fullfile(root, 'logs', sprintf( ...
    'worker_%02d_checkpoint_history.csv', worker_id));
if isfile(path_now), delete(path_now); end
for index = 1:height(shard)
    checkpoint_path = checkpoint_path_local(root, shard.diagnostic_trial_id(index));
    if ~isfile(checkpoint_path), continue; end
    stage8_compact_validate_checkpoint(checkpoint_path, protocol, shard(index, :));
    loaded = load(checkpoint_path, 'checkpoint', '-mat');
    checkpoint = loaded.checkpoint;
    runtime_class = runtime_class_from_checkpoint_local(checkpoint);
    append_history_local(root, checkpoint, runtime_class);
end
end

function value = runtime_class_from_checkpoint_local(checkpoint)
if strcmp(checkpoint.trial_type, 'K1')
    if checkpoint.separation_trigger_count > 0
        value = 'K1_SEPARATION_TRIGGERED';
    else
        value = 'K1_NO_SEPARATION';
    end
elseif any(checkpoint.rows.sentinel_flag)
    if checkpoint.separation_trigger_count > 0
        value = 'K2_SENTINEL_SEPARATION_TRIGGERED';
    else
        value = 'K2_SENTINEL_NO_SEPARATION';
    end
else
    value = 'K2_NON_SENTINEL';
end
end

function write_text_atomic_local(path_now, text_value)
temporary = [path_now, '.tmp'];
fid = fopen(temporary, 'w', 'n', 'UTF-8');
if fid < 0
    error('stage8_compact_worker:Write', 'Unable to write %s.', temporary);
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, text_value, 'char');
clear cleanup
movefile(temporary, path_now, 'f');
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
