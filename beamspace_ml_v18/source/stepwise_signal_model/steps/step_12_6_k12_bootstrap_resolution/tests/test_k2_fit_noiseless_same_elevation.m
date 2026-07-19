function result = test_k2_fit_noiseless_same_elevation()
%TEST_K2_FIT_NOISELESS_SAME_ELEVATION Verify the Q1/Kq2 start.

fixture = build_stage8_synthetic_fixture('K2_SAME_ELEVATION');
[fit1, ~] = fit_local_model_k(fixture.full_data, 1, fixture.domain, ...
    fixture.model, fixture.init_context, struct());
context = fixture.init_context;
context.k1_fit = fit1;
[fit2, ~] = fit_local_model_k(fixture.full_data, 2, fixture.domain, ...
    fixture.model, context, struct());
error_deg = max(abs(fit2.angles_hat_deg - fixture.target_angles_deg), [], 'all');
pass = fit2.estimate_returned_flag && fit2.num_start == 3 && ...
    fit2.effective_rank == 2 && error_deg == 0;
assert(pass, 'test_k2_fit_noiseless_same_elevation:Failed', ...
    'The noiseless same-elevation K2 fixture failed.');
result = table(pass, fit2.num_start, error_deg, ...
    'VariableNames', {'pass_flag','num_start','maximum_error_deg'});
end
