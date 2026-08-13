function [cache_valid, info] = stage8_k2_tcc_validate_cache_identity( ...
    cache, model_or_identity, options)
%STAGE8_K2_TCC_VALIDATE_CACHE_IDENTITY Fail closed on any identity mismatch.

if nargin < 2 || isempty(model_or_identity)
    model_or_identity = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end
strict = isfield(options, 'strict') && logical(options.strict);
cache_valid = false;
info = struct('identity_valid', false, 'cache_valid', false, ...
    'mismatch_reasons', {{}}, 'cache_miss_reason', ...
    'CACHE_IDENTITY_UNAVAILABLE');
if ~(isstruct(cache) && isscalar(cache) && isfield(cache, 'identity') && ...
        isstruct(cache.identity) && isscalar(cache.identity))
    if strict
        error('stage8_k2_tcc_validate_cache_identity:Missing', ...
            'CACHE_IDENTITY_UNAVAILABLE');
    end
    return;
end

reasons = {};
identity = cache.identity;
mirrors = {'fixed_measurement_hash','phase_factor','lambda', ...
    'numeric_class','array_geometry_hash','canonical_geometry_hash', ...
    'canonical_element_order','center_column','requested_center_az_deg', ...
    'measurement_center_az_deg','W_hash','T_hash','delta_grid_hash', ...
    'el_grid_hash','grid_key_tolerance_deg','cache_identity_hash'};
for index = 1:numel(mirrors)
    name = mirrors{index};
    if isfield(cache, name) && isfield(identity, name) && ...
            ~value_equal_local(cache.(name), identity.(name))
        reasons{end + 1} = [upper(name), '_MISMATCH']; %#ok<AGROW>
    end
end

if isstruct(model_or_identity) && isfield(model_or_identity, 'Wseq')
    try
        geometry = stage8_k2_tcc_build_canonical_geometry(model_or_identity);
        [~, expected] = stage8_k2_tcc_build_cache_key(model_or_identity, ...
            geometry, cache.delta_grid_deg, cache.el_grid_deg, options);
        reasons = [reasons, compare_identity_local(identity, expected)]; %#ok<AGROW>
    catch exception
        reasons{end + 1} = ['MODEL_IDENTITY_ERROR_', exception.identifier]; %#ok<AGROW>
    end
elseif isstruct(model_or_identity) && isfield(model_or_identity, ...
        'fixed_measurement_hash')
    reasons = [reasons, compare_identity_local(identity, model_or_identity)]; %#ok<AGROW>
end

if isfield(cache, 'delta_grid_deg') && isfield(cache, 'el_grid_deg')
    expected_delta_hash = stage8_k2_tcc_stable_hash( ...
        double(cache.delta_grid_deg(:).'));
    expected_el_hash = stage8_k2_tcc_stable_hash( ...
        double(cache.el_grid_deg(:).'));
    if ~isfield(identity, 'delta_grid_hash') || ...
            ~value_equal_local(expected_delta_hash, identity.delta_grid_hash)
        reasons{end + 1} = 'DELTA_GRID_HASH_MISMATCH'; %#ok<AGROW>
    end
    if ~isfield(identity, 'el_grid_hash') || ...
            ~value_equal_local(expected_el_hash, identity.el_grid_hash)
        reasons{end + 1} = 'EL_GRID_HASH_MISMATCH'; %#ok<AGROW>
    end
else
    reasons{end + 1} = 'GRID_DATA_MISSING'; %#ok<AGROW>
end

identity_for_hash = identity;
if isfield(identity_for_hash, 'cache_identity_hash')
    identity_for_hash = rmfield(identity_for_hash, 'cache_identity_hash');
end
expected_identity_hash = stage8_k2_tcc_stable_hash( ...
    'CACHE_IDENTITY', identity_for_hash);
if ~isfield(identity, 'cache_identity_hash') || ...
        ~strcmp(char(string(identity.cache_identity_hash)), ...
        char(string(expected_identity_hash)))
    reasons{end + 1} = 'CACHE_IDENTITY_HASH_MISMATCH'; %#ok<AGROW>
end

reasons = unique(reasons, 'stable');
cache_valid = isempty(reasons);
info.identity_valid = cache_valid;
info.cache_valid = cache_valid;
info.mismatch_reasons = reasons;
if cache_valid
    info.cache_miss_reason = 'NOT_APPLICABLE';
else
    info.cache_miss_reason = strjoin(reasons, '|');
    if strict
        error('stage8_k2_tcc_validate_cache_identity:Mismatch', ...
            'Cache identity rejected: %s', info.cache_miss_reason);
    end
end
end

function reasons = compare_identity_local(actual, expected)
names = {'cache_version','fixed_measurement_hash','measurement_config_id', ...
    'noise_profile_id','phase_factor','steering_phase_sign','lambda', ...
    'numeric_class','array_geometry_hash','canonical_geometry_hash', ...
    'canonical_element_order','center_column','requested_center_az_deg', ...
    'measurement_center_az_deg','W_hash','T_hash','delta_grid_hash', ...
    'el_grid_hash','grid_key_tolerance_deg'};
reasons = {};
for index = 1:numel(names)
    name = names{index};
    if ~isfield(actual, name) || ~isfield(expected, name) || ...
            ~value_equal_local(actual.(name), expected.(name))
        reasons{end + 1} = [upper(name), '_MISMATCH']; %#ok<AGROW>
    end
end
end

function equal = value_equal_local(left, right)
if ischar(left) || isstring(left) || ischar(right) || isstring(right)
    equal = strcmp(char(string(left)), char(string(right)));
elseif isnumeric(left) || islogical(left) || isnumeric(right) || ...
        islogical(right)
    equal = isequal(size(left), size(right)) && ...
        all(double(left(:)) == double(right(:)));
else
    equal = isequal(left, right);
end
end
