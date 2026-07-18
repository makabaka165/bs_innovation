function risk = build_stage7_fim_risk_table(methods, enumeration, aggregate, ...
    finite_summary)
%BUILD_STAGE7_FIM_RISK_TABLE Expose FIM and finite-sample divergences.

risk = methods(:, {'method_id','method_class','subset_id','MAC_total','B_out'});
risk.eta_design = NaN(height(risk), 1);
risk.eta_validation = NaN(height(risk), 1);
risk.eta_holdout = NaN(height(risk), 1);
risk.oracle_k_success_rate = NaN(height(risk), 1);
risk.wrong_local_peak_rate = NaN(height(risk), 1);
risk.unconditional_penalized_error = NaN(height(risk), 1);
risk.threshold_success_rate = NaN(height(risk), 1);
for index = 1:height(risk)
    fim = enumeration(enumeration.subset_id == risk.subset_id(index), :);
    finite = aggregate(aggregate.method_id == risk.method_id(index), :);
    threshold = finite_summary(finite_summary.method_id == risk.method_id(index) & ...
        finite_summary.data_split == "THRESHOLD_HOLDOUT", :);
    risk.eta_design(index) = fim.eta_design;
    risk.eta_validation(index) = fim.eta_validation;
    risk.eta_holdout(index) = fim.eta_holdout;
    risk.oracle_k_success_rate(index) = finite.oracle_k_success_rate;
    risk.wrong_local_peak_rate(index) = finite.wrong_local_peak_rate;
    risk.unconditional_penalized_error(index) = ...
        finite.unconditional_penalized_error;
    if ~isempty(threshold)
        weighted_success = sum(threshold.oracle_k_success_rate .* threshold.n_trials);
        risk.threshold_success_rate(index) = weighted_success / sum(threshold.n_trials);
    end
end
risk.similar_eta_different_wrong_peak_flag = false(height(risk), 1);
risk.higher_eta_worse_threshold_flag = false(height(risk), 1);
risk.same_cost_different_risk_flag = false(height(risk), 1);
for index = 1:height(risk)
    other = (1:height(risk)).' ~= index;
    risk.similar_eta_different_wrong_peak_flag(index) = any(other & ...
        abs(risk.eta_design - risk.eta_design(index)) <= 0.02 & ...
        abs(risk.wrong_local_peak_rate - risk.wrong_local_peak_rate(index)) >= 0.02);
    risk.higher_eta_worse_threshold_flag(index) = any(other & ...
        risk.eta_design(index) > risk.eta_design + 1e-6 & ...
        risk.threshold_success_rate(index) < risk.threshold_success_rate - 0.02);
    risk.same_cost_different_risk_flag(index) = any(other & ...
        risk.MAC_total == risk.MAC_total(index) & ...
        abs(risk.oracle_k_success_rate - risk.oracle_k_success_rate(index)) >= 0.02);
end
end
