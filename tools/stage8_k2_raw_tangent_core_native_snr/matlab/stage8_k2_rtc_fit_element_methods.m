function [fits, diagnostics] = stage8_k2_rtc_fit_element_methods(Y, model, domain, classical, structured, applicable)
assert(islogical(applicable) && isscalar(applicable) && applicable);
whitening = struct('whitener',speye(size(Y,1)), ...
    'method','NATIVE_IID_IDENTITY','whitening_error',0);
fits = cell(2,1);
fits{1} = stage8_k2_cb_full4d_cml(Y,model,domain,'ELEMENT',whitening,classical);
timer = tic;
factors = struct('W_az',eye(65),'az_whitening_error',0);
R = stage8_k2_sb_vertical_covariance(Y,factors,structured);
Rfb = stage8_k2_sb_fbss_covariance(R,eye(32),structured);
preprocess = toc(timer);
elevation = stage8_k2_sb_root_music(Rfb,model,structured);
diagnostics = struct('R_vertical',R,'R_fb',Rfb, ...
    'elevation',elevation,'conditional',[]);
fit = struct('applicable',applicable,'fit_valid',false, ...
    'fit_status',elevation.fit_status,'angles_hat_deg',NaN(2,2), ...
    'rss',NaN,'loglik_concentrated',NaN, ...
    'score_call_count',elevation.score_call_count, ...
    'svd_call_count',elevation.svd_call_count,'eig_call_count',elevation.eig_call_count, ...
    'runtime_sec',preprocess+elevation.runtime_sec, ...
    'elevation_valid',elevation.fit_valid,'elevation_status',elevation.fit_status, ...
    'conditional_valid',false,'conditional_status','NOT_RUN_INVALID_ELEVATION');
if elevation.fit_valid
    conditional = stage8_k2_sb_conditional_az_cml(Y,elevation.elevations_hat_deg,model,whitening,structured);
    diagnostics.conditional = conditional;
    fit.fit_valid = conditional.fit_valid;
    fit.fit_status = conditional.fit_status;
    fit.angles_hat_deg = conditional.angles_hat_deg;
    fit.rss = conditional.rss;
    fit.loglik_concentrated = conditional.loglik_concentrated;
    fit.score_call_count = fit.score_call_count+conditional.score_call_count;
    fit.svd_call_count = fit.svd_call_count+conditional.svd_call_count;
    fit.eig_call_count = fit.eig_call_count+conditional.eig_call_count;
    fit.runtime_sec = fit.runtime_sec+conditional.runtime_sec;
    fit.conditional_valid = conditional.fit_valid;
    fit.conditional_status = conditional.fit_status;
end
fits{2} = fit;
end
