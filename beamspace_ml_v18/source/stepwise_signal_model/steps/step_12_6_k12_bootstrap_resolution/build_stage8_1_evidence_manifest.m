function [manifest, bundle_hash] = build_stage8_1_evidence_manifest( ...
    artifact_root, registry)
%BUILD_STAGE8_1_EVIDENCE_MANIFEST Hash deterministic artifacts without self.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 2 || isempty(registry)
    registry = stage8_1_artifact_registry();
end
selected = registry.table.deterministic_bundle_flag;
rows = registry.table(selected, :);
artifact_id = rows.artifact_id;
relative_path = replace(rows.relative_path, "\", "/");
sha256 = strings(height(rows), 1);
byte_count = zeros(height(rows), 1);
for row_index = 1:height(rows)
    path_now = fullfile(artifact_root, char(rows.relative_path(row_index)));
    if ~isfile(path_now)
        error('build_stage8_1_evidence_manifest:MissingArtifact', ...
            'Deterministic artifact is missing: %s.', path_now);
    end
    sha256(row_index) = string(stage8_sha256_file(path_now));
    info = dir(path_now);
    byte_count(row_index) = info.bytes;
end
manifest = table(artifact_id, relative_path, sha256, byte_count);
if any(manifest.artifact_id == "EVIDENCE_MANIFEST") || ...
        any(contains(lower(manifest.relative_path), "checkpoint")) || ...
        any(manifest.artifact_id == "RUNTIME_DIAGNOSTICS")
    error('build_stage8_1_evidence_manifest:Exclusion', ...
        'Manifest, runtime, and checkpoint files must be excluded.');
end
bundle_hash = stage8_stable_hash( ...
    'STAGE8_1_DETERMINISTIC_EVIDENCE_BUNDLE_V1', manifest);
manifest.stage8_1_evidence_bundle_hash = ...
    repmat(string(bundle_hash), height(manifest), 1);
clear path_cleanup
end
