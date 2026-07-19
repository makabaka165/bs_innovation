function table_out = test_stage7_1_manifest_no_self_reference(repo_dir)
%TEST_STAGE7_1_MANIFEST_NO_SELF_REFERENCE Verify bundle exclusions.

root = tempname;
mkdir(root);
cleanup = onCleanup(@() remove_temp_local(root));
bundle = build_stage7_1_writer_fixture(repo_dir);
[~, manifest, evidence] = write_stage7_1_results_bundle( ...
    fullfile(root, 'results'), bundle, struct('unit_test_mode', true));
self = manifest.artifact_id == "stage7_1_evidence_manifest";
runtime = manifest.contains_runtime_metadata;

case_id = ["ONE_MANIFEST_ROW";"SELF_HASH_EXCLUDED"; ...
    "SELF_NOT_IN_BUNDLE";"RUNTIME_NOT_IN_BUNDLE"; ...
    "DETERMINISTIC_COUNT_13";"BUNDLE_PASS"];
pass_flag = [nnz(self) == 1; ...
    manifest.sha256(self) == "SELF_REFERENTIAL_EXCLUSION"; ...
    ~manifest.included_in_deterministic_bundle(self); ...
    all(~manifest.included_in_deterministic_bundle(runtime)); ...
    evidence.deterministic_artifact_count == 13;evidence.pass_flag];
table_out = table(case_id, pass_flag);
assert(all(pass_flag), ...
    'test_stage7_1_manifest_no_self_reference:Failed', ...
    'The Stage7.1 evidence manifest contains self/runtime references.');
clear cleanup
end

function remove_temp_local(path_now)
if exist(path_now, 'dir') == 7, rmdir(path_now, 's'); end
end
