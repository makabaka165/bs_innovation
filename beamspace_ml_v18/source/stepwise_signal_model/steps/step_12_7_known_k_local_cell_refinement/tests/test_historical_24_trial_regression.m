function audit = test_historical_24_trial_regression(repo_dir)
%TEST_HISTORICAL_24_TRIAL_REGRESSION Stop on incompatible K1 history.
%
% The final interface mandates one conventional K1 path for CORE_LITE and
% CORE_PLUS. This preflight proves whether that path can simultaneously
% satisfy the requested H1/H2 bit-level regression before any new trial is
% generated.

path_now = fullfile(repo_dir, 'innovation-mining', ...
    '27_stage8_core_v2_1_safe_hybrid_trials.csv');
historical = readtable(path_now, 'TextType', 'string');
k1 = historical(historical.truth_K == 1, :);
fields = {'final_angles','RSS','loglik','fit_valid','solver_status', ...
    'element_trial_hash'};
differences = strings(0, 1);
ids = unique(k1.trial_id, 'stable');
for index = 1:numel(ids)
    rows = k1(k1.trial_id == ids(index), :);
    h1 = rows(rows.method_id == "H1_DIRECT_SAFE_HYBRID_KNOWN_K", :);
    h2 = rows(rows.method_id == "H2_GROUPED_SAFE_HYBRID_KNOWN_K", :);
    if height(h1) ~= 1 || height(h2) ~= 1
        error('test_historical_24_trial_regression:HistoricalShape', ...
            'Historical H1/H2 K1 pairing is incomplete.');
    end
    for field_index = 1:numel(fields)
        field = fields{field_index};
        if ~isequaln(h1.(field), h2.(field))
            differences(end + 1, 1) = ids(index) + ":" + string(field); %#ok<AGROW>
        end
    end
end
if ~isempty(differences)
    error('test_historical_24_trial_regression:IncompatibleK1History', ...
        ['F1_FAIL_STOPPED: final K1 requires the same conventional path ' ...
        'for CORE_LITE/CORE_PLUS, but historical H1/H2 differ in %s.'], ...
        strjoin(cellstr(differences), ', '));
end
audit = struct('status', 'F1_HISTORICAL_24_TRIAL_REGRESSION_PASS', ...
    'historical_k1_trial_count', numel(ids), ...
    'same_k1_path_required', true, ...
    'h1_h2_scientific_difference_count', 0, ...
    'differences', differences);
end
