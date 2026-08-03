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

fprintf('Running ten registered Monte Carlo tests...\n');
test_output = stage8_k2_mc_run_tests(repo_dir);
context = stage8_k2_mc_build_context(repo_dir);
fprintf('Building and scientifically binding the 1680-row registry...\n');
registry = stage8_k2_mc_build_registry(context);
runtime_state = stage8_k2_mc_registry_prepare( ...
    runtime_root, registry, context);
registry_hash = runtime_state.registry_hash;
scan = stage8_k2_mc_scan_checkpoints( ...
    runtime_root, registry, context, registry_hash);
fprintf('%s: %d/1680 validated checkpoints; %d remaining.\n', ...
    runtime_state.mode, scan.completed_count, scan.remaining_count);

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
