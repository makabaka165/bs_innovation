function table_out = test_effective_fim_vectorized_reference(~)
%TEST_EFFECTIVE_FIM_VECTORIZED_REFERENCE Compare an explicit kron projector.

rng(712510, 'twister');
G = complex(randn(5, 2), randn(5, 2));
dG = struct('azimuth', complex(randn(5, 2), randn(5, 2)), ...
    'elevation', complex(randn(5, 2), randn(5, 2)));
[S, ~] = construct_deterministic_source_matrix(2, 4, -3, 0.5, pi/3, 'REF');
result = effective_deterministic_fim(G, dG, S, 1, struct());
P = eye(5) - G * pinv(G);
P_large = kron(eye(4), P);
J = complex(zeros(20, 4));
for target_index = 1:2
    J(:, 2 * target_index - 1) = ...
        reshape(dG.azimuth(:, target_index) * S(target_index, :), [], 1);
    J(:, 2 * target_index) = ...
        reshape(dG.elevation(:, target_index) * S(target_index, :), [], 1);
end
reference = 2 * real(J' * P_large * J);
error_value = norm(result.F - reference, 'fro') / norm(reference, 'fro');
table_out = stage7_test_table("EXPLICIT_KRON_FIXTURE", ...
    error_value, 1e-12, error_value <= 1e-12);
end
