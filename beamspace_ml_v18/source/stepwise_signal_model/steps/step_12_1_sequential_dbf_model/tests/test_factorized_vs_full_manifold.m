function result_table = test_factorized_vs_full_manifold(context, cfg)
%TEST_FACTORIZED_VS_FULL_MANIFOLD Validate conditional factorization/order.

array_meta = context.array_meta;
az_values_deg = [-35, 8, 48];
el_values_deg = [-5, 20, 50];
[az_grid_deg, el_grid_deg] = ndgrid(az_values_deg, el_values_deg);
az_case_deg = az_grid_deg(:);
el_case_deg = el_grid_deg(:);
num_cases = numel(az_case_deg);
full_factorized_relative_error = zeros(num_cases, 1);
projected_relative_error = zeros(num_cases, 1);
pass_flag = false(num_cases, 1);
phase_factor = ones(num_cases, 1);
k0 = 2*pi/cfg.arr.lambda;
x_az = array_meta.XAct(:, 1);
y_az = array_meta.YAct(:, 1);
z_el = array_meta.ZAct(1, :).';

for idx = 1:num_cases
    az_deg = az_case_deg(idx);
    el_deg = el_case_deg(idx);
    a_legacy = build_receive_cyl_steering_vec( ...
        array_meta.XAct, array_meta.YAct, array_meta.ZAct, ...
        az_deg, el_deg, cfg.arr.lambda);
    a_matrix = reshape_cyl_vector_to_matrix(a_legacy, array_meta);
    a_full = a_matrix(:);
    a_phi = exp(1j * k0 * (x_az * cosd(el_deg) * cosd(az_deg) + ...
                            y_az * cosd(el_deg) * sind(az_deg)));
    a_z = exp(1j * k0 * z_el * sind(el_deg));
    a_factorized = kron(a_phi, a_z);
    full_factorized_relative_error(idx) = norm(a_full - a_factorized) / ...
        max(norm(a_full), eps);
    [Gfull, ~] = build_sequential_beamspace_manifold( ...
        context.Wseq, [az_deg, el_deg], array_meta, cfg);
    Gfactorized = context.Wseq' * a_factorized;
    projected_relative_error(idx) = norm(Gfull - Gfactorized) / ...
        max(norm(Gfull), eps);
    pass_flag(idx) = full_factorized_relative_error(idx) < 1e-12 && ...
        projected_relative_error(idx) < 1e-12;
end

result_table = table(az_case_deg, el_case_deg, ...
    full_factorized_relative_error, projected_relative_error, ...
    pass_flag, phase_factor);
assert(all(pass_flag), 'test_factorized_vs_full_manifold:Failed', ...
    'The conditional factorization does not match the full receive geometry.');
end
