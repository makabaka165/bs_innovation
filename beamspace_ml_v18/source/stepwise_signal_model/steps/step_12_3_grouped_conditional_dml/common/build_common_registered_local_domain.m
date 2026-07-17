function [domain, info] = build_common_registered_local_domain( ...
    conventional_center_deg, opts)
%BUILD_COMMON_REGISTERED_LOCAL_DOMAIN Freeze a method-common physical domain.

if nargin < 2 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
if ~(isnumeric(conventional_center_deg) && isreal(conventional_center_deg) && ...
        isequal(size(conventional_center_deg), [1, 2]) && ...
        all(isfinite(conventional_center_deg)))
    error('build_common_registered_local_domain:Center', ...
        'conventional_center_deg must be one finite [azimuth,elevation] center.');
end

az_grid = conventional_center_deg(1) + opts.azimuth_offsets_deg;
el_grid = conventional_center_deg(2) + opts.elevation_offsets_deg;
[az_mesh, el_mesh] = ndgrid(az_grid, el_grid);
bounds = [min(az_grid), max(az_grid), min(el_grid), max(el_grid)];
domain_hash = stable_object_hash(conventional_center_deg, az_grid, el_grid, ...
    opts.domain_id, opts.domain_source, opts.configuration_hash);

domain = struct();
domain.domain_id = opts.domain_id;
domain.domain_source = opts.domain_source;
domain.conventional_center_deg = conventional_center_deg;
domain.az_grid_deg = az_grid;
domain.el_grid_deg = el_grid;
domain.candidate_points_deg = [az_mesh(:), el_mesh(:)];
domain.domain_bounds_deg = bounds;
domain.domain_bounds = sprintf('[%.12g,%.12g]x[%.12g,%.12g]', bounds);
domain.domain_hash = domain_hash;
domain.grid_step_az_deg = grid_step_local(az_grid);
domain.grid_step_el_deg = grid_step_local(el_grid);
domain.configuration_hash = opts.configuration_hash;
domain.phase_factor = 1;

info = struct();
info.domain_hash = domain_hash;
info.num_azimuth_points = numel(az_grid);
info.num_elevation_points = numel(el_grid);
info.num_physical_points = numel(az_mesh);
info.input_contract = 'conventional_center_and_pre_registered_offsets_only';
info.method_common_flag = true;
info.post_result_expansion_allowed_flag = false;
info.phase_factor = 1;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_common_registered_local_domain:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'azimuth_offsets_deg','elevation_offsets_deg', ...
    'domain_id','domain_source','configuration_hash','phase_factor'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_common_registered_local_domain:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
required = {'azimuth_offsets_deg','elevation_offsets_deg', ...
    'domain_id','domain_source','configuration_hash'};
missing = required(~isfield(opts, required));
if ~isempty(missing)
    error('build_common_registered_local_domain:MissingOption', ...
        'Missing required option: %s.', missing{1});
end
if ~isfield(opts, 'phase_factor')
    opts.phase_factor = 1;
end
if opts.phase_factor ~= 1
    error('build_common_registered_local_domain:PhaseFactor', ...
        'The registered stage-5 domain requires phase_factor=1.');
end
opts.azimuth_offsets_deg = validate_axis_local( ...
    opts.azimuth_offsets_deg, 'azimuth_offsets_deg');
opts.elevation_offsets_deg = validate_axis_local( ...
    opts.elevation_offsets_deg, 'elevation_offsets_deg');
end

function axis = validate_axis_local(axis, name)
axis = axis(:).';
if isempty(axis) || any(~isfinite(axis)) || ~isreal(axis) || ...
        numel(unique(axis)) ~= numel(axis)
    error('build_common_registered_local_domain:Axis', ...
        '%s must contain unique finite offsets.', name);
end
axis = sort(axis);
end

function step = grid_step_local(axis)
if numel(axis) < 2
    step = NaN;
else
    delta = diff(axis);
    tolerance = numel(axis) * eps(max(1, max(abs(axis))));
    if max(abs(delta - delta(1))) <= tolerance
        step = delta(1);
    else
        step = NaN;
    end
end
end
