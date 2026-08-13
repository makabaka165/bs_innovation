function result = test_root_music_fixture(context)
%TEST_ROOT_MUSIC_FIXTURE Verify root selection and positive phase sign.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
fixture = stage8_k2_sb_test_vertical_fixture(context, "WHITE");
fit = stage8_k2_sb_root_music(fixture.R_fb, ...
    fixture.model, context.constants);
assert(fit.fit_valid && ...
    max(abs(fit.elevations_hat_deg - fixture.theta_deg)) <= 0.005 && ...
    all(angle(fit.selected_roots) > 0), ...
    'test_root_music_fixture:Estimate', ...
    'Root-MUSIC roots violate the registered positive-phase convention.');
result = struct('pass', true, 'estimates_deg', fit.elevations_hat_deg, ...
    'selected_roots', fit.selected_roots);
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
