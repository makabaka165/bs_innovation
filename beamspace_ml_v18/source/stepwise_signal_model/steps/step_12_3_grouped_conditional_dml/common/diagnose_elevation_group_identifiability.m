function diag_out = diagnose_elevation_group_identifiability(Ge, Ce_or_Z, opts)
%DIAGNOSE_ELEVATION_GROUP_IDENTIFIABILITY Check group-model rank and aliasing.

opts = normalize_options_local(opts);
validate_matrix_local(Ge, 'Ge');
validate_matrix_local(Ce_or_Z, 'Ce_or_Z');
[B_e, Q] = size(Ge);
if opts.whitening_rank ~= B_e
    error('diagnose_elevation_group_identifiability:WhiteningRank', ...
        'opts.whitening_rank must equal the fixed whitened coordinate count.');
end

[rank_Ge, singular_values_Ge, threshold_Ge, rank_info_Ge] = ...
    stable_matrix_rank(Ge, opts.rank_multiplier);
num_svd = 1;
if strcmp(opts.input_kind, 'coefficient')
    if size(Ce_or_Z, 1) ~= Q
        error('diagnose_elevation_group_identifiability:CoefficientRows', ...
            'Coefficient input must have Q rows.');
    end
    Ce = Ce_or_Z;
    coefficient_source = 'provided_truth_or_estimate';
else
    if size(Ce_or_Z, 1) ~= B_e
        error('diagnose_elevation_group_identifiability:DataRows', ...
            'Data input must have B_e rows.');
    end
    [Ce, solve_info] = stable_svd_solve( ...
        Ge, Ce_or_Z, Q, opts.rank_multiplier);
    coefficient_source = 'svd_least_squares_from_data';
    num_svd = num_svd + solve_info.num_svd;
end
[rank_Ce, singular_values_Ce, threshold_Ce, rank_info_Ce] = ...
    stable_matrix_rank(Ce, opts.rank_multiplier);
num_svd = num_svd + 1;

[alias_info, alias_svd_count] = local_alias_test_local( ...
    Ge, Q, opts.local_manifold_bank, opts.local_parameter_deg, ...
    opts.reference_parameter_deg, opts.rank_multiplier);
num_svd = num_svd + alias_svd_count;

reason = 'all_registered_identifiability_checks_passed';
status = 'GROUP_IDENTIFIABLE';
if B_e < Q
    status = 'GROUP_UNIDENTIFIABLE';
    reason = 'beamspace_dimension_below_group_count';
elseif opts.whitening_rank < Q
    status = 'GROUP_UNIDENTIFIABLE';
    reason = 'whitening_rank_below_group_count';
elseif rank_Ge < Q
    status = 'GROUP_UNIDENTIFIABLE';
    reason = 'elevation_manifold_rank_below_group_count';
elseif rank_Ce < Q
    status = 'GROUP_UNIDENTIFIABLE';
    reason = 'coefficient_rank_below_group_count';
elseif alias_info.alias_flag
    status = 'GROUP_UNIDENTIFIABLE';
    reason = 'finite_local_subspace_alias_detected';
end

diag_out = struct();
diag_out.status = status;
diag_out.reason = reason;
diag_out.identifiability_pass_flag = strcmp(status, 'GROUP_IDENTIFIABLE');
diag_out.high_confidence_group_flag = diag_out.identifiability_pass_flag;
diag_out.B_e = B_e;
diag_out.Q = Q;
diag_out.whitening_effective_rank = opts.whitening_rank;
diag_out.rank_Ge = rank_Ge;
diag_out.singular_values_Ge = singular_values_Ge;
diag_out.rank_threshold_Ge = threshold_Ge;
diag_out.relative_rank_threshold_Ge = rank_info_Ge.relative_threshold;
diag_out.rank_Ce = rank_Ce;
diag_out.singular_values_Ce = singular_values_Ce;
diag_out.rank_threshold_Ce = threshold_Ce;
diag_out.relative_rank_threshold_Ce = rank_info_Ce.relative_threshold;
diag_out.coefficient_source = coefficient_source;
diag_out.local_alias_test_mode = 'finite_registered_candidate_bank';
diag_out.local_alias_flag = alias_info.alias_flag;
diag_out.local_alias_test_pass = ~alias_info.alias_flag;
diag_out.local_alias_min_chordal_distance = alias_info.min_distance;
diag_out.local_alias_tolerance = alias_info.tolerance;
diag_out.local_alias_candidates_checked = alias_info.candidates_checked;
diag_out.local_alias_rank_deficient_candidates = ...
    alias_info.rank_deficient_candidates;
