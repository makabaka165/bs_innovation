function [result_table, context] = test_separable_mmv_whitening()
%TEST_SEPARABLE_MMV_WHITENING Validate fixed row/column PSD whiteners.

V_nonorthogonal = [1, 0.2, -0.1; 0.4, 1, 0.3; ...
    -0.2, 0.5, 1; 0.7, -0.1, 0.4; 0.1, 0.6, -0.3];
cases = struct('name', {}, 'C_row', {}, 'C_col', {}, 'model', {});
cases(end + 1) = make_case_local('identity_row_and_column', ...
    eye(4), eye(3), 'identity');
cases(end + 1) = make_case_local('nonorthogonal_elevation_beams', ...
    V_nonorthogonal' * V_nonorthogonal, eye(3), 'identity');
cases(end + 1) = make_case_local('toeplitz_row_covariance', ...
    toeplitz(0.55 .^ (0:3)), eye(3), 'identity');
cases(end + 1) = make_case_local('toeplitz_column_covariance', ...
    eye(4), toeplitz(0.65 .^ (0:2)), 'toeplitz_column');
cases(end + 1) = make_case_local('correlated_rows_and_columns', ...
    toeplitz(0.45 .^ (0:3)), toeplitz(0.70 .^ (0:2)), ...
    'matrix_normal_separable_toeplitz');
cases(end + 1) = make_case_local('rank_deficient_psd', ...
    diag([3, 1, 0]), diag([2, 0]), 'rank_deficient_psd');

rows = cell(numel(cases), 1);
max_row_error = 0;
max_column_error = 0;
for idx = 1:numel(cases)
    [T_row, T_col, info] = build_separable_mmv_whiteners( ...
        cases(idx).C_row, cases(idx).C_col, struct());
    row_error = whitening_error_local(T_row, cases(idx).C_row);
    column_error = whitening_error_local(T_col, cases(idx).C_col);
    max_row_error = max(max_row_error, row_error);
    max_column_error = max(max_column_error, column_error);
    column_applied = ~strcmp(cases(idx).model, 'identity');
    rows{idx} = make_result_row_local(cases(idx).name, info.row_rank, ...
        info.column_rank, row_error, column_error, NaN, NaN, NaN, ...
        NaN, NaN, NaN, column_applied, cases(idx).model, ...
        row_error < 1e-10 && column_error < 1e-10);
end
result_table = struct2table(vertcat(rows{:}));
assert(all(result_table.pass_flag), ...
    'test_separable_mmv_whitening:Failed', ...
    'A separable row/column whitening gate failed.');

context = struct('max_row_whitening_error', max_row_error, ...
    'max_column_whitening_error', max_column_error, ...
    'num_eigendecompositions', 2 * numel(cases));
end

function c = make_case_local(name, C_row, C_col, model)
c = struct('name', name, 'C_row', C_row, 'C_col', C_col, 'model', model);
end

function value = whitening_error_local(T, C)
identity_r = eye(size(T, 1), 'like', C);
value = norm(T * C * T' - identity_r, 'fro') / ...
    max(norm(identity_r, 'fro'), realmin(class(C)));
end

function row = make_result_row_local(name, row_rank, column_rank, ...
    row_error, column_error, data_error, score_error, rss_error, ...
    data_threshold, score_threshold, rss_threshold, column_applied, ...
    column_model, pass_flag)
row = struct();
row.validation_case = string(name);
row.row_whitening_rank = row_rank;
row.column_whitening_rank = column_rank;
row.row_whitening_error = row_error;
row.column_whitening_error = column_error;
row.data_transform_relative_error = data_error;
row.score_relative_error = score_error;
row.rss_relative_error = rss_error;
row.registered_data_threshold = data_threshold;
row.registered_score_threshold = score_threshold;
row.registered_rss_threshold = rss_threshold;
row.estimate_status = "NOT_APPLICABLE_COMPONENT_VALIDATION";
row.support_status = "NOT_APPLICABLE_COMPONENT_VALIDATION";
row.statistical_calibration_status = "NOT_CALIBRATED_STAGE4";
row.registered_model_certified_flag = false;
row.structural_gate_pass_flag = false;
row.estimate_returned_flag = false;
row.observation_regime = "NOISELESS_STRUCTURAL";
row.coefficient_rank_evidence_kind = "NOISELESS_EXACT_DATA";
row.column_whitening_applied = column_applied;
row.column_covariance_model = string(column_model);
row.truth_on_registered_grid_flag = false;
row.search_domain_source = "not_applicable_component_validation";
row.pass_flag = pass_flag;
row.phase_factor = 1;
end
