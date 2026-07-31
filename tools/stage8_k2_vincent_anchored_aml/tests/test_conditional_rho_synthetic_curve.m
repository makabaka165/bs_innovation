function result = test_conditional_rho_synthetic_curve()
%TEST_CONDITIONAL_RHO_SYNTHETIC_CURVE Validate a noiseless smooth fixture.

rates = [0; 2.0; 5.5; 9.0; 13.0];
h0 = exp(1j * rates * 0);
h1 = 1j * rates .* h0;
h2 = -rates .^ 2 .* h0;
h3 = -1j * rates .^ 3 .* h0;
derivatives = struct('h0', h0, 'h1', h1, 'h2', h2, 'h3', h3);
expansion = stage8_k2_va_projector_expansion(derivatives, 1);
assert(expansion.valid && expansion.B0_rank == 2, ...
    'The synthetic curve did not form a rank-two tangent basis.');
rho_true = 0.04;
h_true = exp(1j * rates * rho_true);
source = [1.0, 0.35; -0.40j, 0.85];
Z = [h0, h_true] * source;
conditional = stage8_k2_va_conditional_rho(expansion, Z * Z', 0.35);
assert(conditional.valid && conditional.q2 < 0, ...
    'The synthetic conditional rho is not valid and concave.');
coarse_interval = 0.05;
rho_error = abs(conditional.rho_AML_deg - rho_true);
assert(rho_error < coarse_interval, ...
    'The synthetic conditional rho error is not below a coarse line interval.');
result = struct('test_name', 'conditional_rho_synthetic_curve', ...
    'pass', true, 'rho_true_deg', rho_true, ...
    'rho_AML_deg', conditional.rho_AML_deg, 'rho_error_deg', rho_error, ...
    'q2', conditional.q2);
end
