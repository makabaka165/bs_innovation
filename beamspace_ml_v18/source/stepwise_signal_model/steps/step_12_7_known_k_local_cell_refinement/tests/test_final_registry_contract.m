function test_final_registry_contract(local_domain)
%TEST_FINAL_REGISTRY_CONTRACT Verify cardinality, seeds, and endpoint bounds.

registry = build_stage8_core_v2_2_final_registry(local_domain);
assert(height(registry) == 144);
assert(nnz(registry.K == 1) == 72 && nnz(registry.K == 2) == 72);
assert(numel(unique(registry.noise_seed)) == 144);
assert(numel(unique(registry.source_seed(registry.K == 2))) == 72);
assert(all(registry.single_cpi_flag));
assert(all(registry.same_range_doppler_cell_flag));
assert(~any(registry.cross_cpi_data_used_flag));
assert(~any(registry.tracking_input_used_flag));
assert(~any(registry.K_estimated_inside_module_flag));
end
