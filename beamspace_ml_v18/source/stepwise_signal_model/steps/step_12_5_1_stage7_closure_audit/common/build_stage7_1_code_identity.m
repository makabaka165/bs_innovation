function identity = build_stage7_1_code_identity(repo_dir, opts)
%BUILD_STAGE7_1_CODE_IDENTITY Build stable tracked-source identity.

if nargin < 2 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
repo_dir = validate_repo_local(repo_dir);
step_root = ['beamspace_ml_v18/source/stepwise_signal_model/steps/', ...
    'step_12_5_1_stage7_closure_audit'];
historical_baseline_commit = ...
    '25e063730309dac2595390d46744040ba6fbe4b3';

runtime_head_commit = runtime_head_local(repo_dir, opts);
baseline_ancestor_flag = ancestor_flag_local(repo_dir, ...
    historical_baseline_commit, runtime_head_commit, opts);
git_status_porcelain = status_porcelain_local(repo_dir, opts);
working_tree_clean_flag = isempty(strtrim(git_status_porcelain));
untracked_source_paths = untracked_source_paths_local( ...
    repo_dir, step_root, opts);

if isfield(opts, 'source_manifest_override')
    manifest = normalize_manifest_local(opts.source_manifest_override);
else
    paths = tracked_source_paths_local(repo_dir, step_root);
    manifest = tracked_manifest_local(repo_dir, paths);
end
source_scope_version = ...
    "STAGE7_1_TRACKED_GIT_BLOB_SOURCE_SCOPE_V2";
code_identity_contract_version = ...
    "STAGE7_1_STABLE_CODE_IDENTITY_V2";
manifest.source_scope = repmat(source_scope_version, height(manifest), 1);
manifest.manifest_order = (1:height(manifest)).';
stage7_1_source_tree_hash = hash_manifest_local(manifest);
stage7_1_stable_code_identity_hash = sha256_text_local( ...
    stage7_1_source_tree_hash + "|" + source_scope_version + "|" + ...
    code_identity_contract_version);

if opts.formal_mode && ~isempty(untracked_source_paths)
    error('build_stage7_1_code_identity:UntrackedSource', ...
        'Formal execution rejects untracked Stage7.1 source files.');
end
if opts.formal_mode && ~baseline_ancestor_flag
    error('build_stage7_1_code_identity:BaselineNotAncestor', ...
        'The historical Stage7.1 baseline is not an ancestor of runtime HEAD.');
end
if opts.formal_mode && ~working_tree_clean_flag
    error('build_stage7_1_code_identity:DirtyWorktree', ...
        'Formal Stage7.1 execution requires a clean working tree.');
end

identity = struct();
identity.historical_baseline_commit = historical_baseline_commit;
identity.runtime_head_commit = runtime_head_commit;
identity.baseline_ancestor_flag = baseline_ancestor_flag;
identity.working_tree_clean_flag = working_tree_clean_flag;
identity.git_status_porcelain = git_status_porcelain;
identity.untracked_source_paths = untracked_source_paths;
identity.untracked_source_count = numel(untracked_source_paths);
identity.stage7_1_source_tree_hash = char(stage7_1_source_tree_hash);
identity.stage7_1_git_blob_tree_hash = char(stage7_1_source_tree_hash);
identity.stage7_1_stable_code_identity_hash = ...
    char(stage7_1_stable_code_identity_hash);
identity.stage7_1_code_identity_hash = ...
    char(stage7_1_stable_code_identity_hash);
identity.code_identity_contract_version = ...
    char(code_identity_contract_version);
identity.source_scope_version = char(source_scope_version);
identity.source_file_count = height(manifest);
identity.formal_mode = opts.formal_mode;
identity.code_identity_status = char(ternary_local(opts.formal_mode, ...
    "FORMAL_TRACKED_SOURCE_IDENTITY_PASS", ...
    "DIAGNOSTIC_TRACKED_SOURCE_IDENTITY"));
identity.runtime_head_role = 'RUNTIME_METADATA_ONLY';
identity.source_commit = runtime_head_commit;
identity.source_commit_role = 'RUNTIME_METADATA_ONLY';
identity.manifest = manifest;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_stage7_1_code_identity:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'formal_mode','unit_test_mode','runtime_head_commit_override', ...
    'baseline_ancestor_flag_override','git_status_porcelain_override', ...
    'untracked_source_paths_override','source_manifest_override'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_stage7_1_code_identity:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'formal_mode'), opts.formal_mode = false; end
if ~isfield(opts, 'unit_test_mode'), opts.unit_test_mode = false; end
if ~(islogical(opts.formal_mode) && isscalar(opts.formal_mode) && ...
        islogical(opts.unit_test_mode) && isscalar(opts.unit_test_mode))
    error('build_stage7_1_code_identity:OptionValue', ...
        'formal_mode and unit_test_mode must be logical scalars.');
end
override_fields = setdiff(fieldnames(opts), ...
    {'formal_mode','unit_test_mode'});
