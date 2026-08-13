function fixture = stage8_k2_snr_build_source_fixture(spec, context)
%STAGE8_K2_SNR_BUILD_SOURCE_FIXTURE Rebuild paired truth, phase, and source shape.

if ~(istable(spec) && height(spec) == 1)
    error('stage8_k2_snr_build_source_fixture:Spec', ...
        'spec must be one registered trial row.');
end
model = resolve_stage8_measurement_model( ...
    context.plan.measurement_model_registry, ...
    context.primary_measurement_config_id, spec.noise_profile_id);
truth = stage8_k2_snr_truth_from_spec(spec);
bounds = context.plan.local_domain.domain_bounds_deg;
if any(truth(:, 1) < bounds(1) | truth(:, 1) > bounds(2) | ...
        truth(:, 2) < bounds(3) | truth(:, 2) > bounds(4))
    error('stage8_k2_snr_build_source_fixture:TruthDomain', ...
        'Both K2 truth endpoints must remain inside the frozen domain.');
end
rng_state = rng;
rng_cleanup = onCleanup(@() rng(rng_state));
rng(spec.source_seed, 'twister');
source_phase_rad = 2 * pi * rand();
clear rng_cleanup
manifold = build_stage8_element_manifold(truth, model);
profile_token = spec.trial_id;
if ismember('paired_original_trial_id', spec.Properties.VariableNames)
    profile_token = spec.paired_original_trial_id;
end
[source_unscaled, source_info] = construct_deterministic_source_matrix( ...
    2, spec.L, spec.secondary_power_db, spec.correlation_magnitude, ...
    source_phase_rad, char(profile_token));
fixture = struct('model', model, 'truth_angles_deg', truth, ...
    'manifold', manifold, 'source_unscaled', source_unscaled, ...
    'source_phase_rad', source_phase_rad, 'source_info', source_info);
end
