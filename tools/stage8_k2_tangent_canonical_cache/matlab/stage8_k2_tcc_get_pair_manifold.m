function [G, manifold_info, provider_info] = ...
    stage8_k2_tcc_get_pair_manifold(angles_deg, model, provider, options)
%STAGE8_K2_TCC_GET_PAIR_MANIFOLD Build ordered columns and rank once.

if nargin < 4 || isempty(options)
    options = struct();
end
if ~(isnumeric(angles_deg) && ismatrix(angles_deg) && ...
        size(angles_deg, 2) == 2 && size(angles_deg, 1) == 2 && ...
        all(isfinite(angles_deg(:))))
    error('stage8_k2_tcc_get_pair_manifold:Angles', ...
        'angles_deg must be a finite 2-by-2 matrix.');
end
if ~(isstruct(provider) && isscalar(provider) && isfield(provider, 'mode'))
    error('stage8_k2_tcc_get_pair_manifold:Provider', ...
        'provider must be a scalar provider struct.');
end
if strcmp(upper(char(string(provider.mode))), 'TECS_EXACT_STACK')
    [G, manifold_info, provider_info] = ...
        stage8_k2_tecs_provider_pair(angles_deg, model, provider, options);
    return;
end
clock = tic;
angles = double(angles_deg);
mode = upper(char(string(provider.mode)));
columns = cell(2, 1);
column_sources = strings(2, 1);
cache_hit_count = 0;
cache_miss_count = 0;
direct_fallback_count = 0;
identity_rejection_count = 0;
lookup_runtime = 0;
direct_runtime = 0;

if strcmp(mode, 'DIRECT_ONLY')
    direct_clock = tic;
    [direct_G, direct_info] = stage8_k2_tcc_build_g_direct( ...
        angles, model, struct());
    direct_runtime = toc(direct_clock);
    columns = {direct_G(:, 1); direct_G(:, 2)};
    column_sources(:) = "DIRECT_ONLY";
elseif strcmp(mode, 'EXACT_CACHE_OR_DIRECT')
    cache_columns = cell(2, 1);
    hit = false(2, 1);
    lookup_infos = cell(2, 1);
    for index = 1:2
        if isfield(provider, 'cache') && ~isempty(provider.cache)
            [cache_columns{index}, current_lookup] = ...
                stage8_k2_tcc_lookup_exact(provider.cache, angles(index, :), ...
                model, provider.options);
            lookup_infos{index} = current_lookup;
        else
            lookup_infos{index} = lookup_template_local();
            lookup_infos{index}.cache_miss_reason = 'CACHE_UNAVAILABLE';
            lookup_infos{index}.identity_valid = false;
        end
        hit(index) = lookup_infos{index}.cache_hit;
        lookup_runtime = lookup_runtime + lookup_infos{index}.runtime_sec;
        cache_hit_count = cache_hit_count + double(hit(index));
        cache_miss_count = cache_miss_count + double(~hit(index));
        identity_rejection_count = identity_rejection_count + ...
            double(~lookup_infos{index}.identity_valid);
    end
    for index = 1:2
        if hit(index)
            columns{index} = cache_columns{index};
            column_sources(index) = "CACHE_EXACT";
        end
    end
    miss_indices = find(~hit);
    if ~isempty(miss_indices)
        direct_clock = tic;
        if numel(miss_indices) == 2
            direct_G = stage8_k2_tcc_build_g_direct(angles, model, struct());
            for index = miss_indices(:).'
                columns{index} = direct_G(:, index);
            end
        else
            % A single fallback column is built with a fixed two-column GEMM
            % so it has the same floating-point accumulation as a pair.
            index = miss_indices(1);
            repeated_angles = repmat(angles(index, :), 2, 1);
            direct_G = stage8_k2_tcc_build_g_direct( ...
                repeated_angles, model, struct());
            columns{index} = direct_G(:, 1);
        end
        direct_runtime = toc(direct_clock);
        direct_fallback_count = numel(miss_indices);
        column_sources(miss_indices) = "DIRECT_FALLBACK";
    end
else
    error('stage8_k2_tcc_get_pair_manifold:Mode', ...
        'Unsupported provider mode: %s.', mode);
end
G = [columns{1}, columns{2}];
rank_multiplier = 1;
if isfield(options, 'rank_multiplier') && ~isempty(options.rank_multiplier)
    rank_multiplier = options.rank_multiplier;
elseif isfield(provider, 'options') && ...
        isfield(provider.options, 'rank_multiplier')
    rank_multiplier = provider.options.rank_multiplier;
end
rank_clock = tic;
[rank_value, singular_values, threshold] = ...
    stage8_k2_tcc_stable_matrix_rank(G, rank_multiplier);
rank_runtime = toc(rank_clock);
manifold_info = struct('rank_Gseq', rank_value, ...
    'singular_values_Gseq', singular_values, ...
    'rank_threshold_Gseq', threshold, 'num_svd', 1, ...
    'target_angles_deg', angles, 'fixed_measurement_hash', ...
    provider.fixed_measurement_hash, 'phase_factor', 1, ...
    'direct_g_only_flag', true, 'full_receive_geometry_used_flag', false, ...
    'Gseq_size', size(G));
provider_info = struct('mode', mode, 'column_sources', column_sources, ...
    'cache_hit_count', cache_hit_count, ...
    'cache_miss_count', cache_miss_count, ...
    'direct_fallback_count', direct_fallback_count, ...
    'identity_rejection_count', identity_rejection_count, ...
    'lookup_runtime_sec', lookup_runtime, ...
    'direct_runtime_sec', direct_runtime, ...
    'rank_runtime_sec', rank_runtime, ...
    'total_runtime_sec', toc(clock), ...
    'fixed_measurement_hash', provider.fixed_measurement_hash);
end

function info = lookup_template_local()
info = struct('cache_hit', false, 'identity_valid', false, ...
    'cache_miss_reason', 'NOT_RUN', 'runtime_sec', 0);
end
