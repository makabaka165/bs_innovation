function [fits, diagnostics] = stage8_k2_rtc_fit_beamspace_methods(Z, model, domain, resources, core, classical)
fits = cell(3,1);
[fits{1},diagnostics] = stage8_k2_rtc_fit_core(Z,model,domain,core);
fits{2} = stage8_k2_cb_full4d_cml(Z,model,domain,'BEAMSPACE',struct(),classical);
fits{3} = stage8_k2_rtc_music(Z,resources,'BEAMSPACE',classical);
end
