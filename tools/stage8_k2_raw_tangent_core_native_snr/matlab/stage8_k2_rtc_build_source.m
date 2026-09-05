function [source, info] = stage8_k2_rtc_build_source(spec)
stream = RandStream('mt19937ar', 'Seed', spec.source_seed);
phase = 2*pi*rand(stream);
[source, info] = construct_deterministic_source_matrix(2, spec.L, ...
    spec.secondary_power_db, spec.correlation_magnitude, phase, ...
    sprintf('RTC_BASE_%03d', spec.base_realization_index));
end
