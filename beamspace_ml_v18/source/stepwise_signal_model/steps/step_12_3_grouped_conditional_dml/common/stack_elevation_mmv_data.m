function [Zemmv, mapping, info] = stack_elevation_mmv_data(elOut, opts)
%STACK_ELEVATION_MMV_DATA Stack azimuth columns and snapshots as MMV columns.

if nargin < 2 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
[Zel, input_metadata] = normalize_input_local(elOut);
if opts.phase_factor ~= 1 || input_metadata.phase_factor ~= 1
    error('stack_elevation_mmv_data:PhaseFactor', ...
        'The active elevation MMV path requires phase_factor=1.');
end
if ndims(Zel) > 3
    error('stack_elevation_mmv_data:Dimensions', ...
        'Zel must have shape [B_e,Nphi,L] with no range dimension.');
end

B_e = size(Zel, 1);
Nphi = size(Zel, 2);
L = size(Zel, 3);
if B_e < 1 || Nphi < 1 || L < 1 || any(~isfinite(Zel(:)))
    error('stack_elevation_mmv_data:Data', ...
        'Zel must be a non-empty finite numeric array.');
end
Zemmv = reshape(Zel, B_e, Nphi * L);

stacked_column = (1:(Nphi * L)).';
azimuth_column = repmat((1:Nphi).', L, 1);
snapshot_index = repelem((1:L).', Nphi);
snapshot_index = snapshot_index(:);
mapping = table(stacked_column, azimuth_column, snapshot_index);

info = struct();
info.phase_factor = 1;
info.coordinate_space = opts.coordinate_space;
info.B_e = B_e;
info.Nphi = Nphi;
info.L = L;
info.input_size = [B_e, Nphi, L];
info.output_size = size(Zemmv);
info.column_order = 'azimuth_column_fastest_snapshot_next';
info.columns_are_independent_time_snapshots = false;
info.columns_are_mmv_coefficient_observations = true;
end

function [Zel, metadata] = normalize_input_local(elOut)
metadata = struct('phase_factor', 1);
if isnumeric(elOut)
    Zel = elOut;
elseif isstruct(elOut) && isscalar(elOut) && isfield(elOut, 'Zel')
    Zel = elOut.Zel;
    if isfield(elOut, 'phase_factor')
        metadata.phase_factor = elOut.phase_factor;
    end
else
    error('stack_elevation_mmv_data:Input', ...
        'elOut must be numeric Zel or a scalar struct containing Zel.');
end
if ~isnumeric(Zel)
    error('stack_elevation_mmv_data:DataType', 'Zel must be numeric.');
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('stack_elevation_mmv_data:Options', 'opts must be a scalar struct.');
end
allowed = {'phase_factor', 'coordinate_space'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('stack_elevation_mmv_data:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'phase_factor')
    opts.phase_factor = 1;
end
if ~isfield(opts, 'coordinate_space')
    opts.coordinate_space = 'fixed_whitened_elevation_beamspace';
end
if ~(isscalar(opts.phase_factor) && opts.phase_factor == 1)
    error('stack_elevation_mmv_data:PhaseFactorOption', ...
        'opts.phase_factor must equal 1.');
end
if ~(ischar(opts.coordinate_space) || ...
        (isstring(opts.coordinate_space) && isscalar(opts.coordinate_space)))
    error('stack_elevation_mmv_data:CoordinateSpace', ...
        'opts.coordinate_space must be scalar text.');
end
opts.coordinate_space = char(opts.coordinate_space);
end
