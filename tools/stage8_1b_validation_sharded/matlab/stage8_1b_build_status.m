function status = stage8_1b_build_status(repo_dir, runtime_root)
%STAGE8_1B_BUILD_STATUS Build a detailed checkpoint audit when MATLAB is idle.

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
context = stage8_1b_frozen_context(repo_dir, true);
stage8_1b_verify_protocol(protocol, context);
registry = context.registry(context.registry.trial_index_within_stratum <= ...
    double(protocol.trials_per_stratum), :);
pair_ids = unique(string(registry.common_trial_id), 'stable');
valid = 0;
invalid = 0;
runtime_seconds = zeros(0, 1);
separation_rows = 0;
state_counts = struct('K1', 0, 'K2_RESOLVED', 0, ...
    'K2_UNRESOLVED', 0, 'SEARCH_NOT_CONVERGED', 0, ...
    'NUMERIC_RANK_DEFICIENT', 0, 'OUT_OF_LOCAL_CELL', 0);
last_error = '';
checkpoint_files = dir(fullfile(runtime_root, 'checkpoints', '*.mat'));
expected_names = pair_ids + ".mat";
unexpected_names = setdiff(string({checkpoint_files.name}), expected_names);
if ~isempty(unexpected_names)
    invalid = invalid + numel(unexpected_names);
    last_error = sprintf('Unexpected checkpoint file: %s', unexpected_names(1));
end
for index = 1:numel(pair_ids)
    path_now = fullfile(runtime_root, 'checkpoints', ...
        [char(pair_ids(index)), '.mat']);
    if ~isfile(path_now), continue; end
    expected = registry(registry.common_trial_id == pair_ids(index), :);
    try
        checkpoint_audit = stage8_1b_validate_checkpoint( ...
            path_now, protocol, expected);
        stage8_1b_write_checkpoint_audit( ...
            path_now, protocol, checkpoint_audit);
        loaded = load(path_now, 'checkpoint', '-mat');
        valid = valid + 1;
        runtime_seconds(end + 1, 1) = ...
            double(loaded.checkpoint.runtime_sec); %#ok<AGROW>
        states = string(loaded.checkpoint.rows.state);
        names = fieldnames(state_counts);
        for name_index = 1:numel(names)
            state_counts.(names{name_index}) = ...
                state_counts.(names{name_index}) + ...
                nnz(states == string(names{name_index}));
        end
        separation_rows = separation_rows + nnz(~startsWith( ...
            string(loaded.checkpoint.rows.separation_status), "NOT_RUN"));
    catch exception
        invalid = invalid + 1;
        if isempty(last_error)
            last_error = getReport(exception, 'extended', ...
                'hyperlinks', 'off');
        end
    end
end
tmp_count = numel(dir(fullfile(runtime_root, 'tmp', '*.tmp')));
lock_count = numel(dir(fullfile(runtime_root, 'workers', '*.current.lock')));
status = struct('protocol_version', protocol.protocol_version, ...
    'protocol_runner_commit', protocol.protocol_runner_commit, ...
    'valid_checkpoint_count', valid, ...
    'invalid_checkpoint_count', invalid, 'tmp_checkpoint_count', tmp_count, ...
    'current_trial_lock_count', lock_count, ...
    'completed_common_trials', valid, ...
    'remaining_common_trials', double(protocol.common_trial_count) - valid, ...
    'completed_rows', 2 * valid, ...
    'separation_trigger_row_count', separation_rows, ...
    'state_counts', state_counts, ...
    'summed_successful_trial_compute_sec', sum(runtime_seconds), ...
    'runtime_p50_sec', percentile_local(runtime_seconds, 0.50), ...
    'runtime_p75_sec', percentile_local(runtime_seconds, 0.75), ...
    'runtime_p90_sec', percentile_local(runtime_seconds, 0.90), ...
    'last_error', last_error, 'generated_utc', utc_now_local());
clear path_cleanup
end

function value = percentile_local(values, probability)
if isempty(values), value = NaN; return; end
values = sort(values(:));
position = 1 + (numel(values) - 1) * probability;
left = floor(position);
right = ceil(position);
if left == right
    value = values(left);
else
    value = values(left) + (position - left) * ...
        (values(right) - values(left));
end
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
