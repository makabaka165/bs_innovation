function [summary, detail] = evaluate_stage7_subset(subset_row, context, opts)
%EVALUATE_STAGE7_SUBSET Evaluate one physical rectangle on every FIM scenario.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'return_detail'), opts.return_detail = false; end
if istable(subset_row)
    if height(subset_row) ~= 1
        error('evaluate_stage7_subset:SubsetRow', ...
            'subset_row must contain exactly one table row.');
    end
    elevation_integer = subset_row.elevation_mask_integer;
    azimuth_integer = subset_row.azimuth_mask_integer;
    subset_id = string(subset_row.subset_id);
else
    elevation_integer = subset_row.elevation_mask_integer;
    azimuth_integer = subset_row.azimuth_mask_integer;
    subset_id = string(subset_row.subset_id);
end
elevation_indices = find(bitget(elevation_integer, 1:5));
azimuth_indices = find(bitget(azimuth_integer, 1:5));
channels = reshape(elevation_indices(:) + (azimuth_indices(:).' - 1) * 5, 1, []);
channels = channels(:).';
models = cell(2, 1);
for noise_index = 1:2
    models{noise_index} = build_exact_subset_model( ...
        context.plan.pool, channels, context.noise_models{noise_index}, struct());
end

scenario_count = numel(context.scenarios);
eta_element = NaN(scenario_count, 1);
eta_parent = NaN(scenario_count, 1);
whitening_rank = zeros(scenario_count, 1);
manifold_rank = zeros(scenario_count, 1);
fim_rank = zeros(scenario_count, 1);
minimum_dp_eigenvalue = NaN(scenario_count, 1);
scenario_status = strings(scenario_count, 1);
data_processing_violation = false(scenario_count, 1);
start_tic = tic;
for scenario_index = 1:scenario_count
    scenario = context.scenarios(scenario_index);
    model = models{scenario.noise_index};
    T_I = model.T_I;
    G = T_I * scenario.raw_G0(channels, :);
    dG = struct('azimuth', T_I * scenario.raw_dG0_az(channels, :), ...
        'elevation', T_I * scenario.raw_dG0_el(channels, :));
    fim = effective_deterministic_fim(G, dG, scenario.S, ...
        context.plan.controls.sigma2_fim, struct());
    whitening_rank(scenario_index) = model.rank_C_I;
    manifold_rank(scenario_index) = fim.rank_G;
    fim_rank(scenario_index) = fim.rank_F;
    if scenario.element_rank < 4
        scenario_status(scenario_index) = "ELEMENT_REFERENCE_UNIDENTIFIABLE";
        continue;
    end
    retention_element = relative_fim_retention( ...
        scenario.F_element, fim.F, struct('expected_rank', 4));
    retention_parent = relative_fim_retention( ...
        scenario.F_parent, fim.F, ...
        struct('expected_rank', scenario.parent_rank));
    if model.rank_C_I < 2
        status = "SUBSET_WHITENING_RANK_INSUFFICIENT";
        eta_element(scenario_index) = 0;
    elseif fim.rank_G < 2
        status = "SUBSET_MANIFOLD_RANK_LOSS";
        eta_element(scenario_index) = 0;
    elseif fim.rank_F < scenario.element_rank
        status = "SUBSET_FIM_RANK_LOSS";
        eta_element(scenario_index) = 0;
    elseif ~isfinite(retention_element.eta)
        status = "NUMERICAL_FAILURE";
    else
        status = "FIM_SCENARIO_VALID";
        eta_element(scenario_index) = retention_element.eta;
    end
    eta_parent(scenario_index) = retention_parent.eta;
    delta_parent = 0.5 * ((scenario.F_parent - fim.F) + ...
        (scenario.F_parent - fim.F).');
    delta_element = 0.5 * ((scenario.F_element - scenario.F_parent) + ...
        (scenario.F_element - scenario.F_parent).');
    eig_parent = min(real(eig(delta_parent, 'vector')));
    eig_element = min(real(eig(delta_element, 'vector')));
    minimum_dp_eigenvalue(scenario_index) = min(eig_parent, eig_element);
    scale = max([norm(scenario.F_element, 2), ...
        norm(scenario.F_parent, 2), norm(fim.F, 2), realmin]);
    tolerance = context.plan.controls.data_processing_tolerance_multiplier * ...
        4 * eps * scale;
    if minimum_dp_eigenvalue(scenario_index) < -tolerance
        data_processing_violation(scenario_index) = true;
        status = "NUMERICAL_DATA_PROCESSING_VIOLATION";
    end
    scenario_status(scenario_index) = status;
end
runtime = toc(start_tic);

design_eta = split_min_local(eta_element, context.design_indices);
validation_eta = split_min_local(eta_element, context.validation_indices);
holdout_eta = split_min_local(eta_element, context.holdout_indices);
parent_relative_eta = split_min_local(eta_parent, context.design_indices);
worst_design = worst_id_local(eta_element, context.design_indices, context.scenarios);
worst_validation = worst_id_local( ...
    eta_element, context.validation_indices, context.scenarios);
worst_holdout = worst_id_local(eta_element, context.holdout_indices, context.scenarios);
cost = stage7_subset_cost(numel(elevation_indices), ...
    numel(azimuth_indices), context.cfg);
aggregate_status = aggregate_status_local(scenario_status, data_processing_violation);
summary = struct('subset_id', subset_id, ...
    'elevation_mask_integer', elevation_integer, ...
    'azimuth_mask_integer', azimuth_integer, ...
    'I_e_global', join(string(elevation_indices), ';'), ...
    'I_a_global', join(string(azimuth_indices), ';'), ...
    'sequential_channel_ids', join(string(channels), ';'), ...
    'B_e', cost.B_e, 'B_a', cost.B_a, 'B_out', cost.B_out, ...
    'MAC_el', cost.MAC_el, 'MAC_az', cost.MAC_az, ...
    'MAC_total', cost.MAC_total, ...
    'output_channel_count', cost.output_channel_count, ...
    'output_bytes_complex_double', cost.output_bytes_complex_double, ...
    'weight_memory_bytes', cost.weight_memory_bytes, ...
    'estimated_data_movement_bytes', cost.estimated_data_movement_bytes, ...
    'incremental_cost_over_conventional', ...
    cost.incremental_cost_over_conventional, ...
    'eta_design', design_eta, ...
    'eta_validation', validation_eta, 'eta_holdout', holdout_eta, ...
    'eta_parent_relative', parent_relative_eta, ...
    'worst_design_scenario_id', worst_design, ...
    'worst_validation_scenario_id', worst_validation, ...
    'worst_holdout_scenario_id', worst_holdout, ...
    'minimum_whitening_rank', min(whitening_rank), ...
    'minimum_manifold_rank', min(manifold_rank), ...
    'minimum_fim_rank', min(fim_rank), ...
    'data_processing_violation_count', nnz(data_processing_violation), ...
    'runtime', runtime, 'offline_subset_design_runtime', runtime, ...
    'status', aggregate_status, ...
    'covariance_decomposition_count', 2, ...
    'whitener_eigendecomposition_count', 2, ...
    'fim_evaluation_count', scenario_count, ...
    'generalized_eigenvalue_evaluation_count', 2 * scenario_count);

if opts.return_detail
    scenario_id = string({context.scenarios.scenario_id}).';
    data_split = string({context.scenarios.data_split}).';
    detail = table(repmat(subset_id, scenario_count, 1), scenario_id, ...
        data_split, eta_element, eta_parent, whitening_rank, manifold_rank, ...
        fim_rank, minimum_dp_eigenvalue, data_processing_violation, ...
        scenario_status, 'VariableNames', {'subset_id','scenario_id', ...
        'data_split','eta_element_relative','eta_parent_relative', ...
        'whitening_rank','manifold_rank','fim_rank', ...
        'minimum_data_processing_eigenvalue', ...
        'data_processing_violation_flag','status'});
else
    detail = table();
end
end

function value = split_min_local(values, indices)
selected = values(indices);
selected = selected(isfinite(selected));
if isempty(selected), value = NaN; else, value = min(selected); end
end

function id = worst_id_local(values, indices, scenarios)
selected = values(indices);
finite = isfinite(selected);
if ~any(finite)
    id = "";
    return;
end
finite_indices = indices(finite);
[~, local_index] = min(selected(finite));
id = string(scenarios(finite_indices(local_index)).scenario_id);
end

function status = aggregate_status_local(scenario_status, violation)
if any(violation)
    status = "NUMERICAL_DATA_PROCESSING_VIOLATION";
elseif any(scenario_status == "NUMERICAL_FAILURE")
    status = "NUMERICAL_FAILURE";
elseif any(scenario_status == "SUBSET_FIM_RANK_LOSS")
    status = "SUBSET_FIM_RANK_LOSS";
elseif any(scenario_status == "SUBSET_MANIFOLD_RANK_LOSS")
    status = "SUBSET_MANIFOLD_RANK_LOSS";
elseif any(scenario_status == "SUBSET_WHITENING_RANK_INSUFFICIENT")
    status = "SUBSET_WHITENING_RANK_INSUFFICIENT";
else
    status = "FIM_SCENARIO_VALID";
end
end
