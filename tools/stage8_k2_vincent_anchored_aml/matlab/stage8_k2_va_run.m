function output = stage8_k2_va_run(repo_dir, runtime_root)
%STAGE8_K2_VA_RUN Run tests, smoke, and one uninterrupted 72-trial session.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_va_run:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
constants = stage8_k2_va_constants();
if nargin < 2 || isempty(runtime_root)
    runtime_root = constants.runtime_root;
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
runtime_root = char(java.io.File(char(string(runtime_root))).getCanonicalPath());
expected_runtime = char(java.io.File(constants.runtime_root).getCanonicalPath());
if ~strcmp(runtime_root, expected_runtime)
    error('stage8_k2_va_run:RuntimeRoot', ...
        'The formal runtime root is frozen at %s.', expected_runtime);
end
if ~strcmp(version('-release'), '2022b') || maxNumCompThreads ~= 1
    error('stage8_k2_va_run:Runtime', ...
        'MATLAB R2022b with -singleCompThread is required.');
end
if isfolder(runtime_root) || isfile(runtime_root)
    entries = dir(runtime_root);
    entries = entries(~ismember({entries.name}, {'.', '..'}));
    if ~isempty(entries)
        error('stage8_k2_va_run:ExistingRuntime', ...
            'The formal runtime root is not empty; restart from scratch.');
    end
end

scope = stage8_k2_va_add_paths(repo_dir); %#ok<NASGU>
preflight = preflight_local(repo_dir, constants);
if ~preflight.pass
    error('stage8_k2_va_run:Preflight', ...
        'Preflight failed: %s', preflight.last_error);
end

test_records = cell(5, 1);
fprintf('Theory test 1/5: cylindrical derivatives\n');
test_records{1} = test_cylindrical_directional_derivatives();
fprintf('Theory test 2/5: projector expansion\n');
test_records{2} = test_projector_expansion_order();
fprintf('Theory test 3/5: synthetic conditional rho\n');
test_records{3} = test_conditional_rho_synthetic_curve();
fprintf('Theory test 4/5: anchor parameterization\n');
test_records{4} = test_anchor_parameterization_contract();
fprintf('Theory test 5/5: no-truth smoke\n');
test_records{5} = test_one_trial_no_truth_smoke();
theory_tests = test_status_table_local(test_records);
if ~all(theory_tests.pass)
    error('stage8_k2_va_run:TheoryTests', ...
        'At least one theory or smoke test did not pass.');
end

if ~isfolder(runtime_root)
    mkdir(runtime_root);
end
context = stage8_k2_va_build_context(repo_dir);
registry = stage8_k2_va_build_registry( ...
    context.plan.local_domain, constants);
method_blocks = cell(constants.trial_count, 1);
diagnostic_blocks = cell(constants.trial_count, 1);
clock = tic;
for index = 1:height(registry)
    fprintf('[%d/%d] %s\n', index, height(registry), ...
        char(registry.trial_id(index)));
    [method_blocks{index}, diagnostic_blocks{index}] = ...
        stage8_k2_va_evaluate_trial(registry(index, :), context);
    drawnow;
end
method_rows = vertcat(method_blocks{:});
diagnostics = vertcat(diagnostic_blocks{:});
run_runtime_sec = toc(clock);
validate_complete_local(method_rows, diagnostics, registry, constants);
writetable(registry, fullfile(runtime_root, 'registry.csv'));
writetable(method_rows, fullfile(runtime_root, 'method_rows.csv'));
writetable(diagnostics, fullfile(runtime_root, 'anchored_diagnostics.csv'));
save(fullfile(runtime_root, 'complete_run.mat'), 'registry', ...
    'method_rows', 'diagnostics', 'preflight', 'theory_tests', ...
    'test_records', 'run_runtime_sec', '-mat');
summary = stage8_k2_va_summarize(method_rows, diagnostics, registry, ...
    repo_dir, runtime_root, theory_tests, preflight);
save(fullfile(runtime_root, 'complete_summary.mat'), 'summary', '-mat');
output = struct('status', 'COMPLETE', 'preflight', preflight, ...
    'trial_count', height(registry), ...
    'method_row_count', height(method_rows), ...
    'diagnostic_row_count', height(diagnostics), ...
    'run_runtime_sec', run_runtime_sec, ...
    'conclusion', summary.conclusion, 'overall', summary.overall, ...
    'integrity', summary.integrity, 'runtime_root', runtime_root, ...
    'evidence_paths', summary.evidence_paths);
fprintf('STAGE8_K2_VINCENT_ANCHORED_AML_RUNTIME_COMPLETE conclusion=%s\n', ...
    output.conclusion);
end

function table_out = test_status_table_local(records)
rows = cell(numel(records), 1);
for index = 1:numel(records)
    record = records{index};
    if ~(isstruct(record) && isfield(record, 'test_name') && ...
            isfield(record, 'pass') && logical(record.pass))
        error('stage8_k2_va_run:TestRecord', ...
            'A theory test did not return a passing status record.');
    end
    rows{index} = struct('test_name', string(record.test_name), ...
        'pass', logical(record.pass));
