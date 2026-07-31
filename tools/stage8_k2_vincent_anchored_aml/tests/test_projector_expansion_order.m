function result = test_projector_expansion_order()
%TEST_PROJECTOR_EXPANSION_ORDER Verify O(rho^3) projector behavior.

[status, repo_dir] = system('git rev-parse --show-toplevel');
assert(status == 0, 'Unable to locate the repository root.');
repo_dir = strtrim(repo_dir);
scope = stage8_k2_va_add_paths(repo_dir); %#ok<NASGU>
context = stage8_k2_va_build_context(repo_dir);
model = resolve_stage8_measurement_model( ...
    context.plan.measurement_model_registry, ...
    context.primary_measurement_config_id, 'WHITE');
anchor = [8.10, 10.00];
axis = [cosd(31), sind(31)];
axis = axis / norm(axis);
derivatives = stage8_k2_va_directional_derivatives(anchor, axis, model);
expansion = stage8_k2_va_projector_expansion(derivatives, 1);
assert(expansion.valid && expansion.B0_rank == 2, ...
    'The cylindrical B0 basis is unexpectedly rank deficient.');
assert(norm(expansion.P0 - expansion.P0', 'fro') < 1e-11 && ...
    norm(expansion.P1 - expansion.P1', 'fro') < 1e-11 && ...
    norm(expansion.P2 - expansion.P2', 'fro') < 1e-11, ...
    'Projector expansion matrices are not Hermitian.');
assert(expansion.idempotence_error < 1e-10, ...
    'P0 is not numerically idempotent.');

rho_values = [0.02, 0.01, 0.005];
errors = zeros(size(rho_values));
for index = 1:numel(rho_values)
    rho = rho_values(index);
    [h_rho, ~, info] = build_full_sequential_local_manifold( ...
        anchor + rho * axis, model, struct('rank_multiplier', 1));
    assert(info.rank_Gseq == 1, 'The displaced curve sample is invalid.');
    B_exact = [derivatives.h0, (h_rho - derivatives.h0) / rho];
    P_exact = B_exact * ((B_exact' * B_exact) \ B_exact');
    P_exact = 0.5 * (P_exact + P_exact');
    P_taylor = expansion.P0 + rho * expansion.P1 + rho ^ 2 * expansion.P2;
    errors(index) = norm(P_exact - P_taylor, 'fro') / ...
        max(1, norm(P_exact, 'fro'));
end
ratios = errors(1:2) ./ errors(2:3);
assert(all(isfinite(errors)) && all(isfinite(ratios)) && min(ratios) > 4, ...
    'The projector expansion does not show cubic residual convergence.');
result = struct('test_name', 'projector_expansion_order', 'pass', true, ...
    'B0_rank', expansion.B0_rank, ...
    'P0_idempotence_error', expansion.idempotence_error, ...
    'min_halving_ratio', min(ratios), 'max_halving_ratio', max(ratios));
end
