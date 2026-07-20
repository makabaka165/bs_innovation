# Stage8.1A4 Non-Bypassable Formal Evidence Paths

## Status

`PASS_STAGE8_1A4_CODE_ONLY`

This directory freezes and unit-tests the K1/K2 fitting, nonregular LRT,
element-domain parametric bootstrap, separation-confidence, resumable
calibration, paired K1-validation, and six-state decision contracts. Stage8.1A4
is code-only: it contains no calibrated threshold, validation result, holdout
result, Monte Carlo performance number, or Stage8.1B/8.2 completion marker.

## Statistical Boundary

The likelihood-ratio test, concentrated likelihood, parametric bootstrap,
source enumeration, bootstrap confidence region, statistical resolution limit,
and unresolved/abstention state are prior art. The Stage8 contribution is only
their engineering integration with the factor-1 sequential DBF, stable
whitened DML, Stage5 initialization chain, and frozen Stage7 physical subsets.

For effective whitened dimension `r_C` and snapshot count `L`, Stage8 uses

```text
n_C          = r_C * L
sigma2_hat_K = RSS_K / n_C
ell_K        = -n_C * (log(pi * sigma2_hat_K) + 1)
Lambda_12    = 2 * n_C * log(RSS_1 / RSS_2)
```

An ordinary chi-square cutoff is diagnostic only and is never a main decision
threshold.

## Fixed Measurement And Domain

- `PRIMARY_RECT_E14_A31` reads Stage7 `RECT_E14_A31`: 3 elevation channels,
  5 conditional azimuth outputs per channel, and 15 outputs in total.
- `SENSITIVITY_FULL_PARENT_5X5` reads Stage7 `RECT_E31_A31` and is sensitivity
  only.
- The four-entry registry resolves PRIMARY/FULL_PARENT times
  WHITE/CORRELATED. Each object retains its own fixed `W_I`, `C_I`, `T_I`,
  `Rn_elem`, noise factorization, subset, array, and factorized V/U metadata.
- The common Stage5 domain is azimuth `7.4:0.2:8.6` degrees and elevation
  `9.8:0.2:10.2` degrees around conventional center `[8,10]` degrees.
- K1, K2, every calibration refit, and every separation refit use the same
  measurement, domain, and solver contract.

## Registered Fits

K1 always charges two starts:

```text
K1_GROUPED_Q1_KQ1
K1_CONVENTIONAL_SINGLETON_PEAK
```

K2 always charges three starts:

```text
K2_GROUPED_Q1_KQ2
K2_GROUPED_Q2_KQ1_PLUS_KQ1
K2_K1_EMBEDDED_NESTED_START
```

The nested start contains the fitted K1 manifold column exactly and chooses the
lexicographically first full-rank registered anchor at maximum projected
Fisher distance. A failed grouped start is recorded; it does not gate the
other starts and does not create a fourth rescue start. Every valid start uses
the same Stage5 full sequential joint refinement. Q and Kq are initialization
structure only, never final oracle outputs.

Best-start selection is
`MAXIMUM_CONCENTRATED_LOG_LIKELIHOOD_AMONG_VALID_REGISTERED_STARTS`. A start
is eligible only when its initialization is available, its estimate was
returned and converged, its effective rank is at least K, RSS and variance are
finite nonnegative reals, concentrated log likelihood is finite, all fixed
measurement/domain/solver/observation identities are complete, and
`phase_factor=1`. A nonconverged high-likelihood start remains in
`all_start_results` but cannot replace a lower-likelihood valid start. Outputs
record disjoint `initialization_failed_start_count`,
`unreturned_start_count`, `nonconverged_start_count`,
`rank_deficient_start_count`, `numeric_invalid_start_count`, and
`valid_start_count` values. A refinement that returns no estimate retains its
registered initialization ID, status, history, and measured score/SVD/runtime
cost in `all_start_results`, but it is never selected or misclassified as rank
deficient. Every registered start is still run and charged.

Coefficient recovery uses an economy-SVD pseudoinverse. Effective rank below K
returns `NUMERIC_RANK_DEFICIENT`; no inverse Gram matrix, absolute ridge, or
fixed RSS floor is used.

An invalid recovered group-noise scale is never replaced by a unit scale. The
affected grouped partition is marked `GROUP_NOISE_SCALE_INVALID` and becomes
unavailable, while the conventional start and other independently valid fixed
grouped starts continue. Results expose `invalid_group_noise_scale_count` and
`group_noise_scale_status`.

## Bootstrap And Threshold

