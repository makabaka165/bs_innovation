function [X, info] = stable_svd_solve(A, B, requested_rank, rank_multiplier)
%STABLE_SVD_SOLVE Solve A*X=B on the scale-relative effective subspace.

if nargin < 4 || isempty(rank_multiplier)
    rank_multiplier = 1;
end
if ~(isnumeric(A) && ismatrix(A) && ~isempty(A) && all(isfinite(A(:))))
    error('stable_svd_solve:MatrixA', 'A must be a non-empty finite matrix.');
end
if ~(isnumeric(B) && ismatrix(B) && size(B, 1) == size(A, 1) && ...
        all(isfinite(B(:))))
    error('stable_svd_solve:MatrixB', ...
        'B must be finite and have the same row count as A.');
end
if ~(isscalar(requested_rank) && isfinite(requested_rank) && ...
        requested_rank >= 0 && requested_rank == fix(requested_rank))
    error('stable_svd_solve:RequestedRank', ...
        'requested_rank must be a nonnegative integer scalar.');
end

[U, S, V] = svd(A, 'econ');
singular_values = diag(S);
[effective_rank, threshold, rank_info] = stable_numeric_rank( ...
    singular_values, size(A), rank_multiplier);
if effective_rank == 0
    X = complex(zeros(size(A, 2), size(B, 2), 'like', A));
else
    U_r = U(:, 1:effective_rank);
    V_r = V(:, 1:effective_rank);
    X = V_r * ((U_r' * B) ./ singular_values(1:effective_rank));
end

info = struct();
info.effective_rank = effective_rank;
info.requested_rank = requested_rank;
info.singular_values = singular_values;
info.rank_threshold = threshold;
info.relative_rank_threshold = rank_info.relative_threshold;
info.rank_multiplier = rank_multiplier;
info.status = 'OK';
if effective_rank < requested_rank
    info.status = 'RANK_DEFICIENT';
end
info.num_svd = 1;
end
