function value = stage8_k2_tfbc_strip_runtime(value)
%STAGE8_K2_TFBC_STRIP_RUNTIME Remove non-semantic timing fields recursively.

if isstruct(value)
    fields = {'runtime','runtime_sec','manifold_runtime_sec', ...
        'build_runtime_sec','cache_build_runtime_sec', ...
        'validate_once_runtime_sec'};
    present = intersect(fieldnames(value), fields, 'stable');
    if ~isempty(present), value = rmfield(value, present); end
    names = fieldnames(value);
    for element = 1:numel(value)
        for index = 1:numel(names)
            value(element).(names{index}) = ...
                stage8_k2_tfbc_strip_runtime(value(element).(names{index}));
        end
    end
elseif iscell(value)
    for index = 1:numel(value)
        value{index} = stage8_k2_tfbc_strip_runtime(value{index});
    end
end
end
