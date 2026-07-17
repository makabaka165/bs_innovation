function [est, debug] = estimate_conditional_azimuth_dml( ...
    data, target_count_Kq, search_domain, model, opts)
%ESTIMATE_CONDITIONAL_AZIMUTH_DML Search a registered one-dimensional domain.

if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
Kq = validate_target_count_local(target_count_Kq);
grid_deg = extract_grid_local(search_domain);
est = empty_estimate_local(data, model, Kq);
debug = struct('candidate_parameters_deg', zeros(0, Kq), ...
    'candidate_score', zeros(0, 1), 'candidate_rss', zeros(0, 1), ...
    'candidate_rank', zeros(0, 1), 'phase_factor', 1);

if ~(data.upstream_estimate_returned_flag && ...
        data.upstream_structural_gate_pass_flag)
    est.conditional_estimate_status = 'UPSTREAM_GROUP_STAGE_UNCERTIFIED';
    return;
end
if size(data.Zphi_white, 1) < Kq
    est.conditional_estimate_status = 'AZIMUTH_MANIFOLD_RANK_UNCERTIFIED';
    return;
end

if Kq == 1
    candidates = grid_deg(:);
else
    if numel(grid_deg) < 2
        est.conditional_estimate_status = 'NO_FULL_RANK_AZIMUTH_CANDIDATE';
        return;
    end
    pairs = nchoosek(1:numel(grid_deg), 2);
    candidates = [grid_deg(pairs(:, 1)).', grid_deg(pairs(:, 2)).'];
end

num_candidates = size(candidates, 1);
score = -Inf(num_candidates, 1);
rss = Inf(num_candidates, 1);
rank_now = zeros(num_candidates, 1);
score_opts = struct('requested_rank', Kq, ...
    'rank_multiplier', opts.rank_multiplier, ...
    'compute_projector_checks', false);
start_tic = tic;
for idx = 1:num_candidates
    [Gphi, ~, manifold_info] = build_conditional_azimuth_manifold( ...
        candidates(idx, :), model, ...
        struct('rank_multiplier', opts.rank_multiplier));
    rank_now(idx) = manifold_info.rank_Gphi;
    if rank_now(idx) == Kq
        [score(idx), rss(idx)] = beamspace_dml_score_svd( ...
            data.Zphi_white, Gphi, score_opts);
    end
end
runtime_sec = toc(start_tic);
valid = isfinite(score) & rank_now == Kq;
est.num_score_eval = nnz(valid);
est.num_svd = num_candidates + nnz(valid);
est.runtime = runtime_sec;
if ~any(valid)
    est.conditional_estimate_status = 'NO_FULL_RANK_AZIMUTH_CANDIDATE';
else
    valid_index = find(valid);
    [~, relative_index] = max(score(valid));
    best = valid_index(relative_index);
    est.az_hat_deg = candidates(best, :);
    est.score = score(best);
    est.rss = rss(best);
    est.rank_Gphi = rank_now(best);
    est.conditional_estimate_status = 'CONDITIONAL_AZIMUTH_RETURNED';
    est.estimate_returned_flag = true;
end

debug.candidate_parameters_deg = candidates;
debug.candidate_score = score;
debug.candidate_rss = rss;
debug.candidate_rank = rank_now;
debug.fixed_measurement_hash = model.fixed_measurement_hash;
debug.fixed_hash_count = 1;
debug.enumeration = enumeration_name_local(Kq);
debug.num_candidate_manifold_build = num_candidates;
end

function est = empty_estimate_local(data, model, Kq)
est = struct();
est.az_hat_deg = NaN(1, Kq);
est.score = NaN;
est.rss = NaN;
est.rank_Gphi = 0;
est.num_score_eval = 0;
est.num_svd = 0;
est.runtime = 0;
est.conditional_estimate_status = 'CONDITIONAL_AZIMUTH_NUMERICAL_FAILURE';
est.upstream_group_support_status = data.upstream_group_support_status;
est.eta_condition_deg = data.eta_condition_deg;
est.condition_source = data.condition_source;
est.statistical_calibration_status = 'NOT_CALIBRATED_STAGE5';
est.fixed_measurement_hash = model.fixed_measurement_hash;
est.estimate_returned_flag = false;
est.phase_factor = 1;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('estimate_conditional_azimuth_dml:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'rank_multiplier'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('estimate_conditional_azimuth_dml:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
end

function Kq = validate_target_count_local(Kq)
if ~(isscalar(Kq) && isfinite(Kq) && any(Kq == [1, 2]))
    error('estimate_conditional_azimuth_dml:TargetCount', ...
        'target_count_Kq must be oracle-specified as 1 or 2.');
end
end

function grid = extract_grid_local(domain)
if isstruct(domain) && isscalar(domain) && isfield(domain, 'az_grid_deg')
    grid = domain.az_grid_deg(:).';
elseif isnumeric(domain)
    grid = domain(:).';
else
    error('estimate_conditional_azimuth_dml:SearchDomain', ...
        'search_domain must contain az_grid_deg or be a numeric grid.');
end
if isempty(grid) || any(~isfinite(grid)) || numel(unique(grid)) ~= numel(grid)
    error('estimate_conditional_azimuth_dml:SearchGrid', ...
        'The registered azimuth grid must contain unique finite points.');
end
grid = sort(grid);
end

function name = enumeration_name_local(Kq)
if Kq == 1
    name = 'registered_single_angle_full_grid';
else
    name = 'registered_all_unordered_angle_pairs';
end
end
