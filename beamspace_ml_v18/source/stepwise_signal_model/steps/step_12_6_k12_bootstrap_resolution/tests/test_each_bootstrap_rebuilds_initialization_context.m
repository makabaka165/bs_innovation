function result = test_each_bootstrap_rebuilds_initialization_context()
%TEST_EACH_BOOTSTRAP_REBUILDS_INITIALIZATION_CONTEXT Audit rebuild count.

fixture = build_stage8_1a_mini_fixture();
cell_input = build_stage8_1a_mini_cell(fixture, 2);
[artifact, ~] = run_stage8_1_calibration_cell( ...
    cell_input, fixture.domain, fixture.registry, fixture.stage5_locked, ...
    miniature_options_local(@stage8_1a_mock_fit_callback));
pass = strcmp(artifact.status, 'CALIBRATION_CELL_PASS') && ...
    artifact.initialization_factory_rebuild_count == 3;
assert(pass, 'test_each_bootstrap_rebuilds_initialization_context:Failed', ...
    'Original data and every bootstrap sample must rebuild initialization.');
result = table(pass, artifact.initialization_factory_rebuild_count, ...
    'VariableNames', {'pass_flag','factory_rebuild_count'});
end

function opts = miniature_options_local(callback)
opts = struct('Bboot_per_cell', 2, 'fit_callback', callback, ...
    'initialization_callback', @stage8_1a_mini_initialization_callback);
end
