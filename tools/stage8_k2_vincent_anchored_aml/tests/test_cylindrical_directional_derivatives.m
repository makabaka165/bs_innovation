function result = test_cylindrical_directional_derivatives()
%TEST_CYLINDRICAL_DIRECTIONAL_DERIVATIVES Verify degree-coordinate O(delta^4).

[status, repo_dir] = system('git rev-parse --show-toplevel');
assert(status == 0, 'Unable to locate the repository root.');
repo_dir = strtrim(repo_dir);
scope = stage8_k2_va_add_paths(repo_dir); %#ok<NASGU>
context = stage8_k2_va_build_context(repo_dir);
model = resolve_stage8_measurement_model( ...
    context.plan.measurement_model_registry, ...
    context.primary_measurement_config_id, 'WHITE');
points = [7.80, 9.90; 8.10, 10.00; 8.40, 10.10];
directions = [1, 0; cosd(37), sind(37); cosd(128), sind(128)];
deltas = [0.02, 0.01, 0.005];
ratios = zeros(size(points, 1), size(directions, 1), 2);
maximum_h0_error = 0;
for point_index = 1:size(points, 1)
    for direction_index = 1:size(directions, 1)
        axis = directions(direction_index, :);
        axis = axis / norm(axis);
        derivatives = stage8_k2_va_directional_derivatives( ...
            points(point_index, :), axis, model);
        [g0, ~, info0] = build_full_sequential_local_manifold( ...
            points(point_index, :), model, struct('rank_multiplier', 1));
        assert(info0.rank_Gseq == 1, 'The reference one-column manifold failed.');
        h0_error = norm(derivatives.h0 - g0, 'fro') / max(1, norm(g0, 'fro'));
        maximum_h0_error = max(maximum_h0_error, h0_error);
        residuals = zeros(size(deltas));
        for delta_index = 1:numel(deltas)
            delta = deltas(delta_index);
            [g, ~, info] = build_full_sequential_local_manifold( ...
                points(point_index, :) + delta * axis, model, ...
                struct('rank_multiplier', 1));
            assert(info.rank_Gseq == 1, 'The Taylor evaluation manifold failed.');
            approximation = derivatives.h0 + delta * derivatives.h1 + ...
                delta ^ 2 * derivatives.h2 / 2 + ...
                delta ^ 3 * derivatives.h3 / 6;
            residuals(delta_index) = norm(g - approximation, 'fro') / ...
                max(1, norm(g, 'fro'));
        end
        ratios(point_index, direction_index, :) = ...
            residuals(1:2) ./ residuals(2:3);
    end
end
assert(maximum_h0_error < 1e-9, ...
    'Directional h0 does not match the frozen full manifold.');
assert(all(isfinite(ratios(:))) && min(ratios(:)) > 8, ...
    'The directional Taylor residual does not exhibit fourth-order convergence.');
result = struct('test_name', 'cylindrical_directional_derivatives', ...
    'pass', true, 'max_h0_relative_error', maximum_h0_error, ...
    'min_halving_ratio', min(ratios(:)), ...
    'max_halving_ratio', max(ratios(:)));
end
