function [lrt, debug] = nested_dml_likelihood_ratio(fit1, fit2, opts)
%NESTED_DML_LIKELIHOOD_RATIO Compute the nonregular adjacent-model LRT.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'tolerance_multiplier')
    opts.tolerance_multiplier = 64;
end
unknown = setdiff(fieldnames(opts), {'tolerance_multiplier'});
if ~isempty(unknown)
    error('nested_dml_likelihood_ratio:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
validate_fit_pair_local(fit1, fit2);
rss1 = normalize_rss_local(fit1.rss, fit2.rss, fit1.n_complex_observations);
rss2 = normalize_rss_local(fit2.rss, fit1.rss, fit1.n_complex_observations);
scale = max(abs([rss1,rss2]));
tau = opts.tolerance_multiplier * fit1.n_complex_observations * eps(scale);
nested_pass = rss2 <= rss1 + tau;
if rss1 > 0 && rss2 > 0
    lambda = 2 * fit1.n_complex_observations * log(rss1 / rss2);
else
    lambda = NaN;
end
if ~nested_pass
    status = 'NESTED_RSS_VIOLATION';
elseif ~isfinite(lambda)
    status = 'LRT_UNDEFINED_ZERO_RSS';
else
    status = 'OK';
end
lrt = struct('rss1', rss1, 'rss2', rss2, ...
    'n_complex_observations', fit1.n_complex_observations, ...
    'lambda_12', lambda, 'nested_rss_tolerance', tau, ...
    'nested_rss_pass', nested_pass, 'lrt_status', status);
debug = struct('effective_whitening_dimension', ...
    fit1.effective_whitening_dimension, ...
    'snapshot_count', fit1.snapshot_count, ...
    'lambda_from_loglik_difference', ...
    2 * (fit2.loglik_concentrated - fit1.loglik_concentrated), ...
    'threshold_role', 'LOCKED_BOOTSTRAP_LOOKUP_ONLY', ...
    'ordinary_chi_square_role', 'DIAGNOSTIC_ONLY', 'phase_factor', 1);
end

function validate_fit_pair_local(fit1, fit2)
required = {'K','rss','loglik_concentrated','n_complex_observations', ...
    'effective_whitening_dimension','snapshot_count','observation_hash', ...
    'fixed_measurement_hash','local_domain_hash','solver_contract_hash', ...
    'phase_factor'};
if ~(isstruct(fit1) && isscalar(fit1) && all(isfield(fit1, required)) && ...
        isstruct(fit2) && isscalar(fit2) && all(isfield(fit2, required)))
    error('nested_dml_likelihood_ratio:FitContract', ...
        'Both fits must expose the frozen Stage8 identity fields.');
end
if fit1.K ~= 1 || fit2.K ~= 2
    error('nested_dml_likelihood_ratio:TargetCount', ...
        'The adjacent comparison must be K1 versus K2.');
end
[valid1, validity1] = validate_stage8_fit_for_lrt(fit1, 1, struct());
expected = struct('fixed_measurement_hash', fit1.fixed_measurement_hash, ...
    'local_domain_hash', fit1.local_domain_hash, ...
    'solver_contract_hash', fit1.solver_contract_hash, ...
    'observation_hash', fit1.observation_hash);
[valid2, validity2] = validate_stage8_fit_for_lrt(fit2, 2, expected);
if ~(valid1 && valid2)
    error('nested_dml_likelihood_ratio:InvalidFit', ...
        'K1/K2 validity failed: %s/%s.', ...
        validity1.status, validity2.status);
end
text_fields = {'observation_hash','fixed_measurement_hash', ...
    'local_domain_hash','solver_contract_hash'};
for index = 1:numel(text_fields)
    field = text_fields{index};
    if ~strcmp(fit1.(field), fit2.(field))
        error('nested_dml_likelihood_ratio:IdentityMismatch', ...
            'K1 and K2 differ in %s.', field);
    end
end
if fit1.n_complex_observations ~= fit2.n_complex_observations || ...
        fit1.effective_whitening_dimension ~= ...
        fit2.effective_whitening_dimension || ...
        fit1.snapshot_count ~= fit2.snapshot_count || ...
        fit1.phase_factor ~= 1 || fit2.phase_factor ~= 1
    error('nested_dml_likelihood_ratio:DimensionMismatch', ...
        'K1 and K2 must share Z, W, T, domain, solver, and dimensions.');
end
end

function rss = normalize_rss_local(value, peer, count)
if ~(isscalar(value) && isreal(value) && isfinite(value))
    error('nested_dml_likelihood_ratio:RSS', 'RSS must be finite and real.');
end
if value >= 0
    rss = value;
    return;
end
tolerance = 64 * max(count, 1) * eps(max(abs([value,peer])));
if value < -tolerance
    error('nested_dml_likelihood_ratio:NegativeRSS', ...
        'RSS is negative beyond machine precision.');
end
rss = 0;
end
