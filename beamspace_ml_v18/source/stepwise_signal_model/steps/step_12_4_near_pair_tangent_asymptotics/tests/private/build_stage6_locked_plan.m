function plan = build_stage6_locked_plan()
%BUILD_STAGE6_LOCKED_PLAN Return the complete pre-result stage-6 registry.

[status, commit_text] = system('git rev-parse HEAD');
if status ~= 0
    error('build_stage6_locked_plan:Git', ...
        'Unable to read the current git commit.');
end
current_git_commit = strtrim(commit_text);
baseline_commit = '0430f25272690a3ddf378dcf0bab465ca93edb68';
if ~strcmp(current_git_commit, baseline_commit)
    error('build_stage6_locked_plan:Baseline', ...
        'Stage 6 must run from baseline commit %s.', baseline_commit);
end

controls = struct();
controls.phase_factor = 1;
controls.matlab_precision = 'double';
controls.first_derivative_step_rad = 1e-6;
controls.second_derivative_step_rad = 2e-4;
controls.third_derivative_step_rad = 5e-4;
controls.derivative_sensitivity_scales = [0.8, 1.25];
controls.numeric_floor_multiplier = 4096;
controls.rank_multiplier = 1;
controls.negative_eigenvalue_tolerance_multiplier = 64;
controls.null_tolerance_multiplier = 256;
controls.near_null_ratio = 1e-6;
controls.first_derivative_relative_error_gate = 1e-6;
controls.stage5_manifold_consistency_gate = 1e-10;
controls.second_derivative_relative_error_gate = 1e-4;
controls.third_derivative_relative_error_gate = 1e-3;
controls.sigma2_ratio_error_gate = 0.02;
controls.coherence_ratio_error_gate = 0.02;
controls.normalized_gram_ratio_error_gate = 0.05;
controls.exact_identity_relative_error_gate = 1e-10;
controls.exact_identity_roundoff_multiplier = 64;
controls.invariance_relative_error_gate = 1e-10;
controls.synthetic_null_slope_gate = 0.25;
controls.synthetic_null_ratio_error_gate = 0.02;
controls.theory_sigma2_constant = 0.5;
controls.theory_coherence_constant = 1;
controls.theory_normalized_gram_constant = 4;
controls.method_version_id = 'STEP12_4_TANGENT_ASYMPTOTICS_V1';
controls.measurement_version_id = 'FIXED_SEQUENTIAL_DBFFACTOR1_V1';
controls.baseline_commit = baseline_commit;
controls.current_git_commit = current_git_commit;

configs = repmat(empty_config_local(), 5, 1);
configs(1) = config_local('SEQ_3X3_WHITE', [7.4, 8.0, 8.6], ...
    [9.6, 10.0, 10.4], 'IDENTITY', 0, 0, true, 'PRIMARY');
configs(2) = config_local('SEQ_3X3_CORRELATED', [7.4, 8.0, 8.6], ...
    [9.6, 10.0, 10.4], 'STAGE5_TOEPLITZ_CORRELATED', ...
    0.45, 0.70, true, 'PRIMARY');
configs(3) = config_local('SEQ_2X3_WHITE', [7.4, 8.6], ...
    [9.6, 10.0, 10.4], 'IDENTITY', 0, 0, true, 'PRIMARY');
configs(4) = config_local('SEQ_3X2_WHITE', [7.4, 8.0, 8.6], ...
    [9.6, 10.4], 'IDENTITY', 0, 0, true, 'PRIMARY');
configs(5) = config_local('SINGLE_CHANNEL_DIAGNOSTIC', 8.0, 10.0, ...
    'IDENTITY', 0, 0, false, 'EXACT_MEASUREMENT_COLLAPSE_ONLY');

[az_mesh, el_mesh] = ndgrid([7.6, 8.0, 8.4], [9.8, 10.0, 10.2]);
centers_deg = [az_mesh(:), el_mesh(:)];
directions = repmat(struct('direction_id', '', 'vector_rad', zeros(2, 1)), 4, 1);
directions(1) = struct('direction_id', 'V_AZ', 'vector_rad', [1; 0]);
directions(2) = struct('direction_id', 'V_EL', 'vector_rad', [0; 1]);
directions(3) = struct('direction_id', 'V_DIAG_POS', ...
    'vector_rad', [1; 1] / sqrt(2));
directions(4) = struct('direction_id', 'V_DIAG_NEG', ...
    'vector_rad', [1; -1] / sqrt(2));
separation_deg = 0.4 * 2 .^ (-(0:8));

stage6_controls_hash = stable_stage6_hash(controls);
stage6_measurement_plan_hash = stable_stage6_hash(configs, ...
    controls.measurement_version_id, controls.phase_factor, current_git_commit);
stage6_experiment_plan_hash = stable_stage6_hash(configs, centers_deg, ...
    directions, separation_deg, controls, stage6_controls_hash, ...
    stage6_measurement_plan_hash, current_git_commit);

plan = struct();
plan.controls = controls;
plan.configs = configs;
plan.centers_deg = centers_deg;
plan.directions = directions;
plan.separation_deg = separation_deg;
plan.separation_rad = deg2rad(separation_deg);
plan.stage6_controls_hash = stage6_controls_hash;
plan.stage6_measurement_plan_hash = stage6_measurement_plan_hash;
plan.stage6_experiment_plan_hash = stage6_experiment_plan_hash;
plan.current_git_commit = current_git_commit;
plan.baseline_commit = baseline_commit;
plan.statistical_scope = 'DETERMINISTIC_GEOMETRIC_VALIDATION';
end

function config = empty_config_local()
config = struct('config_id', '', 'az_beam_deg', [], 'el_beam_deg', [], ...
    'az_beam_indices', [], 'el_beam_indices', [], ...
    'noise_covariance_id', '', 'rho_el', 0, 'rho_az', 0, ...
    'is_primary_configuration', false, 'diagnostic_role', '');
end

function config = config_local(id, az, el, covariance_id, ...
    rho_el, rho_az, primary, role)
config = empty_config_local();
config.config_id = id;
config.az_beam_deg = az;
config.el_beam_deg = el;
config.az_beam_indices = 1:numel(az);
config.el_beam_indices = 1:numel(el);
config.noise_covariance_id = covariance_id;
config.rho_el = rho_el;
config.rho_az = rho_az;
config.is_primary_configuration = primary;
config.diagnostic_role = role;
end
