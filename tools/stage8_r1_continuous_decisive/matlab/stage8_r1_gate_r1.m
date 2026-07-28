function result = stage8_r1_gate_r1(repo_dir, output_root)
%STAGE8_R1_GATE_R1 Verify continuous optimizer correctness and determinism.

repo_dir = char(string(repo_dir));
output_root = char(string(output_root));
tool_dir = fileparts(mfilename('fullpath'));
addpath(tool_dir);
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if ~isfolder(output_root), mkdir(output_root); end
result_path = fullfile(output_root, 'gate_r1_result.json');
result = struct('gate_r1_pass', false, 'status', 'R1_FAIL_STOPPED', ...
    'checked_utc', utc_now_local(), 'last_error', '');
stage8_r1_write_json_atomic(result_path, result);
try
    context = stage8_r1_context(repo_dir, true);
    fixtures = stage8_r1_build_registry(context, 'R2');
    details = repmat(struct('trial_id', '', 'scientific_hash_left', '', ...
        'scientific_hash_right', '', 'deterministic', false, ...
        'monotonic', false, 'in_bounds', false, 'continuous_not_snapped', false, ...
        'continuous_k1_not_worse_than_m0', false, ...
        'truth_isolated', false), height(fixtures), 1);
    all_pass = true;
    for index = 1:height(fixtures)
        [left_rows, left_diag] = stage8_r1_evaluate_trial(fixtures(index, :), context);
        [right_rows, right_diag] = stage8_r1_evaluate_trial(fixtures(index, :), context);
        left_scientific = zero_runtime_local(left_rows);
        right_scientific = zero_runtime_local(right_rows);
        left_hash = stage8_stable_hash('STAGE8_R1_GATE_R1_ROW_V1', ...
            left_scientific, scientific_audit_local(left_diag));
        right_hash = stage8_stable_hash('STAGE8_R1_GATE_R1_ROW_V1', ...
            right_scientific, scientific_audit_local(right_diag));
        deterministic = strcmp(left_hash, right_hash) && ...
            numeric_table_equal_local(left_scientific, right_scientific);
        audit = left_diag.optimizer_audit;
        available = [audit.initialization_available_flag];
        initial_scores = [audit.initial_score];
        final_scores = [audit.final_score];
        finite_scores = isfinite(initial_scores) & isfinite(final_scores);
        scored = available & finite_scores;
        score_scale = max(1, max(abs(initial_scores(scored))));
        monotonic = all([audit.monotonicity_violation_count] == 0) && ...
            all(final_scores(scored) >= initial_scores(scored) - ...
            64 * eps(score_scale));
        bounds = context.plan.local_domain.domain_bounds_deg;
        angle_cells = {audit.final_angles_deg};
        in_bounds = true;
        for cell_index = 1:numel(angle_cells)
            angles = angle_cells{cell_index};
            if isempty(angles) || any(~isfinite(angles(:))), continue; end
            in_bounds = in_bounds && all(angles(:, 1) >= bounds(1) & ...
                angles(:, 1) <= bounds(2) & angles(:, 2) >= bounds(3) & ...
                angles(:, 2) <= bounds(4));
        end
        m0 = left_rows.method_id == "M0_FIXED_GRID_REGISTERED_STAGE8";
        continuous = startsWith(left_rows.method_id, "M1_") | ...
            startsWith(left_rows.method_id, "M2_");
        continuous_valid_k1 = continuous & left_rows.fit1_valid;
        no_worse = all(left_rows.rss1(continuous_valid_k1) <= ...
            left_rows.rss1(m0) + 64 * eps(max(1, left_rows.rss1(m0))));
        not_snapped = not_snapped_local(left_rows(continuous_valid_k1, :), ...
            context.plan.local_domain.candidate_points_deg);
        truth_isolated = ~any(left_rows.truth_used_in_initialization_flag) && ...
            ~any(left_rows.truth_used_in_fit_flag) && ...
            ~any(left_rows.truth_used_in_lrt_flag) && ...
            ~left_diag.truth_used_in_initialization_flag && ...
            ~left_diag.truth_used_in_fit_flag && ~left_diag.truth_used_in_lrt_flag;
        details(index) = struct('trial_id', char(fixtures.trial_id(index)), ...
            'scientific_hash_left', left_hash, ...
            'scientific_hash_right', right_hash, ...
            'deterministic', deterministic, 'monotonic', monotonic, ...
            'in_bounds', in_bounds, 'continuous_not_snapped', not_snapped, ...
            'continuous_k1_not_worse_than_m0', no_worse, ...
            'truth_isolated', truth_isolated);
        all_pass = all_pass && deterministic && monotonic && in_bounds && ...
            no_worse && truth_isolated;
        if fixtures.support_or_difficulty(index) == "INSIDE_OFF_GRID"
            all_pass = all_pass && not_snapped;
        end
    end
    if ~all_pass
        error('stage8_r1_gate_r1:Contract', ...
            'One or more continuous optimizer requirements failed.');
    end
    result = struct('gate_r1_pass', true, ...
        'status', 'R1_OPTIMIZER_DETERMINISM_PASS', ...
        'checked_utc', utc_now_local(), 'fixture_count', height(fixtures), ...
        'details', details, 'last_error', '');
    stage8_r1_write_json_atomic(result_path, result);
catch exception
    result.checked_utc = utc_now_local();
    result.last_error = getReport(exception, 'extended', 'hyperlinks', 'off');
    stage8_r1_write_json_atomic(result_path, result);
    rethrow(exception);
end
clear path_cleanup
end

function value = scientific_audit_local(diagnostics)
value = diagnostics.optimizer_audit;
end

function rows = zero_runtime_local(rows)
names = {'runtime_sec','shared_initialization_runtime_sec', ...
    'initialization_runtime_sec','refinement_runtime_sec'};
for index = 1:numel(names), rows.(names{index})(:) = 0; end
end

function pass = numeric_table_equal_local(left, right)
pass = isequal(left.Properties.VariableNames, right.Properties.VariableNames);
if ~pass, return; end
for index = 1:width(left)
    a = left{:, index};
    b = right{:, index};
    if isnumeric(a)
        pass = isequal(num2hex(double(a)), num2hex(double(b)));
    elseif islogical(a)
        pass = isequal(a, b);
    elseif isstring(a) || ischar(a)
        pass = isequal(a, b);
    end
    if ~pass, return; end
end
end

function pass = not_snapped_local(rows, points)
pass = false;
for index = 1:height(rows)
    angle = [rows.k1_estimate_az_deg(index), rows.k1_estimate_el_deg(index)];
    if any(~isfinite(angle)), continue; end
    distance = sqrt(sum((points - angle) .^ 2, 2));
    pass = pass || min(distance) > 1e-8;
end
end

function value = utc_now_local()
value = char(datetime('now', 'TimeZone', 'UTC', ...
    'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
