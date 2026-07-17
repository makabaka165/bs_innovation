function [score, rss, debug] = beamspace_dml_score_qr(Z, G, opts)
%BEAMSPACE_DML_SCORE_QR Provide a rank-revealing QR comparison score.

if nargin < 3
    opts = struct();
end
[B, L, K] = validate_dml_inputs(Z, G, 'beamspace_dml_score_qr');
opts = normalize_dml_options(opts, K, 'beamspace_dml_score_qr');

[Q, R, permutation] = qr(G, 0);
diagonal_magnitudes = abs(diag(R));
if isempty(diagonal_magnitudes)
    threshold = 0;
    effective_rank = 0;
else
    threshold = opts.rank_multiplier * max(size(G)) * ...
        eps(class(G)) * max(diagonal_magnitudes);
    effective_rank = nnz(diagonal_magnitudes > threshold);
end
Q_r = Q(:, 1:effective_rank);
[score, rss, score_info] = finalize_projection_score(Z, Q_r, opts);

if effective_rank < opts.requested_rank
    status = 'RANK_DEFICIENT';
else
    status = 'OK';
end
debug = score_info;
debug.method = 'pivoted_economy_qr';
debug.status = status;
debug.effective_rank = effective_rank;
debug.requested_rank = opts.requested_rank;
debug.is_rank_deficient = effective_rank < opts.requested_rank;
debug.diagonal_magnitudes = diagonal_magnitudes;
debug.rank_threshold = threshold;
debug.rank_multiplier = opts.rank_multiplier;
debug.permutation = permutation;
debug.B = B;
debug.L = L;
debug.K = K;
end
