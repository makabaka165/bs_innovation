function [S, info] = construct_deterministic_source_matrix( ...
    K, L, secondary_power_db, correlation_magnitude, ...
    correlation_phase_rad, profile_id)
%CONSTRUCT_DETERMINISTIC_SOURCE_MATRIX Build the registered source matrix.

validateattributes(K, {'numeric'}, {'scalar','integer','>=',1,'<=',2});
validateattributes(L, {'numeric'}, {'scalar','integer','positive'});
validateattributes(secondary_power_db, {'numeric'}, {'scalar','real','finite'});
validateattributes(correlation_magnitude, {'numeric'}, ...
    {'scalar','real','finite','>=',0,'<=',1});
validateattributes(correlation_phase_rad, {'numeric'}, ...
    {'scalar','real','finite'});
if ~(ischar(profile_id) || (isstring(profile_id) && isscalar(profile_id)))
    error('construct_deterministic_source_matrix:Profile', ...
        'profile_id must be text.');
end

q1 = ones(1, L) / sqrt(L);
if K == 1
    S = sqrt(L) * q1;
    gamma = NaN;
    rho = NaN;
elseif L == 1
    if abs(correlation_magnitude - 1) > 64 * eps
        error('construct_deterministic_source_matrix:L1Correlation', ...
            'L=1 only permits fully coherent sources.');
    end
    gamma = 10 ^ (secondary_power_db / 10);
    p1 = 1 / (1 + gamma);
    p2 = gamma / (1 + gamma);
    rho = correlation_magnitude * exp(1j * correlation_phase_rad);
    S = [sqrt(L * p1); sqrt(L * p2) * conj(rho)];
else
    gamma = 10 ^ (secondary_power_db / 10);
    p1 = 1 / (1 + gamma);
    p2 = gamma / (1 + gamma);
    q2 = exp(1j * 2 * pi * (0:L - 1) / L) / sqrt(L);
    rho = correlation_magnitude * exp(1j * correlation_phase_rad);
    s1 = sqrt(L * p1) * q1;
    s2 = sqrt(L * p2) * (conj(rho) * q1 + ...
        sqrt(max(0, 1 - abs(rho) ^ 2)) * q2);
    S = [s1; s2];
end

energy_error = abs(norm(S, 'fro') ^ 2 - L) / L;
if K == 2
    power_ratio = norm(S(2, :)) ^ 2 / norm(S(1, :)) ^ 2;
    measured_rho = S(1, :) * S(2, :)' / ...
        (norm(S(1, :)) * norm(S(2, :)));
    power_error = abs(power_ratio - gamma) / max(gamma, realmin);
    correlation_error = abs(measured_rho - rho);
else
    power_ratio = NaN;
    measured_rho = NaN;
    power_error = 0;
    correlation_error = 0;
end
if max([energy_error, power_error, correlation_error]) > 1e-12
    error('construct_deterministic_source_matrix:Invariant', ...
        'The deterministic source invariants failed.');
end
info = struct('profile_id', char(profile_id), 'K', K, 'L', L, ...
    'secondary_power_ratio', power_ratio, 'target_rho', rho, ...
    'measured_rho', measured_rho, 'energy_relative_error', energy_error, ...
    'power_relative_error', power_error, ...
    'correlation_absolute_error', correlation_error);
end
