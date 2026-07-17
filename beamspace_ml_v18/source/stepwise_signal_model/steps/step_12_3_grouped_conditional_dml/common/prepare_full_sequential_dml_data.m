function [data, model, debug] = prepare_full_sequential_dml_data( ...
    Yelem, Wseq, Rn_elem, opts)
%PREPARE_FULL_SEQUENTIAL_DML_DATA Fix the original sequential likelihood data.

if nargin < 4 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
[Y, input_form] = canonical_data_local(Yelem, size(Wseq, 1));
validate_inputs_local(Y, Wseq, Rn_elem, opts);

Zseq_raw = Wseq' * Y;
Cseq = Wseq' * Rn_elem * Wseq;
[Tseq, whitening_info] = build_psd_whitener(Cseq, ...
    struct('rank_multiplier', opts.rank_multiplier));
Zseq_white = Tseq * Zseq_raw;
fixed_hash = stable_object_hash(Wseq, Cseq, Tseq, ...
    opts.array_meta.XAct, opts.array_meta.YAct, opts.array_meta.ZAct, ...
    opts.lambda, opts.element_order);

data = struct();
data.Zseq_raw = Zseq_raw;
data.Zseq_white = Zseq_white;
data.temporal_snapshot_count = size(Y, 2);
data.original_element_data_used_flag = true;
data.observation_source = 'original_factor1_element_snapshots';
data.statistical_calibration_status = 'NOT_CALIBRATED_STAGE5';
data.phase_factor = 1;
data.fixed_measurement_hash = fixed_hash;

model = struct();
model.Wseq = Wseq;
model.Cseq = Cseq;
model.Tseq = Tseq;
model.array_meta = opts.array_meta;
model.lambda = opts.lambda;
model.phase_factor = 1;
model.element_order = opts.element_order;
model.fixed_measurement_hash = fixed_hash;

debug = whitening_info;
debug.Cseq = Cseq;
debug.input_form = input_form;
debug.sequential_output_size = size(Zseq_raw);
debug.whitening_rank = whitening_info.rank;
debug.num_eig = 1;
debug.fixed_measurement_hash = fixed_hash;
debug.candidate_independent_flag = true;
debug.phase_factor = 1;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('prepare_full_sequential_dml_data:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'array_meta', 'lambda', 'element_order', ...
    'rank_multiplier', 'phase_factor'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('prepare_full_sequential_dml_data:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
required = {'array_meta', 'lambda'};
missing = required(~isfield(opts, required));
if ~isempty(missing)
    error('prepare_full_sequential_dml_data:MissingOption', ...
        'Missing required option: %s.', missing{1});
end
if ~isfield(opts, 'element_order')
    opts.element_order = 'elevation_fastest_azimuth_slowest';
end
if ~isfield(opts, 'rank_multiplier')
    opts.rank_multiplier = 1;
end
if ~isfield(opts, 'phase_factor')
    opts.phase_factor = 1;
end
if opts.phase_factor ~= 1
    error('prepare_full_sequential_dml_data:PhaseFactor', ...
        'The active full sequential data path requires phase_factor=1.');
end
end

function [Y, form] = canonical_data_local(Yelem, N_elem)
if ~(isnumeric(Yelem) && ~isempty(Yelem) && all(isfinite(Yelem(:))))
    error('prepare_full_sequential_dml_data:ElementData', ...
        'Yelem must be finite and non-empty.');
end
if ismatrix(Yelem) && size(Yelem, 1) == N_elem
    Y = Yelem;
    form = 'canonical_Nelem_by_L';
    return;
end
sz = size(Yelem);
if numel(Yelem) < N_elem || mod(numel(Yelem), N_elem) ~= 0
    error('prepare_full_sequential_dml_data:ElementShape', ...
        'Yelem cannot be reshaped to canonical N_elem-by-L form.');
end
Y = reshape(Yelem, N_elem, []);
form = sprintf('tensor_%s', strjoin(string(sz), 'x'));
end

function validate_inputs_local(Y, W, R, opts)
N = size(Y, 1);
if ~(isnumeric(W) && ismatrix(W) && size(W, 1) == N && ...
        ~isempty(W) && all(isfinite(W(:))))
    error('prepare_full_sequential_dml_data:BeamMatrix', ...
        'Wseq must be finite with one row per canonical array element.');
end
if ~(isnumeric(R) && ismatrix(R) && isequal(size(R), [N, N]) && ...
        all(isfinite(R(:))))
    error('prepare_full_sequential_dml_data:Covariance', ...
        'Rn_elem must be a finite N_elem-by-N_elem covariance.');
end
validateattributes(opts.lambda, {'numeric'}, ...
    {'real','finite','positive','scalar'});
required = {'XAct','YAct','ZAct'};
if ~(isstruct(opts.array_meta) && all(isfield(opts.array_meta, required)))
    error('prepare_full_sequential_dml_data:ArrayMeta', ...
        'opts.array_meta must contain XAct, YAct, and ZAct.');
end
end
