function result = test_calibration_rejects_rank_deficient_fit()
%TEST_CALIBRATION_REJECTS_RANK_DEFICIENT_FIT Reject insufficient rank.

fixture = build_stage8_1a_mini_fixture();
cell_input = build_stage8_1a_mini_cell(fixture, 2);
[artifact, ~] = run_stage8_1_calibration_cell( ...
    cell_input, fixture.domain, fixture.registry, fixture.stage5_locked, ...
    options_local(@fit_local));
pass = strcmp(artifact.status, 'CALIBRATION_CELL_REFIT_FAILURE') && ...
    artifact.failure_details.failure_status(1) == "NUMERIC_RANK_DEFICIENT";
assert(pass, 'test_calibration_rejects_rank_deficient_fit:Failed', ...
    'A rank-deficient bootstrap fit was accepted.');
result = table(pass, 'VariableNames', {'pass_flag'});
end

function [fit, debug] = fit_local(K, index, data, context, model)
[fit, debug] = stage8_1a_mock_fit_callback(K, index, data, context, model);
if K == 2 && index == 1
    fit.effective_rank = 1;
end
end

function opts = options_local(callback)
opts = struct('Bboot_per_cell', 2, 'fit_callback', callback, ...
    'initialization_callback', @stage8_1a_mini_initialization_callback);
end
