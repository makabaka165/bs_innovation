function result = test_backward_bound_is_dimension_derived(fixture)
%TEST_BACKWARD_BOUND_IS_DIMENSION_DERIVED Recompute gamma from N/B/K.

matches = arrayfun(@(item) item.cell_input.global_cell_index == 151, ...
    fixture.cases);
evaluation = fixture.cases(matches).evaluation;
contract = evaluation.contract;
q = contract.complex_multiply_accumulate_ops_per_inner_term;
u = contract.unit_roundoff;
N = evaluation.element_dimension_N;
B = evaluation.sequential_dimension_B;
K = evaluation.source_dimension_K;
gamma_N = q * N * u / (1 - q * N * u);
gamma_B = q * B * u / (1 - q * B * u);
gamma_K = q * K * u / (1 - q * K * u);
gamma_G = (1 + gamma_N) * (1 + gamma_B) - 1;
gamma_mean = (1 + gamma_K) * (1 + gamma_N) * (1 + gamma_B) - 1;
expected_G_bound = contract.independent_path_count * ...
    gamma_G * evaluation.G_backward_scale;
expected_mean_bound = contract.independent_path_count * ...
    gamma_mean * evaluation.mean_backward_scale;
pass = evaluation.gamma_N == gamma_N && ...
    evaluation.gamma_B == gamma_B && evaluation.gamma_K == gamma_K && ...
    isequal(evaluation.G_backward_bound, expected_G_bound) && ...
    isequal(evaluation.mean_backward_bound, expected_mean_bound) && ...
    numel(unique([gamma_N,gamma_B,gamma_K])) == 3;
assert(pass, 'test_backward_bound_is_dimension_derived:Failed', ...
    'The formal bound is not exactly derived from q, u, and N/B/K.');
result = table(pass, N, B, K, gamma_N, gamma_B, gamma_K, ...
    'VariableNames', {'pass_flag','N','B','K','gamma_N','gamma_B','gamma_K'});
end
