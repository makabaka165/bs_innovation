function [manifest, tree_hash] = build_stage7_git_blob_manifest( ...
    repo_dir, relative_paths, scope_id, opts)
%BUILD_STAGE7_GIT_BLOB_MANIFEST Resolve tracked stage-0 Git identities.

if nargin < 4 || isempty(opts), opts = struct(); end
if ~(isstruct(opts) && isscalar(opts) && isempty(fieldnames(opts)))
    error('build_stage7_git_blob_manifest:Options', ...
        'No options are currently supported.');
end
repo_dir = validate_repo_local(repo_dir);
paths = normalize_paths_local(relative_paths);
if isstring(scope_id), scope_id = char(scope_id); end
if ~(ischar(scope_id) && isrow(scope_id) && ~isempty(scope_id))
    error('build_stage7_git_blob_manifest:Scope', ...
        'scope_id must be nonempty scalar text.');
end

modes = strings(numel(paths), 1);
blobs = strings(numel(paths), 1);
for index = 1:numel(paths)
    arguments = sprintf('ls-files -s -- "%s"', char(paths(index)));
    [status, output] = system(git_command_local(repo_dir, arguments));
    if status ~= 0
        error('build_stage7_git_blob_manifest:Git', ...
            'git ls-files failed for %s: %s', paths(index), strtrim(output));
    end
    lines = splitlines(string(regexprep(output, '[\r\n]+$', '')));
    lines(lines == "") = [];
    if numel(lines) ~= 1
        error('build_stage7_git_blob_manifest:TrackedPath', ...
            'Path must resolve to one tracked stage-0 entry: %s.', paths(index));
    end
    token = regexp(char(lines(1)), ...
        '^([0-9]{6}) ([0-9a-fA-F]{40,64}) ([0-9]+)\t(.+)$', ...
        'tokens', 'once');
    if isempty(token) || ~strcmp(token{3}, '0')
        error('build_stage7_git_blob_manifest:IndexEntry', ...
            'Path lacks one unconflicted stage-0 entry: %s.', paths(index));
    end
    returned_path = strrep(token{4}, '\', '/');
    if ~strcmp(returned_path, char(paths(index)))
        error('build_stage7_git_blob_manifest:PathMismatch', ...
            'Git returned an unexpected path for %s.', paths(index));
    end
    modes(index) = string(token{1});
    blobs(index) = lower(string(token{2}));
end

manifest = table(paths, modes, blobs, 'VariableNames', ...
    {'relative_path','git_mode','git_blob_hash'});
[manifest, tree_hash] = hash_stage7_git_blob_manifest(manifest, scope_id);
end

function repo_dir = validate_repo_local(repo_dir)
if isstring(repo_dir), repo_dir = char(repo_dir); end
if ~(ischar(repo_dir) && isrow(repo_dir) && exist(repo_dir, 'dir') == 7)
    error('build_stage7_git_blob_manifest:RepoDir', ...
        'repo_dir must identify an existing directory.');
end
end

function paths = normalize_paths_local(relative_paths)
if ischar(relative_paths), relative_paths = string({relative_paths}); end
paths = replace(string(relative_paths(:)), '\', '/');
if isempty(paths) || any(ismissing(paths) | strlength(paths) == 0)
    error('build_stage7_git_blob_manifest:Paths', ...
        'relative_paths must contain nonempty text.');
end
if numel(unique(paths)) ~= numel(paths)
    error('build_stage7_git_blob_manifest:DuplicatePath', ...
        'relative_paths contains a duplicate.');
end
for index = 1:numel(paths)
    text = char(paths(index));
    if startsWith(text, '/') || ...
            ~isempty(regexp(text, '^[A-Za-z]:', 'once')) || ...
            ~isempty(regexp(text, '[\t\r\n"]', 'once')) || ...
            any(strcmp(split(paths(index), '/'), '..'))
        error('build_stage7_git_blob_manifest:Path', ...
            'Only safe repository-relative paths are accepted.');
    end
end
paths = sort(paths);
end

function command = git_command_local(repo_dir, arguments)
if contains(repo_dir, '"') || contains(arguments, newline)
    error('build_stage7_git_blob_manifest:ShellInput', ...
        'Git command inputs contain unsupported characters.');
end
command = sprintf('git -C "%s" %s', repo_dir, arguments);
end
