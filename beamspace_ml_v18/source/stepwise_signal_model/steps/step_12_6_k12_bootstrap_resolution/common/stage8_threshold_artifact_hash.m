function digest = stage8_threshold_artifact_hash(artifact)
%STAGE8_THRESHOLD_ARTIFACT_HASH Hash a locked threshold and its provenance.

required = {'stage8_stable_code_identity_hash','stage8_plan_hash', ...
    'stage8_calibration_plan_hash','measurement_registry_hash', ...
    'measurement_config_id','q_global','alpha','calibration_hash', ...
    'source_identity','threshold_status','threshold_policy'};
if ~(isstruct(artifact) && isscalar(artifact) && all(isfield(artifact, required)))
    error('stage8_threshold_artifact_hash:Artifact', ...
        'The locked threshold artifact is incomplete.');
end
names = lower(string(fieldnames(artifact)));
forbidden = ["truth";"scene";"separation"; ...
    "score" + "_" + "gap";"scoregap"];
for token_index = 1:numel(forbidden)
    if any(contains(names, forbidden(token_index)))
        error('stage8_threshold_artifact_hash:ForbiddenInput', ...
            'Threshold artifacts cannot depend on trial or scene information.');
    end
end
payload = artifact;
excluded = intersect(fieldnames(payload), ...
    {'threshold_artifact_hash','runtime_head_in_identity_flag','phase_factor'});
if ~isempty(excluded)
    payload = rmfield(payload, excluded);
end
digest = stage8_stable_hash('STAGE8_LOCKED_THRESHOLD_ARTIFACT_V2', payload);
end
