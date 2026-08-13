function audit = test_f0_structured_process_preflight_contract(repo_dir)
%TEST_F0_STRUCTURED_PROCESS_PREFLIGHT_CONTRACT Verify structured F0 fields.

candidate_runtime = [tempname, '_stage8_structured_preflight_runtime'];
assert(~isfile(candidate_runtime) && ~isfolder(candidate_runtime));
cleanup = onCleanup(@() cleanup_local(candidate_runtime));
f0 = run_stage8_core_v2_2_final_validation( ...
    repo_dir, candidate_runtime, 'Preflight');
assert(~isfile(candidate_runtime) && ~isfolder(candidate_runtime));
assert(strcmp(f0.process_audit_method, ...
    'STRUCTURED_SNAPSHOT_EXACT_IDENTITY_V1'));
assert(f0.process_snapshot_count > 0);
assert(any(f0.current_lineage_ids == double(feature('getpid'))));
assert(f0.old_runtime_audit.tmp_file_count == 0);
assert(f0.old_runtime_audit.tmp_directory_count == 0);

process_eligible = f0.external_matlab_count == 0 && ...
    f0.mwpython_count == 0 && f0.legacy_orchestrator_count == 0 && ...
    f0.coordinator_count == 0;
if ~process_eligible
    audit = struct('pass', false, ...
        'status', 'SKIP_ENVIRONMENT_NOT_ELIGIBLE', ...
        'runtime_claimed', false, 'f0', f0);
    clear cleanup
    return;
end
if ~f0.pass
    assert(~f0.worktree_clean || ~strcmp(f0.head, f0.origin_head), ...
        'Structured Preflight failed outside the expected dirty Git state.');
    audit = struct('pass', false, ...
        'status', 'SKIP_UNCOMMITTED_CODE_FIX', ...
        'runtime_claimed', false, 'f0', f0);
    clear cleanup
    return;
end
assert(strcmp(f0.status, 'F0_BOUNDARY_AND_ENVIRONMENT_PASS'));
audit = struct('pass', true, ...
    'status', 'F0_STRUCTURED_PROCESS_PREFLIGHT_CONTRACT_PASS', ...
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
