function table_out = test_peak_memory_invalid_value_fails(repo_dir, result_dir)
%TEST_PEAK_MEMORY_INVALID_VALUE_FAILS Reject invalid diagnostic values.

invalid_value = ["NaN";"-1";"not_numeric"];
rejected = false(numel(invalid_value), 1);
for index = 1:numel(invalid_value)
    [comparison, summary] = run_stage7_keypoint_comparison_override( ...
        repo_dir, result_dir, 'peak_memory_estimate', 'value', ...
        invalid_value(index));
    diagnostic = comparison(comparison.comparison_type == ...
        "SCHEMA_DEPENDENT_ESTIMATE_DIAGNOSTIC", :);
    rejected(index) = ~summary.pass_flag && height(diagnostic) == 1 && ...
        ~diagnostic.pass_flag;
end
case_id = ["NAN_REJECTED";"NEGATIVE_REJECTED"; ...
    "NONNUMERIC_REJECTED"];
pass_flag = rejected;
table_out = table(case_id, pass_flag);
assert(all(pass_flag), 'test_peak_memory_invalid_value_fails:Failed', ...
    'An invalid peak-memory value was not rejected.');
end
