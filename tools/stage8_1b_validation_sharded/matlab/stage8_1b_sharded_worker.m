function result = stage8_1b_sharded_worker(repo_dir, runtime_root, worker_id)
%STAGE8_1B_SHARDED_WORKER Run one immutable odd/even or all-trials shard.

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
    error('stage8_1b_sharded_worker:Protocol', ...
        'Immutable protocol.json is missing.');
end
protocol = jsondecode(fileread(protocol_path));
worker_count = double(protocol.selected_worker_count);
if worker_id < 1 || worker_id > worker_count || worker_id ~= fix(worker_id)
    error('stage8_1b_sharded_worker:WorkerId', ...
        'Worker ID is outside the selected execution mode.');
end

attempt_id = char(java.util.UUID.randomUUID());
pid = feature('getpid');
started_utc = utc_now_local();
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
    'pid', pid, 'started_utc', started_utc, 'ended_utc', '', ...
    'completion_status', 'RUNNING');
stage8_1b_write_json_atomic(attempt_path, attempt);

state = initial_state_local(protocol, worker_id, pid, attempt_id, started_utc);
stage8_1b_write_json_atomic(status_path, state);
current_tmp = '';
try
    context = stage8_1b_frozen_context(repo_dir, true);
    stage8_1b_verify_protocol(protocol, context);
    registry = context.registry( ...
        context.registry.trial_index_within_stratum <= ...
        double(protocol.trials_per_stratum), :);
    [pair_ids, pair_indices] = pair_registry_local(registry);
    if numel(pair_ids) ~= double(protocol.common_trial_count) || ...
            height(registry) ~= double(protocol.row_count)
        error('stage8_1b_sharded_worker:RegistryCardinality', ...
            'Selected registry differs from protocol cardinality.');
    end
    verify_partition_local(pair_indices, worker_count);
    assigned = shard_mask_local(pair_indices, worker_id, worker_count);
    assigned_ids = pair_ids(assigned);
    assigned_indices = pair_indices(assigned);

    archive_stale_tmp_local(runtime_root, assigned_ids, attempt_id);
    [existing, metrics] = validate_existing_local( ...
        runtime_root, protocol, registry, pair_ids, pair_indices, ...
        assigned_ids, assigned_indices, worker_id);
    state.assigned_common_trial_count = numel(assigned_ids);
    state.completed_common_trial_count = nnz(existing);
    state.skipped_valid_checkpoint_count = nnz(existing);
    state.remaining_common_trial_count = numel(assigned_ids) - nnz(existing);
    state.separation_trigger_row_count = metrics.separation_trigger_row_count;
    state.state_counts = metrics.state_counts;
    state.last_checkpoint_utc = metrics.last_checkpoint_utc;
    state.worker_state = 'RUNNING';
    state.heartbeat_utc = utc_now_local();
    stage8_1b_write_json_atomic(status_path, state);

    for assigned_row = 1:numel(assigned_ids)
        common_id = assigned_ids(assigned_row);
        global_index = assigned_indices(assigned_row);
        expected_rows = registry(registry.common_trial_id == common_id, :);
        checkpoint_path = fullfile(runtime_root, 'checkpoints', ...
            [char(common_id), '.mat']);
        if isfile(checkpoint_path)
            stage8_1b_validate_checkpoint( ...
                checkpoint_path, protocol, expected_rows);
            continue;
        end
        if isfile(fullfile(runtime_root, 'control', 'pause.request'))
            state.worker_state = 'PAUSED_SAFE';
            break;
        end

        state.current_common_trial_id = char(common_id);
        state.current_stratum_id = char(string(expected_rows.stratum_id(1)));
        state.current_trial_started_utc = utc_now_local();
        state.heartbeat_utc = state.current_trial_started_utc;
        write_text_atomic_local(lock_path, sprintf( ...
            'attempt_id=%s\ncommon_trial_id=%s\nstarted_utc=%s\n', ...
            attempt_id, char(common_id), state.current_trial_started_utc));
        stage8_1b_write_json_atomic(status_path, state);

        trial_clock = tic;
        [rows, diagnostics] = stage8_1b_evaluate_common_trial( ...
            expected_rows, context.plan, context.thresholds, struct( ...
            'formal_run', logical(protocol.scientific_formal_run), ...
            'separation_formal_run', ...
            logical(protocol.separation_formal_run), ...
            'fit_options', struct(), 'Bsep', 199, ...
            'run_separation', true));
        runtime_sec = toc(trial_clock);
        checkpoint = checkpoint_local(protocol, rows, global_index, ...
            runtime_sec, worker_id, attempt_id);
        current_tmp = fullfile(runtime_root, 'tmp', ...
            [char(common_id), '.mat.tmp']);
        if isfile(checkpoint_path)
            error('stage8_1b_sharded_worker:CheckpointCollision', ...
                'Another writer created assigned checkpoint %s.', common_id);
        end
        save(current_tmp, 'checkpoint', '-mat');
        stage8_1b_validate_checkpoint(current_tmp, protocol, expected_rows);
        [moved, message] = movefile(current_tmp, checkpoint_path);
        if ~moved
            error('stage8_1b_sharded_worker:AtomicMove', '%s', message);
        end
        current_tmp = '';
        stage8_1b_validate_checkpoint(checkpoint_path, protocol, expected_rows);
        if isfile(lock_path), delete(lock_path); end

        existing(assigned_row) = true;
        state.completed_common_trial_count = nnz(existing);
        state.remaining_common_trial_count = numel(existing) - nnz(existing);
        state.separation_trigger_row_count = ...
            state.separation_trigger_row_count + ...
            diagnostics.separation_trigger_row_count;
        state.state_counts = add_states_local(state.state_counts, rows);
        state.last_trial_runtime_sec = runtime_sec;
        state.last_checkpoint_utc = checkpoint.created_utc;
        state.current_common_trial_id = '';
        state.current_stratum_id = '';
        state.current_trial_started_utc = '';
        state.heartbeat_utc = utc_now_local();
        stage8_1b_write_json_atomic(status_path, state);
        append_history_local(runtime_root, checkpoint);
        if isfile(fullfile(runtime_root, 'control', 'pause.request'))
            state.worker_state = 'PAUSED_SAFE';
            break;
        end
    end

    state.current_common_trial_id = '';
    state.current_stratum_id = '';
    state.current_trial_started_utc = '';
    state.heartbeat_utc = utc_now_local();
    if state.remaining_common_trial_count == 0
        state.worker_state = 'COMPLETE';
    elseif isfile(fullfile(runtime_root, 'control', 'pause.request'))
        state.worker_state = 'PAUSED_SAFE';
    else
        error('stage8_1b_sharded_worker:IncompleteExit', ...
            'Worker exited before its shard was complete.');
    end
    stage8_1b_write_json_atomic(status_path, state);
    attempt.ended_utc = utc_now_local();
    attempt.completion_status = state.worker_state;
    stage8_1b_write_json_atomic(attempt_path, attempt);
    result = state;
