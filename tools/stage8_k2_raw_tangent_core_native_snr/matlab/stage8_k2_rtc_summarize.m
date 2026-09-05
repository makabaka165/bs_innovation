function summary = stage8_k2_rtc_summarize(rows, keys)
[groups, combinations] = findgroups(rows(:,keys));
cells = cell(height(combinations),1);
for k = 1:height(combinations)
    t = rows(groups==k,:);
    valid = t(t.fit_valid,:);
    applicable = nnz(t.applicable);
    row = table2struct(combinations(k,:));
    row.total = height(t);
    row.applicable = applicable;
    row.valid = height(valid);
    row.structural_na = nnz(~t.applicable);
    row.algorithmic_invalid = nnz(t.applicable & ~t.fit_valid);
    row.valid_rate = height(valid)/applicable;
    row.localization_success_rate = nnz(t.localization_success_01bw)/applicable;
    row.resolution_success_rate = nnz(t.resolution_success)/applicable;
    for metric = ["d_max_bw","joint_RMSE_deg","axis_error_deg","rho_error_deg"]
        values = valid.(metric);
        values = values(isfinite(values));
        row.("median_"+metric) = NaN;
        row.("P90_"+metric) = NaN;
        if ~isempty(values)
            row.("median_"+metric) = median(values);
            row.("P90_"+metric) = prctile(values,90);
        end
    end
    row.runtime_total_sec = sum(t.runtime_sec);
    row.runtime_median_sec = median(t.runtime_sec(t.applicable));
    row.runtime_P90_sec = NaN;
    if applicable>0, row.runtime_P90_sec=prctile(t.runtime_sec(t.applicable),90); end
    row.score_call_count = sum(t.score_call_count);
    row.SVD_call_count = sum(t.SVD_call_count);
    row.eig_call_count = sum(t.eig_call_count);
    failed = t(~t.fit_valid,:);
    reasons = unique(failed.fit_status);
    counts = zeros(numel(reasons),1);
    for j = 1:numel(reasons), counts(j)=nnz(failed.fit_status==reasons(j)); end
    row.failure_reasons = string(jsonencode(struct('reason',reasons,'count',counts)));
    cells{k}=row;
end
summary = struct2table(vertcat(cells{:}));
end
