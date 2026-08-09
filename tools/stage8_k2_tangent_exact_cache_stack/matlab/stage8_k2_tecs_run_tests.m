function summary = stage8_k2_tecs_run_tests(repo_dir, runtime_root)
%STAGE8_K2_TECS_RUN_TESTS Run exact-cache contracts and frozen regressions.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0, error('stage8_k2_tecs_run_tests:Repository', ...
            'Unable to locate repository.'); end
    repo_dir = strtrim(repo_dir);
end
if nargin < 2 || isempty(runtime_root)
    runtime_root = ...
        'E:\bs_innovation_runtime\stage8_k2_tangent_exact_cache_stack_v1';
end
scope = stage8_k2_tecs_add_paths(repo_dir); %#ok<NASGU>
clock = tic;
tcc = stage8_k2_tcc_run_tests(repo_dir);
assert(height(tcc) == 8 && all(tcc.pass));
parts = { ...
    test_stage8_k2_tecs_key_contract(); ...
    test_stage8_k2_tecs_session_contract(runtime_root); ...
    test_stage8_k2_tecs_c1_static(repo_dir, runtime_root); ...
    test_stage8_k2_tecs_component_protocol(repo_dir, runtime_root)};
summary = vertcat(parts{:});
summary.runtime_sec = repmat(toc(clock), height(summary), 1);
summary.schema_version = repmat( ...
    "STAGE8_K2_TECS_STATIC_TEST_V1", height(summary), 1);
summary = movevars(summary, 'schema_version', 'Before', 1);
if ~all(summary.pass)
    error('stage8_k2_tecs_run_tests:Failed', ...
        '%d of %d TECS tests failed.', nnz(~summary.pass), height(summary));
end
fprintf('STAGE8_K2_TECS_TESTS_PASS %d/%d; TCC=%d/%d\n', ...
    nnz(summary.pass), height(summary), nnz(tcc.pass), height(tcc));
end
