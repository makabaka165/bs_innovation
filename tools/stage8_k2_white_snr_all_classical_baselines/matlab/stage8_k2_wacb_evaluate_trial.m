function [rows, diagnostics, representative] = ...
    stage8_k2_wacb_evaluate_trial(spec, trial, context, resources)
%STAGE8_K2_WACB_EVALUATE_TRIAL Fit four new methods and evaluate afterward.

if string(resources.noise_profile_id) ~= string(spec.noise_profile_id)
    error('stage8_k2_wacb_evaluate_trial:Resource', ...
        'The active one-noise resource does not match the trial.');
end
constants = context.constants;
rules = repmat(struct('applicable', false, 'status', "", ...
    'uses_registered_scenario_flag', false), numel(constants.method_ids), 1);
for index = 1:numel(constants.method_ids)
    rules(index) = stage8_k2_wacb_applicability( ...
        spec, constants.method_ids(index));
end
fit_input = struct('Y_element', trial.Y_element, 'model', trial.model, ...
    'L', double(spec.L), 'resource_entry', resources.structured_entry, ...
    'music_resources', resources, 'applicability', rules);
fit = stage8_k2_wacb_fit_new_methods(fit_input, constants);
snr_row = context.evidence44.snr_rows( ...
    context.evidence44.snr_rows.trial_id == spec.trial_id, :);
if height(snr_row) ~= 1
    error('stage8_k2_wacb_evaluate_trial:SNRPairing', ...
        'Evidence 44 must provide one SNR row per trial.');
end

result_structs = repmat(stage8_k2_wacb_result_row( ...
    spec, trial, snr_row, fit.element_music, constants), 4, 1);
diagnostic_structs = repmat(stage8_k2_wacb_diagnostic_row( ...
    spec, trial, constants.method_ids(1), rules(1), fit, fit.common), 4, 1);
music = fit.element_music;
music.failure_stage = failure_stage_local(music, "ELEMENT_MUSIC");
music.applicability_uses_registered_scenario_flag = ...
    rules(1).uses_registered_scenario_flag;
music.preprocess_runtime_sec = 0;
music.elevation_runtime_sec = 0;
music.conditional_az_runtime_sec = 0;
result_structs(1) = stage8_k2_wacb_result_row( ...
    spec, trial, snr_row, music, constants);
diagnostic_structs(1) = stage8_k2_wacb_diagnostic_row( ...
    spec, trial, constants.method_ids(1), rules(1), fit, fit.common);
for index = 1:3
    result = fit.structured(index).combined;
    result.applicability_uses_registered_scenario_flag = ...
        rules(index + 1).uses_registered_scenario_flag;
    result_structs(index + 1) = stage8_k2_wacb_result_row( ...
        spec, trial, snr_row, result, constants);
    diagnostic_structs(index + 1) = stage8_k2_wacb_diagnostic_row( ...
        spec, trial, constants.method_ids(index + 1), ...
        rules(index + 1), fit, fit.common);
end
rows = struct2table(result_structs);
diagnostics = struct2table(diagnostic_structs);
if logical(spec.representative_spectrum_flag)
    representative = stage8_k2_wacb_representative_spectra( ...
        spec, rows, fit, resources, trial.model);
else
    representative = struct('included', false, ...
        'trial_id', string(spec.trial_id));
end
end

function value = failure_stage_local(result, stage)
if ~result.applicable
    value = "STRUCTURAL_NA";
elseif result.fit_valid
    value = "NONE";
else
    value = string(stage);
end
end
