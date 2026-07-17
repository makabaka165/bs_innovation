function [est, debug] = estimate_elevation_groups_dml( ...
    data, group_count_Q, search_domain, model, opts)
%ESTIMATE_ELEVATION_GROUPS_DML Estimate oracle-known elevation groups by DML.

if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
data = validate_data_bundle_local(data);
Q = validate_group_count_local(group_count_Q);
[candidate_parameters_deg, grid_deg] = ...
    build_candidates_local(search_domain, Q);
validate_model_contract_local(model, data);

num_candidates = size(candidate_parameters_deg, 1);
B_e = size(data.Z_score_mmv, 1);
[rank_Z_score, singular_values_Z_score, threshold_Z_score] = ...
    stable_matrix_rank(data.Z_score_mmv, opts.rank_multiplier);
[rank_Z_recovery, singular_values_Z_recovery, threshold_Z_recovery] = ...
    stable_matrix_rank(data.Z_recovery_mmv, opts.rank_multiplier);

est = empty_estimate_local(Q, B_e, size(data.Z_recovery_mmv, 2));
est.rank_Z_score_diagnostic = rank_Z_score;
est.singular_values_Z_score_diagnostic = singular_values_Z_score;
est.rank_threshold_Z_score_diagnostic = threshold_Z_score;
est.rank_Z_recovery_diagnostic = rank_Z_recovery;
est.singular_values_Z_recovery_diagnostic = singular_values_Z_recovery;
est.rank_threshold_Z_recovery_diagnostic = threshold_Z_recovery;
est.coefficient_rank_evidence_kind = coefficient_rank_kind_local(data);
est.num_svd = 2;

debug = struct();
debug.phase_factor = 1;
debug.Q = Q;
debug.B_e = B_e;
debug.grid_deg = grid_deg;
debug.candidate_parameters_deg = candidate_parameters_deg;
debug.num_multi_start = 0;
debug.search_mode = search_mode_local(Q);
debug.rank_Z_score_diagnostic = rank_Z_score;
debug.singular_values_Z_score_diagnostic = singular_values_Z_score;
debug.rank_threshold_Z_score_diagnostic = threshold_Z_score;
debug.rank_Z_recovery_diagnostic = rank_Z_recovery;
debug.singular_values_Z_recovery_diagnostic = singular_values_Z_recovery;
debug.rank_threshold_Z_recovery_diagnostic = threshold_Z_recovery;
debug.coefficient_rank_evidence_kind = est.coefficient_rank_evidence_kind;
debug.observation_regime = data.observation_regime;
debug.score_data_used_flag = true;
debug.recovery_data_used_for_scoring_flag = false;
debug.num_svd_preflight = 2;

if data.physical_beam_count < Q || data.row_whitening_rank < Q
    est = set_status_local(est, ...
        'ESTIMATE_NOT_RUN_INSUFFICIENT_OBSERVATION_DIMENSION', ...
        'GROUP_MANIFOLD_RANK_UNCERTIFIED', ...
        'physical_or_row_whitened_observation_dimension_below_group_count');
    debug = finish_debug_local(debug, zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), false(0, 1), 0, est.num_svd);
    return;
end

if strcmp(data.observation_regime, 'NOISELESS_STRUCTURAL') && ...
        (rank_Z_score < Q || rank_Z_recovery < Q)
    est = set_status_local(est, ...
        'ESTIMATE_NOT_RUN_STRUCTURAL_RANK_FAILURE', ...
        'GROUP_MMV_RANK_UNCERTIFIED', ...
        'exact_noiseless_mmv_data_rank_below_group_count');
    debug = finish_debug_local(debug, zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), false(0, 1), 0, est.num_svd);
    return;
end

