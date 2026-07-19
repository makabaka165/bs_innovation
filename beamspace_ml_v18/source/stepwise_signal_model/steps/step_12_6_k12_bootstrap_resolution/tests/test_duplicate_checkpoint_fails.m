function result = test_duplicate_checkpoint_fails(plan)
%TEST_DUPLICATE_CHECKPOINT_FAILS Reject duplicate cell checkpoint identity.

if nargin < 1, plan = build_stage8_calibration_plan(); end
contract = build_stage8_1a_checkpoint_contract(plan);
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
write_stage8_checkpoint_fixture(folder, plan, contract, (1:300).', 'A');
write_stage8_checkpoint_fixture(folder, plan, contract, 1, 'B');
stage8_assert_error(@() collect_stage8_1_cell_artifacts( ...
    folder, plan, contract), ...
    'collect_stage8_1_cell_artifacts:DuplicateCheckpoint');
pass = true;
result = table(pass, 'VariableNames', {'pass_flag'});
clear cleanup
end
