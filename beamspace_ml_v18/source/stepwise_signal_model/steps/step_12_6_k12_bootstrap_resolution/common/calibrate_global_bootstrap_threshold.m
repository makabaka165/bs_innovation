function [artifact, debug] = calibrate_global_bootstrap_threshold( ...
    calibration_cells, local_domain, model, opts)
%CALIBRATE_GLOBAL_BOOTSTRAP_THRESHOLD Refit K1/K2 and take max cell quantile.

if nargin < 4 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
cells = normalize_cells_local(calibration_cells);
config_ids = unique(string({cells.measurement_config_id}));
if ~isscalar(config_ids) || config_ids ~= string(model.measurement_config_id)
    error('calibrate_global_bootstrap_threshold:MeasurementConfig', ...
        'One invocation calibrates exactly one fixed measurement configuration.');
end
if opts.formal_run && (opts.Bboot_per_cell ~= 199 || numel(cells) ~= 150)
    error('calibrate_global_bootstrap_threshold:FormalPlan', ...
        'Formal calibration requires 150 cells and 199 samples per cell.');
end
lambda = NaN(opts.Bboot_per_cell, numel(cells));
cell_quantile = NaN(numel(cells), 1);
k1_fit_count = 0;
k2_fit_count = 0;
score_calls = 0;
svd_calls = 0;
start_clock = tic;
for cell_index = 1:numel(cells)
    context = cells(cell_index).initialization_factory(cells(cell_index).full_data);
    [fit1, ~] = fit_local_model_k(cells(cell_index).full_data, 1, ...
        local_domain, model, context, opts.fit_options);
    k1_fit_count = k1_fit_count + 1;
    score_calls = score_calls + fit1.num_score_eval;
    svd_calls = svd_calls + fit1.num_svd;
    if ~fit1.estimate_returned_flag
        error('calibrate_global_bootstrap_threshold:OriginalK1Fit', ...
            'Calibration cell %d did not return its fitted K1 null.', cell_index);
    end
    for bootstrap_index = 1:opts.Bboot_per_cell
        seed = cells(cell_index).seed + bootstrap_index - 1;
        [boot_data, ~] = simulate_bootstrap_under_k1(fit1, struct('seed', seed));
        boot_context = cells(cell_index).initialization_factory(boot_data);
        [fit1_boot, ~] = fit_local_model_k(boot_data, 1, ...
            local_domain, model, boot_context, opts.fit_options);
        boot_context.k1_fit = fit1_boot;
        [fit2_boot, ~] = fit_local_model_k(boot_data, 2, ...
            local_domain, model, boot_context, opts.fit_options);
        k1_fit_count = k1_fit_count + 1;
        k2_fit_count = k2_fit_count + 1;
        score_calls = score_calls + fit1_boot.num_score_eval + ...
            fit2_boot.num_score_eval;
        svd_calls = svd_calls + fit1_boot.num_svd + fit2_boot.num_svd;
        [lrt, ~] = nested_dml_likelihood_ratio(fit1_boot, fit2_boot, struct());
        if ~strcmp(lrt.lrt_status, 'OK')
            error('calibrate_global_bootstrap_threshold:BootstrapRefit', ...
                'A bootstrap K1/K2 refit did not satisfy the nested LRT contract.');
        end
        lambda(bootstrap_index, cell_index) = lrt.lambda_12;
    end
    cell_quantile(cell_index) = stage8_type1_quantile( ...
        lambda(:, cell_index), 1 - opts.alpha);
end
cell_ids = string({cells.calibration_cell_id}).';
cell_table = table(cell_ids, cell_quantile, ...
    'VariableNames', {'calibration_cell_id','q_cell_0p95'});
q_global = max(cell_quantile);
calibration_hash = stage8_stable_hash(config_ids, opts.alpha, ...
    opts.Bboot_per_cell, 'TYPE1_ORDER_STATISTIC', cell_table, lambda);
artifact = struct('measurement_config_id', char(config_ids), ...
    'q_global', q_global, 'alpha', opts.alpha, ...
    'Bboot_per_cell', opts.Bboot_per_cell, ...
    'quantile_rule', 'TYPE1_ORDER_STATISTIC', ...
    'threshold_policy', ...
    'ONE_GLOBAL_THRESHOLD_PER_FIXED_MEASUREMENT_CONFIG', ...
    'cell_quantiles', cell_table, 'calibration_hash', calibration_hash, ...
    'threshold_status', 'LOCKED_BOOTSTRAP_THRESHOLD', ...
    'artifact_scope', ternary_local(opts.formal_run, ...
    'FORMAL_STAGE8_1', 'SYNTHETIC_UNIT_TEST_ONLY'));
debug = struct('lambda_samples', lambda, 'cell_count', numel(cells), ...
    'bootstrap_sample_count', numel(lambda), ...
    'K1_fit_count', k1_fit_count, 'K2_fit_count', k2_fit_count, ...
    'score_call_count', score_calls, 'svd_call_count', svd_calls, ...
    'runtime', toc(start_clock), 'complete_refit_flag', ...
    k2_fit_count == numel(lambda) && ...
    k1_fit_count == numel(lambda) + numel(cells));
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('calibrate_global_bootstrap_threshold:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'alpha','Bboot_per_cell','formal_run','fit_options'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('calibrate_global_bootstrap_threshold:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
defaults = struct('alpha', 0.05, 'Bboot_per_cell', 199, ...
    'formal_run', false, 'fit_options', struct());
names = fieldnames(defaults);
for index = 1:numel(names)
    if ~isfield(opts, names{index})
        opts.(names{index}) = defaults.(names{index});
    end
end
end

function cells = normalize_cells_local(input)
if iscell(input)
    cells = vertcat(input{:});
elseif isstruct(input)
    cells = input(:);
else
    error('calibrate_global_bootstrap_threshold:Cells', ...
        'calibration_cells must be a struct array or cell array of structs.');
end
required = {'measurement_config_id','calibration_cell_id','seed', ...
    'full_data','initialization_factory'};
if isempty(cells) || ~all(isfield(cells, required))
    error('calibrate_global_bootstrap_threshold:CellContract', ...
        'Every calibration cell must expose data, seed, ID, and initialization factory.');
end
if ~all(arrayfun(@(x) isa(x.initialization_factory, 'function_handle'), cells))
    error('calibrate_global_bootstrap_threshold:Factory', ...
        'Every calibration cell needs a data-dependent initialization factory.');
end
end

function value = ternary_local(condition, yes_value, no_value)
if condition
    value = yes_value;
else
    value = no_value;
end
end