candidate_score = -Inf(num_candidates, 1);
candidate_rss = Inf(num_candidates, 1);
candidate_rank = zeros(num_candidates, 1);
candidate_eligible = false(num_candidates, 1);
candidate_manifolds = cell(num_candidates, 1);
numerical_failure_flag = false;
for idx = 1:num_candidates
    [G_now, ~] = build_elevation_group_manifold( ...
        candidate_parameters_deg(idx, :), model, struct());
    candidate_manifolds{idx} = G_now;
    score_opts = struct('requested_rank', Q, ...
        'rank_multiplier', opts.rank_multiplier, ...
        'compute_projector_checks', false);
    [score_now, rss_now, score_debug] = beamspace_dml_score_svd( ...
        data.Z_score_mmv, G_now, score_opts);
    candidate_rank(idx) = score_debug.effective_rank;
    finite_score = isfinite(score_now) && isfinite(rss_now);
    candidate_eligible(idx) = ~score_debug.is_rank_deficient && finite_score;
    if finite_score
        candidate_score(idx) = score_now;
        candidate_rss(idx) = rss_now;
    elseif ~score_debug.is_rank_deficient
        numerical_failure_flag = true;
    end
end
est.num_score_eval = num_candidates;
est.num_svd = est.num_svd + num_candidates;

eligible_index = find(candidate_eligible);
if isempty(eligible_index)
    if numerical_failure_flag
        est = set_status_local(est, 'NUMERICAL_FAILURE', ...
            'GROUP_NUMERICAL_FAILURE', ...
            'full_rank_candidate_produced_nonfinite_score');
    else
        est = set_status_local(est, 'NO_FULL_RANK_CANDIDATE', ...
            'GROUP_NO_FULL_RANK_CANDIDATE', ...
            'no_full_rank_candidate_in_registered_local_domain');
    end
    debug = finish_debug_local(debug, candidate_score, candidate_rss, ...
        candidate_rank, candidate_eligible, num_candidates, est.num_svd);
    return;
end

[~, local_best] = max(candidate_score(eligible_index));
best_index = eligible_index(local_best);
Ge_hat = candidate_manifolds{best_index};
[Ce_hat_recovery, solve_info] = stable_svd_solve( ...
    Ge_hat, data.Z_recovery_mmv, Q, opts.rank_multiplier);
[rank_Ce_hat, singular_values_Ce_hat, threshold_Ce_hat] = ...
    stable_matrix_rank(Ce_hat_recovery, opts.rank_multiplier);
est.num_svd = est.num_svd + solve_info.num_svd + 1;

if solve_info.effective_rank < Q
    est = set_status_local(est, 'NUMERICAL_FAILURE', ...
        'GROUP_NUMERICAL_FAILURE', ...
        'eligible_candidate_lost_rank_during_recovery');
    debug = finish_debug_local(debug, candidate_score, candidate_rss, ...
        candidate_rank, candidate_eligible, num_candidates, est.num_svd);
    return;
end

provisional_estimate_status = 'ESTIMATE_RETURNED';
if strcmp(data.observation_regime, 'NOISELESS_STRUCTURAL') && ...
        rank_Ce_hat < Q
    provisional_estimate_status = ...
        'ESTIMATE_NOT_RUN_STRUCTURAL_RANK_FAILURE';
end
diag_opts = struct();
diag_opts.evidence_kind = 'ESTIMATED_DIAGNOSTIC';
diag_opts.row_whitening_rank = data.row_whitening_rank;
diag_opts.column_whitening_rank = data.column_whitening_rank;
diag_opts.physical_beam_count = data.physical_beam_count;
diag_opts.observation_regime = data.observation_regime;
diag_opts.estimate_status = provisional_estimate_status;
diag_opts.local_manifold_bank = candidate_manifolds;
diag_opts.local_parameter_deg = candidate_parameters_deg;
diag_opts.reference_parameter_deg = candidate_parameters_deg(best_index, :);
diag_opts.rank_multiplier = opts.rank_multiplier;
ident_diag = diagnose_elevation_group_identifiability( ...
    Ge_hat, Ce_hat_recovery, diag_opts);
est.num_svd = est.num_svd + ident_diag.num_svd;

est.rank_Ge = ident_diag.rank_Ge;
est.singular_values_Ge = ident_diag.singular_values_Ge;
est.rank_Ce_hat_diagnostic = rank_Ce_hat;
est.singular_values_Ce_hat_diagnostic = singular_values_Ce_hat;
est.rank_threshold_Ce_hat_diagnostic = threshold_Ce_hat;
est.coefficient_rank_evidence_kind = ...
    ident_diag.coefficient_rank_evidence_kind;

