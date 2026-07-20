function result = test_permuted_W_fails_structural_identity(fixture)
%TEST_PERMUTED_W_FAILS_STRUCTURAL_IDENTITY Reject a Wseq/W_I alias change.

model = fixture.mini.model;
model.Wseq = model.Wseq(:, [2:end,1]);
evaluation = evaluate_stage8_bootstrap_mean_identity(fixture.fit, model);
pass = ~evaluation.W_alias_pass && ~evaluation.overall_pass && ...
    strcmp(evaluation.failure_status, ...
    'STRUCTURAL_MANIFOLD_IDENTITY_FAILURE');
assert(pass, 'test_permuted_W_fails_structural_identity:Failed', ...
    'A permuted Wseq alias passed the structural contract.');
result = table(pass, evaluation.W_alias_pass, ...
    'VariableNames', {'pass_flag','W_alias_pass'});
end
