function tests = run_stage7_registered_unit_tests(context, step_dir, package_dir)
%RUN_STAGE7_REGISTERED_UNIT_TESTS Execute all 27 mandatory tests.

tests.candidate_pool = test_stage7_candidate_pool_mapping(context);
tests.parent_match = test_stage7_parent_3x3_matches_stage6(context);
tests.subset_count = test_stage7_rectangular_subset_count(context);
tests.selection = test_stage7_selection_matrix(context);
tests.covariance_exact = test_subset_covariance_exactness(context);
tests.covariance_mc = test_subset_covariance_monte_carlo(context);
tests.derivatives = test_element_and_subset_derivatives(context);
tests.sources = test_source_matrix_power_and_correlation(context);
tests.schur = test_effective_fim_vs_schur_complement(context);
tests.vectorized = test_effective_fim_vectorized_reference(context);
tests.permutation = test_fim_target_permutation(context);
tests.coordinates = test_fim_center_difference_coordinate_invariance(context);
tests.output_basis = test_fim_output_basis_invariance(context);
tests.source_scale = test_fim_source_common_scale_invariance(context);
tests.retention = test_relative_fim_retention(context);
tests.data_processing = test_fim_data_processing_inequality(context);
tests.nested = test_fim_nested_subset_monotonicity(context);
tests.parent_ceiling = test_full_parent_retention_ceiling(context);
tests.tangent = test_stage6_subset_tangent_consistency(context);
tests.exact_fixture = test_exact_enumeration_3x3_fixture(context);
tests.greedy_fixture = test_greedy_exchange_against_exact(context);
tests.no_additive = test_stage7_no_additive_fim_assumption(context);
tests.no_model_order = test_stage7_no_model_order_logic(step_dir);
tests.scope = test_stage7_scope_rules(step_dir);
[tests.stage6_frozen, tests.stage6_context] = ...
    verify_stage6_frozen_evidence(package_dir);
[tests.stage5_frozen, tests.stage5_context] = ...
    verify_stage5_frozen_results(package_dir);
[tests.step11_frozen, tests.step11_context] = ...
    verify_step11_frozen_results(package_dir);

names = fieldnames(tests);
row_count = 0;
pass_flag = true;
for index = 1:numel(names)
    value = tests.(names{index});
    if istable(value) && ismember('pass_flag', value.Properties.VariableNames)
        row_count = row_count + height(value);
        pass_flag = pass_flag && all(value.pass_flag);
    end
end
tests.registered_test_row_count = row_count;
tests.all_tests_pass = pass_flag;
end
