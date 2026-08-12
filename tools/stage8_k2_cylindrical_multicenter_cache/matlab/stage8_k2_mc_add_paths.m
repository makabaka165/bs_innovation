function cleanup = stage8_k2_mc_add_paths(repo_dir)
%STAGE8_K2_MC_ADD_PATHS Scope multicenter-cache dependencies.

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
tfbc_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_fixed_backbone_cache', 'matlab');
if ~isfolder(tfbc_matlab)
    error('stage8_k2_mc_add_paths:MissingDependency', ...
        'The fixed-backbone cache dependency is missing.');
end
addpath(tfbc_matlab);
parent_cleanup = stage8_k2_tfbc_add_paths(repo_dir);
matlab_dir = fullfile(repo_dir, 'tools', ...
    'stage8_k2_cylindrical_multicenter_cache', 'matlab');
tests_dir = fullfile(repo_dir, 'tools', ...
    'stage8_k2_cylindrical_multicenter_cache', 'tests');
if ~isfolder(matlab_dir) || ~isfolder(tests_dir)
    error('stage8_k2_mc_add_paths:MissingDirectory', ...
        'The multicenter tool directories are incomplete.');
end
addpath(matlab_dir);
addpath(tests_dir);
cleanup = onCleanup(@() restore_local(old_path, parent_cleanup));
end

function restore_local(old_path, parent_cleanup)
delete(parent_cleanup);
path(old_path);
end