if strcmp(provisional_estimate_status, 'ESTIMATE_RETURNED')
    est.eta_hat_deg = candidate_parameters_deg(best_index, :);
    est.score = candidate_score(best_index);
    est.rss = candidate_rss(best_index);
    est.Ce_hat_recovery = Ce_hat_recovery;
    est.Ge_hat = Ge_hat;
    est.estimate_status = provisional_estimate_status;
    est.estimate_reason = 'best_full_rank_registered_candidate_returned';
    est.support_status = ident_diag.support_status;
    est.support_reason = ident_diag.support_reason;
    est.statistical_calibration_status = ...
        ident_diag.statistical_calibration_status;
    est.registered_model_certified_flag = ...
        ident_diag.registered_model_certified_flag;
    est.structural_gate_pass_flag = ...
        ident_diag.structural_gate_pass_flag;
    est.estimate_returned_flag = true;
else
    est = set_status_local(est, provisional_estimate_status, ...
        ident_diag.support_status, ...
        'exact_recovered_coefficient_rank_below_group_count');
    est.rank_Ge = ident_diag.rank_Ge;
    est.singular_values_Ge = ident_diag.singular_values_Ge;
    est.rank_Ce_hat_diagnostic = rank_Ce_hat;
    est.singular_values_Ce_hat_diagnostic = singular_values_Ce_hat;
    est.rank_threshold_Ce_hat_diagnostic = threshold_Ce_hat;
end

debug = finish_debug_local(debug, candidate_score, candidate_rss, ...
    candidate_rank, candidate_eligible, num_candidates, est.num_svd);
debug.best_index = best_index;
debug.identifiability = ident_diag;
debug.num_svd_coefficient_solve = solve_info.num_svd;
debug.num_svd_identifiability = ident_diag.num_svd;
debug.best_Ge = Ge_hat;
debug.best_Ce_hat_recovery = Ce_hat_recovery;
end

function est = set_status_local(est, estimate_status, support_status, reason)
est.estimate_status = estimate_status;
est.estimate_reason = reason;
est.support_status = support_status;
est.support_reason = reason;
est.statistical_calibration_status = 'NOT_CALIBRATED_STAGE4';
est.registered_model_certified_flag = strcmp( ...
    support_status, 'GROUP_REGISTERED_MODEL_CERTIFIED');
est.structural_gate_pass_flag = ismember(support_status, ...
    {'GROUP_REGISTERED_MODEL_CERTIFIED', ...
    'GROUP_REGISTERED_MODEL_SUPPORTED_UNCALIBRATED'});
est.estimate_returned_flag = strcmp(estimate_status, 'ESTIMATE_RETURNED');
end

function debug = finish_debug_local(debug, score, rss, ranks, eligible, ...
    num_score_eval, num_svd_total)
debug.candidate_score = score;
debug.candidate_rss = rss;
debug.candidate_rank = ranks;
debug.candidate_eligible = eligible;
debug.num_score_eval = num_score_eval;
debug.num_svd_score = num_score_eval;
debug.num_svd_total = num_svd_total;
end

function est = empty_estimate_local(Q, B_e, recovery_column_count)
est = struct();
est.eta_hat_deg = NaN(1, Q);
est.score = NaN;
est.rss = NaN;
est.rank_Ge = NaN;
est.singular_values_Ge = NaN;
est.rank_Ce_hat_diagnostic = NaN;
est.singular_values_Ce_hat_diagnostic = NaN;
est.rank_threshold_Ce_hat_diagnostic = NaN;
est.rank_Z_score_diagnostic = NaN;
est.singular_values_Z_score_diagnostic = NaN;
est.rank_threshold_Z_score_diagnostic = NaN;
est.rank_Z_recovery_diagnostic = NaN;
est.singular_values_Z_recovery_diagnostic = NaN;
est.rank_threshold_Z_recovery_diagnostic = NaN;
est.Ce_hat_recovery = complex(NaN(Q, recovery_column_count));
est.Ge_hat = complex(NaN(B_e, Q));
est.num_score_eval = 0;
est.num_svd = 0;
est.coefficient_rank_evidence_kind = 'NOISY_DIAGNOSTIC_ONLY';
est.estimate_status = 'NUMERICAL_FAILURE';
est.estimate_reason = 'not_evaluated';
est.support_status = 'GROUP_NUMERICAL_FAILURE';
est.support_reason = 'not_evaluated';
est.statistical_calibration_status = 'NOT_CALIBRATED_STAGE4';
est.registered_model_certified_flag = false;
est.structural_gate_pass_flag = false;
est.estimate_returned_flag = false;
end

