# Innovation-Mining Document Status Index

Branch: `experiment/stage8-k2-raw-tangent-core-native-snr-v1`.

Source main: `644fc6e0041e400b6500579bba93d49f45e46990`.

Role: independent scientific experiment. Production: NOT AUTHORIZED.

## Current Authority

- PRIMARY SCIENTIFIC ALGORITHM: TANGENT_PROFILE_CORE.
- SNR: NATIVE WHITENED-BEAMSPACE NOMINAL SNR.
- NOISE: IID CIRCULAR COMPLEX GAUSSIAN ONLY.
- FIXED-K2 FALLBACK: REMOVED.
- CACHE: REMOVED FROM ACTIVE ROUTE.
- 72-TRIAL: DELETED FROM THIS BRANCH; RETAINED IN MAIN HISTORY.
- OLD SAFE 1680: HISTORICAL REFERENCE ONLY.

[57 protocol](57_stage8_k2_raw_tangent_core_native_snr_theory_and_protocol.md) defines the experiment. The [pruning manifest](57_stage8_k2_raw_tangent_pruning_manifest.csv) identifies all 429 deleted files with original blob SHAs and sizes. The [active tool README](../tools/stage8_k2_raw_tangent_core_native_snr/README.md) gives the execution and plotting interfaces.

The [fixed-tests report](58_stage8_k2_raw_tangent_fixed_tests.json) records 18/18 PASS. The [registry](58_stage8_k2_raw_tangent_registry.csv) has 1680 scenarios, 240 base realizations and 20 replicates per exact cell. The [beamwidth contract](58_stage8_k2_raw_tangent_beamwidth_contract.csv) contains measured P1-P4 widths and crossings.

The [formal results](58_stage8_k2_raw_tangent_core_native_snr_results.md) contain 13440 method rows from 3360 verified checkpoints. All 12 figures regenerate from exported data without fitting. A fresh MATLAB session independently reconstructed observations and checked all metrics; the maximum nominal SNR error was 3.5527136788005009e-15 dB. The [runtime manifest](58_stage8_k2_raw_tangent_runtime_manifest.json) records the final audit and artifact identities.

At 22 dB, Raw Core validity is 99.1667%, localization success is 97.0833%, and strict resolution success is 27.5%. No registered overall SNR point reaches the prescribed high-reliability condition: RAW_TANGENT_NO_HIGH_RELIABILITY_REGION_IDENTIFIED. This is a valid scientific result, not an experiment failure. The [closeout recovery record](58_stage8_k2_raw_tangent_closeout_recovery.json) preserves the later controller stop; all formal checkpoint bytes and their frozen code identity were retained.

The [controller recovery record](58_stage8_k2_raw_tangent_controller_recovery.md) documents the first-launch process-count error, the user-authorized repair, the byte-preserved 45-checkpoint archive, and strict-identity recomputation after a complete gate rerun.

## Read-Only Historical Evidence

- 43-44: LEGACY_SAFE_WHITE_SNR_REFERENCE.
- 45-46: LEGACY_SAFE_CLASSICAL_REFERENCE.
- 47-48: LEGACY_SAFE_ALL_CLASSICAL_REFERENCE.

All existing 43-48 files retain their source bytes. They are never merged into the Core results. Historical Safe validity and gain claims do not describe Raw Core.

Earlier retained evidence (including 41/41A/42 and 49) remains historical provenance, not an active runner or execution authorization. References inside those frozen historical records describe source-main paths. Deleted 30-34, 39-40 and 50-56 records, deleted prompts, Safe runners and cache tools remain in source-main history and the verified backup bundle.

## Preserved Boundaries

The main and research refs, EI_paper, physical cylindrical manifold, full-manifold builder mathematics, concentrated DML mathematics and classical scientific kernels remain unchanged. Generic historical compatibility fields may remain dormant in shared code; ACTIVE_ROUTE_ZERO applies to the reachable Core path.

The scheduled workflow is PREPARED -> BEAMSPACE_RUNNING -> ELEMENT_RUNNING -> READY_TO_FINALIZE -> FINALIZATION_RUNNING -> READY_FOR_AUDIT -> AUDIT_RUNNING -> READY_FOR_GIT_CLOSEOUT -> COMPLETE. Errors preserve state and HARD_STOPPED. Final action is USER_REVIEW, with no merge into main and no worktree/runtime deletion.
