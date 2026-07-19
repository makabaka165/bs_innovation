# Step12.6A Stage8.0 K1/K2 Bootstrap Resolution Contracts

## Status

`AUTHORIZED_STAGE8_0_CODE_ONLY`

This directory freezes and unit-tests the K1/K2 fitting, nonregular LRT,
parametric-bootstrap, separation-confidence, and six-state decision contracts.
Stage8.0 contains no calibrated threshold, validation result, holdout result,
Monte Carlo performance number, or Stage8.1/8.2 completion marker.

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
- Each noise profile reconstructs its own fixed `W_I`, `C_I`, and `T_I`.
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

Coefficient recovery uses an economy-SVD pseudoinverse. Effective rank below K
returns `NUMERIC_RANK_DEFICIENT`; no inverse Gram matrix, absolute ridge, or
fixed RSS floor is used.

## Bootstrap And Threshold

K1 calibration uses `alpha=0.05`, `Bboot_per_cell=199`, and the type-1 order
statistic. Each bootstrap sample is generated in fixed whitened coordinates
from fitted `G1_hat`, `S1_hat`, and `sigma2_hat`, then fully refits K1 and K2.
Each physical measurement configuration has one global threshold:

```text
q_global = max(q_cell_0p95 over all 150 registered K1 cells)
```

`lookup_locked_lrt_threshold` accepts only a measurement configuration ID and
a locked artifact. It has no scene, truth, score-gap, or estimated-separation
input.

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

## Frozen Future Work

`build_stage8_calibration_plan`, `build_stage8_validation_plan`, and
`build_stage8_holdout_plan` freeze the Stage8.1/8.2 cells, sample counts, seeds,
baselines, and evaluation gates. Their execution status is
`FROZEN_NOT_EXECUTED_STAGE8_0`. Formal offline calibration contains 59,700
planned bootstrap samples across two measurement configurations; this runner
does not execute them.

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
```

The suite uses small deterministic fixtures, verifies all registered starts,
nested RSS, `r_C*L`, full bootstrap refits, global-threshold aggregation,
separation confidence, state logic, plan/seed isolation, stable identity,
scope exclusions, and frozen Stage7.1/6/5/Step11 evidence. It writes no formal
artifact.
