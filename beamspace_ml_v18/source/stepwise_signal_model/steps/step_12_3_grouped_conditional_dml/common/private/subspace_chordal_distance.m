function [distance, info] = subspace_chordal_distance(A, B, rank_multiplier)
%SUBSPACE_CHORDAL_DISTANCE Compare column spaces with relative ranks.

if nargin < 3 || isempty(rank_multiplier)
    rank_multiplier = 1;
end
if ~(isnumeric(A) && ismatrix(A) && ~isempty(A) && all(isfinite(A(:))) && ...
        isnumeric(B) && ismatrix(B) && ~isempty(B) && all(isfinite(B(:))) && ...
        size(A, 1) == size(B, 1))
    error('subspace_chordal_distance:Inputs', ...
        'A and B must be finite non-empty matrices with equal row counts.');
end

[Ua, Sa, ~] = svd(A, 'econ');
[Ub, Sb, ~] = svd(B, 'econ');
[rank_a, threshold_a] = stable_numeric_rank(diag(Sa), size(A), rank_multiplier);
[rank_b, threshold_b] = stable_numeric_rank(diag(Sb), size(B), rank_multiplier);
Ua = Ua(:, 1:rank_a);
Ub = Ub(:, 1:rank_b);
overlap = real(norm(Ua' * Ub, 'fro') ^ 2);
distance_squared = max(0, 0.5 * (rank_a + rank_b - 2 * overlap));
distance = sqrt(distance_squared);

info = struct();
info.rank_a = rank_a;
info.rank_b = rank_b;
info.rank_threshold_a = threshold_a;
info.rank_threshold_b = threshold_b;
info.num_svd = 2;
end
