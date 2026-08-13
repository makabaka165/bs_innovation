# Stage8 K2 Classical Baseline Theory and Protocol

Protocol: `STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_V1`

Authorization: `AUTHORIZE_STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_V1`

Branch: `experiment/stage8-k2-classical-baselines-v1`

Exact base: `721c30aa96f1687c757004613c23e9fb6a814afd`

## 1. Purpose and boundary

This isolated comparison asks only:

1. How much accuracy Tangent-Profile retains relative to a less constrained
   full four-coordinate known-K conditional-ML fit on the same beamspace.
2. Whether the P2/P4 scale degradation is primarily caused by the fixed
   Tangent center/axis, by the registered beamspace measurement, or by an ML
   threshold/statistical ambiguity shared by beamspace and element fits.
3. How Tangent and ML compare with standard MUSIC where the sample-subspace
   assumptions of standard MUSIC are applicable.

The experiment does not change Tangent-Profile, Core-Lite, Core-Plus,
Step12.7, evidence 31/32, the original Tangent branch, Core-V2, or main. It
does not address automatic K, resolved/unresolved decisions, bootstrap,
production integration, or a new Tangent algorithm.

The historical decision `STAGE8_K2_TANGENT_PROFILE_RETAIN` remains unchanged.

## 2. Frozen evidence and common data

The experiment reconstructs the exact 72-trial TP1 registry and data from the
frozen generator contract:

- identical profile, noise, L, SNR, source-seed, and noise-seed registry;
- identical deterministic source construction and SNR scaling;
- identical element manifold and element-noise generation;
- identical registered `Y_element` for every method in one trial.

Every reconstructed `element_trial_hash` must equal the corresponding hash in
`31_stage8_k2_tangent_profile_trials.csv`. All 72 hashes must match before any
formal baseline is run. The fit never receives truth angles, profile identity,
or a frozen method estimate as an initializer. Complete element observations
are runtime-only and are not committed.

The frozen rows for `CORE_LITE`, `CORE_PLUS`, and `TANGENT_PROFILE_SAFE` are
read from evidence 31. Corrected axis diagnostics are read from evidence 32.
Those methods are not refit.

## 3. Literature position

### 3.1 MUSIC

R. O. Schmidt, "Multiple Emitter Location and Signal Parameter Estimation,"
IEEE Transactions on Antennas and Propagation, 1986,
DOI `10.1109/TAP.1986.1143830`.

Standard MUSIC uses an eigendecomposition of the sample covariance to split a
known two-dimensional signal subspace from its noise subspace. For `L=1`, the
sample covariance has rank at most one and cannot support the registered
known-`K=2` signal subspace. Therefore standard MUSIC is applicable only for
`L in {4,8}` and is marked
`NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK` for `L=1`. This status is
not a failure and is excluded from wins and losses.

Spatial smoothing is excluded. The physical cylindrical array and sequential
beamspace have no preregistered shift-invariant ULA subarray contract; adding
smoothing would change aperture and measurement rather than preserve the
same-condition comparison. Forward/backward smoothing and root-MUSIC are also
outside scope.

### 3.2 Conditional ML / DML

P. Stoica and K. C. Sharman, "Maximum Likelihood Methods for Direction-of-
Arrival Estimation," IEEE TASSP, 1990, DOI `10.1109/29.57542`.

I. Ziskind and M. Wax, "Maximum Likelihood Localization of Multiple Sources
by Alternating Projection," IEEE TASSP, 1988, DOI `10.1109/29.7543`.

For known `K=2` and fixed exact whitening,

```math
Z = G(\Theta)S + N, \qquad N \sim \mathcal{CN}(0,I).
```

Concentrating out the unknown deterministic source coefficients gives

```math
\widehat S(\Theta) = G^\dagger(\Theta)Z,
\qquad
RSS(\Theta) = \|\Pi_{G(\Theta)}^\perp Z\|_F^2.
```

The theoretical full known-K CML/DML problem is

```math
\widehat\Theta_{\rm CML} =
\arg\min_{\Theta\in\Omega^2,\,\operatorname{rank}G=2} RSS(\Theta).
```

Unlike Tangent-Profile, this model permits both endpoints, their center, axis,
and separation to vary independently. The implemented methods are named
`FULL4D_BEAMSPACE_CML_MULTISTART` and
`FULL4D_ELEMENT_CML_MULTISTART`. They are deterministic finite-multistart
numerical approximations, not proofs of a globally optimal exact-ML solution.

