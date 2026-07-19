function result = test_global_threshold_is_max_cell_quantile()
%TEST_GLOBAL_THRESHOLD_IS_MAX_CELL_QUANTILE Verify conservative aggregation.

fixture = build_stage8_synthetic_fixture('K1_NOISY');
base = struct('measurement_config_id', 'SYNTHETIC_CONFIG', ...
    'calibration_cell_id', '', 'seed', 0, ...
    'full_data', fixture.full_data, ...
    'initialization_factory', fixture.initialization_factory);
cells = repmat(base, 2, 1);
cells(1).calibration_cell_id = 'SYNTHETIC_CELL_1';
cells(1).seed = 4101;
cells(2).calibration_cell_id = 'SYNTHETIC_CELL_2';
cells(2).seed = 5101;
model = fixture.model;
model.measurement_config_id = 'SYNTHETIC_CONFIG';
[artifact, ~] = calibrate_global_bootstrap_threshold(cells, ...
    fixture.domain, model, struct('Bboot_per_cell', 2));
expected = max(artifact.cell_quantiles.q_cell_0p95);
pass = artifact.q_global == expected && height(artifact.cell_quantiles) == 2;
assert(pass, 'test_global_threshold_is_max_cell_quantile:Failed', ...
    'q_global must be the maximum registered cell quantile.');
result = table(pass, artifact.q_global, expected, ...
    'VariableNames', {'pass_flag','q_global','expected'});
end
