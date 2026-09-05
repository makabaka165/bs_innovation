function fit = stage8_k2_rtc_fit_k1_white(Z, model, domain, constants)
fit = struct('mode', 'K1_WHITE_SINGLE_TARGET_DML_CENTER', 'fit_valid', false, ...
    'fit_status', 'K1_NO_VALID_GRID_POINT', 'angles_hat_deg', [NaN NaN], ...
    'rss', NaN, 'loglik_concentrated', -Inf, 'score_call_count', 0, ...
    'svd_call_count', 0, 'coarse_count', 0, 'coarse_loglik', -Inf, ...
    'continuous_status', 'NOT_RUN', 'continuous_loglik', -Inf, 'history', table());
points = domain.candidate_points_deg;
assert(size(points,1) == 21);
best = 0;
for k = 1:size(points,1)
    [value, valid] = evaluate(points(k,:));
    fit.coarse_count = fit.coarse_count + 1;
    if valid && value.loglik > fit.coarse_loglik
        fit.coarse_loglik = value.loglik;
        best = k;
    end
end
if best == 0, return; end
[continuous, history] = refine_stage8_k1_continuous(struct('Zseq_white', Z), ...
    points(best,:), domain, model, struct());
fit.score_call_count = fit.score_call_count + continuous.score_call_count;
fit.svd_call_count = fit.svd_call_count + continuous.svd_call_count;
fit.continuous_status = continuous.status;
fit.history = history;
selected = points(best,:);
if continuous.estimate_returned_flag
    [value, valid] = evaluate(continuous.angles_hat_deg);
    if valid
        fit.continuous_loglik = value.loglik;
        if value.loglik >= fit.coarse_loglik, selected = continuous.angles_hat_deg; end
    else
        fit.continuous_status = 'K1_CONTINUOUS_INVALID';
    end
else
    fit.continuous_status = 'K1_CONTINUOUS_INVALID';
end
[value, valid] = evaluate(selected);
if ~valid
    fit.fit_status = 'K1_CENTER_INVALID';
    return;
end
fit.fit_valid = true;
fit.fit_status = 'K1_WHITE_SINGLE_TARGET_DML_CENTER_VALID';
fit.angles_hat_deg = selected;
fit.rss = value.rss;
fit.loglik_concentrated = value.loglik;

    function [value, valid] = evaluate(angles)
        [G,~,info] = build_full_sequential_local_manifold(angles,model, ...
            struct('rank_multiplier',constants.rank_multiplier));
        fit.svd_call_count = fit.svd_call_count + info.num_svd;
        [score,rss,~,ll,rank] = concentrated_dml_rss(Z,G, ...
            struct('requested_rank',1,'rank_multiplier',constants.rank_multiplier, ...
            'compute_projector_checks',false));
        fit.score_call_count = fit.score_call_count+1;
        fit.svd_call_count = fit.svd_call_count+1;
        valid = rank == 1 && isfinite(score) && isfinite(ll) && isfinite(rss) && rss >= 0;
        value = struct('rss',rss,'loglik',ll);
    end
end
