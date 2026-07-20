# Stage8.1A3 / Stage8.1B Execution Readiness Audit

> Date: 2026-07-19
> Repository: `makabaka165/bs_innovation`
> Code baseline: `26b94b57e9d17699783109566468e59df86346e4`
> Runtime: MATLAB R2022b, `phase_factor=1`
> Scope: code-only; no formal calibration, threshold, validation, holdout, or PNG

## A. Stage8.1A3 Conclusion

Stage8.1A3 closes the remaining executable-contract defects in K1 validation,
threshold provenance, formal calibration shards/checkpoints, group-noise scale
handling, and validation RNG roles. It does not change `alpha=0.05`,
`beta=0.05`, `Bboot=199`, `Bsep=199`, minimum valid fraction `0.90`, the
`0.21` degree engineering half-width, K1/K2 starts, the Stage5 domain,
`RECT_E14_A31`, or frozen Stage7.1/6/5/Step11 evidence.

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
| `stage8_source_tree_hash` | `68960fb22115b6d85a6141bfd22e01c29ceaf3f87c3069166585190b87d3553f` |
| `stage8_stable_code_identity` | `78acde57bdc232fec5d93478b4ff155fb5e0fc5dd5a4c988883356885202aa11` |
| `stage8_fit_contract_hash` | `d3638412d5e6dbcae142a96f34a26c55d80f7ced2cc313b8f0e3817db6a9e2c1` |
| `stage8_calibration_plan_hash` | `3c8f71a65e67ed0db7a1551a1594761c737ad8606101d48fcf76fcf40d67c291` |
| `stage8_validation_plan_hash` | `9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7` |
| `stage8_plan_hash` | `f846aa7bc11494feec14f6d8363312b103216a015cfa3cf65546f9b1255153a0` |
| `measurement_registry_hash` | `f20773e1165b8519368b3a4dd3e74b250d84f3a7199f560036e5235988017688` |

The calibration and validation plan hashes are unchanged because their frozen
cells, seeds, statistical constants, paired strata, and gates are unchanged.
The source, fit-contract, and total-plan identities change because A3 repairs
start eligibility and the self-contained evidence lifecycle.

## H. Tests And Scope

- Stage8.0: 428 assertions passed; Code Analyzer/scope violations `0/0`.
- Stage8.1A3: 479 assertions passed; Code Analyzer/scope/formal-artifact
  violations `0/0/0`.
- The suite retains all A2 coverage and adds 32 named A3 tests for valid-start
  selection, V3 hex restoration/tamper rejection, split manifests, committed
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

1. From the clean A2 code commit, run repository-external calibration shards,
   collect 300 cells, freeze two thresholds, and create
   `docs(stage8.1): freeze k1 bootstrap thresholds`.
2. From that clean threshold-evidence commit, rebuild the frozen plan, verify
   provenance, run primary K1 validation with paired sensitivity, and create
   `docs(stage8.1): validate k1 false-split control`.

技术上允许后续单独授权 Stage8.1B：正式 K1 bootstrap threshold calibration 和
primary K1 validation。
