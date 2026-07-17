function [data, info] = prepare_elevation_group_mmv_data( ...
    Zel_raw, T_row, T_col, opts)
%PREPARE_ELEVATION_GROUP_MMV_DATA Fix score and recovery MMV coordinates.

if nargin < 4 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_inputs_local(Zel_raw, T_row, T_col);

B_phys = size(Zel_raw, 1);
Nphi = size(Zel_raw, 2);
L = size(Zel_raw, 3);
r_row = size(T_row, 1);
r_col = size(T_col, 1);

Z_left = complex(zeros(r_row, Nphi, L, 'like', Zel_raw));
Z_score = complex(zeros(r_row, r_col, L, 'like', Zel_raw));
for ell = 1:L
    Z_left(:, :, ell) = T_row * Zel_raw(:, :, ell);
    Z_score(:, :, ell) = Z_left(:, :, ell) * T_col';
end

Z_recovery_mmv = reshape(Z_left, r_row, Nphi * L);
Z_score_mmv = reshape(Z_score, r_row, r_col * L);
stacked_column = (1:(Nphi * L)).';
azimuth_column = repmat((1:Nphi).', L, 1);
snapshot_index = kron((1:L).', ones(Nphi, 1));
recovery_mapping = table(stacked_column, azimuth_column, snapshot_index);

identity_col = eye(Nphi, 'like', T_col);
identity_tolerance = max(size(T_col)) * eps(class(T_col)) * ...
    max(1, norm(T_col, 'fro'));
column_whitening_applied = ~isequal(size(T_col), [Nphi, Nphi]) || ...
    norm(T_col - identity_col, 'fro') > identity_tolerance;

data = struct();
data.Z_recovery_mmv = Z_recovery_mmv;
data.Z_score_mmv = Z_score_mmv;
data.recovery_mapping = recovery_mapping;
data.phase_factor = 1;
data.row_whitening_rank = r_row;
data.column_whitening_rank = r_col;
data.column_whitening_applied = column_whitening_applied;
data.column_covariance_model = opts.column_covariance_model;
data.observation_regime = opts.observation_regime;
data.temporal_snapshot_count = L;
data.mmv_physical_column_count = size(Z_recovery_mmv, 2);
data.mmv_score_column_count = size(Z_score_mmv, 2);
data.physical_beam_count = B_phys;

info = struct();
info.phase_factor = 1;
info.row_whitening_rank = r_row;
info.column_whitening_rank = r_col;
info.column_whitening_applied = column_whitening_applied;
info.column_covariance_model = opts.column_covariance_model;
info.observation_regime = opts.observation_regime;
info.temporal_snapshot_count = L;
info.physical_beam_count = B_phys;
info.physical_azimuth_column_count = Nphi;
info.mmv_physical_column_count = size(Z_recovery_mmv, 2);
info.mmv_score_column_count = size(Z_score_mmv, 2);
info.recovery_coordinate_model = ...
    'row_whitened_physical_circumferential_columns';
info.score_coordinate_model = ...
    'row_and_column_whitened_matrix_normal_coordinates';
info.column_order = 'circumferential_column_fastest_snapshot_next';
info.columns_are_independent_time_snapshots = false;
info.columns_are_mmv_coefficient_observations = true;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('prepare_elevation_group_mmv_data:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'phase_factor', 'observation_regime', ...
    'column_covariance_model'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('prepare_elevation_group_mmv_data:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'phase_factor')
    opts.phase_factor = 1;
end
if ~isfield(opts, 'observation_regime')
    opts.observation_regime = 'NOISY_UNCALIBRATED';
end
if ~isfield(opts, 'column_covariance_model')
    opts.column_covariance_model = 'identity';
end
if ~(isscalar(opts.phase_factor) && opts.phase_factor == 1)
    error('prepare_elevation_group_mmv_data:PhaseFactor', ...
        'opts.phase_factor must equal 1.');
end
opts.observation_regime = char(string(opts.observation_regime));
if ~ismember(opts.observation_regime, ...
        {'NOISELESS_STRUCTURAL', 'NOISY_UNCALIBRATED'})
    error('prepare_elevation_group_mmv_data:ObservationRegime', ...
        'Unsupported observation regime: %s', opts.observation_regime);
end
if ~(ischar(opts.column_covariance_model) || ...
        (isstring(opts.column_covariance_model) && ...
        isscalar(opts.column_covariance_model)))
    error('prepare_elevation_group_mmv_data:ColumnCovarianceModel', ...
        'opts.column_covariance_model must be scalar text.');
end
opts.column_covariance_model = char(opts.column_covariance_model);
end

function validate_inputs_local(Zel_raw, T_row, T_col)
if ~(isnumeric(Zel_raw) && ~isempty(Zel_raw) && ndims(Zel_raw) <= 3 && ...
        all(isfinite(Zel_raw(:))) && ...
        (isa(Zel_raw, 'double') || isa(Zel_raw, 'single')))
    error('prepare_elevation_group_mmv_data:Data', ...
        'Zel_raw must be a finite floating-point [B_phys,Nphi,L] array.');
end
B_phys = size(Zel_raw, 1);
Nphi = size(Zel_raw, 2);
if ~(isnumeric(T_row) && ismatrix(T_row) && ~isempty(T_row) && ...
        size(T_row, 2) == B_phys && all(isfinite(T_row(:))) && ...
        strcmp(class(T_row), class(Zel_raw)))
    error('prepare_elevation_group_mmv_data:RowWhitener', ...
        'T_row must be finite and have B_phys columns in the data precision.');
end
if ~(isnumeric(T_col) && ismatrix(T_col) && ~isempty(T_col) && ...
        size(T_col, 2) == Nphi && all(isfinite(T_col(:))) && ...
        strcmp(class(T_col), class(Zel_raw)))
    error('prepare_elevation_group_mmv_data:ColumnWhitener', ...
        'T_col must be finite and have Nphi columns in the data precision.');
end
end
