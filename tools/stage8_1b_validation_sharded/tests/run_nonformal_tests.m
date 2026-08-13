function results = run_nonformal_tests(repo_dir, opts)
%RUN_NONFORMAL_TESTS Run tool tests before the formal protocol commit.

if nargin < 2 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'run_scientific_smoke')
    opts.run_scientific_smoke = true;
end
tool_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(tool_root, 'matlab'));
addpath(fullfile(tool_root, 'tests'));
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
results = struct();
results.single_worker_checkpoint_resume = ...
    test_single_worker_checkpoint_resume();
results.sharded_serial_parallel_equivalence = ...
    test_sharded_serial_parallel_equivalence();
results.checkpoint_pause_resume = test_checkpoint_pause_resume();
if opts.run_scientific_smoke
    results.external_runner_matches_reference = ...
        test_external_runner_matches_reference(repo_dir);
else
    results.external_runner_matches_reference = ...
        struct('pass', true, 'status', 'DEFERRED_TO_FORMAL_GATE1');
end
assert(all(structfun(@(value) logical(value.pass), results)));
fprintf('STAGE8_1B_NONFORMAL_TESTS=PASS\n');
clear path_cleanup
end
