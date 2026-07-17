function [score, rss, debug] = beamspace_dml_score_svd(Z, G, opts)
%BEAMSPACE_DML_SCORE_SVD Score a manifold column space by economy SVD.

if nargin < 3
    opts = struct();
end
[B, L, K] = validate_dml_inputs(Z, G, 'beamspace_dml_score_svd');
opts = normalize_dml_options(opts, K, 'beamspace_dml_score_svd');

[U, S, ~] = svd(G, 'econ');
singular_values = diag(S);
[effective_rank, threshold, rank_info] = stable_numeric_rank( ...
    singular_values, size(G), opts.rank_multiplier);
U_r = U(:, 1:effective_rank);
[score, rss, score_info] = finalize_projection_score(Z, U_r, opts);

if effective_rank < opts.requested_rank
    status = 'RANK_DEFICIENT';
else
    status = 'OK';
end
if effective_rank > 0
    sigma_min_effective = singular_values(effective_rank);
    effective_condition = singular_values(1) / sigma_min_effective;
else
    sigma_min_effective = 0;
    effective_condition = Inf;
end

debug = score_info;
debug.method = 'economy_svd';
debug.status = status;
debug.effective_rank = effective_rank;
debug.requested_rank = opts.requested_rank;
debug.is_rank_deficient = effective_rank < opts.requested_rank;
debug.singular_values = singular_values;
debug.rank_threshold = threshold;
debug.relative_rank_threshold = rank_info.relative_threshold;
debug.rank_multiplier = opts.rank_multiplier;
debug.sigma_min_effective = sigma_min_effective;
debug.effective_condition = effective_condition;
debug.B = B;
debug.L = L;
debug.K = K;
end
