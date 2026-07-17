function [Zseq, Uset, info] = form_azimuth_dbf_cube( ...
    Zel, az_beam_deg, el_condition_deg, cfg)
%FORM_AZIMUTH_DBF_CUBE Apply elevation-conditioned azimuth DBF.

validate_active_cfg_local(cfg);
[Z4, B_el, N_az, N_range, N_snapshot, input_form] = ...
    normalize_elevation_cube_local(Zel);
az_beam_deg = az_beam_deg(:).';
if isempty(az_beam_deg) || any(~isfinite(az_beam_deg))
    error('form_azimuth_dbf_cube:BeamAngles', ...
        'az_beam_deg must contain finite beam centers.');
end
if isscalar(el_condition_deg)
    el_condition_deg = repmat(el_condition_deg, B_el, 1);
else
    el_condition_deg = el_condition_deg(:);
end
if numel(el_condition_deg) ~= B_el || any(~isfinite(el_condition_deg))
    error('form_azimuth_dbf_cube:ElevationConditions', ...
        'el_condition_deg must be scalar or contain one finite value per elevation channel.');
end

arr_info = arr_cyl(cfg, cfg.beam.azSectorCenter);
if size(arr_info.XAct, 1) ~= N_az
    error('form_azimuth_dbf_cube:AzimuthDimension', ...
        'Zel has N_az=%d, while arr_cyl provides %d work columns.', ...
        N_az, size(arr_info.XAct, 1));
end
x_az = arr_info.XAct(:, 1);
y_az = arr_info.YAct(:, 1);
k0 = 2*pi/cfg.arr.lambda;
B_az = numel(az_beam_deg);
Uset = complex(zeros(N_az, B_az, B_el));
Zseq = complex(zeros(B_el, B_az, N_range, N_snapshot));

for b = 1:B_el
    el_deg = el_condition_deg(b);
    for c = 1:B_az
        ux = cosd(el_deg) * cosd(az_beam_deg(c));
        uy = cosd(el_deg) * sind(az_beam_deg(c));
        u = exp(1j * k0 * (x_az * ux + y_az * uy));
        Uset(:, c, b) = u / norm(u);
    end
    Zel_b = reshape(Z4(b, :, :, :), N_az, N_range * N_snapshot);
    Z_b = Uset(:, :, b)' * Zel_b;
    Zseq(b, :, :, :) = reshape(Z_b, 1, B_az, N_range, N_snapshot);
end

info = struct();
info.phase_factor = 1;
info.input_form = input_form;
info.input_size = size(Zel);
info.output_size = [B_el, B_az, N_range, N_snapshot];
info.Uset_size = size(Uset);
info.az_beam_deg = az_beam_deg;
info.el_condition_deg = el_condition_deg;
info.azimuth_steering_uses_cos_el = true;
info.weight_normalization = 'unit_2_norm';
end

function [Z4, B_el, N_az, N_range, N_snapshot, input_form] = ...
    normalize_elevation_cube_local(Zel)
if ~isnumeric(Zel) || isempty(Zel)
    error('form_azimuth_dbf_cube:InvalidInput', 'Zel must be a non-empty numeric array.');
end
sz = size(Zel);
B_el = sz(1);
N_az = sz(2);
switch ndims(Zel)
    case 2
        N_range = 1;
        N_snapshot = 1;
        input_form = 'B_el_by_N_az';
    case 3
        N_range = 1;
        N_snapshot = sz(3);
        input_form = 'B_el_by_N_az_by_N_snapshot';
    case 4
        N_range = sz(3);
        N_snapshot = sz(4);
        input_form = 'B_el_by_N_az_by_N_range_by_N_snapshot';
    otherwise
        error('form_azimuth_dbf_cube:Dimensions', 'Zel must have two, three, or four dimensions.');
end
Z4 = reshape(Zel, B_el, N_az, N_range, N_snapshot);
end

function validate_active_cfg_local(cfg)
if ~isfield(cfg, 'beam') || ~isfield(cfg.beam, 'spatialPhaseFactor') || ...
        cfg.beam.spatialPhaseFactor ~= 1
    error('form_azimuth_dbf_cube:PhaseFactor', ...
        'The active sequential DBF configuration must use spatialPhaseFactor=1.');
end
end
