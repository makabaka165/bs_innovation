function result = test_compact_worker_equivalence()
%TEST_COMPACT_WORKER_EQUIVALENCE Verify modulo sharding has exact coverage.

tool_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(tool_root, 'matlab'));
L = [1;1;4;4;8;8];
noise_profile_id = ["WHITE";"STAGE5_TOEPLITZ_CORRELATED"; ...
    "WHITE";"STAGE5_TOEPLITZ_CORRELATED"; ...
    "WHITE";"STAGE5_TOEPLITZ_CORRELATED"];
stratum_index = (1:6).';
stratum_id = "S" + string(stratum_index);
strata = table(stratum_index, stratum_id, L, noise_profile_id);
context = struct('plan', struct('validation', ...
    struct('K1', struct('strata', strata))));
registry = stage8_compact_build_registry(context);
assert(height(registry) == 108);
assert(sum(registry.expected_row_count) == 180);
reference = sort(double(registry.global_trial_index));
for worker_count = 1:4
    assigned = cell(worker_count, 1);
    for worker_id = 1:worker_count
        mask = mod(registry.global_trial_index - 1, worker_count) == ...
            worker_id - 1;
        assigned{worker_id} = double(registry.global_trial_index(mask));
    end
    combined = sort(vertcat(assigned{:}));
    assert(isequal(combined, reference));
    assert(numel(unique(combined)) == 108);
end
result = struct('pass', true, 'element_trial_count', 108, ...
    'row_count', 180, 'worker_counts_checked', 1:4);
end
