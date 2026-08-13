function output = run_step12_7_known_k_local_cell_refinement(action, runtime_root)
%RUN_STEP12_7_KNOWN_K_LOCAL_CELL_REFINEMENT One MATLAB final-run command.

if nargin < 1 || isempty(action), action = 'Status'; end
if nargin < 2, runtime_root = ''; end
step_dir = fileparts(mfilename('fullpath'));
steps_dir = fileparts(step_dir);
repo_dir = fileparts(fileparts(fileparts(fileparts(steps_dir))));
path_before = path;
cleanup = onCleanup(@() path(path_before));
addpath(fullfile(step_dir, 'common'));
addpath(fullfile(step_dir, 'tests'));
addpath(fullfile(step_dir, 'validation'));
frozen_step = fullfile(steps_dir, 'step_12_6_k12_bootstrap_resolution');
addpath(frozen_step);
frozen_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
output = run_stage8_core_v2_2_final_validation(repo_dir, runtime_root, action);
end
