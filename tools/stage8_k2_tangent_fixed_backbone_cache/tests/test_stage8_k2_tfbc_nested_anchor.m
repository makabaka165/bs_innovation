function result = test_stage8_k2_tfbc_nested_anchor(fixture)
%TEST_STAGE8_K2_TFBC_NESTED_ANCHOR Preserve nested anchor/RSS semantics.

pair = stage8_k2_tfbc_test_fixed_fit_pair(fixture, 2);
legacy = pair.legacy_fit.all_start_results(3);
cached = pair.cache_fit.all_start_results(3);
domain = fixture.context.plan.local_domain;
stage8_k2_tfbc_assert_registered_angles(cached.initial_angles_deg, ...
    domain, 'TEST_NESTED_START');
pass = isequaln(stage8_k2_tfbc_strip_runtime(legacy), ...
    stage8_k2_tfbc_strip_runtime(cached));
assert(pass, 'test_stage8_k2_tfbc_nested_anchor:Failed', ...
    'Legacy/cache nested anchor and RSS contracts differ.');
result = struct('pass',pass, ...
    'nested_rss_pass',cached.nested_rss_pass);
end
