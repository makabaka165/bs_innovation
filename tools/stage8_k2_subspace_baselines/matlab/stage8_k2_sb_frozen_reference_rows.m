function rows = stage8_k2_sb_frozen_reference_rows(context, new_rows)
%STAGE8_K2_SB_FROZEN_REFERENCE_ROWS Read evidence 34 without refitting.

rows = readtable(context.reference_trials_path, 'TextType', 'string');
rows = rows(ismember(rows.method_id, ...
    context.constants.reference_method_ids), :);
expected_counts = [72, 72, 24, 72, 72];
for index = 1:numel(context.constants.reference_method_ids)
    method_id = context.constants.reference_method_ids(index);
    if nnz(rows.method_id == method_id) ~= expected_counts(index)
        error('stage8_k2_sb_frozen_reference_rows:MethodCount', ...
            'Frozen evidence-34 method count changed for %s.', method_id);
    end
end
if any(logical(rows.truth_used_in_fit_flag)) || ...
        any(~logical(rows.element_hash_match_flag))
    error('stage8_k2_sb_frozen_reference_rows:Integrity', ...
        'Frozen evidence violates truth isolation or element identity.');
end
for index = 1:height(context.registry)
    trial_id = context.registry.trial_id(index);
    subset = rows(rows.trial_id == trial_id, :);
    expected = context.cb_context.frozen_trial_identity.element_trial_hash(index);
    if isempty(subset) || any(subset.element_trial_hash ~= expected)
        error('stage8_k2_sb_frozen_reference_rows:TrialHash', ...
            'A frozen reference row does not pair to evidence 31.');
    end
end

string_names = {'trial_id','method_id','method_source', ...
    'observation_domain','noise_profile_id','profile_id', ...
    'element_trial_hash','applicability_status','fit_status', ...
    'optimizer_status','selected_source','selected_start_id', ...
    'angles_hat_deg','numerical_optimization_status'};
logical_names = {'element_hash_match_flag','applicable','fit_valid', ...
    'numerical_optimization_incomplete_flag','truth_used_in_fit_flag', ...
    'profile_used_in_fit_flag','tangent_used_in_start_flag', ...
    'core_used_in_start_flag','full_manifold_used_flag', ...
    'single_cpi_flag','same_range_doppler_cell_flag', ...
    'cross_cpi_data_used_flag','tracking_input_used_flag', ...
    'K_estimated_inside_module_flag'};
for index = 1:numel(string_names)
    rows.(string_names{index}) = string(rows.(string_names{index}));
end
for index = 1:numel(logical_names)
    rows.(logical_names{index}) = logical(rows.(logical_names{index}));
end
if nargin >= 2 && ~isempty(new_rows)
    if ~isequal(rows.Properties.VariableNames, ...
            new_rows.Properties.VariableNames)
        error('stage8_k2_sb_frozen_reference_rows:Schema', ...
            'Frozen and new result-row schemas differ.');
    end
    for index = 1:numel(rows.Properties.VariableNames)
        name = rows.Properties.VariableNames{index};
        if ~strcmp(class(rows.(name)), class(new_rows.(name)))
            error('stage8_k2_sb_frozen_reference_rows:Type', ...
                'Frozen/new column type differs for %s.', name);
        end
    end
end
end
