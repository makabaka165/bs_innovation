function output = stage8_k2_wcb_run(repo_dir, runtime_root)
%STAGE8_K2_WCB_RUN Run, resume, or finalize the registered comparison.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_wcb_run:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
constants = stage8_k2_wcb_constants();
if nargin < 2 || isempty(runtime_root)
    runtime_root = constants.runtime_root;
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
runtime_root = char(java.io.File(char(string(runtime_root))).getCanonicalPath());
expected_runtime = char(java.io.File(constants.runtime_root).getCanonicalPath());
if ~strcmp(runtime_root, expected_runtime)
    error('stage8_k2_wcb_run:RuntimeRoot', ...
        'Formal runtime is fixed at %s.', expected_runtime);
end
if ~strcmp(version('-release'), '2022b') || maxNumCompThreads ~= 1
    error('stage8_k2_wcb_run:MATLABRuntime', ...
        'Formal execution requires MATLAB R2022b with -singleCompThread.');
end
try
    pool = gcp('nocreate');
catch
    pool = [];
end
if ~isempty(pool)
    error('stage8_k2_wcb_run:ParallelPool', ...
        'Formal execution forbids an active parallel pool.');
end

scope = stage8_k2_wcb_add_paths(repo_dir); %#ok<NASGU>
preflight = stage8_k2_wcb_preflight(repo_dir, constants);
if ~preflight.pass
    error('stage8_k2_wcb_run:Preflight', ...
        'STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPARISON_INVALID: %s', ...
        preflight.last_error);
end
context = stage8_k2_wcb_build_context(repo_dir);
registry = stage8_k2_wcb_build_registry(context);

if isfile(runtime_root)
    error('stage8_k2_wcb_run:RuntimeFile', ...
        'The fixed runtime root is an existing file.');
elseif isfolder(runtime_root)
    test_output = struct();
else
    fprintf('Running registered T1-T10 tests before formal execution...\n');
    test_output = stage8_k2_wcb_run_tests(repo_dir);
end
runtime_state = stage8_k2_wcb_registry_prepare( ...
    runtime_root, registry, context, test_output, preflight);
test_output = runtime_state.test_output;
registry_hash = runtime_state.registry_hash;
scan = stage8_k2_wcb_scan_checkpoints( ...
    runtime_root, registry, context, registry_hash);
fprintf('%s: %d/1680 validated checkpoints; %d remaining.\n', ...
    runtime_state.mode, scan.completed_count, scan.remaining_count);

progress = progress_from_scan_local(scan);
stage8_k2_wcb_status_write(runtime_root, registry, progress, [], ...
    constants, runtime_state.mode);
ready_path = fullfile(runtime_root, 'ready_to_finalize.mat');
if scan.remaining_count > 0
    fprintf('Preparing the two fixed beamspace MUSIC dictionaries...\n');
    resources = stage8_k2_wcb_prepare_music_resources(context);
    for index = 1:height(registry)
        if scan.completed_mask(index)
            continue;
        end
        spec = registry(index, :);
        trial_clock = tic;
        [trial, ~, identity] = ...
            stage8_k2_wcb_reconstruct_trial(spec, context);
        [rows, ~] = stage8_k2_wcb_evaluate_trial( ...
            spec, trial, context, resources);
        trial_runtime_sec = toc(trial_clock);
        [checkpoint, ~] = stage8_k2_wcb_checkpoint_write( ...
            runtime_root, spec, identity, rows, context, ...
            registry_hash, trial_runtime_sec);
        scan.completed_mask(index) = true;
        scan.completed_count = scan.completed_count + 1;
        scan.remaining_count = scan.remaining_count - 1;
        scan.checkpoints{index} = checkpoint;
        scan.runtime_sec(index) = checkpoint.runtime_sec;
        progress = progress_from_scan_local(scan);
        if mod(scan.completed_count, constants.status_stride) == 0 || ...
                scan.completed_count == constants.trial_count
            stage8_k2_wcb_status_write(runtime_root, registry, progress, ...
                spec, constants, "RUNNING");
            runtime_values = progress.runtime_sec( ...
                isfinite(progress.runtime_sec));
            median_runtime = median(runtime_values);
            fprintf([ ...
                'Classical baselines %d/1680: %s; median %.3f s; ', ...
                'ETA %.1f s; Full4D %d valid/%d incomplete; ', ...
                'MUSIC %d valid/%d single-peak; Element %d.\n'], ...
                scan.completed_count, char(spec.trial_id), ...
                median_runtime, median_runtime * scan.remaining_count, ...
                progress.full4d_valid_count, ...
                progress.full4d_incomplete_count, ...
                progress.music_valid_count, ...
                progress.music_single_peak_count, ...
                progress.element_cml_completed_count);
        end
    end
    clear resources
