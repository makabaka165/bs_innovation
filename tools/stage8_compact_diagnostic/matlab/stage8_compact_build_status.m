function status = stage8_compact_build_status(repo_dir, runtime_root)
%STAGE8_COMPACT_BUILD_STATUS Perform a full inactive-runtime checkpoint audit.

repo_dir = char(string(repo_dir));
runtime_root = char(string(runtime_root));
tool_dir = fileparts(mfilename('fullpath'));
addpath(tool_dir);
addpath(fullfile(repo_dir, 'tools', 'stage8_1b_validation_sharded', 'matlab'));
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
protocol = jsondecode(fileread(fullfile(runtime_root, 'protocol.json')));
context = stage8_compact_context(repo_dir, true);
stage8_compact_verify_protocol(protocol, context);
indices = sort(double(protocol.trial_indices(:)));
registry = context.compact_registry(indices, :);
valid = 0;
invalid = 0;
completed_rows = 0;
separation_count = 0;
last_error = '';
hashes = strings(0, 1);
for index = 1:height(registry)
    path_now = fullfile(runtime_root, 'checkpoints', ...
        [char(registry.diagnostic_trial_id(index)), '.mat']);
    if ~isfile(path_now), continue; end
    try
        audit = stage8_compact_validate_checkpoint( ...
            path_now, protocol, registry(index, :));
        valid = valid + 1;
        completed_rows = completed_rows + audit.row_count;
        separation_count = separation_count + audit.separation_trigger_count;
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
tmp_count = numel(dir(fullfile(runtime_root, 'tmp', '*.tmp')));
lock_count = numel(dir(fullfile(runtime_root, 'workers', '*.current.lock')));
status = struct('protocol_version', protocol.protocol_version, ...
    'valid_checkpoint_count', valid, ...
    'invalid_checkpoint_count', invalid, ...
    'unexpected_checkpoint_count', unexpected, ...
    'tmp_checkpoint_count', tmp_count, ...
    'current_trial_lock_count', lock_count, ...
    'completed_element_trials', valid, ...
    'total_element_trials', height(registry), ...
    'completed_rows', completed_rows, ...
    'total_rows', sum(registry.expected_row_count), ...
    'separation_trigger_count', separation_count, ...
    'unique_scientific_hash_count', numel(unique(hashes)), ...
    'last_error', last_error, 'generated_utc', utc_now_local());
clear path_cleanup
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
