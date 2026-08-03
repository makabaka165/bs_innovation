function registry = stage8_k2_snr_build_white_control_registry(context)
%STAGE8_K2_SNR_BUILD_WHITE_CONTROL_REGISTRY Build paired 72-trial registry.

original = context.original_registry;
constants = context.constants;
rows = cell(height(original), 1);
for index = 1:height(original)
    source = original(index, :);
    row = table2struct(source);
    row.paired_original_trial_id = string(source.trial_id);
    row.trial_id = string(sprintf('SW1_K2_N%d_L%d_S%s_%s', ...
        find(context.tp_context.constants.noise_profile_ids == ...
        source.noise_profile_id, 1), source.L, ...
        signed_token_local(source.snr_db), char(source.profile_id)));
    row.snr_control_domain = string(constants.control_domain);
    row.white_beamspace_snr_target_db = double(source.snr_db);
    row.snr_db = double(source.snr_db);
    provisional = struct2table(row);
    trial = stage8_k2_snr_generate_white_control_trial(provisional, context);
    metrics = stage8_k2_snr_compute_metrics(trial);
    row.resulting_element_snr_expected_db = ...
        metrics.element_snr_expected_db;
    row.resulting_raw_beamspace_snr_expected_db = ...
        metrics.raw_beam_snr_expected_db;
    row.resulting_white_beamspace_snr_expected_db = ...
        metrics.white_beam_snr_expected_db;
    rows{index} = row;
end
registry = struct2table(vertcat(rows{:}));
if height(registry) ~= constants.trial_count || ...
        numel(unique(registry.trial_id)) ~= constants.trial_count || ...
        numel(unique(registry.paired_original_trial_id)) ~= ...
        constants.trial_count || ...
        any(abs(registry.resulting_white_beamspace_snr_expected_db - ...
        registry.white_beamspace_snr_target_db) > ...
        constants.snr_db_tolerance)
    error('stage8_k2_snr_build_white_control_registry:Integrity', ...
        'The paired white-control registry violates cardinality or SNR.');
end
end

function token = signed_token_local(value)
if value < 0
    token = sprintf('M%d', abs(value));
else
    token = sprintf('P%d', value);
end
end
