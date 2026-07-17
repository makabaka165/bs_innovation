function [data, model, debug] = prepare_conditional_azimuth_data( ...
    Xphi_q, Uq, Rphi_selected, alpha_q, opts)
%PREPARE_CONDITIONAL_AZIMUTH_DATA Fix and whiten a recovered group view.

if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
validate_inputs_local(Xphi_q, Uq, Rphi_selected, alpha_q);

data = base_data_local(Xphi_q, opts);
model = base_model_local(Uq, opts);
if ~(opts.estimate_returned_flag && opts.structural_gate_pass_flag)
    data.Zphi_raw = complex(zeros(0, size(Xphi_q, 2), 'like', Xphi_q));
    data.Zphi_white = data.Zphi_raw;
    data.preparation_status = 'UPSTREAM_GROUP_STAGE_UNCERTIFIED';
    model.Tphi_q = complex(zeros(0, size(Uq, 2), 'like', Uq));
    model.fixed_measurement_hash = stable_object_hash( ...
        Uq, model.Tphi_q, opts.eta_condition_deg, ...
        opts.array_coordinates, opts.lambda, opts.beam_bank_hash);
    debug = struct('status', data.preparation_status, ...
        'whitening_error', NaN, 'whitening_rank', 0, ...
        'num_eig', 0, 'candidate_independent_flag', true, ...
        'phase_factor', 1);
    return;
end

Zphi_raw = Uq' * Xphi_q;
Cphi_beam_q = alpha_q * (Uq' * Rphi_selected * Uq);
[Tphi_q, whitening_info] = build_psd_whitener(Cphi_beam_q, ...
    struct('rank_multiplier', opts.rank_multiplier));
Zphi_white = Tphi_q * Zphi_raw;
fixed_hash = stable_object_hash(Uq, Tphi_q, opts.eta_condition_deg, ...
    opts.array_coordinates, opts.lambda, opts.beam_bank_hash);

data.Zphi_raw = Zphi_raw;
data.Zphi_white = Zphi_white;
data.preparation_status = 'CONDITIONAL_AZIMUTH_DATA_PREPARED';
data.whitening_rank = whitening_info.rank;
model.Tphi_q = Tphi_q;
model.fixed_measurement_hash = fixed_hash;

debug = whitening_info;
debug.status = data.preparation_status;
debug.Cphi_beam_q = Cphi_beam_q;
debug.whitening_rank = whitening_info.rank;
debug.num_eig = 1;
debug.alpha_q = alpha_q;
debug.candidate_independent_flag = true;
debug.phase_factor = 1;
end

function data = base_data_local(Xphi_q, opts)
data = struct();
data.Zphi_white = [];
data.Zphi_raw = [];
data.temporal_snapshot_count = size(Xphi_q, 2);
data.eta_condition_deg = opts.eta_condition_deg;
data.condition_source = opts.condition_source;
data.upstream_group_support_status = opts.upstream_group_support_status;
data.upstream_estimate_returned_flag = opts.estimate_returned_flag;
data.upstream_structural_gate_pass_flag = opts.structural_gate_pass_flag;
data.statistical_calibration_status = 'NOT_CALIBRATED_STAGE5';
data.phase_factor = 1;
end

function model = base_model_local(Uq, opts)
model = struct();
model.Uq = Uq;
model.Tphi_q = [];
model.array_coordinates = opts.array_coordinates;
model.lambda = opts.lambda;
model.eta_condition_deg = opts.eta_condition_deg;
model.phase_factor = 1;
model.beam_bank_hash = opts.beam_bank_hash;
model.fixed_measurement_hash = '';
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('prepare_conditional_azimuth_data:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'eta_condition_deg', 'condition_source', ...
    'upstream_group_support_status', 'estimate_returned_flag', ...
    'structural_gate_pass_flag', 'array_coordinates', 'lambda', ...
    'beam_bank_hash', 'rank_multiplier', 'phase_factor'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('prepare_conditional_azimuth_data:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
required = {'eta_condition_deg', 'condition_source', ...
    'upstream_group_support_status', 'estimate_returned_flag', ...
    'structural_gate_pass_flag', 'array_coordinates', 'lambda'};
missing = required(~isfield(opts, required));
if ~isempty(missing)
    error('prepare_conditional_azimuth_data:MissingOption', ...
        'Missing required option: %s.', missing{1});
end
if ~isfield(opts, 'beam_bank_hash')
    opts.beam_bank_hash = 'UNREGISTERED_BEAM_BANK_HASH';
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'phase_factor')
    opts.phase_factor = 1;
end
if opts.phase_factor ~= 1
    error('prepare_conditional_azimuth_data:PhaseFactor', ...
        'The active conditional data path requires phase_factor=1.');
end
validateattributes(opts.eta_condition_deg, {'numeric'}, ...
    {'real','finite','scalar'});
validateattributes(opts.lambda, {'numeric'}, ...
    {'real','finite','positive','scalar'});
if ~(islogical(opts.estimate_returned_flag) && isscalar(opts.estimate_returned_flag) && ...
        islogical(opts.structural_gate_pass_flag) && isscalar(opts.structural_gate_pass_flag))
    error('prepare_conditional_azimuth_data:UpstreamFlags', ...
        'The two upstream gate flags must be logical scalars.');
end
end

function validate_inputs_local(X, U, R, alpha)
if ~(isnumeric(X) && ismatrix(X) && ~isempty(X) && all(isfinite(X(:))))
    error('prepare_conditional_azimuth_data:GroupData', ...
        'Xphi_q must be a finite non-empty Nphi-by-L matrix.');
end
if ~(isnumeric(U) && ismatrix(U) && size(U, 1) == size(X, 1) && ...
        ~isempty(U) && all(isfinite(U(:))))
    error('prepare_conditional_azimuth_data:BeamBank', ...
        'Uq must be finite and have the same row count as Xphi_q.');
end
if ~(isnumeric(R) && ismatrix(R) && ...
        isequal(size(R), [size(X, 1), size(X, 1)]) && all(isfinite(R(:))))
    error('prepare_conditional_azimuth_data:Covariance', ...
        'Rphi_selected must be a finite Nphi-by-Nphi covariance.');
end
if ~(isscalar(alpha) && isreal(alpha) && isfinite(alpha) && alpha > 0)
    error('prepare_conditional_azimuth_data:NoiseScale', ...
        'alpha_q must be a positive finite real scalar.');
end
end
