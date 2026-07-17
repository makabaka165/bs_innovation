function [Zel, V, info] = form_elevation_dbf_cube(Yelem, el_beam_deg, cfg)
%FORM_ELEVATION_DBF_CUBE Apply elevation DBF without summing azimuth.

validate_active_cfg_local(cfg);
[Y4, N_el, N_az, N_range, N_snapshot, input_form] = ...
    normalize_element_cube_local(Yelem);
if N_el ~= cfg.arr.Nel
    error('form_elevation_dbf_cube:ElevationDimension', ...
        'Yelem has N_el=%d, while cfg.arr.Nel=%d.', N_el, cfg.arr.Nel);
end
el_beam_deg = el_beam_deg(:).';
if isempty(el_beam_deg) || any(~isfinite(el_beam_deg))
    error('form_elevation_dbf_cube:BeamAngles', ...
        'el_beam_deg must contain finite beam centers.');
end

z_el = (0:N_el-1).' * cfg.arr.dz;
k0 = 2*pi/cfg.arr.lambda;
B_el = numel(el_beam_deg);
V = complex(zeros(N_el, B_el));
for b = 1:B_el
    v = exp(1j * k0 * z_el * sind(el_beam_deg(b)));
    V(:, b) = v / norm(v);
end

Y2 = reshape(Y4, N_el, N_az * N_range * N_snapshot);
Z2 = V' * Y2;
Zel = reshape(Z2, B_el, N_az, N_range, N_snapshot);

info = struct();
info.phase_factor = 1;
info.input_form = input_form;
info.input_size = size(Yelem);
info.output_size = [B_el, N_az, N_range, N_snapshot];
info.V_size = size(V);
info.el_beam_deg = el_beam_deg;
info.summed_dimension = 'elevation_only';
info.azimuth_columns_preserved = true;
info.weight_normalization = 'unit_2_norm';
end

function [Y4, N_el, N_az, N_range, N_snapshot, input_form] = ...
    normalize_element_cube_local(Yelem)
if ~isnumeric(Yelem) || isempty(Yelem)
    error('form_elevation_dbf_cube:InvalidInput', 'Yelem must be a non-empty numeric array.');
end
sz = size(Yelem);
N_el = sz(1);
N_az = sz(2);
switch ndims(Yelem)
    case 2
        N_range = 1;
        N_snapshot = 1;
        input_form = 'N_el_by_N_az';
    case 3
        N_range = 1;
        N_snapshot = sz(3);
        input_form = 'N_el_by_N_az_by_N_snapshot';
    case 4
        N_range = sz(3);
        N_snapshot = sz(4);
        input_form = 'N_el_by_N_az_by_N_range_by_N_snapshot';
    otherwise
        error('form_elevation_dbf_cube:Dimensions', 'Yelem must have two, three, or four dimensions.');
end
Y4 = reshape(Yelem, N_el, N_az, N_range, N_snapshot);
end

function validate_active_cfg_local(cfg)
if ~isfield(cfg, 'beam') || ~isfield(cfg.beam, 'spatialPhaseFactor') || ...
        cfg.beam.spatialPhaseFactor ~= 1
    error('form_elevation_dbf_cube:PhaseFactor', ...
        'The active sequential DBF configuration must use spatialPhaseFactor=1.');
end
end
