function [cache, info] = stage8_k2_tcc_build_cache(model, options)
%STAGE8_K2_TCC_BUILD_CACHE Build a fixed-measurement exact canonical cache.

if nargin < 2 || isempty(options)
    options = struct();
end
constants = stage8_k2_tcc_constants();
geometry = stage8_k2_tcc_build_canonical_geometry(model, options);
bounds = get_option_local(options, 'domain_bounds_deg', ...
    constants.default_domain_bounds_deg);
step = get_option_local(options, 'grid_step_deg', constants.grid_step_deg);
if isfield(options, 'global_az_grid_deg') && ...
        ~isempty(options.global_az_grid_deg)
    global_az_grid = double(options.global_az_grid_deg(:).');
else
    global_az_grid = make_grid_local(bounds(1), bounds(2), step);
end
if isfield(options, 'delta_grid_deg') && ~isempty(options.delta_grid_deg)
    delta_grid = double(options.delta_grid_deg(:).');
    if isfield(options, 'global_az_grid_deg') && ...
            numel(global_az_grid) == numel(delta_grid)
        global_az_for_build = global_az_grid;
    else
        global_az_for_build = wrap180_local(delta_grid + ...
            geometry.measurement_center_az_deg);
    end
else
    delta_grid = wrap180_local(global_az_grid - ...
        geometry.measurement_center_az_deg);
    global_az_for_build = global_az_grid;
end
if isfield(options, 'el_grid_deg') && ~isempty(options.el_grid_deg)
    el_grid = double(options.el_grid_deg(:).');
else
    el_grid = make_grid_local(bounds(3), bounds(4), step);
end
validate_grid_local(delta_grid, el_grid);
[cache_key, identity] = stage8_k2_tcc_build_cache_key( ...
    model, geometry, delta_grid, el_grid, options);

B = size(model.Wseq, 2);
G_grid = complex(zeros(B, numel(delta_grid), numel(el_grid)));
clock = tic;
for el_index = 1:numel(el_grid)
    for az_index = 1:numel(delta_grid)
        % The key remains canonical delta-azimuth. Build the stored column
        % through the frozen actual-frame direct ordering so an exact hit is
        % bitwise identical even at nearly rank-deficient endpoint pairs.
        global_az = global_az_for_build(az_index);
        a_legacy = build_receive_cyl_steering_vec( ...
            model.array_meta.XAct, model.array_meta.YAct, ...
            model.array_meta.ZAct, global_az, el_grid(el_index), ...
            model.lambda);
        canonical_matrix = reshape_cyl_vector_to_matrix( ...
            a_legacy(:), model.array_meta);
        a_canonical_order = canonical_matrix(:);
        G_grid(:, az_index, el_index) = model.Tseq * ...
            (model.Wseq' * a_canonical_order);
    end
end
build_time = toc(clock);
memory_bytes = double(numel(G_grid)) * 16;

cache = struct();
cache.cache_version = identity.cache_version;
cache.G_grid = G_grid;
cache.delta_grid_deg = delta_grid;
cache.el_grid_deg = el_grid;
cache.global_az_grid_deg = global_az_for_build;
cache.identity = identity;
cache.cache_identity_hash = identity.cache_identity_hash;
cache.cache_key = cache_key;
cache.fixed_measurement_hash = identity.fixed_measurement_hash;
cache.measurement_config_id = identity.measurement_config_id;
cache.noise_profile_id = identity.noise_profile_id;
cache.phase_factor = identity.phase_factor;
cache.steering_phase_sign = identity.steering_phase_sign;
cache.lambda = identity.lambda;
cache.numeric_class = identity.numeric_class;
cache.array_geometry_hash = identity.array_geometry_hash;
cache.canonical_geometry_hash = identity.canonical_geometry_hash;
cache.canonical_element_order = identity.canonical_element_order;
cache.center_column = identity.center_column;
cache.requested_center_az_deg = identity.requested_center_az_deg;
cache.measurement_center_az_deg = identity.measurement_center_az_deg;
cache.W_hash = identity.W_hash;
cache.T_hash = identity.T_hash;
cache.delta_grid_hash = identity.delta_grid_hash;
cache.el_grid_hash = identity.el_grid_hash;
cache.grid_key_tolerance_deg = identity.grid_key_tolerance_deg;
cache.geometry = geometry;
cache.cache_build_time_sec = build_time;
cache.cache_memory_bytes = memory_bytes;
cache.cache_memory_MB = memory_bytes / 1024^2;
cache.supports_interpolation = false;
cache.lookup_mode = 'EXACT_ONLY';
cache.cache_build_coordinate_mode = ...
    'CANONICAL_KEY_ACTUAL_FRAME_DIRECT_CERTIFIED';

info = struct('cache_build_time_sec', build_time, ...
    'cache_memory_bytes', memory_bytes, ...
    'cache_memory_MB', memory_bytes / 1024^2, ...
    'cache_identity_hash', cache.cache_identity_hash, ...
    'cache_key', cache.cache_key, 'grid_size', ...
    [numel(delta_grid), numel(el_grid)], 'global_grid_size', ...
    [numel(global_az_grid), numel(el_grid)], ...
    'measurement_center_az_deg', geometry.measurement_center_az_deg, ...
    'requested_center_az_deg', geometry.requested_center_az_deg);
end

function grid = make_grid_local(lower_bound, upper_bound, step)
if ~(isscalar(lower_bound) && isscalar(upper_bound) && ...
        isscalar(step) && isfinite(lower_bound) && ...
        isfinite(upper_bound) && isfinite(step) && step > 0 && ...
        upper_bound >= lower_bound)
    error('stage8_k2_tcc_build_cache:GridSpec', ...
        'Grid bounds and step must be finite with upper >= lower.');
end
count = floor((upper_bound - lower_bound) / step + 1e-10);
grid = lower_bound + (0:count) * step;
if isempty(grid) || abs(grid(end) - upper_bound) > ...
        64 * eps(max(1, abs(upper_bound)))
    grid(end + 1) = upper_bound;
else
    grid(end) = upper_bound;
end
grid = double(grid);
end

function validate_grid_local(delta_grid, el_grid)
if isempty(delta_grid) || isempty(el_grid) || ...
        any(~isfinite(delta_grid)) || any(~isfinite(el_grid)) || ...
        numel(unique(delta_grid)) ~= numel(delta_grid) || ...
        numel(unique(el_grid)) ~= numel(el_grid)
    error('stage8_k2_tcc_build_cache:Grid', ...
        'Cache grids must be finite and contain unique keys.');
end
end

function value = get_option_local(options, name, fallback)
if isfield(options, name) && ~isempty(options.(name))
    value = options.(name);
else
    value = fallback;
end
end

function angle = wrap180_local(angle)
angle = mod(angle + 180, 360) - 180;
end
