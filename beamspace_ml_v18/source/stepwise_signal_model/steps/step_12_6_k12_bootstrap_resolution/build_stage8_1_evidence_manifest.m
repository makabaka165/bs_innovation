function [manifest, bundle_hash, details] = build_stage8_1_evidence_manifest( ...
    artifact_root, registry, opts)
%BUILD_STAGE8_1_EVIDENCE_MANIFEST Hash deterministic artifacts without self.

path_cleanup = stage8_runtime_path_scope(); %#ok<NASGU>
if nargin < 2 || isempty(registry)
    registry = stage8_1_artifact_registry();
end
if nargin < 3 || isempty(opts), opts = struct(); end
if ~isfield(opts, 'calibration_evidence_bundle_hash')
    opts.calibration_evidence_bundle_hash = '';
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
if any(registry.table.manifest_self_excluded_flag & ...
        registry.table.deterministic_bundle_flag) || ...
        any(contains(lower(manifest.relative_path), "checkpoint")) || ...
        any(ismember(manifest.artifact_id, ...
        registry.table.artifact_id(registry.table.runtime_excluded_flag)))
    error('build_stage8_1_evidence_manifest:Exclusion', ...
        'Manifest, runtime, and checkpoint files must be excluded.');
end
lifecycle = "LEGACY";
if isfield(registry, 'lifecycle')
    lifecycle = string(registry.lifecycle);
end
if lifecycle == "CALIBRATION"
    bundle_hash = stage8_stable_hash( ...
        'STAGE8_1_CALIBRATION_EVIDENCE_BUNDLE_V1', manifest);
    manifest.calibration_evidence_bundle_hash = ...
        repmat(string(bundle_hash), height(manifest), 1);
    details = struct('calibration_evidence_bundle_hash', bundle_hash);
elseif lifecycle == "VALIDATION"
    calibration_hash = char(string(opts.calibration_evidence_bundle_hash));
    if isempty(calibration_hash)
        error('build_stage8_1_evidence_manifest:CalibrationBundle', ...
            'Validation evidence must reference calibration evidence.');
    end
    deterministic_hash = stage8_stable_hash( ...
        'STAGE8_1_VALIDATION_DETERMINISTIC_MANIFEST_V1', manifest);
    bundle_hash = stage8_stable_hash( ...
        'STAGE8_1_FINAL_EVIDENCE_BUNDLE_V1', calibration_hash, manifest);
    manifest.calibration_evidence_bundle_hash = ...
        repmat(string(calibration_hash), height(manifest), 1);
    manifest.validation_deterministic_manifest_hash = ...
        repmat(string(deterministic_hash), height(manifest), 1);
    manifest.stage8_1_evidence_bundle_hash = ...
        repmat(string(bundle_hash), height(manifest), 1);
    details = struct('calibration_evidence_bundle_hash', calibration_hash, ...
        'validation_deterministic_manifest_hash', deterministic_hash, ...
        'stage8_1_evidence_bundle_hash', bundle_hash);
else
    bundle_hash = stage8_stable_hash( ...
        'STAGE8_1_DETERMINISTIC_EVIDENCE_BUNDLE_V1', manifest);
    manifest.stage8_1_evidence_bundle_hash = ...
        repmat(string(bundle_hash), height(manifest), 1);
    details = struct('stage8_1_evidence_bundle_hash', bundle_hash);
end
clear path_cleanup
end
