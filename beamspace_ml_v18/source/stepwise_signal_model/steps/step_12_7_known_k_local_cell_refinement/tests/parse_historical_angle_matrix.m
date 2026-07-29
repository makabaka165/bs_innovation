function angles = parse_historical_angle_matrix(value, K)
%PARSE_HISTORICAL_ANGLE_MATRIX Parse committed decimal angle matrices.

if ~(isscalar(K) && isnumeric(K) && isfinite(K) && ismember(K, [1, 2]))
    error('parse_historical_angle_matrix:K', 'K must be 1 or 2.');
end
text = char(string(value));
pattern = '[-+]?(?:(?:\d+\.?\d*)|(?:\.\d+))(?:[eE][-+]?\d+)?';
tokens = regexp(text, pattern, 'match');
residual = regexprep(text, pattern, '');
residual = regexprep(residual, '[\[\]\s,;]', '');
if ~isempty(residual) || numel(tokens) ~= 2 * K
    error('parse_historical_angle_matrix:Format', ...
        'Historical angles do not have the required %d-by-2 form.', K);
end
values = str2double(tokens);
if any(~isfinite(values))
    error('parse_historical_angle_matrix:Finite', ...
        'Historical angles must contain only finite decimal values.');
end
angles = reshape(values, 2, K).';
end
