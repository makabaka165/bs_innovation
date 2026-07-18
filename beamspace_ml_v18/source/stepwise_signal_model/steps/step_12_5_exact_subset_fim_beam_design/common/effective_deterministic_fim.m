function result = effective_deterministic_fim(G, dG, S, sigma2, opts)
%EFFECTIVE_DETERMINISTIC_FIM Eliminate deterministic source amplitudes.

if nargin < 5 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'rank_multiplier'), opts.rank_multiplier = 1; end
if ~(isnumeric(G) && ismatrix(G) && ~isempty(G) && all(isfinite(G(:))))
    error('effective_deterministic_fim:Manifold', ...
        'G must be a finite non-empty matrix.');
end
K = size(G, 2);
if ~(isstruct(dG) && isfield(dG, 'azimuth') && ...
        isfield(dG, 'elevation') && isequal(size(dG.azimuth), size(G)) && ...
        isequal(size(dG.elevation), size(G)))
    error('effective_deterministic_fim:Derivatives', ...
        'dG must contain azimuth and elevation matrices matching G.');
end
if ~(isnumeric(S) && size(S, 1) == K && ~isempty(S) && ...
        all(isfinite(S(:))))
    error('effective_deterministic_fim:Sources', ...
        'S must be a finite K-by-L matrix.');
end
validateattributes(sigma2, {'numeric'}, {'scalar','real','finite','positive'});

[U, singular_matrix, ~] = svd(G, 'econ');
singular_values = diag(singular_matrix);
[rank_G, rank_threshold] = stable_numeric_rank( ...
    singular_values, size(G), opts.rank_multiplier);
parameter_count = 2 * K;
F = zeros(parameter_count, parameter_count);
if rank_G < K
    result = result_local(F, rank_G, 0, singular_values, rank_threshold, ...
        'SUBSET_MANIFOLD_RANK_LOSS');
    result.Q_G = zeros(size(G, 1), 0);
    return;
end
Q_G = U(:, 1:rank_G);
residuals = cell(parameter_count, 1);
for target_index = 1:K
    derivative_columns = {dG.azimuth(:, target_index), ...
        dG.elevation(:, target_index)};
    for dimension = 1:2
        parameter_index = 2 * target_index - 2 + dimension;
        H = derivative_columns{dimension} * S(target_index, :);
        residuals{parameter_index} = H - Q_G * (Q_G' * H);
    end
end
for row_index = 1:parameter_count
    for column_index = row_index:parameter_count
        value = (2 / sigma2) * real(sum(conj(residuals{row_index}(:)) .* ...
            residuals{column_index}(:)));
        F(row_index, column_index) = value;
        F(column_index, row_index) = value;
    end
end
F = 0.5 * (F + F.');
eigenvalues = eig(F, 'vector');
eigenvalues = real(eigenvalues);
negative_tolerance = 512 * max(parameter_count, 1) * eps * ...
    max(norm(F, 2), realmin);
if any(eigenvalues < -negative_tolerance)
    status = 'NUMERICAL_FAILURE';
    rank_F = 0;
else
    eigenvalues = max(eigenvalues, 0);
    [rank_F, ~] = stable_numeric_rank(eigenvalues, size(F), ...
        opts.rank_multiplier);
    if rank_F < parameter_count
        status = 'SUBSET_FIM_RANK_LOSS';
    else
        status = 'FIM_SCENARIO_VALID';
    end
end
result = result_local(F, rank_G, rank_F, singular_values, ...
    rank_threshold, status);
result.residuals = residuals;
result.Q_G = Q_G;
end

function result = result_local(F, rank_G, rank_F, singular_values, ...
    rank_threshold, status)
result = struct('F', F, 'rank_G', rank_G, 'rank_F', rank_F, ...
    'singular_values_G', singular_values, ...
    'rank_threshold_G', rank_threshold, 'status', status, ...
    'parameter_order', 'az1_el1_az2_el2', ...
    'derivative_unit', 'radian', 'residuals', {cell(0, 1)}, ...
    'Q_G', zeros(size(F, 1), 0));
end
