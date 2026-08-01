function result = test_conditional_az_cml_fixture(context, resources)
%TEST_CONDITIONAL_AZ_CML_FIXTURE Recover two azimuths at fixed elevations.

if nargin < 1, context = []; end
if nargin < 2, resources = []; end
[context, resources, cleanup] = context_local(context, resources); %#ok<ASGLU>
entry = resources.entries([resources.entries.noise_profile_id] == "WHITE");
truth = [7.80, 9.90; 8.30, 10.10];
A_white = stage8_k2_cb_build_element_manifold( ...
    truth, entry.model, entry.whitening);
source = [1, 0.4 + 0.2j, -0.3 + 0.7j, 0.8 - 0.1j; ...
    0.2 - 0.6j, 0.9, 0.5 + 0.3j, -0.4 + 0.2j];
sample_index = (1:size(A_white, 1)).';
noise = 1e-3 * exp(1j * 0.017 * sample_index) * [1, -1j, -1, 1j];
Y_white = A_white * source + noise;
fit = stage8_k2_sb_conditional_az_cml(Y_white, truth(:, 2).', ...
    entry.model, entry.whitening, context.constants);
assert(fit.fit_valid && max(abs(fit.azimuths_hat_deg - truth(:, 1).')) ...
    <= 0.01 && fit.coarse_candidate_count == 3721, ...
    'test_conditional_az_cml_fixture:Estimate', ...
    'Conditional full-element CML did not recover the fixture azimuths.');
result = struct('pass', true, ...
    'azimuths_hat_deg', fit.azimuths_hat_deg, ...
    'score_call_count', fit.score_call_count);
end

function [context, resources, cleanup] = context_local(context, resources)
cleanup = [];
if nargin < 1 || isempty(context)
    test_dir = fileparts(mfilename('fullpath'));
    repo_dir = fileparts(fileparts(fileparts(test_dir)));
    cleanup = stage8_k2_sb_add_paths(repo_dir);
    context = stage8_k2_sb_build_context(repo_dir);
end
if nargin < 2 || isempty(resources)
    resources = stage8_k2_sb_prepare_resources(context);
end
end
