clc
clear
close all

script_dir = fileparts(mfilename('fullpath'));
step_dir = script_dir;
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
common_dir = fullfile(step_dir, 'common');
tests_dir = fullfile(step_dir, 'tests');
result_dir = fullfile(step_dir, 'results');

addpath(common_dir);
addpath(tests_dir);
addpath(fullfile(project_dir, 'core', 'config'));
addpath(fullfile(project_dir, 'core', 'array'));
if exist(result_dir, 'dir') ~= 7
    mkdir(result_dir);
end

cfg = sim_cfg();
if cfg.beam.spatialPhaseFactor ~= 1
    error('run_step12_0:ActivePhaseFactor', ...
        'The active receive configuration must use spatialPhaseFactor=1.');
end
arr_info = arr_cyl(cfg, cfg.beam.azSectorCenter);
x = arr_info.xActVec;
y = arr_info.yActVec;
z = arr_info.zActVec;
lambda = cfg.arr.lambda;
steer_az_deg = cfg.tgt.az;
steer_el_deg = cfg.tgt.el;

validation_tic = tic;
formula_table = test_receive_steering_formula(x, y, z, lambda);
derivative_table = test_receive_steering_derivatives(x, y, z, lambda);
figure_path = fullfile(result_dir, 'single_target_receive_pattern.png');
[beamwidth_table, plot_info] = test_receive_beamwidth_comparison( ...
    x, y, z, lambda, steer_az_deg, steer_el_deg, figure_path);
validation_runtime_sec = toc(validation_tic);

derivative_csv = fullfile(result_dir, 'derivative_validation.csv');
beamwidth_csv = fullfile(result_dir, 'old_vs_new_beamwidth.csv');
keypoints_csv = fullfile(result_dir, 'phase_model_keypoints.csv');
validation_md = fullfile(result_dir, 'receive_model_validation.md');
writetable(derivative_table, derivative_csv);
writetable(beamwidth_table, beamwidth_csv);

formula_max_abs_error = max(formula_table.max_abs_error);
formula_max_relative_error = max(formula_table.relative_error);
max_relative_error_az = max(derivative_table.relative_error_az);
max_relative_error_el = max(derivative_table.relative_error_el);
max_peak_offset_deg = max(abs(beamwidth_table.peak_offset_deg));
overall_pass = all(formula_table.pass_flag) && all(derivative_table.pass_flag) && ...
    all(beamwidth_table.pass_flag) && plot_info.active_az_width_deg > plot_info.legacy_az_width_deg && ...
    plot_info.active_el_width_deg > plot_info.legacy_el_width_deg;

metric = ["active_phase_factor"; "extra_phase_argument_rejected"; ...
    "formula_cases"; "formula_max_abs_error"; ...
    "formula_max_relative_error"; "derivative_centers"; ...
    "max_relative_error_az_rad"; "max_relative_error_el_rad"; ...
    "active_az_beamwidth_3db_deg"; "legacy_az_beamwidth_3db_deg"; ...
    "az_beamwidth_ratio_factor1_over_factor2"; ...
    "active_el_beamwidth_3db_deg"; "legacy_el_beamwidth_3db_deg"; ...
    "el_beamwidth_ratio_factor1_over_factor2"; "max_pattern_peak_offset_deg"; ...
    "single_target_pattern_written"; "pattern_scan_angle_evaluations"; ...
    "validation_runtime_sec"; "overall_pass_flag"];
value = [1; double(all(formula_table.extra_input_rejected)); ...
    height(formula_table); formula_max_abs_error; ...
    formula_max_relative_error; height(derivative_table); max_relative_error_az; ...
    max_relative_error_el; plot_info.active_az_width_deg; ...
    plot_info.legacy_az_width_deg; plot_info.az_width_ratio; ...
    plot_info.active_el_width_deg; plot_info.legacy_el_width_deg; ...
    plot_info.el_width_ratio; max_peak_offset_deg; double(exist(figure_path, 'file') == 2); ...
    plot_info.num_pattern_scan_angle_evaluations; validation_runtime_sec; ...
    double(overall_pass)];
unit = ["dimensionless"; "boolean"; "count"; "absolute"; "relative"; "count"; ...
    "relative"; "relative"; "degree"; "degree"; "ratio"; "degree"; ...
    "degree"; "ratio"; "degree"; "boolean"; "count"; "second"; "boolean"];
pass_flag = [true; all(formula_table.extra_input_rejected); ...
    height(formula_table) >= 9; formula_max_abs_error <= 1e-13; ...
    formula_max_relative_error <= 1e-13; height(derivative_table) >= 9; ...
    max_relative_error_az <= 1e-6; max_relative_error_el <= 1e-6; ...
    true; true; plot_info.az_width_ratio > 1; true; true; ...
    plot_info.el_width_ratio > 1; max_peak_offset_deg <= 0.002; ...
    exist(figure_path, 'file') == 2; true; validation_runtime_sec > 0; overall_pass];
phase_factor = ones(size(value));
keypoints_table = table(metric, value, unit, pass_flag, phase_factor);
writetable(keypoints_table, keypoints_csv);

write_validation_markdown_local(validation_md, cfg, arr_info, formula_table, ...
    derivative_table, beamwidth_table, plot_info, overall_pass);

fprintf('Step12.0 receive-model validation: %s\n', pass_fail_text_local(overall_pass));
fprintf('Formula max absolute error: %.3e\n', formula_max_abs_error);
fprintf('Derivative max relative errors (az/el): %.3e / %.3e\n', ...
    max_relative_error_az, max_relative_error_el);
