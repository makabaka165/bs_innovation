function [validation, holdout] = build_stage7_selected_fim_details(methods, context)
%BUILD_STAGE7_SELECTED_FIM_DETAILS Expand selected methods on unseen scenarios.

rows = cell(height(methods), 1);
for method_index = 1:height(methods)
    family_row = context.plan.subset_family( ...
        context.plan.subset_family.subset_id == methods.subset_id(method_index), :);
    [~, detail] = evaluate_stage7_subset(family_row, context, ...
        struct('return_detail', true));
    detail.method_id = repmat(methods.method_id(method_index), height(detail), 1);
    detail.method_class = repmat(methods.method_class(method_index), height(detail), 1);
    rows{method_index} = detail;
end
all_detail = vertcat(rows{:});
validation = all_detail(all_detail.data_split == "VALIDATION", :);
holdout = all_detail(all_detail.data_split == "FIM_HOLDOUT", :);
end
