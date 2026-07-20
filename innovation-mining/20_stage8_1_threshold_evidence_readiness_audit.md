# Stage8.1A4 Threshold-Evidence Readiness Audit

> Date: 2026-07-20
> Repository: `makabaka165/bs_innovation`
> Runtime: MATLAB R2022b, `phase_factor=1`
> Scope: code-only; no formal calibration, validation, holdout, or PNG

## A. Conclusion

Stage8.1A4 makes formal threshold and validation evidence non-bypassable without
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

A registered start whose refinement returns no estimate remains in
`all_start_results`, retains its initialization/status and actual execution
cost, and is counted as `unreturned_start_count`. It cannot be selected or
misreported as rank deficient. Initialization-failed, unreturned,
nonconverged, rank-deficient, numeric-invalid, and valid counts are disjoint.

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

Formal callers cannot disable tracked-artifact checks. Calibration and
validation evidence can only use the registered Stage8 step root, their target
lifecycle directory must be empty except for `.gitkeep`, and formal freezing
or finalization cannot overwrite existing evidence. Checkpoint roots retain
their separate repository-external rule.

Validation can start only through the committed-threshold wrapper. Its output
binds source, Stage8 plan, calibration plan, validation plan, measurement
registry, calibration bundle, threshold set, raw trial set, summary, paired
sensitivity, and PRIMARY gate identities.
It also emits `COMMITTED_THRESHOLD_PREFLIGHT_PASS` and captures the
deterministic calibration artifact SHA-256 snapshot before the first trial.

## E. Finalizer And Authorization

The finalizer reloads committed calibration evidence, validates the raw trial
set against the current plan, and recomputes the 14-row summary, paired
sensitivity, and PRIMARY-only gate. Supplied derived evidence is compared with
the recomputation and tampering fails. The finalizer writes only validation
artifacts and never rewrites calibration bytes. FULL_PARENT remains
sensitivity-only. Stage8.2 is not executed and requires separate authorization.
The finalizer reloads thresholds from disk and compares pre-validation,
pre-write, and post-write calibration snapshots.

## F. Executable Two-Commit Test

The lifecycle test now executes miniature checkpoints, calibration freezing,
committed-style loading, lossless threshold restoration, paired raw-trial
validation, finalization, pre/post calibration SHA-256 comparison, and final
bundle binding. It no longer scans README text as a substitute for execution.

## G. Frozen Identities

The final Git-index identities computed from the staged Stage8 source are:

| Identity | SHA-256 |
|---|---|
| `stage8_source_tree_hash` | `cb91ca4d3806f11edc8179a876e0515ab7ab6522042342ffec41b77fbbd045c3` |
| `stage8_stable_code_identity` | `6bccb4f96ceb173742d8f62ebbb4b535ca8f71075c599d8399db496881037ad7` |
| `stage8_fit_contract_hash` | `7c29661b2a4456c07a53513642e273373c228cf3e72cd2375524f756f155dadd` |
| `stage8_calibration_plan_hash` | `3c8f71a65e67ed0db7a1551a1594761c737ad8606101d48fcf76fcf40d67c291` |
| `stage8_validation_plan_hash` | `9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7` |
| `stage8_plan_hash` | `3a845addf96e10664ced9ef2d7a30eaccf23c08b160c196eaf1caf6dd71435be` |
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
