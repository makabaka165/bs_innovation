function execution = build_stage7_1_execution_context( ...
    repo_dir, stage7_dir, stage7_result_dir)
%BUILD_STAGE7_1_EXECUTION_CONTEXT Rebuild frozen Stage 7 objects without FIM.

repo_dir = existing_dir_local(repo_dir, 'repo_dir');
stage7_dir = existing_dir_local(stage7_dir, 'stage7_dir');
stage7_result_dir = existing_dir_local(stage7_result_dir, ...
    'stage7_result_dir');
steps_dir = fileparts(stage7_dir);
project_dir = fileparts(steps_dir);
old_path = path;
path_cleanup = onCleanup(@() path(old_path));
addpath(fullfile(steps_dir, 'step_12_0_receive_model_correction', 'common'));
addpath(fullfile(steps_dir, 'step_12_1_sequential_dbf_model', 'common'));
addpath(fullfile(steps_dir, 'step_12_2_stable_dml_backend', 'common'));
addpath(fullfile(stage7_dir, 'common'));
addpath(fullfile(stage7_dir, 'tests'));
addpath(fullfile(project_dir, 'core', 'config'));
addpath(fullfile(project_dir, 'core', 'array'));

cfg = sim_cfg();
if cfg.beam.spatialPhaseFactor ~= 1 || ~strcmp(version('-release'), '2022b')
    error('build_stage7_1_execution_context:RuntimeContract', ...
        'Formal Stage7.1 execution requires phase_factor=1 and MATLAB R2022b.');
end
temporary_dir = tempname;
mkdir(temporary_dir);
temp_cleanup = onCleanup(@() remove_temp_local(temporary_dir));
[stage7_plan, ~] = freeze_stage7_locked_plan( ...
    cfg, repo_dir, stage7_dir, temporary_dir);
registry_path = fullfile(stage7_result_dir, 'stage7_plan_registry.csv');
registry_options = detectImportOptions(registry_path, 'TextType', 'string');
registry_options = setvartype(registry_options, ...
    {'registry_key','registry_value'}, 'string');
registry = readtable(registry_path, registry_options);
registered_hash = registry.registry_value( ...
    registry.registry_key == "stage7_plan_hash");
if ~isscalar(registered_hash) || ...
        registered_hash ~= string(stage7_plan.hashes.stage7_plan_hash)
    error('build_stage7_1_execution_context:PlanHash', ...
        'Current Stage 7 results do not match the reconstructed frozen plan.');
end

methods = fixed_edge_methods_local(stage7_plan.subset_family);
noise_models = { ...
    build_stage7_noise_covariance('WHITE', cfg), ...
    build_stage7_noise_covariance('STAGE5_TOEPLITZ_CORRELATED', cfg)};
base_context = struct('plan', stage7_plan, 'cfg', cfg, ...
    'noise_models', {noise_models});
finite = prepare_stage7_finite_sample_context(base_context, methods);
execution = struct('stage7_plan', stage7_plan, 'finite', finite, ...
    'methods', methods, 'stage7_plan_hash', ...
    char(stage7_plan.hashes.stage7_plan_hash), ...
    'context_status', 'FROZEN_STAGE7_CONTEXT_REBUILT_WITHOUT_FIM');
clear temp_cleanup path_cleanup
end

function methods = fixed_edge_methods_local(family)
method_id = ["FIXED_RECT_3X5";"GREEDY_ETA_080";"FULL_PARENT_5X5"];
method_class = ["FIXED_RECTANGLE";"GREEDY_EXACT_FIM";"FULL_PARENT"];
subset_id = ["RECT_E14_A31";"RECT_E28_A31";"RECT_E31_A31"];
rows = cell(numel(method_id), 1);
for index = 1:numel(method_id)
    selected = family(string(family.subset_id) == subset_id(index), :);
    if height(selected) ~= 1
        error('build_stage7_1_execution_context:Subset', ...
            'Expected one frozen row for %s.', subset_id(index));
    end
    row = table2struct(selected);
    row.method_id = method_id(index);
    row.method_class = method_class(index);
    rows{index} = row;
end
methods = struct2table(vertcat(rows{:}));
end

function value = existing_dir_local(value, name)
if isstring(value), value = char(value); end
if ~(ischar(value) && isrow(value) && exist(value, 'dir') == 7)
    error('build_stage7_1_execution_context:Directory', ...
        '%s must identify an existing directory.', name);
end
value = char(java.io.File(value).getCanonicalPath());
end

function remove_temp_local(path_now)
if exist(path_now, 'dir') == 7, rmdir(path_now, 's'); end
end
