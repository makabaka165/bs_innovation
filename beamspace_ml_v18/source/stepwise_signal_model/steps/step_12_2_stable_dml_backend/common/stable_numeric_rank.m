function [rank_value, threshold, info] = stable_numeric_rank( ...
    singular_values, matrix_size, multiplier)
%STABLE_NUMERIC_RANK Determine rank from a scale-relative threshold.

if nargin < 3 || isempty(multiplier)
    multiplier = 1;
end
if ~(isnumeric(singular_values) && isreal(singular_values) && ...
        isvector(singular_values) && ~isempty(singular_values) && ...
        all(isfinite(singular_values(:))) && all(singular_values(:) >= 0))
    error('stable_numeric_rank:SingularValues', ...
        'singular_values must be a non-empty finite nonnegative real vector.');
end
if ~(isa(singular_values, 'double') || isa(singular_values, 'single'))
    error('stable_numeric_rank:FloatingPoint', ...
        'singular_values must use single or double precision.');
end
if ~(isnumeric(matrix_size) && numel(matrix_size) == 2 && ...
        all(isfinite(matrix_size(:))) && all(matrix_size(:) >= 1) && ...
        all(matrix_size(:) == fix(matrix_size(:))))
    error('stable_numeric_rank:MatrixSize', ...
        'matrix_size must contain two positive integer dimensions.');
end
if ~(isscalar(multiplier) && isfinite(multiplier) && multiplier > 0)
    error('stable_numeric_rank:Multiplier', ...
        'multiplier must be a positive finite scalar.');
end

sigma = sort(singular_values(:), 'descend');
sigma1 = sigma(1);
threshold = multiplier * max(matrix_size(:)) * ...
    eps(class(sigma1)) * sigma1;
rank_value = nnz(sigma > threshold);

info = struct();
info.rank = rank_value;
info.threshold = threshold;
info.multiplier = multiplier;
info.matrix_size = reshape(matrix_size, 1, 2);
info.sigma1 = sigma1;
info.singular_values = sigma;
info.relative_threshold = threshold / max(sigma1, realmin(class(sigma1)));
end
