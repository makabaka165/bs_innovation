function context = stage8_compact_context(repo_dir, formal_run)
%STAGE8_COMPACT_CONTEXT Load the frozen Stage8 context through old helpers.

if nargin < 2, formal_run = true; end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
old_tools = fullfile(repo_dir, 'tools', 'stage8_1b_validation_sharded', ...
    'matlab');
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(old_tools);
addpath(step);
context = stage8_1b_frozen_context(repo_dir, logical(formal_run));
context.compact_constants = stage8_compact_constants();
context.compact_registry = stage8_compact_build_registry(context);
end
