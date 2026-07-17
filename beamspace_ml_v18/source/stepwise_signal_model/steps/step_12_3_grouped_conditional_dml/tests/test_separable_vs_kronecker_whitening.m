function [result_table, context] = test_separable_vs_kronecker_whitening()
%TEST_SEPARABLE_VS_KRONECKER_WHITENING Compare the small explicit reference.

rng(120310, 'twister');
B = 4;
Nphi = 3;
Q = 2;
A_row = complex(randn(B), randn(B));
A_col = complex(randn(Nphi), randn(Nphi));
C_row = A_row * A_row' + 0.5 * eye(B);
C_col = A_col * A_col' + 0.5 * eye(Nphi);
[T_row, T_col, whitening_info] = ...
    build_separable_mmv_whiteners(C_row, C_col, struct());
Z = complex(randn(B, Nphi), randn(B, Nphi));
G_raw = complex(randn(B, Q), randn(B, Q));
G = T_row * G_raw;

Z_separable = T_row * Z * T_col';
K_small = kron(conj(T_col), T_row);
z_explicit = K_small * Z(:);
data_error = norm(Z_separable(:) - z_explicit) / ...
    norm(Z_separable(:));

score_opts = struct('requested_rank', Q, 'rank_multiplier', 1, ...
    'compute_projector_checks', false);
[score_separable, rss_separable] = beamspace_dml_score_svd( ...
    Z_separable, G, score_opts);
G_explicit = kron(eye(size(T_col, 1)), G);
explicit_opts = struct('requested_rank', Q * size(T_col, 1), ...
    'rank_multiplier', 1, 'compute_projector_checks', false);
[score_explicit, rss_explicit] = beamspace_dml_score_svd( ...
    z_explicit, G_explicit, explicit_opts);
score_error = abs(score_separable - score_explicit) / ...
    max(abs(score_separable), realmin(class(score_separable)));
rss_error = abs(rss_separable - rss_explicit) / ...
    max(abs(rss_separable), realmin(class(rss_separable)));
pass_flag = data_error < 1e-12 && score_error < 1e-10 && ...
    rss_error < 1e-10;

row = struct();
row.validation_case = "small_explicit_kronecker_reference";
row.row_whitening_rank = whitening_info.row_rank;
row.column_whitening_rank = whitening_info.column_rank;
row.row_whitening_error = whitening_info.row_whitening_error;
row.column_whitening_error = whitening_info.column_whitening_error;
row.data_transform_relative_error = data_error;
row.score_relative_error = score_error;
row.rss_relative_error = rss_error;
row.registered_data_threshold = 1e-12;
row.registered_score_threshold = 1e-10;
row.registered_rss_threshold = 1e-10;
row.estimate_status = "NOT_APPLICABLE_COMPONENT_VALIDATION";
row.support_status = "NOT_APPLICABLE_COMPONENT_VALIDATION";
row.statistical_calibration_status = "NOT_CALIBRATED_STAGE4";
row.registered_model_certified_flag = false;
row.structural_gate_pass_flag = false;
row.estimate_returned_flag = false;
row.observation_regime = "NOISELESS_STRUCTURAL";
row.coefficient_rank_evidence_kind = "NOISELESS_EXACT_DATA";
row.column_whitening_applied = true;
row.column_covariance_model = "small_complex_hermitian_reference";
row.truth_on_registered_grid_flag = false;
row.search_domain_source = "not_applicable_component_validation";
row.pass_flag = pass_flag;
row.phase_factor = 1;
result_table = struct2table(row);
assert(pass_flag, 'test_separable_vs_kronecker_whitening:Failed', ...
    'Separable and explicit Kronecker whitening are inconsistent.');

context = struct('data_transform_relative_error', data_error, ...
    'score_relative_error', score_error, 'rss_relative_error', rss_error, ...
    'explicit_kronecker_bytes', 16 * numel(K_small), ...
    'num_svd', 2, 'num_eigendecompositions', 2);
end
