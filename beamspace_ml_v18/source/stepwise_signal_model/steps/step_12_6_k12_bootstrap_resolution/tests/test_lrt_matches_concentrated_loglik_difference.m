function result = test_lrt_matches_concentrated_loglik_difference()
%TEST_LRT_MATCHES_CONCENTRATED_LOGLIK_DIFFERENCE Verify exact equivalence.

[fit1, fit2] = build_stage8_lrt_fixture(5, 3, 20, 11);
[lrt, debug] = nested_dml_likelihood_ratio(fit1, fit2, struct());
error_value = abs(lrt.lambda_12 - debug.lambda_from_loglik_difference);
pass = error_value <= 64 * eps(max(1, abs(lrt.lambda_12)));
assert(pass, 'test_lrt_matches_concentrated_loglik_difference:Failed', ...
    'The RSS-ratio LRT and concentrated log-likelihood difference disagree.');
result = table(pass, error_value, ...
    'VariableNames', {'pass_flag','absolute_error'});
end
