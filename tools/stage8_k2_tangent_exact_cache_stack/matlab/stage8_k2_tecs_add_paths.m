function cleanup = stage8_k2_tecs_add_paths(repo_dir)
%STAGE8_K2_TECS_ADD_PATHS Scope exact-cache-stack dependencies.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_tecs_add_paths:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_path = path;
tecs_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_exact_cache_stack', 'matlab');
tecs_tests = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_exact_cache_stack', 'tests');
tcc_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_canonical_cache', 'matlab');
if ~isfolder(tecs_matlab) || ~isfolder(tecs_tests) || ~isfolder(tcc_matlab)
    error('stage8_k2_tecs_add_paths:MissingDirectory', ...
        'TECS/TCC directories are incomplete.');
end
addpath(tcc_matlab);
tcc_cleanup = stage8_k2_tcc_add_paths(repo_dir);
addpath(tecs_matlab);
addpath(tecs_tests);
cleanup = onCleanup(@() restore_local(old_path, tcc_cleanup));
end

function restore_local(old_path, tcc_cleanup)
delete(tcc_cleanup);
path(old_path);
end
