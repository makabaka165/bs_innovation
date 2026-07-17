function suite = run_stage5_method_suite(fixture, trial_id)
%RUN_STAGE5_METHOD_SUITE Run the registered stage-5 methods on shared data.

locked = fixture.locked;
reference = run_local_full_dml_reference( ...
    fixture.full_data, fixture.K, fixture.domain, fixture.full_model);
estimated_chain = run_stage5_conditional_chain( ...
    fixture, fixture.stage4_est.eta_hat_deg, 'ESTIMATED_ELEVATION');

main_opts = joint_options_local(locked, fixture, true, ...
    'METHOD_AND_UPSTREAM_REGISTERED_MODEL');
[main_estimate, main_history, main_debug] = refine_joint_sequential_dml( ...
    fixture.full_data, estimated_chain.initial_angles_deg, fixture.domain, ...
    fixture.full_model, main_opts);
main_estimate.method_estimate_status = main_estimate.joint_refinement_status;
main_history = annotate_history_local(main_history, fixture, trial_id, ...
    'MAIN_GROUPED_CONDITIONAL_JOINT', 1);

[conditional_score, conditional_rss, conditional_rank] = ...
    evaluation_score_local(estimated_chain.initial_angles_deg, fixture);
conditional_estimate = estimate_from_angles_local( ...
    estimated_chain.initial_angles_deg, conditional_score, conditional_rss, ...
    conditional_rank, estimated_chain.returned_flag, ...
    'GROUPED_CONDITIONAL_RETURNED');

[conventional_angles, conventional_info] = ...
    conventional_dbf_angles_local(fixture);
direct_starts = direct_start_bank_local( ...
    conventional_angles, fixture.Q, fixture.oracle_Kq, fixture.domain, locked);
direct_estimates = cell(size(direct_starts, 3), 1);
direct_histories = cell(size(direct_starts, 3), 1);
direct_debug = cell(size(direct_starts, 3), 1);
direct_opts = joint_options_local(locked, fixture, false, 'METHOD_ONLY');
for start_index = 1:size(direct_starts, 3)
    [direct_estimates{start_index}, history_now, direct_debug{start_index}] = ...
        refine_joint_sequential_dml(fixture.full_data, ...
        direct_starts(:, :, start_index), fixture.domain, ...
        fixture.full_model, direct_opts);
    direct_histories{start_index} = annotate_history_local( ...
        history_now, fixture, trial_id, ...
        'DIRECT_AP_COORDINATE_ASCENT_FIXED_CENTER', start_index);
end
direct_estimate = select_best_estimate_local(direct_estimates);
direct_estimate.method_estimate_status = direct_estimate.joint_refinement_status;
direct_counts = sum_direct_counts_local(direct_estimates, direct_debug);

[conventional_score, conventional_rss, conventional_rank] = ...
    evaluation_score_local(conventional_angles, fixture);
conventional_estimate = estimate_from_angles_local( ...
    conventional_angles, conventional_score, conventional_rss, ...
    conventional_rank, true, 'CONVENTIONAL_DBF_RETURNED');
reference_estimate = estimate_from_angles_local( ...
    reference.angles_hat_deg, reference.score, reference.rss, ...
    reference.rank_Gseq, strcmp(reference.status, ...
    'LOCAL_FULL_REFERENCE_RETURNED'), reference.status);

rows = cell(5, 1);
rows{1} = method_row_local(fixture, trial_id, ...
    'MAIN_GROUPED_CONDITIONAL_JOINT', main_estimate, reference, ...
    estimated_chain, main_debug, main_cost_local(fixture, estimated_chain, ...
    main_estimate, main_debug), 'ESTIMATED_ELEVATION', ...
    fixture.stage4_est.eta_hat_deg, ...
    'METHOD_AND_UPSTREAM_REGISTERED_MODEL', ...
    main_estimate.joint_refinement_status);
