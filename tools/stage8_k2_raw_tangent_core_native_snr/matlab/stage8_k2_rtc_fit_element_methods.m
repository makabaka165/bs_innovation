function [fits, diagnostics] = stage8_k2_rtc_fit_element_methods(Y, model, domain, resources, classical, structured, applicable)
assert(islogical(applicable) && numel(applicable)==3);
whitening = struct('whitener',speye(size(Y,1)), ...
    'method','NATIVE_IID_IDENTITY','whitening_error',0);
fits = cell(5,1);
fits{1} = stage8_k2_cb_full4d_cml(Y,model,domain,'ELEMENT',whitening,classical);
fits{2} = stage8_k2_rtc_music(Y,resources,'ELEMENT',classical);
diagnostics = struct('R_vertical',[],'R_fb',[],'elevations',{{}},'conditionals',{{}});
preprocess = 0;
if any(applicable)
    timer = tic;
    factors = struct('W_az',eye(65),'az_whitening_error',0);
    R = stage8_k2_sb_vertical_covariance(Y,factors,structured);
    [Rfb,Rn] = stage8_k2_sb_fbss_covariance(R,eye(32),structured);
    preprocess = toc(timer);
    diagnostics.R_vertical = R;
    diagnostics.R_fb = Rfb;
end
for k = 1:3
    fit = struct('applicable',applicable(k),'fit_valid',false, ...
        'fit_status','NOT_APPLICABLE_EQUAL_ELEVATION', ...
        'angles_hat_deg',NaN(2,2),'rss',NaN,'loglik_concentrated',NaN, ...
        'score_call_count',0,'svd_call_count',0,'eig_call_count',0,'runtime_sec',0);
    if applicable(k)
        switch k
            case 1, elevation = stage8_k2_sb_gfbss_music(Rfb,Rn,model,structured);
            case 2, elevation = stage8_k2_sb_root_music(Rfb,model,structured);
            case 3, elevation = stage8_k2_sb_ls_esprit(Rfb,model,structured);
        end
        fit.fit_status = elevation.fit_status;
        fit.score_call_count = elevation.score_call_count;
        fit.svd_call_count = elevation.svd_call_count;
        fit.eig_call_count = elevation.eig_call_count;
        fit.runtime_sec = preprocess+elevation.runtime_sec;
        diagnostics.elevations{k} = elevation;
        if elevation.fit_valid
            conditional = stage8_k2_sb_conditional_az_cml(Y,elevation.elevations_hat_deg,model,whitening,structured);
            diagnostics.conditionals{k} = conditional;
            fit.fit_valid = conditional.fit_valid;
            fit.fit_status = conditional.fit_status;
            fit.angles_hat_deg = conditional.angles_hat_deg;
            fit.rss = conditional.rss;
            fit.loglik_concentrated = conditional.loglik_concentrated;
            fit.score_call_count = fit.score_call_count+conditional.score_call_count;
            fit.svd_call_count = fit.svd_call_count+conditional.svd_call_count;
            fit.eig_call_count = fit.eig_call_count+conditional.eig_call_count;
            fit.runtime_sec = fit.runtime_sec+conditional.runtime_sec;
        end
    end
    fits{k+2} = fit;
end
end
