function observation = stage8_k2_rtc_generate_observation(X, target_db, seed, domain)
signal_energy = norm(X, 'fro')^2;
power = signal_energy / numel(X);
variance = power / 10^(target_db/10);
assert(isfinite(variance) && variance > 0);
stream = RandStream('mt19937ar', 'Seed', seed);
E = (randn(stream, size(X)) + 1i*randn(stream, size(X))) / sqrt(2);
N = sqrt(variance) * E;
Y = X + N;
nominal = 10*log10(signal_energy / (numel(X)*variance));
noise_energy = norm(N, 'fro')^2;
assert(abs(nominal - target_db) <= 1e-12, 'RTC:SNR', 'Nominal SNR formula failed.');
observation = struct('data', Y, 'standard_noise', E, 'noise', N, ...
    'domain', string(domain), 'nominal_snr_db', nominal, ...
    'realized_snr_db', 10*log10(signal_energy/noise_energy), ...
    'signal_average_power', power, 'noise_variance', variance, ...
    'signal_energy', signal_energy, 'noise_energy', noise_energy, ...
    'noise_seed', seed, 'noise_hash', stage8_k2_rtc_hash(E), ...
    'clean_hash', stage8_k2_rtc_hash(X), 'observation_hash', stage8_k2_rtc_hash(Y));
end
