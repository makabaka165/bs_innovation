function [rank_value, singular_values, threshold, info] = ...
    stage8_k2_tcc_stable_matrix_rank(A, rank_multiplier)
%STAGE8_K2_TCC_STABLE_MATRIX_RANK Match the frozen stable rank contract.

if nargin < 2 || isempty(rank_multiplier)
    rank_multiplier = 1;
end
if ~(isnumeric(A) && ismatrix(A) && ~isempty(A) && all(isfinite(A(:))))
    error('stage8_k2_tcc_stable_matrix_rank:Matrix', ...
        'A must be a non-empty finite matrix.');
end
singular_values = svd(A, 'econ');
sigma = sort(double(singular_values(:)), 'descend');
threshold = double(rank_multiplier) * max(size(A)) * eps * sigma(1);
rank_value = nnz(sigma > threshold);
info = struct('rank', rank_value, 'threshold', threshold, ...
    'multiplier', double(rank_multiplier), ...
    'matrix_size', size(A), 'sigma1', sigma(1), ...
    'singular_values', sigma, ...
    'relative_threshold', threshold / max(sigma(1), realmin));
end
