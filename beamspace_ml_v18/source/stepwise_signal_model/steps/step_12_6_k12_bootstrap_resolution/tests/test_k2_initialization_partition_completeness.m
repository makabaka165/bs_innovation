function result = test_k2_initialization_partition_completeness()
%TEST_K2_INITIALIZATION_PARTITION_COMPLETENESS Verify the fixed three starts.

fixture = build_stage8_synthetic_fixture('K2_SAME_ELEVATION');
[fit1, ~] = fit_local_model_k(fixture.full_data, 1, fixture.domain, ...
    fixture.model, fixture.init_context, struct());
[starts, debug] = build_k2_initializations(fixture.full_data, ...
    fixture.domain, fixture.model, fixture.init_context, fit1, struct());
expected = ["K2_GROUPED_Q1_KQ2"; ...
    "K2_GROUPED_Q2_KQ1_PLUS_KQ1";"K2_K1_EMBEDDED_NESTED_START"];
actual = string({starts.initialization_id}).';
pass = isequal(actual, expected) && debug.registered_start_count == 3;
assert(pass, 'test_k2_initialization_partition_completeness:Failed', ...
    'The K2 registered start partition changed.');
result = table(pass, debug.registered_start_count, ...
    'VariableNames', {'pass_flag','registered_start_count'});
end
