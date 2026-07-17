function [rank_value, singular_values, threshold, info] = ...
    stable_matrix_rank(A, rank_multiplier)
%STABLE_MATRIX_RANK Compute matrix rank with the shared relative rule.

if nargin < 2 || isempty(rank_multiplier)
    rank_multiplier = 1;
end
if ~(isnumeric(A) && ismatrix(A) && ~isempty(A) && all(isfinite(A(:))))
    error('stable_matrix_rank:Matrix', 'A must be a non-empty finite matrix.');
end
singular_values = svd(A, 'econ');
[rank_value, threshold, info] = stable_numeric_rank( ...
    singular_values, size(A), rank_multiplier);
end
