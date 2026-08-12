function summary = stage8_k2_mc_run_evidence_tests(repo_dir, runtime_root)
%STAGE8_K2_MC_RUN_EVIDENCE_TESTS Run the four corrected-evidence tests.

if nargin < 1 || isempty(repo_dir)
    [status, repo_dir] = system('git rev-parse --show-toplevel');
    if status ~= 0
        error('stage8_k2_mc_run_evidence_tests:Repository', ...
            'Unable to locate the repository root.');
    end
    repo_dir = strtrim(repo_dir);
end
if nargin < 2 || isempty(runtime_root)
    runtime_root = ...
        'E:\bs_innovation_runtime\stage8_k2_cylindrical_multicenter_cache_v1';
end
repo_dir = char(java.io.File(char(string(repo_dir))).getCanonicalPath());
runtime_root = char(java.io.File(char(string(runtime_root))).getCanonicalPath());
scope = stage8_k2_mc_add_paths(repo_dir); %#ok<NASGU>
fixture = stage8_k2_mc_build_context( ...
    repo_dir,'',struct('include_trials',false));
static_loaded = load(fullfile(runtime_root,'static', ...
    'static_output.mat'),'output');
whitener = stage8_k2_mc_whitener_basis_diagnostics(repo_dir,fixture.spec);
static_metrics = stage8_k2_mc_static_metric_table( ...
    static_loaded.output,whitener);
manifest_path = fullfile(repo_dir,'innovation-mining', ...
    '55_stage8_k2_cylindrical_multicenter_cache_manifest.json');
if ~isfile(manifest_path)
    error('stage8_k2_mc_run_evidence_tests:Manifest', ...
        'Corrected manifest must be written before evidence tests.');
end
manifest = jsondecode(fileread(manifest_path));
outputs = struct('repo_dir',repo_dir,'runtime_root',runtime_root, ...
    'static',static_loaded.output,'whitener',whitener, ...
    'static_metrics',static_metrics,'manifest',manifest);

test_names = { ...
    'test_stage8_k2_mc_evidence_reference_dynamic'; ...
    'test_stage8_k2_mc_whitener_basis_invariance'; ...
    'test_stage8_k2_mc_manifest_provenance_fields'; ...
    'test_stage8_k2_mc_static_metric_roles'};
rows = repmat(struct('test_name',"",'pass',false, ...
    'runtime_sec',0,'message',""),numel(test_names),1);
for index = 1:numel(test_names)
    rows(index).test_name = string(test_names{index});
    clock = tic;
    try
        value = feval(test_names{index},fixture,outputs);
        rows(index).pass = isstruct(value) && isfield(value,'pass') && ...
            logical(value.pass);
        if ~rows(index).pass
            rows(index).message = "TEST_RETURNED_FALSE";
        end
    catch exception
        rows(index).message = string(exception.identifier) + ": " + ...
            string(exception.message);
    end
    rows(index).runtime_sec = toc(clock);
end
summary = struct2table(rows);
disp(summary);
if ~all(summary.pass)
    error('stage8_k2_mc_run_evidence_tests:Failed', ...
        '%d of %d evidence tests failed.', ...
        nnz(~summary.pass),height(summary));
end
fprintf('STAGE8_K2_MC_EVIDENCE_TESTS_PASS %d/%d\n', ...
    nnz(summary.pass),height(summary));
end
