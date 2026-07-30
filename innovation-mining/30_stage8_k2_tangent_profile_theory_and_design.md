# Stage8 K2 Tangent-Profile Theory and Design

Protocol: `STAGE8_K2_TANGENT_PROFILE_DECISIVE_EXPERIMENT_V1`

Authorization: `AUTHORIZE_STAGE8_K2_TANGENT_PROFILE_DECISIVE_EXPERIMENT_V1`

Base branch: `experiment/stage8-core-v2` at
`9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7`.

Execution branch: `experiment/stage8-k2-tangent-profile-v1`.

## 1. Scope and immutable boundary

The experiment asks one question: for a known two-source problem in one
selected range-Doppler cell of one CPI, can the projected residual of a K1
fit identify a two-dimensional separation direction, so that the K2
continuous search becomes a one-dimensional full-manifold profile search?

The experiment does not estimate K, use tracking or cross-CPI data, change
the selected measurement, alter whitening, or modify the local angular
domain. The production Step12.7 implementation, Core-Lite, Core-Plus,
`innovation-mining/29_*`, and their source branches are read-only.

The only online safe baseline is the frozen Core-Lite fixed-grid K2 fit.
Truth, profile identity, SNR, snapshot count, noise identity, geometric q,
and Gamma diagnostics are unavailable to all fitting and selection logic.

## 2. Local two-source model

Let the exactly whitened sequential manifold be `g(xi)`, where
`xi = [azimuth; elevation]`. Write two endpoints as

```text
xi1 = c - d/2
xi2 = c + d/2
```

and the whitened data as

```text
Z = g(xi1) s1^T + g(xi2) s2^T + N.
```

With `a = s1 + s2` and `b = s2 - s1`, a local expansion at `c` gives

```text
Z = g(c) a^T
    + (1/2) Jg(c) d b^T
    + (1/8) Hg(c)[d,d] a^T
    + O(||d||^3) + N.
```

The first term is the effective one-source component. The second is the
first-order two-source separation component. The third is the leading
curvature term.

External angles and reported separations use degrees. The registered
manifold Jacobian is per-radian, so directions are unitless while all
quadratic geometry (`q` and `T`) is evaluated with a separation converted
to radians.

## 3. Projected residual direction

Run the frozen Core-Lite K1 estimator on the same K2 observation and call
its selected center `c_hat`. At that center define

```text
g = g(c_hat)
Pg_perp = I - g g^H / (g^H g)
B = Pg_perp Jg(c_hat)
R = Pg_perp Z.
```

The first-order residual model is

```text
R approximately equals (1/2) B d b^T + N_perp.
```

For `S_R = R R^H / L`, define the real symmetric matrices

```text
T   = Re(B^H B)
C_t = Re(B^H S_R B).
```

For a real direction `u`, the quotient

```text
J(u) = (u^T C_t u) / (u^T T u)
```

is maximized, under the noiseless first-order model and full column rank of
`B`, only when `u` is parallel to `d`. Thus the candidate direction is the
largest generalized eigenvector of

```text
C_t u = lambda T u.
```

Exactly whitened isotropic noise adds `sigma^2 T` to `C_t`; it shifts all
generalized eigenvalues without changing the population eigenvectors. The
algorithm therefore neither estimates nor subtracts a noise floor and does
not introduce an eigen-gap threshold.

## 4. Stable generalized eigensolve

Symmetrize `T`, eigendecompose it, and apply the already registered relative
numeric-rank rule. A direction exists only when `rank(T) = 2`. For positive
eigenvalues `Lambda` and matching eigenvectors `V`, form

```text
Q = V Lambda^(-1/2)
M = Q^T C_t Q.
```

Take the largest eigenvector `w_max` of the real symmetric `M`, map it back
as `u_hat = Q w_max`, and Euclidean-normalize it. The deterministic sign is

```text
u_el > 0
if abs(u_el) <= 1e-12, u_az >= 0.
```

Rank deficiency returns `TANGENT_METRIC_RANK_DEFICIENT` and creates no
alternate direction or additional start.

