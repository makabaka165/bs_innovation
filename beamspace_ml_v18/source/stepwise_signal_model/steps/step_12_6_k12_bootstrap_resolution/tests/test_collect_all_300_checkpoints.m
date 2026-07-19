function result = test_collect_all_300_checkpoints(plan)
%TEST_COLLECT_ALL_300_CHECKPOINTS Collect complete multi-shard checkpoints.

if nargin < 1, plan = build_stage8_calibration_plan(); end
contract = build_stage8_1a_checkpoint_contract(plan);
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
write_stage8_checkpoint_fixture(folder, plan, contract, (1:150).', 'A');
write_stage8_checkpoint_fixture(folder, plan, contract, (151:300).', 'B');
[artifacts, manifest] = collect_stage8_1_cell_artifacts( ...
    folder, plan, contract);
pass = numel(artifacts) == 300 && height(manifest) == 300 && ...
    isequal([artifacts.global_cell_index].', (1:300).');
assert(pass, 'test_collect_all_300_checkpoints:Failed', ...
    'The collector did not recover all 300 checkpoints exactly once.');
result = table(pass, height(manifest), ...
    'VariableNames', {'pass_flag','checkpoint_count'});
clear cleanup
end
