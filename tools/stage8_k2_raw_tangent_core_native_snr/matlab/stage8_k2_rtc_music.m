function fit = stage8_k2_rtc_music(data, resources, mode, constants)
% The legacy kernel uses these zero-valued placeholders only for numel-based accounting.
constants.snr_db_values = 0;
constants.profile_ids = 0;
fit = stage8_k2_cb_music(data,resources.entry,resources,mode,size(data,2),constants);
fit.precompute_runtime_sec_amortized = resources.precompute_runtime_sec/1120;
fit.runtime_sec = fit.online_runtime_sec + fit.precompute_runtime_sec_amortized;
end