## 5. One-dimensional full-manifold profile

For positive scale `rho`, define

```text
xi1(rho) = c_hat - rho u_hat / 2
xi2(rho) = c_hat + rho u_hat / 2.
```

Compute the unique maximum feasible `rho` from the frozen rectangular local
domain so both endpoints remain inside the domain. The fixed solver contract
is:

```text
rho_min_deg       = 1e-3
scan_node_count   = 33
fminbnd TolX      = 1e-4 deg
fminbnd MaxFunEvals = 80
```

Score all 33 equally spaced nodes. Refine only within the neighbors of the
best node. Compare the best node, both bracket endpoints, and the `fminbnd`
candidate, then select the greatest concentrated log-likelihood. Every
score uses the exact full sequential whitened K2 manifold, the requested
rank-two contract, and concentrated DML. The Taylor model chooses only the
direction; it never replaces final scoring.

The raw tangent fit upgrades the frozen fixed-grid K2 fit only when it is
valid and its concentrated log-likelihood is at least the fixed-grid value.
Otherwise M2 returns the fixed-grid result with
`FIXED_GRID_FALLBACK`. No error metric or truth-derived quantity participates
in this choice.

## 6. Identifiability diagnostic

For truth-only post-fit analysis, let

```text
q = d_rad^T T_seq(c_true) d_rad
p_minus = ||s2 - s1||_F^2 / L
Gamma_K2_proxy = (1/2) ||s2 - s1||_F^2 q.
```

This is the registered `sigma^2 = 1` proxy for the product of projected
array geometry and difference-mode source energy. It may explain direction
error, scale error, validity, fallback, and RMSE after fitting. It is not an
online threshold and does not remove trials.

When `s1` and `s2` are nearly equal, `p_minus` approaches zero and the
first-order tangent term disappears. The remaining projected curvature has
amplitude order `||d||^2` and typically information order `||d||^4`. A K1
fit may also be displaced from the geometric midpoint for unequal powers.
V1 records these limitations and does not add center correction, a second
direction, a Hessian solver, asymmetric scales, or extra starts.

## 7. Independent experiment contract

The registry contains 72 new K2 trials:

```text
noise:  WHITE, STAGE5_TOEPLITZ_CORRELATED
L:      1, 4, 8
SNR:    -6, 0, +6 dB
profile: P1, P2, P3, P4
```

The four profiles are fixed as follows.

| Profile | Center [az,el] deg | Separation deg | Direction deg | Secondary power dB | Correlation for L>1 |
|---|---:|---:|---:|---:|---:|
| P1 | [8.00,10.00] | 0.30 | 45 | 0 | 0 |
| P2 | [8.20,10.00] | 0.20 | 0 | -6 | 0 |
| P3 | [7.90,10.10] | 0.15 | 90 | 0 | 0.9 |
| P4 | [8.10,9.95] | 0.10 | 135 | -6 | 0.9 |

Source seeds start at `3326074000`; noise seeds start at `3326075000`.
Each trial has one unique seed of each type. `L=1` uses correlation one by
the `L1_FULLY_COHERENT_BY_CONTRACT` rule. Every truth endpoint is checked
against the frozen local domain before generation.

Each generated `Y_element` is shared by exactly three methods:

```text
M0 = CORE_LITE
M1 = CORE_PLUS
M2 = TANGENT_PROFILE_SAFE
```

M0 and M1 call the frozen public Step12.7 interface. M2 calls the same
Core-Lite K1 path for its center and the same Core-Lite K2 path for its safe
baseline. The expected output is 216 method rows and 72 tangent diagnostic
rows. Element hashes prove method pairing.

The run uses MATLAB R2022b, `-singleCompThread`, and one MATLAB process. It
uses no pool, worker, coordinator, scheduled task, bootstrap, checkpoint
recovery, or multi-gate infrastructure. Runtime output is written first to
`E:/bs_innovation_runtime/stage8_k2_tangent_profile_v1` and repository
evidence is generated only after the complete run.