if ~opts.unit_test_mode && ~isempty(override_fields)
    error('build_stage7_1_code_identity:TestOverride', ...
        'Identity overrides are restricted to explicit unit-test mode.');
end
end

function repo_dir = validate_repo_local(repo_dir)
if isstring(repo_dir), repo_dir = char(repo_dir); end
if ~(ischar(repo_dir) && isrow(repo_dir) && exist(repo_dir, 'dir') == 7)
    error('build_stage7_1_code_identity:RepoDir', ...
        'repo_dir must identify an existing Git repository.');
end
[status, output] = system(git_command_local( ...
    repo_dir, 'rev-parse --show-toplevel'));
if status ~= 0
    error('build_stage7_1_code_identity:GitRepository', ...
        'Unable to resolve the Git repository: %s', strtrim(output));
end
repo_dir = char(java.io.File(strtrim(output)).getCanonicalPath());
end

function commit = runtime_head_local(repo_dir, opts)
if isfield(opts, 'runtime_head_commit_override')
    commit = validate_commit_local(opts.runtime_head_commit_override);
else
    commit = validate_commit_local(git_output_local(repo_dir, 'rev-parse HEAD'));
end
end

function flag = ancestor_flag_local(repo_dir, baseline, runtime_head, opts)
if isfield(opts, 'baseline_ancestor_flag_override')
    flag = opts.baseline_ancestor_flag_override;
    if ~(islogical(flag) && isscalar(flag))
        error('build_stage7_1_code_identity:AncestorOverride', ...
            'baseline_ancestor_flag_override must be a logical scalar.');
    end
    return;
end
[status, output] = system(git_command_local(repo_dir, sprintf( ...
    'merge-base --is-ancestor %s %s', baseline, runtime_head)));
if status == 0
    flag = true;
elseif status == 1
    flag = false;
else
    error('build_stage7_1_code_identity:GitAncestry', ...
        'Unable to evaluate baseline ancestry: %s', strtrim(output));
end
end

function status_text = status_porcelain_local(repo_dir, opts)
if isfield(opts, 'git_status_porcelain_override')
    status_text = scalar_text_local(opts.git_status_porcelain_override, ...
        'git_status_porcelain_override');
else
    [status, status_text] = system(git_command_local(repo_dir, ...
        'status --porcelain=v1 --untracked-files=all'));
    if status ~= 0
        error('build_stage7_1_code_identity:GitStatus', ...
            'Unable to inspect the working tree.');
    end
end
status_text = regexprep(status_text, '\r\n?', '\n');
status_text = regexprep(status_text, '\n+$', '');
end

function paths = untracked_source_paths_local(repo_dir, step_root, opts)
if isfield(opts, 'untracked_source_paths_override')
    paths = string(opts.untracked_source_paths_override(:));
else
    [status, output] = system(git_command_local(repo_dir, sprintf( ...
        'ls-files --others --exclude-standard -- "%s"', step_root)));
    if status ~= 0
        error('build_stage7_1_code_identity:UntrackedEnumerate', ...
            'Unable to enumerate untracked Stage7.1 source files.');
    end
    paths = splitlines(string(regexprep(output, '[\r\n]+$', '')));
end
paths(paths == "") = [];
paths = normalize_paths_local(paths);
paths = paths(untracked_source_path_mask_local(paths, step_root));
paths = sort(paths);
end

function paths = tracked_source_paths_local(repo_dir, step_root)
[status, output] = system(git_command_local(repo_dir, sprintf( ...
    'ls-files -- "%s"', step_root)));
if status ~= 0
    error('build_stage7_1_code_identity:Enumerate', ...
        'Unable to enumerate tracked Stage7.1 source files.');
end
paths = splitlines(string(regexprep(output, '[\r\n]+$', '')));
paths(paths == "") = [];
paths = normalize_paths_local(paths);
paths = paths(source_path_mask_local(paths, step_root));
paths = sort(paths);
if isempty(paths) || ...
        ~any(paths == string([step_root, '/README.md']))
    error('build_stage7_1_code_identity:SourceScope', ...
        'Tracked Stage7.1 source scope is empty or lacks the stable README.');
end
end

function mask = source_path_mask_local(paths, step_root)
root = string(step_root) + "/";
mask = startsWith(paths, root) & ...
    ~contains(paths, root + "results/") & ...
    ~contains(paths, root + "figures/") & ...
    (endsWith(paths, '.m') | paths == root + "README.md");
end

function mask = untracked_source_path_mask_local(paths, step_root)
root = string(step_root) + "/";
mask = startsWith(paths, root) & (endsWith(paths, '.m') | ...
    endsWith(lower(paths), '/readme.md'));
end

