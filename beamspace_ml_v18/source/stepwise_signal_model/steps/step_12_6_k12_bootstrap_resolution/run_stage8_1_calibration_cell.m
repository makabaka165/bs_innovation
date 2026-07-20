function [artifact, debug] = run_stage8_1_calibration_cell( ...
    cell_input, local_domain, model_registry, stage5_locked, opts)
%RUN_STAGE8_1_CALIBRATION_CELL Execute or resume one auditable cell.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts, cell_input);
model = resolve_stage8_measurement_model(model_registry, ...
    cell_input.measurement_config_id, cell_input.noise_profile_id);
verify_cell_identity_local(cell_input, model, local_domain);
expected = checkpoint_identity_local(cell_input, model);
if ~isempty(opts.checkpoint_path) && isfile(opts.checkpoint_path)
    [artifact, debug] = load_checkpoint_local(opts.checkpoint_path, expected);
    clear path_cleanup
    return;
end
start_clock = tic;
Bboot = opts.Bboot_per_cell;
lambda = NaN(Bboot, 1);
bootstrap_seeds = cell_input.bootstrap_seed_start + (0:Bboot - 1).';
failure_rows = cell(Bboot + 1, 1);
failure_count = 0;
k1_fit_count = 0;
k2_fit_count = 0;
score_calls = 0;
svd_calls = 0;
factory_rebuild_count = 0;
fit1_boot_debug = struct();
fit2_boot_debug = struct();
mean_contract = build_stage8_bootstrap_mean_identity_contract();
mean_identity_summary = mean_identity_summary_local([], mean_contract);

[context, init_debug] = build_context_local( ...
    cell_input.full_data, model, local_domain, stage5_locked, opts);
factory_rebuild_count = factory_rebuild_count + 1;
score_calls = score_calls + init_debug.num_score_eval;
svd_calls = svd_calls + init_debug.num_svd;
[fit1, fit1_debug] = fit_model_local(1, 0, cell_input.full_data, ...
    context, local_domain, model, opts);
k1_fit_count = k1_fit_count + 1;
score_calls = score_calls + fit1.num_score_eval;
svd_calls = svd_calls + fit1.num_svd;
[valid1, validity1] = validate_stage8_fit_for_lrt(fit1, 1, ...
    expected_fit_identity_local(model, local_domain, fit1));
if ~valid1
    failure_count = 1;
    failure_rows{1} = failure_row_local(0, NaN, 1, validity1.status);
    status = 'CALIBRATION_CELL_ORIGINAL_FIT_FAILURE';
else
    status = 'CALIBRATION_CELL_PASS';
end

if valid1
    mean_identity = evaluate_stage8_bootstrap_mean_identity(fit1, model);
    mean_identity_summary = mean_identity_summary_local( ...
        mean_identity, mean_contract);
    if ~mean_identity.overall_pass
        failure_count = 1;
        failure_rows{1} = mean_contract_failure_row_local(1, ...
            bootstrap_seeds(1), mean_identity, model, cell_input);
        status = 'CALIBRATION_CELL_BOOTSTRAP_MEAN_CONTRACT_FAILURE';
    end
end

