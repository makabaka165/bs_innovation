function [model, debug] = build_stage8_measurement_model( ...
    measurement_config_id, noise_profile_id, cfg, opts)
%BUILD_STAGE8_MEASUREMENT_MODEL Reconstruct a frozen Stage7 physical subset.

if nargin < 4 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
if cfg.beam.spatialPhaseFactor ~= 1
    error('build_stage8_measurement_model:PhaseFactor', ...
        'Stage8 requires the active receive phase_factor=1 model.');
end
if isempty(opts.pool)
    pool = build_stage7_candidate_pool(cfg);
else
    pool = opts.pool;
end
if isempty(opts.subset_family)
    family = enumerate_stage7_rectangular_subsets(pool, cfg);
else
    family = opts.subset_family;
end
[subset_id, role] = registered_subset_local(measurement_config_id);
row = family(family.subset_id == string(subset_id), :);
if height(row) ~= 1
    error('build_stage8_measurement_model:Subset', ...
        'The registered Stage7 subset %s must occur exactly once.', subset_id);
end
channels = sscanf(char(row.sequential_channel_ids), '%d;').';
if isempty(opts.noise)
    noise = build_stage7_noise_covariance(noise_profile_id, cfg, ...
        struct('rho_el', 0.45, 'rho_az', 0.70));
else
    noise = opts.noise;
end
subset = build_exact_subset_model(pool, channels, noise, ...
    struct('rank_multiplier', 1, 'compute_hash', true));
fixed_hash = stage8_stable_hash('STAGE8_FIXED_MEASUREMENT_V1', ...
    measurement_config_id, subset_id, noise_profile_id, channels, ...
    subset.W_I, subset.C_I, subset.T_I, pool.W0_hash);
model = struct('measurement_config_id', char(measurement_config_id), ...
    'measurement_role', role, 'subset_id', subset_id, ...
    'channels', channels, 'Wseq', subset.W_I, 'W_I', subset.W_I, ...
    'Cseq', subset.C_I, 'C_I', subset.C_I, ...
    'Tseq', subset.T_I, 'T_I', subset.T_I, ...
    'whitening_rank', subset.rank_C_I, 'array_meta', pool.array_meta, ...
    'lambda', cfg.arr.lambda, 'phase_factor', 1, ...
    'element_order', pool.beam_meta.element_vector_order, ...
    'noise_profile_id', char(noise_profile_id), ...
    'fixed_measurement_hash', fixed_hash, ...
    'stage7_parent_pool_hash', pool.W0_hash, ...
    'subset_model_hash', subset.subset_model_hash);
debug = struct('B_el', row.B_e, 'B_az', row.B_a, ...
    'B_out', row.B_out, 'rank_C_I', subset.rank_C_I, ...
    'whitening_error', subset.whitening_info.whitening_error, ...
    'covariance_selection_error', subset.covariance_selection_error, ...
    'fixed_measurement_hash', fixed_hash, ...
    'candidate_independent_flag', true, 'phase_factor', 1);
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_stage8_measurement_model:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'pool','subset_family','noise'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_stage8_measurement_model:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
for name = allowed
    if ~isfield(opts, name{1})
        opts.(name{1}) = [];
    end
end
end

function [subset_id, role] = registered_subset_local(config_id)
switch char(config_id)
    case 'PRIMARY_RECT_E14_A31'
        subset_id = 'RECT_E14_A31';
        role = 'PRIMARY';
    case 'SENSITIVITY_FULL_PARENT_5X5'
        subset_id = 'RECT_E31_A31';
        role = 'SENSITIVITY_ONLY';
    otherwise
        error('build_stage8_measurement_model:Configuration', ...
            'Unknown Stage8 measurement configuration: %s.', char(config_id));
end
end
