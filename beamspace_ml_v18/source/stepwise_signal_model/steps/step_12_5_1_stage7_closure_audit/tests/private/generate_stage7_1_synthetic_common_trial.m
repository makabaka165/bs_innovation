function trial = generate_stage7_1_synthetic_common_trial( ...
    plan_row, trial_index, ~)
%GENERATE_STAGE7_1_SYNTHETIC_COMMON_TRIAL Small deterministic runner fixture.

row = table2struct(plan_row);
targets = [row.target1_az_deg,row.target1_el_deg; ...
    row.target2_az_deg,row.target2_el_deg];
trial = struct();
trial.Y_element = complex([trial_index;row.paired_group_index], ...
    [row.element_snr_db;trial_index]);
trial.signal = 0.75 * trial.Y_element;
trial.noise = 0.25 * trial.Y_element;
trial.source_matrix = ones(2, 1);
trial.target_angles_deg = targets;
trial.paired_group_id = row.paired_group_id;
trial.paired_group_index = row.paired_group_index;
trial.trial_index = trial_index;
trial.trial_seed = row.group_seed_start + trial_index - 1;
trial.realized_element_snr_db = row.element_snr_db + 0.01 * trial_index;
trial.historical_registered_domain_pass = ...
    logical(row.historical_registered_domain_pass);
trial.tolerant_registered_domain_pass = ...
    logical(row.tolerant_registered_domain_pass);
trial.boundary_numeric_disagreement_flag = ...
    logical(row.boundary_numeric_disagreement_flag);
trial.domain_tolerance_deg = row.domain_tolerance_deg;
trial.edge_diagnostic_domain_pass = ...
    logical(row.edge_diagnostic_domain_pass);
trial.common_trial_generation_count = 1;
end
