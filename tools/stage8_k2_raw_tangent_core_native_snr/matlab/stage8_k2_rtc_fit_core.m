function [fit, diagnostics] = stage8_k2_rtc_fit_core(Z_white, model, local_domain, constants)
% DML maximizers are invariant to a common data scale; normalize numerical comparisons.
data_scale = norm(Z_white,'fro');
assert(isfinite(data_scale) && data_scale>0);
[fit,diagnostics] = core_normalized(Z_white/data_scale,model,local_domain,constants);
energy_scale = data_scale^2;
log_offset = 2*numel(Z_white)*log(data_scale);
fit.rss = fit.rss*energy_scale;
fit.loglik_concentrated = fit.loglik_concentrated-log_offset;
diagnostics.observation_normalization = data_scale;
diagnostics.k1.rss = diagnostics.k1.rss*energy_scale;
for name = ["loglik_concentrated","coarse_loglik","continuous_loglik"]
    diagnostics.k1.(name) = diagnostics.k1.(name)-log_offset;
end
if ~isempty(diagnostics.k1.history)
    diagnostics.k1.history.score_before = diagnostics.k1.history.score_before*energy_scale;
    diagnostics.k1.history.score_after = diagnostics.k1.history.score_after*energy_scale;
end
if isfield(diagnostics.scale,'rss')
    diagnostics.scale.rss = diagnostics.scale.rss*energy_scale;
    diagnostics.scale.loglik_concentrated = diagnostics.scale.loglik_concentrated-log_offset;
    for k=1:numel(diagnostics.scale.trace)
        diagnostics.scale.trace(k).score = diagnostics.scale.trace(k).score*energy_scale;
        diagnostics.scale.trace(k).rss = diagnostics.scale.trace(k).rss*energy_scale;
        diagnostics.scale.trace(k).loglik = diagnostics.scale.trace(k).loglik-log_offset;
    end
end
end

function [fit, diagnostics] = core_normalized(Z_white, model, local_domain, constants)
timer = tic;
assert(size(Z_white,1)==15 && all(isfinite(Z_white(:))));
fit = struct('mode','TANGENT_PROFILE_CORE','selected_source','RAW_TANGENT_CORE', ...
    'K',2,'fit_valid',false,'fit_status','K1_CENTER_INVALID', ...
    'angles_hat_deg',NaN(2,2),'rss',NaN,'loglik_concentrated',NaN, ...
    'effective_rank',0,'score_call_count',0,'svd_call_count',0,'eig_call_count',0,'runtime_sec',0);
k1 = stage8_k2_rtc_fit_k1_white(Z_white,model,local_domain,constants);
fit.score_call_count = k1.score_call_count;
fit.svd_call_count = k1.svd_call_count;
diagnostics = struct('k1',k1,'direction',struct(),'scale',struct());
if ~k1.fit_valid
    fit.fit_status = k1.fit_status;
    fit.runtime_sec = toc(timer);
    return;
end
[g,derivatives,info] = build_full_sequential_local_manifold(k1.angles_hat_deg,model, ...
    struct('rank_multiplier',constants.rank_multiplier));
fit.svd_call_count = fit.svd_call_count+info.num_svd;
energy = real(g'*g);
if ~(isfinite(energy) && energy > 0)
    fit.fit_status = 'CENTER_MANIFOLD_INVALID';
    fit.runtime_sec = toc(timer);
    return;
end
P = eye(numel(g),'like',g)-(g*g')/energy;
R = P*Z_white;
B = P*[derivatives.azimuth derivatives.elevation];
T = real(B'*B);
SR = R*R'/size(R,2);
Ct = real(B'*SR*B);
direction = stage8_k2_rtc_projected_direction(T,Ct,constants);
diagnostics.direction = direction;
fit.eig_call_count = 1+double(direction.metric_rank==2);
if ~direction.valid
    fit.fit_status = direction.status;
    fit.runtime_sec = toc(timer);
    return;
end
scale = stage8_k2_rtc_profile_scale_direct(Z_white,model,k1.angles_hat_deg, ...
    direction.direction_hat,local_domain,constants);
diagnostics.scale = scale;
fit.score_call_count = fit.score_call_count+scale.score_call_count;
fit.svd_call_count = fit.svd_call_count+scale.svd_call_count;
fit.fit_status = scale.status;
if scale.valid
    fit.fit_valid = true;
    fit.fit_status = 'RAW_TANGENT_CORE_VALID';
    fit.angles_hat_deg = scale.angles_hat_deg;
    fit.rss = scale.rss;
    fit.loglik_concentrated = scale.loglik_concentrated;
    fit.effective_rank = scale.effective_rank;
end
fit.runtime_sec = toc(timer);
end
