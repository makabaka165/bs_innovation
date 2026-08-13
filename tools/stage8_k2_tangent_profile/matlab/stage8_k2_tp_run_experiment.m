function output = stage8_k2_tp_run_experiment(repo_dir, runtime_root)
%STAGE8_K2_TP_RUN_EXPERIMENT Run one uninterrupted formal 72-trial session.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_tp_run_experiment:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
constants = stage8_k2_tp_constants();
if nargin < 2 || isempty(runtime_root)
    runtime_root = constants.runtime_root;
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
runtime_root = char(java.io.File(char(string(runtime_root))).getCanonicalPath());
expected_runtime = char(java.io.File(constants.runtime_root).getCanonicalPath());
if ~strcmp(runtime_root, expected_runtime)
    error('stage8_k2_tp_run_experiment:RuntimeRoot', ...
        'The formal runtime root is frozen at %s.', expected_runtime);
end
if ~strcmp(version('-release'), '2022b') || maxNumCompThreads ~= 1
    error('stage8_k2_tp_run_experiment:Runtime', ...
        'MATLAB R2022b with -singleCompThread is required.');
end
scope = stage8_k2_tp_add_paths(repo_dir); %#ok<NASGU>
preflight = preflight_local(repo_dir, constants);
if ~preflight.pass
    error('stage8_k2_tp_run_experiment:T0', ...
        'T0_FAIL_STOPPED: %s', preflight.last_error);
end
if isfolder(runtime_root)
    entries = dir(runtime_root);
    entries = entries(~ismember({entries.name}, {'.', '..'}));
    if ~isempty(entries)
        error('stage8_k2_tp_run_experiment:ExistingRuntime', ...
            'Formal runtime root is not empty; delete it before a full restart.');
    end
else
    mkdir(runtime_root);
end
context = stage8_k2_tp_build_context(repo_dir);
registry = stage8_k2_tp_build_registry( ...
    context.plan.local_domain, constants);
method_blocks = cell(constants.trial_count, 1);
diagnostic_blocks = cell(constants.trial_count, 1);
clock = tic;
for index = 1:height(registry)
    fprintf('[%d/%d] %s\n', index, height(registry), ...
        char(registry.trial_id(index)));
    [method_blocks{index}, diagnostic_blocks{index}] = ...
        stage8_k2_tp_evaluate_trial(registry(index, :), context);
    drawnow;
end
method_rows = vertcat(method_blocks{:});
diagnostics = vertcat(diagnostic_blocks{:});
run_runtime_sec = toc(clock);
validate_complete_local(method_rows, diagnostics, registry, constants);
writetable(registry, fullfile(runtime_root, 'registry.csv'));
writetable(method_rows, fullfile(runtime_root, 'method_rows.csv'));
writetable(diagnostics, fullfile(runtime_root, 'tangent_diagnostics.csv'));
save(fullfile(runtime_root, 'complete_run.mat'), 'registry', ...
    'method_rows', 'diagnostics', 'preflight', 'run_runtime_sec', '-mat');
summary = stage8_k2_tp_summarize(method_rows, diagnostics, registry, ...
    repo_dir, runtime_root);
save(fullfile(runtime_root, 'complete_summary.mat'), 'summary', '-mat');
output = struct('status', 'COMPLETE', 'preflight', preflight, ...
    'trial_count', height(registry), 'method_row_count', height(method_rows), ...
    'diagnostic_row_count', height(diagnostics), ...
    'run_runtime_sec', run_runtime_sec, ...
    'conclusion', summary.conclusion, 'overall', summary.overall, ...
    'integrity', summary.integrity, ...
    'runtime_root', runtime_root, ...
    'evidence_paths', summary.evidence_paths);
fprintf('FORMAL_RUN_COMPLETE conclusion=%s runtime=%.3f sec\n', ...
    output.conclusion, output.run_runtime_sec);
end

