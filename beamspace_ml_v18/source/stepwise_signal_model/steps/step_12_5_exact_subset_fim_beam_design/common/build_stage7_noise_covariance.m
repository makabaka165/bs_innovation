function noise = build_stage7_noise_covariance(noise_id, cfg, opts)
%BUILD_STAGE7_NOISE_COVARIANCE Build the registered element covariance.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'rho_el'), opts.rho_el = 0.45; end
if ~isfield(opts, 'rho_az'), opts.rho_az = 0.70; end
N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
switch char(noise_id)
    case 'WHITE'
        R_el = eye(N_el);
        R_az = eye(N_az);
        Rn = speye(N_el * N_az);
    case 'STAGE5_TOEPLITZ_CORRELATED'
        R_el = toeplitz(opts.rho_el .^ (0:N_el - 1));
        R_az = toeplitz(opts.rho_az .^ (0:N_az - 1));
        Rn = kron(R_az, R_el);
    otherwise
        error('build_stage7_noise_covariance:NoiseId', ...
            'Unknown noise covariance id: %s.', char(noise_id));
end
noise = struct();
noise.noise_id = char(noise_id);
noise.R_el = R_el;
noise.R_az = R_az;
noise.Rn = Rn;
noise.L_el = chol(R_el, 'lower');
noise.L_az = chol(R_az, 'lower');
noise.rho_el = opts.rho_el;
noise.rho_az = opts.rho_az;
noise.rank = N_el * N_az;
noise.hash = stage7_stable_hash(noise_id, R_el, R_az);
end
