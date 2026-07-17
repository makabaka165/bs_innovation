function [T, info] = build_psd_whitener(C, opts)
%BUILD_PSD_WHITENER Build an effective-subspace PSD whitener.

if nargin < 2 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
if ~(isnumeric(C) && ismatrix(C) && ~isempty(C) && ...
        size(C, 1) == size(C, 2) && all(isfinite(C(:))))
    error('build_psd_whitener:Covariance', ...
        'C must be a non-empty finite square numeric matrix.');
end
if ~(isa(C, 'double') || isa(C, 'single'))
    error('build_psd_whitener:FloatingPoint', ...
        'C must use single or double precision.');
end

B = size(C, 1);
C_hermitian = 0.5 * (C + C');
hermitianization_relative_change = norm(C_hermitian - C, 'fro') / ...
    max(norm(C, 'fro'), realmin(class(C)));
[U, eigenvalues] = eig(C_hermitian, 'vector');
eigenvalues = real(eigenvalues);
[eigenvalues, order] = sort(eigenvalues, 'descend');
U = U(:, order);

eigenvalue_scale = max(abs(eigenvalues));
psd_tolerance = opts.psd_tolerance_multiplier * max(B, 1) * ...
    eps(class(C)) * eigenvalue_scale;
if any(eigenvalues < -psd_tolerance)
    error('build_psd_whitener:NotPSD', ...
        'C has an eigenvalue below the relative PSD tolerance.');
end

negative_eigenvalue_count = nnz(eigenvalues < 0);
eigenvalues_clipped = max(eigenvalues, 0);
[effective_rank, threshold, rank_info] = stable_numeric_rank( ...
    eigenvalues_clipped, [B, B], opts.rank_multiplier);
retained = eigenvalues_clipped > threshold;
U_r = U(:, retained);
lambda_r = eigenvalues_clipped(retained);

if effective_rank == 0
    T = zeros(0, B, 'like', C);
    whitening_error = 0;
    status = 'ZERO_RANK';
else
    T = diag(1 ./ sqrt(lambda_r)) * U_r';
    identity_r = eye(effective_rank, 'like', C);
    whitening_error = norm(T * C_hermitian * T' - identity_r, 'fro') / ...
        norm(identity_r, 'fro');
    if effective_rank < B
        status = 'RANK_DEFICIENT';
    else
        status = 'OK';
    end
end

info = struct();
info.rank = effective_rank;
info.input_dimension = B;
info.effective_dimension = effective_rank;
info.eigenvalues = eigenvalues;
info.eigenvalues_clipped = eigenvalues_clipped;
info.retained_eigenvalues = lambda_r;
info.threshold = threshold;
info.relative_threshold = rank_info.relative_threshold;
info.rank_multiplier = opts.rank_multiplier;
info.psd_tolerance = psd_tolerance;
info.psd_tolerance_multiplier = opts.psd_tolerance_multiplier;
info.negative_eigenvalue_count_clipped = negative_eigenvalue_count;
info.hermitianization_relative_change = hermitianization_relative_change;
info.whitening_error = whitening_error;
info.status = status;
info.is_full_rank = effective_rank == B;
info.T_size = size(T);
info.coordinate_model = 'effective_subspace_rows';
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_psd_whitener:Options', 'opts must be a scalar struct.');
end
allowed = {'rank_multiplier', 'psd_tolerance_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_psd_whitener:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'psd_tolerance_multiplier')
    opts.psd_tolerance_multiplier = opts.rank_multiplier;
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('build_psd_whitener:RankMultiplier', ...
        'opts.rank_multiplier must be a positive finite scalar.');
end
if ~(isscalar(opts.psd_tolerance_multiplier) && ...
        isfinite(opts.psd_tolerance_multiplier) && ...
        opts.psd_tolerance_multiplier > 0)
    error('build_psd_whitener:PSDToleranceMultiplier', ...
        'opts.psd_tolerance_multiplier must be a positive finite scalar.');
end
end
