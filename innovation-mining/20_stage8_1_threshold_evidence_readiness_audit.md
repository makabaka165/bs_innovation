# Stage8.1A3 Threshold-Evidence Readiness Audit

> Date: 2026-07-20
> Repository: `makabaka165/bs_innovation`
> Runtime: MATLAB R2022b, `phase_factor=1`
> Scope: code-only; no formal calibration, validation, holdout, or PNG

## A. Conclusion

Stage8.1A3 makes threshold and validation evidence self-contained without
changing `alpha`, `beta`, `Bboot`, `Bsep`, the minimum valid fraction, the
engineering half-width, registered K1/K2 starts, the Stage5 local domain, or
frozen Stage7.1/6/5/Step11 evidence.

## B. Valid-Start Selection

All registered starts still execute and contribute score, SVD, and runtime
costs. The selected start is the maximum concentrated log-likelihood member
of the valid registered-start set. Eligibility requires initialization
availability, a returned and converged estimate, rank at least K, finite RSS,
variance, and log likelihood, complete fixed identities, and
`phase_factor=1`. Nonconverged and invalid starts remain auditable but cannot
win selection.

## C. Threshold V3

`STAGE8_LOCKED_THRESHOLD_ARTIFACT_V3` hashes a fixed field whitelist.
`q_global_hex` and `alpha_hex` preserve exact IEEE-754 doubles; decimal columns
are readable copies and are checked against `hex2num` restoration. Cell
quantiles and cell artifact hashes remain bound through `calibration_hash`.
Runtime HEAD, trial/scene fields, and later runtime metadata cannot change the
threshold identity.

## D. Split Evidence Lifecycle

Calibration and validation now have independent registries, writers, and
manifests. Calibration freezing writes no empty validation placeholders. The
formal loader requires a clean commit and tracked deterministic calibration
artifacts, recomputes every SHA-256 and the calibration bundle, verifies the
four frozen identities, restores both thresholds, and checks exact config
coverage.

Validation can start only through the committed-threshold wrapper. Its output
binds source, Stage8 plan, calibration plan, validation plan, measurement
registry, calibration bundle, threshold set, raw trial set, summary, paired
sensitivity, and PRIMARY gate identities.

## E. Finalizer And Authorization

The finalizer reloads committed calibration evidence, validates the raw trial
set against the current plan, and recomputes the 14-row summary, paired
sensitivity, and PRIMARY-only gate. Supplied derived evidence is compared with
the recomputation and tampering fails. The finalizer writes only validation
artifacts and never rewrites calibration bytes. FULL_PARENT remains
sensitivity-only. Stage8.2 is not executed and requires separate authorization.

## F. Executable Two-Commit Test

The lifecycle test now executes miniature checkpoints, calibration freezing,
committed-style loading, lossless threshold restoration, paired raw-trial
validation, finalization, pre/post calibration SHA-256 comparison, and final
bundle binding. It no longer scans README text as a substitute for execution.

## G. Frozen Identities

The final Git-index identities are populated after all Stage8 source is staged:

| Identity | SHA-256 |
|---|---|
| `stage8_source_tree_hash` | `68960fb22115b6d85a6141bfd22e01c29ceaf3f87c3069166585190b87d3553f` |
| `stage8_stable_code_identity` | `78acde57bdc232fec5d93478b4ff155fb5e0fc5dd5a4c988883356885202aa11` |
| `stage8_fit_contract_hash` | `d3638412d5e6dbcae142a96f34a26c55d80f7ced2cc313b8f0e3817db6a9e2c1` |
| `stage8_validation_plan_hash` | `9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7` |
| `stage8_plan_hash` | `f846aa7bc11494feec14f6d8363312b103216a015cfa3cf65546f9b1255153a0` |
| `measurement_registry_hash` | `f20773e1165b8519368b3a4dd3e74b250d84f3a7199f560036e5235988017688` |

## H. Formal Execution Status

No formal calibration cell, Lambda sample, `q_global`, K1 validation row,
Stage8.2 holdout, performance number, or PNG was generated. The repository
artifact directories remain empty except for `.gitkeep`.

## I. Next Gate

Only after all code-only tests, Code Analyzer, scope, artifact, upstream freeze,
identity, and Git checks pass is it technically permissible to request a
separate Stage8.1B authorization. That future execution must first freeze K1
bootstrap thresholds in its own commit, then run PRIMARY K1 validation from
the clean threshold-evidence commit. This audit does not itself execute or
authorize Stage8.1B or Stage8.2.
