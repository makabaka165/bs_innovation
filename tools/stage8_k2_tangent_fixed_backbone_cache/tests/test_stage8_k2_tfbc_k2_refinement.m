function result = test_stage8_k2_tfbc_k2_refinement(fixture)
%TEST_STAGE8_K2_TFBC_K2_REFINEMENT Compare complete K2 fixed trajectories.

pair = stage8_k2_tfbc_test_fixed_fit_pair(fixture, 2);
left = stage8_k2_tfbc_strip_runtime( ...
    struct('fit',pair.legacy_fit, 'debug',pair.legacy_debug));
right = stage8_k2_tfbc_strip_runtime( ...
    struct('fit',pair.cache_fit, 'debug',pair.cache_debug));
pass = isequaln(left, right);
assert(pass, 'test_stage8_k2_tfbc_k2_refinement:Failed');
result = struct('pass',pass, 'score_calls',pair.cache_fit.num_score_eval, ...
    'svd_calls',pair.cache_fit.num_svd);
end
