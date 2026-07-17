function provenance = read_stage6_git_provenance( ...
    repo_dir, baseline_commit, opts)
%READ_STAGE6_GIT_PROVENANCE Read runtime Git identity and enforce guards.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
repo_dir = validate_repo_local(repo_dir);
baseline_commit = validate_commit_local(baseline_commit, 'baseline_commit');

[status, repo_root_text] = system(git_command_local( ...
    repo_dir, 'rev-parse --show-toplevel'));
if status ~= 0
    error('read_stage6_git_provenance:GitRepository', ...
        'Unable to resolve the repository root: %s', strtrim(repo_root_text));
end
repo_root = strtrim(repo_root_text);

if isfield(opts, 'runtime_head_commit_override')
    runtime_head_commit = validate_commit_local( ...
        opts.runtime_head_commit_override, 'runtime_head_commit_override');
else
    [status, head_text] = system(git_command_local(repo_root, 'rev-parse HEAD'));
    if status ~= 0
        error('read_stage6_git_provenance:GitHead', ...
            'Unable to read HEAD: %s', strtrim(head_text));
    end
    runtime_head_commit = validate_commit_local(strtrim(head_text), 'HEAD');
end

if isfield(opts, 'baseline_ancestor_flag_override')
    baseline_ancestor_flag = validate_flag_local( ...
        opts.baseline_ancestor_flag_override, 'baseline_ancestor_flag_override');
else
    command = sprintf('merge-base --is-ancestor %s %s', ...
        baseline_commit, runtime_head_commit);
    [status, ancestry_text] = system(git_command_local(repo_root, command));
    if status == 0
        baseline_ancestor_flag = true;
    elseif status == 1
        baseline_ancestor_flag = false;
    else
        error('read_stage6_git_provenance:GitAncestry', ...
            'Unable to evaluate baseline ancestry: %s', strtrim(ancestry_text));
    end
end

if isfield(opts, 'git_status_porcelain_override')
    git_status_porcelain = validate_status_local( ...
        opts.git_status_porcelain_override);
else
    [status, status_text] = system(git_command_local(repo_root, ...
        'status --porcelain=v1 --untracked-files=all'));
    if status ~= 0
        error('read_stage6_git_provenance:GitStatus', ...
            'Unable to inspect the working tree: %s', strtrim(status_text));
    end
    git_status_porcelain = regexprep(status_text, '[\r\n]+$', '');
end
working_tree_clean_flag = is_stage6_git_status_clean(git_status_porcelain);

if ~baseline_ancestor_flag
    provenance_status = 'STAGE6_BASELINE_NOT_ANCESTOR';
elseif ~working_tree_clean_flag
    provenance_status = 'STAGE6_DIRTY_WORKTREE_AT_START';
else
    provenance_status = 'PASS';
end

provenance = struct();
provenance.repo_root = repo_root;
provenance.runtime_head_commit = runtime_head_commit;
provenance.baseline_commit = baseline_commit;
provenance.baseline_ancestor_flag = baseline_ancestor_flag;
provenance.working_tree_clean_flag = working_tree_clean_flag;
provenance.git_status_porcelain = git_status_porcelain;
provenance.phase_factor = opts.phase_factor;
provenance.provenance_status = provenance_status;

if opts.enforce_guards && ~baseline_ancestor_flag
    error(['read_stage6_git_provenance:', provenance_status], ...
        '%s: baseline %s is not an ancestor of HEAD %s.', ...
        provenance_status, baseline_commit, runtime_head_commit);
end
if opts.enforce_guards && ~working_tree_clean_flag
    error(['read_stage6_git_provenance:', provenance_status], ...
        '%s: formal evidence execution requires a clean working tree.', ...
        provenance_status);
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('read_stage6_git_provenance:Options', 'opts must be a scalar struct.');
end
allowed = {'runtime_head_commit_override', ...
    'baseline_ancestor_flag_override','git_status_porcelain_override', ...
    'enforce_guards','phase_factor'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('read_stage6_git_provenance:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'enforce_guards'), opts.enforce_guards = true; end
if ~isfield(opts, 'phase_factor'), opts.phase_factor = 1; end
opts.enforce_guards = validate_flag_local(opts.enforce_guards, 'enforce_guards');
if ~(isnumeric(opts.phase_factor) && isscalar(opts.phase_factor) && ...
        isfinite(opts.phase_factor) && opts.phase_factor == 1)
    error('read_stage6_git_provenance:PhaseFactor', ...
        'Stage 6 provenance requires phase_factor=1.');
end
end

function repo_dir = validate_repo_local(repo_dir)
if isstring(repo_dir), repo_dir = char(repo_dir); end
if ~(ischar(repo_dir) && isrow(repo_dir) && exist(repo_dir, 'dir') == 7)
    error('read_stage6_git_provenance:RepoDir', ...
        'repo_dir must identify an existing directory.');
end
end

function commit = validate_commit_local(commit, name)
if isstring(commit), commit = char(commit); end
if ~(ischar(commit) && isrow(commit) && ...
        ~isempty(regexp(commit, '^[0-9a-fA-F]{40,64}$', 'once')))
    error('read_stage6_git_provenance:Commit', ...
        '%s must be a full hexadecimal Git object id.', name);
end
commit = lower(commit);
end

function flag = validate_flag_local(flag, name)
if ~(islogical(flag) && isscalar(flag))
    error('read_stage6_git_provenance:Flag', '%s must be a logical scalar.', name);
end
end

function status_text = validate_status_local(status_text)
if isstring(status_text)
    if ~isscalar(status_text) || ismissing(status_text)
        error('read_stage6_git_provenance:StatusOverride', ...
            'git_status_porcelain_override must be scalar text.');
    end
    status_text = char(status_text);
end
if ~(ischar(status_text) && (isrow(status_text) || isempty(status_text)))
    error('read_stage6_git_provenance:StatusOverride', ...
        'git_status_porcelain_override must be scalar text.');
end
status_text = regexprep(status_text, '\r\n?', '\n');
status_text = regexprep(status_text, '\n+$', '');
end

function command = git_command_local(repo_dir, arguments)
if contains(repo_dir, '"') || contains(arguments, newline)
    error('read_stage6_git_provenance:ShellInput', ...
        'Git command inputs contain unsupported characters.');
end
command = sprintf('git -C "%s" %s', repo_dir, arguments);
end
