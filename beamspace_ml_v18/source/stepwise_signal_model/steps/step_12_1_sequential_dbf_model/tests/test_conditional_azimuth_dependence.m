function result_table = test_conditional_azimuth_dependence(cfg)
%TEST_CONDITIONAL_AZIMUTH_DEPENDENCE Verify the required cos(el) dependence.

az_beam_deg = 8;
el_condition_deg = [0; 30; 60];
B_el = numel(el_condition_deg);
N_az = cfg.beam.subNaz;
Zdummy = complex(zeros(B_el, N_az, 1, 2));
[~, Uset] = form_azimuth_dbf_cube( ...
    Zdummy, az_beam_deg, el_condition_deg, cfg);
array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
x_az = array_meta.XAct(:, 1);
y_az = array_meta.YAct(:, 1);
k0 = 2*pi/cfg.arr.lambda;

formula_relative_error = zeros(B_el, 1);
change_from_el0 = zeros(B_el, 1);
elevation_independent_model_error = zeros(B_el, 1);
pass_flag = false(B_el, 1);
phase_factor = ones(B_el, 1);
u_independent = exp(1j * k0 * (x_az * cosd(az_beam_deg) + ...
                               y_az * sind(az_beam_deg)));
u_independent = u_independent / norm(u_independent);
u0 = Uset(:, 1, 1);

for idx = 1:B_el
    el_deg = el_condition_deg(idx);
    expected = exp(1j * k0 * (x_az * cosd(el_deg) * cosd(az_beam_deg) + ...
                              y_az * cosd(el_deg) * sind(az_beam_deg)));
    expected = expected / norm(expected);
    actual = Uset(:, 1, idx);
    formula_relative_error(idx) = norm(actual - expected) / max(norm(expected), eps);
    change_from_el0(idx) = norm(actual - u0) / max(norm(u0), eps);
    elevation_independent_model_error(idx) = norm(actual - u_independent) / ...
        max(norm(actual), eps);
    if idx == 1
        pass_flag(idx) = formula_relative_error(idx) < 1e-12;
    else
        pass_flag(idx) = formula_relative_error(idx) < 1e-12 && ...
            change_from_el0(idx) > 1e-2 && elevation_independent_model_error(idx) > 1e-2;
    end
end

az_beam_column_deg = repmat(az_beam_deg, B_el, 1);
result_table = table(az_beam_column_deg, el_condition_deg, ...
    formula_relative_error, change_from_el0, ...
    elevation_independent_model_error, pass_flag, phase_factor);
assert(all(pass_flag), 'test_conditional_azimuth_dependence:Failed', ...
    'The azimuth weights do not exhibit the required elevation dependence.');
end