function audit = preflight_local(repo_dir, constants)
audit = struct('pass', false, 'last_error', '', 'branch', '', ...
    'head', '', 'origin_new', '', 'origin_core_v2', '', ...
    'origin_main', '', 'worktree_clean', false, ...
    'base_is_ancestor', false, 'step12_7_clean', false, ...
    'evidence29_clean', false);
try
    audit.branch = git_output_local(repo_dir, 'branch --show-current');
    audit.head = git_output_local(repo_dir, 'rev-parse HEAD');
    audit.origin_new = git_output_local(repo_dir, ...
        'rev-parse origin/experiment/stage8-k2-tangent-profile-v1');
    audit.origin_core_v2 = git_output_local(repo_dir, ...
        'rev-parse origin/experiment/stage8-core-v2');
    audit.origin_main = git_output_local(repo_dir, 'rev-parse origin/main');
    audit.worktree_clean = isempty(git_output_local(repo_dir, ...
        'status --porcelain=v1 --untracked-files=all'));
    audit.base_is_ancestor = git_status_local(repo_dir, sprintf( ...
        'merge-base --is-ancestor %s HEAD', constants.base_commit));
    audit.step12_7_clean = git_status_local(repo_dir, sprintf( ...
        'diff --quiet %s -- beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement', ...
        constants.base_commit));
    audit.evidence29_clean = git_status_local(repo_dir, sprintf( ...
        'diff --quiet %s -- ":(glob)innovation-mining/29_*"', ...
        constants.base_commit));
    checks = strcmp(audit.branch, constants.branch) && ...
        strcmp(audit.head, audit.origin_new) && ...
        strcmp(audit.origin_core_v2, constants.expected_origin_core_v2) && ...
        strcmp(audit.origin_main, constants.expected_origin_main) && ...
        audit.worktree_clean && audit.base_is_ancestor && ...
        audit.step12_7_clean && audit.evidence29_clean;
    if ~checks
        error('Branch, remote SHA, clean-tree, ancestry, or frozen-path check failed.');
    end
    audit.pass = true;
catch exception
    audit.last_error = exception.message;
end
end

function validate_complete_local(method_rows, diagnostics, registry, constants)
pair_ids = method_rows.trial_id + "|" + method_rows.method_id;
if height(method_rows) ~= constants.method_row_count || ...
        height(diagnostics) ~= constants.trial_count || ...
        numel(unique(pair_ids)) ~= constants.method_row_count || ...
        numel(unique(diagnostics.trial_id)) ~= constants.trial_count
    error('stage8_k2_tp_run_experiment:Cardinality', ...
        'Formal trial or method rows are missing or duplicated.');
end
if any(method_rows.truth_used_in_fit_flag) || ...
        any(diagnostics.truth_used_in_fit_flag)
    error('stage8_k2_tp_run_experiment:TruthLeakage', ...
        'Truth leakage was recorded in a fitting path.');
end
for index = 1:height(registry)
    rows = method_rows(method_rows.trial_id == registry.trial_id(index), :);
    diagnostic = diagnostics(diagnostics.trial_id == ...
        registry.trial_id(index), :);
    if height(rows) ~= 3 || height(diagnostic) ~= 1 || ...
            numel(unique(rows.element_trial_hash)) ~= 1 || ...
            unique(rows.element_trial_hash) ~= diagnostic.element_trial_hash
        error('stage8_k2_tp_run_experiment:ElementPairing', ...
            'Three methods did not share one generated element trial.');
    end
end
end

function output = git_output_local(repo_dir, arguments)
command = sprintf('git -C "%s" %s', repo_dir, arguments);
[status, output] = system(command);
if status ~= 0
    error('stage8_k2_tp_run_experiment:Git', ...
        'Git command failed: %s', command);
end
output = strtrim(output);
end

function pass = git_status_local(repo_dir, arguments)
command = sprintf('git -C "%s" %s', repo_dir, arguments);
[status, ~] = system(command);
pass = status == 0;
end
