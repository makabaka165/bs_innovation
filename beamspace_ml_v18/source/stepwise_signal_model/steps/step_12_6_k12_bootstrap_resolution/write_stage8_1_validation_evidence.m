function evidence = write_stage8_1_validation_evidence( ...
    bundle, artifact_root, calibration_evidence_bundle_hash, opts)
%WRITE_STAGE8_1_VALIDATION_EVIDENCE Write validation-only evidence.

if nargin < 4 || isempty(opts), opts = struct(); end
opts.calibration_evidence_bundle_hash = calibration_evidence_bundle_hash;
evidence = write_stage8_1_registry_bundle(bundle, artifact_root, ...
    stage8_1_validation_artifact_registry(), opts);
end
