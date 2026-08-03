function output = stage8_k2_mc_run(repo_dir, runtime_root)
%STAGE8_K2_MC_RUN Run or resume the formal 1680-trial experiment.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_mc_run:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
constants = stage8_k2_mc_constants();
if nargin < 2 || isempty(runtime_root)
    runtime_root = constants.runtime_root;
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
runtime_root = char(java.io.File(char(string(runtime_root))).getCanonicalPath());
expected_runtime = char(java.io.File(constants.runtime_root).getCanonicalPath());
if ~strcmp(runtime_root, expected_runtime)
    error('stage8_k2_mc_run:RuntimeRoot', ...
        'Formal runtime is fixed at %s.', expected_runtime);
end
if ~strcmp(version('-release'), '2022b') || maxNumCompThreads ~= 1
    error('stage8_k2_mc_run:MATLABRuntime', ...
        'Formal execution requires MATLAB R2022b with -singleCompThread.');
end
try
    pool = gcp('nocreate');
catch
    pool = [];
end
if ~isempty(pool)
    error('stage8_k2_mc_run:ParallelPool', ...
        'Formal execution forbids an active parallel pool.');
end
scope = stage8_k2_mc_add_paths(repo_dir); %#ok<NASGU>
preflight = stage8_k2_mc_preflight(repo_dir, constants);
if ~preflight.pass
    error('stage8_k2_mc_run:Preflight', ...
        'STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_INVALID: %s', ...
        preflight.last_error);
end
context = stage8_k2_mc_build_context(repo_dir);
if isfile(runtime_root)
    error('stage8_k2_mc_run:RuntimeFile', ...
        'The fixed runtime root is an existing file.');
elseif isfolder(runtime_root)
    fprintf('Loading the frozen runtime registry and validated tests...\n');
    [registry, test_output] = resume_inputs_local( ...
        runtime_root, context, preflight);
    runtime_state = stage8_k2_mc_registry_prepare( ...
        runtime_root, registry, context);
else
    fprintf('Running ten registered Monte Carlo tests...\n');
    test_output = stage8_k2_mc_run_tests(repo_dir);
    fprintf('Building and scientifically binding the 1680-row registry...\n');
    registry = stage8_k2_mc_build_registry(context);
    runtime_state = stage8_k2_mc_registry_prepare( ...
        runtime_root, registry, context);
    write_formal_state_local(runtime_root, test_output, context, ...
        preflight, runtime_state.registry_hash);
end
registry_hash = runtime_state.registry_hash;
scan = stage8_k2_mc_scan_checkpoints( ...
    runtime_root, registry, context, registry_hash);
fprintf('%s: %d/1680 validated checkpoints; %d remaining.\n', ...
    runtime_state.mode, scan.completed_count, scan.remaining_count);

started_complete = scan.completed_count == constants.trial_count;
progress = progress_from_scan_local(scan, constants);
stage8_k2_mc_status_write(runtime_root, registry, progress, [], ...
    constants, runtime_state.mode);
for index = 1:height(registry)
    if scan.completed_mask(index)
        continue;
    end
    spec = registry(index, :);
    trial_clock = tic;
    [trial, metrics] = stage8_k2_mc_generate_trial(spec, context);
    snr_row = stage8_k2_mc_snr_row(spec, trial, metrics);
    method_rows = stage8_k2_mc_evaluate_trial( ...
        spec, trial, metrics, context);
    trial_runtime_sec = toc(trial_clock);
    [checkpoint, ~] = stage8_k2_mc_checkpoint_write( ...
        runtime_root, spec, trial, snr_row, method_rows, context, ...
        registry_hash, trial_runtime_sec);
    scan.completed_mask(index) = true;
    scan.completed_count = scan.completed_count + 1;
    scan.remaining_count = scan.remaining_count - 1;
    scan.checkpoints{index} = checkpoint;
    scan.runtime_sec(index) = checkpoint.runtime_sec;
    progress = progress_from_scan_local(scan, constants);
    stage8_k2_mc_status_write(runtime_root, registry, progress, spec, ...
        constants, "RUNNING");
    if mod(scan.completed_count, constants.status_stride) == 0 || ...
            scan.completed_count == constants.trial_count
        fprintf(['Monte Carlo %d/1680 complete: %s; median %.3f s; ', ...
            'ETA %.1f s.\n'], scan.completed_count, char(spec.trial_id), ...
            median(progress.runtime_sec(isfinite(progress.runtime_sec))), ...
            median(progress.runtime_sec(isfinite(progress.runtime_sec))) * ...
            scan.remaining_count);
    end
end

merged = stage8_k2_mc_merge( ...
    runtime_root, registry, context, registry_hash);
run_info = struct('runtime_state', runtime_state, ...
    'total_active_runtime_sec', merged.total_active_runtime_sec, ...
    'median_trial_runtime_sec', merged.median_trial_runtime_sec, ...
    'shutdown_anomaly', false);
