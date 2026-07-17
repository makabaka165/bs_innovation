function reference = run_local_full_dml_reference(full_data, K, domain, model)
%RUN_LOCAL_FULL_DML_REFERENCE Enumerate the registered local physical domain.

points = domain.candidate_points_deg;
G_bank = complex(zeros(size(model.Tseq, 1), size(points, 1)));
bank_rank = zeros(size(points, 1), 1);
for point_index = 1:size(points, 1)
    [G_bank(:, point_index), ~, point_info] = ...
        build_full_sequential_local_manifold( ...
        points(point_index, :), model, struct());
    bank_rank(point_index) = point_info.rank_Gseq;
end
if K == 1
    candidate_index = (1:size(points, 1)).';
elseif K == 2
    candidate_index = nchoosek(1:size(points, 1), 2);
else
    error('run_local_full_dml_reference:TargetCount', ...
        'The stage-5 local reference supports only K=1 or K=2.');
end
score = -Inf(size(candidate_index, 1), 1);
rss = Inf(size(score));
rank_G = zeros(size(score));
score_opts = struct('requested_rank', K, 'rank_multiplier', 1, ...
    'compute_projector_checks', false);
start_tic = tic;
for idx = 1:size(candidate_index, 1)
    columns = candidate_index(idx, :);
    if all(bank_rank(columns) == 1)
        [score(idx), rss(idx), score_debug] = beamspace_dml_score_svd( ...
            full_data.Zseq_white, G_bank(:, columns), score_opts);
        rank_G(idx) = score_debug.effective_rank;
    end
end
runtime_sec = toc(start_tic);
valid = isfinite(score) & rank_G == K;
reference = struct();
reference.method = 'LOCAL_FULL_DML_REFERENCE';
reference.status = 'NO_FULL_RANK_LOCAL_CANDIDATE';
reference.angles_hat_deg = NaN(K, 2);
reference.score = NaN;
reference.rss = NaN;
reference.rank_Gseq = 0;
reference.num_score_eval = nnz(valid);
reference.num_svd = size(points, 1) + size(candidate_index, 1);
reference.num_candidate_manifold_build = size(points, 1);
reference.runtime_sec = runtime_sec;
reference.fixed_measurement_hash = model.fixed_measurement_hash;
reference.domain_hash = domain.domain_hash;
reference.statistical_calibration_status = 'NOT_CALIBRATED_STAGE5';
reference.phase_factor = 1;
if any(valid)
    valid_index = find(valid);
    [~, relative_index] = max(score(valid));
    best = valid_index(relative_index);
    reference.angles_hat_deg = canonicalize_local( ...
        points(candidate_index(best, :), :));
    reference.score = score(best);
    reference.rss = rss(best);
    reference.rank_Gseq = rank_G(best);
    reference.status = 'LOCAL_FULL_REFERENCE_RETURNED';
end
end

function angles = canonicalize_local(angles)
[~, order] = sortrows([angles(:, 2), angles(:, 1)], [1, 2]);
angles = angles(order, :);
end