K1 calibration uses `alpha=0.05`, `Bboot_per_cell=199`, and the type-1 order
statistic. Each bootstrap sample is generated in element coordinates as
`A_element(theta_hat)*S_hat + N_element`, with
`N_element ~ CN(0,sigma2_hat*Rn_elem)`, then passed through the fixed
`W_I/T_I` chain and fully refitted under K1 and K2. Element observations are
retained so every bootstrap sample reruns the registered Stage4/5
initialization factory.
Each physical measurement configuration has one global threshold:

```text
q_global = max(q_cell_0p95 over all 150 registered K1 cells)
```

The 300 calibration data seeds start at `2026072100`. The 300 bootstrap blocks
start at `2126072100`, use stride 1000, and reserve exactly 199 active seeds per
cell. All 59,700 active bootstrap seeds are unique and disjoint from data,
validation, and holdout spaces.

One shared fit-validity function requires returned and converged estimates,
effective rank at least K, finite nonnegative RSS and variance, finite
concentrated log likelihood, and matching fixed identities. A failed formal
calibration refit invalidates its complete cell; samples are never deleted
before taking a quantile.

Locked thresholds use `STAGE8_LOCKED_THRESHOLD_ARTIFACT_V3`. Its hash payload
is a fixed whitelist of four plan/source registry identities, config ID,
`q_global_hex=num2hex(q_global)`, `alpha_hex=num2hex(alpha)`, registered
counts/policies, calibration hash, source identity, and status. Decimal values
remain human-readable, while lookup restores exact doubles with `hex2num` and
rejects decimal/hex disagreement. Runtime HEAD and added runtime metadata do
not enter the artifact hash.

`lookup_locked_lrt_threshold` accepts only a measurement configuration ID, a
locked artifact, and an expected threshold contract. Before returning a value,
it exactly matches stable Stage8 code, Stage8 plan, calibration-plan, and
measurement-registry hashes, then verifies the threshold artifact hash. It has
no scene, truth, score-gap, or estimated-separation input.

K2 separation confidence uses `beta=0.05`, `Bsep=199`, minimum valid fraction
`0.90`, complete K2 refits, and minimum two-dimensional angular-cost label
matching. The projected Stage6 metric is evaluated at the fitted K2 center.
Zero is excluded only by the strict metric inequality. Simultaneous azimuth
and elevation half-width gates are both fixed at `0.21` degree.

## States

Only these states are active:

```text
K1
K2_RESOLVED
K2_UNRESOLVED
OUT_OF_LOCAL_CELL
SEARCH_NOT_CONVERGED
NUMERIC_RANK_DEFICIENT
```

`MODEL_MISMATCH_STATE_DISABLED_UNTIL_CALIBRATED_GOF`. Hidden simulation truth
cannot enter the classifier. Wrong-confidence resolved outputs in mismatch
holdout remain part of the registered risk.

## Executable Stage8.1 Contracts

`run_stage8_1_calibration_cell` is the minimum checkpoint unit. `FORMAL_SHARD`
materializes only explicitly requested plan rows. A cell input hash depends on
its frozen plan row, data seed, model identity, source identity, and
calibration-plan identity, never shard order or shard size. A checkpoint is
reused only when source, plan, model, and cell-input identities all match;
otherwise reuse fails without overwrite. Formal execution requires an explicit
checkpoint root outside the Git repository. The repository-local
`calibration/checkpoints` location is forbidden. The manifest loader and cell
collector combine shards, reject missing, duplicate, malformed, or stale
checkpoints, and permit aggregation only after all 300 PASS cells and all
59,700 unique seeds are present.

K1 validation freezes six `L x noise` strata, 1000 common element trials per
stratum, and two paired measurement evaluations per trial: 6000 common trials
and 12,000 method rows. Its seed base is `2226072200`, with one nonoverlapping
3000-seed block per stratum: 1000 parameter seeds, 1000 element-noise seeds,
and 1000 separation-auxiliary seeds. Both configurations share all three roles
for a common trial; separation bootstrap uses the auxiliary seed with fixed
substreams. Parameter and noise RNGs are never reset from one shared seed.

Validation summaries are keyed by `measurement_config_id x summary_scope`,
where scope is `OVERALL` or one of six strata. The formal table therefore has
14 rows: 6000 observations in each config-level overall row and 1000 in each
config/stratum row. Only `PRIMARY_RECT_E14_A31` authorizes Stage8.2. The full
parent is labeled
`SENSITIVITY_ONLY_NOT_USED_FOR_STAGE8_2_AUTHORIZATION`; it cannot offset a
primary failure. A separate paired-sensitivity table reports state and
false-split, false-resolved, and nondecision discordance for every common
trial. Validation preflights both provenance-bound thresholds before its first
trial, only looks them up, and cannot recalibrate them.

