function table_out = test_stage7_no_model_order_logic(step_dir)
%TEST_STAGE7_NO_MODEL_ORDER_LOGIC Reject model-order selection in Stage 7.

files = [dir(fullfile(step_dir, 'common', '**', '*.m')); ...
    dir(fullfile(step_dir, 'run_step12_5_exact_subset_fim_design.m'))];
forbidden = ["select_model_order";"estimate_model_order"; ...
    "parametric_bootstrap";"K2_UNRESOLVED";"false_split"; ...
    "false_resolved";"missed_split"];
counts = zeros(numel(forbidden), 1);
for file_index = 1:numel(files)
    text_now = string(fileread(fullfile(files(file_index).folder, ...
        files(file_index).name)));
    for pattern_index = 1:numel(forbidden)
        counts(pattern_index) = counts(pattern_index) + ...
            count(lower(text_now), lower(forbidden(pattern_index)));
    end
end
table_out = stage7_test_table(forbidden, counts, 0, counts == 0);
end