## 8. Tests, summaries, and decision

The four theory tests are exact noiseless direction recovery, isotropic
noise-shift invariance, rank-deficient rejection, and one full-manifold
synthetic smoke trial. Passing these tests authorizes the single formal run.

Results report valid counts, overall/profile/L/SNR RMSE summaries, paired
wins/ties/losses with a reporting-only `1e-6 deg` tie tolerance, direction
and scale errors, separation-vector error, score/SVD calls, runtime, and
Gamma quartiles. The final label follows the prompt's frozen RETAIN,
RETAIN_AS_EFFICIENT_OPTION, NOT_RETAINED, and EXPERIMENT_INVALID rules
without tuning or rerunning.

## 9. Prior-art position

The following matrix limits the claim before a dedicated exhaustive search.

| Work | Array/manifold | Beamspace | Fixed whitening | Direction estimate | Scale/search | Final full-manifold likelihood | Multiple starts |
|---|---|---|---|---|---|---|---|
| Vincent, Besson, Chaumette (2014) | Close-source array model | Not the present sequential beamspace contract | Not the present fixed exact whitener | Taylor approximate-ML parameterization | Low-dimensional/one-dimensional approximate conditional ML | Approximate close-source model | Not the present contract |
| Bonacci et al. (2017) | ULA extended to nonuniform linear arrays | No | Not the present fixed exact whitener | Taylor approximate CML geometry | Two-dimensional minimization reduced to one dimension | Approximate CML model | Not the present contract |
| Trinh-Hoang, Viberg, Pesavento, Partial Relaxation | General multi-source DOA/WSF/covariance fitting | Method-dependent | No system-specific fixed whitener | Structural partial relaxation/eigenvalue criterion | Spectrum or lower-dimensional search | Depends on member estimator | Generally spectral search rather than this start contract |
| Current K2-Tangent-Profile | Actual two-dimensional fixed sequential receive manifold | Yes | Yes, exact and frozen | K1 projected residual plus Fisher-metric generalized eigenvector | One positive separation scale | Yes, exact rank-two concentrated DML | No tangent starts; one direction and safe fixed-grid fallback |

References:

1. F. Vincent, O. Besson, and E. Chaumette, "Approximate maximum
   likelihood estimation of two closely spaced sources," *Signal
   Processing*, vol. 97, pp. 83-90, 2014.
   DOI: `10.1016/j.sigpro.2013.10.017`.
2. Bonacci et al., "Robust DoA estimation in case of multipath environment
   for a sense and avoid airborne radar," *IET Radar, Sonar & Navigation*,
   2017. DOI: `10.1049/iet-rsn.2016.0446`.
3. M. Trinh-Hoang, M. Viberg, and M. Pesavento, "Partial Relaxation
   Approach: An Eigenvalue-Based DOA Estimator Framework," arXiv:1711.01982.
4. J. Kim, H. J. Yang, and N. Kwak, "Low-angle tracking of two objects in a
   three-dimensional beamspace domain," *IET Radar, Sonar & Navigation*,
   2012. DOI: `10.1049/iet-rsn.2010.0163`.

The allowed novelty statement is limited to this combination: on the actual
two-dimensional, exactly whitened, fixed sequential beamspace manifold, use
a K1 projected residual and Fisher-metric generalized eigenvector to choose
a direction, then run a one-dimensional exact full-manifold K2 profile
likelihood with fixed-grid safe fallback. This document does not claim the
first Taylor close-source ML method, first one-dimensional K2 reduction,
first derivative manifold, first generalized-eigenvalue DOA method, or first
close-source ML estimator. If a dedicated search finds the identical
combination, the work is a `SYSTEM-SPECIFIC IMPLEMENTATION / ENGINEERING
SPECIALIZATION` rather than a new algorithm.

## 10. Stop rule

After the one registered run, the branch records the result and stops. A
positive result remains an optional candidate and does not modify or merge
Core-Lite, Core-Plus, `experiment/stage8-core-v2`, or `main`. A negative
result is retained as evidence and does not create V2.
