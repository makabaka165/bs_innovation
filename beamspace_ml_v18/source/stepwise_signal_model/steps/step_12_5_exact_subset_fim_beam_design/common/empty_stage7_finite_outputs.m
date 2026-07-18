function [trials, summary, aggregate, risk, complexity] = ...
    empty_stage7_finite_outputs(methods, enumeration)
%EMPTY_STAGE7_FINITE_OUTPUTS Mark finite sampling as not run after FIM rejection.

trials = table();
data_split = strings(0, 1);
scenario_id = strings(0, 1);
method_id = strings(0, 1);
method_class = strings(0, 1);
subset_id = strings(0, 1);
n_trials = zeros(0, 1);
oracle_k_success_rate = zeros(0, 1);
wrong_local_peak_rate = zeros(0, 1);
element_snr_db = zeros(0, 1);
threshold_profile = strings(0, 1);
summary = table(data_split, scenario_id, method_id, method_class, subset_id, ...
    n_trials, oracle_k_success_rate, wrong_local_peak_rate, ...
    element_snr_db, threshold_profile);
aggregate = table();
risk = methods(:, {'method_id','method_class','subset_id','MAC_total','B_out'});
risk.eta_design = NaN(height(risk), 1);
risk.eta_validation = NaN(height(risk), 1);
risk.eta_holdout = NaN(height(risk), 1);
risk.oracle_k_success_rate = NaN(height(risk), 1);
risk.wrong_local_peak_rate = NaN(height(risk), 1);
risk.unconditional_penalized_error = NaN(height(risk), 1);
risk.threshold_success_rate = NaN(height(risk), 1);
risk.similar_eta_different_wrong_peak_flag = false(height(risk), 1);
risk.higher_eta_worse_threshold_flag = false(height(risk), 1);
risk.same_cost_different_risk_flag = false(height(risk), 1);
for index = 1:height(risk)
    row = enumeration(enumeration.subset_id == risk.subset_id(index), :);
    risk.eta_design(index) = row.eta_design;
    risk.eta_validation(index) = row.eta_validation;
    risk.eta_holdout(index) = row.eta_holdout;
end
complexity = struct('trial_method_row_count', 0, ...
    'actual_unique_subset_score_calls', 0, ...
    'actual_unique_subset_svd_calls', 0, ...
    'charged_method_score_calls', 0, 'charged_method_svd_calls', 0, ...
    'runtime_sec', 0);
end
