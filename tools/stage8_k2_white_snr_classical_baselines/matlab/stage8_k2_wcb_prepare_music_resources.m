function resources = stage8_k2_wcb_prepare_music_resources(context)
%STAGE8_K2_WCB_PREPARE_MUSIC_RESOURCES Build two chunked beam dictionaries.

constants = context.constants;
domain = context.plan.local_domain;
az_grid = exact_axis_local(domain.domain_bounds_deg(1), ...
    domain.domain_bounds_deg(2), constants.music_grid_step_deg);
el_grid = exact_axis_local(domain.domain_bounds_deg(3), ...
    domain.domain_bounds_deg(4), constants.music_grid_step_deg);
[az_mesh, el_mesh] = ndgrid(az_grid, el_grid);
points = [az_mesh(:), el_mesh(:)];

noise_count = numel(constants.noise_profile_ids);
models = cell(noise_count, 1);
whitenings = cell(noise_count, 1);
entries = repmat(struct('noise_profile_id', "", 'model', struct(), ...
    'whitening', struct(), 'G_beamspace', [], ...
    'standalone_precompute_runtime_sec', 0, ...
    'physical_dictionary_runtime_sec', 0, ...
    'transform_runtime_sec', 0), noise_count, 1);
for index = 1:noise_count
    models{index} = resolve_stage8_measurement_model( ...
        context.plan.measurement_model_registry, ...
        context.primary_measurement_config_id, ...
        constants.noise_profile_ids(index));
    dummy = complex(zeros(size(models{index}.Rn_elem, 1), 1));
    [~, whitenings{index}] = stage8_k2_cb_whiten_element_data( ...
        dummy, models{index});
    entries(index).noise_profile_id = constants.noise_profile_ids(index);
    entries(index).model = models{index};
    entries(index).whitening = whitenings{index};
    entries(index).G_beamspace = complex(zeros( ...
        size(models{index}.T_I, 1), size(points, 1)));
end

physical_runtime = 0;
transform_runtime = zeros(noise_count, 1);
chunk_size = constants.music_grid_chunk_size;
for first = 1:chunk_size:size(points, 1)
    last = min(size(points, 1), first + chunk_size - 1);
    physical_clock = tic;
    manifold = build_stage8_element_manifold(points(first:last, :), models{1});
    physical_runtime = physical_runtime + toc(physical_clock);
    for index = 1:noise_count
        transform_clock = tic;
        entries(index).G_beamspace(:, first:last) = ...
            models{index}.T_I * (models{index}.W_I' * manifold.A);
        transform_runtime(index) = transform_runtime(index) + ...
            toc(transform_clock);
    end
end
for index = 1:noise_count
    entries(index).physical_dictionary_runtime_sec = physical_runtime;
    entries(index).transform_runtime_sec = transform_runtime(index);
    entries(index).standalone_precompute_runtime_sec = ...
        physical_runtime + transform_runtime(index);
end
resources = struct('az_grid_deg', az_grid, 'el_grid_deg', el_grid, ...
    'grid_points_deg', points, 'grid_size', size(az_mesh), ...
    'grid_point_count', size(points, 1), 'entries', entries, ...
    'physical_dictionary_runtime_sec', physical_runtime, ...
    'truth_used_in_precompute_flag', false, ...
    'profile_used_in_precompute_flag', false);
end

function axis = exact_axis_local(lower, upper, step)
count = round((upper - lower) / step);
axis = lower + (0:count) * step;
axis(end) = upper;
if abs(axis(1) - lower) > 1e-12 || abs(axis(end) - upper) > 1e-12
    error('stage8_k2_wcb_prepare_music_resources:Grid', ...
        'The fixed MUSIC grid does not cover the local domain exactly.');
end
end
