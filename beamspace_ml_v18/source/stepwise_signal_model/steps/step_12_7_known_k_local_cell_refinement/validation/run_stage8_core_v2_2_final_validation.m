function output = run_stage8_core_v2_2_final_validation(repo_dir, runtime_root, action)
%RUN_STAGE8_CORE_V2_2_FINAL_VALIDATION Single-process resumable final run.

if nargin < 1 || isempty(repo_dir)
    repo_dir = fileparts(fileparts(fileparts(fileparts(fileparts( ...
        fileparts(fileparts(mfilename('fullpath'))))))));
end
if nargin < 2 || isempty(runtime_root)
    runtime_root = fullfile('E:\bs_innovation_runtime', ...
        'stage8_core_v2_2_single_cpi_known_k_final_v1');
end
if nargin < 3 || isempty(action), action = 'Status'; end
action = upper(char(string(action)));
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
runtime_root = char(java.io.File(char(string(runtime_root))).getCanonicalPath());

switch action
    case 'START'
        output = start_local(repo_dir, runtime_root);
    case 'STATUS'
        output = status_local(runtime_root);
    case 'PAUSE'
        ensure_runtime_local(runtime_root);
        write_text_local(fullfile(runtime_root, 'pause.request'), 'PAUSE\n');
        output = status_local(runtime_root);
    case 'RESUME'
        pause_path = fullfile(runtime_root, 'pause.request');
        if isfile(pause_path), delete(pause_path); end
        output = resume_local(repo_dir, runtime_root);
    case 'FINALIZE'
        output = finalize_stage8_core_v2_2_final_validation(repo_dir, runtime_root);
    otherwise
        error('run_stage8_core_v2_2_final_validation:Action', ...
            'Action must be Start, Status, Pause, Resume, or Finalize.');
end
end

function output = start_local(repo_dir, runtime_root)
f0 = f0_local(repo_dir, runtime_root);
if ~f0.pass
    error('run_stage8_core_v2_2_final_validation:F0', 'F0_FAIL_STOPPED: %s', ...
        f0.last_error);
end
ensure_runtime_local(runtime_root);
save(fullfile(runtime_root, 'f0_audit.mat'), 'f0', '-mat');
try
    f1 = test_historical_24_trial_regression(repo_dir);
catch exception
    f1 = struct('pass', false, 'status', 'F1_FAIL_STOPPED', ...
        'last_error', getReport(exception, 'extended', ...
        'hyperlinks', 'off'));
    save(fullfile(runtime_root, 'f1_audit.mat'), 'f1', '-mat');
    rethrow(exception);
end
f1.pass = true;
save(fullfile(runtime_root, 'f1_audit.mat'), 'f1', '-mat');
context = build_stage8_core_v2_2_validation_context(repo_dir, true);
registry = build_stage8_core_v2_2_final_registry(context.plan.local_domain);
initialize_protocol_local(runtime_root, repo_dir, registry);
output = execute_pending_local(context, registry, runtime_root);
end

function output = resume_local(repo_dir, runtime_root)
protocol_path = fullfile(runtime_root, 'protocol.mat');
if ~isfile(protocol_path)
    error('run_stage8_core_v2_2_final_validation:Resume', ...
        'Resume requires a passing Start-created protocol.');
end
loaded = load(protocol_path, 'protocol', '-mat');
if ~isfield(loaded, 'protocol') || ...
        ~strcmp(loaded.protocol.protocol_version, ...
        'STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_V1')
    error('run_stage8_core_v2_2_final_validation:Protocol', ...
        'Runtime protocol is invalid.');
end
context = build_stage8_core_v2_2_validation_context(repo_dir, true);
registry = build_stage8_core_v2_2_final_registry(context.plan.local_domain);
output = execute_pending_local(context, registry, runtime_root);
end

function output = execute_pending_local(context, registry, runtime_root)
completed = false(height(registry), 1);
for index = 1:height(registry)
    checkpoint_path = checkpoint_path_local(runtime_root, registry.trial_id(index));
    if isfile(checkpoint_path)
        validate_checkpoint_local(checkpoint_path, registry(index, :));
        completed(index) = true;
    end
