function feasible_set = enumerate_stage7_minimum_cost_feasible_set( ...
    result_dir, eta0)
%ENUMERATE_STAGE7_MINIMUM_COST_FEASIBLE_SET Audit all minimum-MAC members.

if nargin < 2 || isempty(eta0), eta0 = 0.80; end
if ~(isnumeric(eta0) && isscalar(eta0) && isfinite(eta0))
    error('enumerate_stage7_minimum_cost_feasible_set:Eta', ...
        'eta0 must be a finite numeric scalar.');
end
result_dir = validate_result_dir_local(result_dir);
enumeration = readtable(fullfile(result_dir, ...
    'fim_subset_enumeration.csv'), 'TextType', 'string');
operating = readtable(fullfile(result_dir, ...
    'fim_operating_points.csv'), 'TextType', 'string');

feasible = enumeration(enumeration.eta_design >= eta0 & ...
    enumeration.eta_validation >= eta0 & enumeration.eta_holdout >= eta0, :);
if isempty(feasible)
    error('enumerate_stage7_minimum_cost_feasible_set:Infeasible', ...
        'No subset passes all three eta gates at eta0=%.6g.', eta0);
end
minimum_mac = min(feasible.MAC_total);
minimum = feasible(feasible.MAC_total == minimum_mac, :);
registered_row = operating(abs(operating.eta0 - eta0) <= eps(eta0) & ...
    operating.fim_gate_pass, :);
if height(registered_row) ~= 1
    error('enumerate_stage7_minimum_cost_feasible_set:Registered', ...
        'Expected one registered passing operating point at eta0=%.6g.', eta0);
end
registered_id = registered_row.subset_id;
registered = minimum(minimum.subset_id == registered_id, :);
if height(registered) ~= 1
    error('enumerate_stage7_minimum_cost_feasible_set:RegisteredCost', ...
        'The registered selection is not in the minimum-cost feasible family.');
end

subset_id = minimum.subset_id;
I_e = minimum.I_e_global;
I_a = minimum.I_a_global;
MAC_total = minimum.MAC_total;
B_out = minimum.B_out;
eta_design = minimum.eta_design;
eta_validation = minimum.eta_validation;
eta_holdout = minimum.eta_holdout;
minimum_cost_flag = true(height(minimum), 1);
registered_selection_flag = subset_id == registered_id;
tolerance = 4096 * eps(max([eta_design;eta_validation;eta_holdout]));
same_cost_dominates_registered_flag = ...
    eta_design >= registered.eta_design - tolerance & ...
    eta_validation >= registered.eta_validation - tolerance & ...
    eta_holdout >= registered.eta_holdout - tolerance & ...
    (eta_design > registered.eta_design + tolerance | ...
    eta_validation > registered.eta_validation + tolerance | ...
    eta_holdout > registered.eta_holdout + tolerance);
dominance_reason = repmat( ...
    "NO_COMPONENTWISE_DOMINANCE_OVER_REGISTERED_SELECTION", ...
    height(minimum), 1);
dominance_reason(same_cost_dominates_registered_flag) = ...
    "SAME_MAC_AND_NO_LOWER_ETA_ACROSS_ALL_SPLITS";
if any(same_cost_dominates_registered_flag)
    dominance_reason(registered_selection_flag) = ...
        "REGISTERED_SELECTION_RETAINED_DESPITE_POST_HOC_SAME_COST_DOMINATOR";
end

role = repmat("MINIMUM_COST_FEASIBLE_MEMBER", height(minimum), 1);
role = add_role_local(role, registered_selection_flag, ...
    "LEXICOGRAPHIC_REGISTERED_SELECTION");
role = add_role_local(role, maximum_flag_local(eta_design), ...
    "MAX_DESIGN_ETA_SENSITIVITY");
role = add_role_local(role, maximum_flag_local(eta_validation), ...
    "MAX_VALIDATION_ETA_SENSITIVITY");
role = add_role_local(role, maximum_flag_local(eta_holdout), ...
    "MAX_HOLDOUT_ETA_SENSITIVITY");
central = minimum.elevation_mask_integer == 14 & ...
    minimum.azimuth_mask_integer == 31;
role = add_role_local(role, central, "CENTRAL_SYMMETRIC_FIXED_BASELINE");

feasible_set = table(subset_id, I_e, I_a, MAC_total, B_out, ...
    eta_design, eta_validation, eta_holdout, minimum_cost_flag, ...
    registered_selection_flag, same_cost_dominates_registered_flag, ...
    dominance_reason, role);
feasible_set = sortrows(feasible_set, 'subset_id');
end

function result_dir = validate_result_dir_local(result_dir)
if isstring(result_dir), result_dir = char(result_dir); end
if ~(ischar(result_dir) && isrow(result_dir) && exist(result_dir, 'dir') == 7)
    error('enumerate_stage7_minimum_cost_feasible_set:ResultDir', ...
        'result_dir must identify the Stage 7 results directory.');
end
end

function flags = maximum_flag_local(values)
maximum = max(values);
flags = abs(values - maximum) <= 4096 * eps(max(abs(maximum), 1));
end

function role = add_role_local(role, flags, label)
for index = find(flags(:)).'
    role(index) = role(index) + ";" + label;
end
end
