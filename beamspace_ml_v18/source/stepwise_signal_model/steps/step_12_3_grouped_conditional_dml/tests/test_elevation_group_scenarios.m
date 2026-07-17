function [trial_table, identifiability_table, recovery_table, context] = ...
    test_elevation_group_scenarios(cfg, el_beam_deg)
%TEST_ELEVATION_GROUP_SCENARIOS Exercise all registered phase-4 scenarios.

specs = scenario_specs_local(cfg);
fixtures = cell(numel(specs) + 1, 1);
for idx = 1:numel(specs)
    fixtures{idx} = build_stage4_physical_fixture( ...
        specs(idx), cfg, el_beam_deg);
end
fixtures{end} = build_stage4_structural_fixture(cfg, el_beam_deg);

trial_rows = cell(0, 1);
ident_rows = cell(0, 1);
recovery_rows = cell(0, 1);
total_score_calls = 0;
total_svd_calls = 0;
total_runtime_sec = 0;
common_group_sum_relative_error = NaN;
max_identifiable_truth_residual = 0;

for idx = 1:numel(fixtures)
    fixture = fixtures{idx};
    [bank, candidate_parameters_deg] = build_registered_candidate_bank( ...
        fixture.search_grid_deg, fixture.Q, fixture.group_model);
    diag_opts = struct('input_kind', 'coefficient', ...
        'whitening_rank', size(fixture.Ge_true, 1), ...
        'local_manifold_bank', {bank}, ...
        'local_parameter_deg', candidate_parameters_deg, ...
        'reference_parameter_deg', fixture.eta_true_deg, ...
        'rank_multiplier', 1);
    truth_diag = diagnose_elevation_group_identifiability( ...
        fixture.Ge_true, fixture.Ce_true, diag_opts);
    diag_opts.input_kind = 'data';
    data_diag = diagnose_elevation_group_identifiability( ...
        fixture.Ge_true, fixture.Zsignal_mmv, diag_opts);
    score_opts = struct('requested_rank', fixture.Q, ...
        'rank_multiplier', 1, 'compute_projector_checks', false);
    [~, truth_rss] = beamspace_dml_score_svd( ...
        fixture.Zsignal_mmv, fixture.Ge_true, score_opts);
    total_score_calls = total_score_calls + 1;
    truth_rss_relative = truth_rss / max(norm(fixture.Zsignal_mmv, 'fro') ^ 2, ...
        realmin(class(fixture.Zsignal_mmv)));
    if strcmp(fixture.expected_status, 'GROUP_IDENTIFIABLE')
        max_identifiable_truth_residual = max(max_identifiable_truth_residual, ...
            max(fixture.truth_model_relative_residual, truth_rss_relative));
    end
    ident_pass = strcmp(truth_diag.status, fixture.expected_status) && ...
        strcmp(data_diag.status, fixture.expected_status) && ...
        truth_diag.local_alias_test_pass && ...
        fixture.truth_model_relative_residual < 5e-12 && ...
        truth_rss_relative < 5e-12;
    if strcmp(fixture.expected_status, 'GROUP_IDENTIFIABLE')
        ident_pass = ident_pass && truth_diag.rank_Ge == fixture.Q && ...
            truth_diag.rank_Ce == fixture.Q;
    else
        ident_pass = ident_pass && truth_diag.rank_Ce < fixture.Q && ...
            ~truth_diag.high_confidence_group_flag && fixture.Nphi > fixture.Q;
    end
    ident_rows{end + 1, 1} = make_ident_row_local( ...
        fixture, truth_diag, data_diag, truth_rss_relative, ident_pass); %#ok<AGROW>
    total_svd_calls = total_svd_calls + truth_diag.num_svd + ...
        data_diag.num_svd + 1;

    estimate_tic = tic;
    [est, est_debug] = estimate_elevation_groups_dml( ...
        fixture.Zemmv, fixture.Q, fixture.search_grid_deg, ...
        fixture.group_model, struct());
    estimate_runtime_sec = toc(estimate_tic);
    main_error_deg = ordered_angle_error_local( ...
        est.eta_hat_deg, fixture.eta_true_deg);
    main_pass = estimate_pass_local(est, main_error_deg, fixture);
    trial_rows{end + 1, 1} = make_trial_row_local( ...
        fixture, 'grouped_svd_dml', 'local_full_reference', est, ...
        main_error_deg, estimate_runtime_sec, main_pass); %#ok<AGROW>
    total_score_calls = total_score_calls + est.num_score_eval;
    total_svd_calls = total_svd_calls + est.num_svd;
    total_runtime_sec = total_runtime_sec + estimate_runtime_sec;

    element_tic = tic;
    [element_est, ~] = estimate_elevation_groups_dml( ...
        fixture.Zelement_mmv, fixture.Q, fixture.search_grid_deg, ...
        fixture.element_model, struct());
    element_runtime_sec = toc(element_tic);
    element_error_deg = ordered_angle_error_local( ...
        element_est.eta_hat_deg, fixture.eta_true_deg);
    element_pass = estimate_pass_local( ...
        element_est, element_error_deg, fixture);
    trial_rows{end + 1, 1} = make_trial_row_local( ...
        fixture, 'vertical_element_domain_dml', 'local_full_reference', ...
        element_est, element_error_deg, element_runtime_sec, element_pass); %#ok<AGROW>
    total_score_calls = total_score_calls + element_est.num_score_eval;
    total_svd_calls = total_svd_calls + element_est.num_svd;
    total_runtime_sec = total_runtime_sec + element_runtime_sec;

    if fixture.Q == 1
        peak_tic = tic;
        peak_est = beam_peak_baseline_local( ...
            fixture.Zel_raw, fixture.el_beam_deg);
        peak_runtime_sec = toc(peak_tic);
        peak_error_deg = ordered_angle_error_local( ...
            peak_est.eta_hat_deg, fixture.eta_true_deg);
        peak_pass = isfinite(peak_error_deg) && ...
            peak_error_deg <= max(diff(fixture.el_beam_deg));
        trial_rows{end + 1, 1} = make_trial_row_local( ...
            fixture, 'elevation_beam_peak', 'single_peak_q1_only', ...
            peak_est, peak_error_deg, peak_runtime_sec, peak_pass); %#ok<AGROW>
        total_runtime_sec = total_runtime_sec + peak_runtime_sec;
    end

    if strcmp(est.status, 'GROUP_IDENTIFIABLE')
        recovery_opts = struct('true_Ce', fixture.Ce_true, ...
            'true_Ge', fixture.Ge_true, 'rank_multiplier', 1);
        [~, ~, recovery_debug] = recover_group_azimuth_data( ...
            fixture.Zemmv, est.Ge_hat, fixture.mapping, recovery_opts);
        total_svd_calls = total_svd_calls + recovery_debug.num_svd;
        recovery_subspace_gate = recovery_subspace_gate_local(fixture.noise_kind);
        for q = 1:fixture.Q
            recovery_pass = strcmp(recovery_debug.status, ...
                'GROUP_IDENTIFIABLE') && ...
                recovery_debug.relative_fro_error_by_group(q) <= ...
                fixture.recovery_gate && ...
                recovery_debug.subspace_chordal_distance_by_group(q) <= ...
                recovery_subspace_gate && ...
                recovery_debug.max_offdiagonal_crosstalk <= 5e-9 && ...
                recovery_debug.diagonal_mixing_error <= 5e-9;
            recovery_rows{end + 1, 1} = make_recovery_row_local( ...
                fixture, q, recovery_debug, recovery_subspace_gate, ...
                recovery_pass); %#ok<AGROW>
        end
        if strcmp(fixture.scenario, 'k2_q1_common_elevation_l3')
            common_group_sum_relative_error = ...
                recovery_debug.relative_fro_error_by_group(1);
        end
    else
        rejection_pass = strcmp(fixture.expected_status, ...
            'GROUP_UNIDENTIFIABLE') && ...
            strcmp(est.status, 'GROUP_UNIDENTIFIABLE') && ...
            ~est.high_confidence_group_flag;
        recovery_rows{end + 1, 1} = make_rejection_recovery_row_local( ...
            fixture, est, rejection_pass); %#ok<AGROW>
    end

    if ~main_pass || ~element_pass || ~ident_pass
        fprintf('Scenario gate failed: %s\n', fixture.scenario);
        disp(est_debug);
    end