% Keep R2022b plotting in a fresh process after the long numerical pass.
if ~started_complete
    write_ready_state_local(runtime_root, run_info, context, registry_hash);
    progress = progress_from_scan_local(merged.scan, constants);
    stage8_k2_mc_status_write(runtime_root, registry, progress, [], ...
        constants, "READY_TO_FINALIZE");
    output = struct('status', ...
        'STAGE8_K2_TANGENT_WHITE_SNR_TRIALS_COMPLETE_READY_TO_FINALIZE', ...
        'completed_count', merged.scan.completed_count, ...
        'registry_hash', registry_hash, ...
        'next', 'RERUN_SAME_COMMAND_IN_FRESH_SINGLE_THREAD_MATLAB');
    fprintf(['STAGE8_K2_TANGENT_WHITE_SNR_TRIALS_COMPLETE_', ...
        'READY_TO_FINALIZE\n']);
    return;
end

output = stage8_k2_mc_summarize(merged, context, runtime_root, ...
    test_output, run_info, preflight);
complete_path = fullfile(runtime_root, 'complete_run.mat');
save(complete_path, 'output', 'test_output', 'run_info', ...
    'preflight', '-mat');
progress = progress_from_scan_local(merged.scan, constants);
stage8_k2_mc_status_write(runtime_root, registry, progress, [], ...
    constants, "COMPLETE");
fprintf('STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_COMPLETE\n');
fprintf('%s\n', output.terminal_status);
end

function [registry, test_output] = resume_inputs_local( ...
    runtime_root, context, preflight)
registry_path = fullfile(runtime_root, 'registry', 'registry.mat');
state_path = fullfile(runtime_root, 'formal_execution_state.mat');
if ~isfile(registry_path) || ~isfile(state_path)
    error('stage8_k2_mc_run:ResumeState', ...
        'Existing runtime lacks its frozen registry or formal test state.');
end
loaded_registry = load(registry_path, 'registry', 'registry_hash', '-mat');
loaded_state = load(state_path, 'formal_state', '-mat');
if ~isfield(loaded_state, 'formal_state') || ...
        ~isstruct(loaded_state.formal_state)
    error('stage8_k2_mc_run:FormalStateSchema', ...
        'The formal execution state schema is invalid.');
end
formal_state = loaded_state.formal_state;
required = {'protocol','formal_head','context_hash','code_identity', ...
    'registry_hash','test_output','tests_completed_utc'};
if ~all(isfield(formal_state, required)) || ...
        ~strcmp(formal_state.protocol, context.constants.protocol) || ...
        ~strcmp(formal_state.formal_head, preflight.head) || ...
        ~strcmp(formal_state.context_hash, context.context_hash) || ...
        ~strcmp(formal_state.code_identity, context.code_identity.tree_hash) || ...
        ~strcmp(formal_state.registry_hash, loaded_registry.registry_hash) || ...
        ~strcmp(stage8_k2_mc_stable_hash( ...
        'REGISTRY', loaded_registry.registry), loaded_registry.registry_hash)
    error('stage8_k2_mc_run:FormalStateIdentity', ...
        'The frozen formal test or registry identity is invalid.');
end
test_output = formal_state.test_output;
if ~isstruct(test_output) || ~isfield(test_output, 'pass') || ...
        ~test_output.pass || test_output.test_count ~= 10 || ...
        ~strcmp(test_output.context_hash, context.context_hash) || ...
        ~strcmp(test_output.registry_hash, loaded_registry.registry_hash)
    error('stage8_k2_mc_run:FormalTests', ...
        'Stored formal T1-T10 evidence is invalid.');
end
registry = loaded_registry.registry;
end

function write_formal_state_local( ...
    runtime_root, test_output, context, preflight, registry_hash)
formal_state = struct('protocol', context.constants.protocol, ...
    'formal_head', preflight.head, 'context_hash', context.context_hash, ...
    'code_identity', context.code_identity.tree_hash, ...
    'registry_hash', registry_hash, 'test_output', test_output, ...
    'tests_completed_utc', stage8_k2_mc_utc_now());
path_now = fullfile(runtime_root, 'formal_execution_state.mat');
temporary = [path_now, '.tmp'];
save(temporary, 'formal_state', '-mat');
[ok, message] = movefile(temporary, path_now, 'f');
if ~ok
    error('stage8_k2_mc_run:FormalStateWrite', '%s', message);
end
end

function write_ready_state_local(runtime_root, run_info, context, registry_hash)
ready_state = struct('protocol', context.constants.protocol, ...
    'code_identity', context.code_identity.tree_hash, ...
    'registry_hash', registry_hash, 'checkpoint_count', ...
    context.constants.trial_count, 'total_active_runtime_sec', ...
    run_info.total_active_runtime_sec, 'median_trial_runtime_sec', ...
    run_info.median_trial_runtime_sec, ...
    'ready_utc', stage8_k2_mc_utc_now());
path_now = fullfile(runtime_root, 'ready_to_finalize.mat');
temporary = [path_now, '.tmp'];
save(temporary, 'ready_state', '-mat');
[ok, message] = movefile(temporary, path_now, 'f');
if ~ok
    error('stage8_k2_mc_run:ReadyStateWrite', '%s', message);
end
end

function progress = progress_from_scan_local(scan, constants)
fallback = zeros(1, numel(constants.method_ids));
for index = find(scan.completed_mask).'
    rows = scan.checkpoints{index}.method_rows;
    for method_index = 1:numel(constants.method_ids)
        selected = rows.method_id == constants.method_ids(method_index);
        fallback(method_index) = fallback(method_index) + ...
            nnz(rows.fallback_flag(selected));
    end
end
progress = struct('completed_count', scan.completed_count, ...
    'runtime_sec', scan.runtime_sec, 'fallback_counts', fallback);
end
