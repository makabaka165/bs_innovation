function evidence = write_stage8_1_registry_bundle( ...
    bundle, artifact_root, registry, opts)
%WRITE_STAGE8_1_REGISTRY_BUNDLE Write one complete lifecycle registry.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 4 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'overwrite'), opts.overwrite = false; end
if ~isfield(opts, 'calibration_evidence_bundle_hash')
    opts.calibration_evidence_bundle_hash = '';
end
allowed = {'overwrite','calibration_evidence_bundle_hash'};
unknown = setdiff(fieldnames(opts), allowed);
if ~isempty(unknown)
    error('write_stage8_1_registry_bundle:UnknownOption', ...
        'Unknown option: %s.', unknown{1});
end
if ~isfolder(artifact_root), mkdir(artifact_root); end
manifest_row = registry.table.manifest_self_excluded_flag;
if nnz(manifest_row) ~= 1
    error('write_stage8_1_registry_bundle:Registry', ...
        'A lifecycle registry must contain exactly one manifest.');
end
written = false(height(registry.table), 1);
for row_index = 1:height(registry.table)
    if manifest_row(row_index), continue; end
    row = registry.table(row_index, :);
    field = char(row.bundle_field);
    if ~isfield(bundle, field)
        error('write_stage8_1_registry_bundle:MissingPayload', ...
            'bundle.%s is required.', field);
    end
    path_now = fullfile(artifact_root, char(row.relative_path));
    write_payload_local(path_now, bundle.(field), row.artifact_id, opts);
    written(row_index) = true;
end
[manifest, bundle_hash, details] = build_stage8_1_evidence_manifest( ...
    artifact_root, registry, struct('calibration_evidence_bundle_hash', ...
    opts.calibration_evidence_bundle_hash));
manifest_path = fullfile(artifact_root, ...
    char(registry.table.relative_path(manifest_row)));
write_payload_local(manifest_path, manifest, ...
    registry.table.artifact_id(manifest_row), opts);
written(manifest_row) = true;
evidence = details;
evidence.manifest = manifest;
evidence.bundle_hash = bundle_hash;
evidence.artifact_registry_hash = registry.registry_hash;
evidence.written_artifact_count = nnz(written);
evidence.all_registered_artifacts_written_flag = all(written);
evidence.runtime_in_bundle_identity_flag = false;
evidence.manifest_self_reference_flag = false;
clear path_cleanup
end

function write_payload_local(path_now, payload, artifact_id, opts)
folder = fileparts(path_now);
if ~isfolder(folder), mkdir(folder); end
if isfile(path_now) && ~opts.overwrite
    error('write_stage8_1_registry_bundle:ExistingArtifact', ...
        'Refusing to overwrite existing artifact: %s.', path_now);
end
if artifact_id == "REPORT"
    if ~(ischar(payload) || (isstring(payload) && isscalar(payload)))
        error('write_stage8_1_registry_bundle:Report', ...
            'report_text must be scalar text.');
    end
    fid = fopen(path_now, 'w');
    if fid < 0
        error('write_stage8_1_registry_bundle:Open', ...
            'Unable to open %s.', path_now);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', char(payload));
    clear cleanup
else
    if isstruct(payload), payload = struct2table(payload); end
    if ~istable(payload)
        error('write_stage8_1_registry_bundle:TablePayload', ...
            'Artifact %s requires a table-compatible payload.', artifact_id);
    end
    writetable(payload, path_now);
end
end
