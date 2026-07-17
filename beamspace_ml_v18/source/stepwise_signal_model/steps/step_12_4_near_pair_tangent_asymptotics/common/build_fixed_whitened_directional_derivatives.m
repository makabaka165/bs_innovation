function out = build_fixed_whitened_directional_derivatives( ...
    center_deg, direction_unit_rad, model, opts)
%BUILD_FIXED_WHITENED_DIRECTIONAL_DERIVATIVES Return g and D_v^1..3 g.

if nargin < 4
    opts = struct();
end
validate_inputs_local(center_deg, direction_unit_rad, model, opts);
v = direction_unit_rad(:) / norm(direction_unit_rad);
[a_legacy, da_az_legacy, da_el_legacy] = ...
    build_receive_cyl_steering_with_derivatives( ...
    model.array_meta.XAct, model.array_meta.YAct, model.array_meta.ZAct, ...
    center_deg(1), center_deg(2), model.lambda);

phi = deg2rad(center_deg(1));
theta = deg2rad(center_deg(2));
u = [cos(theta) * cos(phi); cos(theta) * sin(phi); sin(theta)];
u_phi = [-cos(theta) * sin(phi); cos(theta) * cos(phi); 0];
u_theta = [-sin(theta) * cos(phi); -sin(theta) * sin(phi); cos(theta)];
u_phiphi = [-cos(theta) * cos(phi); -cos(theta) * sin(phi); 0];
u_phitheta = [sin(theta) * sin(phi); -sin(theta) * cos(phi); 0];
u_thetatheta = -u;
u_phiphiphi = -u_phi;
u_phiphitheta = [sin(theta) * cos(phi); sin(theta) * sin(phi); 0];
u_phithetatheta = -u_phi;
u_thetathetatheta = -u_theta;

u1 = v(1) * u_phi + v(2) * u_theta;
u2 = v(1)^2 * u_phiphi + 2 * v(1) * v(2) * u_phitheta + ...
    v(2)^2 * u_thetatheta;
u3 = v(1)^3 * u_phiphiphi + ...
    3 * v(1)^2 * v(2) * u_phiphitheta + ...
    3 * v(1) * v(2)^2 * u_phithetatheta + ...
    v(2)^3 * u_thetathetatheta;

positions = [model.array_meta.XAct(:), model.array_meta.YAct(:), ...
    model.array_meta.ZAct(:)];
k0 = 2 * pi / model.lambda;
f1 = k0 * positions * u1;
f2 = k0 * positions * u2;
f3 = k0 * positions * u3;
a1_authoritative = v(1) * da_az_legacy + v(2) * da_el_legacy;
a2_legacy = (1j * f2 - f1 .^ 2) .* a_legacy;
a3_legacy = (1j * f3 - 3 * f1 .* f2 - 1j * f1 .^ 3) .* a_legacy;

projection = model.Tseq * model.Wseq';
out = struct();
out.g0 = projection * canonicalize_local(a_legacy, model.array_meta);
out.g1 = projection * canonicalize_local(a1_authoritative, model.array_meta);
out.g2 = projection * canonicalize_local(a2_legacy, model.array_meta);
out.g3 = projection * canonicalize_local(a3_legacy, model.array_meta);
out.direction_unit_rad = v;
out.fixed_measurement_hash = model.fixed_measurement_hash;
out.derivative_unit = 'per_radian';
out.phase_factor = 1;
out.center_deg = center_deg;
out.direction_geometry = struct('u1', u1, 'u2', u2, 'u3', u3);
out.num_receive_manifold_evaluations = 1;
end

function vector = canonicalize_local(legacy_vector, array_meta)
matrix = reshape_cyl_vector_to_matrix(legacy_vector, array_meta);
vector = matrix(:);
end

function validate_inputs_local(center_deg, direction, model, opts)
if ~(isnumeric(center_deg) && isreal(center_deg) && ...
        isequal(size(center_deg), [1, 2]) && all(isfinite(center_deg)))
    error('build_fixed_whitened_directional_derivatives:Center', ...
        'center_deg must be one finite [azimuth,elevation] row.');
end
if ~(isnumeric(direction) && isreal(direction) && numel(direction) == 2 && ...
        all(isfinite(direction)) && abs(norm(direction) - 1) <= 64 * eps)
    error('build_fixed_whitened_directional_derivatives:Direction', ...
        'direction_unit_rad must be a unit real two-vector.');
end
if model.phase_factor ~= 1
    error('build_fixed_whitened_directional_derivatives:PhaseFactor', ...
        'The active stage-6 manifold requires phase_factor=1.');
end
if ~(isstruct(opts) && isscalar(opts) && isempty(fieldnames(opts)))
    error('build_fixed_whitened_directional_derivatives:Options', ...
        'No angle-dependent measurement options are accepted.');
end
end
