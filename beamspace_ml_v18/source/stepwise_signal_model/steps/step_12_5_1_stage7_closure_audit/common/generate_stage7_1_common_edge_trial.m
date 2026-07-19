function trial = generate_stage7_1_common_edge_trial( ...
    plan_group_row, trial_index, stage7_context, opts)
%GENERATE_STAGE7_1_COMMON_EDGE_TRIAL Generate one method-invariant trial.

if nargin < 4 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
row = scalar_row_local(plan_group_row);
required = {'paired_group_id','paired_group_index','group_seed_start', ...
    'paired_trial_count','target1_az_deg','target1_el_deg', ...
    'target2_az_deg','target2_el_deg','L','secondary_power_db', ...
    'correlation_magnitude','correlation_phase_rad', ...
    'noise_covariance_id','element_snr_db', ...
    'historical_registered_domain_pass','tolerant_registered_domain_pass', ...
    'boundary_numeric_disagreement_flag','domain_tolerance_deg', ...
    'edge_diagnostic_domain_pass','mismatch_id'};
if ~all(isfield(row, required))
    error('generate_stage7_1_common_edge_trial:PlanSchema', ...
        'The edge plan group row is missing a frozen field.');
end
if ~(isnumeric(trial_index) && isscalar(trial_index) && ...
        isfinite(trial_index) && trial_index == fix(trial_index) && ...
        trial_index >= 1 && trial_index <= row.paired_trial_count)
    error('generate_stage7_1_common_edge_trial:TrialIndex', ...
        'trial_index must be inside the frozen paired trial block.');
end
targets_deg = [row.target1_az_deg,row.target1_el_deg; ...
    row.target2_az_deg,row.target2_el_deg];
domain = evaluate_stage7_1_tolerant_domain_check( ...
    targets_deg, [7.4,8.6;9.6,10.4], ...
    row.historical_registered_domain_pass);
if domain.tolerant_registered_domain_pass ~= ...
        logical(row.tolerant_registered_domain_pass) || ...
        domain.boundary_numeric_disagreement_flag ~= ...
        logical(row.boundary_numeric_disagreement_flag) || ...
        domain.domain_tolerance_deg ~= row.domain_tolerance_deg
    error('generate_stage7_1_common_edge_trial:DomainContract', ...
        'The plan domain metadata does not match the tolerant domain rule.');
end
if ~logical(row.edge_diagnostic_domain_pass) || ...
        ~domain.tolerant_registered_domain_pass
    error('generate_stage7_1_common_edge_trial:DomainGate', ...
        'The tolerant edge diagnostic domain gate rejected this group.');
end
trial_seed = row.group_seed_start + trial_index - 1;
rng(trial_seed, 'twister');
if isempty(opts.raw_trial_factory)
    raw = generate_raw_trial_local(row, targets_deg, stage7_context);
else
    raw = opts.raw_trial_factory(row, trial_index, trial_seed, stage7_context);
end
validate_raw_trial_local(raw, targets_deg);
realized_snr_db = 10 * log10(norm(raw.signal, 'fro') ^ 2 / ...
    max(norm(raw.noise, 'fro') ^ 2, realmin));

trial = raw;
trial.paired_group_id = string(row.paired_group_id);
trial.paired_group_index = row.paired_group_index;
trial.trial_index = trial_index;
trial.trial_seed = trial_seed;
trial.target_angles_deg = targets_deg;
trial.realized_element_snr_db = realized_snr_db;
trial.historical_registered_domain_pass = ...
    logical(row.historical_registered_domain_pass);
trial.tolerant_registered_domain_pass = ...
    logical(row.tolerant_registered_domain_pass);
trial.boundary_numeric_disagreement_flag = ...
    logical(row.boundary_numeric_disagreement_flag);
trial.domain_tolerance_deg = row.domain_tolerance_deg;
trial.edge_diagnostic_domain_pass = ...
    logical(row.edge_diagnostic_domain_pass);
trial.domain_gate_source = 'TOLERANT_REGISTERED_DOMAIN_PASS';
trial.common_trial_generation_count = 1;
trial.common_trial_generation_status = ...
    'GENERATED_ONCE_IN_ELEMENT_DOMAIN_BEFORE_METHOD_SUBSETS';
trial.method_invariant_realization_flag = true;
end

function raw = generate_raw_trial_local(row, targets_deg, finite)
if isfield(finite, 'finite'), finite = finite.finite; end
if ~(isstruct(finite) && isscalar(finite) && isfield(finite, 'context') && ...
        isfield(finite.context, 'plan') && isfield(finite.context, 'cfg'))
    error('generate_stage7_1_common_edge_trial:Context', ...
        'Formal generation requires the frozen Stage 7 finite context.');
