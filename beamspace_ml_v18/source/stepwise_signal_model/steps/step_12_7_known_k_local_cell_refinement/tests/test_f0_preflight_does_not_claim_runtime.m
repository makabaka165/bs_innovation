function audit = test_f0_preflight_does_not_claim_runtime(repo_dir)
%TEST_F0_PREFLIGHT_DOES_NOT_CLAIM_RUNTIME Keep Preflight read-only.

candidate_runtime = [tempname, '_stage8_f0_preflight_runtime'];
assert(~isfile(candidate_runtime) && ~isfolder(candidate_runtime));
cleanup = onCleanup(@() cleanup_local(candidate_runtime));
f0 = run_stage8_core_v2_2_final_validation( ...
    repo_dir, candidate_runtime, 'Preflight');
assert(~isfile(candidate_runtime) && ~isfolder(candidate_runtime));
assert(~isfile(fullfile(candidate_runtime, 'f0_audit.mat')));
assert(~isfile(fullfile(candidate_runtime, 'protocol.mat')));
assert(~isfolder(fullfile(candidate_runtime, 'checkpoints')));
assert(~isfolder(fullfile(candidate_runtime, 'tmp')));
assert(isfield(f0.old_runtime_audit, 'tmp_file_count') && ...
    f0.old_runtime_audit.tmp_file_count == 0);
assert(isfield(f0.old_runtime_audit, 'tmp_directory_count') && ...
    f0.old_runtime_audit.tmp_directory_count == 0);

if ~f0.pass
    assert(~f0.worktree_clean, ...
        'Preflight failed for a reason other than the expected dirty tree.');
    audit = struct('pass', false, ...
        'status', 'SKIP_ENVIRONMENT_NOT_ELIGIBLE', ...
        'runtime_claimed', false, 'f0', f0);
    clear cleanup
    return;
end
audit = struct('pass', true, ...
    'status', 'F0_PREFLIGHT_DOES_NOT_CLAIM_RUNTIME_PASS', ...
    'runtime_claimed', false, 'f0', f0);
clear cleanup
end

function cleanup_local(path_now)
if isfolder(path_now)
    rmdir(path_now, 's');
elseif isfile(path_now)
    delete(path_now);
end
end
