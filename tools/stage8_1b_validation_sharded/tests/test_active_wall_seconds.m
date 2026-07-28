function result = test_active_wall_seconds()
%TEST_ACTIVE_WALL_SECONDS Verify overlap union and paused-gap exclusion.

root = tempname;
workers = fullfile(root, 'workers');
mkdir(workers);
cleanup = onCleanup(@() rmdir(root, 's'));
write_attempt_local(workers, 1, ...
    '2026-07-27T00:00:00.000Z', '2026-07-27T00:00:10.000Z', 'COMPLETE');
write_attempt_local(workers, 2, ...
    '2026-07-27T00:00:05.000Z', '2026-07-27T00:00:15.000Z', 'ERROR_STOPPED');
write_attempt_local(workers, 3, ...
    '2026-07-27T00:00:20.000Z', '2026-07-27T00:00:25.000Z', 'PAUSED_SAFE');
actual = stage8_1b_active_wall_seconds(root);
assert(isnumeric(actual) && isscalar(actual) && actual == 20);
result = struct('pass', true, 'active_wall_sec', actual, ...
    'paused_gap_sec', 5);
clear cleanup
end

function write_attempt_local(root, index, started, ended, status)
value = struct('attempt_id', sprintf('UNIT_%d', index), ...
    'worker_id', index, 'pid', index, 'started_utc', started, ...
    'ended_utc', ended, 'completion_status', status);
stage8_1b_write_json_atomic(fullfile(root, ...
    sprintf('attempt_%02d_UNIT.json', index)), value);
end
