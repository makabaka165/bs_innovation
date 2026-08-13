function result = test_tangent_direction_noiseless()
%TEST_TANGENT_DIRECTION_NOISELESS Recover the first-order separation axis.

rng_state = rng;
cleanup = onCleanup(@() rng(rng_state)); %#ok<NASGU>
rng(91731, 'twister');
B = randn(9, 2) + 1i * randn(9, 2);
d = [0.37; -0.81];
b = randn(1, 7) + 1i * randn(1, 7);
R = 0.5 * (B * d) * b;
T = real(B' * B);
Ct = real(B' * ((R * R') / size(R, 2)) * B);
direction = stage8_k2_tp_projected_direction(T, Ct);
alignment = abs(direction.direction_hat.' * (d / norm(d)));
assert(direction.valid && alignment >= 1 - 1e-12, ...
    'test_tangent_direction_noiseless:Failed', ...
    'Noiseless direction alignment did not meet the exact contract.');
result = struct('pass', true, 'alignment', alignment, ...
    'status', direction.status);
fprintf('test_tangent_direction_noiseless PASS alignment=%.17g\n', alignment);
end
