function callback = build_stage8_refit_callback(base_fit, angle_samples_deg)
%BUILD_STAGE8_REFIT_CALLBACK Return deterministic fit summaries for CI tests.

callback = @refit_local;
    function fit = refit_local(index, ~)
        fit = base_fit;
        fit.angles_hat_deg = angle_samples_deg(:, :, index);
        fit.estimate_returned_flag = true;
        fit.converged_flag = true;
        fit.effective_rank = 2;
    end
end