catch exception
    failed_common_trial_id = state.current_common_trial_id;
    if isfile(lock_path)
        destination = fullfile(runtime_root, 'incomplete', ...
            sprintf('worker_%02d_%s.current.lock', worker_id, attempt_id));
        movefile(lock_path, destination, 'f');
    end
    state.worker_state = 'ERROR_STOPPED';
    state.current_common_trial_id = '';
    state.current_stratum_id = '';
    state.current_trial_started_utc = '';
    state.heartbeat_utc = utc_now_local();
    state.last_error = getReport(exception, 'extended', 'hyperlinks', 'off');
    stage8_1b_write_json_atomic(status_path, state);
    attempt.ended_utc = utc_now_local();
    attempt.completion_status = 'ERROR_STOPPED';
    attempt.last_error = state.last_error;
    stage8_1b_write_json_atomic(attempt_path, attempt);
    if ~isempty(current_tmp) && isfile(current_tmp)
        destination = fullfile(runtime_root, 'incomplete', ...
            sprintf('%s.%s.tmp', char(failed_common_trial_id), attempt_id));
        movefile(current_tmp, destination, 'f');
    end
    rethrow(exception);
end
clear path_cleanup
end

function checkpoint = checkpoint_local(protocol, rows, global_index, ...
    runtime_sec, worker_id, attempt_id)
