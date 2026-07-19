function table_out = test_peak_memory_status_change_fails(repo_dir, result_dir)
%TEST_PEAK_MEMORY_STATUS_CHANGE_FAILS Reject non-ESTIMATE status values.

invalid_status = ["MEASURED";"PASS"];
rejected = false(numel(invalid_status), 1);
for index = 1:numel(invalid_status)
    [comparison, summary] = run_stage7_keypoint_comparison_override( ...
        repo_dir, result_dir, 'peak_memory_estimate', 'status', ...
        invalid_status(index));
    diagnostic = comparison(comparison.comparison_type == ...
        "SCHEMA_DEPENDENT_ESTIMATE_DIAGNOSTIC", :);
    rejected(index) = ~summary.pass_flag && height(diagnostic) == 1 && ...
        ~diagnostic.pass_flag;
end
case_id = "NON_ESTIMATE_STATUS_REJECTED_" + invalid_status;
pass_flag = rejected;
table_out = table(case_id, pass_flag);
assert(all(pass_flag), 'test_peak_memory_status_change_fails:Failed', ...
    'A changed peak-memory status was not rejected.');
end
