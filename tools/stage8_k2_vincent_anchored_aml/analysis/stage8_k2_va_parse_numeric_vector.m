function values = stage8_k2_va_parse_numeric_vector(serialized, expected_count)
%STAGE8_K2_VA_PARSE_NUMERIC_VECTOR Parse a serialized numeric vector.

if nargin < 2
    expected_count = [];
end
if ismissing(string(serialized))
    values = NaN(1, expected_count);
    return;
end
tokens = regexp(char(string(serialized)), ...
    '(?i)(?:[+-]?inf|nan|[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?)', ...
    'match');
values = str2double(tokens);
if ~isempty(expected_count) && numel(values) ~= expected_count
    error('stage8_k2_va_parse_numeric_vector:Cardinality', ...
        'Expected %d numeric values but parsed %d.', ...
        expected_count, numel(values));
end
values = reshape(values, 1, []);
end
