function [Uq, info] = build_fixed_conditional_azimuth_beam_bank( ...
    az_beam_deg, eta_condition_deg, array_meta, opts)
%BUILD_FIXED_CONDITIONAL_AZIMUTH_BEAM_BANK Build a fixed factor-1 bank.

if nargin < 4 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts, array_meta);
az_beam_deg = validate_angles_local(az_beam_deg, 'az_beam_deg');
validateattributes(eta_condition_deg, {'numeric'}, ...
    {'real','finite','scalar'}, mfilename, 'eta_condition_deg');
[x_az, y_az, element_order] = coordinates_local(array_meta, opts);

k0 = 2 * pi / opts.lambda;
Uq = complex(zeros(numel(x_az), numel(az_beam_deg)));
for idx = 1:numel(az_beam_deg)
    az_rad = deg2rad(az_beam_deg(idx));
    el_rad = deg2rad(eta_condition_deg);
    phase = k0 * cos(el_rad) * ...
        (x_az * cos(az_rad) + y_az * sin(az_rad));
    weight = exp(1j * phase);
    Uq(:, idx) = weight / norm(weight);
end

info = struct();
info.az_beam_deg = az_beam_deg;
info.eta_condition_deg = eta_condition_deg;
info.array_coordinates = [x_az, y_az];
info.lambda = opts.lambda;
info.phase_factor = 1;
info.element_order = element_order;
info.weight_normalization = 'unit_2_norm';
info.candidate_independent_flag = true;
info.beam_bank_hash = stable_object_hash(Uq, az_beam_deg, ...
    eta_condition_deg, [x_az, y_az], opts.lambda, element_order);
end

function opts = normalize_options_local(opts, array_meta)
if ~(isstruct(opts) && isscalar(opts))
    error('build_fixed_conditional_azimuth_beam_bank:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'lambda', 'phase_factor', 'aperture_index', 'element_order'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_fixed_conditional_azimuth_beam_bank:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'lambda')
    if isfield(array_meta, 'lambda')
        opts.lambda = array_meta.lambda;
    else
        error('build_fixed_conditional_azimuth_beam_bank:Lambda', ...
            'opts.lambda or array_meta.lambda is required.');
    end
end
if ~isfield(opts, 'phase_factor')
    opts.phase_factor = 1;
end
if opts.phase_factor ~= 1
    error('build_fixed_conditional_azimuth_beam_bank:PhaseFactor', ...
        'The active conditional bank requires phase_factor=1.');
end
if ~isfield(opts, 'aperture_index')
    opts.aperture_index = [];
end
if ~isfield(opts, 'element_order')
    opts.element_order = 'physical_circumferential_column_order';
end
validateattributes(opts.lambda, {'numeric'}, ...
    {'real','finite','positive','scalar'}, mfilename, 'opts.lambda');
end

function [x, y, order] = coordinates_local(array_meta, opts)
if ~(isstruct(array_meta) && isscalar(array_meta) && ...
        isfield(array_meta, 'XAct') && isfield(array_meta, 'YAct'))
    error('build_fixed_conditional_azimuth_beam_bank:ArrayMeta', ...
        'array_meta must contain XAct and YAct.');
end
x = array_meta.XAct(:, 1);
y = array_meta.YAct(:, 1);
if ~isempty(opts.aperture_index)
    idx = opts.aperture_index(:);
    if any(idx < 1) || any(idx > numel(x)) || any(idx ~= fix(idx))
        error('build_fixed_conditional_azimuth_beam_bank:ApertureIndex', ...
            'aperture_index must contain valid integer circumferential indices.');
    end
    x = x(idx);
    y = y(idx);
end
if isempty(x) || numel(x) ~= numel(y) || any(~isfinite([x; y]))
    error('build_fixed_conditional_azimuth_beam_bank:Coordinates', ...
        'The selected circumferential coordinates must be finite and non-empty.');
end
order = char(opts.element_order);
end

function values = validate_angles_local(values, name)
values = values(:).';
if isempty(values) || ~isreal(values) || any(~isfinite(values)) || ...
        numel(unique(values)) ~= numel(values)
    error('build_fixed_conditional_azimuth_beam_bank:Angles', ...
        '%s must contain unique finite real beam centers.', name);
end
end
