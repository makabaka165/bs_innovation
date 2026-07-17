function result_table = test_receive_steering_derivatives(x, y, z, lambda)
%TEST_RECEIVE_STEERING_DERIVATIVES Validate radian derivatives by differences.

az_values_deg = [-40, 8, 55];
el_values_deg = [-5, 20, 50];
[az_grid_deg, el_grid_deg] = ndgrid(az_values_deg, el_values_deg);
az_case_deg = az_grid_deg(:);
el_case_deg = el_grid_deg(:);
num_cases = numel(az_case_deg);
h_rad = 1e-6;
h_deg = h_rad * 180 / pi;
relative_error_az = zeros(num_cases, 1);
relative_error_el = zeros(num_cases, 1);
max_abs_error_az = zeros(num_cases, 1);
max_abs_error_el = zeros(num_cases, 1);
formula_relative_error = zeros(num_cases, 1);
pass_flag = false(num_cases, 1);
phase_factor = ones(num_cases, 1);
derivative_tolerance = 1e-6;

for idx = 1:num_cases
    az_deg = az_case_deg(idx);
    el_deg = el_case_deg(idx);
    [a, da_daz_rad, da_del_rad, meta] = ...
        build_receive_cyl_steering_with_derivatives(x, y, z, az_deg, el_deg, lambda);
    a_direct = build_receive_cyl_steering_vec(x, y, z, az_deg, el_deg, lambda);
    az_plus = build_receive_cyl_steering_vec(x, y, z, az_deg + h_deg, el_deg, lambda);
    az_minus = build_receive_cyl_steering_vec(x, y, z, az_deg - h_deg, el_deg, lambda);
    el_plus = build_receive_cyl_steering_vec(x, y, z, az_deg, el_deg + h_deg, lambda);
    el_minus = build_receive_cyl_steering_vec(x, y, z, az_deg, el_deg - h_deg, lambda);
    fd_az = (az_plus - az_minus) / (2*h_rad);
    fd_el = (el_plus - el_minus) / (2*h_rad);

    relative_error_az(idx) = norm(da_daz_rad - fd_az) / max(norm(da_daz_rad), eps);
    relative_error_el(idx) = norm(da_del_rad - fd_el) / max(norm(da_del_rad), eps);
    max_abs_error_az(idx) = max(abs(da_daz_rad - fd_az));
    max_abs_error_el(idx) = max(abs(da_del_rad - fd_el));
    formula_relative_error(idx) = norm(a - a_direct) / max(norm(a_direct), eps);
    pass_flag(idx) = meta.phase_factor == 1 && ...
        strcmp(meta.derivative_angle_unit, 'radian') && ...
        relative_error_az(idx) <= derivative_tolerance && ...
        relative_error_el(idx) <= derivative_tolerance;
end

h_rad_column = repmat(h_rad, num_cases, 1);
result_table = table(az_case_deg, el_case_deg, h_rad_column, relative_error_az, ...
    relative_error_el, max_abs_error_az, max_abs_error_el, ...
    formula_relative_error, pass_flag, phase_factor);
assert(all(pass_flag), 'test_receive_steering_derivatives:Failed', ...
    'At least one analytic derivative exceeded the relative-error tolerance.');
end
