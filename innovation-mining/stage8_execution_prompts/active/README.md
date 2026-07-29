# Active Stage8 Exploration

Branch:
`experiment/stage8-core-v2`

Status:
`STAGE8_CORE_V2_2_F0_REAL_ENTRY_FIX_AUTHORIZED`

Safety:
`NO_ALGORITHM_CHANGE`

Runtime lifecycle:
`CANONICAL_RUNTIME_FAILURE_NO_LONGER_CLAIMS_RUNTIME`

Failed runtime:
`FAILED_RUNTIME_ARCHIVED`

Active protocols:
`008_stage8_core_v2_2_f1_canonical_oracle_correction_v1.md`
`009_stage8_core_v2_2_archive_f0_and_restart_final_freeze_v1.md`
`010_stage8_core_v2_2_f0_real_entry_preflight_final_freeze_v1.md`

Starting point:
`af459db19d56b0952b9bad3ff93093eaea30e92a`

Current authoritative theory and algorithm scope:
`innovation-mining/11_sequential_beamspace_ml_innovations_theory.md`

The previous V2.2 invalid result and all `28_*` evidence remain immutable. The
F1 canonical-oracle correction is unchanged. Both F0-only failed runtimes are
preserved in external byte-identical archives. The remaining failure is a
filesystem enumeration bug: MATLAB `dir('*')` counted `.` and `..` in an empty
temporary directory.

The authorized fix counts real files and subdirectories, adds a read-only F0
Preflight action, and runs F0 before claiming the canonical runtime path.
Execution order remains F0, F1A, and the real 24-trial production-interface
F1B. Only an exact F1B pass authorizes the unchanged 144-trial independent
known-K validation, Finalize, and corrected `29_*` final evidence.

Core-V3, automatic K, unknown-K LRT, bootstrap thresholds,
resolved/unresolved, the 6000-trial run, a third K2 solver, adaptive W/B, K=3,
and Stage8.2 are permanently outside the active plan.
