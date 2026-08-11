function result = test_stage8_k2_tfbc_static_domain(fixture)
%TEST_STAGE8_K2_TFBC_STATIC_DOMAIN Run 42/462/882 certification.

summary = stage8_k2_tfbc_run_static_certification(fixture);
result = struct('pass',logical(summary.pass), 'summary',summary);
end
