function methods = build_stage7_method_registry(operating, greedy_table, context)
%BUILD_STAGE7_METHOD_REGISTRY Register all mandatory finite-sample methods.

method_id = ["FULL_PARENT_5X5";"STAGE6_CENTER_3X3"; ...
    "FIXED_AZ_1X3";"FIXED_EL_3X1";"FIXED_RECT_3X3"; ...
    "FIXED_RECT_3X5";"FIXED_RECT_5X3"];
mask_e = [31;14;4;14;14;14;31];
mask_a = [31;14;14;4;14;31;14];
method_class = ["FULL_PARENT";"FIXED_RECTANGLE";"FIXED_RECTANGLE"; ...
    "FIXED_RECTANGLE";"FIXED_RECTANGLE";"FIXED_RECTANGLE"; ...
    "FIXED_RECTANGLE"];
eta0 = NaN(numel(method_id), 1);
for index = 1:height(operating)
    if ~operating.fim_gate_pass(index) || ...
            ~isfinite(operating.elevation_mask_integer(index)) || ...
            ~isfinite(operating.azimuth_mask_integer(index))
        continue;
    end
    method_id(end + 1, 1) = string(operating.method_id(index)); %#ok<AGROW>
    mask_e(end + 1, 1) = operating.elevation_mask_integer(index); %#ok<AGROW>
    mask_a(end + 1, 1) = operating.azimuth_mask_integer(index); %#ok<AGROW>
    method_class(end + 1, 1) = "EXACT"; %#ok<AGROW>
    eta0(end + 1, 1) = operating.eta0(index); %#ok<AGROW>
end
for index = 1:height(greedy_table)
    greedy_fim_pass = greedy_table.eta_design(index) >= greedy_table.eta0(index) && ...
        greedy_table.eta_validation(index) >= greedy_table.eta0(index) && ...
        greedy_table.eta_holdout(index) >= greedy_table.eta0(index);
    if ~greedy_fim_pass
        continue;
    end
    method_id(end + 1, 1) = sprintf('GREEDY_ETA_%03d', ...
        round(100 * greedy_table.eta0(index))); %#ok<AGROW>
    mask_e(end + 1, 1) = greedy_table.elevation_mask_integer(index); %#ok<AGROW>
    mask_a(end + 1, 1) = greedy_table.azimuth_mask_integer(index); %#ok<AGROW>
    method_class(end + 1, 1) = "GREEDY"; %#ok<AGROW>
    eta0(end + 1, 1) = greedy_table.eta0(index); %#ok<AGROW>
end
subset_id = strings(numel(method_id), 1);
B_e = zeros(numel(method_id), 1);
B_a = zeros(numel(method_id), 1);
B_out = zeros(numel(method_id), 1);
MAC_total = zeros(numel(method_id), 1);
for index = 1:numel(method_id)
    row = context.plan.subset_family( ...
        context.plan.subset_family.elevation_mask_integer == mask_e(index) & ...
        context.plan.subset_family.azimuth_mask_integer == mask_a(index), :);
    subset_id(index) = row.subset_id;
    B_e(index) = row.B_e;
    B_a(index) = row.B_a;
    B_out(index) = row.B_out;
    MAC_total(index) = row.MAC_total;
end
methods = table(method_id, method_class, subset_id, mask_e, mask_a, ...
    B_e, B_a, B_out, MAC_total, eta0, 'VariableNames', ...
    {'method_id','method_class','subset_id','elevation_mask_integer', ...
    'azimuth_mask_integer','B_e','B_a','B_out','MAC_total','eta0'});
end
