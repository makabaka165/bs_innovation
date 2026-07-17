function diag_out = diagnose_elevation_group_identifiability( ...
    Ge, coefficient_evidence, opts)
%DIAGNOSE_ELEVATION_GROUP_IDENTIFIABILITY Diagnose registered-model support.

opts = normalize_options_local(opts);
validate_matrix_local(Ge, 'Ge');
[B_e, Q] = size(Ge);
if opts.row_whitening_rank ~= B_e
    error('diagnose_elevation_group_identifiability:RowWhiteningRank', ...
        'opts.row_whitening_rank must equal the row-coordinate count.');
end

[rank_Ge, singular_values_Ge, threshold_Ge, rank_info_Ge] = ...
    stable_matrix_rank(Ge, opts.rank_multiplier);
num_svd = 1;
rank_Ce = NaN;
singular_values_Ce = NaN;
threshold_Ce = NaN;
relative_threshold_Ce = NaN;
if ~strcmp(opts.evidence_kind, 'NONE')
    validate_matrix_local(coefficient_evidence, 'coefficient_evidence');
    if size(coefficient_evidence, 1) ~= Q
        error('diagnose_elevation_group_identifiability:CoefficientRows', ...
            'coefficient_evidence must have Q rows.');
    end
    [rank_Ce, singular_values_Ce, threshold_Ce, rank_info_Ce] = ...
        stable_matrix_rank(coefficient_evidence, opts.rank_multiplier);
    relative_threshold_Ce = rank_info_Ce.relative_threshold;
    num_svd = num_svd + 1;
elseif ~isempty(coefficient_evidence)
    error('diagnose_elevation_group_identifiability:UnusedEvidence', ...
        'coefficient_evidence must be empty when evidence_kind is NONE.');
end

[alias_info, alias_svd_count] = registered_alias_test_local( ...
    Ge, rank_Ge, Q, opts.local_manifold_bank, ...
    opts.local_parameter_deg, opts.reference_parameter_deg, ...
    opts.rank_multiplier);
num_svd = num_svd + alias_svd_count;

coefficient_rank_evidence_kind = coefficient_rank_kind_local(opts);
exact_coefficient_evidence = strcmp(opts.evidence_kind, 'TRUTH_STRUCTURAL') || ...
    (strcmp(opts.evidence_kind, 'ESTIMATED_DIAGNOSTIC') && ...
    strcmp(opts.observation_regime, 'NOISELESS_STRUCTURAL'));
exact_mmv_rank_failure = exact_coefficient_evidence && rank_Ce < Q;

support_status = 'GROUP_MMV_RANK_UNCERTIFIED';
support_reason = 'registered_mmv_coefficient_structure_not_certified';
if opts.physical_beam_count < Q || opts.row_whitening_rank < Q || ...
        rank_Ge < Q
    support_status = 'GROUP_MANIFOLD_RANK_UNCERTIFIED';
    support_reason = 'physical_or_whitened_manifold_dimension_below_group_count';
elseif exact_mmv_rank_failure
    support_status = 'GROUP_MMV_RANK_UNCERTIFIED';
    support_reason = 'exact_registered_mmv_coefficient_rank_below_group_count';
elseif alias_info.exact_alias_flag
    support_status = 'GROUP_REGISTERED_ALIAS_UNCERTIFIED';
    support_reason = 'exact_subspace_alias_in_registered_candidate_bank';
elseif strcmp(opts.estimate_status, 'NO_FULL_RANK_CANDIDATE')
    support_status = 'GROUP_NO_FULL_RANK_CANDIDATE';
    support_reason = 'registered_search_contains_no_full_rank_candidate';
elseif strcmp(opts.estimate_status, 'NUMERICAL_FAILURE')
    support_status = 'GROUP_NUMERICAL_FAILURE';
    support_reason = 'registered_estimator_numerical_failure';
elseif strcmp(opts.observation_regime, 'NOISELESS_STRUCTURAL') && ...
        exact_coefficient_evidence && rank_Ce == Q && ...
        strcmp(opts.estimate_status, 'ESTIMATE_RETURNED')
    support_status = 'GROUP_REGISTERED_MODEL_CERTIFIED';
    support_reason = 'exact_registered_structural_checks_passed';
elseif strcmp(opts.observation_regime, 'NOISY_UNCALIBRATED') && ...
        strcmp(opts.estimate_status, 'ESTIMATE_RETURNED')
    support_status = 'GROUP_REGISTERED_MODEL_SUPPORTED_UNCALIBRATED';
    support_reason = 'noisy_registered_model_supported_without_calibration';
end

