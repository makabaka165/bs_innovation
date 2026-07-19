function [manifest, artifacts] = ...
    load_stage8_1_checkpoint_manifest(checkpoint_root)
%LOAD_STAGE8_1_CHECKPOINT_MANIFEST Inventory cell checkpoints recursively.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if ~(ischar(checkpoint_root) || ...
        (isstring(checkpoint_root) && isscalar(checkpoint_root))) || ...
        ~isfolder(checkpoint_root)
    error('load_stage8_1_checkpoint_manifest:CheckpointRoot', ...
        'checkpoint_root must be an existing directory.');
end
files = dir(fullfile(char(checkpoint_root), '**', 'stage8_1_cell_*.mat'));
files = files(~[files.isdir]);
count = numel(files);
artifacts = cell(count, 1);
checkpoint_path = strings(count, 1);
calibration_cell_id = strings(count, 1);
global_cell_index = zeros(count, 1);
source_identity = strings(count, 1);
plan_hash = strings(count, 1);
model_hash = strings(count, 1);
cell_input_hash = strings(count, 1);
cell_artifact_hash = strings(count, 1);
computed_cell_artifact_hash = strings(count, 1);
artifact_hash_match = false(count, 1);
status = strings(count, 1);
required = {'calibration_cell_id','global_cell_index','source_identity', ...
    'plan_hash','model_hash','cell_input_hash','cell_artifact_hash','status'};
for file_index = 1:count
    path_now = fullfile(files(file_index).folder, files(file_index).name);
    loaded = load(path_now, 'artifact');
    if ~isfield(loaded, 'artifact') || ...
            ~(isstruct(loaded.artifact) && isscalar(loaded.artifact)) || ...
            ~all(isfield(loaded.artifact, required))
        error('load_stage8_1_checkpoint_manifest:CheckpointFormat', ...
            'Malformed checkpoint: %s.', path_now);
    end
    artifact = loaded.artifact;
    computed = stage8_calibration_artifact_hash(artifact);
    artifacts{file_index} = artifact;
    checkpoint_path(file_index) = string(path_now);
    calibration_cell_id(file_index) = string(artifact.calibration_cell_id);
    global_cell_index(file_index) = artifact.global_cell_index;
    source_identity(file_index) = string(artifact.source_identity);
    plan_hash(file_index) = string(artifact.plan_hash);
    model_hash(file_index) = string(artifact.model_hash);
    cell_input_hash(file_index) = string(artifact.cell_input_hash);
    cell_artifact_hash(file_index) = string(artifact.cell_artifact_hash);
    computed_cell_artifact_hash(file_index) = string(computed);
    artifact_hash_match(file_index) = ...
        cell_artifact_hash(file_index) == computed_cell_artifact_hash(file_index);
    status(file_index) = string(artifact.status);
end
manifest = table(checkpoint_path, calibration_cell_id, global_cell_index, ...
    source_identity, plan_hash, model_hash, cell_input_hash, ...
    cell_artifact_hash, computed_cell_artifact_hash, ...
    artifact_hash_match, status);
clear path_cleanup
end
