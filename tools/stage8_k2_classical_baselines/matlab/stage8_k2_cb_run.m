function output = stage8_k2_cb_run(repo_dir, runtime_root)
%STAGE8_K2_CB_RUN Run smoke then the formal comparison in one MATLAB process.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_cb_run:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
if nargin < 2 || isempty(runtime_root)
    runtime_root = stage8_k2_cb_constants().runtime_root;
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
runtime_root = char(java.io.File(char(string(runtime_root))).getCanonicalPath());
if isfolder(runtime_root) || isfile(runtime_root)
    error('stage8_k2_cb_run:RuntimeExists', ...
        ['Runtime root already exists. Delete this exact uncommitted ', ...
        'comparison runtime before restarting from the beginning.']);
end
if ~mkdir(runtime_root)
    error('stage8_k2_cb_run:RuntimeCreate', ...
        'Unable to create the isolated runtime root.');
end

scope = stage8_k2_cb_add_paths(repo_dir); %#ok<NASGU>
context = stage8_k2_cb_build_context(repo_dir);
registry = stage8_k2_cb_build_registry(context);
fprintf('Preparing fixed MUSIC dictionaries...\n');
resources = stage8_k2_cb_prepare_resources(context);

smoke_selectors = { ...
    "P1", 4, 0, "WHITE"; ...
    "P2", 4, 0, "WHITE"; ...
    "P3", 4, 0, "STAGE5_TOEPLITZ_CORRELATED"; ...
    "P4", 4, 0, "STAGE5_TOEPLITZ_CORRELATED"};
smoke_tables = cell(size(smoke_selectors, 1), 1);
for index = 1:size(smoke_selectors, 1)
    selected = registry.profile_id == smoke_selectors{index, 1} & ...
        registry.L == smoke_selectors{index, 2} & ...
        registry.snr_db == smoke_selectors{index, 3} & ...
        registry.noise_profile_id == smoke_selectors{index, 4};
    spec = registry(selected, :);
    if height(spec) ~= 1
        error('stage8_k2_cb_run:SmokeSelector', ...
            'A smoke selector did not resolve to exactly one trial.');
    end
    trial = stage8_k2_cb_generate_trial(spec, context);
    [smoke_tables{index}, diagnostic] = ...
        stage8_k2_cb_evaluate_trial(spec, trial, context, resources);
    cml = smoke_tables{index}(contains(smoke_tables{index}.method_id, ...
        "FULL4D_"), :);
    music = smoke_tables{index}(contains(smoke_tables{index}.method_id, ...
        "MUSIC"), :);
    if ~trial.element_hash_match_flag || ~all(cml.fit_valid) || ...
            any(~isfinite(cml.loglik)) || ...
            ~all(cml.coarse_candidate_count == 210) || ...
            ~all(music.applicable) || ~diagnostic.truth_isolation_flag
        error('stage8_k2_cb_run:SmokeFailure', ...
            'A registered smoke case failed its non-performance contract.');
    end
    fprintf('Smoke %d/4 PASS: %s\n', index, char(spec.trial_id));
end
smoke_rows = vertcat(smoke_tables{:});
writetable(smoke_rows, fullfile(runtime_root, 'smoke_rows.csv'));

fprintf('Reconstructing all 72 formal trials before fitting...\n');
trials = cell(context.constants.trial_count, 1);
reconstruction = cell(context.constants.trial_count, 1);
for index = 1:height(registry)
    trials{index} = stage8_k2_cb_generate_trial(registry(index, :), context);
    reconstruction{index} = struct('trial_id', registry.trial_id(index), ...
        'element_trial_hash', trials{index}.element_trial_hash, ...
        'expected_element_trial_hash', ...
        context.frozen_trial_identity.element_trial_hash(index), ...
        'hash_match_flag', trials{index}.element_hash_match_flag);
end
reconstruction_table = struct2table(vertcat(reconstruction{:}));
if height(reconstruction_table) ~= context.constants.trial_count || ...
        ~all(reconstruction_table.hash_match_flag)
    error('stage8_k2_cb_run:Reconstruction', ...
        'Formal baseline execution requires 72/72 exact element hashes.');
end
writetable(reconstruction_table, ...
    fullfile(runtime_root, 'trial_reconstruction.csv'));
fprintf('Trial reconstruction PASS: 72/72 exact hashes.\n');

baseline_tables = cell(context.constants.trial_count, 1);
diagnostic_rows = cell(context.constants.trial_count, 1);
for index = 1:height(registry)
    [baseline_tables{index}, diagnostic_rows{index}] = ...
        stage8_k2_cb_evaluate_trial(registry(index, :), trials{index}, ...
        context, resources);
    fprintf('Formal baseline %d/72 complete: %s\n', ...
        index, char(registry.trial_id(index)));
end
baseline_rows = vertcat(baseline_tables{:});
frozen_rows = stage8_k2_cb_frozen_rows(context, registry);
rows = [frozen_rows; baseline_rows];
rows = sortrows(rows, {'global_trial_index','method_id'});
diagnostics = struct2table(vertcat(diagnostic_rows{:}));
writetable(diagnostics, fullfile(runtime_root, 'baseline_diagnostics.csv'));
writetable(rows, fullfile(runtime_root, 'all_method_rows.csv'));
output = stage8_k2_cb_summarize(rows, registry, resources, ...
    repo_dir, runtime_root);
output.smoke_rows = smoke_rows;
output.reconstruction = reconstruction_table;
output.diagnostics = diagnostics;
fprintf('STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_RUNTIME_COMPLETE\n');
end
