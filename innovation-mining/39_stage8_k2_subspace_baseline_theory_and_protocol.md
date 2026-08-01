# Stage8 K2 Structured Subspace Baseline Theory and Protocol

Protocol: `STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_V1`

Authorization:
`AUTHORIZE_STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_AND_FF_INTEGRATION_V1`

Work branch: `work/stage8-k2-subspace-baselines-v1`

Actual Tangent base: `1705b160c08313d2ade9fc701085e8ce4bed4f7c`

The protocol prompt named `8e591779095e94333ed804351be1d35340d974ea`
as its expected base. The user explicitly requested execution from the current
branch. The actual base is a direct docs-only descendant that records the
authorized deletion of legacy refs; it changes no scientific code or evidence.
The read-only research branch similarly advanced by one equivalent docs-only
commit to `a7139204d717923cb89d0d629b67f1b3ab7ae94d`. The immutable scientific
contents and `origin/main` remain unchanged.

## 1. Purpose and frozen boundary

This comparison adds three classical structured-subspace references for the
registered coherent K2 trials:

- `ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML`;
- `ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML`;
- `ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML`.

Each method estimates two elevations from the exact vertical ULA structure of
the active cylindrical subarray, then estimates two azimuths with a shared
full-element conditional-ML backend. They are classical references, not a
production algorithm and not a modification of Tangent.

The following remain frozen: `TANGENT_PROFILE_SAFE`, Step12.7, Core-Lite,
Core-Plus, the four existing Full4D CML/MUSIC references, profiles P1-P4,
source/noise seeds, tools under `stage8_k2_tangent_profile` and
`stage8_k2_classical_baselines`, and evidence `31_*` through `34_*`.

## 2. Trial identity and fairness

The exact 72 evidence-31 trials are reconstructed with the frozen generator:

- noise: `WHITE` and `STAGE5_TOEPLITZ_CORRELATED`;
- snapshots: `L in {1,4,8}`;
- SNR: `{-6,0,+6} dB`;
- profiles: P1-P4.

Every reconstructed `element_trial_hash` must equal its evidence-31 hash
before formal fitting starts. Any mismatch invalidates the experiment. The
new fits never receive truth angles, profile identity, Tangent estimates,
Full4D estimates, or Core estimates as initializers. Truth is used only after
estimation for target permutation and metrics. Existing reference rows are
read from evidence 31/34 and are not refit.

All methods share the same element observation, seeds, CPI/range-Doppler cell,
known K=2, local angular domain, array, and noise model. Tangent and beamspace
CML observe the registered 15-dimensional sequential beamspace. The new
methods require the more informative full active element domain because the
registered beamspace does not preserve vertical shift invariance. Reports
therefore label them `MORE_INFORMATIVE_ELEMENT_DOMAIN_CLASSICAL_REFERENCES`.

## 3. Cylindrical-array structure and applicability boundary

For active azimuth column q and vertical layer n, the steering entry is

```math
a_{n,q}(\phi,\theta)=\exp\{j k_0[R\cos\theta\cos(\phi-\varphi_q)
 + n d_z\sin\theta]\}.
```

With

```math
v_n(\theta)=e^{j n\mu_z(\theta)},\quad
\mu_z(\theta)=k_0d_z\sin\theta,
```

and

```math
b_q(\phi,\theta)=
e^{j k_0R\cos\theta\cos(\phi-\varphi_q)},
```

the canonical element vector satisfies exactly

```math
a(\phi,\theta)=b(\phi,\theta)\otimes v(\theta).
```

Thus only the vertical dimension has standard ULA/Vandermonde shift
invariance. The active 65-of-192 azimuth sector is neither a ULA nor a complete
UCA. Standard two-dimensional ESPRIT, two-dimensional Root-MUSIC, UCA-RB-MUSIC,
and UCA-ESPRIT are not applicable without changing the observation. A complete
UCA phase-mode construction would use a different aperture and is intentionally
not presented as a same-condition reference.

This boundary follows the UCA requirements in C. P. Mathews and M. D.
Zoltowski, "Eigenstructure Techniques for 2-D Angle Estimation with Uniform
Circular Arrays," IEEE TSP, 1994, DOI `10.1109/78.317861`.

## 4. Vertical covariance and FBSS

The registered element-noise covariance is

```math
R_{n,\mathrm{elem}}=R_{\mathrm{az}}\otimes R_{\mathrm{el}}.
```

For each snapshot, reshape the canonical element vector to
`X in C^(32 x 65)`. If `L_az L_az^H=R_az`, use
`W_az=L_az^(-1)` and the nonconjugate matrix transpose
`X_azw=X W_az^T`. Then

```math
\widehat R_v=\frac{1}{L N_{az}}\sum_l X_{l,azw}X_{l,azw}^H
\approx VCV^H+R_{el}.
```

For K=2, freeze the maximum-aperture smoothing choice `M_s=31`, giving
`P=2` overlapping subarrays. With selection matrices `J_0,J_1` and exchange
matrix `Pi`, compute

```math
R_F=\frac12\sum_{p=0}^1 J_p\widehat R_vJ_p^H,
\qquad
R_{FB}=\frac12(R_F+\Pi R_F^*\Pi).
```

