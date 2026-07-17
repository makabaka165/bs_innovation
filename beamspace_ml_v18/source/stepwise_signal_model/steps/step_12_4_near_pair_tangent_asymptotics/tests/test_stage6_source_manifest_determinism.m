function table_out = test_stage6_source_manifest_determinism()
%TEST_STAGE6_SOURCE_MANIFEST_DETERMINISM Verify Git-identity hash behavior.

paths = ["z/file.m"; "a/README.md"];
modes = ["100644"; "100644"];
blobs = [string(repmat('1', 1, 40)); string(repmat('2', 1, 40))];
base = table(paths, modes, blobs, ["LF"; "CRLF"], ...
    'VariableNames', {'relative_path','git_mode','git_blob_hash', ...
    'working_tree_form'});
[manifest, base_hash] = hash_git_blob_manifest(base, 'TEST_SOURCE_SCOPE_V1');

reordered = base([2, 1], :);
[~, reordered_hash] = hash_git_blob_manifest( ...
    reordered, 'TEST_SOURCE_SCOPE_V1');
alternate_checkout = base;
alternate_checkout.working_tree_form = ["CRLF"; "LF"];
[~, checkout_hash] = hash_git_blob_manifest( ...
    alternate_checkout, 'TEST_SOURCE_SCOPE_V1');
changed = base;
changed.git_blob_hash(1) = string(repmat('3', 1, 40));
[~, changed_hash] = hash_git_blob_manifest(changed, 'TEST_SOURCE_SCOPE_V1');
added = [base; table("m/new.m", "100644", string(repmat('4', 1, 40)), ...
    "LF", 'VariableNames', base.Properties.VariableNames)];
[~, added_hash] = hash_git_blob_manifest(added, 'TEST_SOURCE_SCOPE_V1');
removed = base(1, :);
[~, removed_hash] = hash_git_blob_manifest(removed, 'TEST_SOURCE_SCOPE_V1');

case_id = ["SORTED_MANIFEST"; "ORDER_INVARIANCE"; ...
    "CHECKOUT_EOL_INVARIANCE"; "BLOB_CHANGE_SENSITIVITY"; ...
    "ADD_PATH_SENSITIVITY"; "REMOVE_PATH_SENSITIVITY"];
pass_flag = [issorted(manifest.relative_path); ...
    strcmp(base_hash, reordered_hash); strcmp(base_hash, checkout_hash); ...
    ~strcmp(base_hash, changed_hash); ~strcmp(base_hash, added_hash); ...
    ~strcmp(base_hash, removed_hash)];
table_out = table(case_id, pass_flag);
assert(all(pass_flag), 'test_stage6_source_manifest_determinism:Failed', ...
    'Source manifest determinism contract failed.');
end
