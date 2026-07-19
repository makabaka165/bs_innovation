function result = test_paired_rows_not_pooled_as_independent()
%TEST_PAIRED_ROWS_NOT_POOLED_AS_INDEPENDENT Reject a pooled 12,000-row CI.

[trials, K1] = build_stage8_1a_validation_trials();
[summary, ~, paired] = summarize_stage8_k1_validation(trials, K1);
overall = summary(summary.summary_scope == "OVERALL", :);
pass = height(trials) == 12000 && height(overall) == 2 && ...
    all(overall.common_trial_count == 6000) && height(paired) == 6000 && ...
    ~any(summary.common_trial_count == 12000);
assert(pass, 'test_paired_rows_not_pooled_as_independent:Failed', ...
    'Paired method rows were pooled as independent Bernoulli samples.');
result = table(pass, height(trials), height(paired), ...
    'VariableNames', {'pass_flag','method_row_count','paired_trial_count'});
end
