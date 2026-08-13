# Stage8 K2 SNR Domain Theory and Validation Protocol

Protocol: `STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V1`

Authorization:
`AUTHORIZE_STAGE8_K2_SNR_DOMAIN_AUDIT_AND_DIRECT_TANGENT_BRANCH_EXECUTION_V1`

Execution branch: `experiment/stage8-k2-tangent`

Starting commit: `dcde540e3f3af793c0b8beb18e41a798af64739a`

## 1. Purpose and frozen boundary

This validation separates three receive-estimator SNR domains that were
previously represented by one numeric trial label:

1. element-input expected total-energy SNR;
2. raw sequential-beamspace expected total-energy SNR;
3. whitened sequential-beamspace expected total-energy SNR.

It also adds a truth-only K2 projected-residual diagnostic. Phase A audits the
existing 72 element-SNR-controlled trials without rerunning any fit. Phase B
creates 72 paired trials controlled at whitened-beamspace expected SNR
`{-6,0,+6} dB` and evaluates only Core-Lite, Core-Plus, and the frozen safe
Tangent method. Phase C compares the two SNR parameterizations without treating
equal numeric labels as equal physical input conditions.

The Tangent implementation, its profile likelihood and fallback rule, the
measurement model, whitening, local manifold, P1-P4, source/noise seeds, and
evidence `31_*` through `40_*` remain byte-identical to the starting commit.
No production interface or retention decision changes.

## 2. Element-domain SNR

For one trial,

```math
Y_e=X_e+N_e,\qquad X_e=A(\Theta)S,
```

with per-snapshot element-noise covariance `R_e`. The registered generators use
`sigma2=1`, `diag(R_e)=1`, and therefore `tr(R_e)=N_e`. Define

```math
\mathrm{SNR}_{e,\mathrm{exp}}
=\frac{\|X_e\|_F^2}{L\,\mathrm{tr}(R_e)},\qquad
\mathrm{SNR}_{e,\mathrm{real}}
=\frac{\|X_e\|_F^2}{\|N_e\|_F^2}.
```

The original `31_*` labels scale the signal to

```math
\|X_e\|_F^2=10^{\gamma_e/10}N_eL.
```

Thus the historical `-6/0/+6 dB` labels are element-input expected SNR, not
beamspace SNR.

## 3. Raw and whitened sequential-beamspace SNR

For the frozen registered measurement,

```math
X_b=W_I^H X_e,\qquad C_b=W_I^H R_e W_I=C_I.
```

The raw sequential-beamspace definitions are

```math
\mathrm{SNR}_{b,\mathrm{raw,exp}}
=\frac{\|X_b\|_F^2}{L\,\mathrm{tr}(C_b)},\qquad
\mathrm{SNR}_{b,\mathrm{raw,real}}
=\frac{\|X_b\|_F^2}{\|W_I^H N_e\|_F^2}.
```

After the frozen sequential whitener,

```math
X_w=T_I X_b,\qquad C_w=T_I C_b T_I^H\approx I_r,
```

where `r=model.whitening_rank`. Every energy calculation uses the actual
`tr(C_w)`, not a hard-coded rank. The whitened definitions are

```math
\mathrm{SNR}_{b,\mathrm{white,exp}}
=\frac{\|X_w\|_F^2}{L\,\mathrm{tr}(C_w)},\qquad
\mathrm{SNR}_{b,\mathrm{white,real}}
=\frac{\|X_w\|_F^2}{\|T_IW_I^H N_e\|_F^2}.
```

The receive-domain mappings

```math
G_{\mathrm{raw,dB}}=mathrm{SNR}_{b,\mathrm{raw,exp,dB}}
-\mathrm{SNR}_{e,\mathrm{exp,dB}},
```

and

```math
G_{\mathrm{white,dB}}=mathrm{SNR}_{b,\mathrm{white,exp,dB}}
-\mathrm{SNR}_{e,\mathrm{exp,dB}}
```

describe the fixed receive measurement only. They are not transmit gain,
propagation loss, radar-equation gain, or CPI integration gain.

