function status = stage8_r1_build_status(repo_dir, runtime_root)
%STAGE8_R1_BUILD_STATUS Perform a full checkpoint and worker audit.

repo_dir = char(string(repo_dir));
runtime_root = char(string(runtime_root));
tool_dir = fileparts(mfilename('fullpath'));
addpath(tool_dir);
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
protocol = jsondecode(fileread(fullfile(runtime_root, 'protocol.json')));
context = stage8_r1_context(repo_dir, true);
registry = stage8_r1_build_registry(context, protocol.registry_kind);
registry = registry(ismember(registry.global_trial_index, ...
    double(protocol.trial_indices(:))), :);
valid = 0;
invalid = 0;
rows = 0;
k1 = 0;
k2 = 0;
last_error = '';
hashes = strings(0, 1);
for index = 1:height(registry)
    path_now = fullfile(runtime_root, 'checkpoints', ...
        [char(registry.trial_id(index)), '.mat']);
    if ~isfile(path_now), continue; end
    try
        audit = stage8_r1_validate_checkpoint( ...
            path_now, protocol, registry(index, :));
        valid = valid + 1;
        rows = rows + audit.row_count;
        if strcmp(audit.trial_type, 'K1'), k1 = k1 + 1; else, k2 = k2 + 1; end
        hashes(end + 1, 1) = string(audit.scientific_content_hash); %#ok<AGROW>
    catch exception
        invalid = invalid + 1;
        if isempty(last_error)
            last_error = getReport(exception, 'extended', 'hyperlinks', 'off');
        end
    end
end
checkpoint_files = dir(fullfile(runtime_root, 'checkpoints', '*.mat'));
unexpected = numel(checkpoint_files) - valid - invalid;
worker_files = dir(fullfile(runtime_root, 'workers', 'worker_*_status.json'));
worker_states = strings(numel(worker_files), 1);
active_workers = 0;
for index = 1:numel(worker_files)
    worker = jsondecode(fileread(fullfile( ...
        worker_files(index).folder, worker_files(index).name)));
    worker_states(index) = string(worker.worker_state);
    active_workers = active_workers + ...
        double(ismember(worker_states(index), ["STARTING","RUNNING"]));
    if strlength(string(worker.last_error)) > 0 && isempty(last_error)
        last_error = char(string(worker.last_error));
    end
end
tmp_count = numel(dir(fullfile(runtime_root, 'tmp', '*.tmp')));
lock_count = numel(dir(fullfile(runtime_root, 'workers', '*.current.lock')));
pause_requested = isfile(fullfile(runtime_root, 'control', 'pause.request'));
complete = valid == height(registry) && invalid == 0 && unexpected == 0;
safe = active_workers == 0 && tmp_count == 0 && lock_count == 0;
status = struct('protocol_version', protocol.protocol_version, ...
    'protocol_stage', stage_local(complete, safe, pause_requested, active_workers), ...
    'valid_checkpoint_count', valid, ...
    'invalid_checkpoint_count', invalid, ...
    'unexpected_checkpoint_count', unexpected, ...
    'tmp_checkpoint_count', tmp_count, ...
    'current_trial_lock_count', lock_count, ...
    'completed_element_trials', valid, ...
    'total_element_trials', height(registry), ...
    'completed_rows', rows, 'total_rows', 3 * height(registry), ...
    'k1_completed_count', k1, 'k2_completed_count', k2, ...
    'active_worker_count', active_workers, ...
    'worker_states', worker_states, 'pause_requested_flag', pause_requested, ...
    'safe_to_shutdown', safe, 'ready_to_finalize', complete && safe, ...
    'unique_scientific_hash_count', numel(unique(hashes)), ...
    'last_error', last_error, ...
    'formal_6000_trial_status', protocol.formal_6000_trial_status, ...
    'stage8_2_executed_flag', logical(protocol.stage8_2_executed_flag), ...
    'generated_utc', utc_now_local());
stage8_r1_write_json_atomic(fullfile(runtime_root, 'status', ...
    'latest_status.json'), status);
clear path_cleanup
end

function value = stage_local(complete, safe, pause_requested, active)
if complete && safe
    value = 'READY_TO_FINALIZE';
elseif pause_requested && safe
    value = 'PAUSED_SAFE_TO_SHUTDOWN';
elseif active > 0
    value = 'WORKERS_RUNNING';
else
    value = 'RUNTIME_INITIALIZED';
end
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
