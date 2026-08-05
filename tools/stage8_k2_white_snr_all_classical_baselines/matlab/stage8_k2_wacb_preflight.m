function audit = stage8_k2_wacb_preflight(repo_dir, constants, allow_results)
%STAGE8_K2_WACB_PREFLIGHT Enforce pushed branch, refs, and frozen paths.

if nargin < 3, allow_results = false; end
audit = struct('pass', false, 'branch', '', 'head', '', ...
    'remote_work', '', 'source_white_classic', '', 'origin_tangent', '', ...
    'origin_main', '', 'origin_research', '', 'old_subspace', '', ...
    'worktree_clean', false, 'frozen_paths_clean', false, 'last_error', '');
try
    audit.branch = git_output_local(repo_dir, 'branch --show-current');
    audit.head = git_output_local(repo_dir, 'rev-parse HEAD');
    audit.remote_work = git_output_local(repo_dir, ...
        'rev-parse origin/work/stage8-k2-white-snr-all-classical-baselines-v1');
    audit.source_white_classic = git_output_local(repo_dir, ...
        'rev-parse origin/work/stage8-k2-white-snr-classical-baselines-v1');
    audit.origin_tangent = git_output_local(repo_dir, ...
        'rev-parse origin/experiment/stage8-k2-tangent');
    audit.origin_main = git_output_local(repo_dir, 'rev-parse origin/main');
    audit.origin_research = git_output_local(repo_dir, ...
        'rev-parse origin/research/stage8-k2-vincent-anchored');
    audit.old_subspace = git_output_local(repo_dir, ...
        'rev-parse origin/work/stage8-k2-subspace-baselines-v1');
    status = git_output_local(repo_dir, ...
        'status --porcelain=v1 --untracked-files=all');
    audit.worktree_clean = status_allowed_local(status, allow_results);
    frozen = {'tools/stage8_k2_tangent_profile', ...
        'tools/stage8_k2_classical_baselines', ...
        'tools/stage8_k2_subspace_baselines', ...
        'tools/stage8_k2_snr_validation', ...
        'tools/stage8_k2_white_snr_monte_carlo', ...
        'tools/stage8_k2_white_snr_classical_baselines', ...
        'beamspace_ml_v18'};
    prefixes = {'31','32','33','34','39','40','41','41A','42','43', ...
        '44','45','46'};
    checks = true(numel(frozen) + numel(prefixes), 1);
    for index = 1:numel(frozen)
        checks(index) = git_status_local(repo_dir, sprintf( ...
            'diff --quiet %s..HEAD -- %s', ...
            constants.source_commit, frozen{index}));
    end
    offset = numel(frozen);
    for index = 1:numel(prefixes)
        checks(offset + index) = git_status_local(repo_dir, sprintf( ...
            'diff --quiet %s..HEAD -- ":(glob)innovation-mining/%s_*"', ...
            constants.source_commit, prefixes{index}));
    end
    audit.frozen_paths_clean = all(checks);
    if ~strcmp(audit.branch, constants.branch) || ...
            ~strcmp(audit.head, audit.remote_work) || ...
            ~strcmp(audit.source_white_classic, ...
            constants.expected_source_white_classic) || ...
            ~strcmp(audit.origin_tangent, constants.expected_origin_tangent) || ...
            ~strcmp(audit.origin_main, constants.expected_origin_main) || ...
            ~strcmp(audit.origin_research, constants.expected_origin_research) || ...
            ~strcmp(audit.old_subspace, constants.expected_old_subspace) || ...
            ~audit.worktree_clean || ~audit.frozen_paths_clean
        error('Branch, remote refs, worktree scope, or frozen paths failed.');
    end
    audit.pass = true;
catch exception
    audit.last_error = exception.message;
end
end

function pass = status_allowed_local(status, allow_results)
status = splitlines(string(status));
status = status(strlength(status) > 0);
if isempty(status)
    pass = true;
    return;
end
if ~allow_results
    pass = false;
    return;
end
pass = true;
for index = 1:numel(status)
    path_now = replace(extractAfter(status(index), 3), '"', '');
    if contains(path_now, ' -> ')
        pieces = split(path_now, ' -> ');
        path_now = pieces(end);
    end
    allowed = startsWith(path_now, "innovation-mining/48_") || ...
        startsWith(path_now, "innovation-mining/figures/48_");
    if ~allowed
        pass = false;
        return;
    end
end
end

function output = git_output_local(repo_dir, arguments)
[status, output] = system(sprintf('git -C "%s" %s', repo_dir, arguments));
if status ~= 0
    error('stage8_k2_wacb_preflight:Git', ...
        'Git command failed: %s', arguments);
end
output = strtrim(output);
end

function pass = git_status_local(repo_dir, arguments)
[status, ~] = system(sprintf('git -C "%s" %s', repo_dir, arguments));
pass = status == 0;
end
