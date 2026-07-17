function [metric, debug] = compute_projected_jacobian_metric(g, Jg, opts)
%COMPUTE_PROJECTED_JACOBIAN_METRIC Compute the projected real metric.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
if ~(isnumeric(g) && iscolumn(g) && ~isempty(g) && all(isfinite(g))) || ...
        ~(isnumeric(Jg) && isequal(size(Jg), [numel(g), 2]) && ...
        all(isfinite(Jg(:))))
    error('compute_projected_jacobian_metric:Inputs', ...
        'g and Jg must be finite with sizes B-by-1 and B-by-2.');
end
g_energy = real(g' * g);
if g_energy <= opts.center_zero_multiplier * eps(class(g)) * numel(g)
    error('compute_projected_jacobian_metric:ZeroCenter', ...
        'The center manifold is numerically zero.');
end

Pg_perp = eye(numel(g), 'like', g) - (g * g') / g_energy;
T_raw = real(Jg' * Pg_perp * Jg);
T = 0.5 * (T_raw + T_raw.');
[eigenvectors, eigenvalues] = eig(T, 'vector');
[eigenvalues, order] = sort(real(eigenvalues), 'ascend');
eigenvectors = eigenvectors(:, order);
lambda_scale = max(abs(eigenvalues));
negative_tolerance = opts.negative_tolerance_multiplier * max(size(T)) * ...
    eps(class(T)) * max(norm(T, 2), realmin(class(T)));
if any(eigenvalues < -negative_tolerance)
    error('compute_projected_jacobian_metric:NegativeEigenvalue', ...
        'The projected metric has a negative eigenvalue beyond roundoff.');
end
[rank_T, rank_threshold] = stable_numeric_rank(max(eigenvalues, 0), ...
    size(T), opts.rank_multiplier);
lambda_max = max(eigenvalues);
lambda_min = min(eigenvalues);
null_tolerance = opts.null_tolerance_multiplier * max(size(T)) * ...
    eps(class(T)) * max(lambda_max, realmin(class(T)));
if lambda_min <= null_tolerance
    tangent_class = 'EXACT_TANGENT_NULL';
elseif lambda_min / lambda_max < opts.near_null_ratio
    tangent_class = 'NEAR_TANGENT_NULL';
else
    tangent_class = 'NONDEGENERATE_TANGENT';
end
positive = eigenvalues(eigenvalues > rank_threshold);
if numel(positive) < 2
    condition_T = Inf;
else
    condition_T = max(positive) / min(positive);
end

metric = struct();
metric.Pg_perp = Pg_perp;
metric.T = T;
metric.eigenvalues = eigenvalues;
metric.eigenvectors = eigenvectors;
metric.rank_T = rank_T;
metric.condition_T = condition_T;
metric.trace_T = trace(T);
metric.min_eigenvalue = lambda_min;
metric.max_eigenvalue = lambda_max;
metric.negative_eigenvalue_tolerance = negative_tolerance;
metric.null_tolerance = null_tolerance;
metric.tangent_class = tangent_class;
metric.phase_factor = 1;

debug = struct();
debug.hermitian_error = norm(Pg_perp - Pg_perp', 'fro');
debug.idempotence_error = norm(Pg_perp * Pg_perp - Pg_perp, 'fro');
debug.projected_center_error = norm(Pg_perp * g) / norm(g);
debug.T_symmetry_error = norm(T - T.', 'fro');
debug.rank_threshold = rank_threshold;
debug.lambda_scale = lambda_scale;
debug.phase_factor = 1;
end

function opts = normalize_options_local(opts)
allowed = {'rank_multiplier','negative_tolerance_multiplier', ...
    'null_tolerance_multiplier','near_null_ratio','center_zero_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('compute_projected_jacobian_metric:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
defaults = struct('rank_multiplier', 1, ...
    'negative_tolerance_multiplier', 64, ...
    'null_tolerance_multiplier', 256, ...
    'near_null_ratio', 1e-6, 'center_zero_multiplier', 256);
names = fieldnames(defaults);
for index = 1:numel(names)
    if ~isfield(opts, names{index})
        opts.(names{index}) = defaults.(names{index});
    end
end
end
