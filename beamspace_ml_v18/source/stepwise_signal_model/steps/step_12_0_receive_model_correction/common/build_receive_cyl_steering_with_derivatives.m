function [a, da_daz_rad, da_del_rad, meta] = ...
    build_receive_cyl_steering_with_derivatives(x, y, z, az_deg, el_deg, lambda)
%BUILD_RECEIVE_CYL_STEERING_WITH_DERIVATIVES Receive manifold derivatives.
% Derivatives are with respect to azimuth and elevation measured in radians.

narginchk(6, 6);
a = build_receive_cyl_steering_vec(x, y, z, az_deg, el_deg, lambda);
xv = x(:);
yv = y(:);
zv = z(:);

az_rad = az_deg * pi / 180;
el_rad = el_deg * pi / 180;
du_daz_rad = [-cos(el_rad) * sin(az_rad); ...
                cos(el_rad) * cos(az_rad); ...
                0];
du_del_rad = [-sin(el_rad) * cos(az_rad); ...
              -sin(el_rad) * sin(az_rad); ...
               cos(el_rad)];

dphase_daz_rad = xv * du_daz_rad(1) + yv * du_daz_rad(2) + zv * du_daz_rad(3);
dphase_del_rad = xv * du_del_rad(1) + yv * du_del_rad(2) + zv * du_del_rad(3);
k0 = 2*pi/lambda;
da_daz_rad = 1j * k0 * dphase_daz_rad .* a;
da_del_rad = 1j * k0 * dphase_del_rad .* a;

meta = struct();
meta.phase_factor = 1;
meta.phase_sign = 1;
meta.input_angle_unit = 'degree';
meta.derivative_angle_unit = 'radian';
meta.lambda = lambda;
meta.num_elements = numel(a);
meta.direction_cosines = [cos(el_rad) * cos(az_rad), ...
                          cos(el_rad) * sin(az_rad), ...
                          sin(el_rad)];
meta.du_daz_rad = du_daz_rad;
meta.du_del_rad = du_del_rad;
end