function data = validate_data_bundle_local(data)
if ~(isstruct(data) && isscalar(data))
    error('estimate_elevation_groups_dml:DataBundle', ...
        'data must be a scalar bundle from prepare_elevation_group_mmv_data.');
end
required = {'Z_score_mmv', 'Z_recovery_mmv', 'recovery_mapping', ...
    'phase_factor', 'row_whitening_rank', 'column_whitening_rank', ...
    'column_whitening_applied', 'column_covariance_model', ...
    'observation_regime', 'temporal_snapshot_count', ...
    'mmv_physical_column_count', 'mmv_score_column_count', ...
    'physical_beam_count'};
for idx = 1:numel(required)
    if ~isfield(data, required{idx})
        error('estimate_elevation_groups_dml:MissingDataField', ...
            'data.%s is required.', required{idx});
    end
end
unknown = setdiff(fieldnames(data), required);
if ~isempty(unknown)
    error('estimate_elevation_groups_dml:UnknownDataField', ...
        'Unknown data field: %s', unknown{1});
end
validate_matrix_local(data.Z_score_mmv, 'Z_score_mmv');
validate_matrix_local(data.Z_recovery_mmv, 'Z_recovery_mmv');
if size(data.Z_score_mmv, 1) ~= size(data.Z_recovery_mmv, 1)
    error('estimate_elevation_groups_dml:CoordinateRows', ...
        'Score and recovery data must have the same row count.');
end
if data.phase_factor ~= 1
    error('estimate_elevation_groups_dml:PhaseFactor', ...
        'The active elevation estimator requires phase_factor=1.');
end
integer_fields = {'row_whitening_rank', 'column_whitening_rank', ...
    'temporal_snapshot_count', 'mmv_physical_column_count', ...
    'mmv_score_column_count', 'physical_beam_count'};
for idx = 1:numel(integer_fields)
    value = data.(integer_fields{idx});
    if ~(isscalar(value) && isfinite(value) && value >= 1 && ...
            value == fix(value))
        error('estimate_elevation_groups_dml:DataDimension', ...
            'data.%s must be a positive integer.', integer_fields{idx});
    end
end
if data.row_whitening_rank ~= size(data.Z_score_mmv, 1) || ...
        data.mmv_physical_column_count ~= size(data.Z_recovery_mmv, 2) || ...
        data.mmv_score_column_count ~= size(data.Z_score_mmv, 2) || ...
        data.column_whitening_rank * data.temporal_snapshot_count ~= ...
        data.mmv_score_column_count
    error('estimate_elevation_groups_dml:DataMetadata', ...
        'Data dimensions and bundle metadata are inconsistent.');
end
validate_mapping_local(data.recovery_mapping, ...
    data.mmv_physical_column_count, data.temporal_snapshot_count);
data.observation_regime = char(string(data.observation_regime));
if ~ismember(data.observation_regime, ...
        {'NOISELESS_STRUCTURAL', 'NOISY_UNCALIBRATED'})
    error('estimate_elevation_groups_dml:ObservationRegime', ...
        'Unsupported observation regime: %s', data.observation_regime);
end
if ~(islogical(data.column_whitening_applied) && ...
        isscalar(data.column_whitening_applied))
    error('estimate_elevation_groups_dml:ColumnWhiteningFlag', ...
        'data.column_whitening_applied must be scalar logical.');
end
end

