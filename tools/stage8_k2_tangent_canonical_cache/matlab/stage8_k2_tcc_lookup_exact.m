function [g, info] = stage8_k2_tcc_lookup_exact( ...
    cache, global_angle_deg, model_or_identity, options)
%STAGE8_K2_TCC_LOOKUP_EXACT Return a column only for an exact grid key.

if nargin < 3 || isempty(model_or_identity)
    model_or_identity = struct();
end
if nargin < 4 || isempty(options)
    options = struct();
end
clock = tic;
g = [];
info = info_template_local(global_angle_deg);
if ~(isnumeric(global_angle_deg) && numel(global_angle_deg) == 2 && ...
        all(isfinite(global_angle_deg(:))))
    error('stage8_k2_tcc_lookup_exact:Angle', ...
        'global_angle_deg must be a finite [azimuth,elevation] pair.');
end
angle = double(global_angle_deg(:).');
info.requested_global_az_deg = angle(1);
info.requested_el_deg = angle(2);

[identity_valid, identity_info] = ...
    stage8_k2_tcc_validate_cache_identity(cache, model_or_identity, options);
info.identity_valid = identity_valid;
if ~identity_valid
    info.cache_miss_reason = identity_info.cache_miss_reason;
    info.runtime_sec = toc(clock);
    return;
end

center = double(cache.identity.measurement_center_az_deg);
delta = wrap180_local(angle(1) - center);
info.requested_delta_az_deg = delta;
tolerance = double(cache.identity.grid_key_tolerance_deg);
[delta_error, delta_index] = nearest_key_local(delta, ...
    double(cache.delta_grid_deg), tolerance);
[el_error, el_index] = nearest_key_local(angle(2), ...
    double(cache.el_grid_deg), tolerance);
info.delta_key_error_deg = delta_error;
info.el_key_error_deg = el_error;
if ~isfinite(delta_error) || ~isfinite(el_error)
    info.cache_miss_reason = 'OFF_GRID_EXACT_KEY';
    if isfield(options, 'strict') && logical(options.strict)
        error('stage8_k2_tcc_lookup_exact:CacheMiss', ...
            'Exact lookup missed the requested grid key.');
    end
    info.runtime_sec = toc(clock);
    return;
end
g = cache.G_grid(:, delta_index, el_index);
info.cache_hit = true;
info.cache_miss_reason = 'NOT_APPLICABLE';
info.matched_delta_index = delta_index;
info.matched_el_index = el_index;
info.runtime_sec = toc(clock);
end

function [error_value, index] = nearest_key_local(value, grid, tolerance)
difference = abs(grid - value);
[minimum, index] = min(difference);
if isempty(minimum) || minimum > tolerance
    error_value = Inf;
    index = NaN;
else
    error_value = minimum;
end
end

function info = info_template_local(angle)
info = struct('cache_hit', false, 'cache_miss_reason', ...
    'NOT_RUN', 'requested_global_az_deg', NaN, 'requested_el_deg', NaN, ...
    'requested_delta_az_deg', NaN, 'matched_delta_index', NaN, ...
    'matched_el_index', NaN, 'delta_key_error_deg', Inf, ...
    'el_key_error_deg', Inf, 'identity_valid', false, 'runtime_sec', 0);
if isnumeric(angle) && numel(angle) == 2
    info.requested_global_az_deg = double(angle(1));
    info.requested_el_deg = double(angle(2));
end
end

function angle = wrap180_local(angle)
angle = mod(angle + 180, 360) - 180;
end
