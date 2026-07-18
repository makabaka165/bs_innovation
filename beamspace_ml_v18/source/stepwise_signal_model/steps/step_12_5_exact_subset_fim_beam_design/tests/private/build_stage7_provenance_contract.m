function contract = build_stage7_provenance_contract( ...
    repo_dir, plan_inputs, opts)
%BUILD_STAGE7_PROVENANCE_CONTRACT Bind stable Git and plan identities.

if nargin < 3 || isempty(opts), opts = struct(); end
opts = normalize_options_local(opts);
validate_inputs_local(plan_inputs);

git_provenance = read_stage7_git_provenance(repo_dir, ...
    plan_inputs.baseline_commit, opts.git_provenance_options);
scope = collect_stage7_source_scope(repo_dir, struct());
[source_manifest, source_tree_hash] = build_stage7_git_blob_manifest( ...
    repo_dir, scope.source_paths, scope.source_scope_version, struct());
[dependency_manifest, dependency_tree_hash] = ...
    build_stage7_git_blob_manifest(repo_dir, scope.dependency_paths, ...
    scope.dependency_scope_version, struct());

provenance_hash = stage7_stable_hash( ...
    plan_inputs.baseline_commit, source_tree_hash, dependency_tree_hash, ...
    plan_inputs.stable_plan_hashes, ...
    plan_inputs.stage6_evidence_bundle_hash, plan_inputs.phase_factor, ...
    plan_inputs.matlab_release_contract, ...
    'STAGE7_PROVENANCE_CONTRACT_V1');

contract = struct();
contract.baseline_commit = plan_inputs.baseline_commit;
contract.runtime_head_commit = git_provenance.runtime_head_commit;
contract.origin_main_commit = git_provenance.origin_main_commit;
contract.baseline_ancestor_flag = git_provenance.baseline_ancestor_flag;
contract.working_tree_clean_at_start = ...
    git_provenance.working_tree_clean_flag;
contract.git_status_porcelain = git_provenance.git_status_porcelain;
contract.provenance_status = git_provenance.provenance_status;
contract.stage7_source_tree_hash = source_tree_hash;
contract.stage7_dependency_tree_hash = dependency_tree_hash;
contract.stage7_provenance_hash = provenance_hash;
contract.source_manifest = source_manifest;
contract.dependency_manifest = dependency_manifest;
contract.source_scope_version = scope.source_scope_version;
contract.dependency_scope_version = scope.dependency_scope_version;
contract.provenance_contract_version = 'STAGE7_PROVENANCE_CONTRACT_V1';
contract.matlab_release_contract = plan_inputs.matlab_release_contract;
contract.phase_factor = plan_inputs.phase_factor;
end

function opts = normalize_options_local(opts)
if ~(isstruct(opts) && isscalar(opts))
    error('build_stage7_provenance_contract:Options', ...
        'opts must be a scalar struct.');
end
allowed = {'git_provenance_options'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('build_stage7_provenance_contract:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfield(opts, 'git_provenance_options')
    opts.git_provenance_options = struct();
end
end

function validate_inputs_local(inputs)
required = {'baseline_commit','stable_plan_hashes', ...
    'stage6_evidence_bundle_hash','phase_factor', ...
    'matlab_release_contract'};
if ~(isstruct(inputs) && isscalar(inputs) && all(isfield(inputs, required)))
    error('build_stage7_provenance_contract:Inputs', ...
        'plan_inputs is missing a stable identity object.');
end
if inputs.phase_factor ~= 1
    error('build_stage7_provenance_contract:PhaseFactor', ...
        'Stage 7 provenance requires phase_factor=1.');
end
end
