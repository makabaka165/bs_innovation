function result = test_missing_checkpoint_fails(plan)
%TEST_MISSING_CHECKPOINT_FAILS Reject an incomplete checkpoint root.

if nargin < 1, plan = build_stage8_calibration_plan(); end
contract = build_stage8_1a_checkpoint_contract(plan);
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
write_stage8_checkpoint_fixture(folder, plan, contract, (1:299).');
stage8_assert_error(@() collect_stage8_1_cell_artifacts( ...
    folder, plan, contract), ...
    'collect_stage8_1_cell_artifacts:MissingCheckpoint');
pass = true;
result = table(pass, 'VariableNames', {'pass_flag'});
clear cleanup
end
