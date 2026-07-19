function result = test_formal_checkpoint_root_must_be_outside_repo()
%TEST_FORMAL_CHECKPOINT_ROOT_MUST_BE_OUTSIDE_REPO Reject repository paths.

[status, repo_dir] = system('git rev-parse --show-toplevel');
assert(status == 0, ...
    'test_formal_checkpoint_root_must_be_outside_repo:Repository', ...
    'Unable to locate repository root.');
repo_dir = strtrim(repo_dir);
inside = fullfile(repo_dir, 'stage8_forbidden_checkpoints');
stage8_assert_error(@() validate_stage8_formal_checkpoint_root( ...
    repo_dir, inside), ...
    ['validate_stage8_formal_checkpoint_root:', ...
    'FORMAL_CHECKPOINT_ROOT_INSIDE_REPOSITORY']);
outside = validate_stage8_formal_checkpoint_root(repo_dir, tempdir);
pass = strlength(string(outside)) > 0;
result = table(pass, 'VariableNames', {'pass_flag'});
end
