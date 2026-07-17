function [result_table, context] = test_full_sequential_manifold(cfg)
%TEST_FULL_SEQUENTIAL_MANIFOLD Compare to the Step12.1 full receive model.

locked = build_stage5_locked_config();
fixture = build_stage5_physical_fixture( ...
    stage5_design_spec(cfg, 'Q1_K2', 0), cfg, locked);
angles = [7.6, 10.0; 8.4, 10.0];
[G, dG, info] = build_full_sequential_local_manifold( ...
    angles, fixture.full_model, struct());
[Graw, raw_info] = build_sequential_beamspace_manifold( ...
    fixture.Wseq, angles, fixture.array_meta, cfg);
G_reference = fixture.full_model.Tseq * Graw;
manifold_error = norm(G - G_reference, 'fro') / norm(G_reference, 'fro');

h_rad = 1e-6;
dG_fd_az = finite_difference_local( ...
    angles, 1, h_rad, fixture.full_model);
dG_fd_el = finite_difference_local( ...
    angles, 2, h_rad, fixture.full_model);
derivative_az_error = norm(dG.azimuth - dG_fd_az, 'fro') / ...
    norm(dG_fd_az, 'fro');
derivative_el_error = norm(dG.elevation - dG_fd_el, 'fro') / ...
    norm(dG_fd_el, 'fro');
hash_match = strcmp(info.fixed_measurement_hash, ...
    fixture.full_model.fixed_measurement_hash);
source_match = strcmp(raw_info.manifold_source, ...
    'full_receive_cyl_geometry_not_separable_approximation');
pass_flag = manifold_error < 1e-12 && derivative_az_error < 1e-6 && ...
    derivative_el_error < 1e-6 && hash_match && source_match && ...
    info.full_receive_geometry_used_flag && ~info.factorized_scoring_used_flag;

metric = ["full_manifold_relative_error"; ...
    "azimuth_derivative_relative_error"; ...
    "elevation_derivative_relative_error"];
value = [manifold_error; derivative_az_error; derivative_el_error];
registered_gate = [1e-12; 1e-6; 1e-6];
pass_column = value < registered_gate;
statistical_calibration_status = repmat("NOT_CALIBRATED_STAGE5", 3, 1);
phase_factor = ones(3, 1);
result_table = table(metric, value, registered_gate, ...
    statistical_calibration_status, pass_column, phase_factor, ...
    'VariableNames', {'metric','value','registered_gate', ...
    'statistical_calibration_status','pass_flag','phase_factor'});
if ~pass_flag
    disp(result_table);
end
assert(pass_flag, 'test_full_sequential_manifold:Failed', ...
    'The fixed full-sequential manifold validation failed.');
context = struct('fixture', fixture, 'manifold_error', manifold_error, ...
    'derivative_az_error', derivative_az_error, ...
    'derivative_el_error', derivative_el_error, 'rank_Gseq', info.rank_Gseq);
end

function derivative = finite_difference_local(angles, dimension, h_rad, model)
derivative = complex(zeros(size(model.Tseq, 1), size(angles, 1)));
for idx = 1:size(angles, 1)
    plus = angles;
    minus = angles;
    plus(idx, dimension) = plus(idx, dimension) + rad2deg(h_rad);
    minus(idx, dimension) = minus(idx, dimension) - rad2deg(h_rad);
    G_plus = build_full_sequential_local_manifold(plus, model, struct());
    G_minus = build_full_sequential_local_manifold(minus, model, struct());
    derivative(:, idx) = (G_plus(:, idx) - G_minus(:, idx)) / (2 * h_rad);
end
end
