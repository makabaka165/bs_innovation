function table_out = test_stage6_measurement_hash_freeze(context, evidence)
%TEST_STAGE6_MEASUREMENT_HASH_FREEZE Verify fixed hashes across candidates.

table_out = evidence.measurement_hash_table;
assert(all(table_out.pass_flag) && numel(unique(table_out.fixed_measurement_hash)) == 5, ...
    'test_stage6_measurement_hash_freeze:Registry', ...
    'Measurement hashes are invalid or not configuration-specific.');
for index = 1:numel(context.models)
    model = context.models{index};
    W_before = model.Wseq;
    C_before = model.Cseq;
    T_before = model.Tseq;
    build_fixed_whitened_sequential_derivatives([7.6, 9.8], model, struct());
    build_fixed_whitened_sequential_derivatives([8.4, 10.2], model, struct());
    assert(strcmp(model.Wseq_hash, stable_stage6_hash(W_before)) && ...
        strcmp(model.Cseq_hash, stable_stage6_hash(C_before)) && ...
        strcmp(model.Tseq_hash, stable_stage6_hash(T_before)), ...
        'test_stage6_measurement_hash_freeze:CandidateMutation', ...
        'A fixed measurement object changed across candidate angles.');
end
end