end

scan = stage8_k2_wcb_scan_checkpoints( ...
    runtime_root, registry, context, registry_hash);
if scan.completed_count ~= constants.trial_count
    error('stage8_k2_wcb_run:IncompleteScan', ...
        'The trial pass returned without all checkpoints.');
end
if ~isfile(ready_path)
    write_ready_state_local(runtime_root, scan, context, registry_hash);
    progress = progress_from_scan_local(scan);
    stage8_k2_wcb_status_write(runtime_root, registry, progress, [], ...
        constants, "READY_TO_FINALIZE");
    output = struct('status', 'READY_TO_FINALIZE', ...
        'completed_count', scan.completed_count, ...
        'registry_hash', registry_hash, ...
        'next', 'RERUN_SAME_COMMAND_IN_FRESH_SINGLE_THREAD_MATLAB');
    fprintf('READY_TO_FINALIZE\n');
    return;
end

ready = load(ready_path, 'ready_state', '-mat');
validate_ready_local(ready.ready_state, context, registry_hash);
merged = stage8_k2_wcb_merge( ...
    runtime_root, registry, context, registry_hash);
output = stage8_k2_wcb_summarize(merged, context, runtime_root, ...
    test_output, runtime_state, preflight);
complete_path = fullfile(runtime_root, 'complete_run.mat');
save(complete_path, 'output', 'test_output', 'preflight', '-mat');
progress = progress_from_scan_local(merged.scan);
stage8_k2_wcb_status_write(runtime_root, registry, progress, [], ...
    constants, "FINALIZED_AWAITING_INDEPENDENT_AUDIT");
fprintf('FINALIZATION_COMPLETE_READY_FOR_INDEPENDENT_AUDIT\n');
end

function progress = progress_from_scan_local(scan)
full4d_valid = 0;
full4d_incomplete = 0;
music_valid = 0;
music_single = 0;
element_completed = 0;
for index = find(scan.completed_mask).'
    rows = scan.checkpoints{index}.baseline_rows;
    beam = rows(rows.method_id == ...
        "FULL4D_BEAMSPACE_CML_MULTISTART", :);
    music = rows(rows.method_id == "BEAMSPACE_MUSIC_K2", :);
    element = rows(rows.method_id == ...
        "FULL4D_ELEMENT_CML_MULTISTART", :);
    full4d_valid = full4d_valid + double(beam.fit_valid);
    full4d_incomplete = full4d_incomplete + ...
        double(beam.numerical_optimization_incomplete_flag);
    music_valid = music_valid + double(music.fit_valid);
    music_single = music_single + double( ...
        music.fit_status == "MUSIC_FEWER_THAN_TWO_PEAKS");
    element_completed = element_completed + double(element.applicable);
end
progress = struct('completed_count', scan.completed_count, ...
    'runtime_sec', scan.runtime_sec, ...
    'full4d_valid_count', full4d_valid, ...
    'full4d_incomplete_count', full4d_incomplete, ...
    'music_valid_count', music_valid, ...
    'music_single_peak_count', music_single, ...
    'element_cml_completed_count', element_completed);
end

function write_ready_state_local(runtime_root, scan, context, registry_hash)
ready_state = struct('protocol', context.constants.protocol, ...
    'code_identity', context.code_identity.tree_hash, ...
    'registry_hash', registry_hash, ...
    'evidence44_identity', context.evidence44.identity, ...
    'checkpoint_count', scan.completed_count, ...
    'total_active_runtime_sec', sum(scan.runtime_sec), ...
    'median_trial_runtime_sec', median(scan.runtime_sec), ...
    'ready_utc', stage8_k2_mc_utc_now());
path_now = fullfile(runtime_root, 'ready_to_finalize.mat');
temporary = [path_now, '.tmp'];
save(temporary, 'ready_state', '-mat');
[ok, message] = movefile(temporary, path_now);
if ~ok
    error('stage8_k2_wcb_run:ReadyMove', '%s', message);
end
end

function validate_ready_local(ready, context, registry_hash)
if ~isstruct(ready) || ...
        ~strcmp(ready.protocol, context.constants.protocol) || ...
        ~strcmp(ready.code_identity, context.code_identity.tree_hash) || ...
        ~strcmp(ready.registry_hash, registry_hash) || ...
        string(ready.evidence44_identity) ~= context.evidence44.identity || ...
        ready.checkpoint_count ~= context.constants.trial_count
    error('stage8_k2_wcb_run:ReadyIdentity', ...
        'The ready-to-finalize marker identity is invalid.');
end
end
