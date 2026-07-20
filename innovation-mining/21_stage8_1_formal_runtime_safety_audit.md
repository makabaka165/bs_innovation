# Stage8.1A4 Formal Runtime Safety Audit

> Date: 2026-07-20
> Repository: `makabaka165/bs_innovation`
> Baseline: `354eea79572382be70f0bf2a5943fc2a73843a1e`
> Runtime: MATLAB R2022b, `phase_factor=1`
> Scope: code-only; no formal calibration, validation, Stage8.2, or PNG

## A. Conclusion

`PASS_STAGE8_1A4_CODE_ONLY`. The production unreturned-start branch and the
formal calibration/validation evidence lifecycle are now executable and
non-bypassable through public runners. Frozen statistical constants, starts,
the Stage5 local domain, `RECT_E14_A31`, and upstream evidence are unchanged.

## B. Unreturned Registered Starts

`fit_local_model_k` no longer references the undefined and unused
`rank_failure_count`. Every executed start is recorded through one production
helper. A refinement that returns no estimate keeps its initialization ID,
status, history, score/SVD counts, and runtime, but cannot participate in
best-start selection. Initialization-failed, unreturned, nonconverged,
rank-deficient, numeric-invalid, and valid counters are disjoint and exhaustive.

## C. Tracked Calibration Evidence

Formal `load_stage8_1_locked_thresholds`, public K1 validation, and finalization
force tracked calibration evidence in a clean Git worktree. Explicit
`require_tracked_artifacts=false` fails with
`FORMAL_TRACKED_CALIBRATION_EVIDENCE_REQUIRED`; it is never silently upgraded.
Nonformal test fixtures retain an explicit untracked path.

## D. Overwrite And Artifact Roots

Formal threshold freezing and validation finalization reject `overwrite=true`
with `FORMAL_EVIDENCE_OVERWRITE_FORBIDDEN`. Their artifact root must resolve to
the registered Stage8 step directory in the active repository, and the target
calibration or results lifecycle must be empty except for `.gitkeep`.
Calibration checkpoints follow a different contract and remain outside the
repository.

## E. Calibration Freezer Gate

Before a formal freeze, the runner requires authorization, a clean current
plan, the registered empty calibration root, a repository-external checkpoint
root, and the complete identity-bound checkpoint set. It writes calibration
evidence only and reports both validation and Stage8.2 as not executed.

## F. Validation And Finalizer Gate

The public validation wrapper is the only formal validation entry. It loads
tracked thresholds, recomputes manifests and threshold identities, verifies an
empty registered results root, records
`COMMITTED_THRESHOLD_PREFLIGHT_PASS`, and captures deterministic calibration
SHA-256 before trials. The finalizer reloads thresholds from disk, recomputes
the trial set, 14-row summary, paired sensitivity, and PRIMARY gate, and
compares calibration snapshots before validation, before writing, and after
writing.

## G. Executable Lifecycle

The miniature two-commit test executes checkpoint creation, threshold freeze,
lossless committed-style loading, public-wrapper validation, finalization,
calibration snapshot equality, and the Stage8.2 stop. A second no-overwrite
freeze and a second no-overwrite finalization both fail. Formal tracked-check
bypass attempts fail in the loader, wrapper, and finalizer.

## H. Frozen Identities

| Identity | SHA-256 |
|---|---|
| `stage8_source_tree_hash` | `cb91ca4d3806f11edc8179a876e0515ab7ab6522042342ffec41b77fbbd045c3` |
| `stage8_stable_code_identity` | `6bccb4f96ceb173742d8f62ebbb4b535ca8f71075c599d8399db496881037ad7` |
| `stage8_fit_contract_hash` | `7c29661b2a4456c07a53513642e273373c228cf3e72cd2375524f756f155dadd` |
| `stage8_calibration_plan_hash` | `3c8f71a65e67ed0db7a1551a1594761c737ad8606101d48fcf76fcf40d67c291` |
| `stage8_validation_plan_hash` | `9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7` |
| `stage8_plan_hash` | `3a845addf96e10664ced9ef2d7a30eaccf23c08b160c196eaf1caf6dd71435be` |
| `measurement_registry_hash` | `f20773e1165b8519368b3a4dd3e74b250d84f3a7199f560036e5235988017688` |

## I. Verification And Formal Execution Status

Stage8.0 retains 428 assertions. The expanded Stage8.1A suite passes 501
assertions with Code Analyzer/scope/formal-artifact counts `0/0/0`. Frozen
Stage7.1, Stage6, Stage5, and Step11 checks pass. No formal calibration cell,
Lambda sample, `q_global`, K1 validation row, Stage8.2 result, performance
number, or PNG was produced; registered artifact directories contain only
`.gitkeep`.

## J. Next Gate

It is technically permissible to request a separate Stage8.1B authorization
only after this clean A4 code commit. That future run must create calibration
threshold evidence from repository-external shards, commit it, then execute
PRIMARY K1 validation from the clean tracked threshold-evidence commit.
Stage8.1B and Stage8.2 remain unexecuted and unauthorized in this audit.
