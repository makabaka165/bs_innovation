function digest = stable_object_hash(varargin)
%STABLE_OBJECT_HASH Return a deterministic SHA-256 digest for fixed objects.

payload = uint8([]);
for idx = 1:nargin
    payload = [payload, encode_value_local(varargin{idx})]; %#ok<AGROW>
end
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(payload);
bytes = typecast(md.digest(), 'uint8');
digest = lower(reshape(dec2hex(bytes, 2).', 1, []));
end

function bytes = encode_value_local(value)
if isnumeric(value) || islogical(value)
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
    bytes = [uint8('char'), 0, typecast(uint64(numel(value)), 'uint8'), ...
        typecast(uint16(value(:).'), 'uint8')];
elseif isstring(value) && isscalar(value)
    bytes = encode_value_local(char(value));
elseif iscell(value)
    bytes = [uint8('cell'), 0, typecast(uint64(size(value)), 'uint8')];
    for idx = 1:numel(value)
        item = encode_value_local(value{idx});
        bytes = [bytes, typecast(uint64(numel(item)), 'uint8'), item]; %#ok<AGROW>
    end
elseif isstruct(value) && isscalar(value)
    names = sort(fieldnames(value));
    bytes = [uint8('struct'), 0];
    for idx = 1:numel(names)
        item = encode_value_local(value.(names{idx}));
        bytes = [bytes, encode_value_local(names{idx}), ...
            typecast(uint64(numel(item)), 'uint8'), item]; %#ok<AGROW>
    end
else
    error('stable_object_hash:UnsupportedType', ...
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
