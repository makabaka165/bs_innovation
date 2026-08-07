function cleanup = stage8_k2_tcc_add_paths(repo_dir)
%STAGE8_K2_TCC_ADD_PATHS Scope Tangent and TCC MATLAB dependencies.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_tcc_add_paths:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_path = path;

tangent_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_profile', 'matlab');
tcc_matlab = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_canonical_cache', 'matlab');
tcc_tests = fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_canonical_cache', 'tests');
if ~isfolder(tangent_matlab) || ~isfolder(tcc_matlab) || ...
        ~isfolder(tcc_tests)
    error('stage8_k2_tcc_add_paths:MissingDirectory', ...
        'Tangent or TCC directory is missing.');
end

% The existing helper owns the frozen dependency list. Keep its cleanup
% object alive until the returned cleanup runs, then restore the caller path.
addpath(tangent_matlab);
tangent_cleanup = stage8_k2_tp_add_paths(repo_dir);
addpath(tcc_matlab);
addpath(tcc_tests);
cleanup = onCleanup(@() restore_path_local(old_path, tangent_cleanup));
end

function restore_path_local(old_path, tangent_cleanup)
clear tangent_cleanup
path(old_path);
end
