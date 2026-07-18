function result = relative_fim_retention(F_reference, F_candidate, opts)
%RELATIVE_FIM_RETENTION Compute generalized retention on reference support.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'rank_multiplier'), opts.rank_multiplier = 1; end
if ~isfield(opts, 'expected_rank'), opts.expected_rank = size(F_reference, 1); end
if ~(isnumeric(F_reference) && ismatrix(F_reference) && ...
        isequal(size(F_reference), size(F_candidate)) && ...
        size(F_reference, 1) == size(F_reference, 2) && ...
        all(isfinite(F_reference(:))) && all(isfinite(F_candidate(:))))
    error('relative_fim_retention:Shape', ...
        'Reference and candidate FIMs must be finite equal square matrices.');
end
F_reference = 0.5 * (real(F_reference) + real(F_reference).');
F_candidate = 0.5 * (real(F_candidate) + real(F_candidate).');
[U, lambda] = eig(F_reference, 'vector');
lambda = real(lambda);
[lambda, order] = sort(lambda, 'descend');
U = U(:, order);
scale = max(max(abs(lambda)), realmin);
negative_tolerance = 512 * max(size(F_reference)) * eps * scale;
if any(lambda < -negative_tolerance)
    result = failure_local('NUMERICAL_FAILURE', lambda);
    return;
end
lambda = max(lambda, 0);
[rank_reference, threshold] = stable_numeric_rank(lambda, ...
    size(F_reference), opts.rank_multiplier);
if rank_reference < opts.expected_rank
    result = failure_local('ELEMENT_REFERENCE_UNIDENTIFIABLE', lambda);
    result.rank_reference = rank_reference;
    result.rank_threshold = threshold;
    return;
end
retained = lambda > threshold;
U_r = U(:, retained);
lambda_r = lambda(retained);
B = diag(1 ./ sqrt(lambda_r)) * (U_r' * F_candidate * U_r) * ...
    diag(1 ./ sqrt(lambda_r));
B = 0.5 * (B + B.');
retention_eigenvalues = sort(real(eig(B, 'vector')), 'ascend');
eta_tolerance = 4096 * max(size(B)) * eps * ...
    max(1, norm(B, 2));
if min(retention_eigenvalues) < -eta_tolerance
    status = 'NUMERICAL_FAILURE';
    eta = NaN;
else
    retention_eigenvalues(abs(retention_eigenvalues) <= eta_tolerance) = 0;
    eta = min(retention_eigenvalues);
    status = 'FIM_SCENARIO_VALID';
end
result = struct('eta', eta, 'B', B, ...
    'generalized_eigenvalues', retention_eigenvalues, ...
    'reference_eigenvalues', lambda, 'rank_reference', rank_reference, ...
    'rank_threshold', threshold, 'status', status);
end

function result = failure_local(status, lambda)
result = struct('eta', NaN, 'B', zeros(0), ...
    'generalized_eigenvalues', zeros(0, 1), ...
    'reference_eigenvalues', lambda, 'rank_reference', 0, ...
    'rank_threshold', NaN, 'status', status);
end
