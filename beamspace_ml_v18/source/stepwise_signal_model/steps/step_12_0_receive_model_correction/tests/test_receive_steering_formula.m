function result_table = test_receive_steering_formula(x, y, z, lambda)
%TEST_RECEIVE_STEERING_FORMULA Compare the implementation element by element.

az_values_deg = [-40, 8, 55];
el_values_deg = [-5, 20, 50];
[az_grid_deg, el_grid_deg] = ndgrid(az_values_deg, el_values_deg);
az_case_deg = az_grid_deg(:);
el_case_deg = el_grid_deg(:);
num_cases = numel(az_case_deg);

max_abs_error = zeros(num_cases, 1);
relative_error = zeros(num_cases, 1);
pass_flag = false(num_cases, 1);
phase_factor = ones(num_cases, 1);
formula_tolerance = 1e-13;
coords = [x(:), y(:), z(:)];

extra_input_rejected_scalar = false;
try
    build_receive_cyl_steering_vec(x, y, z, az_case_deg(1), el_case_deg(1), lambda, 2);
catch
    extra_input_rejected_scalar = true;
end
extra_input_rejected = repmat(extra_input_rejected_scalar, num_cases, 1);

for idx = 1:num_cases
    az_deg = az_case_deg(idx);
    el_deg = el_case_deg(idx);
    u = [cosd(el_deg) * cosd(az_deg); ...
         cosd(el_deg) * sind(az_deg); ...
         sind(el_deg)];
    expected = exp(1j * (2*pi/lambda) * (coords * u));
    actual = build_receive_cyl_steering_vec(x, y, z, az_deg, el_deg, lambda);
    delta = actual - expected;
    max_abs_error(idx) = max(abs(delta));
    relative_error(idx) = norm(delta) / max(norm(expected), eps);
    pass_flag(idx) = isequal(size(actual), [numel(x), 1]) && ...
        max_abs_error(idx) <= formula_tolerance && extra_input_rejected(idx);
end

result_table = table(az_case_deg, el_case_deg, max_abs_error, relative_error, ...
    extra_input_rejected, pass_flag, phase_factor);
assert(all(pass_flag), 'test_receive_steering_formula:Failed', ...
    'The receive steering implementation does not match the elementwise formula.');
end