diag_out = struct();
diag_out.support_status = support_status;
diag_out.support_reason = support_reason;
diag_out.statistical_calibration_status = 'NOT_CALIBRATED_STAGE4';
diag_out.registered_model_certified_flag = strcmp( ...
    support_status, 'GROUP_REGISTERED_MODEL_CERTIFIED');
diag_out.structural_gate_pass_flag = ismember(support_status, ...
    {'GROUP_REGISTERED_MODEL_CERTIFIED', ...
    'GROUP_REGISTERED_MODEL_SUPPORTED_UNCALIBRATED'});
diag_out.estimate_returned_flag = strcmp( ...
    opts.estimate_status, 'ESTIMATE_RETURNED');
diag_out.estimate_status = opts.estimate_status;
diag_out.observation_regime = opts.observation_regime;
diag_out.evidence_kind = opts.evidence_kind;
diag_out.coefficient_rank_evidence_kind = ...
    coefficient_rank_evidence_kind;
diag_out.exact_coefficient_evidence_flag = exact_coefficient_evidence;
diag_out.B_e = B_e;
diag_out.physical_beam_count = opts.physical_beam_count;
diag_out.Q = Q;
diag_out.row_whitening_rank = opts.row_whitening_rank;
diag_out.column_whitening_rank = opts.column_whitening_rank;
diag_out.rank_Ge = rank_Ge;
diag_out.singular_values_Ge = singular_values_Ge;
diag_out.rank_threshold_Ge = threshold_Ge;
diag_out.relative_rank_threshold_Ge = rank_info_Ge.relative_threshold;
diag_out.rank_Ce_evidence = rank_Ce;
diag_out.singular_values_Ce_evidence = singular_values_Ce;
diag_out.rank_threshold_Ce_evidence = threshold_Ce;
diag_out.relative_rank_threshold_Ce_evidence = relative_threshold_Ce;
diag_out.registered_bank_min_chordal_distance = alias_info.min_distance;
diag_out.registered_bank_exact_alias_tolerance = alias_info.tolerance;
diag_out.registered_bank_exact_alias_flag = alias_info.exact_alias_flag;
diag_out.registered_bank_candidates_checked = alias_info.candidates_checked;
diag_out.registered_bank_rank_deficient_candidates = ...
    alias_info.rank_deficient_candidates;
diag_out.num_svd = num_svd;
diag_out.rank_multiplier = opts.rank_multiplier;
diag_out.phase_factor = 1;
end

function [out, num_svd] = registered_alias_test_local( ...
    Ge, rank_Ge, Q, bank, parameters_deg, reference_deg, rank_multiplier)
num_candidates = numel(bank);
if size(parameters_deg, 1) ~= num_candidates || ...
        size(parameters_deg, 2) ~= Q
    error('diagnose_elevation_group_identifiability:RegisteredParameters', ...
        'local_parameter_deg must have one Q-angle row per manifold.');
end
reference_sorted = sort(reshape(reference_deg, 1, []));
if numel(reference_sorted) ~= Q
    error('diagnose_elevation_group_identifiability:ReferenceParameters', ...
        'reference_parameter_deg must contain Q angles.');
end

tolerance = rank_multiplier * max(size(Ge)) * eps(class(Ge)) * max(1, Q);
out = struct('min_distance', Inf, 'tolerance', tolerance, ...
    'exact_alias_flag', false, 'candidates_checked', 0, ...
    'rank_deficient_candidates', 0);
num_svd = 0;
if rank_Ge < Q
    return;
end

[U_ref, S_ref, ~] = svd(Ge, 'econ');
[rank_ref, ~] = stable_numeric_rank(diag(S_ref), size(Ge), rank_multiplier);
num_svd = 1;
U_ref = U_ref(:, 1:rank_ref);
P_ref = U_ref * U_ref';
for idx = 1:num_candidates
    G_now = bank{idx};
    validate_matrix_local(G_now, sprintf('local_manifold_bank{%d}', idx));
    if ~isequal(size(G_now), size(Ge))
        error('diagnose_elevation_group_identifiability:RegisteredManifoldSize', ...
            'Every registered manifold must match size(Ge).');
    end
    if isequal(sort(parameters_deg(idx, :)), reference_sorted)
        continue;
    end
    [U_now, S_now, ~] = svd(G_now, 'econ');
    [rank_now, ~] = stable_numeric_rank( ...
        diag(S_now), size(G_now), rank_multiplier);
    num_svd = num_svd + 1;
    if rank_now < Q
        out.rank_deficient_candidates = ...
            out.rank_deficient_candidates + 1;
        continue;
    end
    U_now = U_now(:, 1:rank_now);
    P_now = U_now * U_now';
    distance = norm(P_ref - P_now, 'fro') / sqrt(2);
    out.min_distance = min(out.min_distance, distance);
    out.candidates_checked = out.candidates_checked + 1;
