function result = test_gfbss_music_fixture(context)
%TEST_GFBSS_MUSIC_FIXTURE Verify two peaks for white and colored noise.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
noise_ids = ["WHITE", "STAGE5_TOEPLITZ_CORRELATED"];
estimates = NaN(2, 2);
for index = 1:numel(noise_ids)
    fixture = stage8_k2_sb_test_vertical_fixture(context, noise_ids(index));
    fit = stage8_k2_sb_gfbss_music(fixture.R_fb, ...
        fixture.R_noise_subarray, fixture.model, context.constants);
    assert(fit.fit_valid && all(isfinite(fit.elevations_hat_deg)) && ...
        max(abs(fit.elevations_hat_deg - fixture.theta_deg)) <= 0.005, ...
        'test_gfbss_music_fixture:Estimate', ...
        'GFBSS-MUSIC did not recover both fixture elevations.');
    estimates(index, :) = fit.elevations_hat_deg;
end
result = struct('pass', true, 'estimates_deg', estimates);
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
