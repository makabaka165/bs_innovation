function a = build_receive_cyl_steering_vec(x, y, z, az_deg, el_deg, lambda)
%BUILD_RECEIVE_CYL_STEERING_VEC Build the factor-1 receive-array manifold.

narginchk(6, 6);
[xv, yv, zv] = validate_coordinates_local(x, y, z);
validateattributes(az_deg, {'numeric'}, {'real','finite','scalar'}, mfilename, 'az_deg');
validateattributes(el_deg, {'numeric'}, {'real','finite','scalar'}, mfilename, 'el_deg');
validateattributes(lambda, {'numeric'}, {'real','finite','positive','scalar'}, mfilename, 'lambda');

ux = cosd(el_deg) * cosd(az_deg);
uy = cosd(el_deg) * sind(az_deg);
uz = sind(el_deg);
phase = xv * ux + yv * uy + zv * uz;
a = exp(1j * 2*pi/lambda * phase);
end

function [xv, yv, zv] = validate_coordinates_local(x, y, z)
xv = x(:);
yv = y(:);
zv = z(:);
if isempty(xv) || numel(xv) ~= numel(yv) || numel(xv) ~= numel(zv)
    error('build_receive_cyl_steering_vec:CoordinateShape', ...
        'x, y, and z must be non-empty and contain the same number of elements.');
end
if ~isreal(xv) || ~isreal(yv) || ~isreal(zv) || ...
        any(~isfinite(xv)) || any(~isfinite(yv)) || any(~isfinite(zv))
    error('build_receive_cyl_steering_vec:InvalidCoordinates', ...
        'x, y, and z must contain finite real coordinates.');
end
end
