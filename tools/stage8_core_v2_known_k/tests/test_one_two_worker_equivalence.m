function result = test_one_two_worker_equivalence()
%TEST_ONE_TWO_WORKER_EQUIVALENCE Compare scientific rows in two orderings.

repo = char(java.io.File(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))).getCanonicalPath());
addpath(fullfile(repo, 'beamspace_ml_v18', 'source', 'stepwise_signal_model', 'steps', 'step_12_6_k12_bootstrap_resolution'));
cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
[context, registry] = fixture_context_local();
rows_one = cell(height(registry), 1);
rows_two = cell(height(registry), 1);
for index = 1:height(registry)
    [rows_one{index}, ~] = stage8_core_v2_evaluate_trial(registry(index, :), context);
end
for index = height(registry):-1:1
    [rows_two{index}, ~] = stage8_core_v2_evaluate_trial(registry(index, :), context);
end
one = sortrows(vertcat(rows_one{:}), {'global_trial_index','method_id'});
two = sortrows(vertcat(rows_two{:}), {'global_trial_index','method_id'});
one.runtime_sec(:) = 0; two.runtime_sec(:) = 0;
assert(strcmp(stage8_stable_hash(one), stage8_stable_hash(two)));
assert(isequal(num2hex(one.RSS), num2hex(two.RSS)));
assert(isequal(one.selected_start_id, two.selected_start_id));
assert(isequal(one.solver_status, two.solver_status));
result = true;
end

function [context, registry] = fixture_context_local()
repo = char(java.io.File(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))).getCanonicalPath());
tool = fullfile(repo, 'tools', 'stage8_core_v2_known_k', 'matlab');
step = fullfile(repo, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', 'step_12_6_k12_bootstrap_resolution');
addpath(tool); addpath(step);
context = stage8_core_v2_context(repo, false);
registry = stage8_core_v2_registry(context, 'GATES');
end