rows{2} = method_row_local(fixture, trial_id, ...
    'GROUPED_CONDITIONAL_ONLY', conditional_estimate, reference, ...
    estimated_chain, struct('monotonicity_violation_count', 0), ...
    conditional_cost_local(fixture, estimated_chain), ...
    'ESTIMATED_ELEVATION', fixture.stage4_est.eta_hat_deg, ...
    'METHOD_AND_UPSTREAM_REGISTERED_MODEL', 'NOT_RUN_BY_METHOD');
rows{3} = method_row_local(fixture, trial_id, ...
    'DIRECT_AP_COORDINATE_ASCENT_FIXED_CENTER', direct_estimate, reference, ...
    empty_chain_local(fixture), direct_counts, ...
    direct_cost_local(fixture, direct_counts), ...
    'NOT_APPLICABLE_BASELINE', NaN(1, fixture.Q), ...
    'METHOD_ONLY', direct_estimate.joint_refinement_status);
rows{4} = method_row_local(fixture, trial_id, ...
    'LOCAL_FULL_DML_REFERENCE', reference_estimate, reference, ...
    empty_chain_local(fixture), struct('monotonicity_violation_count', 0), ...
    reference_cost_local(fixture, reference), ...
    'NOT_APPLICABLE_REFERENCE', NaN(1, fixture.Q), ...
    'METHOD_ONLY', 'NOT_RUN_BY_REFERENCE');
rows{5} = method_row_local(fixture, trial_id, ...
    'CONVENTIONAL_DBF', conventional_estimate, reference, ...
    empty_chain_local(fixture), struct('monotonicity_violation_count', 0), ...
    conventional_cost_local(fixture, conventional_info), ...
    'NOT_APPLICABLE_BASELINE', NaN(1, fixture.Q), ...
    'METHOD_ONLY', 'NOT_RUN_BY_METHOD');

suite = struct();
suite.method_table = struct2table(vertcat(rows{:}));
suite.history_table = vertcat_nonempty_local( ...
    [{main_history}; direct_histories(:)]);
suite.conditional_table = conditional_rows_local( ...
    fixture, estimated_chain, trial_id);
suite.reference = reference;
suite.estimated_chain = estimated_chain;
suite.main_estimate = main_estimate;
suite.direct_estimate = direct_estimate;
suite.conventional_angles = conventional_angles;
suite.direct_start_count = size(direct_starts, 3);
end

function row = method_row_local(fixture, trial_id, method, estimate, ...
    reference, chain, debug, cost, condition_source, eta_condition, ...
    method_scope, joint_status)
angles = estimate.angles_hat_deg;
returned = estimate.estimate_returned_flag && ...
    isequal(size(angles), size(fixture.spec.target_angles_deg)) && ...
    all(isfinite(angles(:)));
if returned
    [matched, match] = match_target_sets( ...
        angles, fixture.spec.target_angles_deg, struct());
    max_az_error = max(abs(matched(:, 1) - ...
        fixture.spec.target_angles_deg(:, 1)));
    max_el_error = max(abs(matched(:, 2) - ...
        fixture.spec.target_angles_deg(:, 2)));
else
    match = empty_match_local();
    max_az_error = Inf;
    max_el_error = Inf;
end
[truth_in_domain, truth_on_grid] = domain_flags_local( ...
    fixture.spec.target_angles_deg, fixture.domain);
success = returned && truth_in_domain && ...
    max_az_error <= fixture.locked.success_gate_az_deg && ...
    max_el_error <= fixture.locked.success_gate_el_deg;
wrong_peak = returned && truth_in_domain && ...
    match.pair_rmse_deg > fixture.locked.wrong_peak_gate_pair_deg;
if success
    penalized_error = match.pair_rmse_deg;
else
    penalized_error = fixture.locked.penalty_pair_error_deg;
end
if isfinite(estimate.score) && isfinite(reference.score)
    normalized_gap = (reference.score - estimate.score) / ...
        max(abs(reference.score), eps);
else
    normalized_gap = NaN;
end

