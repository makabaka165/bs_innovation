function result = test_calibration_bootstrap_seed_blocks_unique(plan)
%TEST_CALIBRATION_BOOTSTRAP_SEED_BLOCKS_UNIQUE Check 300 disjoint blocks.

if nargin < 1, plan = build_stage8_calibration_plan(); end
cells = plan.cells;
starts = cells.bootstrap_seed_start;
ends = cells.bootstrap_seed_end;
pass = height(cells) == 300 && all(ends - starts + 1 == 199) && ...
    all(diff(starts) == 1000) && numel(unique(starts)) == 300 && ...
    all(ends(1:end - 1) < starts(2:end));
assert(pass, 'test_calibration_bootstrap_seed_blocks_unique:Failed', ...
    'Calibration bootstrap blocks overlap or violate the frozen formula.');
result = table(pass, numel(starts), ...
    'VariableNames', {'pass_flag','block_count'});
end
