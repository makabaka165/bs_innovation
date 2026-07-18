function table_out = test_relative_fim_retention(~)
%TEST_RELATIVE_FIM_RETENTION Check a known generalized spectrum.

F_reference = diag([2,3,5,7]);
expected = [0.4;0.6;0.8;0.9];
F_candidate = diag(diag(F_reference) .* expected);
result = relative_fim_retention(F_reference, F_candidate, ...
    struct('expected_rank', 4));
error_value = norm(result.generalized_eigenvalues - sort(expected)) / ...
    norm(expected);
eta_error = abs(result.eta - min(expected));
metric = [error_value;eta_error];
table_out = stage7_test_table(["SPECTRUM";"ETA"], ...
    metric, 1e-14, metric <= 1e-14);
end