## Stage8.1B Two-Commit Lifecycle

Formal Stage8.1B remains separately authorized and must use two evidence
commits in this order:

1. Start from the clean Stage8.1A4 code commit, run calibration shards with a
   checkpoint root outside the Git repository, collect all 300 cells, freeze
   two thresholds, and create
   `docs(stage8.1): freeze k1 bootstrap thresholds`.
2. Start from that clean threshold evidence commit, rebuild the current frozen
   Stage8 plan, preflight exact threshold provenance, run 6000 common K1 trials
   and 12,000 paired config rows, keep primary authorization separate from
   sensitivity, and create
   `docs(stage8.1): validate k1 false-split control`.

Validation is forbidden in a working tree containing uncommitted threshold
evidence. Stage8.2 still requires a later, separate authorization.

Calibration and validation have separate artifact registries, writers,
manifests, and deterministic bundle identities. The calibration freezer
collects all checkpoints, writes only calibration evidence, and never creates
validation placeholders. `load_stage8_1_locked_thresholds` requires a clean
tracked evidence commit in formal mode, recomputes every deterministic file
hash and bundle identity, restores both V3 thresholds losslessly, and verifies
the exact current plan. Formal validation can start only through
`run_stage8_1_k1_validation_from_frozen_thresholds`.

Formal evidence paths are not caller-configurable escape hatches. The loader,
public validation wrapper, and finalizer force tracked calibration evidence;
an explicit `require_tracked_artifacts=false` fails before authorization or
execution. Formal freezing and finalization force `overwrite=false`. Their
artifact root is exactly this registered Stage8 step directory, with only
`.gitkeep` allowed in the target lifecycle before writing. Calibration
checkpoints remain subject to the separate rule that their root must be
outside the repository. The validation wrapper records
`COMMITTED_THRESHOLD_PREFLIGHT_PASS` and captures SHA-256 for every
deterministic calibration artifact plus its manifest before trials. The
finalizer reloads calibration from disk and requires the pre-validation,
pre-write, and post-write snapshots to match.

The validation-output validator independently compares raw trials with the
current 12,000-row plan registry and recomputes the 14-row summary, paired
sensitivity, and PRIMARY gate. The finalizer reloads committed calibration
evidence, writes only the validation registry, and leaves every calibration
byte unchanged. The final identity is the SHA-256 binding of the calibration
evidence bundle and validation deterministic manifest. Runtime, each evidence
manifest itself, and checkpoint temporaries are excluded. Formal use of the
legacy monolithic writer fails with
`FORMAL_MONOLITHIC_STAGE8_1_WRITER_FORBIDDEN`. No Stage8.1 runner invokes
Stage8.2.

Offline complexity must report cells, bootstrap samples, K1/K2 fits, score and
SVD calls, runtime, memory, and artifact size. Online complexity must report
K1/K2 starts, threshold lookup, separation-bootstrap trigger rate and refits,
average latency, and worst-case latency.

## Provenance

Stable Stage8 code identity hashes the sorted Git index `mode/blob/path`
manifest for tracked Stage8 `.m` files and this README. It excludes runtime
HEAD and excludes `calibration/`, `results/`, and `figures/`. Formal execution
requires baseline ancestry, a clean working tree, and no untracked Stage8
source.

## Unit Tests

Run only the code-only suite:

```matlab
run_stage8_0_contract_unit_tests
run_stage8_1a_contract_unit_tests
```

The suite uses small deterministic fixtures and synthetic decision tables,
verifies all registered starts,
nested RSS, `r_C*L`, full bootstrap refits, global-threshold aggregation,
separation confidence, state logic, plan/seed isolation, stable identity,
scope exclusions, and frozen Stage7.1/6/5/Step11 evidence. It writes no formal
artifact. The Stage8.1A4 suite additionally checks all seed spaces, four-model
resolution, element-bootstrap mean/covariance, real initialization, unified
fit validity, checkpoint mismatch behavior, 300-cell aggregation, 14-row
primary/sensitivity summaries, exact threshold provenance, formal
shard/checkpoint collection, RNG-role separation, the two-commit lifecycle,
writer determinism, valid-start selection, V3 hex round trips and tamper
rejection, calibration-only freezing, committed threshold loading, raw-trial
plan binding, finalizer recomputation, calibration byte immutability, the
executable two-stage lifecycle, and the Stage8.2 stop boundary.
It also exercises unreturned registered starts, disjoint start diagnostics,
formal tracked-evidence bypass rejection, registered artifact roots,
no-overwrite evidence creation, committed-threshold preflight, and calibration
snapshot immutability.
