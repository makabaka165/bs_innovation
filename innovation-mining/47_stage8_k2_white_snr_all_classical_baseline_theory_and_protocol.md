# Stage8 K2 Unified White-SNR All-Classical Baseline Theory and Protocol

Status: `AUTHORIZED_ON_ISOLATED_WORK_BRANCH`

Protocol:
`STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_V2`

Authorization:
`AUTHORIZE_STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_WORK_BRANCH_V2`

Branch:
`work/stage8-k2-white-snr-all-classical-baselines-v1`

Source branch and commit:
`work/stage8-k2-white-snr-classical-baselines-v1@224eedb8282b64fec210e77081bc4fc7748c1fc1`

## 1. Purpose and boundary

This isolated comparison completes the registered all-classical reference set
on the frozen 1680 white-SNR trials. It runs only these methods:

1. `ELEMENT_MUSIC_K2`;
2. `ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML`;
3. `ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML`; and
4. `ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML`.

The existing six methods are read only and must never be refit:

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
FULL4D_ELEMENT_CML_MULTISTART
```

No Tangent, Core, Full4D, beamspace MUSIC, measurement, whitener, physical
manifold, noise model, white-SNR scale, registry seed, trial hash, production
interface, or frozen evidence path is authorized to change. Merge, rebase,
cherry-pick, fast-forward integration, and pushes to every branch other than
this work branch are prohibited.

## 2. Frozen evidence and common trials

Evidence 44 and 46 are immutable inputs. Before execution, the implementation
must validate their manifest statuses, artifact hashes, registry identities,
row counts, zero leakage assertions, and the evidence-46 independent audit.

Every new method reconstructs the same element-domain realization from the
evidence-44 registry. The `trial_id`, measurement identity,
`element_trial_hash`, source and noise seeds, and expected white-SNR target
must match the registered inputs exactly. The target error may not exceed
`1e-10 dB`.

The controlled coordinate remains expected total-energy SNR after the
registered sequential measurement and whitening. Element-domain methods do
not receive it as a fit input; it is joined into their rows only as the common
experimental coordinate. The seven targets are `-6, 0, +6, +10, +14, +18,
+22 dB` across both noise models, `L = 1, 4, 8`, profiles `P1` through `P4`,
and ten replicates, giving 1680 trials.

## 3. Element-domain MUSIC

For element observation `Y_e`, the method uses the exact element covariance
whitener:

\[
Y_{e,w}=R_e^{-1/2}Y_e,\qquad A_w(\phi,\theta)=R_e^{-1/2}a(\phi,\theta).
\]

With known `K=2`, it forms the sample covariance and the noise projector from
the two leading signal eigenvectors. The two-dimensional MUSIC spectrum is

\[
P_{\rm MUSIC}(\phi,\theta)=
\frac{1}{a_w^H(\phi,\theta)P_n a_w(\phi,\theta)}.
\]

It reuses the frozen Element-mode MUSIC and peak-picker interfaces with a
`0.005 deg` two-dimensional grid and chunk size `2048`. `L=1` is structural
N/A; `L=4,8` are applicable, so exactly `1120` rows are applicable. A valid
K2 result requires two independent local peaks; no truth-based separation,
SNR-based threshold, or forced top-two selection is allowed.

## 4. Vertical structured references

The cylindrical array is used through its exact vertical shift-invariant
substructure, not as an entire-array ULA. The vertical covariance and FBSS
construction reuse the frozen subspace implementation with:

```text
N_el = 32, N_az = 65, K = 2, smoothing length = 31, subarray count = 2.
```

GFBSS-MUSIC searches elevation on the fixed `9.8:0.001:10.2 deg` grid and is
structurally applicable to `P1/P3/P4` for both noise models and all snapshot
counts: exactly `1260` rows. Root-MUSIC and LS-ESPRIT use the frozen root,
rank, and duplicate tolerances. They are structurally applicable only for
white noise and `P1/P3/P4`: exactly `630` rows each. `P2` is an
equal-elevation multiplicity N/A, and colored-noise Root-MUSIC/ESPRIT is a
registered structural N/A.

Each valid vertical two-elevation result is completed by frozen conditional
azimuth CML on the full whitened cylindrical manifold. The fixed azimuth grid,
four coarse starts, eight sweeps, nine scan nodes, `TolX=1e-4 deg`, and
`MaxFunEvals=80` are immutable. Tangent, Core, Full4D, profile, truth, and
other-method estimates are prohibited as starts.

## 5. Truth isolation and applicability

The fit boundary rejects truth, truth angles, profile identity, Tangent/Core/
Full4D outputs, RMSE, working-region labels, K2 projected SNR, white-SNR
thresholds, and other estimator outputs. Applicability may use only the
registered structural scenario flag; it records that fact separately from
fit inputs. Formal outputs must record zero truth leakage, zero profile
leakage into fit, and zero Tangent/Core/Full4D initializer use.

Structural N/A, algorithmic invalid output, and valid output remain distinct.
RMSE and paired comparisons use only `applicable && fit_valid` rows. N/A is
not a Tangent win and no method produces an online selector or SNR threshold.

## 6. Registered products and verification

The formal run writes one validated checkpoint per trial, each containing four
new method rows, four diagnostics, identity fields, and representative-spectrum
data or its reference. Atomic `.tmp -> validation -> rename` writes allow
resume only from valid checkpoints; an invalid final checkpoint hard-stops.

The final plot-ready table has exactly `16800` rows: 1680 trials by ten
methods. New-method and diagnostic tables each have exactly `6720` rows.
Representative spectra are preregistered on 56 `L=8`, replicate-one trials
and provide plot data without rerunning an estimator. The result manifest
must preserve all plot-data hashes, evidence identities, and an explicit
`existing_method_rerun_count = 0`.

Independent verification reconstructs all 1680 trial identities, validates
every checkpoint and output count, confirms representative-spectrum identity,
checks all artifact hashes, and confirms no method was rerun outside the four
authorized new methods.

## 7. Execution control and completion

Formal execution uses MATLAB R2022b with `-singleCompThread`, one background
MATLAB runner, and no pool, `parfor`, or worker fan-out. Windows Task Scheduler
owns a 15-minute bounded controller tick. The controller may launch at most
one correctly identified runner per tick, automatically progresses through
trial, fresh-session finalization, fresh-session independent audit, and Git
closeout, then unregisters itself on success.

Successful completion requires:

```text
1680 checkpoints
6720 new method rows
6720 diagnostics
16800 all-method rows
Element MUSIC applicable = 1120
GFBSS applicable = 1260
Root-MUSIC applicable = 630
LS-ESPRIT applicable = 630
truth leakage = 0
existing-method rerun count = 0
independent artifact audit = PASS
```

The terminal state is
`STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE`; performance
or valid-rate differences do not invalidate the experiment. On completion,
Tangent and production remain unmodified, merge-back remains unauthorized,
and the next action is `USER_REVIEW`.
