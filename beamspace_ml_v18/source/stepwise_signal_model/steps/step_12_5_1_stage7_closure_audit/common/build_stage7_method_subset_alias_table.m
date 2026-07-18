function aliases = build_stage7_method_subset_alias_table(result_dir)
%BUILD_STAGE7_METHOD_SUBSET_ALIAS_TABLE Map labels to physical subsets.

result_dir = validate_result_dir_local(result_dir);
methods = readtable(fullfile(result_dir, 'fim_vs_finite_sample_risk.csv'), ...
    'TextType', 'string');
family = readtable(fullfile(result_dir, 'stage7_subset_family.csv'), ...
    'TextType', 'string');
required_methods = {'method_id','method_class','subset_id','B_out'};
required_family = {'subset_id','elevation_mask_integer', ...
    'azimuth_mask_integer','I_e_global','I_a_global','B_e','B_a','B_out'};
if ~all(ismember(required_methods, methods.Properties.VariableNames)) || ...
        ~all(ismember(required_family, family.Properties.VariableNames))
    error('build_stage7_method_subset_alias_table:Schema', ...
        'Stage 7 method or subset schema is incomplete.');
end

[found, family_index] = ismember(methods.subset_id, family.subset_id);
if ~all(found)
    error('build_stage7_method_subset_alias_table:Subset', ...
        'Every method must resolve to one registered subset.');
end
matched = family(family_index, :);
method_id = methods.method_id;
method_class = methods.method_class;
subset_id = methods.subset_id;
elevation_mask = matched.elevation_mask_integer;
azimuth_mask = matched.azimuth_mask_integer;
I_e = matched.I_e_global;
I_a = matched.I_a_global;
B_el = matched.B_e;
B_az = matched.B_a;
B_out = matched.B_out;

physical_subset_hash = strings(height(methods), 1);
for index = 1:height(methods)
    physical_subset_hash(index) = stage7_stable_hash( ...
        elevation_mask(index), azimuth_mask(index), ...
        char(I_e(index)), char(I_a(index)));
end
[group_index, group_hash] = stable_group_local(physical_subset_hash);
group_size = accumarray(group_index, 1);
alias_group_id = compose('PHYSICAL_SUBSET_ALIAS_%02d', group_index);
alias_group_size = group_size(group_index);
is_duplicate_physical_method = alias_group_size > 1;
primary_label = strings(height(methods), 1);
for group = 1:numel(group_hash)
    members = find(group_index == group);
    priority = zeros(numel(members), 1);
    for member_index = 1:numel(members)
        priority(member_index) = label_priority_local( ...
            method_id(members(member_index)));
    end
    candidates = table(priority, method_id(members), members, ...
        'VariableNames', {'priority','method_id','row_index'});
    candidates = sortrows(candidates, {'priority','method_id'});
    primary_label(members) = candidates.method_id(1);
end
comparison_independence_status = repmat( ...
    "DISTINCT_PHYSICAL_SUBSET", height(methods), 1);
comparison_independence_status(is_duplicate_physical_method) = ...
    "IDENTICAL_PHYSICAL_SUBSET_NOT_INDEPENDENT_METHOD";

aliases = table(method_id, method_class, subset_id, elevation_mask, ...
    azimuth_mask, I_e, I_a, B_el, B_az, B_out, physical_subset_hash, ...
    alias_group_id, alias_group_size, is_duplicate_physical_method, ...
    primary_label, comparison_independence_status);
end

function result_dir = validate_result_dir_local(result_dir)
if isstring(result_dir), result_dir = char(result_dir); end
if ~(ischar(result_dir) && isrow(result_dir) && exist(result_dir, 'dir') == 7)
    error('build_stage7_method_subset_alias_table:ResultDir', ...
        'result_dir must identify the Stage 7 results directory.');
end
end

function [group_index, unique_hashes] = stable_group_local(hashes)
unique_hashes = strings(0, 1);
group_index = zeros(numel(hashes), 1);
for index = 1:numel(hashes)
    match = find(unique_hashes == hashes(index), 1);
    if isempty(match)
        unique_hashes(end + 1, 1) = hashes(index); %#ok<AGROW>
        match = numel(unique_hashes);
    end
    group_index(index) = match;
end
end

function priority = label_priority_local(method_id)
if startsWith(method_id, "FIXED_") || method_id == "FULL_PARENT_5X5"
    priority = 1;
elseif startsWith(method_id, "STAGE6_")
    priority = 2;
elseif startsWith(method_id, "EXACT_")
    priority = 3;
else
    priority = 4;
end
end
