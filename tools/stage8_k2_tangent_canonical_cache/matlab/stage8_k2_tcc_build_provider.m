function provider = stage8_k2_tcc_build_provider( ...
    mode, model, cache, options)
%STAGE8_K2_TCC_BUILD_PROVIDER Construct an explicit stateless provider.

if nargin < 1 || isempty(mode)
    mode = 'DIRECT_ONLY';
end
if nargin < 2
    error('stage8_k2_tcc_build_provider:Model', ...
        'A measurement model is required.');
end
if nargin < 3
    cache = [];
end
if nargin < 4 || isempty(options)
    options = struct();
end
mode = upper(char(string(mode)));
if ~ismember(mode, {'DIRECT_ONLY','EXACT_CACHE_OR_DIRECT'})
    error('stage8_k2_tcc_build_provider:Mode', ...
        'Unsupported provider mode: %s.', mode);
end
provider = struct('mode', mode, 'cache', cache, 'options', options, ...
    'fixed_measurement_hash', char(string(model.fixed_measurement_hash)), ...
    'identity_valid', true, 'identity_info', struct(), ...
    'created_by', 'stage8_k2_tcc_build_provider');
if strcmp(mode, 'EXACT_CACHE_OR_DIRECT') && ~isempty(cache)
    [valid, identity_info] = stage8_k2_tcc_validate_cache_identity( ...
        cache, model, options);
    provider.identity_valid = valid;
    provider.identity_info = identity_info;
elseif strcmp(mode, 'EXACT_CACHE_OR_DIRECT')
    provider.identity_valid = false;
    provider.identity_info = struct('identity_valid', false, ...
        'cache_miss_reason', 'CACHE_UNAVAILABLE', ...
        'mismatch_reasons', {{'CACHE_UNAVAILABLE'}});
end
end