row = struct();
row.scenario = string(fixture.spec.name);
row.data_split = string(fixture.spec.data_split);
row.trial_id = trial_id;
row.method = string(method);
row.K = fixture.K;
row.oracle_Q = fixture.Q;
row.oracle_Kq = string(vector_text_local(fixture.oracle_Kq));
row.condition_source = string(condition_source);
row.eta_condition_deg = string(vector_text_local(eta_condition));
row.upstream_group_support_status = string(fixture.stage4_est.support_status);
row.conditional_estimate_status = string(chain_status_local(chain));
row.joint_refinement_status = string(joint_status);
row.method_estimate_status = string(estimate.method_estimate_status);
row.method_status_scope = string(method_scope);
row.statistical_calibration_status = "NOT_CALIBRATED_STAGE5";
row.domain_id = string(fixture.domain.domain_id);
row.domain_source = string(fixture.domain.domain_source);
row.domain_bounds = string(fixture.domain.domain_bounds);
row.domain_hash = string(fixture.domain.domain_hash);
row.truth_in_domain_flag = truth_in_domain;
row.truth_on_search_grid_flag = truth_on_grid;
row.grid_step_az_deg = fixture.domain.grid_step_az_deg;
row.grid_step_el_deg = fixture.domain.grid_step_el_deg;
row.az_hat_deg = string(vector_text_local(angles(:, 1).'));
row.el_hat_deg = string(vector_text_local(angles(:, 2).'));
row.score = estimate.score;
row.rss = estimate.rss;
row.normalized_score_gap_to_local_full = normalized_gap;
row.az_rmse = match.azimuth_rmse_deg;
row.el_rmse = match.elevation_rmse_deg;
row.pair_rmse = match.pair_rmse_deg;
row.unconditional_penalized_pair_error = penalized_error;
row.success_flag = success;
row.wrong_local_peak_flag = wrong_peak;
row.convergence_flag = contains(string(joint_status), "CONVERGED") || ...
    any(strcmp(method, {'GROUPED_CONDITIONAL_ONLY', ...
    'LOCAL_FULL_DML_REFERENCE','CONVENTIONAL_DBF'})) && returned;
row.rank_Gphi_min = min_chain_rank_local(chain);
row.group_recovery_relative_error = group_recovery_error_local(fixture);
row.cross_group_noise_correlation_max = ...
    cross_group_correlation_local(fixture.noise_model);
row.monotonicity_violation_count = debug.monotonicity_violation_count;
row.num_score_eval_stage4 = cost.num_score_eval_stage4;
row.num_score_eval_conditional = cost.num_score_eval_conditional;
row.num_score_eval_joint = cost.num_score_eval_joint;
row.num_score_eval_total = cost.num_score_eval_total;
row.num_svd_total = cost.num_svd_total;
row.num_eig_total = cost.num_eig_total;
row.num_candidate_manifold_build = cost.num_candidate_manifold_build;
row.num_iterations = cost.num_iterations;
row.num_multi_start = cost.num_multi_start;
row.runtime_total = cost.runtime_total;
row.precompute_time_sec = cost.precompute_time_sec;
row.online_time_sec = cost.online_time_sec;
row.max_primary_array_bytes = max_primary_bytes_local(fixture);
row.registered_model_certified_flag = ...
    strcmp(method_scope, 'METHOD_AND_UPSTREAM_REGISTERED_MODEL') && ...
    fixture.stage4_est.registered_model_certified_flag;
row.phase_factor = 1;
row.pass_flag = contract_pass_local(row, returned, method);
end

function cost = main_cost_local(fixture, chain, estimate, debug)
cost = blank_cost_local(fixture);
cost.num_score_eval_stage4 = fixture.stage4_est.num_score_eval;
cost.num_score_eval_conditional = chain.num_score_eval;
cost.num_score_eval_joint = estimate.num_score_eval;
cost.num_score_eval_total = cost.num_score_eval_stage4 + ...
    cost.num_score_eval_conditional + cost.num_score_eval_joint;
cost.num_svd_total = fixture.stage4_est.num_svd + ...
    fixture.recovery_debug.num_svd + fixture.noise_model.num_svd + ...
    chain.num_svd + estimate.num_svd;
cost.num_eig_total = 2 + chain.num_eig + 1;
cost.num_candidate_manifold_build = ...
    chain_candidate_count_local(chain) + debug.num_candidate_manifold_build;
cost.num_iterations = estimate.iteration_count;
cost.num_multi_start = fixture.locked.main_num_multi_start;
cost.precompute_time_sec = fixture.common_precompute_runtime_sec + ...
    fixture.stage4_precompute_runtime_sec + chain.precompute_runtime_sec;
cost.online_time_sec = fixture.stage4_runtime_sec + ...
    fixture.recovery_noise_runtime_sec + chain.online_runtime_sec + ...
    estimate.runtime;
cost.runtime_total = cost.precompute_time_sec + cost.online_time_sec;
end

function cost = conditional_cost_local(fixture, chain)
cost = blank_cost_local(fixture);
cost.num_score_eval_stage4 = fixture.stage4_est.num_score_eval;
cost.num_score_eval_conditional = chain.num_score_eval;
cost.num_score_eval_total = cost.num_score_eval_stage4 + ...
    cost.num_score_eval_conditional;
cost.num_svd_total = fixture.stage4_est.num_svd + ...
    fixture.recovery_debug.num_svd + fixture.noise_model.num_svd + chain.num_svd;
cost.num_eig_total = 2 + chain.num_eig;
cost.num_candidate_manifold_build = chain_candidate_count_local(chain);
cost.num_multi_start = 1;
cost.precompute_time_sec = fixture.common_precompute_runtime_sec + ...
    fixture.stage4_precompute_runtime_sec + chain.precompute_runtime_sec;
cost.online_time_sec = fixture.stage4_runtime_sec + ...
    fixture.recovery_noise_runtime_sec + chain.online_runtime_sec;
cost.runtime_total = cost.precompute_time_sec + cost.online_time_sec;
end

function cost = direct_cost_local(fixture, counts)
cost = blank_cost_local(fixture);
cost.num_score_eval_joint = counts.num_score_eval;
cost.num_score_eval_total = counts.num_score_eval;
cost.num_svd_total = counts.num_svd;
cost.num_eig_total = 1;
cost.num_candidate_manifold_build = counts.num_candidate_manifold_build;
cost.num_iterations = counts.num_iterations;
cost.num_multi_start = counts.num_multi_start;
cost.precompute_time_sec = fixture.common_precompute_runtime_sec;
cost.online_time_sec = counts.runtime;
cost.runtime_total = cost.precompute_time_sec + cost.online_time_sec;
end

function cost = reference_cost_local(fixture, reference)
cost = blank_cost_local(fixture);
cost.num_score_eval_joint = reference.num_score_eval;
cost.num_score_eval_total = reference.num_score_eval;
cost.num_svd_total = reference.num_svd;
cost.num_eig_total = 1;
cost.num_candidate_manifold_build = reference.num_candidate_manifold_build;
cost.num_multi_start = 1;
cost.precompute_time_sec = fixture.common_precompute_runtime_sec;
cost.online_time_sec = reference.runtime_sec;
cost.runtime_total = cost.precompute_time_sec + cost.online_time_sec;
end

function cost = conventional_cost_local(fixture, info)
cost = blank_cost_local(fixture);
cost.num_candidate_manifold_build = 0;
cost.num_multi_start = 1;
cost.precompute_time_sec = fixture.common_precompute_runtime_sec;
cost.online_time_sec = info.runtime_sec;
cost.runtime_total = cost.precompute_time_sec + cost.online_time_sec;
end

function cost = blank_cost_local(~)
cost = struct('num_score_eval_stage4', 0, ...
    'num_score_eval_conditional', 0, 'num_score_eval_joint', 0, ...
    'num_score_eval_total', 0, 'num_svd_total', 0, 'num_eig_total', 0, ...
    'num_candidate_manifold_build', 0, 'num_iterations', 0, ...
    'num_multi_start', 0, 'runtime_total', 0, ...
    'precompute_time_sec', 0, 'online_time_sec', 0);
end

function opts = joint_options_local(locked, fixture, require_gate, scope)
opts = struct('max_iter', locked.max_iter, ...
    'relative_score_tolerance', locked.relative_score_tolerance, ...
    'angle_tolerance_deg', locked.angle_tolerance_deg, ...
    'require_upstream_group_gate', require_gate, ...
    'upstream_estimate_returned_flag', ...
    fixture.stage4_est.estimate_returned_flag, ...
    'upstream_structural_gate_pass_flag', ...
    fixture.stage4_est.structural_gate_pass_flag, ...
    'upstream_group_support_status', fixture.stage4_est.support_status, ...
    'method_status_scope', scope, 'num_multi_start', 1);
end

function [angles, info] = conventional_dbf_angles_local(fixture)
start_tic = tic;
power = sum(abs(fixture.full_data.Zseq_raw) .^ 2, 2);
[~, order] = sort(power, 'descend');
B_el = numel(fixture.locked.el_beam_deg);
beam_angles = zeros(numel(order), 2);
for idx = 1:numel(order)
    column = order(idx);
    el_index = mod(column - 1, B_el) + 1;
    az_index = floor((column - 1) / B_el) + 1;
    az = fixture.locked.az_beam_deg(az_index);
    el = fixture.locked.el_beam_deg(el_index);
    [~, iaz] = min(abs(fixture.domain.az_grid_deg - az));
    [~, iel] = min(abs(fixture.domain.el_grid_deg - el));
    beam_angles(idx, :) = [fixture.domain.az_grid_deg(iaz), ...
        fixture.domain.el_grid_deg(iel)];
end
beam_angles = unique(beam_angles, 'rows', 'stable');
if size(beam_angles, 1) < fixture.K
    error('run_stage5_method_suite:ConventionalPeaks', ...
        'The conventional beam bank did not provide K distinct centers.');
end
angles = canonicalize_local(beam_angles(1:fixture.K, :));
info = struct('runtime_sec', toc(start_tic), ...
    'beam_candidates_checked', numel(power));
end

function starts = direct_start_bank_local(conventional, Q, Kq, domain, locked)
K = sum(Kq);
if locked.direct_num_multi_start ~= 2
    error('run_stage5_method_suite:DirectStartBudget', ...
        'The registered direct baseline requires exactly two starts.');
end
fixed = zeros(K, 2);
row = 0;
if Q == 1
    az_offsets = linspace(-0.4, 0.4, Kq(1));
    for idx = 1:Kq(1)
        row = row + 1;
        fixed(row, :) = [locked.conventional_center_deg(1) + az_offsets(idx), ...
            locked.conventional_center_deg(2)];
    end
else
    group_elevation = linspace(min(domain.el_grid_deg), ...
        max(domain.el_grid_deg), Q);
    for q = 1:Q
        az_offsets = linspace(-0.2, 0.2, Kq(q));
        for idx = 1:Kq(q)
            row = row + 1;
            fixed(row, :) = [locked.conventional_center_deg(1) + ...
                az_offsets(idx), group_elevation(q)];
        end
    end
end
fixed = snap_to_domain_local(fixed, domain);
starts = zeros(K, 2, 2);
starts(:, :, 1) = conventional;
starts(:, :, 2) = canonicalize_local(fixed);
end

function estimate = select_best_estimate_local(estimates)
score = cellfun(@(x) x.score, estimates);
score(~isfinite(score)) = -Inf;
[~, best] = max(score);
estimate = estimates{best};
estimate.num_multi_start = numel(estimates);
end

function counts = sum_direct_counts_local(estimates, debug)
counts = struct();
counts.num_score_eval = sum(cellfun(@(x) x.num_score_eval, estimates));
counts.num_svd = sum(cellfun(@(x) x.num_svd, estimates));
counts.num_candidate_manifold_build = sum(cellfun( ...
    @(x) x.num_candidate_manifold_build, debug));
counts.num_iterations = sum(cellfun(@(x) x.iteration_count, estimates));
counts.num_multi_start = numel(estimates);
counts.runtime = sum(cellfun(@(x) x.runtime, estimates));
counts.monotonicity_violation_count = sum(cellfun( ...
    @(x) x.monotonicity_violation_count, debug));
end

function estimate = estimate_from_angles_local(angles, score, rss, rank_G, ...
    returned, status)
estimate = struct('angles_hat_deg', angles, 'score', score, 'rss', rss, ...
    'rank_Gseq', rank_G, 'estimate_returned_flag', returned, ...
    'method_estimate_status', status, 'joint_refinement_status', ...
    'NOT_RUN_BY_METHOD', 'num_score_eval', 0, 'num_svd', 0, ...
    'iteration_count', 0, 'runtime', 0);
end

function [score, rss, rank_G] = evaluation_score_local(angles, fixture)
if ~isequal(size(angles), [fixture.K, 2]) || any(~isfinite(angles(:)))
    score = NaN;
    rss = NaN;
    rank_G = 0;
    return;
end
[G, ~, info] = build_full_sequential_local_manifold( ...
    angles, fixture.full_model, struct());
rank_G = info.rank_Gseq;
if rank_G < fixture.K
    score = NaN;
    rss = NaN;
else
    [score, rss] = beamspace_dml_score_svd( ...
        fixture.full_data.Zseq_white, G, ...
        struct('requested_rank', fixture.K, ...
        'compute_projector_checks', false));
end
end

function table_out = conditional_rows_local(fixture, chain, trial_id)
rows = cell(fixture.Q, 1);
for q = 1:fixture.Q
    estimate = chain.group_estimate{q};
    relative_error = NaN;
    if ~isempty(fixture.Xphi_hat)
        relative_error = norm(fixture.Xphi_hat{q} - fixture.Xphi_true{q}, 'fro') / ...
            max(norm(fixture.Xphi_true{q}, 'fro'), eps);
    end
    rows{q} = struct('scenario', string(fixture.spec.name), ...
        'data_split', string(fixture.spec.data_split), 'trial_id', trial_id, ...
        'group_index', q, 'oracle_Kq', fixture.oracle_Kq(q), ...
        'condition_source', string(chain.source_name), ...
        'eta_condition_deg', chain.eta_condition_deg(q), ...
        'upstream_group_support_status', ...
        string(fixture.stage4_est.support_status), ...
        'conditional_estimate_status', ...
        string(estimate.conditional_estimate_status), ...
        'az_hat_deg', string(vector_text_local(estimate.az_hat_deg)), ...
        'score', estimate.score, 'rss', estimate.rss, ...
        'rank_Gphi', estimate.rank_Gphi, ...
        'group_noise_scale', fixture.noise_model.group_noise_scale(q), ...
        'group_recovery_relative_error', relative_error, ...
        'num_score_eval', estimate.num_score_eval, ...
        'num_svd', estimate.num_svd, ...
        'runtime_sec', estimate.runtime, ...
        'fixed_measurement_hash', string(estimate.fixed_measurement_hash), ...
        'domain_hash', string(fixture.domain.domain_hash), ...
        'statistical_calibration_status', "NOT_CALIBRATED_STAGE5", ...
        'pass_flag', estimate.estimate_returned_flag, 'phase_factor', 1);
end
table_out = struct2table(vertcat(rows{:}));
end

function history = annotate_history_local(history, fixture, trial_id, method, start_id)
count = height(history);
history = addvars(history, repmat(string(fixture.spec.name), count, 1), ...
    repmat(string(fixture.spec.data_split), count, 1), ...
    repmat(trial_id, count, 1), repmat(string(method), count, 1), ...
    repmat(start_id, count, 1), ...
    repmat(string(fixture.domain.domain_hash), count, 1), ...
    'Before', 1, 'NewVariableNames', {'scenario','data_split', ...
    'trial_id','method','start_id','domain_hash'});
end

function table_out = vertcat_nonempty_local(tables)
keep = ~cellfun(@isempty, tables);
if any(keep)
    table_out = vertcat(tables{keep});
else
    table_out = table();
end
end

function [in_domain, on_grid] = domain_flags_local(angles, domain)
bounds = domain.domain_bounds_deg;
in_domain = all(angles(:, 1) >= bounds(1) & angles(:, 1) <= bounds(2) & ...
    angles(:, 2) >= bounds(3) & angles(:, 2) <= bounds(4));
on_grid = true;
tolerance = 64 * eps(max(1, max(abs(domain.candidate_points_deg(:)))));
for idx = 1:size(angles, 1)
    on_grid = on_grid && ...
        min(abs(domain.az_grid_deg - angles(idx, 1))) <= tolerance && ...
        min(abs(domain.el_grid_deg - angles(idx, 2))) <= tolerance;
end
end

function match = empty_match_local()
match = struct('azimuth_rmse_deg', NaN, 'elevation_rmse_deg', NaN, ...
    'pair_rmse_deg', NaN);
end

function status = chain_status_local(chain)
if isempty(chain.group_estimate)
    status = 'NOT_APPLICABLE_METHOD';
    return;
end
values = cellfun(@(x) x.conditional_estimate_status, ...
    chain.group_estimate, 'UniformOutput', false);
status = strjoin(unique(values, 'stable'), ';');
end

function value = min_chain_rank_local(chain)
if isempty(chain.group_estimate)
    value = NaN;
else
    value = min(cellfun(@(x) x.rank_Gphi, chain.group_estimate));
end
end

function value = chain_candidate_count_local(chain)
value = 0;
for idx = 1:numel(chain.group_debug)
    value = value + chain.group_debug{idx}.num_candidate_manifold_build;
end
end

function value = group_recovery_error_local(fixture)
if isempty(fixture.Xphi_hat)
    value = NaN;
    return;
end
error_by_group = zeros(fixture.Q, 1);
for q = 1:fixture.Q
    error_by_group(q) = norm(fixture.Xphi_hat{q} - ...
        fixture.Xphi_true{q}, 'fro') / ...
        max(norm(fixture.Xphi_true{q}, 'fro'), eps);
end
value = max(error_by_group);
end

function value = cross_group_correlation_local(model)
if size(model.cross_group_noise_correlation, 1) < 2
    value = 0;
    return;
end
matrix = model.cross_group_noise_correlation;
matrix(1:size(matrix, 1) + 1:end) = 0;
value = max(abs(matrix(:)));
end

function value = max_primary_bytes_local(fixture)
complex_bytes = 16;
real_bytes = 8;
sizes = [complex_bytes * numel(fixture.Ycanonical), ...
    complex_bytes * numel(fixture.Wseq), ...
    complex_bytes * numel(fixture.full_data.Zseq_white), ...
    real_bytes * numel(fixture.full_model.Cseq)];
value = max(sizes);
end

function flag = contract_pass_local(row, returned, method)
if any(strcmp(method, {'MAIN_GROUPED_CONDITIONAL_JOINT', ...
        'GROUPED_CONDITIONAL_ONLY'})) && ...
        strcmp(row.upstream_group_support_status, 'GROUP_MMV_RANK_UNCERTIFIED')
    flag = ~returned;
else
    flag = returned && row.phase_factor == 1 && ...
        strcmp(row.statistical_calibration_status, 'NOT_CALIBRATED_STAGE5');
end
end

function chain = empty_chain_local(fixture)
chain = struct('group_estimate', {cell(0, 1)}, ...
    'group_debug', {cell(0, 1)}, 'num_score_eval', 0, 'num_svd', 0, ...
    'num_eig', 0, 'runtime_sec', 0, 'precompute_runtime_sec', 0, ...
    'online_runtime_sec', 0, 'return_flag', false, ...
    'initial_angles_deg', NaN(fixture.K, 2));
end

function angles = snap_to_domain_local(angles, domain)
for idx = 1:size(angles, 1)
    [~, iaz] = min(abs(domain.az_grid_deg - angles(idx, 1)));
    [~, iel] = min(abs(domain.el_grid_deg - angles(idx, 2)));
    angles(idx, :) = [domain.az_grid_deg(iaz), domain.el_grid_deg(iel)];
end
end

function angles = canonicalize_local(angles)
[~, order] = sortrows([angles(:, 2), angles(:, 1)], [1, 2]);
angles = angles(order, :);
end

function text = vector_text_local(value)
text = strtrim(sprintf('%.12g ', value));
end
