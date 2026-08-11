function result = test_stage8_k2_tfbc_runtime_protocol(fixture)
%TEST_STAGE8_K2_TFBC_RUNTIME_PROTOCOL Verify frozen paired schedule.

[schedule, schedule_hash] = ...
    stage8_k2_tfbc_build_timing_schedule(fixture.registry);
groups = findgroups(schedule.comparison_id, schedule.trial_id);
ab_count = splitapply(@(x) nnz(x == "AB"), schedule.pair_order, groups);
ba_count = splitapply(@(x) nnz(x == "BA"), schedule.pair_order, groups);
pass = height(schedule) == 2880 && numel(unique(groups)) == 144 && ...
    all(ab_count == 10) && all(ba_count == 10) && ...
    strlength(string(schedule_hash)) == 64;
assert(pass, 'test_stage8_k2_tfbc_runtime_protocol:Failed');
result = struct('pass',pass, 'pair_count',height(schedule), ...
    'schedule_hash',schedule_hash);
end
