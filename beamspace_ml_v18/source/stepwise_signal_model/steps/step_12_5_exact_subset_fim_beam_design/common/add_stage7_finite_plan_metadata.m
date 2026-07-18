function summary = add_stage7_finite_plan_metadata(summary, finite_plan)
%ADD_STAGE7_FINITE_PLAN_METADATA Add frozen scenario inputs to summaries.

n = height(summary);
summary.element_snr_db = NaN(n, 1);
summary.separation_deg = NaN(n, 1);
summary.secondary_power_db = NaN(n, 1);
summary.L = NaN(n, 1);
summary.noise_covariance_id = strings(n, 1);
summary.mismatch_id = strings(n, 1);
summary.threshold_profile = strings(n, 1);
summary.SNR_80_crossing_db = NaN(n, 1);
for index = 1:n
    match = finite_plan.scenario_id == summary.scenario_id(index);
    if nnz(match) ~= 1
        continue;
    end
    row = finite_plan(match, :);
    summary.element_snr_db(index) = row.element_snr_db;
    summary.separation_deg(index) = row.separation_deg;
    summary.secondary_power_db(index) = row.secondary_power_db;
    summary.L(index) = row.L;
    summary.noise_covariance_id(index) = row.noise_covariance_id;
    summary.mismatch_id(index) = row.mismatch_id;
    if startsWith(row.scenario_id, "T0_")
        summary.threshold_profile(index) = "T0";
    elseif startsWith(row.scenario_id, "T1_")
        summary.threshold_profile(index) = "T1";
    end
end
profiles = ["T0";"T1"];
methods = unique(summary.method_id, 'stable');
for method_index = 1:numel(methods)
    for profile_index = 1:numel(profiles)
        selected = summary.method_id == methods(method_index) & ...
            summary.threshold_profile == profiles(profile_index);
        rows = summary(selected, :);
        if isempty(rows), continue; end
        rows = sortrows(rows, 'element_snr_db');
        crossing = crossing_local(rows.element_snr_db, ...
            rows.oracle_k_success_rate, 0.8);
        summary.SNR_80_crossing_db(selected) = crossing;
    end
end
end

function crossing = crossing_local(snr, rate, threshold)
index = find(rate >= threshold, 1);
if isempty(index)
    crossing = Inf;
elseif index == 1
    crossing = snr(1);
else
    x1 = snr(index - 1);
    x2 = snr(index);
    y1 = rate(index - 1);
    y2 = rate(index);
    if y2 == y1
        crossing = x2;
    else
        crossing = x1 + (threshold - y1) * (x2 - x1) / (y2 - y1);
    end
end
end