This is the spatial-smoothing construction of T.-J. Shan, M. Wax, and T.
Kailath, IEEE TASSP, 1985, DOI `10.1109/TASSP.1985.1164649`, with the
forward/backward extension of S. U. Pillai and B. H. Kwon, IEEE TASSP, 1989,
DOI `10.1109/29.17496`. The smoothing length is deterministic and is not tuned
from results.

## 5. Registered elevation estimators

### 5.1 Generalized FBSS-MUSIC

For `R_n,s=J_0 R_el J_0^H=L_sL_s^H`, whiten with `C_s=L_s^(-1)` and eigendecompose
`C_s R_FB C_s^H`. The generalized MUSIC spectrum is

```math
P(\theta)=\|E_n^H C_s v_s(\theta)\|_2^{-2}.
```

Select the two strongest distinct one-dimensional local maxima on the frozen
`9.8:0.001:10.2 deg` grid. This method is applicable to P1/P3/P4 for both
noise models, all L, and all SNR: 54 trials. P2 is structurally N/A because
equal elevations yield only one distinct vertical spatial frequency.

This estimator uses the subspace principle of R. O. Schmidt, "Multiple Emitter
Location and Signal Parameter Estimation," IEEE TAP, 1986.

### 5.2 FBSS Root-MUSIC

For white noise, eigendecompose `R_FB` and form `Q_n=E_nE_n^H`. The Root-MUSIC
Laurent-polynomial coefficients are the sums of projector diagonals

```math
c_l=\sum_{m-n=l}[Q_n]_{mn}.
```

Choose two distinct inside-unit-circle roots nearest the unit circle that map
to the registered elevation domain, and verify the repository's
`exp(+j k z sin(theta))` sign convention with a synthetic fixture. This method
is applicable to the 27 white-noise P1/P3/P4 trials. Correlated-noise rows are
N/A because generalized whitening would destroy the standard Vandermonde
polynomial. P2 remains N/A.

The root construction follows A. J. Barabell, "Improving the Resolution
Performance of Eigenstructure-Based Direction-Finding Algorithms," ICASSP,
1983.

### 5.3 FBSS LS-ESPRIT

For white noise, let `U_s` contain the two principal eigenvectors of `R_FB`.
With `S_1=U_s(1:end-1,:)` and `S_2=U_s(2:end,:)`, compute

```math
\Psi=S_1^\dagger S_2,
\qquad
\widehat\theta_k=\arcsin(\arg\lambda_k/(k_0d_z)).
```

Rank deficiency, nonfinite eigenvalues, repeated elevation estimates, or an
estimate outside the registered local domain is invalid. Applicability is the
same 27 white-noise P1/P3/P4 trials as Root-MUSIC. TLS, unitary ESPRIT, and
additional variants are excluded.

This estimator follows R. Roy and T. Kailath, "ESPRIT--Estimation of Signal
Parameters Via Rotational Invariance Techniques," IEEE TASSP, 1989,
DOI `10.1109/29.32276`.

## 6. Shared conditional-azimuth CML backend

For each valid elevation pair, exactly whiten `Y_element` with the registered
element covariance. For each ordered azimuth pair on
`7.4:0.02:8.6 deg`, build the complete whitened element manifold and score

```math
RSS(\phi_1,\phi_2\mid\widehat\theta_1,\widehat\theta_2)
=\|\Pi_{A_w}^\perp Y_w\|_F^2.
```

Equal azimuths are allowed for P3. Rank all 3721 ordered pairs by exact
concentrated likelihood, retain four deterministic starts, and use at most
eight coordinate sweeps. Each coordinate update uses nine scan nodes and
`fminbnd` with `TolX=1e-4 deg`, `MaxFunEvals=80`. The best finite valid start
is returned. The backend follows the conditional-ML formulation of P. Stoica
and K. C. Sharman, IEEE TASSP, 1990, DOI `10.1109/29.57542`.

## 7. Rows, diagnostics, and metrics

Each new method retains one row for every one of the 72 trials. Structural N/A
rows have `applicable=false`, `fit_valid=false`, and an explicit status. Every
applicable row has an explicit valid or invalid outcome.

After fitting, choose the best target permutation and report joint endpoint,
azimuth, and elevation RMSE; center, unoriented-axis, separation-magnitude,
and separation-vector errors; runtime; score, eig, and SVD counts. Summaries
also report elevation-selection success and conditional-CML success.

Pairwise wins/ties/losses are computed only on the common applicable-and-valid
subset, with a display tie tolerance of `1e-6 deg`. No resolved threshold,
bootstrap, or performance retention gate is introduced.

## 8. Verification and completion contract

Ten fixed tests cover exact cylindrical Kronecker factorization, vertical shift
invariance, Kronecker-noise azimuth whitening, coherent-rank restoration,
white/colored GFBSS-MUSIC, Root-MUSIC sign/root selection, ESPRIT phase,
conditional azimuth CML, applicability, and 72/72 reconstruction hashes.

After tests, four smoke trials check finite outputs, applicability, truth
isolation, and CML execution. A single uninterrupted formal run then evaluates
all 72 trials under MATLAB R2022b `-singleCompThread` with no parallel pool,
coordinator, checkpoint, scheduler, or bootstrap.

Completion requires 72/72 hashes, exact applicability, no truth leakage,
explicit outcomes for every applicable row, complete evidence tables, and no
change to frozen code/evidence. Performance is descriptive. The only terminal
states are `STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_COMPLETE` and
`STAGE8_K2_SUBSPACE_BASELINE_EXPERIMENT_INVALID`.
