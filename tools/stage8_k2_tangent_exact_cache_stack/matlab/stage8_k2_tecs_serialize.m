function bytes = stage8_k2_tecs_serialize(value)
%STAGE8_K2_TECS_SERIALIZE Canonical type-tagged exact-key serialization.

[~, ~, endian] = computer;
header = frame_local('SERIALIZER', unicode2native( ...
    ['STAGE8_K2_TECS_CANONICAL_KEY_SERIALIZER_V1_', endian], 'UTF-8'));
bytes = [header, encode_local(value)];
end

function bytes = encode_local(value)
if isnumeric(value)
    bytes = numeric_local(value);
elseif islogical(value)
    payload = [shape_local(size(value)), reshape(uint8(value), 1, [])];
    bytes = frame_local('LOGICAL', payload);
elseif ischar(value)
    payload = [shape_local(size(value)), ...
        frame_bytes_local(unicode2native(value(:).', 'UTF-8'))];
    bytes = frame_local('CHAR_UTF8', payload);
elseif isstring(value)
    payload = shape_local(size(value));
    for index = 1:numel(value)
        if ismissing(value(index))
            payload = [payload, frame_local('MISSING_STRING', uint8([]))]; %#ok<AGROW>
        else
            payload = [payload, frame_local('STRING_ELEMENT', ...
                unicode2native(char(value(index)), 'UTF-8'))]; %#ok<AGROW>
        end
    end
    bytes = frame_local('STRING_ARRAY', payload);
elseif iscell(value)
    payload = shape_local(size(value));
    for index = 1:numel(value)
        payload = [payload, frame_local('CELL_ELEMENT', ...
            encode_local(value{index}))]; %#ok<AGROW>
    end
    bytes = frame_local('CELL', payload);
elseif isstruct(value)
    names = sort_names_local(fieldnames(value));
    payload = [shape_local(size(value)), ...
        typecast(uint64(numel(names)), 'uint8')];
    for element = 1:numel(value)
        for index = 1:numel(names)
            name = names{index};
            payload = [payload, frame_local('FIELD_NAME', ...
                unicode2native(name, 'UTF-8')), ...
                frame_local('FIELD_VALUE', ...
                encode_local(value(element).(name)))]; %#ok<AGROW>
        end
    end
    bytes = frame_local('STRUCT', payload);
else
    error('stage8_k2_tecs_serialize:UnsupportedType', ...
        'Unsupported key type: %s.', class(value));
end
bytes = reshape(uint8(bytes), 1, []);
end

function bytes = numeric_local(value)
if issparse(value)
    error('stage8_k2_tecs_serialize:Sparse', ...
        'Sparse numeric key values are unsupported.');
end
if isfloat(value) && any(~isfinite(value(:)))
    error('stage8_k2_tecs_serialize:Nonfinite', ...
        'NaN and Inf are not valid normal cache-key values.');
end
class_bytes = unicode2native(class(value), 'UTF-8');
if isreal(value)
    real_bytes = raw_numeric_local(value);
    payload = [frame_bytes_local(class_bytes), uint8(0), ...
        shape_local(size(value)), frame_bytes_local(real_bytes)];
else
    real_bytes = raw_numeric_local(real(value));
    imaginary_bytes = raw_numeric_local(imag(value));
    payload = [frame_bytes_local(class_bytes), uint8(1), ...
        shape_local(size(value)), frame_bytes_local(real_bytes), ...
        frame_bytes_local(imaginary_bytes)];
end
bytes = frame_local('NUMERIC', payload);
end

function bytes = raw_numeric_local(value)
if isempty(value)
    bytes = uint8([]);
else
    bytes = typecast(reshape(value, 1, []), 'uint8');
end
end

function bytes = shape_local(shape)
shape = uint64(shape(:).');
bytes = [typecast(uint64(numel(shape)), 'uint8'), ...
    typecast(shape, 'uint8')];
end

function output = frame_local(tag, payload)
tag_bytes = unicode2native(char(tag), 'UTF-8');
payload = reshape(uint8(payload), 1, []);
output = [frame_bytes_local(tag_bytes), frame_bytes_local(payload)];
end

function output = frame_bytes_local(bytes)
bytes = reshape(uint8(bytes), 1, []);
output = [typecast(uint64(numel(bytes)), 'uint8'), bytes];
end

function names = sort_names_local(names)
keys = strings(numel(names), 1);
for index = 1:numel(names)
    raw = unicode2native(names{index}, 'UTF-8');
    keys(index) = string(lower(reshape(dec2hex(raw, 2).', 1, [])));
end
[~, order] = sort(keys);
names = names(order);
end
