function schedule = stage8_k2_tecs_build_screening_schedule( ...
    comparison, registry)
%STAGE8_K2_TECS_BUILD_SCREENING_SCHEDULE Deterministic 72x6 pairs.

seed_trial = 2026080902;
seed_pair = 2026080903;
rows = repmat(schedule_template_local(), ...
    height(comparison.raw) * height(registry) * 6, 1);
cursor = 0;
for comparison_index = 1:height(comparison.raw)
    current = comparison.raw(comparison_index, :);
    for trial_index = 1:height(registry)
        trial_id = char(registry.trial_id(trial_index));
        nominal = [repmat("AB", 3, 1); repmat("BA", 3, 1)];
        keys = strings(6, 1);
        for local_index = 1:6
            material = struct('seed', seed_pair, 'pass', 'PASS_E', ...
                'comparison_id', char(current.comparison_id), ...
                'trial_id', trial_id, ...
                'local_repeat_index', local_index, ...
                'nominal_direction', char(nominal(local_index)));
            keys(local_index) = stage8_k2_tecs_sha256( ...
                'PAIR_ORDER', material);
        end
        [~, order] = sort(keys);
        for repeat_index = 1:6
            nominal_index = order(repeat_index);
            cursor = cursor + 1;
            row = schedule_template_local();
            row.comparison_id = current.comparison_id;
            row.baseline_canonical_mode_id = ...
                current.baseline_canonical_mode_id;
            row.candidate_canonical_mode_id = ...
                current.candidate_canonical_mode_id;
            row.enabled_layer_set_hash = current.enabled_layer_set_hash;
            row.precedence_hash = current.precedence_hash;
            row.fixed_measurement_hash = identity_for_trial_local( ...
                registry(trial_index, :));
            row.global_trial_index = registry.global_trial_index(trial_index);
            row.trial_id = string(trial_id);
            row.repeat_index = repeat_index;
            row.nominal_repeat_index = nominal_index;
            row.pair_order = nominal(nominal_index);
            row.pair_order_key = keys(nominal_index);
            trial_material = struct('seed', seed_trial, ...
                'pass', 'PASS_E', ...
                'comparison_id', char(current.comparison_id), ...
                'repeat_index', repeat_index, 'trial_id', trial_id);
            row.trial_order_key = stage8_k2_tecs_sha256( ...
                'TRIAL_ORDER', trial_material);
            rows(cursor) = row;
        end
    end
end
schedule = struct2table(rows);
schedule = sortrows(schedule, ...
    {'comparison_id','repeat_index','trial_order_key','global_trial_index'});
schedule.schedule_row_id = (1:height(schedule)).';
schedule = movevars(schedule, 'schedule_row_id', 'Before', 1);
hashes = strings(height(schedule), 1);
for index = 1:height(schedule)
    hashes(index) = stage8_k2_tecs_sha256( ...
        'TECS_SCREENING_SCHEDULE_ROW_V1', ...
        table2struct(schedule(index, :)));
end
schedule.schedule_row_hash = hashes;
end

function identity = identity_for_trial_local(spec)
switch char(spec.noise_profile_id)
    case 'WHITE'
        identity = ...
            "208ac1cfafa1a4e0367aa0af9d46f0a362b14343fad97aaa06a7888e73a536fe";
    case 'STAGE5_TOEPLITZ_CORRELATED'
        identity = ...
            "e965700fc8d335f6546924993f4e20988aa34b85d5e11899ed0fb3136c3a5c16";
    otherwise
        error('stage8_k2_tecs_build_screening_schedule:Identity');
end
end

function row = schedule_template_local()
row = struct('comparison_id', "", ...
    'baseline_canonical_mode_id', "", ...
    'candidate_canonical_mode_id', "", ...
    'enabled_layer_set_hash', "", 'precedence_hash', "", ...
    'fixed_measurement_hash', "", 'global_trial_index', 0, ...
    'trial_id', "", 'repeat_index', 0, ...
    'nominal_repeat_index', 0, 'pair_order', "", ...
    'pair_order_key', "", 'trial_order_key', "", ...
    'included_in_statistics', true);
end
