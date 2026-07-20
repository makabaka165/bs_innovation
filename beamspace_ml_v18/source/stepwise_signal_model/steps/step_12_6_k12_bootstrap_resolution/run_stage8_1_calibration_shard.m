function shard = run_stage8_1_calibration_shard( ...
    cells, local_domain, model_registry, stage5_locked, opts)
%RUN_STAGE8_1_CALIBRATION_SHARD Execute an explicit auditable cell shard.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 5 || isempty(opts)
    opts = struct();
end
opts = normalize_options_local(opts, numel(cells));
if isfield(opts.cell_options, 'formal_run') && opts.cell_options.formal_run
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('run_stage8_1_calibration_shard:Repository', ...
            'Unable to locate the Git repository root.');
    end
    opts.checkpoint_dir = validate_stage8_formal_checkpoint_root( ...
        strtrim(repo_dir), opts.checkpoint_dir);
end
artifacts = cell(numel(opts.cell_indices), 1);
reused = false(numel(opts.cell_indices), 1);
start_clock = tic;
for output_index = 1:numel(opts.cell_indices)
    cell_index = opts.cell_indices(output_index);
    cell_opts = opts.cell_options;
    if ~isempty(opts.checkpoint_dir)
        cell_opts.checkpoint_path = fullfile(opts.checkpoint_dir, sprintf( ...
            'stage8_1_cell_%03d.mat', cells(cell_index).global_cell_index));
    end
    [artifacts{output_index}, cell_debug] = ...
        run_stage8_1_calibration_cell(cells(cell_index), local_domain, ...
        model_registry, stage5_locked, cell_opts);
    reused(output_index) = cell_debug.checkpoint_reused_flag;
    if ~strcmp(artifacts{output_index}.status, 'CALIBRATION_CELL_PASS')
        artifacts = artifacts(1:output_index);
        reused = reused(1:output_index);
        break;
    end
end
artifacts = vertcat(artifacts{:});
shard_identity = stage8_stable_hash('STAGE8_1_CALIBRATION_SHARD_V1', ...
    [artifacts.global_cell_index], string({artifacts.cell_artifact_hash}));
shard = struct('artifacts', artifacts, ...
    'global_cell_indices', [artifacts.global_cell_index].', ...
    'checkpoint_reused_flags', reused, ...
    'shard_identity', shard_identity, 'runtime', toc(start_clock), ...
    'status', ternary_local(all(strcmp({artifacts.status}, ...
    'CALIBRATION_CELL_PASS')), 'CALIBRATION_SHARD_PASS', ...
    'CALIBRATION_SHARD_FAILURE'), 'phase_factor', 1);
clear path_cleanup
end

function opts = normalize_options_local(opts, cell_count)
if ~(isstruct(opts) && isscalar(opts))
    error('run_stage8_1_calibration_shard:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'cell_indices','checkpoint_dir','cell_options'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('run_stage8_1_calibration_shard:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'cell_indices')
    opts.cell_indices = (1:cell_count).';
end
if ~isfield(opts, 'checkpoint_dir')
    opts.checkpoint_dir = '';
end
if ~isfield(opts, 'cell_options')
    opts.cell_options = struct();
end
indices = opts.cell_indices(:);
if isempty(indices) || any(indices < 1) || any(indices > cell_count) || ...
        any(indices ~= fix(indices)) || numel(unique(indices)) ~= numel(indices)
    error('run_stage8_1_calibration_shard:CellIndices', ...
        'cell_indices must be unique valid materialized-cell indices.');
end
opts.cell_indices = indices;
end

function value = ternary_local(condition, yes_value, no_value)
if condition
    value = yes_value;
else
    value = no_value;
end
end
