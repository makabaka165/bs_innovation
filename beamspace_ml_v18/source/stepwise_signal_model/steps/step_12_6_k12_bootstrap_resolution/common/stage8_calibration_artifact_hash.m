function digest = stage8_calibration_artifact_hash(artifact)
%STAGE8_CALIBRATION_ARTIFACT_HASH Recompute a cell checkpoint identity.

if ~(isstruct(artifact) && isscalar(artifact))
    error('stage8_calibration_artifact_hash:Artifact', ...
        'artifact must be a scalar struct.');
end
excluded = intersect(fieldnames(artifact), ...
    {'runtime','cell_artifact_hash','phase_factor'});
payload = artifact;
if ~isempty(excluded)
    payload = rmfield(payload, excluded);
end
digest = stage8_stable_hash( ...
    'STAGE8_1_CALIBRATION_CELL_ARTIFACT_V1', payload);
end
