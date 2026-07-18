function plan = build_stage7_locked_plan(cfg, repo_dir, step_dir, opts)
%BUILD_STAGE7_LOCKED_PLAN Freeze every design and holdout object.

if nargin < 4 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
if isstring(step_dir), step_dir = char(step_dir); end
if ~(ischar(step_dir) && isrow(step_dir) && exist(step_dir, 'dir') == 7)
    error('build_stage7_locked_plan:StepDir', ...
        'step_dir must identify the Stage 7 implementation directory.');
end
if ~strcmp(version('-release'), '2022b')
    error('build_stage7_locked_plan:MatlabRelease', ...
        'Stage 7 is registered for MATLAB R2022b.');
end
baseline_commit = 'ea1c0320b7ba9639d6d955a1a45037cdc6cfdb31';
read_stage7_git_provenance( ...
    repo_dir, baseline_commit, opts.git_provenance_options);

pool = build_stage7_candidate_pool(cfg);
subset_family = enumerate_stage7_rectangular_subsets(pool, cfg);
source_profiles = source_profiles_local();
design_scenarios = design_scenarios_local(source_profiles);
validation_scenarios = validation_scenarios_local(source_profiles);
fim_holdout_scenarios = fim_holdout_scenarios_local();
finite_sample_plan = finite_sample_plan_local();

controls = struct();
controls.phase_factor = 1;
controls.sigma2_fim = 1;
controls.rank_multiplier = 1;
controls.derivative_relative_error_gate = 1e-6;
controls.schur_relative_error_gate = 1e-9;
controls.covariance_formula_error_gate = 1e-12;
controls.covariance_monte_carlo_error_gate = 0.04;
controls.invariance_relative_error_gate = 1e-9;
controls.data_processing_tolerance_multiplier = 4096;
controls.eta_tolerance_multiplier = 4096;
controls.eta_operating_points = [0.80, 0.90, 0.95];
controls.stage6_evidence_bundle_hash = ...
    '0c1f444603398e03865043af4e4c6e4a414dd15a3cc90e0539b19c56e990c839';
controls.fim_holdout_seed = 20260718;
controls.finite_sample_nmc = 200;
controls.method_version = 'STEP12_5_EXACT_RECTANGULAR_SUBSET_FIM_V1';
controls.source_pool_status = pool.source_status;

solver = struct();
solver.az_grid_deg = 7.4:0.1:8.6;
solver.el_grid_deg = 9.6:0.1:10.4;
solver.max_iter = 4;
solver.relative_score_tolerance = 1e-10;
solver.angle_tolerance_deg = 0;
solver.multi_start_count = 1;
solver.initialization_id = 'DATA_DRIVEN_SINGLETON_PEAKS_COMMON_RULE_V1';
solver.coordinate_update_order = 'target_then_azimuth_then_elevation';
solver.manifold_rank_multiplier = 1;
solver.search_domain_source = 'REGISTERED_STAGE7_PARENT_POOL_DOMAIN';

cost = struct();
cost.formula_id = 'TWO_STAGE_RECTANGULAR_SEQUENTIAL_DBF_MAC_V1';
cost.N_el = cfg.arr.Nel;
cost.N_az = cfg.beam.subNaz;
cost.complex_double_bytes = 16;
cost.tie_break = 'MAC_TOTAL_BOUT_INCREMENTAL_COST_GLOBAL_ID_LEXICOGRAPHIC';
cost.conventional_center_deg = [8, 10];
cost.online_benchmark_seed = 20260718;
cost.online_benchmark_batch_samples = 256;
cost.online_benchmark_repeats = 20;
cost.online_benchmark_warmup_count = 3;
cost.online_benchmark_status = ...
    'POST_FREEZE_DIAGNOSTIC_NOT_USED_FOR_SELECTION';

success = struct();
success.azimuth_gate_deg = 0.21;
success.elevation_gate_deg = 0.21;
success.wrong_peak_pair_gate_deg = 0.45;
success.unconditional_penalty_deg = sqrt(0.6 ^ 2 + 0.2 ^ 2);
success.pareto_noninferiority_margin = -0.02;
success.pareto_wrong_peak_margin = 0.02;
success.pareto_cost_reduction = 0.20;
success.significant_cost_reduction = 0.05;
success.interval_id = 'WILSON_AND_PAIRED_NORMAL_95_NO_BOOTSTRAP';
success.pareto_risk_splits = ["NORMAL_HOLDOUT";"THRESHOLD_HOLDOUT"; ...
    "MISMATCH_HOLDOUT";"STRESS_HOLDOUT"];

