function [G, info] = stage8_k2_tcc_registered_lookup( ...
    dictionary, angles_deg, model_or_guard)
%STAGE8_K2_TCC_REGISTERED_LOOKUP Exact O(B) diagnostic dictionary lookup.

if nargin < 3
    model_or_guard = struct();
end
clock = tic;
validate_dictionary_local(dictionary);
if ~(isnumeric(angles_deg) && ismatrix(angles_deg) && ...
        size(angles_deg, 2) == 2 && ~isempty(angles_deg) && ...
        all(isfinite(angles_deg(:))))
    error('stage8_k2_tcc_registered_lookup:Angles', ...
        'angles_deg must be a finite K-by-2 matrix.');
end
identity_valid = cheap_guard_local(dictionary, model_or_guard);
K = size(angles_deg, 1);
G = complex(zeros(size(dictionary.G, 1), 0));
info = struct('cache_hit', false, 'identity_valid', identity_valid, ...
    'key_indices', NaN(K, 1), 'key_ids', strings(K, 1), ...
    'key_error_deg', Inf(K, 1), 'off_grid_count', K, ...
    'runtime_sec', 0, 'status', 'NOT_RUN');
if ~identity_valid
    info.status = 'CHEAP_IDENTITY_GUARD_REJECTED';
    info.runtime_sec = toc(clock);
    return;
end

indices = NaN(K, 1);
errors = Inf(K, 1);
tolerance = 1e-11;
key_angles = [dictionary.key_table.az_deg, dictionary.key_table.el_deg];
for row = 1:K
    difference = max(abs(key_angles - double(angles_deg(row, :))), [], 2);
    [errors(row), indices(row)] = min(difference);
    if isempty(indices(row)) || errors(row) > tolerance
        indices(row) = NaN;
    end
end
info.key_indices = indices;
info.key_error_deg = errors;
info.off_grid_count = nnz(~isfinite(indices));
valid = isfinite(indices);
if any(valid)
    info.key_ids(valid) = string(dictionary.key_table.key_id(indices(valid)));
end
if all(valid)
    G = dictionary.G(:, indices);
    info.cache_hit = true;
    info.status = 'REGISTERED_EXACT_HIT';
else
    info.status = 'OFF_GRID_EXACT_KEY';
end
info.runtime_sec = toc(clock);
end

function pass = cheap_guard_local(dictionary, value)
pass = true;
if isempty(value)
    return;
end
if ~(isstruct(value) && isscalar(value))
    pass = false;
    return;
end
checks = {'fixed_measurement_hash','phase_factor'};
for index = 1:numel(checks)
    name = checks{index};
    if isfield(value, name)
        if ischar(dictionary.(name)) || isstring(dictionary.(name))
            pass = pass && strcmp(char(string(dictionary.(name))), ...
                char(string(value.(name))));
        else
            pass = pass && isequal(dictionary.(name), value.(name));
        end
    end
end
if isfield(value, 'local_domain_hash')
    pass = pass && strcmp(dictionary.domain_hash, ...
        char(string(value.local_domain_hash)));
elseif isfield(value, 'domain_hash')
    pass = pass && strcmp(dictionary.domain_hash, ...
        char(string(value.domain_hash)));
end
end

function validate_dictionary_local(dictionary)
required = {'G','key_table','key_count','fixed_measurement_hash', ...
    'domain_hash','phase_factor','numeric_class','dictionary_hash', ...
    'diagnostic_only_flag','production_integrated_flag'};
if ~(isstruct(dictionary) && isscalar(dictionary) && ...
        all(isfield(dictionary, required)) && ...
        dictionary.diagnostic_only_flag && ...
        ~dictionary.production_integrated_flag && ...
        dictionary.key_count == 21 && size(dictionary.G, 2) == 21)
    error('stage8_k2_tcc_registered_lookup:Dictionary', ...
        'The diagnostic registered dictionary contract is invalid.');
end
end
