function [noise, debug] = generate_stage8_element_noise( ...
    model, L, sigma2, seed, substream)
%GENERATE_STAGE8_ELEMENT_NOISE Draw auditable complex element-domain noise.

required = {'Rn_elem','element_noise_factorization','W_I','phase_factor'};
if nargin < 5
    substream = [];
end
if ~(isstruct(model) && isscalar(model) && all(isfield(model, required)) && ...
        model.phase_factor == 1)
    error('generate_stage8_element_noise:Model', ...
        'model does not expose the frozen element-noise contract.');
end
if ~(isscalar(L) && isfinite(L) && L >= 1 && L == fix(L))
    error('generate_stage8_element_noise:Snapshots', ...
        'L must be a positive integer.');
end
if ~(isscalar(sigma2) && isreal(sigma2) && isfinite(sigma2) && sigma2 >= 0)
    error('generate_stage8_element_noise:Variance', ...
        'sigma2 must be finite and nonnegative.');
end
if ~(isscalar(seed) && isfinite(seed) && seed >= 0 && seed == fix(seed))
    error('generate_stage8_element_noise:Seed', ...
        'seed must be a nonnegative integer.');
end
if isempty(substream)
    rng_state = rng;
    cleanup = onCleanup(@() rng(rng_state));
    rng(seed, 'twister');
    stream = [];
else
    if ~(isscalar(substream) && isfinite(substream) && ...
            substream >= 1 && substream == fix(substream))
        error('generate_stage8_element_noise:Substream', ...
            'substream must be a positive integer.');
    end
    stream = RandStream('mrg32k3a', 'Seed', seed);
    stream.Substream = substream;
    cleanup = onCleanup(@() delete(stream));
end
factor = model.element_noise_factorization;
N = size(model.W_I, 1);
standard_noise = complex(zeros(N, L));
if isfield(factor, 'factorization_type') && ...
        strcmp(factor.factorization_type, 'SEPARABLE_MATRIX_NORMAL')
    N_el = size(factor.L_el, 1);
    N_az = size(factor.L_az, 1);
    if N_el * N_az ~= N
        error('generate_stage8_element_noise:FactorizationShape', ...
            'The separable factorization does not match the element count.');
    end
    for snapshot_index = 1:L
        E = complex(normal_draw_local(stream, N_el, N_az), ...
            normal_draw_local(stream, N_el, N_az)) / sqrt(2);
        page = factor.L_el * E * factor.L_az';
        standard_noise(:, snapshot_index) = page(:);
    end
else
    Rn = full(model.Rn_elem);
    L_elem = chol(0.5 * (Rn + Rn'), 'lower');
    standard_noise = L_elem * (normal_draw_local(stream, N, L) + ...
        1j * normal_draw_local(stream, N, L)) / sqrt(2);
end
noise = sqrt(sigma2) * standard_noise;
debug = struct('standard_correlated_noise', standard_noise, ...
    'sigma2', sigma2, 'seed', seed, 'substream', substream, ...
    'element_covariance_hash', stage8_stable_hash(model.Rn_elem), ...
    'phase_factor', 1);
clear cleanup
end

function values = normal_draw_local(stream, row_count, column_count)
if isempty(stream)
    values = randn(row_count, column_count);
else
    values = randn(stream, row_count, column_count);
end
end