end
out.exact_alias_flag = out.candidates_checked > 0 && ...
    out.min_distance <= out.tolerance;
end

function kind = coefficient_rank_kind_local(opts)
if strcmp(opts.evidence_kind, 'TRUTH_STRUCTURAL')
    kind = 'TRUTH_STRUCTURAL';
elseif strcmp(opts.observation_regime, 'NOISELESS_STRUCTURAL')
    kind = 'NOISELESS_EXACT_DATA';
else
    kind = 'NOISY_DIAGNOSTIC_ONLY';
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('diagnose_elevation_group_identifiability:Options', ...
        'opts must be a scalar struct.');
end
required = {'evidence_kind', 'row_whitening_rank', ...
    'column_whitening_rank', 'physical_beam_count', ...
    'observation_regime', 'estimate_status', 'local_manifold_bank', ...
    'local_parameter_deg', 'reference_parameter_deg'};
for idx = 1:numel(required)
    if ~isfield(opts, required{idx})
        error('diagnose_elevation_group_identifiability:MissingOption', ...
            'opts.%s is required.', required{idx});
    end
end
allowed = [required, {'rank_multiplier'}];
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('diagnose_elevation_group_identifiability:UnknownOption', ...
        'Unknown option: %s', unknown{1});
end
opts.evidence_kind = char(string(opts.evidence_kind));
if ~ismember(opts.evidence_kind, ...
        {'TRUTH_STRUCTURAL', 'ESTIMATED_DIAGNOSTIC', 'NONE'})
    error('diagnose_elevation_group_identifiability:EvidenceKind', ...
        'Unsupported evidence kind: %s', opts.evidence_kind);
end
opts.observation_regime = char(string(opts.observation_regime));
if ~ismember(opts.observation_regime, ...
        {'NOISELESS_STRUCTURAL', 'NOISY_UNCALIBRATED'})
    error('diagnose_elevation_group_identifiability:ObservationRegime', ...
        'Unsupported observation regime: %s', opts.observation_regime);
end
opts.estimate_status = char(string(opts.estimate_status));
allowed_estimate_status = {'ESTIMATE_RETURNED', ...
    'ESTIMATE_NOT_RUN_INSUFFICIENT_OBSERVATION_DIMENSION', ...
    'ESTIMATE_NOT_RUN_STRUCTURAL_RANK_FAILURE', ...
    'NO_FULL_RANK_CANDIDATE', 'NUMERICAL_FAILURE'};
if ~ismember(opts.estimate_status, allowed_estimate_status)
    error('diagnose_elevation_group_identifiability:EstimateStatus', ...
        'Unsupported estimate status: %s', opts.estimate_status);
end
integer_fields = {'row_whitening_rank', 'column_whitening_rank', ...
    'physical_beam_count'};
for idx = 1:numel(integer_fields)
    value = opts.(integer_fields{idx});
    if ~(isscalar(value) && isfinite(value) && value >= 1 && ...
            value == fix(value))
        error('diagnose_elevation_group_identifiability:DimensionOption', ...
            'opts.%s must be a positive integer.', integer_fields{idx});
    end
end
if ~iscell(opts.local_manifold_bank) || isempty(opts.local_manifold_bank)
    error('diagnose_elevation_group_identifiability:RegisteredBank', ...
        'opts.local_manifold_bank must be a non-empty cell array.');
end
if ~(isnumeric(opts.local_parameter_deg) && ...
        isreal(opts.local_parameter_deg) && ...
        all(isfinite(opts.local_parameter_deg(:))))
    error('diagnose_elevation_group_identifiability:RegisteredParameters', ...
        'opts.local_parameter_deg must be finite and real.');
end
if ~(isnumeric(opts.reference_parameter_deg) && ...
        isreal(opts.reference_parameter_deg) && ...
        all(isfinite(opts.reference_parameter_deg(:))))
    error('diagnose_elevation_group_identifiability:ReferenceValues', ...
        'opts.reference_parameter_deg must be finite and real.');
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~(isscalar(opts.rank_multiplier) && isfinite(opts.rank_multiplier) && ...
        opts.rank_multiplier > 0)
    error('diagnose_elevation_group_identifiability:RankMultiplier', ...
        'opts.rank_multiplier must be positive and finite.');
end
end

function validate_matrix_local(A, name)
if ~(isnumeric(A) && ismatrix(A) && ~isempty(A) && all(isfinite(A(:))) && ...
        (isa(A, 'double') || isa(A, 'single')))
    error('diagnose_elevation_group_identifiability:Matrix', ...
        '%s must be a non-empty finite floating-point matrix.', name);
end
end
