function plan = build_stage7_1_memory_plan_fixture(result_dir)
%BUILD_STAGE7_1_MEMORY_PLAN_FIXTURE Build a frozen-shape memory test plan.

subset_family = readtable(fullfile(result_dir, ...
    'stage7_subset_family.csv'), 'TextType', 'string');
sequential_channel_id = (1:25).';
pool = struct('table', table(sequential_channel_id));
plan = struct();
plan.pool = pool;
plan.subset_family = subset_family;
plan.cost = struct('N_el', 32, 'N_az', 65, ...
    'complex_double_bytes', 16);
plan.hashes = struct('stage7_plan_hash', repmat('a', 1, 64));
plan.phase_factor = 1;
plan.plan_freeze_status = 'FROZEN_BEFORE_ANY_STAGE7_FIM_RESULT';
end