### 3.3 Approximate ML and Partial Relaxation

F. Vincent, O. Besson, and E. Chaumette, "Approximate Maximum Likelihood
Estimation of Two Closely Spaced Sources," Signal Processing, 2014,
DOI `10.1016/j.sigpro.2013.10.017`.

D. Bonacci, F. Vincent, and B. Gigleux, "Robust DoA Estimation in Case of
Multipath Environment for a Sense and Avoid Airborne Radar," IET Radar,
Sonar & Navigation, 2017, DOI `10.1049/iet-rsn.2016.0446`.

Those close-pair reductions rely on one-dimensional ULA/NULA parameterizations
and specific Taylor approximations. Directly transplanting them to the current
two-dimensional azimuth/elevation cylindrical-array, exactly whitened
sequential-beamspace problem would simultaneously change the array,
parameterization, and estimator. They are literature context only.

M. Trinh-Hoang, M. Viberg, and M. Pesavento, "Partial Relaxation Approach: An
Eigenvalue-Based DOA Estimator Framework," arXiv `1711.01982`.

PR-DML supports general arrays, but its two-dimensional local-manifold
implementation, peak pairing, and `L=1` identifiability require a separate
protocol. It is not added during this baseline comparison.

## 4. Registered methods and subsets

| Method | Registered trials | Observation |
|---|---:|---|
| `CORE_LITE` | frozen 72 | evidence 31 |
| `CORE_PLUS` | frozen 72 | evidence 31 |
| `TANGENT_PROFILE_SAFE` | frozen 72 | evidence 31/32 |
| `FULL4D_BEAMSPACE_CML_MULTISTART` | 72 | exact registered beamspace whitening |
| `FULL4D_ELEMENT_CML_MULTISTART` | 24 | exact element-covariance whitening |
| `BEAMSPACE_MUSIC_K2` | 48 applicable, 24 N/A | `L in {4,8}` |
| `ELEMENT_MUSIC_K2` | 48 applicable, 24 N/A | `L in {4,8}` |

The 24-trial element reference subset is exactly `L=4`, both noise profiles,
all three SNR values, and P1-P4. The MUSIC subset is exactly all 48 trials with
`L in {4,8}`.

The fair comparison sets are:

- all 72: Core-Lite, Core-Plus, Tangent, and full beamspace CML;
- element reference 24: Tangent, beamspace CML, and element CML;
- MUSIC applicable 48: Tangent, beamspace CML, beamspace MUSIC, and element
  MUSIC. Core rows may be retained as an appendix.

## 5. Full4D finite-multistart CML

Beamspace data use exactly
`Z_white = T_I * W_I' * Y_element` and the frozen
`build_full_sequential_local_manifold`. Element data and manifolds use
`R_n,elem^(-1/2)` computed from `model.Rn_elem` by Cholesky, with a stable
Hermitian-eigenvalue fallback. Element white noise is never assumed.

All unordered pairs of distinct points on the frozen 7-by-3 local grid are
scored with `concentrated_dml_rss`, `requested_rank=2`. Ranking is deterministic
by likelihood and then endpoint lexicographic order. The top six unique pairs
are the only starts. Truth, profile ID, Tangent, and Core outputs are prohibited
from start generation.

Each start is represented as four independent endpoint coordinates via
`[c_az,c_el,d_az,d_el]`. The representation permits center, direction, and
separation changes while enforcing endpoint bounds, an unoriented canonical
difference, separation at least `1e-3 deg`, full manifold rank two, and finite
RSS/log likelihood.

The frozen deterministic coordinate-profile budget is:

- top starts: 6;
- maximum sweeps: 12;
- scan nodes per coordinate: 9;
- `fminbnd TolX`: `1e-4 deg`;
- `fminbnd MaxFunEvals`: 80;
- update order: center azimuth, center elevation, difference azimuth,
  difference elevation.

The best finite valid endpoint set over all starts is returned even when a
strict stationary status is not reached. Output records optimizer status,
sweep count, selected start ID, score/SVD counts, and runtime. If the full4D
beamspace result has lower log likelihood than the frozen raw Tangent candidate,
the row records `NUMERICAL_OPTIMIZATION_INCOMPLETE`; the budget is not retuned.

