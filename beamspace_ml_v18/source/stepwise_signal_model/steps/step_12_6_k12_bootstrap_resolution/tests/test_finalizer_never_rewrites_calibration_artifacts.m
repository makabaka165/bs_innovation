function result = test_finalizer_never_rewrites_calibration_artifacts()
%TEST_FINALIZER_NEVER_REWRITES_CALIBRATION_ARTIFACTS Verify one Stage8.1A3 contract.

result = stage8_1a3_contract_case('finalizer_never_rewrites_calibration_artifacts');
end