end

trial_table = struct2table(vertcat(trial_rows{:}));
identifiability_table = struct2table(vertcat(ident_rows{:}));
recovery_table = struct2table(vertcat(recovery_rows{:}));
if any(~trial_table.pass_flag)
    disp(trial_table(~trial_table.pass_flag, :));
end
if any(~identifiability_table.pass_flag)
    disp(identifiability_table(~identifiability_table.pass_flag, :));
end
if any(~recovery_table.pass_flag)
    disp(recovery_table(~recovery_table.pass_flag, :));
end
assert(all(trial_table.pass_flag), 'test_elevation_group_scenarios:TrialFailed', ...
    'An elevation-group estimator or baseline execution gate failed.');
assert(all(identifiability_table.pass_flag), ...
    'test_elevation_group_scenarios:IdentifiabilityFailed', ...
    'An elevation-group identifiability gate failed.');
assert(all(recovery_table.pass_flag), ...
    'test_elevation_group_scenarios:RecoveryFailed', ...
    'An elevation-group recovery gate failed.');
assert(common_group_sum_relative_error < 5e-10, ...
    'test_elevation_group_scenarios:CommonGroupSum', ...
    'The common-elevation Q1 recovery did not equal the within-group sum.');

context = struct();
context.fixtures = fixtures;
context.total_score_calls = total_score_calls;
context.total_svd_calls = total_svd_calls;
context.total_multi_start = 0;
context.total_estimator_runtime_sec = total_runtime_sec;
context.common_group_sum_relative_error = common_group_sum_relative_error;
context.max_identifiable_truth_residual = max_identifiable_truth_residual;
context.num_physical_scenarios = numel(specs);
context.num_structural_counterexamples = 1;
context.ap_pr_baseline_status = ...
    'not_run_no_audited_exact_reproduction_available';
