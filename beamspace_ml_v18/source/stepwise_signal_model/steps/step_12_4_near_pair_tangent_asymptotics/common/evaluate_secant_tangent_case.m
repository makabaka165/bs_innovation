function row = evaluate_secant_tangent_case( ...
    center_deg, direction_unit_rad, separation_rad, model, opts)
%EVALUATE_SECANT_TANGENT_CASE Evaluate one registered near-pair case.

if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts, model);
validateattributes(separation_rad, {'numeric'}, ...
    {'real','finite','positive','scalar'}, mfilename, 'separation_rad');
v = direction_unit_rad(:) / norm(direction_unit_rad);
directional = build_fixed_whitened_directional_derivatives( ...
    center_deg, v, model, struct());
[~, Jg] = build_fixed_whitened_sequential_derivatives( ...
    center_deg, model, struct());
[metric, ~] = compute_projected_jacobian_metric( ...
    directional.g0, Jg, opts.metric_options);

offset_deg = rad2deg(0.5 * separation_rad * v).';
minus_deg = center_deg - offset_deg;
plus_deg = center_deg + offset_deg;
[g_minus, ~] = build_fixed_whitened_sequential_derivatives( ...
    minus_deg, model, struct());
[g_plus, ~] = build_fixed_whitened_sequential_derivatives( ...
    plus_deg, model, struct());
G2 = [g_minus, g_plus];
singular_values = svd(G2, 'econ');
sigma1_sq = singular_values(1) ^ 2;
if numel(singular_values) >= 2
    sigma2_sq = singular_values(2) ^ 2;
else
    sigma2_sq = 0;
end