## 6. Standard MUSIC

For applicable trials, sample covariances are

```math
\widehat R_b = Z_wZ_w^H/L,
\qquad
\widehat R_e = Y_{e,w}Y_{e,w}^H/L.
```

A Hermitian eigendecomposition orders eigenvalues descending. The first two
eigenvectors form the known-K signal subspace and the remainder form the noise
subspace. Numerical sample rank below two yields
`MUSIC_SIGNAL_SUBSPACE_RANK_DEFICIENT`.

Both spectra use the same frozen local bounds and a fixed `0.005 deg` azimuth
and elevation grid. Beamspace uses the exact `g(az,el)` and element MUSIC uses
the exactly whitened `a_w(az,el)`.

Peak picking is data-only: enumerate 8-neighbor local maxima, collapse a
plateau deterministically by spectrum value and then azimuth/elevation lexical
order, sort descending, and return the highest two distinct local peaks. It
uses no truth matching and no truth-derived minimum peak distance. Fewer than
two peaks is invalid.

## 7. Metrics and reporting

Truth is used only after estimation for the best of the two target
permutations. Each applicable output records:

- joint endpoint RMSE;
- center error;
- unoriented axis error `acosd(abs(u_hat' * u_true))`, or `NaN` for a
  numerically zero estimated separation;
- separation-magnitude error;
- matched separation-vector error;
- score calls, SVD/eig calls, runtime, coarse candidates, and continuous
  starts.

Summaries report valid/applicable counts and median/p90 values for all accuracy
metrics and runtime, overall and stratified by P1-P4, SNR, L, and noise.
Paired joint-RMSE wins/ties/losses use `1e-6 deg` as a display-only tie
tolerance. No bootstrap and no new pass/fail gate are introduced. Beamspace and
element likelihood numbers are not compared directly because their observation
dimensions differ.

## 8. Interpretation matrix

- A: beamspace full4D CML materially repairs P2/P4 endpoint/separation errors
  relative to Tangent. The fixed K1 center/axis is the primary limitation and
  a later center or alpha-rho study has theoretical motivation.
- B: beamspace CML does not repair P2/P4 but element CML does. The registered
  3-by-5 beamspace loses relevant K2 information.
- C: beamspace and element CML both show scale collapse or outliers. The case
  is in an ML threshold/statistical ambiguity region under low SNR,
  correlation, weak secondary power, or small separation.
- D: Tangent is close to beamspace CML at materially lower registered call
  count. Tangent is an effective system-specific dimension reduction.

MUSIC conclusions use only the 48 applicable trials. The 24 `L=1` N/A rows
cannot be counted as Tangent wins.

## 9. Alpha-rho theoretical appendix

For a fixed Tangent axis `u_hat`, a possible later parameterization is

```math
\xi_1 = \widehat c + \alpha\widehat u - \frac{\rho}{2}\widehat u,
\qquad
\xi_2 = \widehat c + \alpha\widehat u + \frac{\rho}{2}\widehat u.
```

The current Tangent uses `alpha=0`; free alpha could correct a K1 center offset
along the fixed axis. This two-dimensional fit would be a constrained slice of
full CML. In this protocol it is `NOT_IMPLEMENTED`, `NOT_TUNED`, and
`NOT_VALIDATED`. Only interpretation A can motivate a separately authorized
follow-up.

## 10. Execution and evidence

Execution uses MATLAB R2022b, `-singleCompThread`, and one MATLAB process. It
uses no pool, `parfor`, coordinator, scheduled task, bootstrap, or resumable
checkpoint framework. Runtime is isolated under
`E:/bs_innovation_runtime/stage8_k2_classical_baselines_v1`.

Four smoke cases are run first: P1/P2 with white noise and P3/P4 with correlated
noise, all at `L=4`, `SNR=0`. Smoke checks only finite fits, exact element hash,
truth isolation, MUSIC applicability, and execution of the full CML search.
The formal comparison then runs once from the start.

Committed result evidence is limited to the `34_stage8_k2_classical_baseline_*`
report and CSV tables. No complete `Y_element` is committed. Completion does
not authorize an alpha-rho implementation, Tangent modification, expanded
trials, additional MUSIC variants, deep learning, automatic K, or a merge back
to an upstream branch.
