function [model, debug] = build_stage6_fixed_measurement_model(config, cfg, opts)
%BUILD_STAGE6_FIXED_MEASUREMENT_MODEL Build one candidate-independent model.

if nargin < 3 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_config_local(config);
if cfg.beam.spatialPhaseFactor ~= 1
    error('build_stage6_fixed_measurement_model:PhaseFactor', ...
        'Stage 6 requires the receive-only phase_factor=1 model.');
end

array_meta = arr_cyl(cfg, cfg.beam.azSectorCenter);
N_el = cfg.arr.Nel;
N_az = cfg.beam.subNaz;
[~, V] = form_elevation_dbf_cube(complex(zeros(N_el, N_az)), ...
    config.el_beam_deg, cfg);
[~, Uset] = form_azimuth_dbf_cube( ...
    complex(zeros(numel(config.el_beam_deg), N_az)), ...
    config.az_beam_deg, config.el_beam_deg, cfg);
[Wseq, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta);

[Rn_elem, covariance_meta] = covariance_local( ...
    config.noise_covariance_id, N_el, N_az, config);
Cseq = Wseq' * Rn_elem * Wseq;
[Tseq, whitening_info] = build_psd_whitener(Cseq, struct( ...
    'rank_multiplier', opts.rank_multiplier, ...
    'psd_tolerance_multiplier', opts.rank_multiplier));

array_geometry_hash = stable_stage6_hash(array_meta.XAct, ...
    array_meta.YAct, array_meta.ZAct, cfg.arr.lambda, ...
    beam_meta.element_vector_order);
Wseq_hash = stable_stage6_hash(Wseq);
Cseq_hash = stable_stage6_hash(Cseq);
Tseq_hash = stable_stage6_hash(Tseq);
beam_indices = struct('azimuth', config.az_beam_indices, ...
    'elevation', config.el_beam_indices);
fixed_measurement_hash = stable_stage6_hash(config.config_id, ...
    Wseq_hash, Cseq_hash, Tseq_hash, array_geometry_hash, beam_indices, ...
    config.noise_covariance_id, covariance_meta, opts.stage6_controls_hash, ...
    opts.stage6_measurement_plan_hash, cfg.arr.lambda, 1);

model = struct();
model.config_id = config.config_id;
model.Wseq = Wseq;
model.Cseq = Cseq;
model.Tseq = Tseq;
model.whitening_rank = whitening_info.rank;
model.array_meta = array_meta;
model.lambda = cfg.arr.lambda;
model.phase_factor = 1;
model.az_beam_deg = config.az_beam_deg;
model.el_beam_deg = config.el_beam_deg;
model.beam_indices = beam_indices;
model.noise_covariance_id = config.noise_covariance_id;
model.noise_covariance_parameters = covariance_meta;
model.Rn_elem = Rn_elem;
model.Wseq_hash = Wseq_hash;
model.Cseq_hash = Cseq_hash;
model.Tseq_hash = Tseq_hash;
model.array_geometry_hash = array_geometry_hash;
model.fixed_measurement_hash = fixed_measurement_hash;
model.stage6_controls_hash = opts.stage6_controls_hash;
model.stage6_measurement_plan_hash = opts.stage6_measurement_plan_hash;
model.stage6_experiment_plan_hash = opts.stage6_experiment_plan_hash;
model.element_order = beam_meta.element_vector_order;
model.beam_meta = beam_meta;
model.is_primary_configuration = config.is_primary_configuration;

debug = whitening_info;
debug.whitening_rank = whitening_info.rank;
debug.Wseq_size = size(Wseq);
debug.Cseq_size = size(Cseq);
debug.Tseq_size = size(Tseq);
debug.whitening_identity_error = whitening_info.whitening_error;
debug.fixed_objects_candidate_independent_flag = true;
debug.fixed_measurement_hash = fixed_measurement_hash;
debug.phase_factor = 1;
end

function opts = normalize_options_local(opts)
required = {'stage6_controls_hash','stage6_measurement_plan_hash', ...
    'stage6_experiment_plan_hash'};
if ~(isstruct(opts) && isscalar(opts) && all(isfield(opts, required)))
    error('build_stage6_fixed_measurement_model:Options', ...
        'opts must contain all registered stage-6 hashes.');
end
allowed = [required, {'rank_multiplier'}];
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_stage6_fixed_measurement_model:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
end

function validate_config_local(config)
required = {'config_id','az_beam_deg','el_beam_deg', ...
    'az_beam_indices','el_beam_indices','noise_covariance_id', ...
    'is_primary_configuration'};
if ~(isstruct(config) && isscalar(config) && all(isfield(config, required)))
    error('build_stage6_fixed_measurement_model:Config', ...
        'config is missing a registered measurement field.');
end
if isempty(config.az_beam_deg) || isempty(config.el_beam_deg) || ...
        numel(config.az_beam_deg) ~= numel(config.az_beam_indices) || ...
        numel(config.el_beam_deg) ~= numel(config.el_beam_indices)
    error('build_stage6_fixed_measurement_model:BeamConfig', ...
        'Beam centers and registered indices must be non-empty and aligned.');
end
end

function [R, meta] = covariance_local(kind, N_el, N_az, config)
switch char(kind)
    case 'IDENTITY'
        R = speye(N_el * N_az);
        meta = struct('kind', 'IDENTITY', 'rho_el', 0, 'rho_az', 0);
    case 'STAGE5_TOEPLITZ_CORRELATED'
        R_el = toeplitz(config.rho_el .^ (0:N_el - 1));
        R_az = toeplitz(config.rho_az .^ (0:N_az - 1));
        R = kron(R_az, R_el);
        meta = struct('kind', 'STAGE5_TOEPLITZ_CORRELATED', ...
            'rho_el', config.rho_el, 'rho_az', config.rho_az);
    otherwise
        error('build_stage6_fixed_measurement_model:Covariance', ...
            'Unknown covariance id: %s.', char(kind));
end
end
