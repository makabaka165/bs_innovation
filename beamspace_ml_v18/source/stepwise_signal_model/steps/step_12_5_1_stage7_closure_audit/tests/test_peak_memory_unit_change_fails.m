function table_out = test_peak_memory_unit_change_fails(repo_dir, result_dir)
%TEST_PEAK_MEMORY_UNIT_CHANGE_FAILS Reject a changed diagnostic unit.

[comparison, summary] = run_stage7_keypoint_comparison_override( ...
    repo_dir, result_dir, 'peak_memory_estimate', 'unit', "kilobyte");
diagnostic = comparison(comparison.comparison_type == ...
    "SCHEMA_DEPENDENT_ESTIMATE_DIAGNOSTIC", :);
case_id = ["UNIT_CHANGE_REJECTED";"DIAGNOSTIC_CONTRACT_FAILS"];
pass_flag = [~summary.pass_flag && summary.failed_comparison_count > 0; ...
    height(diagnostic) == 1 && ~diagnostic.pass_flag];
table_out = table(case_id, pass_flag);
assert(all(pass_flag), 'test_peak_memory_unit_change_fails:Failed', ...
    'A changed peak-memory unit was not rejected.');
end
