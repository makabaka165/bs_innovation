function [Xphi, Ce_hat, debug] = recover_group_azimuth_data( ...
    Zemmv, Ge_hat, mapping, opts)
%RECOVER_GROUP_AZIMUTH_DATA Recover one circumferential data matrix per group.

if nargin < 4 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_inputs_local(Zemmv, Ge_hat);
[Nphi, L] = validate_mapping_local(mapping, size(Zemmv, 2));
Q = size(Ge_hat, 2);

[Ce_hat, solve_info] = stable_svd_solve( ...
    Ge_hat, Zemmv, Q, opts.rank_multiplier);
[rank_Ce_hat, singular_values_Ce_hat, threshold_Ce_hat] = ...
    stable_matrix_rank(Ce_hat, opts.rank_multiplier);

Xphi = cell(Q, 1);
for q = 1:Q
    X_now = complex(zeros(Nphi, L, 'like', Ce_hat));
    linear_index = sub2ind([Nphi, L], ...
        mapping.azimuth_column, mapping.snapshot_index);
    X_now(linear_index) = Ce_hat(q, mapping.stacked_column).';
    Xphi{q} = X_now;
end

relative_fro_error_by_group = NaN(Q, 1);
subspace_chordal_distance_by_group = NaN(Q, 1);
subspace_rank_estimate = NaN(Q, 1);
subspace_rank_truth = NaN(Q, 1);
num_svd_error_metrics = 0;
if ~isempty(opts.true_Ce)
    if ~isequal(size(opts.true_Ce), size(Ce_hat)) || ...
            any(~isfinite(opts.true_Ce(:)))
        error('recover_group_azimuth_data:TrueCoefficient', ...
            'opts.true_Ce must be finite and match size(Ce_hat).');
    end
    for q = 1:Q
        X_true = complex(zeros(Nphi, L, 'like', opts.true_Ce));
        linear_index = sub2ind([Nphi, L], ...
            mapping.azimuth_column, mapping.snapshot_index);
        X_true(linear_index) = opts.true_Ce(q, mapping.stacked_column).';
        relative_fro_error_by_group(q) = norm(Xphi{q} - X_true, 'fro') / ...
            max(norm(X_true, 'fro'), realmin(class(X_true)));
        [subspace_chordal_distance_by_group(q), subspace_info] = ...
            subspace_chordal_distance( ...
            Xphi{q}(:), X_true(:), opts.rank_multiplier);
        subspace_rank_estimate(q) = subspace_info.rank_a;
        subspace_rank_truth(q) = subspace_info.rank_b;
        num_svd_error_metrics = num_svd_error_metrics + subspace_info.num_svd;
    end
    overall_relative_fro_error = norm(Ce_hat - opts.true_Ce, 'fro') / ...
        max(norm(opts.true_Ce, 'fro'), realmin(class(opts.true_Ce)));
else
    overall_relative_fro_error = NaN;
end

crosstalk_matrix = NaN(Q, Q);
max_offdiagonal_crosstalk = NaN;
diagonal_mixing_error = NaN;
num_svd_crosstalk = 0;
if ~isempty(opts.true_Ge)
    if ~isequal(size(opts.true_Ge), size(Ge_hat)) || ...
            any(~isfinite(opts.true_Ge(:)))
        error('recover_group_azimuth_data:TrueManifold', ...
            'opts.true_Ge must be finite and match size(Ge_hat).');
    end
    [mixing, mixing_info] = stable_svd_solve( ...
        Ge_hat, opts.true_Ge, Q, opts.rank_multiplier);
    crosstalk_matrix = abs(mixing);
    off_diagonal = crosstalk_matrix;
    off_diagonal(1:(Q + 1):end) = 0;
    max_offdiagonal_crosstalk = max(off_diagonal(:));
    diagonal_mixing_error = max(abs(diag(mixing) - 1));
    num_svd_crosstalk = mixing_info.num_svd;
