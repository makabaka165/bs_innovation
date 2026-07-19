function result = test_k1_fit_noiseless_single_target()
%TEST_K1_FIT_NOISELESS_SINGLE_TARGET Verify both K1 starts and exact fit.

fixture = build_stage8_synthetic_fixture('K1');
[fit, ~] = fit_local_model_k(fixture.full_data, 1, fixture.domain, ...
    fixture.model, fixture.init_context, struct());
error_deg = max(abs(fit.angles_hat_deg - fixture.target_angles_deg), [], 'all');
pass = fit.estimate_returned_flag && fit.num_start == 2 && ...
    fit.effective_rank == 1 && error_deg == 0;
assert(pass, 'test_k1_fit_noiseless_single_target:Failed', ...
    'The noiseless K1 fixture did not return the registered target.');
result = table(pass, fit.num_start, error_deg, ...
    'VariableNames', {'pass_flag','num_start','maximum_error_deg'});
end
