function identity = build_stage8_code_identity(repo_dir, opts)
%BUILD_STAGE8_CODE_IDENTITY Hash tracked Stage8 source independently of HEAD.

if nargin < 1 || isempty(repo_dir)
    repo_dir = repository_root_local();
end
if nargin < 2 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
step_relative = ['beamspace_ml_v18/source/stepwise_signal_model/steps/', ...
    'step_12_6_k12_bootstrap_resolution'];
[status, output] = system(sprintf( ...
    'git -C "%s" ls-files -- "%s"', repo_dir, step_relative));
if status ~= 0
    error('build_stage8_code_identity:Git', ...
        'Unable to enumerate tracked Stage8 files.');
end
paths = splitlines(string(regexprep(output, '[\r\n]+$', '')));
paths(paths == "") = [];
normalized = replace(paths, "\", "/");
eligible = endsWith(normalized, ".m") | ...
    normalized == string(step_relative) + "/README.md";
excluded = contains(normalized, "/calibration/") | ...
    contains(normalized, "/results/") | contains(normalized, "/figures/");
paths = normalized(eligible & ~excluded);
manifest = stage8_git_blob_manifest(repo_dir, paths);
if isempty(manifest)
    error('build_stage8_code_identity:EmptyScope', ...
        'The Stage8 tracked source scope is empty. Stage files must be staged.');
end
[untracked_source_count, status_text] = ...
    untracked_source_count_local(repo_dir, step_relative);
[clean_status, clean_output] = system(sprintf( ...
    'git -C "%s" status --porcelain=v1 --untracked-files=all', repo_dir));
working_tree_clean = clean_status == 0 && isempty(strtrim(clean_output));
runtime_head = git_scalar_local(repo_dir, 'rev-parse HEAD');
if ~isempty(opts.runtime_head_metadata_override)
    if opts.require_formal_runtime
        error('build_stage8_code_identity:RuntimeOverride', ...
            'Runtime metadata overrides are unavailable in formal execution.');
    end
    runtime_head = opts.runtime_head_metadata_override;
end
baseline_ancestor = system(sprintf( ...
    'git -C "%s" merge-base --is-ancestor %s HEAD', repo_dir, ...
    opts.historical_baseline_commit)) == 0;
source_tree_hash = stage8_stable_hash(manifest);
stable_identity = stage8_stable_hash( ...
    'STAGE8_TRACKED_GIT_BLOB_IDENTITY_V1', source_tree_hash);
if opts.require_formal_runtime && ...
        ~(baseline_ancestor && working_tree_clean && untracked_source_count == 0)
    error('build_stage8_code_identity:FormalRuntime', ...
        'Formal Stage8 execution requires ancestor baseline, clean tree, and no untracked source.');
end
identity = struct('source_manifest', manifest, ...
    'stage8_source_tree_hash', source_tree_hash, ...
    'stage8_stable_code_identity_hash', stable_identity, ...
    'runtime_head_commit', runtime_head, ...
    'historical_baseline_commit', opts.historical_baseline_commit, ...
    'baseline_ancestor_flag', baseline_ancestor, ...
    'working_tree_clean_flag', working_tree_clean, ...
    'untracked_source_count', untracked_source_count, ...
    'git_status_text', status_text, ...
    'identity_contract_version', 'STAGE8_TRACKED_GIT_BLOB_IDENTITY_V1');
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_stage8_code_identity:Options', 'opts must be a scalar struct.');
end
allowed = {'historical_baseline_commit','require_formal_runtime', ...
    'runtime_head_metadata_override'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_stage8_code_identity:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'historical_baseline_commit')
    opts.historical_baseline_commit = ...
        '8899023cd608f53c271b5ca429ad41b17d8e0f22';
end
if ~isfield(opts, 'require_formal_runtime')
    opts.require_formal_runtime = false;
end
if ~isfield(opts, 'runtime_head_metadata_override')
    opts.runtime_head_metadata_override = '';
end
end

function [count, text_out] = untracked_source_count_local(repo_dir, root)
[status, output] = system(sprintf( ...
    'git -C "%s" status --porcelain=v1 --untracked-files=all -- "%s"', ...
    repo_dir, root));
if status ~= 0
    error('build_stage8_code_identity:GitStatus', ...
        'Unable to inspect untracked Stage8 files.');
end
if isempty(strtrim(output))
    count = 0;
    text_out = '';
    return;
end
lines = splitlines(string(regexprep(output, '[\r\n]+$', '')));
lines(lines == "") = [];
is_untracked = startsWith(lines, "?? ");
source_line = endsWith(lower(lines), ".m") | ...
    endsWith(lower(lines), "readme.md");
count = nnz(is_untracked & source_line);
text_out = char(join(lines, newline));
end

function value = git_scalar_local(repo_dir, arguments)
[status, output] = system(sprintf('git -C "%s" %s', repo_dir, arguments));
if status ~= 0
    error('build_stage8_code_identity:GitScalar', ...
        'Git command failed: %s.', arguments);
end
value = strtrim(output);
end

function repo_dir = repository_root_local()
[status, output] = system('git rev-parse --show-toplevel');
if status ~= 0
    error('build_stage8_code_identity:Repository', ...
        'Unable to locate the Git repository root.');
end
repo_dir = strtrim(output);
end