q_direction = real(v' * metric.T * v);
q_at_separation = separation_rad ^ 2 * q_direction;
sigma2_prediction = 0.5 * q_at_separation;
norm_minus = norm(g_minus);
norm_plus = norm(g_plus);
rho = (g_minus' * g_plus) / (norm_minus * norm_plus);
abs_rho_raw = abs(rho);
coherence_roundoff_clipped_flag = false;
coherence_limit_tolerance = 64 * eps(class(abs_rho_raw));
if abs_rho_raw > 1 + coherence_limit_tolerance
    error('evaluate_secant_tangent_case:Coherence', ...
        'Normalized coherence exceeds one beyond roundoff.');
elseif abs_rho_raw > 1
    abs_rho = 1;
    coherence_roundoff_clipped_flag = true;
else
    abs_rho = abs_rho_raw;
end
coherence_deficit = 1 - abs_rho ^ 2;
coherence_prediction = q_at_separation / norm(directional.g0) ^ 2;

Gbar = [g_minus / norm_minus, g_plus / norm_plus];
normalized_gram_condition = cond(Gbar' * Gbar);
if abs_rho < 1
    normalized_gram_exact_from_rho = (1 + abs_rho) / (1 - abs_rho);
else
    normalized_gram_exact_from_rho = Inf;
end
normalized_gram_asymptotic = 4 * norm(directional.g0) ^ 2 / ...
    q_at_separation;
raw_gram_condition = cond(G2' * G2);

h_sum = (g_minus + g_plus) / sqrt(2);
h_difference = (g_plus - g_minus) / sqrt(2);
h_sum_prediction = sqrt(2) * (directional.g0 + ...
    separation_rad ^ 2 * directional.g2 / 8);
h_difference_prediction = separation_rad / sqrt(2) * ...
    (directional.g1 + separation_rad ^ 2 * directional.g3 / 24);
taylor_sum_residual = norm(h_sum - h_sum_prediction) / ...
    max(norm(h_sum), realmin(class(h_sum)));
taylor_difference_residual = norm(h_difference - h_difference_prediction) / ...
    max(norm(h_difference), realmin(class(h_difference)));

numeric_floor = opts.numeric_floor_multiplier * eps(class(directional.g0)) * ...
    norm(directional.g0) ^ 2;
numeric_floor_reached_flag = sigma2_prediction <= numeric_floor || ...
    sigma2_sq <= numeric_floor / 4;
direction_ratio = q_direction / max(metric.max_eigenvalue, realmin(class(q_direction)));
if q_direction <= metric.null_tolerance
    case_status = "EXACT_TANGENT_NULL";
elseif direction_ratio < opts.near_null_ratio
    case_status = "NEAR_TANGENT_NULL";
elseif numeric_floor_reached_flag
    case_status = "NUMERIC_FLOOR_REACHED";
else
    case_status = "NONDEGENERATE_TANGENT";
end

row = struct();
row.config_id = string(model.config_id);
row.center_az_deg = center_deg(1);
row.center_el_deg = center_deg(2);
row.direction_id = string(opts.direction_id);
row.direction_az_component = v(1);
row.direction_el_component = v(2);
row.separation_norm_rad = separation_rad;
row.separation_norm_deg = rad2deg(separation_rad);
row.endpoint_minus_az_deg = minus_deg(1);
row.endpoint_minus_el_deg = minus_deg(2);
row.endpoint_plus_az_deg = plus_deg(1);
row.endpoint_plus_el_deg = plus_deg(2);
row.q_direction = q_direction;
row.q_at_separation = q_at_separation;
row.sigma1_sq = sigma1_sq;
row.sigma2_sq = sigma2_sq;
row.sigma2_prediction = sigma2_prediction;
row.sigma2_ratio = sigma2_sq / sigma2_prediction;
row.abs_rho = abs_rho;
row.coherence_deficit = coherence_deficit;
row.coherence_prediction = coherence_prediction;
row.coherence_ratio = coherence_deficit / coherence_prediction;
row.normalized_gram_condition = normalized_gram_condition;
row.normalized_gram_exact_from_rho = normalized_gram_exact_from_rho;
row.normalized_gram_asymptotic = normalized_gram_asymptotic;
row.normalized_gram_ratio = normalized_gram_condition / normalized_gram_asymptotic;
row.raw_gram_condition = raw_gram_condition;
row.column_norm_minus = norm_minus;
row.column_norm_plus = norm_plus;
row.column_norm_ratio = norm_minus / norm_plus;
row.column_norm_log_ratio = log(norm_minus / norm_plus);
row.taylor_sum_residual = taylor_sum_residual;
row.taylor_difference_residual = taylor_difference_residual;
row.numeric_floor = numeric_floor;
row.numeric_floor_reached_flag = numeric_floor_reached_flag;
row.coherence_roundoff_clipped_flag = coherence_roundoff_clipped_flag;
row.Wseq_hash = string(model.Wseq_hash);
row.Cseq_hash = string(model.Cseq_hash);
row.Tseq_hash = string(model.Tseq_hash);
row.fixed_measurement_hash = string(model.fixed_measurement_hash);
row.stage6_controls_hash = string(model.stage6_controls_hash);
row.stage6_experiment_plan_hash = string(model.stage6_experiment_plan_hash);
row.phase_factor = 1;
row.case_status = case_status;
end

function opts = normalize_options_local(opts, model)
allowed = {'direction_id','numeric_floor_multiplier','near_null_ratio', ...
    'metric_options','stage6_experiment_plan_hash'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('evaluate_secant_tangent_case:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'direction_id'), opts.direction_id = 'UNSPECIFIED'; end
if ~isfield(opts, 'numeric_floor_multiplier'), opts.numeric_floor_multiplier = 4096; end
if ~isfield(opts, 'near_null_ratio'), opts.near_null_ratio = 1e-6; end
if ~isfield(opts, 'metric_options'), opts.metric_options = struct(); end
if ~isfield(opts, 'stage6_experiment_plan_hash')
    opts.stage6_experiment_plan_hash = model.stage6_experiment_plan_hash;
end
if ~strcmp(opts.stage6_experiment_plan_hash, model.stage6_experiment_plan_hash)
    error('evaluate_secant_tangent_case:PlanHash', ...
        'The case plan hash differs from the fixed measurement model.');
end
end