if valid1 && mean_identity_summary.overall_pass
    for bootstrap_index = 1:Bboot
        seed = bootstrap_seeds(bootstrap_index);
        [boot_data, ~] = simulate_bootstrap_local( ...
            fit1, model, seed, opts);
        [boot_context, boot_init_debug] = build_context_local( ...
            boot_data, model, local_domain, stage5_locked, opts);
        factory_rebuild_count = factory_rebuild_count + 1;
        score_calls = score_calls + boot_init_debug.num_score_eval;
        svd_calls = svd_calls + boot_init_debug.num_svd;
        [fit1_boot, fit1_boot_debug] = fit_model_local( ...
            1, bootstrap_index, boot_data, boot_context, ...
            local_domain, model, opts);
        k1_fit_count = k1_fit_count + 1;
        score_calls = score_calls + fit1_boot.num_score_eval;
        svd_calls = svd_calls + fit1_boot.num_svd;
        [valid1_boot, validity1_boot] = validate_stage8_fit_for_lrt( ...
            fit1_boot, 1, expected_fit_identity_local( ...
            model, local_domain, fit1_boot));
        if ~valid1_boot
            failure_count = failure_count + 1;
            failure_rows{failure_count} = failure_row_local( ...
                bootstrap_index, seed, 1, validity1_boot.status);
            status = 'CALIBRATION_CELL_REFIT_FAILURE';
            break;
        end
        boot_context.k1_fit = fit1_boot;
        [fit2_boot, fit2_boot_debug] = fit_model_local( ...
            2, bootstrap_index, boot_data, boot_context, ...
            local_domain, model, opts);
        k2_fit_count = k2_fit_count + 1;
        score_calls = score_calls + fit2_boot.num_score_eval;
        svd_calls = svd_calls + fit2_boot.num_svd;
        expected2 = expected_fit_identity_local(model, local_domain, fit1_boot);
        [valid2_boot, validity2_boot] = validate_stage8_fit_for_lrt( ...
            fit2_boot, 2, expected2);
        if ~valid2_boot
            failure_count = failure_count + 1;
            failure_rows{failure_count} = failure_row_local( ...
                bootstrap_index, seed, 2, validity2_boot.status);
            status = 'CALIBRATION_CELL_REFIT_FAILURE';
            break;
        end
        [lrt, ~] = nested_dml_likelihood_ratio( ...
            fit1_boot, fit2_boot, struct());
        if ~strcmp(lrt.lrt_status, 'OK') || ~lrt.nested_rss_pass
            failure_count = failure_count + 1;
            failure_rows{failure_count} = failure_row_local( ...
                bootstrap_index, seed, 0, lrt.lrt_status);
            status = 'CALIBRATION_CELL_REFIT_FAILURE';
            break;
        end
        lambda(bootstrap_index) = lrt.lambda_12;
    end
end
if strcmp(status, 'CALIBRATION_CELL_PASS') && all(isfinite(lambda))
    q_cell = stage8_type1_quantile(lambda, 1 - opts.alpha);
else
    q_cell = NaN;
end
failure_details = failures_table_local(failure_rows, failure_count);
runtime = toc(start_clock);
hash_payload = struct( ...
    'measurement_config_id', cell_input.measurement_config_id, ...
    'noise_profile_id', cell_input.noise_profile_id, ...
    'calibration_cell_id', cell_input.calibration_cell_id, ...
    'global_cell_index', cell_input.global_cell_index, ...
    'model_key', model.model_key, 'data_seed', ...
    cell_input.calibration_data_seed, ...
    'bootstrap_seed_start', cell_input.bootstrap_seed_start, ...
    'bootstrap_seed_end', cell_input.bootstrap_seed_end, ...
    'lambda_samples', lambda, 'q_cell_0p95', q_cell, ...
    'failure_details', failure_details, 'source_identity', ...
    cell_input.source_identity, 'plan_hash', cell_input.plan_hash, ...
    'model_hash', model.fixed_measurement_hash, ...
    'cell_input_hash', cell_input.cell_input_hash, 'status', status);
hash_payload.K1_fit_count = k1_fit_count;
hash_payload.K2_fit_count = k2_fit_count;
hash_payload.score_call_count = score_calls;
hash_payload.svd_call_count = svd_calls;
hash_payload.initialization_factory_rebuild_count = factory_rebuild_count;
hash_payload.failure_count = failure_count;
hash_payload.bootstrap_mean_identity_contract_version = ...
    mean_identity_summary.contract_version;
hash_payload.bootstrap_mean_identity_contract_hash = ...
    mean_identity_summary.contract_hash;
