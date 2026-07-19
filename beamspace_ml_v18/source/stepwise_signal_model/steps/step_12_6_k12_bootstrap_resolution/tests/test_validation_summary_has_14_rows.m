function result = test_validation_summary_has_14_rows()
%TEST_VALIDATION_SUMMARY_HAS_14_ROWS Check config-by-scope primary key.

[trials, K1] = build_stage8_1a_validation_trials();
summary = summarize_stage8_k1_validation(trials, K1);
keys = summary.measurement_config_id + "__" + summary.summary_scope;
pass = height(summary) == 14 && numel(unique(keys)) == 14;
assert(pass, 'test_validation_summary_has_14_rows:Failed', ...
    'Validation summary must have 2 configs times 7 scopes.');
result = table(pass, height(summary), ...
    'VariableNames', {'pass_flag','summary_row_count'});
end
