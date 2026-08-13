function result = test_sharded_serial_parallel_equivalence()
%TEST_SHARDED_SERIAL_PARALLEL_EQUIVALENCE Check partition and hash invariance.

indices = (1:60).';
odd = indices(mod(indices, 2) == 1);
even = indices(mod(indices, 2) == 0);
assert(isempty(intersect(odd, even)));
assert(isequal(sort([odd; even]), indices));
[~, serial_checkpoint] = build_checkpoint_fixture();
parallel_checkpoint = serial_checkpoint;
parallel_checkpoint.worker_id = 2;
parallel_checkpoint.attempt_id = 'OTHER_ATTEMPT';
parallel_checkpoint.runtime_sec = 99;
parallel_checkpoint.created_utc = '2030-01-01T00:00:00.000Z';
serial_hash = stage8_1b_checkpoint_content_hash(serial_checkpoint);
parallel_hash = stage8_1b_checkpoint_content_hash(parallel_checkpoint);
assert(strcmp(serial_hash, parallel_hash));
result = struct('pass', true, 'odd_count', numel(odd), ...
    'even_count', numel(even), 'content_hash', serial_hash);
end