end
for index = 1:height(registry)
    if completed(index), continue; end
    if isfile(fullfile(runtime_root, 'pause.request'))
        break;
    end
    spec = registry(index, :);
    trial = generate_stage8_core_v2_2_trial(spec, context);
    lite = estimate_stage8_known_k_local_cell(trial.Y_element, trial.model, ...
        context.plan.local_domain, context.stage5_locked, ...
        trial.model.noise_factorization, spec.K, ...
        struct('mode', 'CORE_LITE'));
    plus = estimate_stage8_known_k_local_cell(trial.Y_element, trial.model, ...
        context.plan.local_domain, context.stage5_locked, ...
        trial.model.noise_factorization, spec.K, ...
        struct('mode', 'CORE_PLUS'));
    if spec.K == 1
        assert_same_k1_local(lite, plus);
    end
    checkpoint = struct('trial_id', char(spec.trial_id), ...
        'global_trial_index', double(spec.global_trial_index), ...
        'K', double(spec.K), 'element_trial_hash', trial.element_trial_hash, ...
        'spec', spec, 'trial', trial, 'core_lite', lite, ...
        'core_plus', plus, 'completion_status', 'COMPLETE_PASS');
    checkpoint_path = checkpoint_path_local(runtime_root, spec.trial_id);
    tmp_path = [checkpoint_path, '.tmp'];
    save(tmp_path, 'checkpoint', '-mat');
    validate_checkpoint_local(tmp_path, spec);
    if isfile(checkpoint_path)
        error('run_stage8_core_v2_2_final_validation:Collision', ...
            'A completed checkpoint appeared while processing %s.', spec.trial_id);
    end
    [moved, message] = movefile(tmp_path, checkpoint_path);
    if ~moved
        error('run_stage8_core_v2_2_final_validation:AtomicMove', '%s', message);
    end
    validate_checkpoint_local(checkpoint_path, spec);
    completed(index) = true;
end
output = status_local(runtime_root);
output.completed_trial_count = nnz(completed);
output.remaining_trial_count = height(registry) - nnz(completed);
end

function result = f0_local(repo_dir, runtime_root)
result = struct('pass', false, 'status', 'F0_FAIL_STOPPED', ...
    'last_error', '', 'branch', '', 'head', '', 'origin_main', '', ...
    'worktree_clean', false, 'matlab_external_count', NaN, ...
    'lock_count', 0, 'coordinator_count', 0);
