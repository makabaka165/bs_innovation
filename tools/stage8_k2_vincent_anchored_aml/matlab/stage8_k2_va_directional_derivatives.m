function derivatives = stage8_k2_va_directional_derivatives( ...
    anchor_deg, axis_hat, model)
%STAGE8_K2_VA_DIRECTIONAL_DERIVATIVES Exact degree-coordinate derivatives.

validate_inputs_local(anchor_deg, axis_hat, model);
anchor = reshape(double(anchor_deg), 1, 2);
axis = double(axis_hat(:)) / norm(axis_hat);
azimuth = deg2rad(anchor(1));
elevation = deg2rad(anchor(2));
x = model.array_meta.XAct(:);
y = model.array_meta.YAct(:);
z = model.array_meta.ZAct(:);
k0 = 2 * pi / model.lambda;
az_component = axis(1);
el_component = axis(2);

A = x * cos(azimuth) + y * sin(azimuth);
B = -x * sin(azimuth) + y * cos(azimuth);
chi_phi = k0 * cos(elevation) * B;
chi_theta = k0 * (-sin(elevation) * A + z * cos(elevation));
chi_phi_phi = -k0 * cos(elevation) * A;
chi_phi_theta = -k0 * sin(elevation) * B;
chi_theta_theta = -k0 * (cos(elevation) * A + z * sin(elevation));
chi_phi_phi_phi = -k0 * cos(elevation) * B;
chi_phi_phi_theta = k0 * sin(elevation) * A;
chi_phi_theta_theta = -k0 * cos(elevation) * B;
chi_theta_theta_theta = k0 * (sin(elevation) * A - z * cos(elevation));

p1 = az_component * chi_phi + el_component * chi_theta;
p2 = az_component ^ 2 * chi_phi_phi + ...
    2 * az_component * el_component * chi_phi_theta + ...
    el_component ^ 2 * chi_theta_theta;
p3 = az_component ^ 3 * chi_phi_phi_phi + ...
    3 * az_component ^ 2 * el_component * chi_phi_phi_theta + ...
    3 * az_component * el_component ^ 2 * chi_phi_theta_theta + ...
    el_component ^ 3 * chi_theta_theta_theta;

a_legacy = build_receive_cyl_steering_vec( ...
    model.array_meta.XAct, model.array_meta.YAct, model.array_meta.ZAct, ...
    anchor(1), anchor(2), model.lambda);
a0 = canonicalize_local(a_legacy, model.array_meta);
kappa = pi / 180;
a1_legacy = kappa * (1j * p1) .* a_legacy;
a2_legacy = kappa ^ 2 * (1j * p2 - p1 .^ 2) .* a_legacy;
a3_legacy = kappa ^ 3 * ...
    (1j * p3 - 3 * p1 .* p2 - 1j * p1 .^ 3) .* a_legacy;
a1 = canonicalize_local(a1_legacy, model.array_meta);
a2 = canonicalize_local(a2_legacy, model.array_meta);
a3 = canonicalize_local(a3_legacy, model.array_meta);
transform = model.T_I * model.W_I';

derivatives = struct('h0', transform * a0, 'h1', transform * a1, ...
    'h2', transform * a2, 'h3', transform * a3, ...
    'anchor_deg', anchor, 'axis_hat', axis.', ...
    'coordinate', 'degree', 'phase_factor', model.phase_factor, ...
    'full_receive_geometry_used_flag', true, ...
    'canonical_element_order_used_flag', true);
end

function vector = canonicalize_local(legacy_vector, array_meta)
matrix = reshape_cyl_vector_to_matrix(legacy_vector, array_meta);
vector = matrix(:);
end

function validate_inputs_local(anchor, axis, model)
required = {'T_I','W_I','array_meta','lambda','phase_factor'};
if ~(isnumeric(anchor) && isreal(anchor) && numel(anchor) == 2 && ...
        all(isfinite(anchor(:))) && isnumeric(axis) && isreal(axis) && ...
        numel(axis) == 2 && all(isfinite(axis(:))) && norm(axis) > 0 && ...
        isstruct(model) && isscalar(model) && ...
        all(isfield(model, required)) && model.phase_factor == 1)
    error('stage8_k2_va_directional_derivatives:Input', ...
        'The degree coordinate, axis, or frozen model is invalid.');
end
end