diag_out.num_svd = num_svd;
diag_out.rank_multiplier = opts.rank_multiplier;
diag_out.phase_factor = 1;
end

function [out, num_svd] = local_alias_test_local( ...
    Ge, Q, bank, parameters_deg, reference_deg, rank_multiplier)
num_candidates = numel(bank);
if size(parameters_deg, 1) ~= num_candidates || size(parameters_deg, 2) ~= Q
    error('diagnose_elevation_group_identifiability:LocalParameters', ...
        'local_parameter_deg must have one Q-angle row per manifold.');
end
reference_sorted = sort(reshape(reference_deg, 1, []));
if numel(reference_sorted) ~= Q
    error('diagnose_elevation_group_identifiability:ReferenceParameters', ...
        'reference_parameter_deg must contain Q angles.');
end

[U_ref, S_ref, ~] = svd(Ge, 'econ');
[rank_ref, ~] = stable_numeric_rank(diag(S_ref), size(Ge), rank_multiplier);
U_ref = U_ref(:, 1:rank_ref);
num_svd = 1;
min_distance = Inf;
candidates_checked = 0;
rank_deficient_candidates = 0;
for idx = 1:num_candidates
    G_now = bank{idx};
    validate_matrix_local(G_now, sprintf('local_manifold_bank{%d}', idx));
    if ~isequal(size(G_now), size(Ge))
        error('diagnose_elevation_group_identifiability:LocalManifoldSize', ...
            'Every local manifold must match size(Ge).');
    end
    candidate_sorted = sort(parameters_deg(idx, :));
    if isequal(candidate_sorted, reference_sorted)
        continue;
    end
    [U_now, S_now, ~] = svd(G_now, 'econ');
    [rank_now, ~] = stable_numeric_rank(diag(S_now), size(G_now), rank_multiplier);
    num_svd = num_svd + 1;
    if rank_now < Q || rank_ref < Q
        rank_deficient_candidates = rank_deficient_candidates + 1;
        continue;
    end
    U_now = U_now(:, 1:rank_now);
    overlap = real(norm(U_ref' * U_now, 'fro') ^ 2);
    distance = sqrt(max(0, Q - overlap));
    min_distance = min(min_distance, distance);
    candidates_checked = candidates_checked + 1;
end
if candidates_checked == 0
    error('diagnose_elevation_group_identifiability:LocalAliasCoverage', ...
        'The local alias bank must contain a distinct full-rank candidate.');
end
tolerance = max(size(Ge)) * eps(class(Ge)) * max(1, Q);
out = struct();
out.min_distance = min_distance;
out.tolerance = tolerance;
out.alias_flag = min_distance <= tolerance;
out.candidates_checked = candidates_checked;
out.rank_deficient_candidates = rank_deficient_candidates;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('diagnose_elevation_group_identifiability:Options', ...
        'opts must be a scalar struct.');
end
required = {'input_kind', 'whitening_rank', 'local_manifold_bank', ...
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
opts.input_kind = char(string(opts.input_kind));
if ~ismember(opts.input_kind, {'coefficient', 'data'})
    error('diagnose_elevation_group_identifiability:InputKind', ...
        'opts.input_kind must be coefficient or data.');
end
if ~(isscalar(opts.whitening_rank) && isfinite(opts.whitening_rank) && ...
        opts.whitening_rank >= 1 && opts.whitening_rank == fix(opts.whitening_rank))
    error('diagnose_elevation_group_identifiability:WhiteningRankOption', ...
        'opts.whitening_rank must be a positive integer.');
end
if ~iscell(opts.local_manifold_bank) || isempty(opts.local_manifold_bank)
    error('diagnose_elevation_group_identifiability:LocalManifoldBank', ...
        'opts.local_manifold_bank must be a non-empty cell array.');
end
if ~(isnumeric(opts.local_parameter_deg) && isreal(opts.local_parameter_deg) && ...
        all(isfinite(opts.local_parameter_deg(:))))
    error('diagnose_elevation_group_identifiability:LocalParameterValues', ...
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
