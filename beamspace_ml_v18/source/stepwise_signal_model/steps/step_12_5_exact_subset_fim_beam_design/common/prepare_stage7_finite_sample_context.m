function finite = prepare_stage7_finite_sample_context(context, methods)
%PREPARE_STAGE7_FINITE_SAMPLE_CONTEXT Precompute the shared DML grid.

az_grid = context.plan.solver.az_grid_deg;
el_grid = context.plan.solver.el_grid_deg;
[az_mesh, el_mesh] = ndgrid(az_grid, el_grid);
grid_angles_deg = [az_mesh(:), el_mesh(:)];
grid_manifold = build_stage7_element_manifold( ...
    grid_angles_deg, context.plan.pool, context.cfg);
raw_grid_G0 = context.plan.pool.W0' * grid_manifold.A;

finite = struct();
finite.context = struct('plan', context.plan, 'cfg', context.cfg);
finite.methods = methods;
finite.grid_angles_deg = grid_angles_deg;
finite.raw_grid_G0 = raw_grid_G0;
finite.az_grid_deg = az_grid;
finite.el_grid_deg = el_grid;
finite.N_az_grid = numel(az_grid);
finite.N_el_grid = numel(el_grid);
finite.method_models = cell(2, 1);
for noise_index = 1:2
    unique_subsets = unique(methods.subset_id, 'stable');
    models = repmat(struct('subset_id', "", 'channels', [], ...
        'model', struct(), 'G_bank', []), numel(unique_subsets), 1);
    for subset_index = 1:numel(unique_subsets)
        method_row = methods(find(methods.subset_id == ...
            unique_subsets(subset_index), 1), :);
        channels = channels_local(method_row.elevation_mask_integer, ...
            method_row.azimuth_mask_integer);
        model = build_exact_subset_model(context.plan.pool, channels, ...
            context.noise_models{noise_index}, struct());
        models(subset_index) = struct('subset_id', unique_subsets(subset_index), ...
            'channels', channels, 'model', model, ...
            'G_bank', model.T_I * raw_grid_G0(channels, :));
    end
    finite.method_models{noise_index} = models;
end
end

function channels = channels_local(mask_e, mask_a)
elevation = find(bitget(mask_e, 1:5));
azimuth = find(bitget(mask_a, 1:5));
channels = reshape(elevation(:) + (azimuth(:).' - 1) * 5, 1, []);
channels = channels(:).';
end