end

status = 'GROUP_IDENTIFIABLE';
reason = 'group_data_recovered_on_full_rank_model';
if solve_info.effective_rank < Q || rank_Ce_hat < Q
    status = 'GROUP_UNIDENTIFIABLE';
    reason = 'manifold_or_recovered_coefficient_rank_below_group_count';
end

debug = struct();
debug.status = status;
debug.reason = reason;
debug.phase_factor = 1;
debug.Q = Q;
debug.Nphi = Nphi;
debug.L = L;
debug.rank_Ge = solve_info.effective_rank;
debug.singular_values_Ge = solve_info.singular_values;
debug.rank_threshold_Ge = solve_info.rank_threshold;
debug.rank_Ce_hat = rank_Ce_hat;
debug.singular_values_Ce_hat = singular_values_Ce_hat;
debug.rank_threshold_Ce_hat = threshold_Ce_hat;
debug.relative_fro_error_by_group = relative_fro_error_by_group;
debug.overall_relative_fro_error = overall_relative_fro_error;
debug.subspace_chordal_distance_by_group = ...
    subspace_chordal_distance_by_group;
debug.subspace_rank_estimate = subspace_rank_estimate;
debug.subspace_rank_truth = subspace_rank_truth;
debug.crosstalk_matrix = crosstalk_matrix;
debug.max_offdiagonal_crosstalk = max_offdiagonal_crosstalk;
debug.diagonal_mixing_error = diagonal_mixing_error;
debug.num_svd = solve_info.num_svd + 1 + ...
    num_svd_error_metrics + num_svd_crosstalk;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('recover_group_azimuth_data:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier', 'true_Ce', 'true_Ge'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('recover_group_azimuth_data:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'true_Ce')
    opts.true_Ce = [];
end
if ~isfield(opts, 'true_Ge')
    opts.true_Ge = [];
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('recover_group_azimuth_data:RankMultiplier', ...
        'opts.rank_multiplier must be positive and finite.');
end
end

function validate_inputs_local(Z, G)
if ~(isnumeric(Z) && ismatrix(Z) && ~isempty(Z) && all(isfinite(Z(:))))
    error('recover_group_azimuth_data:Data', ...
        'Zemmv must be a non-empty finite matrix.');
end
if ~(isnumeric(G) && ismatrix(G) && ~isempty(G) && ...
        size(G, 1) == size(Z, 1) && all(isfinite(G(:))))
    error('recover_group_azimuth_data:Manifold', ...
        'Ge_hat must be finite and have the same row count as Zemmv.');
end
end

function [Nphi, L] = validate_mapping_local(mapping, num_columns)
required = {'stacked_column', 'azimuth_column', 'snapshot_index'};
if ~istable(mapping) || ~all(ismember(required, mapping.Properties.VariableNames))
    error('recover_group_azimuth_data:Mapping', ...
        'mapping must contain stacked_column, azimuth_column, and snapshot_index.');
end
if height(mapping) ~= num_columns || ...
        ~isequal(mapping.stacked_column(:), (1:num_columns).') || ...
        any(mapping.azimuth_column < 1) || any(mapping.snapshot_index < 1) || ...
        any(mapping.azimuth_column ~= fix(mapping.azimuth_column)) || ...
        any(mapping.snapshot_index ~= fix(mapping.snapshot_index))
    error('recover_group_azimuth_data:MappingValues', ...
        'mapping must describe every stacked column exactly once.');
end
Nphi = max(mapping.azimuth_column);
L = max(mapping.snapshot_index);
pairs = unique([mapping.azimuth_column, mapping.snapshot_index], 'rows');
if size(pairs, 1) ~= num_columns || Nphi * L ~= num_columns
    error('recover_group_azimuth_data:MappingCoverage', ...
        'mapping must cover a rectangular Nphi-by-L coefficient array.');
end
end
