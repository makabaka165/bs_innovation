function [S_hat, info] = solve_fitted_source_coefficients(G_hat, Z_white, opts)
%SOLVE_FITTED_SOURCE_COEFFICIENTS Recover ML coefficients by stable SVD.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
unknown = setdiff(fieldnames(opts), {'rank_multiplier'});
if ~isempty(unknown)
    error('solve_fitted_source_coefficients:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~(isnumeric(G_hat) && ismatrix(G_hat) && ~isempty(G_hat) && ...
        all(isfinite(G_hat(:))) && isnumeric(Z_white) && ...
        ismatrix(Z_white) && size(Z_white, 1) == size(G_hat, 1) && ...
        all(isfinite(Z_white(:))))
    error('solve_fitted_source_coefficients:Inputs', ...
        'G_hat and Z_white must be finite matrices with equal row count.');
end
[U, Sigma, V] = svd(G_hat, 'econ');
singular_values = diag(Sigma);
[effective_rank, threshold, rank_info] = stable_numeric_rank( ...
    singular_values, size(G_hat), opts.rank_multiplier);
K = size(G_hat, 2);
if effective_rank < K
    S_hat = complex(NaN(K, size(Z_white, 2)));
    status = 'NUMERIC_RANK_DEFICIENT';
else
    S_hat = V(:, 1:K) * ...
        (diag(1 ./ singular_values(1:K)) * (U(:, 1:K)' * Z_white));
    status = 'OK';
end
info = struct('effective_rank', effective_rank, ...
    'requested_rank', K, 'singular_values', singular_values, ...
    'rank_threshold', threshold, ...
    'relative_rank_threshold', rank_info.relative_threshold, ...
    'rank_multiplier', opts.rank_multiplier, 'status', status, ...
    'num_svd', 1, 'solve_method', 'ECONOMY_SVD_PSEUDOINVERSE');
end
