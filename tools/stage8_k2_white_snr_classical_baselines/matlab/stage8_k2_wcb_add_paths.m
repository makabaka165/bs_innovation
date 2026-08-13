function cleanup = stage8_k2_wcb_add_paths(repo_dir)
%STAGE8_K2_WCB_ADD_PATHS Scope frozen dependencies and this tool.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_wcb_add_paths:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_path = path;
cleanup = onCleanup(@() path(old_path));

mc_dir = fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_monte_carlo', 'matlab');
cb_dir = fullfile(repo_dir, 'tools', ...
    'stage8_k2_classical_baselines', 'matlab');
if ~isfolder(mc_dir) || ~isfolder(cb_dir)
    error('stage8_k2_wcb_add_paths:FrozenDependency', ...
        'A frozen Monte Carlo or classical-baseline dependency is missing.');
end
addpath(mc_dir);
mc_cleanup = stage8_k2_mc_add_paths(repo_dir);
scoped_path = path;
delete(mc_cleanup);
path(scoped_path);

addpath(cb_dir);
cb_cleanup = stage8_k2_cb_add_paths(repo_dir);
scoped_path = path;
delete(cb_cleanup);
path(scoped_path);

directories = { ...
    fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_classical_baselines', 'matlab'), ...
    fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_classical_baselines', 'tests')};
for index = 1:numel(directories)
    if ~isfolder(directories{index})
        error('stage8_k2_wcb_add_paths:MissingDirectory', ...
            'Required directory is missing: %s', directories{index});
    end
    addpath(directories{index});
end
end
