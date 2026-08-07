function [g, info] = stage8_k2_tcc_get_single_target_g( ...
    angle_deg, model, provider)
%STAGE8_K2_TCC_GET_SINGLE_TARGET_G Get one whitened manifold column.

if ~(isnumeric(angle_deg) && numel(angle_deg) == 2 && ...
        all(isfinite(angle_deg(:))))
    error('stage8_k2_tcc_get_single_target_g:Angle', ...
        'angle_deg must be a finite [azimuth,elevation] pair.');
end
if ~(isstruct(provider) && isscalar(provider) && isfield(provider, 'mode'))
    error('stage8_k2_tcc_get_single_target_g:Provider', ...
        'provider must be a scalar provider struct.');
end
angle = double(angle_deg(:).');
clock = tic;
info = struct('source', 'NOT_RUN', 'cache_hit', false, ...
    'cache_miss_reason', 'NOT_RUN', 'identity_valid', true, ...
    'global_angle_deg', angle, 'delta_az_deg', NaN, ...
    'runtime_sec', 0, 'lookup_runtime_sec', 0, ...
    'direct_runtime_sec', 0, 'identity_rejection_count', 0);

if isfield(provider, 'cache') && ~isempty(provider.cache)
    center = provider.cache.identity.measurement_center_az_deg;
    info.delta_az_deg = wrap180_local(angle(1) - center);
else
    geometry = stage8_k2_tcc_build_canonical_geometry(model);
    info.delta_az_deg = wrap180_local(angle(1) - ...
        geometry.measurement_center_az_deg);
end

mode = upper(char(string(provider.mode)));
switch mode
    case 'DIRECT_ONLY'
        [G, direct_info] = stage8_k2_tcc_build_g_direct(angle, model, ...
            struct());
        g = G(:, 1);
        info.source = 'DIRECT_ONLY';
        info.cache_miss_reason = 'NOT_APPLICABLE';
    case 'EXACT_CACHE_OR_DIRECT'
        if ~isfield(provider, 'cache') || isempty(provider.cache)
            info.identity_valid = false;
            info.identity_rejection_count = 1;
            info.cache_miss_reason = 'CACHE_UNAVAILABLE';
            [g, direct_info] = direct_local(angle, model);
            info.source = 'DIRECT_FALLBACK';
        else
            [cached, lookup_info] = stage8_k2_tcc_lookup_exact( ...
                provider.cache, angle, model, provider.options);
            info.lookup_runtime_sec = lookup_info.runtime_sec;
            info.cache_hit = lookup_info.cache_hit;
            info.identity_valid = lookup_info.identity_valid;
            info.cache_miss_reason = lookup_info.cache_miss_reason;
            if lookup_info.cache_hit
                g = cached;
                info.source = 'CACHE_EXACT';
                direct_info = struct('runtime_sec', 0);
            else
                if ~lookup_info.identity_valid
                    info.identity_rejection_count = 1;
                end
                [g, direct_info] = direct_local(angle, model);
                info.source = 'DIRECT_FALLBACK';
            end
        end
    otherwise
        error('stage8_k2_tcc_get_single_target_g:Mode', ...
            'Unsupported provider mode: %s.', mode);
end
if isfield(direct_info, 'runtime_sec')
    info.direct_runtime_sec = info.direct_runtime_sec + ...
        double(direct_info.runtime_sec);
end
info.runtime_sec = toc(clock);
end

function [g, info] = direct_local(angle, model)
[G, info] = stage8_k2_tcc_build_g_direct(angle, model, struct());
g = G(:, 1);
end

function angle = wrap180_local(angle)
angle = mod(angle + 180, 360) - 180;
end
