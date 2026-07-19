function result = test_element_bootstrap_noise_whitens_to_identity()
%TEST_ELEMENT_BOOTSTRAP_NOISE_WHITENS_TO_IDENTITY Monte Carlo covariance.

fixture = build_stage8_1a_mini_fixture();
model = resolve_stage8_measurement_model(fixture.registry, ...
    'MINI_PRIMARY', 'STAGE5_TOEPLITZ_CORRELATED');
[noise, ~] = generate_stage8_element_noise(model, 20000, 1, 29);
white = model.T_I * (model.W_I' * noise);
covariance = white * white' / size(white, 2);
error_value = norm(covariance - eye(size(covariance)), 'fro') / ...
    norm(eye(size(covariance)), 'fro');
pass = error_value < 0.04;
assert(pass, 'test_element_bootstrap_noise_whitens_to_identity:Failed', ...
    'Element noise does not whiten to identity within Monte Carlo error.');
result = table(pass, error_value, ...
    'VariableNames', {'pass_flag','relative_covariance_error'});
end