hash_payload.bootstrap_mean_identity_status = ...
    mean_identity_summary.failure_status;
hash_payload.bootstrap_mean_identity_G_absolute_residual = ...
    mean_identity_summary.G_absolute_residual;
hash_payload.bootstrap_mean_identity_G_absolute_bound = ...
    mean_identity_summary.G_absolute_bound;
hash_payload.bootstrap_mean_identity_G_max_bound_ratio = ...
    mean_identity_summary.G_max_bound_ratio;
hash_payload.bootstrap_mean_identity_mean_absolute_residual = ...
    mean_identity_summary.mean_absolute_residual;
hash_payload.bootstrap_mean_identity_mean_absolute_bound = ...
    mean_identity_summary.mean_absolute_bound;
hash_payload.bootstrap_mean_identity_mean_max_bound_ratio = ...
    mean_identity_summary.mean_max_bound_ratio;
hash_payload.bootstrap_mean_identity_old_relative_error = ...
    mean_identity_summary.mean_old_relative_residual;
hash_payload.bootstrap_mean_identity_fitted_mean_norm = ...
    mean_identity_summary.fitted_mean_norm;
hash_payload.bootstrap_mean_identity_W_alias_pass = ...
    mean_identity_summary.W_alias_pass;
hash_payload.bootstrap_mean_identity_T_alias_pass = ...
    mean_identity_summary.T_alias_pass;
hash_payload.bootstrap_mean_identity_fixed_measurement_pass = ...
    mean_identity_summary.fixed_measurement_pass;
hash_payload.bootstrap_mean_identity_overall_pass = ...
    mean_identity_summary.overall_pass;
cell_artifact_hash = stage8_calibration_artifact_hash(hash_payload);
artifact = hash_payload;
artifact.K1_fit_count = k1_fit_count;
artifact.K2_fit_count = k2_fit_count;
artifact.score_call_count = score_calls;
artifact.svd_call_count = svd_calls;
artifact.initialization_factory_rebuild_count = factory_rebuild_count;
artifact.runtime = runtime;
artifact.failure_count = failure_count;
artifact.cell_artifact_hash = cell_artifact_hash;
artifact.phase_factor = 1;
debug = struct('checkpoint_reused_flag', false, ...
    'fit1_debug', fit1_debug, 'last_fit1_boot_debug', ...
    fit1_boot_debug, 'last_fit2_boot_debug', fit2_boot_debug, ...
    'bootstrap_mean_identity_preflight', mean_identity_summary, ...
    'runtime', runtime, 'phase_factor', 1);
if ~isempty(opts.checkpoint_path)
    write_checkpoint_local(opts.checkpoint_path, artifact);
end
clear path_cleanup
end

