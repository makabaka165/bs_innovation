function evidence = run_stage8_1_freeze_threshold_evidence( ...
    repo_dir, checkpoint_root, artifact_root, opts)
%RUN_STAGE8_1_FREEZE_THRESHOLD_EVIDENCE Freeze calibration-only evidence.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 4 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
if opts.formal_run && ~strcmp(opts.execution_authorization, ...
        'AUTHORIZE_STAGE8_1B_THRESHOLD_FREEZE')
    error('run_stage8_1_freeze_threshold_evidence:Authorization', ...
        'Formal threshold freezing requires explicit authorization.');
end
if opts.formal_run
    checkpoint_root = validate_stage8_formal_checkpoint_root( ...
        repo_dir, checkpoint_root);
end
if isempty(opts.frozen_plan)
    plan = build_stage8_locked_plan(repo_dir, sim_cfg(), ...
        struct('require_formal_runtime', opts.formal_run));
else
    if opts.formal_run
        error('run_stage8_1_freeze_threshold_evidence:PlanOverride', ...
            'Formal threshold freezing cannot override the frozen plan.');
    end
    plan = opts.frozen_plan;
end
contract = build_stage8_threshold_contract(plan);
[artifacts, checkpoint_manifest] = collect_stage8_1_cell_artifacts( ...
    checkpoint_root, plan.calibration, contract);
[thresholds, aggregation_debug] = aggregate_stage8_1_calibration( ...
    artifacts, plan.calibration, struct('formal_run', opts.formal_run, ...
    'alpha', plan.controls.alpha, 'expected_contract', contract));
config_ids = string(plan.validation.K1.measurement_config_ids(:));
[thresholds, threshold_set_hash] = validate_stage8_locked_threshold_set( ...
    config_ids, thresholds, contract);
checkpoint_manifest_hash = checkpoint_manifest_hash_local( ...
    checkpoint_manifest);
bundle = build_stage8_1_calibration_bundle(plan, artifacts, thresholds, ...
    checkpoint_manifest_hash);
written = write_stage8_1_calibration_evidence(bundle, artifact_root, ...
    struct('overwrite', opts.overwrite));
evidence = written;
evidence.artifact_root = artifact_root;
evidence.repo_dir = repo_dir;
evidence.locked_thresholds = thresholds;
evidence.threshold_set_hash = threshold_set_hash;
evidence.two_threshold_artifact_hashes = ...
    string({thresholds.threshold_artifact_hash}).';
evidence.stage8_stable_code_identity_hash = ...
    contract.stage8_stable_code_identity_hash;
evidence.stage8_plan_hash = contract.stage8_plan_hash;
evidence.stage8_calibration_plan_hash = ...
    contract.stage8_calibration_plan_hash;
evidence.measurement_registry_hash = contract.measurement_registry_hash;
evidence.checkpoint_manifest_hash = checkpoint_manifest_hash;
evidence.cell_count = numel(artifacts);
evidence.bootstrap_sample_count = ...
    sum(arrayfun(@(item) numel(item.lambda_samples), artifacts));
evidence.calibration_freeze_status = ...
    'PASS_STAGE8_1_THRESHOLD_EVIDENCE_FREEZE';
evidence.validation_executed_flag = false;
evidence.aggregation_debug = aggregation_debug;
clear path_cleanup
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('run_stage8_1_freeze_threshold_evidence:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'formal_run','execution_authorization','frozen_plan','overwrite'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('run_stage8_1_freeze_threshold_evidence:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'formal_run'), opts.formal_run = true; end
if ~isfield(opts, 'execution_authorization')
    opts.execution_authorization = '';
end
if ~isfield(opts, 'frozen_plan'), opts.frozen_plan = []; end
if ~isfield(opts, 'overwrite'), opts.overwrite = false; end
end

function digest = checkpoint_manifest_hash_local(manifest)
columns = {'calibration_cell_id','global_cell_index','source_identity', ...
    'plan_hash','model_hash','cell_input_hash','cell_artifact_hash', ...
    'computed_cell_artifact_hash','artifact_hash_match','status'};
digest = stage8_stable_hash( ...
    'STAGE8_1_CHECKPOINT_MANIFEST_V1', manifest(:, columns));
end
