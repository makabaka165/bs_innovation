# Controller Recovery After the First Launch

Protocol: `STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_V1`.

This is execution recovery evidence, not a scientific performance result. The user explicitly requested fixing the cause and continuing the protocol after the recorded hard stop.

## Cause and Correction

The controller at pruning commit `d4e2517bf860efeabbf40925af44ba17bff85495` counted both `E:/MATLABR2022b/bin/matlab.exe` and its child `E:/MATLABR2022b/bin/win64/MATLAB.exe` as workers. There was one compute worker. The controller entered HARD_STOPPED, and both task-owned processes were stopped after ownership inspection.

The corrected inventory requires the expected executable paths, recorded launcher PID and creation time, the child's parent PID and creation time, and exact parsed batch arguments. Windows `CommandLineToArgvW` handles the different argument quoting used by the launcher and child. One verified pair counts as one compute worker. Duplicate workers, foreign executables, missing process identity and mismatched commands still stop execution. Windows PowerShell's built-in module path is restored when it inherits a PowerShell 7 environment through MATLAB.

## Preserved Checkpoints

Before editing the controller, a read-only MATLAB audit verified all 45 Beamspace checkpoints against the old formal HEAD and source hash. It verified the checkpoint payloads and all recorded source-file hashes, reconstructed all 45 observations, and recomputed 135 metric rows. The archive retains the original checkpoint bytes, old state, formal identity, gates and incident/audit records at:

`E:/bs_innovation_runtime/experiment_stage8-k2-raw-tangent-core-native-snr-v1/backup/launch_incident_d4e2517`.

Because the code identity includes the controller and tests, the recovery revision has a different identity. The 45 archived trials will be recomputed under that revision. The checkpoint validator remains unchanged: exact HEAD and source hash are required, corrupt or mismatched files are rejected, and valid files are skipped without rewriting. No historical checkpoint is relabeled or admitted through an identity exception.

## Validation and Continuation

The [machine-readable recovery record](58_stage8_k2_raw_tangent_controller_recovery.json) contains the archive hashes and actual-launch evidence. The real launch test uses the production launch helper and executes a Tick while both launcher and child are present. It requires one compute worker, unchanged state and clean process exit. T18 also covers four allowed and nine rejected process inventories, 15 state transitions, and real scheduled-task registration/export/removal. T16 additionally rejects wrong HEAD and wrong source hash. The [fixed-test report](58_stage8_k2_raw_tangent_fixed_tests.json) records the complete 18-test rerun.

The recovery script is restricted to this incident and requires the verified archive, empty new checkpoint directories, a clean pushed recovery commit, matching 18-test gates and formal identity, and the existing 15-minute IgnoreNew scheduled task. It then starts Beamspace under the new identity. Estimators, noise generation, metrics, frozen contracts and classical scientific kernels are unchanged.

The registered task continues Beamspace, Element, finalization, fresh-session read-only audit, result commit/push and automatic task removal. It does not poll in a resident loop. Formal completion is recorded only after all 13440 rows pass audit and closeout succeeds. No main merge, worktree removal or runtime removal is authorized.