end

function specs = scenario_specs_local(cfg)
full_aperture = 1:cfg.beam.subNaz;
center = (cfg.beam.subNaz + 1) / 2;
reduced_aperture = (center - 4):(center + 4);
specs = make_spec_local('k1_q1_l1_noiseless', ...
    [8.0, 10.0], 1, 1, full_aperture, 'none', 0, 120301, ...
    9.0:0.1:11.0, 0.051, 5e-10);
specs(end + 1) = make_spec_local('k1_q1_l4_white_noise', ...
    [8.2, 10.3], [1, exp(0.2j), 0.9 * exp(-0.3j), 1.1 * exp(0.5j)], ...
    1, full_aperture, 'white', 0.005, 120302, ...
    9.3:0.1:11.3, 0.11, 0.08);
specs(end + 1) = make_spec_local('k2_q2_distinct_elevation_l1', ...
    [7.4, 9.2; 8.8, 11.0], [1; 0.8 * exp(0.4j)], [1; 2], ...
    full_aperture, 'none', 0, 120303, 8.6:0.2:11.4, 0.101, 5e-9);
specs(end + 1) = make_spec_local('k2_q1_common_elevation_l3', ...
    [7.2, 10.0; 9.1, 10.0], ...
    [1, 0.8 * exp(0.2j), 1.1 * exp(-0.3j); ...
     0.7 * exp(0.5j), 0.9 * exp(-0.2j), 0.6 * exp(0.8j)], ...
    [1; 1], full_aperture, 'none', 0, 120304, ...
    9.0:0.1:11.0, 0.051, 5e-9);
specs(end + 1) = make_spec_local('k2_q2_extremely_close_l1', ...
    [7.5, 10.0; 9.5, 10.05], [1; 0.8 * exp(0.6j)], [1; 2], ...
    full_aperture, 'none', 0, 120305, 9.95:0.025:10.10, ...
    0.013, 5e-8);
specs(end + 1) = make_spec_local('k2_q2_weak_secondary_l4', ...
    [7.3, 9.4; 9.0, 11.2], ...
    [1, exp(0.2j), exp(-0.4j), exp(0.6j); ...
     0.03 * exp(0.1j), 0.03 * exp(-0.5j), ...
     0.03 * exp(0.7j), 0.03 * exp(-0.9j)], ...
    [1; 2], full_aperture, 'none', 0, 120306, ...
    8.8:0.2:11.6, 0.101, 5e-8);
coherent_waveform = [1, exp(0.3j), 0.9 * exp(-0.2j), 1.1 * exp(0.5j)];
specs(end + 1) = make_spec_local('k2_q2_coherent_sources_l4', ...
    [7.3, 9.4; 9.0, 11.2], ...
    [coherent_waveform; 0.7 * exp(0.4j) * coherent_waveform], ...
    [1; 2], full_aperture, 'none', 0, 120307, ...
    8.8:0.2:11.6, 0.101, 5e-8);
