function evidence = write_stage8_1_calibration_evidence( ...
    bundle, artifact_root, opts)
%WRITE_STAGE8_1_CALIBRATION_EVIDENCE Write calibration-only evidence.

if nargin < 3 || isempty(opts), opts = struct(); end
evidence = write_stage8_1_registry_bundle(bundle, artifact_root, ...
    stage8_1_calibration_artifact_registry(), opts);
end
