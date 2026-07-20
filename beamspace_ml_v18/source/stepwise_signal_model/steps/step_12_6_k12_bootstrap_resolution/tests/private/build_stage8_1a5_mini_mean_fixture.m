function fixture = build_stage8_1a5_mini_mean_fixture()
%BUILD_STAGE8_1A5_MINI_MEAN_FIXTURE Build one reusable miniature fit.

mini = build_stage8_1a_mini_fixture();
[context, ~] = stage8_1a_mini_initialization_callback( ...
    mini.full_k1, mini.model, mini.domain);
[fit, ~] = stage8_1a_mock_fit_callback( ...
    1, 0, mini.full_k1, context, mini.model);
evaluation = evaluate_stage8_bootstrap_mean_identity(fit, mini.model);
fixture = struct('mini', mini, 'context', context, 'fit', fit, ...
    'evaluation', evaluation, 'phase_factor', 1);
end
