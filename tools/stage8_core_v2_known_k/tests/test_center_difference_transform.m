function result = test_center_difference_transform()
%TEST_CENTER_DIFFERENCE_TRANSFORM Verify the K2 coordinate contract.

repo = char(java.io.File(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))).getCanonicalPath());
addpath(fullfile(repo, 'beamspace_ml_v18', 'source', 'stepwise_signal_model', 'steps', 'step_12_6_k12_bootstrap_resolution'));
cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
[context, ~, data, model, domain] = fixture_local();
initialization = build_initialization_local(data, model, domain, context);
angles = initialization.grouped_q1_kq2_angles_deg;
[estimate, ~, debug] = stage8_core_v2_k2_center_difference_solver( ...
    data, angles, domain, model, struct());
assert(isequal(size(debug.initial_c), [1, 2]));
assert(isequal(size(debug.initial_d), [1, 2]));
assert(debug.initial_d(2) > 0 || ...
    (abs(debug.initial_d(2)) <= 1e-12 && debug.initial_d(1) >= 0));
assert(all(isfinite(estimate.angles_hat_deg(:))));
assert(all(estimate.angles_hat_deg(:, 1) >= domain.domain_bounds_deg(1) & ...
    estimate.angles_hat_deg(:, 1) <= domain.domain_bounds_deg(2)));
assert(all(estimate.angles_hat_deg(:, 2) >= domain.domain_bounds_deg(3) & ...
    estimate.angles_hat_deg(:, 2) <= domain.domain_bounds_deg(4)));
assert(norm(diff(estimate.angles_hat_deg, 1, 1)) >= ...
    stage8_core_v2_constants().k2_solver_contract.minimum_separation_deg);
result = true;
end

function [context, spec, data, model, domain] = fixture_local()
[context, spec, trial, data, model, domain] = build_fixture_local(); %#ok<ASGLU>
end

function [context, spec, trial, data, model, domain] = build_fixture_local()
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

function initialization = build_initialization_local(data, model, domain, context)
[initialization, ~] = build_stage8_initialization_context_from_data( ...
    data, model, domain, context.stage5_locked, model.noise_factorization, struct());
end