For registered raw beam `j`, the expected channel SNR is

```math
\mathrm{SNR}_{b,j,\mathrm{exp}}
=\frac{\|w_j^H X_e\|_2^2}{L[C_b]_{jj}}.
```

The maximum and median across registered beams are descriptive measures of
coherent accumulation; neither controls a fit.

## 4. Truth-only K2 projected SNR

Total SNR does not describe whether two nearby targets are distinguishable.
For true center `c_true`, let `g_c` be the whitened sequential manifold and

```math
P_c^\perp=I-\frac{g_cg_c^H}{g_c^Hg_c}.
```

The K2-specific residual diagnostic is

```math
\mathrm{SNR}_{K2,\perp,\mathrm{exp}}
=\frac{\|P_c^\perp X_w\|_F^2}
{L\,\mathrm{tr}(P_c^\perp C_w P_c^\perp)},
```

with realized counterpart

```math
\mathrm{SNR}_{K2,\perp,\mathrm{real}}
=\frac{\|P_c^\perp X_w\|_F^2}
{\|P_c^\perp T_IW_I^H N_e\|_F^2}.
```

This metric uses truth after generation for analysis only. It is never passed
to an estimator, initializer, selection rule, threshold, or safe fallback.
The existing `Gamma_K2_proxy` remains the separate geometry/difference-mode
descriptor.

## 5. Paired white-SNR control

For unscaled source matrix `S_0`, define

```math
X_{w,0}=T_IW_I^H A(\Theta)S_0.
```

For target `gamma_w*=10^(snr_target_db/10)`, apply only the common signal scale

```math
\alpha=\sqrt{\frac{\gamma_w^*L\,\mathrm{tr}(C_w)}
{\|X_{w,0}\|_F^2}}.
```

Each Phase B trial retains its paired original profile, truth, noise model,
snapshot count, source seed, source phase, normalized source matrix, noise seed,
and exact noise realization. Only `alpha` changes. The scale must not depend on
realized noise energy. Consequently finite-sample noise variation remains in
the realized SNR, as required for later Monte Carlo work.

## 6. Integrity and execution contract

Phase B cannot start unless all 72 reconstructed original hashes exactly match
`31_stage8_k2_tangent_profile_trials.csv`. Fixed tests additionally require:

- element expected-SNR label error at most `1e-10 dB`;
- raw covariance relative residual at most `1e-12`;
- whitening residual at most `1e-10`;
- white-control target error at most `1e-10 dB`;
- identical paired seeds, phases, normalized sources, and noise matrices;
- no truth or audit value in a fitting entry point;
- 72 unique white-control hashes and 216 complete method rows.

Formal execution uses one MATLAB R2022b process with `-singleCompThread`. It
uses no pool, `parfor`, coordinator, scheduler, checkpoint, bootstrap, automatic
K, Full4D, MUSIC, Root-MUSIC, ESPRIT, or Vincent method.

## 7. Interpretation boundary

All registered complex beams in `W_I` are formed from the same `Y_element`.
This is a simultaneous multi-beam/full-stare receive interface, not a temporal
scan. Tangent is a post-detection, one-cell, known-K=2 local refinement backend.

The experiment does not model transmit broad-beam loss, RCS, range, the radar
equation, CFAR, range-Doppler detection, CPI pulse integration, unknown K, or
tracking. Element and whitened-beamspace SNR are internal receive-estimation
coordinates.

Whitening remains mandatory because it corrects nonorthogonal registered beams
and correlated element noise, converts generalized weighted CML to Euclidean
CML, and supplies the correct noise geometry for the Tangent projection and
Fisher metric. Its role is independent of whether a search proceeds first in
azimuth, elevation, or the Tangent separation coordinate.

This is a paired SNR-definition validation with one source/noise realization per
factor cell. It is not statistically sufficient Monte Carlo evidence and does
not support confidence intervals, stable tail percentiles, or outlier rates.
No 800/1200-trial Monte Carlo run is authorized by this protocol.
