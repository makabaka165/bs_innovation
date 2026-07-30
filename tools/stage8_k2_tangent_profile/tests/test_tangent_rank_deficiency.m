function result = test_tangent_rank_deficiency()
%TEST_TANGENT_RANK_DEFICIENCY Reject a rank-one Fisher metric.

T = [2, 0; 0, 0];
Ct = [1, 0.2; 0.2, 0.5];
direction = stage8_k2_tp_projected_direction(T, Ct);
assert(~direction.valid && isempty(direction.direction_hat) && ...
    strcmp(direction.status, 'TANGENT_METRIC_RANK_DEFICIENT'), ...
    'test_tangent_rank_deficiency:Failed', ...
    'A rank-deficient metric generated a tangent direction.');
result = struct('pass', true, 'metric_rank', direction.metric_rank, ...
    'status', direction.status);
fprintf('test_tangent_rank_deficiency PASS status=%s\n', direction.status);
end
