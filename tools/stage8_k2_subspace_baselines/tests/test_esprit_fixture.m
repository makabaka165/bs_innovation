function result = test_esprit_fixture(context)
%TEST_ESPRIT_FIXTURE Verify lambda=exp(+j*k0*dz*sin(theta)).

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
fixture = stage8_k2_sb_test_vertical_fixture(context, "WHITE");
fit = stage8_k2_sb_ls_esprit(fixture.R_fb, ...
    fixture.model, context.constants);
expected_phase = sort(2 * pi / fixture.model.lambda * ...
    fixture.model.array_configuration.arr.dz * sind(fixture.theta_deg));
actual_phase = sort(angle(fit.esprit_eigenvalues));
assert(fit.fit_valid && ...
    max(abs(fit.elevations_hat_deg - fixture.theta_deg)) <= 0.005 && ...
    max(abs(actual_phase - expected_phase)) <= 1e-4, ...
    'test_esprit_fixture:Estimate', ...
    'LS-ESPRIT violates the registered positive-phase convention.');
result = struct('pass', true, 'estimates_deg', fit.elevations_hat_deg, ...
    'eigenvalues', fit.esprit_eigenvalues);
end

function [context, cleanup] = context_local(context)
cleanup = [];
if nargin < 1 || isempty(context)
    test_dir = fileparts(mfilename('fullpath'));
    repo_dir = fileparts(fileparts(fileparts(test_dir)));
    cleanup = stage8_k2_sb_add_paths(repo_dir);
    context = stage8_k2_sb_build_context(repo_dir);
end
end
