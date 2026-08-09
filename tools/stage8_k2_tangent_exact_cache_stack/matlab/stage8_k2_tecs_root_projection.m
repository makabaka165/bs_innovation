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
end
function value = remove_fields_local(value, fields)
present = intersect(fieldnames(value), fields, 'stable');
if ~isempty(present), value = rmfield(value, present); end
end
