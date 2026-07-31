function result = test_anchor_parameterization_contract()
%TEST_ANCHOR_PARAMETERIZATION_CONTRACT Verify alpha/t/rho identities.

rng_state = rng;
cleanup = onCleanup(@() rng(rng_state));
rng(6212026, 'twister');
maximum_error = 0;
for index = 1:100
    c0 = -2 + 4 * rand(1, 2);
    axis = randn(1, 2);
    axis = axis / norm(axis);
    t = -0.8 + 1.6 * rand();
    rho = 1e-3 + 0.349 * rand();
    alpha = t + rho / 2;
    x1_anchor = c0 + t * axis;
    x2_anchor = c0 + (t + rho) * axis;
    x1_center = c0 + alpha * axis - rho * axis / 2;
    x2_center = c0 + alpha * axis + rho * axis / 2;
    maximum_error = max([maximum_error, abs(alpha - (t + rho / 2)), ...
        norm(x1_anchor - x1_center), norm(x2_anchor - x2_center)]);
end
assert(maximum_error < 1e-13, ...
    'The anchor and center parameterizations are not identical.');
result = struct('test_name', 'anchor_parameterization_contract', ...
    'pass', true, 'maximum_absolute_error', maximum_error);
end