checkpoint = struct( ...
    'protocol_version', char(string(protocol.protocol_version)), ...
    'checkpoint_contract_version', ...
    char(string(protocol.checkpoint_contract_version)), ...
    'common_trial_id', char(string(rows.common_trial_id(1))), ...
    'global_common_trial_index', double(global_index), 'rows', rows, ...
    'stage8_stable_code_identity_hash', ...
    char(string(protocol.stage8_stable_code_identity_hash)), ...
    'stage8_plan_hash', char(string(protocol.stage8_plan_hash)), ...
    'stage8_validation_plan_hash', ...
    char(string(protocol.stage8_validation_plan_hash)), ...
    'measurement_registry_hash', ...
    char(string(protocol.measurement_registry_hash)), ...
    'calibration_evidence_bundle_hash', ...
    char(string(protocol.calibration_evidence_bundle_hash)), ...
    'threshold_set_hash', char(string(protocol.threshold_set_hash)), ...
    'calibration_snapshot_hash', ...
    char(string(protocol.calibration_snapshot_hash)), ...
    'threshold_lookup_only_flag', true, ...
    'threshold_modification_flag', false, ...
    'completion_status', 'COMPLETE_PASS', 'content_hash', '', ...
    'runtime_sec', double(runtime_sec), 'worker_id', double(worker_id), ...
    'attempt_id', attempt_id, 'created_utc', utc_now_local());
checkpoint.content_hash = stage8_1b_checkpoint_content_hash(checkpoint);
end

function [pair_ids, pair_indices] = pair_registry_local(registry)
pair_ids = unique(string(registry.common_trial_id), 'stable');
pair_indices = zeros(numel(pair_ids), 1);
for index = 1:numel(pair_ids)
    rows = registry(registry.common_trial_id == pair_ids(index), :);
    if height(rows) ~= 2
        error('stage8_1b_sharded_worker:PairRegistry', ...
            'Selected registry contains an incomplete pair.');
    end
    pair_indices(index) = (min(rows.evaluation_row_index) + 1) / 2;
end
end

function mask = shard_mask_local(indices, worker_id, worker_count)
if worker_count == 1
    mask = true(size(indices));
else
    mask = mod(indices, 2) == mod(worker_id, 2);
end
end

function verify_partition_local(indices, worker_count)
if worker_count == 1, return; end
left = indices(mod(indices, 2) == 1);
right = indices(mod(indices, 2) == 0);
if ~isempty(intersect(left, right)) || ...
        ~isequal(sort([left; right]), sort(indices))
    error('stage8_1b_sharded_worker:Partition', ...
        'Odd/even shards are not disjoint and complete.');
end
end

function archive_stale_tmp_local(root, assigned_ids, attempt_id)
files = dir(fullfile(root, 'tmp', '*.tmp'));
for index = 1:numel(files)
    name = string(files(index).name);
    common_id = erase(name, '.mat.tmp');
    if ismember(common_id, assigned_ids)
        source = fullfile(files(index).folder, files(index).name);
        destination = fullfile(root, 'incomplete', ...
            sprintf('%s.%s.stale.tmp', char(common_id), attempt_id));
        if isfile(source), movefile(source, destination); end
    end
end
end

function [existing, metrics] = validate_existing_local( ...
    root, protocol, registry, all_ids, all_indices, ...
    assigned_ids, assigned_indices, worker_id)
files = dir(fullfile(root, 'checkpoints', '*.mat'));
for index = 1:numel(files)
    common_id = erase(string(files(index).name), '.mat');
    selected = find(all_ids == common_id);
    if numel(selected) ~= 1
        error('stage8_1b_sharded_worker:UnexpectedCheckpoint', ...
            'Checkpoint is outside the selected registry: %s.', common_id);
    end
    expected = registry(registry.common_trial_id == common_id, :);
    audit = stage8_1b_validate_checkpoint( ...
        fullfile(files(index).folder, files(index).name), protocol, expected);
    if audit.global_common_trial_index ~= all_indices(selected)
        error('stage8_1b_sharded_worker:CheckpointIndex', ...
            'Checkpoint global index differs from selected registry.');
    end
end
existing = false(numel(assigned_ids), 1);
metrics = empty_metrics_local();
history_rows = cell(numel(assigned_ids), 1);
history_count = 0;
for index = 1:numel(assigned_ids)
    path_now = fullfile(root, 'checkpoints', ...
        [char(assigned_ids(index)), '.mat']);
    if ~isfile(path_now), continue; end
    expected = registry(registry.common_trial_id == assigned_ids(index), :);
    audit = stage8_1b_validate_checkpoint(path_now, protocol, expected);
    if audit.global_common_trial_index ~= assigned_indices(index)
        error('stage8_1b_sharded_worker:AssignedIndex', ...
            'Assigned checkpoint index is invalid.');
    end
    loaded = load(path_now, 'checkpoint', '-mat');
    checkpoint = loaded.checkpoint;
    existing(index) = true;
    metrics = add_checkpoint_metrics_local(metrics, checkpoint);
    history_count = history_count + 1;
    history_rows{history_count} = history_row_local(checkpoint);
