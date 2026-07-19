function table_out = test_stage7_1_clean_tree_guard(repo_dir)
%TEST_STAGE7_1_CLEAN_TREE_GUARD Enforce formal clean-tree entry.

base = struct('formal_mode', true, 'unit_test_mode', true, ...
    'runtime_head_commit_override', ...
    '25e063730309dac2595390d46744040ba6fbe4b3', ...
    'baseline_ancestor_flag_override', true, ...
    'untracked_source_paths_override', strings(0, 1));
clean_opts = base;
clean_opts.git_status_porcelain_override = '';
clean = build_stage7_1_code_identity(repo_dir, clean_opts);
dirty_opts = base;
dirty_opts.git_status_porcelain_override = ...
    ' M innovation-mining/16_stage7_exact_subset_fim_audit.md';
dirty_rejected = throws_local(@() ...
    build_stage7_1_code_identity(repo_dir, dirty_opts), ...
    'build_stage7_1_code_identity:DirtyWorktree');

case_id = ["CLEAN_FORMAL_PASS";"DIRTY_FORMAL_REJECTED"; ...
    "BASELINE_ANCESTOR_REQUIRED"];
pass_flag = [clean.working_tree_clean_flag;dirty_rejected; ...
    clean.baseline_ancestor_flag];
table_out = table(case_id, pass_flag);
assert(all(pass_flag), 'test_stage7_1_clean_tree_guard:Failed', ...
    'Formal Stage7.1 clean-tree guard failed.');
end

function flag = throws_local(action, expected_identifier)
flag = false;
try
    action();
catch exception
    flag = strcmp(exception.identifier, expected_identifier);
end
end
