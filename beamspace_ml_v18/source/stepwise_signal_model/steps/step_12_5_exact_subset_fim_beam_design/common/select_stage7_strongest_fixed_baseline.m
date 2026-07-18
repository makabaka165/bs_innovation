function method_id = select_stage7_strongest_fixed_baseline(methods, enumeration)
%SELECT_STAGE7_STRONGEST_FIXED_BASELINE Freeze the strongest fixed comparator.

fixed = methods(methods.method_class == "FIXED_RECTANGLE", :);
fixed.eta_design = zeros(height(fixed), 1);
fixed.eta_validation = zeros(height(fixed), 1);
for index = 1:height(fixed)
    row = enumeration(enumeration.subset_id == fixed.subset_id(index), :);
    fixed.eta_design(index) = row.eta_design;
    fixed.eta_validation(index) = row.eta_validation;
end
fixed = sortrows(fixed, {'eta_design','eta_validation','MAC_total','method_id'}, ...
    {'descend','descend','ascend','ascend'});
method_id = fixed.method_id(1);
end
