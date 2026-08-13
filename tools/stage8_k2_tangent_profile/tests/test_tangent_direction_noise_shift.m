function result = test_tangent_direction_noise_shift()
%TEST_TANGENT_DIRECTION_NOISE_SHIFT Verify Ct + alpha*T invariance.

T = [3.2, 0.45; 0.45, 1.7];
Ct = [2.4, -0.31; -0.31, 0.62];
alpha = 4.75;
first = stage8_k2_tp_projected_direction(T, Ct);
second = stage8_k2_tp_projected_direction(T, Ct + alpha * T);
alignment = abs(first.direction_hat.' * second.direction_hat);
assert(first.valid && second.valid && alignment >= 1 - 1e-12, ...
    'test_tangent_direction_noise_shift:Failed', ...
    'An isotropic generalized-eigenvalue shift changed the direction.');
result = struct('pass', true, 'alignment', alignment, 'alpha', alpha);
fprintf('test_tangent_direction_noise_shift PASS alignment=%.17g\n', alignment);
end
