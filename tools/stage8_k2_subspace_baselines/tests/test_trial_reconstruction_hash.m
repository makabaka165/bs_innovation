function result = test_trial_reconstruction_hash(context)
%TEST_TRIAL_RECONSTRUCTION_HASH Verify all 72 frozen element observations.

if nargin < 1, context = []; end
[context, cleanup] = context_local(context); %#ok<ASGLU>
matches = false(height(context.registry), 1);
for index = 1:height(context.registry)
    trial = stage8_k2_cb_generate_trial( ...
        context.registry(index, :), context.cb_context);
    matches(index) = trial.element_hash_match_flag && ...
        trial.element_trial_hash == ...
        context.cb_context.frozen_trial_identity.element_trial_hash(index);
end
assert(all(matches) && nnz(matches) == 72, ...
    'test_trial_reconstruction_hash:Mismatch', ...
    'Not all 72 reconstructed element hashes match evidence 31.');
result = struct('pass', true, 'matched_count', nnz(matches));
end

function [context, cleanup] = context_local(context)
cleanup = [];
if nargin < 1 || isempty(context)
    test_dir = fileparts(mfilename('fullpath'));
    repo_dir = fileparts(fileparts(fileparts(test_dir)));
    cleanup = stage8_k2_sb_add_paths(repo_dir);
    context = stage8_k2_sb_build_context(repo_dir);
end
end
