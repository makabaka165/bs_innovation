function [manifest, bundle] = build_stage7_1_evidence_manifest( ...
    step_dir, registry, identity)
%BUILD_STAGE7_1_EVIDENCE_MANIFEST Hash deterministic closure artifacts.

step_dir = existing_dir_local(step_dir);
validate_inputs_local(registry, identity);
n = height(registry);
byte_count = nan(n, 1);
sha256 = strings(n, 1);
file_exists_flag = false(n, 1);
pass_flag = false(n, 1);
for index = 1:n
    relative = safe_relative_path_local(registry.relative_path(index));
    path_now = fullfile(step_dir, char(relative));
    if registry.self_referential_exclusion_flag(index)
        sha256(index) = "SELF_REFERENTIAL_EXCLUSION";
        file_exists_flag(index) = exist(path_now, 'file') == 2;
        pass_flag(index) = true;
        continue;
    end
    file_exists_flag(index) = exist(path_now, 'file') == 2;
    if file_exists_flag(index)
        details = dir(path_now);
        byte_count(index) = details.bytes;
        sha256(index) = sha256_file_local(path_now);
        pass_flag(index) = true;
    else
        sha256(index) = "MISSING";
    end
end
manifest = table(registry.artifact_id, registry.relative_path, ...
    registry.artifact_type, registry.evidence_class, byte_count, sha256, ...
    registry.required_by_closure_runner, ...
    registry.included_in_deterministic_bundle, ...
    registry.self_referential_exclusion_flag, ...
    registry.contains_runtime_metadata, file_exists_flag, pass_flag, ...
    'VariableNames', {'artifact_id','relative_path','artifact_type', ...
    'evidence_class','byte_count','sha256', ...
    'required_by_closure_runner','included_in_deterministic_bundle', ...
    'self_referential_exclusion_flag','contains_runtime_metadata', ...
    'file_exists_flag','pass_flag'});
included = manifest.included_in_deterministic_bundle;
if any(~manifest.file_exists_flag(included)) || ...
        any(manifest.contains_runtime_metadata(included)) || ...
        any(manifest.self_referential_exclusion_flag(included))
    error('build_stage7_1_evidence_manifest:DeterministicScope', ...
        'The deterministic artifact set is incomplete or contaminated.');
end
included_rows = sortrows(manifest(included, :), 'relative_path');
payload = uint8([]);
for index = 1:height(included_rows)
    payload = [payload, utf8_local(included_rows.relative_path(index)), ...
        uint8(0), utf8_local(included_rows.sha256(index)), uint8(0)]; %#ok<AGROW>
end
bundle_hash = sha256_bytes_local(payload);
stage7_1_evidence_bundle_hash = string(bundle_hash);
stage7_1_stable_code_identity_hash = string( ...
    identity.stage7_1_stable_code_identity_hash);
deterministic_artifact_count = height(included_rows);
deterministic_total_bytes = sum(included_rows.byte_count);
excluded_runtime_artifact_count = nnz( ...
    registry.contains_runtime_metadata);
excluded_self_referential_artifact_count = nnz( ...
    registry.self_referential_exclusion_flag);
bundle_contract_version = "STAGE7_1_DETERMINISTIC_EVIDENCE_BUNDLE_V1";
pass_flag = all(manifest.pass_flag) && deterministic_artifact_count == 13;
bundle = table(stage7_1_evidence_bundle_hash, ...
    stage7_1_stable_code_identity_hash, deterministic_artifact_count, ...
    deterministic_total_bytes, excluded_runtime_artifact_count, ...
    excluded_self_referential_artifact_count, bundle_contract_version, ...
    pass_flag);
end

function validate_inputs_local(registry, identity)
required = {'artifact_id','relative_path','artifact_type','evidence_class', ...
    'required_by_closure_runner','included_in_deterministic_bundle', ...
    'self_referential_exclusion_flag','contains_runtime_metadata'};
if ~(istable(registry) && all(ismember(required, ...
        registry.Properties.VariableNames)) && ...
        isstruct(identity) && isscalar(identity) && ...
        isfield(identity, 'stage7_1_stable_code_identity_hash'))
    error('build_stage7_1_evidence_manifest:Inputs', ...
        'A valid registry and stable code identity are required.');
end
if numel(unique(registry.artifact_id)) ~= height(registry) || ...
        numel(unique(registry.relative_path)) ~= height(registry)
    error('build_stage7_1_evidence_manifest:Duplicate', ...
        'Artifact registry identities must be unique.');
end
end

function relative = safe_relative_path_local(relative)
relative = replace(string(relative), '\', '/');
components = split(relative, '/');
if ~isscalar(relative) || ismissing(relative) || strlength(relative) == 0 || ...
        startsWith(relative, '/') || ...
        ~isempty(regexp(char(relative), '^[A-Za-z]:', 'once')) || ...
        any(components == "..")
    error('build_stage7_1_evidence_manifest:Path', ...
        'Artifact paths must remain below step_dir.');
end
end

function value = existing_dir_local(value)
if isstring(value), value = char(value); end
if ~(ischar(value) && isrow(value) && exist(value, 'dir') == 7)
    error('build_stage7_1_evidence_manifest:StepDir', ...
        'step_dir must identify an existing directory.');
end
value = char(java.io.File(value).getCanonicalPath());
end

function digest = sha256_file_local(path_now)
fid = fopen(path_now, 'rb');
if fid < 0
    error('build_stage7_1_evidence_manifest:Open', ...
        'Unable to open %s.', path_now);
end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');
digest = sha256_bytes_local(bytes);
clear cleanup
end

function bytes = utf8_local(value)
bytes = uint8(unicode2native(char(value), 'UTF-8'));
end

function digest = sha256_bytes_local(payload)
sha = System.Security.Cryptography.SHA256.Create();
cleanup = onCleanup(@() sha.Dispose());
bytes = uint8(sha.ComputeHash(uint8(payload)));
digest = lower(string(reshape(dec2hex(bytes, 2).', 1, [])));
clear cleanup
end