function validate_model_contract_local(model, data)
if ~(isstruct(model) && isscalar(model) && isfield(model, 'V') && ...
        isfield(model, 'whitener'))
    error('estimate_elevation_groups_dml:Model', ...
        'model must contain fixed V and whitener matrices.');
end
if size(model.V, 2) ~= data.physical_beam_count || ...
        size(model.whitener, 1) ~= data.row_whitening_rank || ...
        size(model.whitener, 2) ~= data.physical_beam_count
    error('estimate_elevation_groups_dml:ModelDataContract', ...
        'The fixed row manifold projection does not match the data bundle.');
end
end

function validate_mapping_local(mapping, num_columns, L)
required = {'stacked_column', 'azimuth_column', 'snapshot_index'};
if ~istable(mapping) || ~all(ismember(required, ...
        mapping.Properties.VariableNames)) || height(mapping) ~= num_columns
    error('estimate_elevation_groups_dml:RecoveryMapping', ...
        'data.recovery_mapping must describe every physical MMV column.');
end
if ~isequal(mapping.stacked_column(:), (1:num_columns).') || ...
        any(mapping.azimuth_column < 1) || any(mapping.snapshot_index < 1) || ...
        max(mapping.snapshot_index) ~= L
    error('estimate_elevation_groups_dml:RecoveryMappingValues', ...
        'The recovery mapping contains invalid indices.');
end
end

function validate_matrix_local(A, name)
if ~(isnumeric(A) && ismatrix(A) && ~isempty(A) && all(isfinite(A(:))) && ...
        (isa(A, 'double') || isa(A, 'single')))
    error('estimate_elevation_groups_dml:DataMatrix', ...
        'data.%s must be a non-empty finite floating-point matrix.', name);
end
end

function [candidate_parameters_deg, grid_deg] = ...
    build_candidates_local(search_domain, Q)
if isnumeric(search_domain)
    grid_deg = search_domain;
elseif isstruct(search_domain) && isscalar(search_domain) && ...
        isfield(search_domain, 'grid_deg')
    unknown = setdiff(fieldnames(search_domain), {'grid_deg'});
    if ~isempty(unknown)
        error('estimate_elevation_groups_dml:SearchDomainOption', ...
            'Unknown search-domain field: %s', unknown{1});
    end
    grid_deg = search_domain.grid_deg;
else
    error('estimate_elevation_groups_dml:SearchDomain', ...
        'search_domain must be a numeric grid or a struct containing grid_deg.');
end
if ~(isnumeric(grid_deg) && isreal(grid_deg) && isvector(grid_deg) && ...
        all(isfinite(grid_deg(:))))
    error('estimate_elevation_groups_dml:Grid', ...
        'The elevation grid must be a finite real vector.');
end
grid_deg = unique(reshape(grid_deg, [], 1), 'sorted');
if numel(grid_deg) < Q
    error('estimate_elevation_groups_dml:GridSize', ...
        'The registered local grid must contain at least Q distinct angles.');
end
if Q == 1
    candidate_parameters_deg = grid_deg;
else
    pair_index = nchoosek(1:numel(grid_deg), 2);
    candidate_parameters_deg = [grid_deg(pair_index(:, 1)), ...
        grid_deg(pair_index(:, 2))];
end
end

function Q = validate_group_count_local(Q)
if ~(isscalar(Q) && isreal(Q) && isfinite(Q) && Q == fix(Q) && ...
        ismember(Q, [1, 2]))
    error('estimate_elevation_groups_dml:GroupCount', ...
        'This phase supports only oracle-known Q=1 or Q=2.');
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('estimate_elevation_groups_dml:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('estimate_elevation_groups_dml:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('estimate_elevation_groups_dml:RankMultiplier', ...
        'opts.rank_multiplier must be a positive finite scalar.');
end
end

function kind = coefficient_rank_kind_local(data)
if strcmp(data.observation_regime, 'NOISELESS_STRUCTURAL')
    kind = 'NOISELESS_EXACT_DATA';
else
    kind = 'NOISY_DIAGNOSTIC_ONLY';
end
end

function mode = search_mode_local(Q)
if Q == 1
    mode = 'one_dimensional_registered_grid';
else
    mode = 'two_group_local_full_reference';
end
end
