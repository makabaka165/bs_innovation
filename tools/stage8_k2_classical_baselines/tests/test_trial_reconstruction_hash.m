function result = test_trial_reconstruction_hash()
%TEST_TRIAL_RECONSTRUCTION_HASH Verify all 72 frozen element observations.

[repo_dir, scope] = setup_local(); %#ok<ASGLU>
context = stage8_k2_cb_build_context(repo_dir);
registry = stage8_k2_cb_build_registry(context);
matches = false(height(registry), 1);
for index = 1:height(registry)
    trial = stage8_k2_cb_generate_trial(registry(index, :), context);
    matches(index) = trial.element_hash_match_flag && ...
        trial.element_trial_hash == ...
        context.frozen_trial_identity.element_trial_hash(index);
end
assert(all(matches) && nnz(matches) == 72, ...
    'test_trial_reconstruction_hash:Mismatch', ...
    'Not all 72 reconstructed element hashes match evidence 31.');
result = struct('pass', true, 'matched_count', nnz(matches));
fprintf('test_trial_reconstruction_hash PASS 72/72\n');
end

function [repo_dir, scope] = setup_local()
test_dir = fileparts(mfilename('fullpath'));
repo_dir = fileparts(fileparts(fileparts(test_dir)));
scope = stage8_k2_cb_add_paths(repo_dir);
end
