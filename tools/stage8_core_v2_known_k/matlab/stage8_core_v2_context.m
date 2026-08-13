function context = stage8_core_v2_context(repo_dir, require_formal_runtime)
%STAGE8_CORE_V2_CONTEXT Load frozen Stage8 data and the R1 read-only bridge.

if nargin < 2, require_formal_runtime = true; end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
tool_dir = fileparts(mfilename('fullpath'));
r1_dir = fullfile(repo_dir, 'tools', 'stage8_r1_continuous_decisive', ...
    'matlab');
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(tool_dir);
addpath(r1_dir);
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>

base = stage8_r1_context(repo_dir, require_formal_runtime);
constants = stage8_core_v2_constants();
k2_contract = constants.k2_solver_contract;
k2_hash = stage8_stable_hash( ...
    'STAGE8_CORE_V2_K2_CENTER_DIFFERENCE_SOLVER_CONTRACT_V2', ...
    k2_contract);
context = base;
context.constants = constants;
context.r1_constants = base.constants;
context.k1_solver_contract_hash = base.solver_contract_hash;
context.k2_solver_contract = k2_contract;
context.k2_solver_contract_hash = k2_hash;
context.tool_dir = tool_dir;
context.r1_tool_dir = r1_dir;
context.registry = stage8_core_v2_registry(context, 'FORMAL');
clear path_cleanup
end
