function cleanup = stage8_k2_snr_add_paths(repo_dir)
%STAGE8_K2_SNR_ADD_PATHS Scope frozen dependencies and this isolated tool.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_snr_add_paths:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_path = path;
cleanup = onCleanup(@() path(old_path));

tp_dir = fullfile(repo_dir, 'tools', 'stage8_k2_tangent_profile', 'matlab');
if ~isfolder(tp_dir)
    error('stage8_k2_snr_add_paths:TangentDependency', ...
        'The frozen Tangent MATLAB directory is missing.');
end
addpath(tp_dir);
tp_cleanup = stage8_k2_tp_add_paths(repo_dir);
scoped_dependency_path = path;
delete(tp_cleanup);
path(scoped_dependency_path);

directories = { ...
    fullfile(repo_dir, 'tools', 'stage8_k2_snr_validation', 'matlab'), ...
    fullfile(repo_dir, 'tools', 'stage8_k2_snr_validation', 'tests')};
for index = 1:numel(directories)
    if ~isfolder(directories{index})
        error('stage8_k2_snr_add_paths:MissingDirectory', ...
            'Required directory is missing: %s', directories{index});
    end
    addpath(directories{index});
end
end
