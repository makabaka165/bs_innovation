function [start, debug] = stage8_r1_build_direct_grid_pair_start( ...
    full_data, local_domain, model)
%STAGE8_R1_BUILD_DIRECT_GRID_PAIR_START Exhaustively score unordered pairs.

clock = tic;
points = sortrows(local_domain.candidate_points_deg, [1, 2]);
pairs = nchoosek(1:size(points, 1), 2);
angles = cell(size(pairs, 1), 1);
keys = zeros(size(pairs, 1), 4);
for index = 1:size(pairs, 1)
    angles{index} = sortrows(points(pairs(index, :), :), [2, 1]);
    keys(index, :) = reshape(angles{index}(:, [2, 1]).', 1, []);
end
[~, order] = sortrows(keys, 1:4);
angles = angles(order);
score = -Inf(numel(angles), 1);
rank_now = zeros(numel(angles), 1);
num_svd = 0;
for index = 1:numel(angles)
    [G, ~, manifold_info] = build_full_sequential_local_manifold( ...
        angles{index}, model, struct('rank_multiplier', 1));
    num_svd = num_svd + manifold_info.num_svd;
    rank_now(index) = manifold_info.rank_Gseq;
    if rank_now(index) == 2
        [score(index), ~, ~, ~, effective_rank] = ...
            concentrated_dml_rss(full_data.Zseq_white, G, struct( ...
            'requested_rank', 2, 'rank_multiplier', 1, ...
            'compute_projector_checks', false));
        num_svd = num_svd + 1;
        if effective_rank < 2, score(index) = -Inf; end
    end
end
valid = isfinite(score) & rank_now == 2;
start = struct('initialization_id', 'M1_K2_DIRECT_GRID_PAIR_BEST', ...
    'angles_deg', NaN(2, 2), 'available_flag', false, ...
    'initialization_status', 'NO_FULL_RANK_DIRECT_GRID_PAIR');
best_index = 0;
if any(valid)
    maximum = max(score(valid));
    tolerance = 64 * eps(max(1, abs(maximum)));
    best_index = find(valid & score >= maximum - tolerance, 1, 'first');
    start.angles_deg = angles{best_index};
    start.available_flag = true;
    start.initialization_status = 'INITIALIZATION_READY';
end
debug = struct('pair_count', numel(angles), ...
    'full_rank_pair_count', nnz(valid), 'best_pair_index', best_index, ...
    'best_score', max([score(valid);-Inf]), ...
    'num_score_eval', nnz(rank_now == 2), 'num_svd', num_svd, ...
    'runtime_sec', toc(clock), ...
    'selection_rule', ...
    'MAX_SCORE_LEXICOGRAPHIC_FIRST_ELEVATION_AZIMUTH');
end
