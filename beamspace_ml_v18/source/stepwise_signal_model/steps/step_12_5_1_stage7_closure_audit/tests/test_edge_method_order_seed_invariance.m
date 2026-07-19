function table_out = test_edge_method_order_seed_invariance(result_dir)
%TEST_EDGE_METHOD_ORDER_SEED_INVARIANCE Exclude method labels from seeds.

plan = build_stage7_1_edge_diagnostic_plan(result_dir);
rng(20260719, 'twister');
reordered = plan;
group_ids = unique(string(plan.paired_group_id), 'stable');
for index = 1:numel(group_ids)
    rows = find(string(reordered.paired_group_id) == group_ids(index));
    reordered(rows, :) = reordered(rows(randperm(3)), :);
end
first = expanded_seed_table_local(plan);
second = expanded_seed_table_local(reordered);

case_id = ["METHOD_ORDER_CHANGED";"COMMON_TRIAL_KEYS_SAME"; ...
    "TRIAL_SEEDS_SAME";"METHOD_LABEL_NOT_IN_FORMULA"];
pass_flag = [~isequal(plan.method_id, reordered.method_id); ...
    isequal(first(:, {'paired_group_id','trial_index'}), ...
    second(:, {'paired_group_id','trial_index'})); ...
    isequal(first.trial_seed, second.trial_seed); ...
    all(plan.trial_seed_formula == ...
    "group_seed_start+trial_index-1")];
table_out = table(case_id, pass_flag);
assert(all(pass_flag), ...
    'test_edge_method_order_seed_invariance:Failed', ...
    'Method row order changed the common trial seed mapping.');
end

function expanded = expanded_seed_table_local(plan)
groups = unique(plan(:, {'paired_group_id','paired_group_index', ...
    'group_seed_start','paired_trial_count'}), 'rows');
groups = sortrows(groups, 'paired_group_index');
rows = cell(sum(groups.paired_trial_count), 1);
row_index = 0;
for index = 1:height(groups)
    for trial_index = 1:groups.paired_trial_count(index)
        row_index = row_index + 1;
        rows{row_index} = struct('paired_group_id', ...
            groups.paired_group_id(index), 'trial_index', trial_index, ...
            'trial_seed', groups.group_seed_start(index) + trial_index - 1);
    end
end
expanded = struct2table(vertcat(rows{:}));
end
