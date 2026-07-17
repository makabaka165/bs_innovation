function [result_table, context] = test_noisy_rank_is_diagnostic_only()
%TEST_NOISY_RANK_IS_DIAGNOSTIC_ONLY Ensure noisy numeric rank is not certification.

rng(120311, 'twister');
model = struct();
model.V = eye(3);
model.whitener = eye(3);
model.z_el_m = [0; 0.25; 0.5];
model.lambda = 1;
model.phase_factor = 1;
model.model_id = 'noisy_rank_diagnostic_unit_test';
grid_deg = [-20, 0, 20];
[Ge, ~] = build_elevation_group_manifold([-20, 20], model, struct());
Ce_rank_one = [1, 2, 3, 4; exp(0.4j) * [1, 2, 3, 4]];
noise = 1e-8 * complex(randn(3, 4), randn(3, 4));
Zel_raw = reshape(Ge * Ce_rank_one + noise, 3, 4, 1);
[data, ~] = prepare_elevation_group_mmv_data( ...
    Zel_raw, eye(3), eye(4), struct( ...
    'observation_regime', 'NOISY_UNCALIBRATED', ...
    'column_covariance_model', 'identity'));
[est, ~] = estimate_elevation_groups_dml( ...
    data, 2, grid_deg, model, struct());
pass_flag = est.rank_Ce_hat_diagnostic == 2 && ...
    est.rank_Z_score_diagnostic >= 2 && ...
    strcmp(est.estimate_status, 'ESTIMATE_RETURNED') && ...
    strcmp(est.support_status, ...
    'GROUP_REGISTERED_MODEL_SUPPORTED_UNCALIBRATED') && ...
    ~est.registered_model_certified_flag && ...
    strcmp(est.statistical_calibration_status, 'NOT_CALIBRATED_STAGE4') && ...
    strcmp(est.coefficient_rank_evidence_kind, 'NOISY_DIAGNOSTIC_ONLY');

row = struct();
row.case_name = "noisy_rank_one_coefficient_becomes_numeric_full_rank";
row.estimate_status = string(est.estimate_status);
row.support_status = string(est.support_status);
row.statistical_calibration_status = ...
    string(est.statistical_calibration_status);
row.registered_model_certified_flag = ...
    est.registered_model_certified_flag;
row.structural_gate_pass_flag = est.structural_gate_pass_flag;
row.estimate_returned_flag = est.estimate_returned_flag;
row.observation_regime = string(data.observation_regime);
row.coefficient_rank_evidence_kind = ...
    string(est.coefficient_rank_evidence_kind);
row.row_whitening_rank = data.row_whitening_rank;
row.column_whitening_rank = data.column_whitening_rank;
row.column_whitening_applied = data.column_whitening_applied;
row.column_covariance_model = string(data.column_covariance_model);
row.truth_on_registered_grid_flag = true;
row.search_domain_source = "registered_noisy_rank_unit_test_grid";
row.rank_Ge = est.rank_Ge;
row.rank_Ce_hat_diagnostic = est.rank_Ce_hat_diagnostic;
row.rank_Z_score_diagnostic = est.rank_Z_score_diagnostic;
row.rank_Z_recovery_diagnostic = est.rank_Z_recovery_diagnostic;
row.registered_bank_exact_alias_flag = false;
row.old_confidence_field_absent_flag = ...
    ~isfield(est, 'high_confidence_group_flag');
row.num_svd = est.num_svd;
row.pass_flag = pass_flag;
row.phase_factor = 1;
result_table = struct2table(row);
assert(pass_flag, 'test_noisy_rank_is_diagnostic_only:Failed', ...
    'Noisy numerical rank incorrectly affected structural certification.');
context = struct('num_svd', est.num_svd, ...
    'num_score_eval', est.num_score_eval);
end
