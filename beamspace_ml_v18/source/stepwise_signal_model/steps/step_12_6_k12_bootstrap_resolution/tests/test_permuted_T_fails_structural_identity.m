function result = test_permuted_T_fails_structural_identity(fixture)
%TEST_PERMUTED_T_FAILS_STRUCTURAL_IDENTITY Reject a Tseq/T_I alias change.

model = fixture.mini.model;
model.Tseq = model.Tseq([2:end,1], :);
evaluation = evaluate_stage8_bootstrap_mean_identity(fixture.fit, model);
pass = ~evaluation.T_alias_pass && ~evaluation.overall_pass && ...
    strcmp(evaluation.failure_status, ...
    'STRUCTURAL_MANIFOLD_IDENTITY_FAILURE');
assert(pass, 'test_permuted_T_fails_structural_identity:Failed', ...
    'A permuted Tseq alias passed the structural contract.');
result = table(pass, evaluation.T_alias_pass, ...
    'VariableNames', {'pass_flag','T_alias_pass'});
end
