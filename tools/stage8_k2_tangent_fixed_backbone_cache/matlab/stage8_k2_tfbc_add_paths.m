function cleanup = stage8_k2_tfbc_add_paths(repo_dir)
%STAGE8_K2_TFBC_ADD_PATHS Scope fixed-backbone cache dependencies.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_tfbc_add_paths:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_path = path;
tfbc_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_fixed_backbone_cache', 'matlab');
tfbc_tests = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_fixed_backbone_cache', 'tests');
tecs_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_exact_cache_stack', 'matlab');
if ~isfolder(tfbc_matlab) || ~isfolder(tfbc_tests) || ...
        ~isfolder(tecs_matlab)
    error('stage8_k2_tfbc_add_paths:MissingDirectory', ...
        'TFBC or exact-cache-stack directories are incomplete.');
end
addpath(tecs_matlab);
tecs_cleanup = stage8_k2_tecs_add_paths(repo_dir);
addpath(tfbc_matlab);
addpath(tfbc_tests);
cleanup = onCleanup(@() restore_local(old_path, tecs_cleanup));
end

function restore_local(old_path, tecs_cleanup)
delete(tecs_cleanup);
path(old_path);
end