end
table_out = struct2table(vertcat(rows{:}));
end

function audit = preflight_local(repo_dir, constants)
audit = struct('pass', false, 'last_error', '', 'branch', '', ...
    'head', '', 'origin_new', '', 'origin_classical', '', ...
    'origin_tangent', '', 'tangent_commit_object', '', ...
    'origin_core_v2', '', 'origin_main', '', ...
    'tracked_worktree_clean', false, 'base_is_ancestor', false, ...
    'frozen_paths_clean', false, 'tangent_remote_available', false);
try
    audit.branch = git_output_local(repo_dir, 'branch --show-current');
    audit.head = git_output_local(repo_dir, 'rev-parse HEAD');
    audit.origin_new = git_output_local(repo_dir, ...
        'rev-parse origin/experiment/stage8-k2-vincent-anchored-aml-v1');
    audit.origin_classical = git_output_local(repo_dir, ...
        'rev-parse origin/experiment/stage8-k2-classical-baselines-v1');
    audit.origin_core_v2 = git_output_local(repo_dir, ...
        'rev-parse origin/experiment/stage8-core-v2');
    audit.origin_main = git_output_local(repo_dir, 'rev-parse origin/main');
    audit.tangent_remote_available = git_status_local(repo_dir, ...
        'rev-parse --verify origin/experiment/stage8-k2-tangent-profile-v1');
    if audit.tangent_remote_available
        audit.origin_tangent = git_output_local(repo_dir, ...
            'rev-parse origin/experiment/stage8-k2-tangent-profile-v1');
    else
        audit.origin_tangent = 'MISSING_REMOTE_REF';
    end
    audit.tangent_commit_object = git_output_local(repo_dir, ...
        ['rev-parse ', constants.expected_origin_tangent]);
    audit.tracked_worktree_clean = git_status_local(repo_dir, ...
        'diff --quiet') && git_status_local(repo_dir, ...
        'diff --cached --quiet');
    audit.base_is_ancestor = git_status_local(repo_dir, sprintf( ...
        'merge-base --is-ancestor %s HEAD', constants.base_commit));
    frozen_paths = { ...
        'beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement', ...
        'tools/stage8_k2_tangent_profile', ...
        'tools/stage8_k2_classical_baselines', ...
        'innovation-mining/31_stage8_k2_tangent_profile_trials.csv', ...
        'innovation-mining/32_stage8_k2_tangent_profile_corrected_diagnostics.csv', ...
        'innovation-mining/33_stage8_k2_classical_baseline_theory_and_protocol.md', ...
        'innovation-mining/34_stage8_k2_classical_baseline_trials.csv'};
    frozen_clean = true;
    for index = 1:numel(frozen_paths)
        frozen_clean = frozen_clean && git_status_local(repo_dir, sprintf( ...
            'diff --quiet %s -- "%s"', constants.base_commit, ...
            frozen_paths{index}));
    end
    audit.frozen_paths_clean = frozen_clean;
    checks = strcmp(audit.branch, constants.branch) && ...
        strcmp(audit.head, audit.origin_new) && ...
        strcmp(audit.origin_classical, constants.expected_origin_classical) && ...
        strcmp(audit.origin_core_v2, constants.expected_origin_core_v2) && ...
        strcmp(audit.origin_main, constants.expected_origin_main) && ...
        strcmp(audit.tangent_commit_object, ...
        constants.expected_origin_tangent) && ...
        audit.tracked_worktree_clean && audit.base_is_ancestor && ...
        audit.frozen_paths_clean;
    if ~checks
        error('Branch, remote SHA, tracked-clean, ancestry, or frozen-path check failed.');
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
    error('stage8_k2_va_run:Cardinality', ...
        'Formal trial, method, or diagnostic rows are missing or duplicated.');
end
if any(method_rows.truth_used_in_fit_flag) || ...
        any(diagnostics.truth_used_in_fit_flag)
    error('stage8_k2_va_run:TruthLeakage', ...
        'Truth leakage was recorded in a fitting path.');
end
for index = 1:height(registry)
    rows = method_rows(method_rows.trial_id == registry.trial_id(index), :);
    diagnostic = diagnostics(diagnostics.trial_id == ...
        registry.trial_id(index), :);
    if height(rows) ~= 4 || height(diagnostic) ~= 1 || ...
            numel(unique(rows.element_trial_hash)) ~= 1 || ...
            unique(rows.element_trial_hash) ~= diagnostic.element_trial_hash
        error('stage8_k2_va_run:ElementPairing', ...
            'Four methods did not share one generated element trial.');
    end
end
end

function output = git_output_local(repo_dir, arguments)
command = sprintf('git -C "%s" %s', repo_dir, arguments);
[status, output] = system(command);
if status ~= 0
    error('stage8_k2_va_run:Git', 'Git command failed: %s', command);
end
output = strtrim(output);
end

function pass = git_status_local(repo_dir, arguments)
command = sprintf('git -C "%s" %s', repo_dir, arguments);
[status, ~] = system(command);
pass = status == 0;
end