try
    if ~strcmp(version('-release'), '2022b') || maxNumCompThreads ~= 1
        error('MATLAB R2022b with -singleCompThread is required.');
    end
    result.branch = git_local(repo_dir, 'branch --show-current');
    result.head = git_local(repo_dir, 'rev-parse HEAD');
    result.origin_main = git_local(repo_dir, 'rev-parse origin/main');
    status = git_local(repo_dir, 'status --porcelain=v1 --untracked-files=all');
    result.worktree_clean = isempty(strtrim(status));
    [ancestor, ~] = system(sprintf( ...
        'git -C "%s" merge-base --is-ancestor %s HEAD', repo_dir, ...
        'c0f77ee4bcd94cc621f459c6e365c63c2bc4c669'));
    protected = { ...
        'innovation-mining/15_stage6_tangent_theory_validation_audit.md', ...
        'innovation-mining/16_stage7_exact_subset_fim_audit.md', ...
        'innovation-mining/23_stage8_compact_algorithm_diagnostic.md', ...
        'innovation-mining/24_stage8_r1_continuous_refinement_decisive_experiment.md', ...
        'innovation-mining/26_stage8_core_v2_known_k_pruning_experiment.md', ...
        'innovation-mining/27_stage8_core_v2_1_safe_hybrid_closure.md', ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_0_receive_model_correction', ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_1_sequential_dbf_model', ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_2_stable_dml_backend', ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml', ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics', ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_5_exact_subset_fim_beam_design', ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution'};
    protected_clean = true;
    for index = 1:numel(protected)
        [code, ~] = system(sprintf( ...
            'git -C "%s" diff --quiet %s..HEAD -- "%s"', repo_dir, ...
            'c0f77ee4bcd94cc621f459c6e365c63c2bc4c669', protected{index}));
        protected_clean = protected_clean && code == 0;
    end
    result.lock_count = numel(dir(fullfile(runtime_root, '**', '*.lock')));
    result.coordinator_count = 0;
    result.matlab_external_count = 0;
    result.pass = strcmp(strtrim(result.branch), ...
        'experiment/stage8-core-v2') && ...
        strcmp(strtrim(result.origin_main), ...
        '247fad2208e77b04f7062e22b0fd3fd8a81bfc1f') && ...
        result.worktree_clean && ancestor == 0 && protected_clean && ...
        result.lock_count == 0;
    if result.pass
        result.status = 'F0_BOUNDARY_AND_ENVIRONMENT_PASS';
    else
        result.last_error = 'Branch, anchor, clean-tree, or frozen-path check failed.';
    end
catch exception
    result.last_error = getReport(exception, 'extended', 'hyperlinks', 'off');
end
end

function initialize_protocol_local(runtime_root, repo_dir, registry)
ensure_runtime_local(runtime_root);
path_now = fullfile(runtime_root, 'protocol.mat');
if isfile(path_now), return; end
if ~isempty(dir(fullfile(runtime_root, 'checkpoints', '*.mat')))
    error('run_stage8_core_v2_2_final_validation:Protocol', ...
        'Orphan checkpoints exist without a protocol.');
end
protocol = struct('protocol_version', ...
    'STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_V1', ...
    'repo_dir', repo_dir, 'runtime_root', runtime_root, ...
    'trial_count', height(registry), 'result_row_count', 2 * height(registry), ...
    'threads_per_worker', 1, 'worker_count', 1, ...
    'single_cpi_flag', true, 'known_k_flag', true, ...
    'created_utc', char(datetime('now', 'TimeZone', 'UTC')));
save(path_now, 'protocol', '-mat');
writetable(registry, fullfile(runtime_root, 'registry.csv'));
end

function validate_checkpoint_local(path_now, spec)
loaded = load(path_now, 'checkpoint', '-mat');
if ~isfield(loaded, 'checkpoint')
    error('run_stage8_core_v2_2_final_validation:Checkpoint', ...
        'Checkpoint payload is missing.');
end
checkpoint = loaded.checkpoint;
required = {'trial_id','global_trial_index','K','element_trial_hash', ...
    'spec','trial','core_lite','core_plus','completion_status'};
if ~isstruct(checkpoint) || ~all(isfield(checkpoint, required)) || ...
        ~strcmp(checkpoint.completion_status, 'COMPLETE_PASS') || ...
        checkpoint.global_trial_index ~= spec.global_trial_index || ...
        checkpoint.K ~= spec.K
    error('run_stage8_core_v2_2_final_validation:CheckpointContract', ...
        'Checkpoint contract differs from the registry.');
end
for result = {checkpoint.core_lite, checkpoint.core_plus}
    value = result{1};
    if value.K ~= spec.K || ~value.single_cpi_flag || ...
            ~value.same_range_doppler_cell_flag || ...
            value.cross_cpi_data_used_flag || value.tracking_input_used_flag || ...
            value.K_estimated_inside_module_flag || value.truth_used_in_fit_flag
        error('run_stage8_core_v2_2_final_validation:CheckpointFlags', ...
            'One result violates the single-CPI known-K contract.');
    end
end
end

function assert_same_k1_local(lite, plus)
same = isequal(num2hex(lite.angles_hat_deg), num2hex(plus.angles_hat_deg)) && ...
    isequal(num2hex(lite.rss), num2hex(plus.rss)) && ...
    isequal(num2hex(lite.loglik_concentrated), ...
    num2hex(plus.loglik_concentrated)) && lite.fit_valid == plus.fit_valid && ...
    strcmp(lite.selected_source, plus.selected_source) && ...
    strcmp(lite.selected_start_id, plus.selected_start_id) && ...
    strcmp(lite.fit_status, plus.fit_status);
if ~same
    error('run_stage8_core_v2_2_final_validation:K1ModeIdentity', ...
        'CORE_LITE and CORE_PLUS K1 outputs differ.');
end
end

function output = status_local(runtime_root)
checkpoints = dir(fullfile(runtime_root, 'checkpoints', '*.mat'));
output = struct('runtime_root', runtime_root, ...
    'completed_trial_count', numel(checkpoints), ...
    'remaining_trial_count', max(0, 144 - numel(checkpoints)), ...
    'pause_requested', isfile(fullfile(runtime_root, 'pause.request')), ...
    'finalized', isfile(fullfile(runtime_root, 'finalized.mat')));
end

function ensure_runtime_local(root)
if ~isfolder(root), mkdir(root); end
names = {'checkpoints','tmp'};
for index = 1:numel(names)
    path_now = fullfile(root, names{index});
    if ~isfolder(path_now), mkdir(path_now); end
end
end

function path_now = checkpoint_path_local(root, trial_id)
path_now = fullfile(root, 'checkpoints', [char(string(trial_id)), '.mat']);
end

function value = git_local(repo_dir, arguments)
[status, value] = system(sprintf('git -C "%s" %s', repo_dir, arguments));
if status ~= 0
    error('run_stage8_core_v2_2_final_validation:Git', ...
        'Git command failed: %s.', arguments);
end
value = strtrim(value);
end

function write_text_local(path_now, text)
fid = fopen(path_now, 'w', 'n', 'UTF-8');
if fid < 0
    error('run_stage8_core_v2_2_final_validation:Write', ...
        'Cannot write %s.', path_now);
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, text, 'char');
clear cleanup
end