function opts = normalize_options_local(opts, cell_input)
if ~(isstruct(opts) && isscalar(opts))
    error('run_stage8_1_calibration_cell:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'alpha','Bboot_per_cell','formal_run','fit_options', ...
    'checkpoint_path','fit_callback','bootstrap_callback', ...
    'initialization_callback'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('run_stage8_1_calibration_cell:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
defaults = struct('alpha', 0.05, ...
    'Bboot_per_cell', cell_input.Bboot_per_cell, 'formal_run', false, ...
    'fit_options', struct(), 'checkpoint_path', '', ...
    'fit_callback', [], 'bootstrap_callback', [], ...
    'initialization_callback', []);
names = fieldnames(defaults);
for field_index = 1:numel(names)
    if ~isfield(opts, names{field_index})
        opts.(names{field_index}) = defaults.(names{field_index});
    end
end
if opts.formal_run && (opts.alpha ~= 0.05 || ...
        opts.Bboot_per_cell ~= 199 || ~isempty(opts.fit_callback) || ...
        ~isempty(opts.bootstrap_callback) || ...
        ~isempty(opts.initialization_callback))
    error('run_stage8_1_calibration_cell:FormalContract', ...
        'Formal cells require alpha=0.05, Bboot=199, and real data paths.');
end
if opts.Bboot_per_cell > cell_input.Bboot_per_cell
    error('run_stage8_1_calibration_cell:SeedCount', ...
        'Bboot exceeds the materialized seed block.');
end
end

function verify_cell_identity_local(cell_input, model, domain)
required = {'measurement_config_id','noise_profile_id', ...
    'calibration_cell_id','global_cell_index','model_key', ...
    'fixed_measurement_hash','calibration_data_seed', ...
    'bootstrap_seed_start','bootstrap_seed_end','Bboot_per_cell', ...
    'full_data','cell_input_hash','source_identity','plan_hash'};
if ~(isstruct(cell_input) && isscalar(cell_input) && ...
        all(isfield(cell_input, required)))
    error('run_stage8_1_calibration_cell:CellContract', ...
        'cell_input is incomplete.');
end
if ~strcmp(cell_input.model_key, model.model_key) || ...
        ~strcmp(cell_input.fixed_measurement_hash, ...
        model.fixed_measurement_hash) || ...
        ~strcmp(cell_input.full_data.fixed_measurement_hash, ...
        model.fixed_measurement_hash)
    error('run_stage8_1_calibration_cell:ModelIdentity', ...
        'Cell, data, and resolved model identities differ.');
end
if ~isfield(domain, 'domain_hash')
    error('run_stage8_1_calibration_cell:Domain', ...
        'local_domain must expose domain_hash.');
end
end

function identity = checkpoint_identity_local(cell_input, model)
identity = struct('source_identity', cell_input.source_identity, ...
    'plan_hash', cell_input.plan_hash, ...
    'model_hash', model.fixed_measurement_hash, ...
    'cell_input_hash', cell_input.cell_input_hash);
end

function expected = expected_fit_identity_local(model, domain, reference_fit)
expected = struct('fixed_measurement_hash', model.fixed_measurement_hash, ...
    'local_domain_hash', domain.domain_hash);
if isfield(reference_fit, 'solver_contract_hash')
    expected.solver_contract_hash = reference_fit.solver_contract_hash;
end
if isfield(reference_fit, 'observation_hash')
    expected.observation_hash = reference_fit.observation_hash;
end
end

function [context, debug] = build_context_local( ...
    data, model, domain, locked, opts)
if isempty(opts.initialization_callback)
    [context, debug] = build_stage8_initialization_context_from_data( ...
        data, model, domain, locked, model.noise_factorization, struct());
else
    [context, debug] = opts.initialization_callback(data, model, domain);
end
end

function [fit, debug] = fit_model_local( ...
    K, sample_index, data, context, domain, model, opts)
if isempty(opts.fit_callback)
    [fit, debug] = fit_local_model_k( ...
        data, K, domain, model, context, opts.fit_options);
else
    [fit, debug] = opts.fit_callback(K, sample_index, data, context, model);
end
end

function [data, debug] = simulate_bootstrap_local(fit1, model, seed, opts)
if isempty(opts.bootstrap_callback)
    [data, debug] = simulate_bootstrap_under_k1( ...
        fit1, model, struct('seed', seed, 'formal_run', opts.formal_run));
else
    [data, debug] = opts.bootstrap_callback(fit1, model, seed);
end
end

function row = failure_row_local(index, seed, K, status)
row = struct('bootstrap_index', index, 'bootstrap_seed', seed, ...
    'model_K', K, 'failure_status', string(status), ...
    'G_absolute_residual', NaN, 'G_backward_bound', NaN, ...
    'G_max_bound_ratio', NaN, 'mean_absolute_residual', NaN, ...
    'mean_backward_bound', NaN, 'mean_max_bound_ratio', NaN, ...
    'old_relative_mean_error', NaN, 'fitted_mean_norm', NaN, ...
    'model_hash', "", 'cell_input_hash', "", ...
    'mean_contract_version', "", 'mean_contract_hash', "");
end

function row = mean_contract_failure_row_local( ...
    index, seed, evaluation, model, cell_input)
row = failure_row_local(index, seed, 1, evaluation.failure_status);
row.G_absolute_residual = evaluation.G_absolute_residual;
row.G_backward_bound = evaluation.G_absolute_bound;
row.G_max_bound_ratio = evaluation.G_max_bound_ratio;
row.mean_absolute_residual = evaluation.mean_absolute_residual;
row.mean_backward_bound = evaluation.mean_absolute_bound;
row.mean_max_bound_ratio = evaluation.mean_max_bound_ratio;
row.old_relative_mean_error = evaluation.mean_old_relative_residual;
row.fitted_mean_norm = evaluation.fitted_mean_norm;
row.model_hash = string(model.fixed_measurement_hash);
row.cell_input_hash = string(cell_input.cell_input_hash);
row.mean_contract_version = string(evaluation.contract_version);
row.mean_contract_hash = string(evaluation.contract_hash);
end

function table_out = failures_table_local(rows, count)
if count == 0
    table_out = struct2table(failure_row_local(NaN, NaN, NaN, ""));
    table_out(1, :) = [];
else
    table_out = struct2table(vertcat(rows{1:count}));
end
end

function summary = mean_identity_summary_local(evaluation, contract)
summary = struct('contract_version', contract.contract_version, ...
    'contract_hash', contract.contract_hash, ...
    'failure_status', 'MEAN_IDENTITY_NOT_EVALUATED', ...
    'G_absolute_residual', NaN, 'G_absolute_bound', NaN, ...
    'G_max_bound_ratio', NaN, 'mean_absolute_residual', NaN, ...
    'mean_absolute_bound', NaN, 'mean_max_bound_ratio', NaN, ...
    'mean_old_relative_residual', NaN, 'fitted_mean_norm', NaN, ...
    'W_alias_pass', false, 'T_alias_pass', false, ...
    'fixed_measurement_pass', false, 'overall_pass', false);
if isempty(evaluation)
    return;
end
names = fieldnames(summary);
for index = 1:numel(names)
    if isfield(evaluation, names{index})
        summary.(names{index}) = evaluation.(names{index});
    end
end
end

function [artifact, debug] = load_checkpoint_local(path_now, expected)
loaded = load(path_now, 'artifact');
if ~isfield(loaded, 'artifact')
    error('run_stage8_1_calibration_cell:CheckpointFormat', ...
        'Checkpoint does not contain artifact.');
end
artifact = loaded.artifact;
if ~isfield(artifact, 'cell_artifact_hash') || ...
        ~strcmp(artifact.cell_artifact_hash, ...
        stage8_calibration_artifact_hash(artifact))
    error('run_stage8_1_calibration_cell:CheckpointArtifactHashMismatch', ...
        'Checkpoint artifact hash verification failed: %s.', path_now);
end
fields = fieldnames(expected);
for field_index = 1:numel(fields)
    field = fields{field_index};
    if ~isfield(artifact, field) || ...
            ~strcmp(string(artifact.(field)), string(expected.(field)))
        error('run_stage8_1_calibration_cell:CheckpointIdentityMismatch', ...
            'Checkpoint %s does not match %s.', path_now, field);
    end
end
debug = struct('checkpoint_reused_flag', true, ...
    'checkpoint_path', path_now, 'runtime', 0, 'phase_factor', 1);
end

function write_checkpoint_local(path_now, artifact)
folder = fileparts(path_now);
if ~isempty(folder) && ~isfolder(folder)
    mkdir(folder);
end
temporary_path = [path_now, '.tmp'];
save(temporary_path, 'artifact', '-v7');
[success, message] = movefile(temporary_path, path_now, 'f');
if ~success
    error('run_stage8_1_calibration_cell:CheckpointWrite', '%s', message);
end
end