specs(end + 1) = make_spec_local('k2_q2_reduced_aperture_l1', ...
    [7.3, 9.4; 9.0, 11.2], [1; 0.8 * exp(0.4j)], [1; 2], ...
    reduced_aperture, 'none', 0, 120308, ...
    8.8:0.2:11.6, 0.101, 5e-8);
specs(end + 1) = make_spec_local('k2_q2_correlated_noise_l4', ...
    [7.3, 9.4; 9.0, 11.2], ...
    [1, exp(0.2j), exp(-0.4j), exp(0.6j); ...
     0.8 * exp(0.1j), 0.7 * exp(-0.5j), ...
     0.9 * exp(0.7j), 0.75 * exp(-0.9j)], ...
    [1; 2], full_aperture, 'correlated_rows_and_columns', ...
    0.003, 120309, 8.8:0.2:11.6, 0.21, 0.15);
end

function spec = make_spec_local(name, target_angles_deg, source_snapshots, ...
    group_index, aperture_index, noise_kind, noise_sigma, seed, ...
    search_grid_deg, angle_gate_deg, recovery_gate)
spec = struct();
spec.name = name;
spec.target_angles_deg = target_angles_deg;
spec.source_snapshots = source_snapshots;
spec.group_index = group_index;
spec.aperture_index = aperture_index;
spec.noise_kind = noise_kind;
spec.noise_sigma = noise_sigma;
spec.seed = seed;
spec.search_grid_deg = search_grid_deg;
spec.angle_gate_deg = angle_gate_deg;
spec.recovery_gate = recovery_gate;
end

function row = make_trial_row_local(fixture, method, search_reference, est, ...
    angle_error_deg, runtime_sec, pass_flag)
row = struct();
row.scenario = string(fixture.scenario);
row.fixture_kind = string(fixture.fixture_kind);
row.method = string(method);
row.search_reference = string(search_reference);
row.K = fixture.K;
row.oracle_Q = fixture.Q;
row.Nphi = fixture.Nphi;
row.L = fixture.L;
row.aperture_columns = numel(fixture.aperture_index);
row.noise_model = string(fixture.noise_kind);
row.truth_eta_deg = vector_text_local(fixture.eta_true_deg);
row.eta_hat_deg = vector_text_local(est.eta_hat_deg);
row.max_abs_error_deg = angle_error_deg;
row.score = est.score;
row.rss = est.rss;
row.rank_Ge = est.rank_Ge;
row.rank_Ce_hat = est.rank_Ce_hat;
row.num_score_eval = est.num_score_eval;
row.num_svd = est.num_svd;
row.num_multi_start = 0;
row.runtime_sec = runtime_sec;
row.status = string(est.status);
row.expected_status = string(fixture.expected_status);
row.high_confidence_group_flag = est.high_confidence_group_flag;
row.pass_flag = pass_flag;
row.phase_factor = 1;
end

function row = make_ident_row_local(fixture, truth_diag, data_diag, ...
    truth_rss_relative, pass_flag)
row = struct();
row.scenario = string(fixture.scenario);
row.fixture_kind = string(fixture.fixture_kind);
row.K = fixture.K;
row.oracle_Q = fixture.Q;
row.B_e = truth_diag.B_e;
row.Nphi = fixture.Nphi;
row.L = fixture.L;
row.Nphi_gt_Q_flag = fixture.Nphi > fixture.Q;
row.whitening_effective_rank = truth_diag.whitening_effective_rank;
row.rank_Ge = truth_diag.rank_Ge;
row.singular_values_Ge = vector_text_local(truth_diag.singular_values_Ge);
row.sigma_min_Ge = truth_diag.singular_values_Ge(end);
row.sigma_ratio_Ge = truth_diag.singular_values_Ge(end) / ...
    truth_diag.singular_values_Ge(1);
row.rank_threshold_Ge = truth_diag.rank_threshold_Ge;
row.rank_Ce_truth = truth_diag.rank_Ce;
row.singular_values_Ce_truth = vector_text_local(truth_diag.singular_values_Ce);
row.sigma_min_Ce_truth = truth_diag.singular_values_Ce(end);
row.sigma_ratio_Ce_truth = truth_diag.singular_values_Ce(end) / ...
    truth_diag.singular_values_Ce(1);
row.rank_threshold_Ce = truth_diag.rank_threshold_Ce;
row.rank_Ce_from_data = data_diag.rank_Ce;
row.local_alias_min_chordal_distance = ...
    truth_diag.local_alias_min_chordal_distance;
