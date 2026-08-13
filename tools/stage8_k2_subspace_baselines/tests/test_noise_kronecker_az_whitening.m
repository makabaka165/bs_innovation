function result = test_noise_kronecker_az_whitening(context)
%TEST_NOISE_KRONECKER_AZ_WHITENING Verify white and colored factorization.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
errors = zeros(numel(context.models), 2);
for index = 1:numel(context.models)
    model = context.models(index).model;
    factors = context.models(index).noise_factors;
    expected = kron(factors.R_az, factors.R_el);
    errors(index, 1) = norm(full(model.Rn_elem) - expected, 'fro') / ...
        max(1, norm(expected, 'fro'));
    whitened_factor = factors.W_az * factors.R_az * factors.W_az';
    factorized_lhs = kron(whitened_factor, factors.R_el);
    factorized_rhs = kron(eye(context.constants.N_az), factors.R_el);
    errors(index, 2) = norm(factorized_lhs - factorized_rhs, 'fro') / ...
        max(1, norm(factorized_rhs, 'fro'));
end
assert(max(errors, [], 'all') <= ...
    context.constants.factorization_tolerance, ...
    'test_noise_kronecker_az_whitening:Residual', ...
    'Noise Kronecker factorization or azimuth whitening failed.');
result = struct('pass', true, 'residuals', errors);
end

function [context, cleanup] = context_local(context)
cleanup = [];
if nargin < 1 || isempty(context)
    test_dir = fileparts(mfilename('fullpath'));
    repo_dir = fileparts(fileparts(fileparts(test_dir)));
    cleanup = stage8_k2_sb_add_paths(repo_dir);
    context = stage8_k2_sb_build_context(repo_dir);
end
end
