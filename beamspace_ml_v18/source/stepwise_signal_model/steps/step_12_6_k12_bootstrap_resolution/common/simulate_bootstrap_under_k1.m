function [full_data_boot, debug] = simulate_bootstrap_under_k1( ...
    fit1, model_or_opts, opts)
%SIMULATE_BOOTSTRAP_UNDER_K1 Route formal samples through element space.

if nargin < 2
    model_or_opts = struct();
end
if nargin < 3
    opts = model_or_opts;
    model = [];
else
    model = model_or_opts;
end
if isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'seed')
    error('simulate_bootstrap_under_k1:Seed', ...
        'opts.seed must come from the locked Stage8 calibration plan.');
end
unknown = setdiff(fieldnames(opts), {'seed','formal_run'});
if ~isempty(unknown)
    error('simulate_bootstrap_under_k1:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'formal_run')
    opts.formal_run = false;
end
if ~isempty(model)
    [full_data_boot, debug] = simulate_stage8_element_bootstrap( ...
        fit1, model, struct('seed', opts.seed, ...
        'formal_run', opts.formal_run));
    debug.K1_refit_required_flag = true;
    debug.K2_refit_required_flag = true;
    return;
end
if opts.formal_run
    error('simulate_bootstrap_under_k1:FormalElementModel', ...
        'Formal K1 bootstrap requires the resolved element measurement model.');
end
required = {'K','G_hat','S_hat','sigma2_hat','estimate_returned_flag', ...
    'fixed_measurement_hash','effective_whitening_dimension', ...
    'snapshot_count','phase_factor'};
if ~(isstruct(fit1) && isscalar(fit1) && all(isfield(fit1, required)) && ...
        fit1.K == 1 && fit1.estimate_returned_flag && fit1.phase_factor == 1)
    error('simulate_bootstrap_under_k1:Fit', ...
        'fit1 must be a returned phase_factor=1 K1 fit.');
end
if ~(isscalar(fit1.sigma2_hat) && isreal(fit1.sigma2_hat) && ...
        isfinite(fit1.sigma2_hat) && fit1.sigma2_hat >= 0)
    error('simulate_bootstrap_under_k1:Variance', ...
        'The fitted K1 variance must be finite and nonnegative.');
end
rng_state = rng;
cleanup = onCleanup(@() rng(rng_state));
rng(opts.seed, 'twister');
noise = (randn(fit1.effective_whitening_dimension, fit1.snapshot_count) + ...
    1j * randn(fit1.effective_whitening_dimension, fit1.snapshot_count)) / sqrt(2);
fitted_mean = fit1.G_hat * fit1.S_hat;
Z_boot = fitted_mean + sqrt(fit1.sigma2_hat) * noise;
full_data_boot = struct('Zseq_white', Z_boot, ...
    'fixed_measurement_hash', fit1.fixed_measurement_hash, ...
    'phase_factor', 1, 'bootstrap_seed', opts.seed, ...
    'bootstrap_source', 'SYNTHETIC_TEST_WHITENED_COORDINATES');
debug = struct('seed', opts.seed, 'fitted_mean', fitted_mean, ...
    'standard_complex_noise', noise, 'sigma2_hat', fit1.sigma2_hat, ...
    'K1_refit_required_flag', true, 'K2_refit_required_flag', true, ...
    'fixed_measurement_hash', fit1.fixed_measurement_hash, ...
    'phase_factor', 1);
clear cleanup
end