row.local_alias_tolerance = truth_diag.local_alias_tolerance;
row.local_alias_candidates_checked = ...
    truth_diag.local_alias_candidates_checked;
row.local_alias_flag = truth_diag.local_alias_flag;
row.truth_model_relative_residual = fixture.truth_model_relative_residual;
row.truth_dml_rss_relative = truth_rss_relative;
row.status = string(truth_diag.status);
row.data_status = string(data_diag.status);
row.expected_status = string(fixture.expected_status);
row.high_confidence_group_flag = truth_diag.high_confidence_group_flag;
row.pass_flag = pass_flag;
row.phase_factor = 1;
end

function row = make_recovery_row_local( ...
    fixture, q, debug, subspace_gate, pass_flag)
row = struct();
row.scenario = string(fixture.scenario);
row.group_index = q;
row.Nphi = fixture.Nphi;
row.L = fixture.L;
row.relative_fro_error = debug.relative_fro_error_by_group(q);
row.registered_fro_gate = fixture.recovery_gate;
row.subspace_chordal_distance = ...
    debug.subspace_chordal_distance_by_group(q);
row.registered_subspace_gate = subspace_gate;
row.subspace_rank_estimate = debug.subspace_rank_estimate(q);
row.subspace_rank_truth = debug.subspace_rank_truth(q);
row.max_offdiagonal_crosstalk = debug.max_offdiagonal_crosstalk;
row.diagonal_mixing_error = debug.diagonal_mixing_error;
row.rank_Ge = debug.rank_Ge;
row.rank_Ce_hat = debug.rank_Ce_hat;
row.status = string(debug.status);
row.expected_status = "GROUP_IDENTIFIABLE";
row.pass_flag = pass_flag;
row.phase_factor = 1;
end

function row = make_rejection_recovery_row_local(fixture, est, pass_flag)
row = struct();
row.scenario = string(fixture.scenario);
row.group_index = 0;
row.Nphi = fixture.Nphi;
row.L = fixture.L;
row.relative_fro_error = NaN;
row.registered_fro_gate = NaN;
row.subspace_chordal_distance = NaN;
row.registered_subspace_gate = NaN;
row.subspace_rank_estimate = NaN;
row.subspace_rank_truth = NaN;
row.max_offdiagonal_crosstalk = NaN;
row.diagonal_mixing_error = NaN;
row.rank_Ge = est.rank_Ge;
row.rank_Ce_hat = est.rank_Ce_hat;
row.status = string(est.status);
row.expected_status = "GROUP_UNIDENTIFIABLE";
row.pass_flag = pass_flag;
row.phase_factor = 1;
end

function est = beam_peak_baseline_local(Zel_raw, el_beam_deg)
energy = sum(abs(reshape(Zel_raw, size(Zel_raw, 1), [])) .^ 2, 2);
[score, index] = max(energy);
est = struct();
est.eta_hat_deg = el_beam_deg(index);
est.score = score;
est.rss = sum(energy) - score;
est.rank_Ge = NaN;
est.rank_Ce_hat = NaN;
est.num_score_eval = numel(el_beam_deg);
est.num_svd = 0;
est.status = 'BASELINE_OK';
est.high_confidence_group_flag = false;
end

function pass_flag = estimate_pass_local(est, angle_error_deg, fixture)
if strcmp(fixture.expected_status, 'GROUP_UNIDENTIFIABLE')
    pass_flag = strcmp(est.status, 'GROUP_UNIDENTIFIABLE') && ...
        ~est.high_confidence_group_flag && est.num_score_eval == 0;
else
    pass_flag = strcmp(est.status, 'GROUP_IDENTIFIABLE') && ...
        est.high_confidence_group_flag && est.rank_Ge == fixture.Q && ...
        est.rank_Ce_hat == fixture.Q && ...
        angle_error_deg <= fixture.angle_gate_deg;
end
end

function error_deg = ordered_angle_error_local(estimate_deg, truth_deg)
if numel(estimate_deg) ~= numel(truth_deg) || any(~isfinite(estimate_deg))
    error_deg = NaN;
else
    error_deg = max(abs(sort(estimate_deg(:)) - sort(truth_deg(:))));
end
end

function gate = recovery_subspace_gate_local(noise_kind)
if strcmp(noise_kind, 'none')
    gate = 5e-7;
else
    gate = 0.35;
end
end

function text = vector_text_local(values)
text = string(strtrim(sprintf('%.12g ', values)));
end