end
write_history_local(root, worker_id, history_rows(1:history_count));
end

function state = initial_state_local(protocol, worker_id, pid, attempt_id, started)
state = struct('protocol_version', char(string(protocol.protocol_version)), ...
    'worker_id', worker_id, 'pid', pid, 'attempt_id', attempt_id, ...
    'worker_state', 'STARTING', 'started_utc', started, ...
    'heartbeat_utc', started, 'current_common_trial_id', '', ...
    'current_stratum_id', '', 'current_trial_started_utc', '', ...
    'assigned_common_trial_count', 0, ...
    'completed_common_trial_count', 0, ...
    'skipped_valid_checkpoint_count', 0, ...
    'remaining_common_trial_count', 0, ...
    'separation_trigger_row_count', 0, ...
    'state_counts', empty_state_counts_local(), ...
    'last_trial_runtime_sec', 0, 'last_checkpoint_utc', '', ...
    'last_error', '');
end

function metrics = empty_metrics_local()
metrics = struct('separation_trigger_row_count', 0, ...
    'state_counts', empty_state_counts_local(), ...
    'last_checkpoint_utc', '');
end

function counts = empty_state_counts_local()
counts = struct('K1', 0, 'K2_RESOLVED', 0, 'K2_UNRESOLVED', 0, ...
    'SEARCH_NOT_CONVERGED', 0, 'NUMERIC_RANK_DEFICIENT', 0, ...
    'OUT_OF_LOCAL_CELL', 0);
end

function counts = add_states_local(counts, rows)
names = fieldnames(counts);
states = string(rows.state);
for index = 1:numel(names)
    counts.(names{index}) = counts.(names{index}) + ...
        nnz(states == string(names{index}));
end
end

function metrics = add_checkpoint_metrics_local(metrics, checkpoint)
metrics.state_counts = add_states_local(metrics.state_counts, checkpoint.rows);
metrics.separation_trigger_row_count = ...
    metrics.separation_trigger_row_count + ...
    nnz(~startsWith(string(checkpoint.rows.separation_status), "NOT_RUN"));
if isempty(metrics.last_checkpoint_utc) || ...
        string(checkpoint.created_utc) > string(metrics.last_checkpoint_utc)
    metrics.last_checkpoint_utc = char(string(checkpoint.created_utc));
end
end

function row = history_row_local(checkpoint)
rows = sortrows(checkpoint.rows, 'evaluation_row_index');
row = struct('created_utc', string(checkpoint.created_utc), ...
    'worker_id', double(checkpoint.worker_id), ...
    'common_trial_id', string(checkpoint.common_trial_id), ...
    'global_common_trial_index', double(checkpoint.global_common_trial_index), ...
    'stratum_id', string(rows.stratum_id(1)), ...
    'runtime_sec', double(checkpoint.runtime_sec), ...
    'separation_trigger_rows', ...
    nnz(~startsWith(string(rows.separation_status), "NOT_RUN")), ...
    'primary_state', string(rows.state(1)), ...
    'sensitivity_state', string(rows.state(2)), ...
    'content_hash', string(checkpoint.content_hash));
end

function append_history_local(root, checkpoint)
path_now = fullfile(root, 'logs', ...
    sprintf('worker_%02d_checkpoint_history.csv', checkpoint.worker_id));
row = struct2table(history_row_local(checkpoint));
if isfile(path_now)
    writetable(row, path_now, 'WriteMode', 'append', ...
        'WriteVariableNames', false);
else
    writetable(row, path_now);
end
end

function write_history_local(root, worker_id, rows)
path_now = fullfile(root, 'logs', ...
    sprintf('worker_%02d_checkpoint_history.csv', worker_id));
if isempty(rows)
    if isfile(path_now), delete(path_now); end
    return;
end
history = struct2table(vertcat(rows{:}));
temporary = [path_now, '.tmp'];
% The temporary suffix is intentionally not .csv.
% Explicit FileType keeps R2022b from inferring a spreadsheet format.
writetable(history, temporary, 'FileType', 'text');
movefile(temporary, path_now, 'f');
end

function write_text_atomic_local(path_now, text_value)
temporary = [path_now, '.tmp'];
fid = fopen(temporary, 'w', 'n', 'UTF-8');
if fid < 0, error('stage8_1b_sharded_worker:Write', ...
        'Unable to write %s.', temporary); end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, text_value, 'char');
clear cleanup
movefile(temporary, path_now, 'f');
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
