function fixture = stage8_k2_tfbc_test_fixture(repo_dir)
%STAGE8_K2_TFBC_TEST_FIXTURE Build one persistent formal fixture.

persistent cached_fixture cached_repo
if nargin < 1 || isempty(repo_dir)
    repo_dir = fileparts(fileparts(fileparts(fileparts( ...
        mfilename('fullpath')))));
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
if isempty(cached_fixture) || ~strcmp(cached_repo, repo_dir)
    cached_fixture = stage8_k2_tfbc_build_fixture( ...
        repo_dir, '', struct('include_trials',true));
    cached_repo = repo_dir;
end
fixture = cached_fixture;
end
