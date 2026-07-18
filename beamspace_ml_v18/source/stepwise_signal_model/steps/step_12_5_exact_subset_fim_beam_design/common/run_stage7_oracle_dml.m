function estimate = run_stage7_oracle_dml(Z, G_bank, finite, K)
%RUN_STAGE7_ORACLE_DML Run the common oracle-K SVD-DML solver.

solver = finite.context.plan.solver;
grid = finite.grid_angles_deg;
grid_count = size(grid, 1);
singleton_score = -Inf(grid_count, 1);
score_calls = 0;
svd_calls = 0;
start_tic = tic;
for grid_index = 1:grid_count
    [singleton_score(grid_index), ~] = beamspace_dml_score_svd( ...
        Z, G_bank(:, grid_index), struct('requested_rank', 1, ...
        'rank_multiplier', solver.manifold_rank_multiplier, ...
        'compute_projector_checks', false));
    score_calls = score_calls + 1;
    svd_calls = svd_calls + 1;
end
[~, order] = sort(singleton_score, 'descend');
if K == 1
    angle_indices = order(1);
else
    angle_indices = order(1:K);
end
angles = canonicalize_local(grid(angle_indices, :));
[current_score, current_rss, rank_now] = score_angles_local( ...
    Z, G_bank, angles, finite, K);
score_calls = score_calls + 1;
svd_calls = svd_calls + 1;
if rank_now < K
    estimate = failure_local(K, score_calls, svd_calls, toc(start_tic));
    return;
end

converged = false;
iteration_count = 0;
for iteration = 1:solver.max_iter
    iteration_count = iteration;
    start_angles = angles;
    start_score = current_score;
    for target_index = 1:K
        for dimension = 1:2
            if dimension == 1
                axis_values = finite.az_grid_deg;
            else
                axis_values = finite.el_grid_deg;
            end
            best_angles = angles;
            best_score = current_score;
            best_rss = current_rss;
            for value_index = 1:numel(axis_values)
                candidate = angles;
                candidate(target_index, dimension) = axis_values(value_index);
                candidate = canonicalize_local(candidate);
                if K == 2 && all(candidate(1, :) == candidate(2, :))
                    continue;
                end
                [score, rss, candidate_rank] = score_angles_local( ...
                    Z, G_bank, candidate, finite, K);
                score_calls = score_calls + 1;
                svd_calls = svd_calls + 1;
                if candidate_rank == K && score > best_score
                    best_score = score;
                    best_rss = rss;
                    best_angles = candidate;
                end
            end
            angles = best_angles;
            current_score = best_score;
            current_rss = best_rss;
        end
    end
    relative_change = abs(current_score - start_score) / ...
        max(abs(start_score), realmin);
    if relative_change <= solver.relative_score_tolerance && ...
            max(abs(angles(:) - start_angles(:))) <= solver.angle_tolerance_deg
        converged = true;
        break;
    end
end
estimate = struct('angles_hat_deg', angles, 'score', current_score, ...
    'rss', current_rss, 'rank_G', K, 'score_calls', score_calls, ...
    'svd_calls', svd_calls, 'iterations', iteration_count, ...
    'multi_start_count', solver.multi_start_count, ...
    'runtime_sec', toc(start_tic), 'estimate_returned_flag', true, ...
    'converged_flag', converged, 'status', ...
    string(ternary_local(converged, 'ORACLE_DML_CONVERGED', ...
    'ORACLE_DML_MAX_ITER')));
end

function [score, rss, rank_value] = score_angles_local(Z, G_bank, angles, finite, K)
indices = zeros(K, 1);
for target_index = 1:K
    az_index = find(finite.az_grid_deg == angles(target_index, 1), 1);
    el_index = find(finite.el_grid_deg == angles(target_index, 2), 1);
    indices(target_index) = az_index + (el_index - 1) * finite.N_az_grid;
end
[score, rss, debug] = beamspace_dml_score_svd(Z, G_bank(:, indices), ...
    struct('requested_rank', K, ...
    'rank_multiplier', finite.context.plan.solver.manifold_rank_multiplier, ...
    'compute_projector_checks', false));
rank_value = debug.effective_rank;
end

function angles = canonicalize_local(angles)
[~, order] = sortrows([angles(:, 2), angles(:, 1)], [1,2]);
angles = angles(order, :);
end

function estimate = failure_local(K, score_calls, svd_calls, runtime)
estimate = struct('angles_hat_deg', NaN(K, 2), 'score', NaN, 'rss', Inf, ...
    'rank_G', 0, 'score_calls', score_calls, 'svd_calls', svd_calls, ...
    'iterations', 0, 'multi_start_count', 1, 'runtime_sec', runtime, ...
    'estimate_returned_flag', false, 'converged_flag', false, ...
    'status', "ORACLE_DML_NUMERICAL_FAILURE");
end

function value = ternary_local(condition, yes_value, no_value)
if condition, value = yes_value; else, value = no_value; end
end
