# Stage8 K2 White-SNR Monte Carlo Theory and Protocol

Status: `AUTHORIZED_FOR_DIRECT_TANGENT_BRANCH_EXECUTION`

Protocol:
`STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_AND_CLOSURE_V1`

Authorization:
`AUTHORIZE_STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_AND_CLOSURE_V1`

Starting commit:
`5753cd706d139dcc4904ff20b3cef205f5954e7d`

## Purpose

This experiment measures the operating region of the frozen
`TANGENT_PROFILE_SAFE` estimator when expected total-energy SNR after the
registered sequential measurement and whitener is the controlled variable.
It repeats each exact factor cell ten times so that fallback behavior and
paired relative performance can be summarized beyond the single-realization
Stage8 K2 SNR-domain validation.

This protocol does not authorize changes to Tangent, Core-Lite, Core-Plus,
the measurement, the whitener, the source/noise models, or the SNR formulas.

## Controlled SNR

For unscaled element-domain signal

\[
X_{e,0}=A(\Theta)S_0,
\]

the whitened sequential-beamspace signal and covariance are

\[
X_{w,0}=T_IW_I^HX_{e,0}, \qquad C_w=T_IC_IT_I^H.
\]

For target linear SNR \(\gamma_w^\star\), the only permitted signal scale is

\[
\alpha=\sqrt{\frac{\gamma_w^\star L\,\operatorname{tr}(C_w)}
{\lVert X_{w,0}\rVert_F^2}}.
\]

The implementation must use the measured `trace(C_w)`, never the whitening
rank as a replacement, and must not use realized noise energy to choose
`alpha`.

## Fixed Design

The registered factors are:

- white-SNR target: `-6, 0, +6, +10, +14, +18, +22 dB`;
- noise: `WHITE`, `STAGE5_TOEPLITZ_CORRELATED`;
- snapshots: `L = 1, 4, 8`;
- geometry: `P1, P2, P3, P4`;
- independent replicates per exact cell: `10`.

This gives `1680` trials and `5040` method rows for `CORE_LITE`,
`CORE_PLUS`, and `TANGENT_PROFILE_SAFE`.

## Common Random Numbers

There are `240` independent base realizations. Within one
`noise x L x profile x replicate` realization, all seven SNR targets reuse
the same normalized source matrix, source phase, source seed, noise matrix,
and noise seed. Only the common signal scale changes.

For zero-based `base_realization_index`:

```text
source_seed = 430100000 + base_realization_index
noise_seed  = 430200000 + base_realization_index
```

Seeds are unique across the 240 base realizations. The frozen `L=1` fully
coherent source contract remains in force.

## Integrity Contracts

Every trial must satisfy:

- expected white-SNR target error at most `1e-10 dB`;
- one unique scientific trial hash across all `1680` trials;
- identical fit input for all three methods;
- zero use of truth, profile label, projected K2 SNR, target SNR, previous SNR
  results, or other method results inside an estimator;
- frozen code and `31_*` through `42_*` evidence remain byte-identical.

Truth and projected K2 SNR are evaluation-only data. Projected K2 SNR bins
are descriptive and cannot become an online selector or production threshold.

## Recoverable Execution

Execution uses one MATLAB R2022b process with `-singleCompThread`. Each trial
is committed atomically to a validated checkpoint. A resumed run verifies the
registry, code identity, checkpoint schema, and scientific hash before
skipping completed trials. Temporary or invalid checkpoints never authorize
silent overwrite.

## Registered Summaries

Results are summarized by white SNR overall, SNR by profile, SNR by noise,
SNR by `L`, and exact factor cell. Exact cells have `N=10`; they report
medians, fallback, validity, and paired wins/ties/losses, but not stable P90
or confidence intervals.

Paired comparisons use

\[
\Delta=\mathrm{RMSE}_{\mathrm{Tangent}}-
\mathrm{RMSE}_{\mathrm{baseline}},
\]

with `abs(delta) <= 1e-6 deg` treated as a tie.

## Working-Region Classification

- `FALLBACK_DOMINATED`: Tangent fallback rate is at least `0.50`.
- `RELATIVE_GAIN_UNSTABLE`: fallback is below `0.50` and Tangent median joint
  RMSE improves on at least one baseline, without meeting all stable gates.
- `STABLE_RELATIVE_GAIN`: Tangent is fully valid, fallback is below `0.50`,
  median and P90 joint RMSE do not exceed either baseline, and Tangent has
  more wins than losses against both baselines.
- `NO_RELATIVE_GAIN`: none of the preceding classifications applies.

The first stable point is reported overall and for each profile. If a higher
SNR point loses the stable classification, the result is explicitly marked
`NON_MONOTONIC_EMPIRICAL_REGION`; no monotonic threshold is claimed.

## Scientific Boundary and Closure

The `-6/0/+6 dB` Stage8 K2 single-realization results are reference points,
not pass/fail gates. The Monte Carlo only asks whether they lie within a
reasonable part of the repeated-trial distribution.

Regardless of performance:

```text
DEFAULT_K2 = TANGENT_PROFILE_SAFE
Tangent algorithm modified = false
Production interface modified = false
New online SNR threshold = false
Automatic selector = false
Further Stage8-K2 algorithm development = NOT_AUTHORIZED
```

After this protocol, permitted work is limited to thesis formulas, figures,
operating-range interpretation, and limitations.
