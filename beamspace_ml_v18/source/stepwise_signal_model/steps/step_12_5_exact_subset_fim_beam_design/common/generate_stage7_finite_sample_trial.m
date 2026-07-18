function trial = generate_stage7_finite_sample_trial(plan_row, finite, trial_index)
%GENERATE_STAGE7_FINITE_SAMPLE_TRIAL Generate one common element-domain trial.

seed = plan_row.seed + trial_index - 1;
rng(seed, 'twister');
direction = [cosd(plan_row.direction_angle_deg), ...
    sind(plan_row.direction_angle_deg)];
center = [plan_row.center_az_deg, plan_row.center_el_deg];
targets = [center - plan_row.separation_deg * direction / 2; ...
    center + plan_row.separation_deg * direction / 2];
pool_true = finite.context.plan.pool;
if plan_row.mismatch_id == "M2_POSITION"
    perturbation_scale = 0.02 * finite.context.cfg.arr.lambda;
    pool_true.array_meta.XAct = pool_true.array_meta.XAct + ...
        perturbation_scale * randn(size(pool_true.array_meta.XAct));
    pool_true.array_meta.YAct = pool_true.array_meta.YAct + ...
        perturbation_scale * randn(size(pool_true.array_meta.YAct));
    pool_true.array_meta.ZAct = pool_true.array_meta.ZAct + ...
        perturbation_scale * randn(size(pool_true.array_meta.ZAct));
    pool_true.array_meta.xActVec = pool_true.array_meta.XAct(:);
    pool_true.array_meta.yActVec = pool_true.array_meta.YAct(:);
    pool_true.array_meta.zActVec = pool_true.array_meta.ZAct(:);
end
manifold = build_stage7_element_manifold(targets, pool_true, finite.context.cfg);
if plan_row.mismatch_id == "STAGE5_COHERENT_WEAK"
    base = [1, exp(0.2j), 0.9 * exp(-0.4j), 1.1 * exp(0.6j)];
    S = [base;0.12 * exp(0.4j) * base];
    noise_scale = plan_row.noise_sigma_override;
else
    [S, ~] = construct_deterministic_source_matrix(2, plan_row.L, ...
        plan_row.secondary_power_db, plan_row.correlation_magnitude, ...
        plan_row.correlation_phase_rad, plan_row.scenario_id);
    signal_unscaled = manifold.A * S;
    target_energy = 10 ^ (plan_row.element_snr_db / 10) * ...
        size(signal_unscaled, 1) * size(signal_unscaled, 2);
    S = S * sqrt(target_energy / norm(signal_unscaled, 'fro') ^ 2);
    noise_scale = 1;
end
signal = manifold.A * S;

if plan_row.mismatch_id == "M0_COVARIANCE"
    true_noise = build_stage7_noise_covariance( ...
        'STAGE5_TOEPLITZ_CORRELATED', finite.context.cfg, ...
        struct('rho_el', 0.55, 'rho_az', 0.80));
else
    true_noise = build_stage7_noise_covariance( ...
        plan_row.noise_covariance_id, finite.context.cfg);
end
noise = matrix_normal_noise_local(true_noise, plan_row.L, noise_scale);
Y = signal + noise;
if plan_row.mismatch_id == "M1_GAIN_PHASE"
    gain_db = 0.5 * randn(size(Y, 1), 1);
    phase_rad = deg2rad(5) * randn(size(Y, 1), 1);
    calibration = 10 .^ (gain_db / 20) .* exp(1j * phase_rad);
    Y = calibration .* Y;
elseif plan_row.mismatch_id == "M3_CHANNEL_FAILURE"
    failure = rand(size(Y, 1), 1) < 0.02;
    Y(failure, :) = 0;
end
signal_snr_db = 10 * log10(norm(signal, 'fro') ^ 2 / ...
    max(norm(noise, 'fro') ^ 2, realmin));
trial = struct('Y_element', Y, 'target_angles_deg', targets, ...
    'source_matrix', S, 'seed', seed, ...
    'realized_element_snr_db', signal_snr_db, ...
    'registered_domain_pass', all(targets(:, 1) >= 7.4 & ...
    targets(:, 1) <= 8.6 & targets(:, 2) >= 9.6 & targets(:, 2) <= 10.4));
end

function noise = matrix_normal_noise_local(model, L, scale)
N_el = size(model.R_el, 1);
N_az = size(model.R_az, 1);
noise = complex(zeros(N_el * N_az, L));
for snapshot_index = 1:L
    E = complex(randn(N_el, N_az), randn(N_el, N_az)) / sqrt(2);
    page = scale * model.L_el * E * model.L_az';
    noise(:, snapshot_index) = page(:);
end
end
