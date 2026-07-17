function [est, debug] = estimate_elevation_groups_dml( ...
    Zemmv, group_count_Q, search_domain, model, opts)
%ESTIMATE_ELEVATION_GROUPS_DML Estimate oracle-known elevation groups by DML.

if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_data_local(Zemmv);
Q = validate_group_count_local(group_count_Q);
[candidate_parameters_deg, grid_deg] = ...
    build_candidates_local(search_domain, Q);
num_candidates = size(candidate_parameters_deg, 1);
B_e = size(Zemmv, 1);

est = empty_estimate_local(Q);
debug = struct();
debug.phase_factor = 1;
debug.Q = Q;
debug.B_e = B_e;
debug.grid_deg = grid_deg;
debug.candidate_parameters_deg = candidate_parameters_deg;
debug.num_multi_start = 0;
debug.search_mode = search_mode_local(Q);

[rank_Z, singular_values_Z, rank_threshold_Z] = ...
    stable_matrix_rank(Zemmv, opts.rank_multiplier);
debug.rank_Zemmv = rank_Z;
debug.singular_values_Zemmv = singular_values_Z;
debug.rank_threshold_Zemmv = rank_threshold_Z;
debug.num_svd_preflight = 1;
if B_e < Q || rank_Z < Q
    est.status = 'GROUP_UNIDENTIFIABLE';
    est.reason = 'observed_mmv_rank_below_oracle_group_count';
    est.high_confidence_group_flag = false;
    est.rank_Ce_hat = rank_Z;
    est.singular_values_Ce_hat = singular_values_Z;
    est.num_score_eval = 0;
    est.num_svd = 1;
    debug.num_score_eval = 0;
    debug.num_svd_score = 0;
    debug.num_svd_total = 1;
    debug.candidate_score = zeros(0, 1);
    debug.candidate_rss = zeros(0, 1);
    debug.candidate_rank = zeros(0, 1);
    debug.candidate_eligible = false(0, 1);
    return;
end

candidate_score = -Inf(num_candidates, 1);
candidate_rss = Inf(num_candidates, 1);
candidate_rank = zeros(num_candidates, 1);
candidate_eligible = false(num_candidates, 1);
candidate_manifolds = cell(num_candidates, 1);
for idx = 1:num_candidates
    [G_now, ~] = build_elevation_group_manifold( ...
        candidate_parameters_deg(idx, :), model, struct());
    candidate_manifolds{idx} = G_now;
    score_opts = struct('requested_rank', Q, ...
        'rank_multiplier', opts.rank_multiplier, ...
        'compute_projector_checks', false);
    [candidate_score(idx), candidate_rss(idx), score_debug] = ...
        beamspace_dml_score_svd(Zemmv, G_now, score_opts);
    candidate_rank(idx) = score_debug.effective_rank;
    candidate_eligible(idx) = ~score_debug.is_rank_deficient;
end

eligible_index = find(candidate_eligible);
if isempty(eligible_index)
    est.status = 'GROUP_UNIDENTIFIABLE';
    est.reason = 'no_full_rank_candidate_in_registered_local_domain';
    est.num_score_eval = num_candidates;
    est.num_svd = 1 + num_candidates;
    debug = finish_debug_local(debug, candidate_score, candidate_rss, ...
        candidate_rank, candidate_eligible, num_candidates, est.num_svd);
    return;
end
[~, local_best] = max(candidate_score(eligible_index));
best_index = eligible_index(local_best);
Ge_hat = candidate_manifolds{best_index};
[Ce_hat, solve_info] = stable_svd_solve( ...
    Ge_hat, Zemmv, Q, opts.rank_multiplier);

diag_opts = struct();
diag_opts.input_kind = 'coefficient';
diag_opts.whitening_rank = B_e;
diag_opts.local_manifold_bank = candidate_manifolds;
diag_opts.local_parameter_deg = candidate_parameters_deg;
diag_opts.reference_parameter_deg = candidate_parameters_deg(best_index, :);
diag_opts.rank_multiplier = opts.rank_multiplier;
ident_diag = diagnose_elevation_group_identifiability( ...
    Ge_hat, Ce_hat, diag_opts);

est.eta_hat_deg = candidate_parameters_deg(best_index, :);
est.score = candidate_score(best_index);
est.rss = candidate_rss(best_index);
est.rank_Ge = ident_diag.rank_Ge;
est.singular_values_Ge = ident_diag.singular_values_Ge;
est.rank_Ce_hat = ident_diag.rank_Ce;
est.singular_values_Ce_hat = ident_diag.singular_values_Ce;
est.Ce_hat = Ce_hat;
est.Ge_hat = Ge_hat;
est.num_score_eval = num_candidates;
est.num_svd = 1 + num_candidates + solve_info.num_svd + ident_diag.num_svd;
est.status = ident_diag.status;
est.reason = ident_diag.reason;
est.high_confidence_group_flag = ident_diag.high_confidence_group_flag;

debug = finish_debug_local(debug, candidate_score, candidate_rss, ...
    candidate_rank, candidate_eligible, num_candidates, est.num_svd);
debug.best_index = best_index;
debug.identifiability = ident_diag;
debug.num_svd_coefficient_solve = solve_info.num_svd;
debug.num_svd_identifiability = ident_diag.num_svd;
debug.best_Ge = Ge_hat;
debug.best_Ce_hat = Ce_hat;
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

function est = empty_estimate_local(Q)
est = struct();
est.eta_hat_deg = NaN(1, Q);
est.score = NaN;
est.rss = NaN;
est.rank_Ge = NaN;
est.singular_values_Ge = NaN;
est.rank_Ce_hat = NaN;
est.singular_values_Ce_hat = NaN;
est.Ce_hat = complex(NaN(Q, 1));
est.Ge_hat = complex(NaN(1, Q));
est.num_score_eval = 0;
est.num_svd = 0;
est.status = 'GROUP_UNIDENTIFIABLE';
est.reason = 'not_evaluated';
est.high_confidence_group_flag = false;
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
        'The local grid must contain at least Q distinct angles.');
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

function validate_data_local(Z)
if ~(isnumeric(Z) && ismatrix(Z) && ~isempty(Z) && all(isfinite(Z(:))) && ...
        (isa(Z, 'double') || isa(Z, 'single')))
    error('estimate_elevation_groups_dml:Data', ...
        'Zemmv must be a non-empty finite floating-point matrix.');
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

function mode = search_mode_local(Q)
if Q == 1
    mode = 'one_dimensional_registered_grid';
else
    mode = 'two_group_local_full_reference';
end
end
