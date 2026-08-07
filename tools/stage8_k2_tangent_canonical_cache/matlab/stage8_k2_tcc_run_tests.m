function summary = stage8_k2_tcc_run_tests(repo_dir)
%STAGE8_K2_TCC_RUN_TESTS Run the compact Level-A MATLAB tests.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_tcc_run_tests:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
scope = stage8_k2_tcc_add_paths(repo_dir); %#ok<NASGU>
test_names = { ...
    'test_direct_g_only_matches_full_manifold'; ...
    'test_factor1_rotation_equivalence'; ...
    'test_exact_cache_matches_direct_g'; ...
    'test_pair_manifold_mixed_provider'; ...
    'test_profile_score_equivalence'; ...
    'test_cache_identity_rejection'};
rows = repmat(struct('test_name', "", 'pass', false, ...
    'runtime_sec', 0, 'message', ""), numel(test_names), 1);
for index = 1:numel(test_names)
    rows(index).test_name = string(test_names{index});
    clock = tic;
    try
        result = feval(test_names{index});
        rows(index).pass = isstruct(result) && isfield(result, 'pass') && ...
            logical(result.pass);
        if ~rows(index).pass
            rows(index).message = "TEST_RETURNED_FALSE";
        end
    catch exception
        rows(index).pass = false;
        rows(index).message = string(exception.identifier) + ": " + ...
            string(exception.message);
    end
    rows(index).runtime_sec = toc(clock);
end
summary = struct2table(rows);
disp(summary);
if ~all(summary.pass)
    error('stage8_k2_tcc_run_tests:Failed', ...
        '%d of %d TCC tests failed.', nnz(~summary.pass), height(summary));
end
fprintf('STAGE8_K2_TCC_TESTS_PASS %d/%d\n', ...
    nnz(summary.pass), height(summary));
end
