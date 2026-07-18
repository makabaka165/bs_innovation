function [decision, operating_out] = apply_stage7_finite_sample_pareto_gate( ...
    operating, aggregate, strongest_fixed_method, context)
%APPLY_STAGE7_FINITE_SAMPLE_PARETO_GATE Apply the preregistered risk gate.

operating_out = operating;
operating_out.scheme_A_pass = false(height(operating), 1);
operating_out.scheme_B_pass = false(height(operating), 1);
operating_out.finite_sample_pareto_pass = false(height(operating), 1);
operating_out.strongest_fixed_baseline = ...
    repmat(string(strongest_fixed_method), height(operating), 1);
operating_out.decision_status = strings(height(operating), 1);
baseline = aggregate(aggregate.method_id == strongest_fixed_method, :);
full_parent = aggregate(aggregate.method_id == "FULL_PARENT_5X5", :);
for index = 1:height(operating)
    method = aggregate(aggregate.method_id == operating.method_id(index), :);
    if isempty(method) || ~operating.fim_gate_pass(index)
        operating_out.decision_status(index) = "FIM_GATE_REJECTED";
        continue;
    end
    cost_reduction = 1 - method.MAC_total / baseline.MAC_total;
    significant_reduction = 1 - method.MAC_total / full_parent.MAC_total >= ...
        context.plan.success.significant_cost_reduction;
    scheme_A = method.paired_success_difference_95_low >= ...
        context.plan.success.pareto_noninferiority_margin && ...
        cost_reduction >= context.plan.success.pareto_cost_reduction && ...
        method.wrong_peak_increase_95_high <= ...
        context.plan.success.pareto_wrong_peak_margin;
    scheme_B = method.MAC_total <= baseline.MAC_total && ...
        (method.paired_success_difference_95_low > 0 || ...
        method.paired_error_difference_95_high < 0) && ...
        method.paired_success_difference_vs_full_parent_95_low >= ...
        context.plan.success.pareto_noninferiority_margin && significant_reduction;
    operating_out.scheme_A_pass(index) = scheme_A;
    operating_out.scheme_B_pass(index) = scheme_B;
    operating_out.finite_sample_pareto_pass(index) = scheme_A || scheme_B;
    if scheme_A || scheme_B
        operating_out.decision_status(index) = "PARETO_GATE_PASS";
    elseif method.MAC_total < full_parent.MAC_total
        operating_out.decision_status(index) = "SYSTEM_DESIGN_ANALYSIS_ONLY";
    else
        operating_out.decision_status(index) = "STAGE7_CONTRIBUTION_REJECTED";
    end
end
any_fim = any(operating_out.fim_gate_pass);
any_pareto = any(operating_out.finite_sample_pareto_pass);
if any_fim && any_pareto
    stage_status = 'PASS_CONTRIBUTION_RETAINED';
    stage8_technical_permission = true;
elseif any_fim
    stage_status = 'PASS_SYSTEM_ANALYSIS_ONLY';
    stage8_technical_permission = false;
else
    stage_status = 'PARTIAL';
    stage8_technical_permission = false;
end
decision = struct('stage_status', stage_status, ...
    'stage8_technical_permission', stage8_technical_permission, ...
    'strongest_fixed_baseline', char(strongest_fixed_method), ...
    'fim_operating_point_pass_count', nnz(operating_out.fim_gate_pass), ...
    'finite_sample_pareto_pass_count', ...
    nnz(operating_out.finite_sample_pareto_pass), ...
    'baseline_success_rate', baseline.oracle_k_success_rate, ...
    'full_parent_success_rate', full_parent.oracle_k_success_rate);
end