end
pool_true = finite.context.plan.pool;
cfg = finite.context.cfg;
if string(row.mismatch_id) == "M2_POSITION"
    perturbation_scale = 0.02 * cfg.arr.lambda;
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
manifold = build_stage7_element_manifold(targets_deg, pool_true, cfg);
if string(row.mismatch_id) == "STAGE5_COHERENT_WEAK"
    base = [1, exp(0.2j), 0.9 * exp(-0.4j), 1.1 * exp(0.6j)];
    source_matrix = [base;0.12 * exp(0.4j) * base];
    noise_scale = row.noise_sigma_override;
else
    [source_matrix, ~] = construct_deterministic_source_matrix( ...
        2, row.L, row.secondary_power_db, row.correlation_magnitude, ...
        row.correlation_phase_rad, row.source_profile_id);
    unscaled = manifold.A * source_matrix;
    target_energy = 10 ^ (row.element_snr_db / 10) * numel(unscaled);
    source_matrix = source_matrix * sqrt( ...
        target_energy / norm(unscaled, 'fro') ^ 2);
    noise_scale = 1;
end
signal = manifold.A * source_matrix;
if string(row.mismatch_id) == "M0_COVARIANCE"
    noise_model = build_stage7_noise_covariance( ...
        'STAGE5_TOEPLITZ_CORRELATED', cfg, ...
        struct('rho_el', 0.55, 'rho_az', 0.80));
else
    noise_model = build_stage7_noise_covariance( ...
        row.noise_covariance_id, cfg);
end
noise = matrix_normal_noise_local(noise_model, row.L, noise_scale);
Y_element = signal + noise;
if string(row.mismatch_id) == "M1_GAIN_PHASE"
    gain_db = 0.5 * randn(size(Y_element, 1), 1);
    phase_rad = deg2rad(5) * randn(size(Y_element, 1), 1);
    calibration = 10 .^ (gain_db / 20) .* exp(1j * phase_rad);
    Y_element = calibration .* Y_element;
elseif string(row.mismatch_id) == "M3_CHANNEL_FAILURE"
    failure = rand(size(Y_element, 1), 1) < 0.02;
    Y_element(failure, :) = 0;
end
raw = struct('Y_element', Y_element, 'signal', signal, ...
    'noise', noise, 'source_matrix', source_matrix, ...
    'noise_covariance_id', string(row.noise_covariance_id), ...
    'mismatch_id', string(row.mismatch_id));
end

function noise = matrix_normal_noise_local(model, L, scale)
N_el = size(model.R_el, 1);
N_az = size(model.R_az, 1);
noise = complex(zeros(N_el * N_az, L));
for index = 1:L
    E = complex(randn(N_el, N_az), randn(N_el, N_az)) / sqrt(2);
    page = scale * model.L_el * E * model.L_az';
    noise(:, index) = page(:);
end
end

function validate_raw_trial_local(raw, targets_deg)
required = {'Y_element','signal','noise','source_matrix'};
if ~(isstruct(raw) && isscalar(raw) && all(isfield(raw, required)) && ...
        isnumeric(raw.Y_element) && isnumeric(raw.signal) && ...
        isnumeric(raw.noise) && isequal(size(raw.Y_element), size(raw.signal)) && ...
        isequal(size(raw.Y_element), size(raw.noise)) && ...
        size(raw.source_matrix, 1) == size(targets_deg, 1))
    error('generate_stage7_1_common_edge_trial:RawTrial', ...
        'The raw trial factory returned an invalid element-domain trial.');
end
end

function row = scalar_row_local(value)
if istable(value) && height(value) == 1
    row = table2struct(value);
elseif isstruct(value) && isscalar(value)
    row = value;
else
    error('generate_stage7_1_common_edge_trial:PlanRow', ...
        'plan_group_row must be one table row or scalar struct.');
end
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('generate_stage7_1_common_edge_trial:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'unit_test_mode','raw_trial_factory'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('generate_stage7_1_common_edge_trial:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'unit_test_mode'), opts.unit_test_mode = false; end
if ~isfield(opts, 'raw_trial_factory'), opts.raw_trial_factory = []; end
if ~(islogical(opts.unit_test_mode) && isscalar(opts.unit_test_mode))
    error('generate_stage7_1_common_edge_trial:OptionValue', ...
        'unit_test_mode must be a logical scalar.');
end
if ~isempty(opts.raw_trial_factory) && ...
        (~opts.unit_test_mode || ~isa(opts.raw_trial_factory, 'function_handle'))
    error('generate_stage7_1_common_edge_trial:TrialFactory', ...
        'A raw trial factory is restricted to explicit unit-test mode.');
end
end
