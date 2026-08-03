function value = stage8_k2_mc_utc_now()
%STAGE8_K2_MC_UTC_NOW Return a stable UTC timestamp string.

value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"));
end
