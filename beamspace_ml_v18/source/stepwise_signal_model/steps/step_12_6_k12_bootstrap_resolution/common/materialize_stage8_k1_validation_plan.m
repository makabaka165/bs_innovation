function registry = materialize_stage8_k1_validation_plan(validation_plan)
%MATERIALIZE_STAGE8_K1_VALIDATION_PLAN Expand 6000 trials to paired rows.

K1 = validation_plan.K1;
required = {'strata','measurement_config_ids','trials_per_stratum', ...
    'common_element_trial_count','config_evaluation_row_count'};
if ~all(isfield(K1, required))
    error('materialize_stage8_k1_validation_plan:Plan', ...
        'validation_plan.K1 is incomplete.');
end
strata = K1.strata;
config_ids = K1.measurement_config_ids;
row_count = height(strata) * K1.trials_per_stratum * numel(config_ids);
stratum_index = zeros(row_count, 1);
stratum_id = strings(row_count, 1);
common_trial_id = strings(row_count, 1);
pairing_key = strings(row_count, 1);
trial_index_within_stratum = zeros(row_count, 1);
measurement_config_id = strings(row_count, 1);
noise_profile_id = strings(row_count, 1);
L = zeros(row_count, 1);
parameter_seed = zeros(row_count, 1);
element_noise_seed = zeros(row_count, 1);
separation_auxiliary_seed = zeros(row_count, 1);
evaluation_row_index = (1:row_count).';
row_index = 0;
for stratum_row = 1:height(strata)
    for trial_index = 1:K1.trials_per_stratum
        trial_id = sprintf('%s_T%04d', ...
            char(strata.stratum_id(stratum_row)), trial_index);
        for config_index = 1:numel(config_ids)
            row_index = row_index + 1;
            stratum_index(row_index) = strata.stratum_index(stratum_row);
            stratum_id(row_index) = strata.stratum_id(stratum_row);
            common_trial_id(row_index) = string(trial_id);
            pairing_key(row_index) = string(trial_id);
            trial_index_within_stratum(row_index) = trial_index;
            measurement_config_id(row_index) = config_ids(config_index);
            noise_profile_id(row_index) = ...
                strata.noise_profile_id(stratum_row);
            L(row_index) = strata.L(stratum_row);
            parameter_seed(row_index) = ...
                strata.parameter_seed_start(stratum_row) + trial_index - 1;
            element_noise_seed(row_index) = ...
                strata.element_noise_seed_start(stratum_row) + trial_index - 1;
            separation_auxiliary_seed(row_index) = ...
                strata.separation_auxiliary_seed_start(stratum_row) + ...
                trial_index - 1;
        end
    end
end
registry = table(evaluation_row_index, stratum_index, stratum_id, ...
    common_trial_id, pairing_key, trial_index_within_stratum, ...
    measurement_config_id, noise_profile_id, L, parameter_seed, ...
    element_noise_seed, separation_auxiliary_seed);
if height(registry) ~= K1.config_evaluation_row_count || ...
        numel(unique(registry.common_trial_id)) ~= ...
        K1.common_element_trial_count
    error('materialize_stage8_k1_validation_plan:Cardinality', ...
        'The paired validation registry has the wrong cardinality.');
end
end
