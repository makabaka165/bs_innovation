function bundle = stage8_k2_mc_build_measurement_model( ...
    spec, center, noise_profile_id)
%STAGE8_K2_MC_BUILD_MEASUREMENT_MODEL Rebuild one production center model.

noise_profile_id = char(string(noise_profile_id));
[pool, cfg] = stage8_k2_mc_build_rotated_candidate_pool(spec, center);
family = enumerate_stage7_rectangular_subsets(pool, cfg);
noise = build_stage7_noise_covariance(noise_profile_id, cfg, ...
    struct('rho_el',0.45, 'rho_az',0.70));
[raw_model, raw_debug] = build_stage8_measurement_model( ...
    spec.measurement_config_id, noise_profile_id, cfg, struct( ...
    'pool',pool, 'subset_family',family, 'noise',noise));
reference_model = reference_model_local(spec, noise_profile_id);

W_error = relative_error_local(raw_model.Wseq, reference_model.Wseq);
C_error = relative_error_local(raw_model.Cseq, reference_model.Cseq);
raw_T_error = relative_error_local(raw_model.Tseq, reference_model.Tseq);
if W_error > 1e-11
    error('stage8_k2_mc_build_measurement_model:WEquivalence', ...
        'BLOCKED_W_EQUIVALENCE_FAILED (%.17g).', W_error);
end
if C_error > 1e-11
    error('stage8_k2_mc_build_measurement_model:CEquivalence', ...
        'BLOCKED_C_EQUIVALENCE_FAILED (%.17g).', C_error);
end

