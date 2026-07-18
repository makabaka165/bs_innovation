function table_out = test_subset_covariance_exactness(context)
%TEST_SUBSET_COVARIANCE_EXACTNESS Compare direct and selected covariance.

channels = [7,8,9,12,13,14,17,18,19];
errors = zeros(2, 1);
whitening_errors = zeros(2, 1);
for noise_index = 1:2
    noise = context.noise_models{noise_index};
    model = build_exact_subset_model(context.plan.pool, channels, noise, struct());
    direct = model.W_I' * noise.Rn * model.W_I;
    errors(noise_index) = norm(model.C_I - direct, 'fro') / norm(direct, 'fro');
    whitening_errors(noise_index) = model.whitening_info.whitening_error;
end
metric = [errors; whitening_errors];
threshold = [1e-12;1e-12;1e-8;1e-8];
table_out = stage7_test_table( ...
    ["WHITE_DIRECT";"CORRELATED_DIRECT"; ...
    "WHITE_WHITENING";"CORRELATED_WHITENING"], metric, threshold, ...
    metric <= threshold);
end
