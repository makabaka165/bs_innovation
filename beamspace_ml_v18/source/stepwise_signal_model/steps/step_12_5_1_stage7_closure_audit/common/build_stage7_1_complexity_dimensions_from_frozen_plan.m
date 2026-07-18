function dimensions = ...
    build_stage7_1_complexity_dimensions_from_frozen_plan(plan)
%BUILD_STAGE7_1_COMPLEXITY_DIMENSIONS_FROM_FROZEN_PLAN Extract formal sizes.

if ~(isstruct(plan) && isscalar(plan) && isfield(plan, 'cost') && ...
        isstruct(plan.cost) && isscalar(plan.cost) && ...
        isfield(plan, 'subset_family') && istable(plan.subset_family))
    error('build_stage7_1_complexity_dimensions_from_frozen_plan:Plan', ...
        'plan must contain the frozen cost object and subset family.');
end
required_cost = {'N_el','N_az','complex_double_bytes'};
if ~all(isfield(plan.cost, required_cost))
    error('build_stage7_1_complexity_dimensions_from_frozen_plan:Cost', ...
        'The frozen plan cost object is incomplete.');
end
required_subset = {'subset_id','B_e','B_a'};
if ~all(ismember(required_subset, ...
        plan.subset_family.Properties.VariableNames))
    error('build_stage7_1_complexity_dimensions_from_frozen_plan:SubsetSchema', ...
        'The frozen subset family is missing B_e/B_a identity fields.');
end
selected = plan.subset_family( ...
    string(plan.subset_family.subset_id) == "RECT_E14_A31", :);
if height(selected) ~= 1
    error('build_stage7_1_complexity_dimensions_from_frozen_plan:Subset', ...
        'Expected one frozen RECT_E14_A31 subset row.');
end

dimensions = struct();
dimensions.N_el = plan.cost.N_el;
dimensions.N_az = plan.cost.N_az;
dimensions.B_el = selected.B_e;
dimensions.B_az = selected.B_a;
dimensions.complex_double_bytes = plan.cost.complex_double_bytes;
dimensions.dimension_source = 'FROZEN_STAGE7_PLAN_EXPLICIT_DIMENSIONS';
if isfield(plan, 'hashes') && isfield(plan.hashes, 'stage7_plan_hash')
    dimensions.frozen_stage7_plan_hash = plan.hashes.stage7_plan_hash;
else
    dimensions.frozen_stage7_plan_hash = '';
end
end
