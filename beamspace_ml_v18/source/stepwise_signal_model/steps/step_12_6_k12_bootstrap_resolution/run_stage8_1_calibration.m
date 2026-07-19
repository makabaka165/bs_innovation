function output = run_stage8_1_calibration(repo_dir, opts)
%RUN_STAGE8_1_CALIBRATION Execute the separately authorized formal shards.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 1 || isempty(repo_dir)
    repo_dir = repository_root_local();
end
if nargin < 2 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts);
if ~strcmp(opts.execution_authorization, ...
        'AUTHORIZE_STAGE8_1B_FORMAL_CALIBRATION')
    error('run_stage8_1_calibration:Authorization', ...
        'Formal calibration requires separate Stage8.1B authorization.');
end
cfg = sim_cfg();
plan = build_stage8_locked_plan(repo_dir, cfg, ...
    struct('require_formal_runtime', true));
registry = plan.measurement_model_registry;
stage5_locked = build_stage8_stage5_locked_config();
[cells, materialization_debug] = materialize_stage8_calibration_cells( ...
    plan.calibration, plan.local_domain, registry, stage5_locked, ...
    struct('formal_run', true, 'source_identity', ...
    plan.identity.stage8_stable_code_identity_hash));
fit_options = struct('max_iter', plan.solver.max_iter, ...
    'relative_score_tolerance', plan.solver.relative_score_tolerance, ...
    'angle_tolerance_deg', plan.solver.angle_tolerance_deg, ...
    'rank_multiplier', plan.solver.rank_multiplier, ...
    'solver_contract_hash', plan.solver_contract_hash);
cell_options = struct('formal_run', true, 'alpha', 0.05, ...
    'Bboot_per_cell', 199, 'fit_options', fit_options);
shard = run_stage8_1_calibration_shard(cells, plan.local_domain, ...
    registry, stage5_locked, struct('cell_indices', opts.cell_indices, ...
    'checkpoint_dir', opts.checkpoint_dir, ...
    'cell_options', cell_options));
if numel(opts.cell_indices) == 300
    [thresholds, aggregation_debug] = aggregate_stage8_1_calibration( ...
        shard.artifacts, plan.calibration, struct('formal_run', true));
else
    thresholds = struct([]);
    aggregation_debug = struct('status', ...
        'PARTIAL_SHARD_NOT_ELIGIBLE_FOR_AGGREGATION');
end
output = struct('plan', plan, 'measurement_registry', registry, ...
    'materialized_cells', cells, 'materialization_debug', ...
    materialization_debug, 'shard', shard, 'locked_thresholds', ...
    thresholds, 'aggregation_debug', aggregation_debug, ...
    'formal_calibration_executed_flag', true, ...
    'validation_executed_flag', false, 'phase_factor', 1);
clear path_cleanup
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('run_stage8_1_calibration:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'execution_authorization','checkpoint_dir','cell_indices'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('run_stage8_1_calibration:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'execution_authorization')
    opts.execution_authorization = '';
end
if ~isfield(opts, 'checkpoint_dir')
    opts.checkpoint_dir = fullfile(fileparts(mfilename('fullpath')), ...
        'calibration', 'checkpoints');
end
if ~isfield(opts, 'cell_indices')
    opts.cell_indices = (1:300).';
end
indices = opts.cell_indices(:);
if isempty(indices) || any(indices < 1) || any(indices > 300) || ...
        any(indices ~= fix(indices)) || numel(unique(indices)) ~= numel(indices)
    error('run_stage8_1_calibration:CellIndices', ...
        'cell_indices must be unique members of 1:300.');
end
opts.cell_indices = indices;
end

function repo_dir = repository_root_local()
[status, output] = system('git rev-parse --show-toplevel');
if status ~= 0
    error('run_stage8_1_calibration:Repository', ...
        'Unable to locate the Git repository root.');
end
repo_dir = strtrim(output);
end
