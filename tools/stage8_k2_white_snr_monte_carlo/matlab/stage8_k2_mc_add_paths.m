function cleanup = stage8_k2_mc_add_paths(repo_dir)
%STAGE8_K2_MC_ADD_PATHS Scope frozen dependencies and this tool.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_mc_add_paths:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_path = path;
cleanup = onCleanup(@() path(old_path));

snr_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_snr_validation', 'matlab');
if ~isfolder(snr_matlab)
    error('stage8_k2_mc_add_paths:SNRDependency', ...
        'The frozen Stage8 K2 SNR tool is missing.');
end
addpath(snr_matlab);
snr_cleanup = stage8_k2_snr_add_paths(repo_dir);
scoped_path = path;
delete(snr_cleanup);
path(scoped_path);

directories = { ...
    fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_monte_carlo', 'matlab'), ...
    fullfile(repo_dir, 'tools', ...
    'stage8_k2_white_snr_monte_carlo', 'tests')};
for index = 1:numel(directories)
    if ~isfolder(directories{index})
        error('stage8_k2_mc_add_paths:MissingDirectory', ...
            'Required directory is missing: %s', directories{index});
    end
    addpath(directories{index});
end
end
