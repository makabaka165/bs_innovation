function result = test_calibration_rejects_nonconverged_k2()
%TEST_CALIBRATION_REJECTS_NONCONVERGED_K2 Reject a bootstrap K2 fit.

fixture = build_stage8_1a_mini_fixture();
cell_input = build_stage8_1a_mini_cell(fixture, 2);
[artifact, ~] = run_stage8_1_calibration_cell( ...
    cell_input, fixture.domain, fixture.registry, fixture.stage5_locked, ...
    options_local(@fit_local));
pass = strcmp(artifact.status, 'CALIBRATION_CELL_REFIT_FAILURE') && ...
    artifact.failure_details.model_K(1) == 2 && ...
    artifact.failure_details.failure_status(1) == "SEARCH_NOT_CONVERGED";
assert(pass, 'test_calibration_rejects_nonconverged_k2:Failed', ...
    'A nonconverged bootstrap K2 fit was accepted.');
result = table(pass, 'VariableNames', {'pass_flag'});
end

function [fit, debug] = fit_local(K, index, data, context, model)
[fit, debug] = stage8_1a_mock_fit_callback(K, index, data, context, model);
if K == 2 && index == 1
    fit.converged_flag = false;
    fit.fit_status = 'JOINT_REFINEMENT_MAX_ITER';
end
end

function opts = options_local(callback)
opts = struct('Bboot_per_cell', 2, 'fit_callback', callback, ...
    'initialization_callback', @stage8_1a_mini_initialization_callback);
end
