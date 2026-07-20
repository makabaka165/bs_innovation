function [snapshot, snapshot_hash] = ...
    capture_stage8_1_calibration_snapshot(artifact_root)
%CAPTURE_STAGE8_1_CALIBRATION_SNAPSHOT Hash committed calibration bytes.

registry = stage8_1_calibration_artifact_registry();
root = char(string(artifact_root));
if isfile(fullfile(root, 'stage8_1_calibration_evidence_manifest.csv'))
    root = fileparts(root);
end
selected = registry.table.deterministic_bundle_flag | ...
    registry.table.manifest_self_excluded_flag;
rows = registry.table(selected, :);
artifact_id = rows.artifact_id;
relative_path = replace(rows.relative_path, "\", "/");
sha256 = strings(height(rows), 1);
byte_count = zeros(height(rows), 1);
for row_index = 1:height(rows)
    path_now = fullfile(root, char(rows.relative_path(row_index)));
    if ~isfile(path_now)
        error('capture_stage8_1_calibration_snapshot:MissingArtifact', ...
            'Calibration snapshot artifact is missing: %s.', path_now);
    end
    sha256(row_index) = string(stage8_sha256_file(path_now));
    info = dir(path_now);
    byte_count(row_index) = info.bytes;
end
snapshot = table(artifact_id, relative_path, sha256, byte_count);
snapshot_hash = stage8_stable_hash( ...
    'STAGE8_1_CALIBRATION_BYTE_SNAPSHOT_V1', snapshot);
end
