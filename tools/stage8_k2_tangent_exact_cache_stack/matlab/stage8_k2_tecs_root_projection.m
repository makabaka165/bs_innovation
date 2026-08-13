function projection = stage8_k2_tecs_root_projection(result, diagnostics, mode)
%STAGE8_K2_TECS_ROOT_PROJECTION Project root output for frozen comparison.

if nargin < 3 || isempty(mode), mode = 'CACHE_OFF_BASELINE'; end
mode = upper(char(string(mode)));
projection = struct('result', result, 'diagnostics', diagnostics);
projection.result = remove_fields_local(projection.result, {'runtime_sec'});
projection.diagnostics = remove_fields_local(projection.diagnostics, ...
    {'runtime_sec','manifold_runtime_sec'});
if strcmp(mode, 'CACHE_ON_DECISION')
    % These fields expose provider/cache mechanics but are not read by the
    % estimator's mathematical decisions or returned result contract.
    projection.diagnostics = remove_fields_local(projection.diagnostics, ...
        {'manifold_provider_mode','evaluated_column_sources', ...
        'cache_hit_count','cache_miss_count','direct_fallback_count', ...
        'identity_rejection_count','full_manifold_profile_used_flag', ...
        'evaluated_status'});
elseif ~strcmp(mode, 'CACHE_OFF_BASELINE')
    error('stage8_k2_tecs_root_projection:Mode', ...
        'Unsupported projection mode: %s.', mode);
end
% The projection is consumed only after the external root timer has
% stopped. Preserve invalid/undefined numeric semantics in a reversible
% representation that the strict cache-key serializer can checksum.
projection = normalize_nonfinite_local(projection);
end
function value = remove_fields_local(value, fields)
present = intersect(fieldnames(value), fields, 'stable');
if ~isempty(present), value = rmfield(value, present); end
end

function value = normalize_nonfinite_local(value)
if isstruct(value)
    names = fieldnames(value);
    for element = 1:numel(value)
        for index = 1:numel(names)
            name = names{index};
            value(element).(name) = normalize_nonfinite_local( ...
                value(element).(name));
        end
    end
elseif iscell(value)
    for index = 1:numel(value)
        value{index} = normalize_nonfinite_local(value{index});
    end
elseif isnumeric(value) && isfloat(value) && any(~isfinite(value(:)))
    real_values = real(value);
    imaginary_values = imag(value);
    real_codes = special_codes_local(real_values);
    imaginary_codes = special_codes_local(imaginary_values);
    real_values(~isfinite(real_values)) = 0;
    imaginary_values(~isfinite(imaginary_values)) = 0;
    value = struct( ...
        'schema_version','STAGE8_K2_TECS_NONFINITE_NUMERIC_V1', ...
        'numeric_class',class(value), ...
        'numeric_shape',uint64(size(value)), ...
        'is_complex',~isreal(value), ...
        'finite_real_values',real_values, ...
        'finite_imaginary_values',imaginary_values, ...
        'real_special_codes',real_codes, ...
        'imaginary_special_codes',imaginary_codes);
end
end

function codes = special_codes_local(value)
codes = zeros(size(value), 'uint8');
codes(isnan(value)) = uint8(1);
codes(isinf(value) & value > 0) = uint8(2);
codes(isinf(value) & value < 0) = uint8(3);
end
