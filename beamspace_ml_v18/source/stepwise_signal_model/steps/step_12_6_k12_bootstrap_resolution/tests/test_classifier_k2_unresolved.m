function result = test_classifier_k2_unresolved()
%TEST_CLASSIFIER_K2_UNRESOLVED Verify zero-inside abstention.

[fit1, fit2, lrt, threshold, separation, diagnostics] = ...
    build_stage8_classifier_fixture();
separation.zero_excluded_flag = false;
decision = classify_local_cluster_state(fit1, fit2, lrt, threshold, ...
    separation, diagnostics);
pass = strcmp(decision.state, 'K2_UNRESOLVED');
assert(pass, 'test_classifier_k2_unresolved:Failed', ...
    'A confidence region containing zero must return K2_UNRESOLVED.');
result = table(pass, string(decision.state), ...
    'VariableNames', {'pass_flag','state'});
end
