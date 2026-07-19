function result = test_primary_stratum_gate_uses_1000_trials()
%TEST_PRIMARY_STRATUM_GATE_USES_1000_TRIALS Check all six primary strata.

[trials, K1] = build_stage8_1a_validation_trials();
summary = summarize_stage8_k1_validation(trials, K1);
rows = summary(summary.measurement_config_id == ...
    string(K1.primary_measurement_config_id) & ...
    summary.summary_scope ~= "OVERALL", :);
pass = height(rows) == 6 && all(rows.common_trial_count == 1000);
assert(pass, 'test_primary_stratum_gate_uses_1000_trials:Failed', ...
    'Each primary stratum gate must use 1000 common trials.');
result = table(pass, height(rows), min(rows.common_trial_count), ...
    'VariableNames', {'pass_flag','stratum_count','trial_count'});
end