prior_art = struct();
prior_art.chepuri_leus_status = ...
    'INDEPENDENT_OBSERVATION_REFERENCE_NOT_PHYSICAL_SUBSET';
prior_art.liu_2026_status = 'EXACT_REPRODUCTION_UNAVAILABLE';
prior_art.legacy_greedy_b7_status = ...
    'LEGACY_FACTOR2_OR_NONSEQUENTIAL_NOT_COMPARABLE';
prior_art.continuous_svd_status = 'UNCONSTRAINED_SUBSPACE_REFERENCE';
prior_art.direct_identical_complete_algorithm_found = false;

hashes = struct();
hashes.stage7_candidate_pool_hash = stage7_stable_hash( ...
    pool.table, pool.W0, pool.array_geometry_hash);
hashes.stage7_subset_family_hash = stage7_stable_hash(subset_family);
hashes.stage7_source_profile_hash = stage7_stable_hash(source_profiles);
hashes.stage7_design_scenario_hash = stage7_stable_hash(design_scenarios);
hashes.stage7_validation_scenario_hash = stage7_stable_hash(validation_scenarios);
hashes.stage7_fim_holdout_hash = stage7_stable_hash(fim_holdout_scenarios);
hashes.stage7_finite_sample_plan_hash = stage7_stable_hash(finite_sample_plan);
hashes.stage7_controls_hash = stage7_stable_hash( ...
    controls, solver, cost, success, prior_art);
stable_plan_hashes = hashes;
provenance_inputs = struct('baseline_commit', baseline_commit, ...
    'stable_plan_hashes', stable_plan_hashes, ...
    'stage6_evidence_bundle_hash', controls.stage6_evidence_bundle_hash, ...
    'phase_factor', controls.phase_factor, ...
    'matlab_release_contract', 'MATLAB_R2022b');
provenance = build_stage7_provenance_contract( ...
    repo_dir, provenance_inputs, opts);
hashes.stage7_source_tree_hash = provenance.stage7_source_tree_hash;
hashes.stage7_dependency_tree_hash = provenance.stage7_dependency_tree_hash;
hashes.stage7_provenance_hash = provenance.stage7_provenance_hash;
hashes.stage6_evidence_bundle_hash = controls.stage6_evidence_bundle_hash;
hashes.stage7_plan_hash = stage7_stable_hash(baseline_commit, ...
    stable_plan_hashes, hashes.stage7_source_tree_hash, ...
    hashes.stage7_dependency_tree_hash, hashes.stage7_provenance_hash, ...
    pool.W0_hash, cfg.arr.lambda, 'MATLAB_R2022b');

plan = struct();
plan.baseline_commit = baseline_commit;
plan.runtime_head_commit = provenance.runtime_head_commit;
plan.origin_main_commit = provenance.origin_main_commit;
plan.baseline_ancestor_flag = provenance.baseline_ancestor_flag;
plan.working_tree_clean_at_start = provenance.working_tree_clean_at_start;
plan.provenance_status = provenance.provenance_status;
plan.matlab_release = 'R2022b';
plan.pool = pool;
plan.subset_family = subset_family;
plan.source_profiles = source_profiles;
plan.design_scenarios = design_scenarios;
plan.validation_scenarios = validation_scenarios;
plan.fim_holdout_scenarios = fim_holdout_scenarios;
plan.finite_sample_plan = finite_sample_plan;
plan.local_domain_deg = [7.4, 8.6; 9.6, 10.4];
plan.noise_profile_ids = ["WHITE"; "STAGE5_TOEPLITZ_CORRELATED"];
plan.controls = controls;
plan.solver = solver;
plan.cost = cost;
plan.success = success;
plan.prior_art = prior_art;
plan.hashes = hashes;
plan.source_manifest = provenance.source_manifest;
plan.dependency_manifest = provenance.dependency_manifest;
plan.source_scope_version = provenance.source_scope_version;
plan.dependency_scope_version = provenance.dependency_scope_version;
plan.provenance_contract_version = provenance.provenance_contract_version;
plan.phase_factor = 1;
plan.plan_freeze_status = 'FROZEN_BEFORE_ANY_STAGE7_FIM_RESULT';
end

function profiles = source_profiles_local()
profile_id = ["P0";"P1";"P2";"P3";"V0";"V1";"V2"];
split = [repmat("DESIGN", 4, 1); repmat("VALIDATION", 3, 1)];
L = [4;4;4;4;8;4;8];
secondary_power_db = [0;-6;0;-6;-3;-12;0];
correlation_magnitude = [0;0;0.9;0.9;0.5;0;0.99];
correlation_phase_rad = [0;0;0;pi/2;pi/3;0;pi/2];
profiles = table(profile_id, split, L, secondary_power_db, ...
    correlation_magnitude, correlation_phase_rad);
