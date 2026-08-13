function cleanup = stage8_k2_wacb_add_paths(repo_dir)
%STAGE8_K2_WACB_ADD_PATHS Scope frozen dependencies and the V2 tool.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_wacb_add_paths:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_path = path;
cleanup = onCleanup(@() path(old_path));

wcb_dir = fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_classical_baselines', 'matlab');
sb_dir = fullfile(repo_dir, 'tools', ...
    'stage8_k2_subspace_baselines', 'matlab');
if ~isfolder(wcb_dir) || ~isfolder(sb_dir)
    error('stage8_k2_wacb_add_paths:FrozenDependency', ...
        'A frozen white-SNR or subspace dependency is missing.');
end
addpath(wcb_dir);
wcb_cleanup = stage8_k2_wcb_add_paths(repo_dir);
scoped = path;
delete(wcb_cleanup);
path(scoped);
addpath(sb_dir);
sb_cleanup = stage8_k2_sb_add_paths(repo_dir);
scoped = path;
delete(sb_cleanup);
path(scoped);

directories = { ...
    fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_all_classical_baselines', 'matlab'), ...
    fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_all_classical_baselines', 'tests'), ...
    fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_all_classical_baselines', 'plotting')};
for index = 1:numel(directories)
    if ~isfolder(directories{index})
        error('stage8_k2_wacb_add_paths:MissingDirectory', ...
            'Required directory is missing: %s', directories{index});
    end
    addpath(directories{index});
end
end
