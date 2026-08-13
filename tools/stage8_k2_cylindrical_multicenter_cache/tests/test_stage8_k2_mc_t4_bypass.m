function result = test_stage8_k2_mc_t4_bypass(~, outputs)
%TEST_STAGE8_K2_MC_T4_BYPASS Check finite cache exposure remains zero.
semantics = outputs.semantics;
pass = semantics.t4_cache_query_count == 0 && ...
    all(semantics.semantics.t4_cache_query_count == 0);
assert(pass, 'test_stage8_k2_mc_t4_bypass:Failed');
result = struct('pass',pass,'t4_cache_query_count', ...
    semantics.t4_cache_query_count);
end
