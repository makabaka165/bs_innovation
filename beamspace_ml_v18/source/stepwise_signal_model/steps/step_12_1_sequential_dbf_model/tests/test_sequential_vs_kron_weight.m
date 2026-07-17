function [result_table, context] = test_sequential_vs_kron_weight( ...
    el_beam_deg, az_beam_deg, el_condition_deg, cfg)
%TEST_SEQUENTIAL_VS_KRON_WEIGHT Compare staged and equivalent projections.

rng(120102, 'twister');
array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
Yzero = complex(zeros(N_el, N_az));
[~, V] = form_elevation_dbf_cube(Yzero, el_beam_deg, cfg);
[~, Uset] = form_azimuth_dbf_cube(complex(zeros(numel(el_beam_deg), N_az)), ...
    az_beam_deg, el_condition_deg, cfg);
[Wseq, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta);

Yrandom = complex(randn(N_el, N_az, 2, 4), randn(N_el, N_az, 2, 4)) / sqrt(2);
single_angles_deg = [8.4, 10.7];
single_S = exp(1j * [0.0, 0.31, -0.47, 0.82]);
[Ysingle, single_model] = generate_receive_only_element_snapshots( ...
    single_angles_deg, single_S, [], cfg);
double_angles_deg = [7.5, 9.2; 9.1, 12.4];
double_S = [1.0, exp(1j*0.2), exp(-1j*0.5), exp(1j*0.8); ...
            0.72*exp(1j*0.4), 0.72*exp(-1j*0.1), ...
            0.72*exp(1j*0.7), 0.72*exp(-1j*0.6)];
[Ydouble, double_model] = generate_receive_only_element_snapshots( ...
    double_angles_deg, double_S, [], cfg);

scenario = ["random_complex_element_data"; ...
            "factor1_single_target_snapshot"; ...
            "factor1_two_target_snapshot"];
Ycases = {Yrandom, Ysingle, Ydouble};
models = {[], single_model, double_model};
angles = {[], single_angles_deg, double_angles_deg};
sources = {[], single_S, double_S};
sequential_direct_relative_error = zeros(3, 1);
physical_manifold_relative_error = NaN(3, 1);
num_range_cells = zeros(3, 1);
num_snapshots = zeros(3, 1);
pass_flag = false(3, 1);
phase_factor = ones(3, 1);

for idx = 1:3
    Y = Ycases{idx};
    [Zel, V_now] = form_elevation_dbf_cube(Y, el_beam_deg, cfg);
    [Zseq, U_now] = form_azimuth_dbf_cube(Zel, az_beam_deg, el_condition_deg, cfg);
    [W_now, meta_now] = build_sequential_beam_matrix(V_now, U_now, array_meta);
    Ycanonical = reshape(Y, N_el * N_az, []);
    Zdirect = W_now' * Ycanonical;
    Zdirect_cube = reshape(Zdirect, meta_now.B_el, meta_now.B_az, ...
        size(Zseq, 3), size(Zseq, 4));
    sequential_direct_relative_error(idx) = norm(Zseq(:) - Zdirect_cube(:)) / ...
        max(norm(Zdirect_cube(:)), eps);
    num_range_cells(idx) = size(Zseq, 3);
    num_snapshots(idx) = size(Zseq, 4);
    if ~isempty(models{idx})
        [Gseq, manifold_info] = build_sequential_beamspace_manifold( ...
            W_now, angles{idx}, array_meta, cfg);
        predicted = Gseq * sources{idx};
        physical_manifold_relative_error(idx) = norm(Zdirect - predicted, 'fro') / ...
            max(norm(predicted, 'fro'), eps);
        assert(norm(manifold_info.A_canonical - models{idx}.A_canonical, 'fro') == 0, ...
            'test_sequential_vs_kron_weight:ManifoldSource', ...
            'Snapshot generation and sequential manifold used different receive manifolds.');
    end
    pass_flag(idx) = sequential_direct_relative_error(idx) < 1e-12 && ...
        (isnan(physical_manifold_relative_error(idx)) || ...
         physical_manifold_relative_error(idx) < 1e-12);
end

result_table = table(scenario, num_range_cells, num_snapshots, ...
    sequential_direct_relative_error, physical_manifold_relative_error, ...
    pass_flag, phase_factor);
assert(all(pass_flag), 'test_sequential_vs_kron_weight:Failed', ...
    'A staged/direct sequential DBF equivalence test failed.');

context = struct();
context.array_meta = array_meta;
context.V = V;
context.Uset = Uset;
context.Wseq = Wseq;
context.beam_meta = beam_meta;
context.el_beam_deg = el_beam_deg;
context.az_beam_deg = az_beam_deg;
context.el_condition_deg = el_condition_deg;
end
