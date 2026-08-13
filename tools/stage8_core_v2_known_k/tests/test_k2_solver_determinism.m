function result = test_k2_solver_determinism()
%TEST_K2_SOLVER_DETERMINISM Repeat a K2 start and compare scientific bits.

repo = char(java.io.File(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))).getCanonicalPath());
addpath(fullfile(repo, 'beamspace_ml_v18', 'source', 'stepwise_signal_model', 'steps', 'step_12_6_k12_bootstrap_resolution'));
cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
[context, ~, data, model, domain] = fixture_local();
[initialization, ~] = build_stage8_initialization_context_from_data( ...
    data, model, domain, context.stage5_locked, model.noise_factorization, struct());
start = initialization.grouped_q1_kq2_angles_deg;
[a, h1, d1] = stage8_core_v2_k2_center_difference_solver( ...
    data, start, domain, model, struct());
[b, h2, d2] = stage8_core_v2_k2_center_difference_solver( ...
    data, start, domain, model, struct());
assert(isequal(num2hex(a.angles_hat_deg), num2hex(b.angles_hat_deg)));
assert(isequal(num2hex(a.final_score), num2hex(b.final_score)));
assert(strcmp(stage8_stable_hash(h1), stage8_stable_hash(h2)));
assert(strcmp(stage8_stable_hash(d1), stage8_stable_hash(d2)));
result = true;
end

function [context, spec, data, model, domain] = fixture_local()
repo = char(java.io.File(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))).getCanonicalPath());
tool = fullfile(repo, 'tools', 'stage8_core_v2_known_k', 'matlab');
step = fullfile(repo, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', 'step_12_6_k12_bootstrap_resolution');
addpath(tool); addpath(step);
context = stage8_core_v2_context(repo, false);
registry = stage8_core_v2_registry(context, 'GATES');
spec = registry(registry.truth_K == 2, :);
trial = stage8_r1_generate_trial(spec, context);
data = build_stage8_full_data_from_element(trial.Y_element, trial.model, struct( ...
    'data_role', 'STAGE8_CORE_V2_TEST_FIXTURE'));
model = trial.model; domain = context.plan.local_domain;
end
