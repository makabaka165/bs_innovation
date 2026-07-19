function cleanup = stage8_runtime_path_scope()
%STAGE8_RUNTIME_PATH_SCOPE Add frozen dependencies for one runner call.

step_dir = fileparts(mfilename('fullpath'));
steps_dir = fileparts(step_dir);
project_dir = fileparts(steps_dir);
old_path = path;
cleanup = onCleanup(@() path(old_path));
addpath(fullfile(project_dir, 'core', 'config'));
addpath(fullfile(project_dir, 'core', 'array'));
addpath(fullfile(steps_dir, 'step_12_0_receive_model_correction', 'common'));
addpath(fullfile(steps_dir, 'step_12_1_sequential_dbf_model', 'common'));
addpath(fullfile(steps_dir, 'step_12_2_stable_dml_backend', 'common'));
addpath(fullfile(steps_dir, 'step_12_3_grouped_conditional_dml', 'common'));
addpath(fullfile(steps_dir, ...
    'step_12_4_near_pair_tangent_asymptotics', 'common'));
addpath(fullfile(steps_dir, ...
    'step_12_5_exact_subset_fim_beam_design', 'common'));
addpath(step_dir);
addpath(fullfile(step_dir, 'common'));
end
