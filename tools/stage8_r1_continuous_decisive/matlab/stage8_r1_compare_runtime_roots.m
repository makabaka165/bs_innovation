function result = stage8_r1_compare_runtime_roots( ...
    repo_dir, left_root, right_root, result_path, gate_name)
%STAGE8_R1_COMPARE_RUNTIME_ROOTS Compare runtime-independent checkpoints.

repo_dir = char(string(repo_dir));
tool_dir = fileparts(mfilename('fullpath'));
addpath(tool_dir);
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
left_protocol = jsondecode(fileread(fullfile(left_root, 'protocol.json')));
right_protocol = jsondecode(fileread(fullfile(right_root, 'protocol.json')));
context = stage8_r1_context(repo_dir, true);
registry = stage8_r1_build_registry(context, left_protocol.registry_kind);
left_indices = sort(double(left_protocol.trial_indices(:)));
right_indices = sort(double(right_protocol.trial_indices(:)));
if ~isequal(left_indices, right_indices) || ...
        ~strcmp(string(left_protocol.registry_kind), ...
        string(right_protocol.registry_kind))
    error('stage8_r1_compare_runtime_roots:Registry', ...
        'Runtime roots use different trial selections.');
end
registry = registry(ismember(registry.global_trial_index, left_indices), :);
left_hashes = strings(height(registry), 1);
right_hashes = strings(height(registry), 1);
left_rows = cell(height(registry), 1);
right_rows = cell(height(registry), 1);
for index = 1:height(registry)
    name = [char(registry.trial_id(index)), '.mat'];
    left_path = fullfile(left_root, 'checkpoints', name);
    right_path = fullfile(right_root, 'checkpoints', name);
    stage8_r1_validate_checkpoint(left_path, left_protocol, registry(index, :));
    stage8_r1_validate_checkpoint(right_path, right_protocol, registry(index, :));
    left = load(left_path, 'checkpoint', '-mat');
    right = load(right_path, 'checkpoint', '-mat');
    left_hashes(index) = string(left.checkpoint.scientific_content_hash);
    right_hashes(index) = string(right.checkpoint.scientific_content_hash);
    left_rows{index} = zero_runtime_local(left.checkpoint.rows);
    right_rows{index} = zero_runtime_local(right.checkpoint.rows);
end
left_table = sortrows(vertcat(left_rows{:}), ...
    {'global_trial_index','method_id'});
right_table = sortrows(vertcat(right_rows{:}), ...
    {'global_trial_index','method_id'});
checkpoint_equal = isequal(left_hashes, right_hashes);
row_equal = isequal(left_table, right_table);
left_hash = stage8_stable_hash('STAGE8_R1_ROW_SET_V1', left_table);
right_hash = stage8_stable_hash('STAGE8_R1_ROW_SET_V1', right_table);
pass = checkpoint_equal && row_equal && strcmp(left_hash, right_hash);
result = struct('gate_name', upper(char(string(gate_name))), ...
    'pass', pass, 'checkpoint_scientific_hash_equality', checkpoint_equal, ...
    'row_exact_equality', row_equal, 'left_row_hash', left_hash, ...
    'right_row_hash', right_hash, ...
    'element_trial_count', height(registry), ...
    'method_row_count', height(left_table), 'last_error', '');
stage8_r1_write_json_atomic(result_path, result);
clear path_cleanup
end

function rows = zero_runtime_local(rows)
names = {'runtime_sec','shared_initialization_runtime_sec', ...
    'initialization_runtime_sec','refinement_runtime_sec'};
for index = 1:numel(names), rows.(names{index})(:) = 0; end
end