% The independently rebuilt triplet proves the physical rotation. Its
% remaining differences are only absolute-angle evaluation roundoff. Use
% the reference class's certified numerical coordinate for W/C/T so the
% online model has Q_c = I and exact shared-column semantics.
canonical_W = reference_model.Wseq;
canonical_C = reference_model.Cseq;
canonical_T = reference_model.Tseq;
physical_C = canonical_W' * noise.Rn * canonical_W;
physical_C = 0.5 * (physical_C + physical_C');
canonical_covariance_error = relative_error_local(physical_C, canonical_C);
identity_now = eye(size(canonical_T, 1), 'like', canonical_T);
canonical_whitening_error = norm( ...
    canonical_T * canonical_C * canonical_T' - identity_now, 'fro') / ...
    max(norm(identity_now, 'fro'), realmin);
reference_whitening_error = norm( ...
    reference_model.Tseq * reference_model.Cseq * ...
    reference_model.Tseq' - identity_now, 'fro') / ...
    max(norm(identity_now, 'fro'), realmin);
whitening_residual_delta = abs( ...
    canonical_whitening_error - reference_whitening_error);
if canonical_covariance_error > 1e-11 || ...
        whitening_residual_delta > 64 * eps(max(1, reference_whitening_error))
    error('stage8_k2_mc_build_measurement_model:TEquivalence', ...
        ['BLOCKED_T_EQUIVALENCE_FAILED (covariance %.17g, ', ...
        'whitening delta %.17g).'], canonical_covariance_error, ...
        whitening_residual_delta);
end
model = raw_model;
model.Wseq = canonical_W;
model.W_I = canonical_W;
model.Cseq = canonical_C;
model.C_I = canonical_C;
model.Tseq = canonical_T;
model.T_I = canonical_T;
model.stage7_parent_pool_hash = pool.W0_hash;
model.factorized_sequential.parent_W0_hash = pool.W0_hash;
model.subset_model_hash = stage7_stable_hash(model.channels, ...
    model.Cseq, model.Tseq, noise.hash);
model.fixed_measurement_hash = stage8_stable_hash( ...
    'STAGE8_FIXED_MEASUREMENT_V1', spec.measurement_config_id, ...
    model.subset_id, noise_profile_id, model.channels, model.W_I, ...
    model.C_I, model.T_I, pool.W0_hash);
model.actual_center_column = center.center_column;
model.actual_physical_center_az_deg = center.physical_center_az_deg;
model.actual_physical_center_unwrapped_az_deg = ...
    center.physical_center_unwrapped_az_deg;
model.requested_center_az_deg = center.requested_center_az_deg;
model.rotation_delta_deg = center.rotation_delta_deg;
model.reference_requested_center_az_deg = ...
    spec.reference_requested_center_az_deg;
model.reference_physical_center_az_deg = ...
    spec.reference_physical_center_az_deg;
model.reference_center_column = spec.reference_center_column;
model.whitening_coordinate_contract = ...
    'ROTATION_CLASS_CANONICAL_REFERENCE_PSD_COORDINATE_QC_IDENTITY';
model.canonical_whitener_hash = stage8_stable_hash(canonical_T);
model.independent_rebuilt_whitener_hash = ...
    stage8_stable_hash(raw_model.Tseq);

stage5_locked = stage8_k2_mc_build_rotated_stage5_config(spec, center);
domain = stage8_k2_mc_build_local_domain(spec, center, stage5_locked);
identity = stage8_k2_mc_build_rotation_class_identity( ...
    spec, center, pool, domain, stage5_locked, model);
model.rotation_class_hash = identity.rotation_class_hash;
model.actual_center_hash = identity.actual_center_hash;
model.stage5_rotation_class_hash = ...
    stage5_locked.stage5_rotation_class_hash;
model.stage5_actual_center_hash = stage5_locked.stage5_actual_center_hash;
model.absolute_domain_hash = domain.domain_hash;
model.absolute_beam_layout_hash = identity.absolute_beam_layout_hash;
model.absolute_active_geometry_hash = identity.absolute_active_geometry_hash;

debug = raw_debug;
debug.fixed_measurement_hash = model.fixed_measurement_hash;
debug.independent_rebuilt_Tseq = raw_model.Tseq;
debug.independent_rebuilt_fixed_measurement_hash = ...
    raw_model.fixed_measurement_hash;
debug.independent_W_relative_error = W_error;
debug.independent_C_relative_error = C_error;
debug.independent_T_basis_relative_error = raw_T_error;
debug.W_relative_error = relative_error_local(model.Wseq, ...
    reference_model.Wseq);
debug.C_relative_error = relative_error_local(model.Cseq, ...
    reference_model.Cseq);
debug.T_relative_error = relative_error_local(model.Tseq, ...
    reference_model.Tseq);
debug.canonical_covariance_error = canonical_covariance_error;
debug.canonical_whitening_error = canonical_whitening_error;
debug.reference_whitening_error = reference_whitening_error;
debug.whitening_residual_delta = whitening_residual_delta;
debug.canonical_rotation_class_coordinate_selected = true;
debug.rotation_class_hash = identity.rotation_class_hash;
debug.actual_center_hash = identity.actual_center_hash;

bundle = struct( ...
    'schema_version','STAGE8_K2_MC_PRODUCTION_BUNDLE_V1', ...
    'center',center, 'noise_profile_id',noise_profile_id, ...
    'cfg',cfg, 'pool',pool, 'subset_family',family, 'noise',noise, ...
    'model',model, 'raw_rebuilt_model',raw_model, ...
    'stage5_locked',stage5_locked, 'local_domain',domain, ...
    'identity',identity, 'debug',debug);
bundle.bundle_hash = stage8_stable_hash( ...
    'STAGE8_K2_MC_PRODUCTION_BUNDLE_V1', ...
    identity.rotation_class_hash, identity.actual_center_hash, ...
    model.fixed_measurement_hash, domain.domain_hash, ...
    stage5_locked.configuration_hash);
end

function model = reference_model_local(spec, noise_profile_id)
ids = string({spec.reference_models.noise_profile_id});
index = find(ids == string(noise_profile_id), 1);
if isempty(index)
    error('stage8_k2_mc_build_measurement_model:NoiseProfile', ...
        'The noise profile is not in the frozen formal scope.');
end
model = spec.reference_models(index);
end

function value = relative_error_local(actual, reference)
value = norm(actual - reference, 'fro') / ...
    max(norm(reference, 'fro'), realmin);
end
