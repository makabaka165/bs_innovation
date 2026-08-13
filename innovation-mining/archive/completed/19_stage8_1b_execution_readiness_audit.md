# Stage8.1A4 / Stage8.1B Execution Readiness Audit

> Date: 2026-07-20
> Repository: `makabaka165/bs_innovation`
> A3 baseline: `354eea79572382be70f0bf2a5943fc2a73843a1e`
> Runtime: MATLAB R2022b, `phase_factor=1`
> Scope: code-only; no formal calibration, threshold, validation, holdout, or PNG

## A. Stage8.1A4 Conclusion

Stage8.1A4 closes the remaining executable-contract defects in K1 validation,
threshold provenance, formal calibration shards/checkpoints, group-noise scale
handling, and validation RNG roles. It does not change `alpha=0.05`,
`beta=0.05`, `Bboot=199`, `Bsep=199`, minimum valid fraction `0.90`, the
`0.21` degree engineering half-width, K1/K2 starts, the Stage5 domain,
`RECT_E14_A31`, or frozen Stage7.1/6/5/Step11 evidence.

The production fitter now preserves and charges a registered start whose
refinement returns no estimate without selecting it or treating it as a rank
failure. Formal public entry points force tracked calibration evidence, a
registered repository artifact root, no-overwrite evidence creation, and
calibration SHA-256 immutability across validation and finalization.

## B. Primary And Sensitivity Validation

K1 summaries are keyed by `measurement_config_id x summary_scope`. Formal
output is fixed at 14 rows: two configurations times one overall plus six
strata. Each overall row uses 6000 common trials and each stratum row uses
1000; the 12,000 paired method rows are never pooled into one Bernoulli
interval.

Only `PRIMARY_RECT_E14_A31` enters the Stage8.2 authorization gate. The full
parent is labeled
`SENSITIVITY_ONLY_NOT_USED_FOR_STAGE8_2_AUTHORIZATION` and cannot offset a
primary failure. A separate 6000-row paired-sensitivity table records primary
and full-parent states and false-split, false-resolved, and nondecision
discordance.

## C. Threshold Provenance

Every locked threshold now carries and exactly verifies:

- `stage8_stable_code_identity_hash`;
- `stage8_plan_hash`;
- `stage8_calibration_plan_hash`;
- `measurement_registry_hash`;
- `measurement_config_id`, `calibration_hash`, and `source_identity`;
- `threshold_status`, `threshold_policy`, and `threshold_artifact_hash`.

Lookup accepts only configuration ID, locked artifact, and expected contract.
Truth, scene, separation, and score-gap inputs are rejected. Formal validation
preflights the complete two-threshold set and the live clean threshold-evidence
commit before its first trial. Finalization requires exactly two unique,
complete thresholds and requires validation's threshold-set hash to equal the
hash written into final evidence.

## D. Formal Shard And Checkpoint Lifecycle

`FORMAL_SHARD` materializes only explicit `cell_indices`. A cell-input hash is
stable between singleton, shard, and full-plan materialization because it does
not depend on shard order or size. Formal checkpoint root is mandatory and
must be outside the Git repository.

The checkpoint manifest loader and collector combine multiple shards and
require exactly one checkpoint for every cell. Source, calibration-plan,
model, cell-input, and cell-artifact hashes are rechecked. Missing, duplicate,
malformed, stale, or failed checkpoints stop collection. Aggregation remains
unavailable until all 300 PASS cells and all 59,700 unique bootstrap seeds are
present.

## E. Group-Noise Fallback Revision

An invalid group-noise scale (`NaN`, nonfinite, zero, or negative) is never
replaced by one. The affected grouped partition becomes unavailable with
`GROUP_NOISE_SCALE_INVALID`; conventional and independently valid fixed starts
continue, and no rescue start is added. Results expose
`invalid_group_noise_scale_count` and `group_noise_scale_status`.

## F. Validation RNG Role Separation

Each of six validation strata reserves a 3000-seed block:

- first 1000: parameter seeds for center and SNR only;
- middle 1000: element-noise seeds only;
- final 1000: separation-auxiliary seeds.

The three roles are mutually disjoint across roles and strata and remain
disjoint from calibration and holdout. Both measurement configurations share
all three common-trial roles. Separation bootstrap uses one auxiliary seed
with deterministic substreams `1:199`.

## G. New Stage8.1B Baseline

The Git-index-frozen code-only identities are:

| Identity | SHA-256 |
|---|---|
| `stage8_source_tree_hash` | `cb91ca4d3806f11edc8179a876e0515ab7ab6522042342ffec41b77fbbd045c3` |
| `stage8_stable_code_identity` | `6bccb4f96ceb173742d8f62ebbb4b535ca8f71075c599d8399db496881037ad7` |
| `stage8_fit_contract_hash` | `7c29661b2a4456c07a53513642e273373c228cf3e72cd2375524f756f155dadd` |
| `stage8_calibration_plan_hash` | `3c8f71a65e67ed0db7a1551a1594761c737ad8606101d48fcf76fcf40d67c291` |
| `stage8_validation_plan_hash` | `9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7` |
| `stage8_plan_hash` | `3a845addf96e10664ced9ef2d7a30eaccf23c08b160c196eaf1caf6dd71435be` |
| `measurement_registry_hash` | `f20773e1165b8519368b3a4dd3e74b250d84f3a7199f560036e5235988017688` |

The calibration and validation plan hashes are unchanged because their frozen
cells, seeds, statistical constants, paired strata, and gates are unchanged.
The source, fit-contract, and total-plan identities change because A4 adds the
disjoint start-failure contract and non-bypassable evidence lifecycle.

## H. Tests And Scope

- Stage8.0: 428 assertions passed; Code Analyzer/scope violations `0/0`.
- Stage8.1A4: 501 assertions passed; Code Analyzer/scope/formal-artifact
  violations `0/0/0`.
- The suite retains all A3 coverage and adds 22 named A4 tests for unreturned
  starts, formal bypass rejection, registered roots, overwrite rejection, and
  calibration byte snapshots, in addition to valid-start selection, V3 hex
  restoration/tamper rejection, split manifests, committed
  threshold loading, validation plan/trial hashes, finalizer recomputation,
  calibration byte immutability, and the executable two-commit lifecycle.
- Frozen Stage7.1, Stage6, Stage5, and Step11 verification passed.
- `calibration/`, `results/`, and `figures/` contain only `.gitkeep`.

## I. Formal Execution Not Performed

No formal calibration cell, Lambda sample, bootstrap threshold, 6000-trial K1
validation, Stage8.2 holdout, performance number, or PNG was generated. This
audit does not authorize or execute Stage8.1B or Stage8.2.

## J. Stage8.1B Readiness Decision

If separately authorized later, Stage8.1B must use two commits:

1. From the clean A4 code commit, run repository-external calibration shards,
   collect 300 cells, freeze two thresholds, and create
   `docs(stage8.1): freeze k1 bootstrap thresholds`.
2. From that clean threshold-evidence commit, rebuild the frozen plan, verify
   provenance, run primary K1 validation with paired sensitivity, and create
   `docs(stage8.1): validate k1 false-split control`.

技术上允许后续单独授权 Stage8.1B：正式 K1 bootstrap threshold calibration 和
primary K1 validation。