fprintf('3 dB beamwidth factor1/factor2 ratios (az/el): %.6f / %.6f\n', ...
    plot_info.az_width_ratio, plot_info.el_width_ratio);
fprintf('Results: %s\n', result_dir);
assert(overall_pass, 'run_step12_0:ValidationFailed', ...
    'Step12.0 receive-model validation did not pass all gates.');

function write_validation_markdown_local(path_out, cfg, arr_info, formula_table, ...
    derivative_table, beamwidth_table, plot_info, overall_pass)
fid = fopen(path_out, 'w');
if fid < 0
    error('run_step12_0:MarkdownOpenFailed', 'Cannot open %s for writing.', path_out);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '---\n');
fprintf(fid, 'phase_factor: 1\n');
fprintf(fid, 'phase_model: receive_array_one_way_spatial_phase\n');
fprintf(fid, 'derivative_angle_unit: radian\n');
fprintf(fid, 'validation_status: %s\n', pass_fail_text_local(overall_pass));
fprintf(fid, '---\n\n');
fprintf(fid, '# Step12.0 Receive-Model Validation\n\n');
fprintf(fid, '## Scope and boundary\n\n');
fprintf(fid, ['The active manifold uses factor 1. The monostatic round-trip range phase is common ', ...
    'to the receive elements in the far-field narrowband model and is absorbed into the complex ', ...
    'source envelope. The factor-2 curve is an isolated legacy comparison only. No sequential DBF, ', ...
    'DML, FIM design, bootstrap, cache, or model-order logic is implemented here.\n\n']);
fprintf(fid, '## Configuration\n\n');
fprintf(fid, '- Carrier frequency: %.12g Hz\n', cfg.arr.fc);
fprintf(fid, '- Wavelength: %.12g m\n', cfg.arr.lambda);
fprintf(fid, '- Full array: %d azimuth positions x %d elevation elements\n', cfg.arr.Naz, cfg.arr.Nel);
fprintf(fid, '- Work array: %d azimuth positions x %d elevation elements = %d elements\n', ...
    cfg.beam.subNaz, cfg.arr.Nel, arr_info.nAct);
fprintf(fid, '- Steering center: az %.6f deg, el %.6f deg\n', cfg.tgt.az, cfg.tgt.el);
fprintf(fid, '- Active phase factor: 1\n\n');
fprintf(fid, '## Formula and derivative checks\n\n');
fprintf(fid, '- Elementwise formula cases: %d; maximum absolute error: %.6e; maximum relative error: %.6e.\n', ...
    height(formula_table), max(formula_table.max_abs_error), max(formula_table.relative_error));
fprintf(fid, '- A seventh phase-factor input is rejected: %d.\n', all(formula_table.extra_input_rejected));
fprintf(fid, '- Derivative centers: %d; finite-difference step: %.6e rad.\n', ...
    height(derivative_table), derivative_table.h_rad_column(1));
fprintf(fid, '- Maximum azimuth derivative relative error: %.6e.\n', max(derivative_table.relative_error_az));
fprintf(fid, '- Maximum elevation derivative relative error: %.6e.\n\n', max(derivative_table.relative_error_el));
fprintf(fid, '| az (deg) | el (deg) | rel. error az/rad | rel. error el/rad | pass |\n');
fprintf(fid, '|---:|---:|---:|---:|---:|\n');
for idx = 1:height(derivative_table)
    fprintf(fid, '| %.6g | %.6g | %.6e | %.6e | %d |\n', ...
        derivative_table.az_case_deg(idx), derivative_table.el_case_deg(idx), ...
        derivative_table.relative_error_az(idx), derivative_table.relative_error_el(idx), ...
        derivative_table.pass_flag(idx));
end
fprintf(fid, '\n## Single-target pattern and 3 dB width\n\n');
fprintf(fid, '![Single-target receive pattern](single_target_receive_pattern.png)\n\n');
fprintf(fid, '| role | comparison factor | cut | 3 dB width (deg) | peak offset (deg) | pass |\n');
fprintf(fid, '|---|---:|---|---:|---:|---:|\n');
for idx = 1:height(beamwidth_table)
    fprintf(fid, '| %s | %g | %s | %.9f | %.9f | %d |\n', ...
        char(beamwidth_table.role_column(idx)), ...
        beamwidth_table.comparison_model_phase_factor(idx), ...
        char(beamwidth_table.cut_name(idx)), beamwidth_table.beamwidth_3db_deg(idx), ...
        beamwidth_table.peak_offset_deg(idx), beamwidth_table.pass_flag(idx));
end
fprintf(fid, '\n- Azimuth width ratio factor1/factor2: %.9f.\n', plot_info.az_width_ratio);
fprintf(fid, '- Elevation width ratio factor1/factor2: %.9f.\n\n', plot_info.el_width_ratio);
fprintf(fid, '- Pattern scan angle evaluations: %d; chunk size: %d.\n\n', ...
    plot_info.num_pattern_scan_angle_evaluations, plot_info.scan_chunk_size);
fprintf(fid, '## Result\n\n');
fprintf(fid, '**%s.** All active result metadata use `phase_factor=1`. This deterministic validation has no confidence interval.\n', ...
    pass_fail_text_local(overall_pass));
clear cleanup;
end

function text = pass_fail_text_local(flag)
if flag
    text = 'PASS';
else
    text = 'FAIL';
end
end
