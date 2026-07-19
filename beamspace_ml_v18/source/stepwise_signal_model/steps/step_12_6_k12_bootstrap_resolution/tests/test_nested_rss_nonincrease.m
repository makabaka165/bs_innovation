function result = test_nested_rss_nonincrease()
%TEST_NESTED_RSS_NONINCREASE Verify the fitted K2 RSS is nested below K1.

fixture = build_stage8_synthetic_fixture('K2_SAME_ELEVATION');
[fit1, ~] = fit_local_model_k(fixture.full_data, 1, fixture.domain, ...
    fixture.model, fixture.init_context, struct());
context = fixture.init_context;
context.k1_fit = fit1;
[fit2, ~] = fit_local_model_k(fixture.full_data, 2, fixture.domain, ...
    fixture.model, context, struct());
scale = max(abs([fit1.rss,fit2.rss]));
tolerance = 64 * numel(fixture.full_data.Zseq_white) * eps(scale);
pass = fit2.rss <= fit1.rss + tolerance;
assert(pass, 'test_nested_rss_nonincrease:Failed', ...
    'The complete K2 fit increased RSS beyond machine precision.');
result = table(pass, fit1.rss, fit2.rss, tolerance, ...
    'VariableNames', {'pass_flag','rss1','rss2','tolerance'});
end