end

function scenarios = design_scenarios_local(profiles)
centers = [8.0,10.0;7.6,9.8;7.6,10.2;8.4,9.8;8.4,10.2];
directions = [1,0;0,1;1,1;1,-1];
directions(3:4, :) = directions(3:4, :) / sqrt(2);
separations = [0.05,0.10,0.20,0.40];
profiles = profiles(profiles.split == "DESIGN", :);
scenarios = scenario_product_local('D', 'DESIGN', centers, directions, ...
    separations, profiles, ["WHITE";"STAGE5_TOEPLITZ_CORRELATED"]);
scenarios.holdout_seed = NaN(height(scenarios), 1);
scenarios.sampling_rule = repmat("REGISTERED_CARTESIAN_PRODUCT", ...
    height(scenarios), 1);
if height(scenarios) ~= 640
    error('build_stage7_locked_plan:DesignCount', ...
        'The design registry must contain 640 scenarios.');
end
end

function scenarios = validation_scenarios_local(profiles)
centers = [7.6,10.0;8.0,9.8;8.0,10.2;8.4,10.0];
angles = deg2rad([22.5;67.5;-22.5;-67.5]);
directions = [cos(angles), sin(angles)];
separations = [0.075,0.15,0.30];
profiles = profiles(profiles.split == "VALIDATION", :);
scenarios = scenario_product_local('V', 'VALIDATION', centers, directions, ...
    separations, profiles, ["WHITE";"STAGE5_TOEPLITZ_CORRELATED"]);
scenarios.holdout_seed = NaN(height(scenarios), 1);
scenarios.sampling_rule = repmat("REGISTERED_CARTESIAN_PRODUCT", ...
    height(scenarios), 1);
if height(scenarios) ~= 288
    error('build_stage7_locked_plan:ValidationCount', ...
        'The validation registry must contain 288 scenarios.');
end
end

function scenarios = scenario_product_local(prefix, split, centers, ...
    directions, separations, profiles, noise_ids)
rows = cell(0, 1);
index = 0;
for center_index = 1:size(centers, 1)
    for direction_index = 1:size(directions, 1)
        for separation_index = 1:numel(separations)
            for profile_index = 1:height(profiles)
                for noise_index = 1:numel(noise_ids)
                    index = index + 1;
                    direction = directions(direction_index, :);
                    separation = separations(separation_index);
                    targets = [centers(center_index, :) - separation * direction / 2; ...
                        centers(center_index, :) + separation * direction / 2];
                    rows{index, 1} = scenario_row_local( ...
                        sprintf('%s%04d', prefix, index), split, ...
                        centers(center_index, :), direction, separation, ...
                        targets, profiles(profile_index, :), noise_ids(noise_index));
                end
            end
        end
    end
end
scenarios = struct2table(vertcat(rows{:}));
end

function row = scenario_row_local(id, split, center, direction, separation, ...
    targets, profile, noise_id)
row = struct('scenario_id', string(id), 'data_split', string(split), ...
    'center_az_deg', center(1), 'center_el_deg', center(2), ...
    'direction_az_component', direction(1), ...
    'direction_el_component', direction(2), ...
    'separation_deg', separation, ...
    'target1_az_deg', targets(1, 1), 'target1_el_deg', targets(1, 2), ...
    'target2_az_deg', targets(2, 1), 'target2_el_deg', targets(2, 2), ...
    'source_profile_id', profile.profile_id, 'L', profile.L, ...
    'secondary_power_db', profile.secondary_power_db, ...
    'correlation_magnitude', profile.correlation_magnitude, ...
    'correlation_phase_rad', profile.correlation_phase_rad, ...
    'noise_covariance_id', string(noise_id), ...
    'registered_domain_pass', domain_pass_local(targets));
end

function scenarios = fim_holdout_scenarios_local()
rng(20260718, 'twister');
rows = cell(256, 1);
noise_ids = [repmat("WHITE", 128, 1); ...
    repmat("STAGE5_TOEPLITZ_CORRELATED", 128, 1)];
