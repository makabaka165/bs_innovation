function result = test_classifier_k1()
%TEST_CLASSIFIER_K1 Verify the global-threshold K1 branch.

[fit1, fit2, lrt, threshold, separation, diagnostics] = ...
    build_stage8_classifier_fixture();
lrt.lambda_12 = threshold.q_global;
decision = classify_local_cluster_state(fit1, fit2, lrt, threshold, ...
    separation, diagnostics);
pass = strcmp(decision.state, 'K1');
assert(pass, 'test_classifier_k1:Failed', 'Lambda <= q_global must return K1.');
result = table(pass, string(decision.state), ...
    'VariableNames', {'pass_flag','state'});
end
