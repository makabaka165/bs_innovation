function digest = stage8_stable_hash(varargin)
%STAGE8_STABLE_HASH Return a deterministic SHA-256 digest.

payload = uint8([]);
for index = 1:nargin
    item = encode_value_local(varargin{index});
    payload = [payload, typecast(uint64(numel(item)), 'uint8'), item]; %#ok<AGROW>
end
sha = System.Security.Cryptography.SHA256.Create();
cleanup = onCleanup(@() sha.Dispose());
bytes = uint8(sha.ComputeHash(payload));
digest = lower(reshape(dec2hex(bytes, 2).', 1, []));
clear cleanup
end

function bytes = encode_value_local(value)
if istable(value)
    bytes = [uint8('table'), 0, ...
        encode_value_local(value.Properties.VariableNames)];
    for index = 1:width(value)
        item = encode_value_local(value.(value.Properties.VariableNames{index}));
        bytes = [bytes, typecast(uint64(numel(item)), 'uint8'), item]; %#ok<AGROW>
    end
elseif isnumeric(value) || islogical(value)
    if issparse(value), value = full(value); end
    shape = uint64(size(value));
    bytes = [uint8(class(value)), 0, typecast(uint64(numel(shape)), 'uint8'), ...
        typecast(shape, 'uint8')];
    if islogical(value)
        bytes = [bytes, uint8(value(:).')];
    else
        bytes = [bytes, numeric_bytes_local(real(value)), ...
            numeric_bytes_local(imag(value))];
    end
elseif ischar(value)
    bytes = [uint8('char'), 0, typecast(uint64(size(value)), 'uint8'), ...
        typecast(uint16(value(:).'), 'uint8')];
elseif isstring(value)
    bytes = encode_value_local(cellstr(value));
elseif iscell(value)
    bytes = [uint8('cell'), 0, typecast(uint64(size(value)), 'uint8')];
    for index = 1:numel(value)
        item = encode_value_local(value{index});
        bytes = [bytes, typecast(uint64(numel(item)), 'uint8'), item]; %#ok<AGROW>
    end
elseif isstruct(value)
    names = sort(fieldnames(value));
    bytes = [uint8('struct'), 0, typecast(uint64(size(value)), 'uint8')];
    for element_index = 1:numel(value)
        for name_index = 1:numel(names)
            item = encode_value_local(value(element_index).(names{name_index}));
            bytes = [bytes, encode_value_local(names{name_index}), ...
                typecast(uint64(numel(item)), 'uint8'), item]; %#ok<AGROW>
        end
    end
else
    error('stage8_stable_hash:UnsupportedType', ...
        'Unsupported hash input type: %s.', class(value));
end
end

function bytes = numeric_bytes_local(value)
if isempty(value)
    bytes = uint8([]);
else
    bytes = typecast(value(:).', 'uint8');
end
end
