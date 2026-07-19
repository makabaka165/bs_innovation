function result = test_real_initialization_context_uses_no_truth()
%TEST_REAL_INITIALIZATION_CONTEXT_USES_NO_TRUTH Scan context and source.

fixture = build_stage8_1a_mini_fixture();
context = build_stage8_initialization_context_from_data( ...
    fixture.full_k1, fixture.model, fixture.domain, ...
    fixture.stage5_locked, fixture.model.noise_factorization, struct());
field_text = lower(strjoin(fieldnames(context), ';'));
source_path = which('build_stage8_initialization_context_from_data');
source_text = lower(fileread(source_path));
pass = ~contains(field_text, 'truth') && ~contains(source_text, 'truth') && ...
    ~context.simulation_metadata_used_flag;
assert(pass, 'test_real_initialization_context_uses_no_truth:Failed', ...
    'Simulation metadata entered the initialization factory.');
result = table(pass, 'VariableNames', {'pass_flag'});
end
