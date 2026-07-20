function context = build_stage8_1a_frozen_evidence_fixture(fresh_copy)
%BUILD_STAGE8_1A_FROZEN_EVIDENCE_FIXTURE Freeze and reload tiny evidence.

if nargin < 1, fresh_copy = false; end
persistent cached_context
if ~fresh_copy && ~isempty(cached_context) && ...
        isfolder(cached_context.artifact_root)
    context = cached_context;
    return;
end
context = create_context_local();
if ~fresh_copy
    cached_context = context;
end
end

function context = create_context_local()
checkpoint_root = tempname;
artifact_root = tempname;
mkdir(checkpoint_root);
mkdir(artifact_root);
fixture = build_stage8_1a_two_commit_fixture();
indices = (1:height(fixture.plan.calibration.cells)).';
write_stage8_checkpoint_fixture(checkpoint_root, ...
    fixture.plan.calibration, fixture.contract, indices);
frozen = run_stage8_1_freeze_threshold_evidence( ...
    tempdir, checkpoint_root, artifact_root, struct( ...
    'formal_run', false, 'frozen_plan', fixture.plan));
[thresholds, calibration] = load_stage8_1_locked_thresholds( ...
    tempdir, artifact_root, fixture.plan, struct( ...
    'formal_run', false, 'require_tracked_artifacts', false));
context = struct('fixture', fixture, 'checkpoint_root', checkpoint_root, ...
    'artifact_root', artifact_root, 'frozen', frozen, ...
    'thresholds', thresholds, 'calibration', calibration, ...
    'cleanup', onCleanup(@() cleanup_local( ...
    checkpoint_root, artifact_root)));
end

function cleanup_local(checkpoint_root, artifact_root)
if isfolder(checkpoint_root), rmdir(checkpoint_root, 's'); end
if isfolder(artifact_root), rmdir(artifact_root, 's'); end
end