function manifest = tracked_manifest_local(repo_dir, paths)
modes = strings(numel(paths), 1);
blobs = strings(numel(paths), 1);
for index = 1:numel(paths)
    [status, output] = system(git_command_local(repo_dir, sprintf( ...
        'ls-files -s -- "%s"', paths(index))));
    token = regexp(strtrim(output), ...
        '^([0-9]{6}) ([0-9a-fA-F]{40,64}) 0\t(.+)$', ...
        'tokens', 'once');
    if status ~= 0 || isempty(token) || ...
            string(strrep(token{3}, '\', '/')) ~= paths(index)
        error('build_stage7_1_code_identity:TrackedSource', ...
            'Source path is not one tracked stage-0 Git entry: %s.', ...
            paths(index));
    end
    modes(index) = string(token{1});
    blobs(index) = lower(string(token{2}));
end
manifest = table(paths, modes, blobs, 'VariableNames', ...
    {'relative_path','git_mode','git_blob_hash'});
manifest = normalize_manifest_local(manifest);
end

function manifest = normalize_manifest_local(manifest)
required = {'relative_path','git_mode','git_blob_hash'};
if ~(istable(manifest) && all(ismember(required, ...
        manifest.Properties.VariableNames)))
    error('build_stage7_1_code_identity:Manifest', ...
        'source_manifest_override has an invalid schema.');
end
paths = normalize_paths_local(string(manifest.relative_path));
modes = string(manifest.git_mode);
blobs = lower(string(manifest.git_blob_hash));
if isempty(paths) || numel(unique(paths)) ~= numel(paths) || ...
        any(ismissing(modes) | ismissing(blobs))
    error('build_stage7_1_code_identity:ManifestValues', ...
        'Source manifest identity values must be unique and nonmissing.');
end
for index = 1:numel(paths)
    if isempty(regexp(char(modes(index)), '^[0-9]{6}$', 'once')) || ...
            isempty(regexp(char(blobs(index)), ...
            '^[0-9a-f]{40,64}$', 'once'))
        error('build_stage7_1_code_identity:ManifestIdentity', ...
            'Source manifest contains an invalid Git mode or blob.');
    end
end
[paths, order] = sort(paths);
manifest = table(paths, modes(order), blobs(order), 'VariableNames', ...
    {'relative_path','git_mode','git_blob_hash'});
end

function paths = normalize_paths_local(paths)
paths = replace(string(paths(:)), '\', '/');
for index = 1:numel(paths)
    value = char(paths(index));
    if ismissing(paths(index)) || strlength(paths(index)) == 0 || ...
            startsWith(value, '/') || ...
            ~isempty(regexp(value, '^[A-Za-z]:', 'once')) || ...
            ~isempty(regexp(value, '[\t\r\n"]', 'once')) || ...
            any(split(paths(index), '/') == "..")
        error('build_stage7_1_code_identity:Path', ...
            'Source paths must be safe repository-relative paths.');
    end
end
end

function commit = validate_commit_local(commit)
commit = lower(string(commit));
if ~isscalar(commit) || ismissing(commit) || ...
        isempty(regexp(char(commit), '^[0-9a-f]{40,64}$', 'once'))
    error('build_stage7_1_code_identity:Commit', ...
        'Runtime HEAD must be a full hexadecimal Git object id.');
end
commit = char(commit);
end

function text_value = scalar_text_local(value, name)
if isstring(value)
    if ~isscalar(value) || ismissing(value)
        error('build_stage7_1_code_identity:Text', ...
            '%s must be scalar text.', name);
    end
    value = char(value);
end
if ~(ischar(value) && (isrow(value) || isempty(value)))
    error('build_stage7_1_code_identity:Text', ...
        '%s must be scalar text.', name);
end
text_value = value;
end

function digest = hash_manifest_local(manifest)
payload = uint8([]);
for index = 1:height(manifest)
    payload = [payload, utf8_local(manifest.git_mode(index)), uint8(0), ...
        utf8_local(manifest.git_blob_hash(index)), uint8(0), ...
        utf8_local(manifest.relative_path(index)), uint8(0)]; %#ok<AGROW>
end
digest = sha256_bytes_local(payload);
end

function output = git_output_local(repo_dir, arguments)
[status, output] = system(git_command_local(repo_dir, arguments));
if status ~= 0
    error('build_stage7_1_code_identity:Git', ...
        'Git command failed: %s.', arguments);
end
output = string(strtrim(output));
end

function command = git_command_local(repo_dir, arguments)
if contains(repo_dir, '"') || contains(arguments, newline)
    error('build_stage7_1_code_identity:ShellInput', ...
        'Git command inputs contain unsupported characters.');
end
command = sprintf('git -C "%s" %s', repo_dir, arguments);
end

function bytes = utf8_local(value)
bytes = uint8(unicode2native(char(value), 'UTF-8'));
end

function digest = sha256_text_local(value)
digest = sha256_bytes_local(utf8_local(value));
end

function digest = sha256_bytes_local(payload)
sha = System.Security.Cryptography.SHA256.Create();
cleanup = onCleanup(@() sha.Dispose());
bytes = uint8(sha.ComputeHash(payload));
digest = lower(string(reshape(dec2hex(bytes, 2).', 1, [])));
clear cleanup
end

function value = ternary_local(condition, yes_value, no_value)
if condition, value = yes_value; else, value = no_value; end
end
