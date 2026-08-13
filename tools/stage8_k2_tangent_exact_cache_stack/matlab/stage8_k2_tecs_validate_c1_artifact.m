function artifact = stage8_k2_tecs_validate_c1_artifact(path_now, identity)
%STAGE8_K2_TECS_VALIDATE_C1_ARTIFACT Load and verify an immutable artifact.

loaded = load(path_now, 'artifact');
if ~isfield(loaded, 'artifact')
    error('stage8_k2_tecs_validate_c1_artifact:Payload', ...
        'CACHE_CORRUPTION: artifact variable is missing.');
end
artifact = loaded.artifact;
stage8_k2_tecs_validate_c1_value(artifact, identity);
end
