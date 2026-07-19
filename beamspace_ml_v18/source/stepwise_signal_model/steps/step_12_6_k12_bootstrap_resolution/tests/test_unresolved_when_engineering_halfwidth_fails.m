function result = test_unresolved_when_engineering_halfwidth_fails()
%TEST_UNRESOLVED_WHEN_ENGINEERING_HALFWIDTH_FAILS Verify the 0.21-degree gate.

[fit1, fit2, lrt, threshold, separation, diagnostics] = ...
    build_stage8_classifier_fixture();
separation.engineering_halfwidth_pass = false;
decision = classify_local_cluster_state(fit1, fit2, lrt, threshold, ...
    separation, diagnostics);
pass = strcmp(decision.state, 'K2_UNRESOLVED');
assert(pass, 'test_unresolved_when_engineering_halfwidth_fails:Failed', ...
    'Failed engineering half-width must return K2_UNRESOLVED.');
result = table(pass, string(decision.state), ...
    'VariableNames', {'pass_flag','state'});
end
