function registry = stage8_k2_tecs_build_c1_artifacts(repo_dir, runtime_root)
%STAGE8_K2_TECS_BUILD_C1_ARTIFACTS Build immutable timing/lifecycle inputs.

scope = stage8_k2_tecs_add_paths(repo_dir); %#ok<NASGU>
fixture = stage8_k2_tecs_build_runtime_fixture(repo_dir, runtime_root);
artifact_dir = fullfile(runtime_root, 'artifacts');
if ~isfolder(artifact_dir), mkdir(artifact_dir); end
rows = repmat(struct('fixed_measurement_hash', "", ...
    'artifact_path', "", 'artifact_hash', "", ...
    'artifact_file_sha256', "", 'entry_count', 0, ...
    'value_bytes', 0, 'status', ""), ...
    numel(fixture.identities), 1);
for index = 1:numel(fixture.identities)
    identity = fixture.identities(index);
    path_now = fullfile(artifact_dir, ...
        ['C1_', identity.fixed_measurement_hash, '.mat']);
    if isfile(path_now)
        checked = stage8_k2_tecs_validate_c1_artifact( ...
            path_now, identity.fixed_measurement_hash);
    else
        [dictionary, ~] = stage8_k2_tcc_build_registered_dictionary( ...
            identity.model, fixture.context.plan.local_domain, struct());
        artifact = stage8_k2_tecs_promote_c1_artifact(dictionary); %#ok<NASGU>
        temporary = [path_now, '.tmp'];
        save(temporary, 'artifact', '-v7.3');
        movefile(temporary, path_now, 'f');
        checked = stage8_k2_tecs_validate_c1_artifact( ...
            path_now, identity.fixed_measurement_hash);
    end
    if ~isequaln(checked.G, identity.artifact.G) || ...
            ~strcmp(checked.artifact_hash, identity.artifact.artifact_hash)
        error('stage8_k2_tecs_build_c1_artifacts:Certification', ...
            'C1 timing artifact differs from static certification.');
    end
    row = rows(index);
    row.fixed_measurement_hash = string(identity.fixed_measurement_hash);
    row.artifact_path = string(strrep(path_now, '\', '/'));
    row.artifact_hash = string(checked.artifact_hash);
    row.artifact_file_sha256 = string( ...
        stage8_k2_tecs_sha256_file(path_now));
    row.entry_count = checked.entry_count;
    row.value_bytes = checked.value_bytes;
    row.status = "IMMUTABLE_C1_ARTIFACT_VALIDATED";
    rows(index) = row;
    [status, message] = fileattrib(path_now, '-w');
    if ~status, error('stage8_k2_tecs_build_c1_artifacts:ReadOnly', ...
            '%s', message); end
end
registry = struct2table(rows);
end
