function [score, rss, sigma2_hat, loglik_concentrated, ...
    effective_rank, debug] = concentrated_dml_rss(Z, G, opts)
%CONCENTRATED_DML_RSS Return stable DML RSS and complex-Gaussian ML scale.

if nargin < 3
    opts = struct();
end
[score, rss, debug] = beamspace_dml_score_svd(Z, G, opts);
effective_rank = debug.effective_rank;
rC = size(Z, 1);
L = size(Z, 2);
num_complex_observations = rC * L;
sigma2_hat = rss / num_complex_observations;
if sigma2_hat > 0
    loglik_concentrated = -num_complex_observations * ...
        (log(pi * sigma2_hat) + 1);
else
    loglik_concentrated = Inf;
end

debug.effective_whitening_dimension = rC;
debug.num_complex_observations = num_complex_observations;
debug.sigma2_hat = sigma2_hat;
debug.loglik_concentrated = loglik_concentrated;
debug.variance_estimator = 'maximum_likelihood_rss_over_rC_times_L';
end
