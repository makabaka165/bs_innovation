function result = test_lrt_uses_effective_whitening_dimension()
%TEST_LRT_USES_EFFECTIVE_WHITENING_DIMENSION Verify n_C=r_C*L.

[fit1, fit2] = build_stage8_lrt_fixture(3, 4, 12, 8);
[lrt, debug] = nested_dml_likelihood_ratio(fit1, fit2, struct());
expected = 2 * 3 * 4 * log(12 / 8);
pass = lrt.n_complex_observations == 12 && ...
    debug.effective_whitening_dimension == 3 && ...
    abs(lrt.lambda_12 - expected) <= 16 * eps(expected);
assert(pass, 'test_lrt_uses_effective_whitening_dimension:Failed', ...
    'The LRT did not use r_C times L.');
result = table(pass, lrt.n_complex_observations, lrt.lambda_12, ...
    'VariableNames', {'pass_flag','n_complex_observations','lambda_12'});
end
