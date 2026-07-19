function [valid, details] = validate_stage8_fit_for_lrt(fit, K, expected)
%VALIDATE_STAGE8_FIT_FOR_LRT Apply one validity contract everywhere.

if nargin < 3 || isempty(expected)
    expected = struct();
end
if ~(isscalar(K) && ismember(K, [1, 2]))
    error('validate_stage8_fit_for_lrt:TargetCount', 'K must be 1 or 2.');
end
required = {'K','estimate_returned_flag','converged_flag', ...
    'effective_rank','rss','sigma2_hat','loglik_concentrated', ...
    'fixed_measurement_hash','phase_factor'};
missing = required;
if isstruct(fit) && isscalar(fit)
    missing = required(~isfield(fit, required));
end
checks = struct('contract_complete', isempty(missing), ...
    'target_count', false, 'estimate_returned', false, ...
    'converged', false, 'effective_rank', false, 'rss', false, ...
    'sigma2', false, 'loglik', false, 'phase_factor', false, ...
    'identity', false);
identity_mismatches = strings(0, 1);
if checks.contract_complete
    checks.target_count = isscalar(fit.K) && fit.K == K;
    checks.estimate_returned = islogical(fit.estimate_returned_flag) && ...
        isscalar(fit.estimate_returned_flag) && fit.estimate_returned_flag;
    checks.converged = islogical(fit.converged_flag) && ...
        isscalar(fit.converged_flag) && fit.converged_flag;
    checks.effective_rank = isscalar(fit.effective_rank) && ...
        isfinite(fit.effective_rank) && fit.effective_rank >= K;
    checks.rss = finite_nonnegative_local(fit.rss);
    checks.sigma2 = finite_nonnegative_local(fit.sigma2_hat);
    checks.loglik = isscalar(fit.loglik_concentrated) && ...
        isreal(fit.loglik_concentrated) && isfinite(fit.loglik_concentrated);
    checks.phase_factor = isscalar(fit.phase_factor) && fit.phase_factor == 1;
    identity_fields = {'fixed_measurement_hash','local_domain_hash', ...
        'solver_contract_hash','observation_hash'};
    for field_index = 1:numel(identity_fields)
        field = identity_fields{field_index};
        if isfield(expected, field) && ~isempty(expected.(field))
            if ~isfield(fit, field) || ...
                    ~strcmp(string(fit.(field)), string(expected.(field)))
                identity_mismatches(end + 1, 1) = string(field); %#ok<AGROW>
            end
        end
    end
    checks.identity = isempty(identity_mismatches);
end
values = struct2array(checks);
valid = all(values);
if ~checks.contract_complete
    status = 'FIT_CONTRACT_INCOMPLETE';
elseif ~checks.target_count
    status = 'FIT_TARGET_COUNT_MISMATCH';
elseif ~checks.estimate_returned
    status = 'FIT_NOT_RETURNED';
elseif ~checks.converged
    status = 'SEARCH_NOT_CONVERGED';
elseif ~checks.effective_rank
    status = 'NUMERIC_RANK_DEFICIENT';
elseif ~(checks.rss && checks.sigma2 && checks.loglik)
    status = 'FIT_NUMERIC_INVALID';
elseif ~checks.phase_factor
    status = 'PHASE_FACTOR_MISMATCH';
elseif ~checks.identity
    status = 'FIT_IDENTITY_MISMATCH';
else
    status = 'VALID_FOR_LRT';
end
details = struct('valid_flag', valid, 'status', status, ...
    'checks', checks, 'missing_fields', string(missing(:)), ...
    'identity_mismatches', identity_mismatches, 'required_K', K, ...
    'phase_factor', 1);
end

function pass = finite_nonnegative_local(value)
pass = isscalar(value) && isreal(value) && isfinite(value) && value >= 0;
end