noise_ids = noise_ids(randperm(256));
rho_values = [0, 0.5, 0.9, 0.99];
for index = 1:256
    accepted = false;
    while ~accepted
        center = [7.4 + 1.2 * rand, 9.6 + 0.8 * rand];
        angle = 2 * pi * rand;
        direction = [cos(angle), sin(angle)];
        separation = exp(log(0.05) + rand * log(0.4 / 0.05));
        targets = [center - separation * direction / 2; ...
            center + separation * direction / 2];
        accepted = domain_pass_local(targets);
    end
    L_values = [4, 8];
    profile = table("H", "FIM_HOLDOUT", ...
        L_values(randi(2)), -12 + 12 * rand, ...
        rho_values(randi(4)), 2 * pi * rand, 'VariableNames', ...
        {'profile_id','split','L','secondary_power_db', ...
        'correlation_magnitude','correlation_phase_rad'});
    rows{index} = scenario_row_local(sprintf('H%04d', index), ...
        'FIM_HOLDOUT', center, direction, separation, targets, ...
        profile, noise_ids(index));
end
scenarios = struct2table(vertcat(rows{:}));
scenarios.holdout_seed = repmat(20260718, height(scenarios), 1);
scenarios.sampling_rule = repmat( ...
    "REGISTERED_UNIFORM_CENTER_WITH_DOMAIN_REJECTION", height(scenarios), 1);
end

function plan = finite_sample_plan_local()
rows = cell(0, 1);
normal = [ ...
    8.0,10.0,0,0.2,0,4,0,0,0,0; ...
    8.0,10.0,90,0.4,-6,8,0.5,pi/3,1,5; ...
    8.0,10.0,45,0.2,-6,4,0.5,pi/3,1,10; ...
    8.0,10.0,0,0.4,0,8,0,0,0,5; ...
    8.0,10.0,90,0.2,0,4,0,0,0,10; ...
    8.0,10.0,-45,0.4,-6,8,0.5,pi/3,1,0];
for index = 1:size(normal, 1)
    rows{end + 1, 1} = finite_row_local(sprintf('N%d', index - 1), ...
        'NORMAL_HOLDOUT', normal(index, :), 200, 270000 + index, 'NONE'); %#ok<AGROW>
end
snr_grid = -15:3:9;
for index = 1:numel(snr_grid)
    values = [8,10,0,0.2,-3,4,0.5,0,0,snr_grid(index)];
    rows{end + 1, 1} = finite_row_local(sprintf('T0_%+03d', snr_grid(index)), ...
        'THRESHOLD_HOLDOUT', values, 200, 271000 + index, 'NONE'); %#ok<AGROW>
    values = [8,10,45,0.1,-6,8,0.9,0,1,snr_grid(index)];
    rows{end + 1, 1} = finite_row_local(sprintf('T1_%+03d', snr_grid(index)), ...
        'THRESHOLD_HOLDOUT', values, 200, 272000 + index, 'NONE'); %#ok<AGROW>
end
base = [8,10,45,0.2,-3,4,0.5,pi/3,1,5];
mismatch_ids = ["M0_COVARIANCE";"M1_GAIN_PHASE"; ...
    "M2_POSITION";"M3_CHANNEL_FAILURE"];
for index = 1:numel(mismatch_ids)
    rows{end + 1, 1} = finite_row_local(sprintf('M%d', index - 1), ...
        'MISMATCH_HOLDOUT', base, 200, 273000 + index, mismatch_ids(index)); %#ok<AGROW>
end
stress = [8,10,0,0.6,20*log10(0.12),4,1,0.4,0,NaN];
row = finite_row_local('S0_STAGE5_COHERENT_WEAK', 'STRESS_HOLDOUT', ...
    stress, 200, 274001, 'STAGE5_COHERENT_WEAK');
row.noise_sigma_override = 0.004;
rows{end + 1, 1} = row;
plan = struct2table(vertcat(rows{:}));
end

function row = finite_row_local(id, split, values, nmc, seed, mismatch_id)
noise_ids = ["WHITE", "STAGE5_TOEPLITZ_CORRELATED"];
row = struct('scenario_id', string(id), 'data_split', string(split), ...
    'K', 2, 'center_az_deg', values(1), 'center_el_deg', values(2), ...
    'direction_angle_deg', values(3), 'separation_deg', values(4), ...
    'secondary_power_db', values(5), 'L', values(6), ...
    'correlation_magnitude', values(7), ...
    'correlation_phase_rad', values(8), ...
    'noise_covariance_id', noise_ids(values(9) + 1), ...
    'element_snr_db', values(10), 'Nmc', nmc, 'seed', seed, ...
    'mismatch_id', string(mismatch_id), 'noise_sigma_override', NaN);
end

function pass = domain_pass_local(targets)
pass = all(targets(:, 1) >= 7.4 & targets(:, 1) <= 8.6 & ...
    targets(:, 2) >= 9.6 & targets(:, 2) <= 10.4);
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_stage7_locked_plan:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'git_provenance_options'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_stage7_locked_plan:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'git_provenance_options')
    opts.git_provenance_options = struct();
end
end
