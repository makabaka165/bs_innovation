function table_out = test_subset_covariance_monte_carlo(context)
%TEST_SUBSET_COVARIANCE_MONTE_CARLO Validate subset output covariance by MC.

rng(712505, 'twister');
channels = [7,8,9,12,13,14,17,18,19];
errors = zeros(2, 1);
Nmc = 100000;
for noise_index = 1:2
    model = build_exact_subset_model(context.plan.pool, channels, ...
        context.noise_models{noise_index}, struct());
    L = chol(model.C_I, 'lower');
    E = complex(randn(numel(channels), Nmc), ...
        randn(numel(channels), Nmc)) / sqrt(2);
    Z = L * E;
    sample = (Z * Z') / Nmc;
    errors(noise_index) = norm(sample - model.C_I, 'fro') / ...
        norm(model.C_I, 'fro');
end
table_out = stage7_test_table(["WHITE_MC";"CORRELATED_MC"], ...
    errors, 0.02, errors <= 0.02);
end
