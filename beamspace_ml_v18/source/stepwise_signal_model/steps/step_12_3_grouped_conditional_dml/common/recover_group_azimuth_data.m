function [Xphi, Ce_hat, debug] = recover_group_azimuth_data( ...
    data, Ge_hat, opts)
%RECOVER_GROUP_AZIMUTH_DATA Recover physical circumferential group data.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
[Z_recovery_mmv, mapping, Nphi, L] = validate_data_local(data);
validate_manifold_local(Ge_hat, size(Z_recovery_mmv, 1));
Q = size(Ge_hat, 2);

[Ce_hat, solve_info] = stable_svd_solve( ...
    Ge_hat, Z_recovery_mmv, Q, opts.rank_multiplier);
[rank_Ce_hat, singular_values_Ce_hat, threshold_Ce_hat] = ...
    stable_matrix_rank(Ce_hat, opts.rank_multiplier);

Xphi = cell(Q, 1);
linear_index = sub2ind([Nphi, L], ...
    mapping.azimuth_column, mapping.snapshot_index);
for q = 1:Q
    X_now = complex(zeros(Nphi, L, 'like', Ce_hat));
    X_now(linear_index) = Ce_hat(q, mapping.stacked_column).';
    Xphi{q} = X_now;
end

solve_status = 'RECOVERY_RETURNED';
recovery_returned_flag = true;
if solve_info.effective_rank < Q
    solve_status = 'RECOVERY_NOT_RUN_MANIFOLD_RANK_FAILURE';
    recovery_returned_flag = false;
end

debug = struct();
debug.solve_status = solve_status;
debug.recovery_returned_flag = recovery_returned_flag;
debug.statistical_calibration_status = 'NOT_CALIBRATED_STAGE4';
debug.phase_factor = 1;
debug.Q = Q;
debug.Nphi = Nphi;
debug.L = L;
debug.recovery_coordinate_model = ...
    'row_whitened_physical_circumferential_columns';
debug.column_whitening_used_for_recovery_flag = false;
debug.rank_Ge = solve_info.effective_rank;
debug.singular_values_Ge = solve_info.singular_values;
debug.rank_threshold_Ge = solve_info.rank_threshold;
debug.rank_Ce_hat_diagnostic = rank_Ce_hat;
debug.singular_values_Ce_hat_diagnostic = singular_values_Ce_hat;
debug.rank_threshold_Ce_hat_diagnostic = threshold_Ce_hat;
debug.num_svd = solve_info.num_svd + 1;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('recover_group_azimuth_data:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('recover_group_azimuth_data:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('recover_group_azimuth_data:RankMultiplier', ...
        'opts.rank_multiplier must be positive and finite.');
end
end

function [Z, mapping, Nphi, L] = validate_data_local(data)
required = {'Z_recovery_mmv', 'recovery_mapping', 'phase_factor'};
allowed = {'Z_score_mmv', 'Z_recovery_mmv', 'recovery_mapping', ...
    'phase_factor', 'row_whitening_rank', 'column_whitening_rank', ...
    'column_whitening_applied', 'column_covariance_model', ...
    'observation_regime', 'temporal_snapshot_count', ...
    'mmv_physical_column_count', 'mmv_score_column_count', ...
    'physical_beam_count'};
if ~(isstruct(data) && isscalar(data) && ...
        all(isfield(data, required)))
    error('recover_group_azimuth_data:DataBundle', ...
        'data must contain Z_recovery_mmv, recovery_mapping, and phase_factor.');
end
unknown = setdiff(fieldnames(data), allowed);
if ~isempty(unknown)
    error('recover_group_azimuth_data:UnknownDataField', ...
        'Unknown data field: %s', unknown{1});
end
if data.phase_factor ~= 1
    error('recover_group_azimuth_data:PhaseFactor', ...
        'The active recovery path requires phase_factor=1.');
end
Z = data.Z_recovery_mmv;
if ~(isnumeric(Z) && ismatrix(Z) && ~isempty(Z) && all(isfinite(Z(:))))
    error('recover_group_azimuth_data:Data', ...
        'data.Z_recovery_mmv must be a non-empty finite matrix.');
end
mapping = data.recovery_mapping;
[Nphi, L] = validate_mapping_local(mapping, size(Z, 2));
end

function validate_manifold_local(G, row_count)
if ~(isnumeric(G) && ismatrix(G) && ~isempty(G) && ...
        size(G, 1) == row_count && all(isfinite(G(:))))
    error('recover_group_azimuth_data:Manifold', ...
        'Ge_hat must be finite and match the recovery-data row count.');
end
end

function [Nphi, L] = validate_mapping_local(mapping, num_columns)
required = {'stacked_column', 'azimuth_column', 'snapshot_index'};
if ~istable(mapping) || ~all(ismember(required, ...
        mapping.Properties.VariableNames))
    error('recover_group_azimuth_data:Mapping', ...
        'The recovery mapping is missing required columns.');
end
if height(mapping) ~= num_columns || ...
        ~isequal(mapping.stacked_column(:), (1:num_columns).') || ...
        any(mapping.azimuth_column < 1) || any(mapping.snapshot_index < 1) || ...
        any(mapping.azimuth_column ~= fix(mapping.azimuth_column)) || ...
        any(mapping.snapshot_index ~= fix(mapping.snapshot_index))
    error('recover_group_azimuth_data:MappingValues', ...
        'The recovery mapping must describe every stacked column once.');
end
Nphi = max(mapping.azimuth_column);
L = max(mapping.snapshot_index);
pairs = unique([mapping.azimuth_column, mapping.snapshot_index], 'rows');
if size(pairs, 1) ~= num_columns || Nphi * L ~= num_columns
    error('recover_group_azimuth_data:MappingCoverage', ...
        'The recovery mapping must cover a rectangular Nphi-by-L array.');
end
end
