function identity = build_stage7_1_code_identity(repo_dir)
%BUILD_STAGE7_1_CODE_IDENTITY Hash the current Git blob/mode/path manifest.

if isstring(repo_dir), repo_dir = char(repo_dir); end
if ~(ischar(repo_dir) && isrow(repo_dir) && exist(repo_dir, 'dir') == 7)
    error('build_stage7_1_code_identity:RepoDir', ...
        'repo_dir must identify an existing Git repository.');
end
step_root = ['beamspace_ml_v18/source/stepwise_signal_model/steps/', ...
    'step_12_5_1_stage7_closure_audit'];
[status, output] = system(git_command_local(repo_dir, sprintf( ...
    'ls-files --cached --others --exclude-standard -- "%s"', step_root)));
if status ~= 0
    error('build_stage7_1_code_identity:Enumerate', ...
        'Unable to enumerate Stage7.1 source files: %s', strtrim(output));
end
paths = splitlines(string(regexprep(output, '[\r\n]+$', '')));
paths(paths == "") = [];
paths = paths(endsWith(paths, '.m') | ...
    paths == string([step_root, '/README.md']));
paths = sort(paths);
if isempty(paths) || numel(unique(paths)) ~= numel(paths)
    error('build_stage7_1_code_identity:Scope', ...
        'Stage7.1 code identity scope is empty or contains duplicates.');
end

modes = strings(numel(paths), 1);
blobs = strings(numel(paths), 1);
for index = 1:numel(paths)
    [status, index_text] = system(git_command_local(repo_dir, sprintf( ...
        'ls-files -s -- "%s"', paths(index))));
    if status ~= 0
        error('build_stage7_1_code_identity:Index', ...
            'Unable to read the Git mode for %s.', paths(index));
    end
    token = regexp(strtrim(index_text), ...
        '^([0-9]{6}) [0-9a-fA-F]{40,64} 0\t.+$', 'tokens', 'once');
    if isempty(token)
        modes(index) = "100644";
    else
        modes(index) = string(token{1});
    end
    arguments = sprintf('hash-object --path="%s" -- "%s"', ...
        paths(index), paths(index));
    [status, blob_text] = system(git_command_local(repo_dir, arguments));
    blob = lower(string(strtrim(blob_text)));
    if status ~= 0 || isempty(regexp(char(blob), ...
            '^[0-9a-f]{40,64}$', 'once'))
        error('build_stage7_1_code_identity:Blob', ...
            'Unable to build the Git blob identity for %s.', paths(index));
    end
    blobs(index) = blob;
end

scope_version = "STAGE7_1_WORKTREE_GIT_BLOB_SOURCE_SCOPE_V1";
source_scope = repmat(scope_version, numel(paths), 1);
manifest_order = (1:numel(paths)).';
manifest = table(paths, modes, blobs, source_scope, manifest_order, ...
    'VariableNames', {'relative_path','git_mode','git_blob_hash', ...
    'source_scope','manifest_order'});
tree_hash = hash_manifest_local(manifest);
source_commit = git_output_local(repo_dir, 'rev-parse HEAD');
[status, status_text] = system(git_command_local(repo_dir, sprintf( ...
    'status --porcelain=v1 --untracked-files=all -- "%s"', step_root)));
if status ~= 0
    error('build_stage7_1_code_identity:Status', ...
        'Unable to inspect Stage7.1 working-tree state.');
end
working_tree_clean = isempty(strtrim(status_text));
identity_hash = sha256_text_local(source_commit + "|" + ...
    tree_hash + "|" + scope_version);

identity = struct();
identity.source_commit = char(source_commit);
identity.stage7_1_source_tree_hash = char(tree_hash);
identity.stage7_1_git_blob_tree_hash = char(tree_hash);
identity.stage7_1_code_identity_hash = char(identity_hash);
identity.code_identity_contract_version = 'STAGE7_1_CODE_IDENTITY_V1';
identity.source_scope_version = char(scope_version);
identity.source_file_count = height(manifest);
identity.working_tree_clean_flag = working_tree_clean;
identity.source_commit_role = char(ternary_local(working_tree_clean, ...
    "COMMITTED_SOURCE_COMMIT", ...
    "BASE_COMMIT_FOR_WORKTREE_GIT_BLOB_MANIFEST"));
identity.code_identity_status = char(ternary_local(working_tree_clean, ...
    "COMMITTED_GIT_BLOB_TREE_IDENTITY", ...
    "WORKTREE_GIT_BLOB_TREE_IDENTITY"));
identity.manifest = manifest;
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
