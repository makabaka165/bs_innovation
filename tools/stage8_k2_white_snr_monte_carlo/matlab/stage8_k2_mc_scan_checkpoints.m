function scan = stage8_k2_mc_scan_checkpoints( ...
    runtime_root, registry, context, registry_hash)
%STAGE8_K2_MC_SCAN_CHECKPOINTS Validate every existing final checkpoint.

checkpoint_dir = fullfile(runtime_root, 'checkpoints');
if ~isfolder(checkpoint_dir)
    error('stage8_k2_mc_scan_checkpoints:Directory', ...
        'Checkpoint directory is missing.');
end
expected_names = strings(height(registry), 1);
for index = 1:height(registry)
    [~, name, extension] = fileparts(stage8_k2_mc_checkpoint_path( ...
        runtime_root, registry(index, :)));
    expected_names(index) = string([name, extension]);
end
found = dir(fullfile(checkpoint_dir, '*.mat'));
found_names = string({found.name}).';
unexpected = setdiff(found_names, expected_names);
if ~isempty(unexpected)
    error('stage8_k2_mc_scan_checkpoints:Unexpected', ...
        'Unexpected final checkpoint: %s', unexpected(1));
end
completed = false(height(registry), 1);
checkpoints = cell(height(registry), 1);
runtime_sec = nan(height(registry), 1);
for index = 1:height(registry)
    path_now = stage8_k2_mc_checkpoint_path( ...
        runtime_root, registry(index, :));
    if isfile(path_now)
        checkpoints{index} = stage8_k2_mc_checkpoint_load( ...
            path_now, registry(index, :), context, registry_hash);
        completed(index) = true;
        runtime_sec(index) = checkpoints{index}.runtime_sec;
    end
end
temporary = dir(fullfile(checkpoint_dir, '*.tmp'));
scan = struct('completed_mask', completed, ...
    'completed_count', nnz(completed), ...
    'remaining_count', height(registry) - nnz(completed), ...
    'checkpoints', {checkpoints}, 'runtime_sec', runtime_sec, ...
    'tmp_count', numel(temporary), ...
    'unexpected_count', numel(unexpected));
end
