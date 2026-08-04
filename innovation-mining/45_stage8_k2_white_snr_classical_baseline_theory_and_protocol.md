# Stage8 K2 White-SNR Classical Baseline Theory and Protocol

Status: `AUTHORIZED_ON_ISOLATED_WORK_BRANCH`

Protocol:
`STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_FINAL_COMPARISON_V1`

Authorization:
`AUTHORIZE_STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_WORK_BRANCH_V1`

Branch:
`work/stage8-k2-white-snr-classical-baselines-v1`

Source Tangent commit:
`d2d59fe550d8999dc8589aa76e52e89736539b66`

## 1. Purpose and boundary

This isolated experiment adds the final classical references on the exact
white-SNR Monte Carlo trials frozen in evidence 44. It evaluates:

1. finite-budget Full4D conditional maximum likelihood in the same whitened
   sequential beamspace as Tangent;
2. standard known-`K=2` MUSIC in that same beamspace where sample rank permits;
3. a preregistered, more-informative element-domain Full4D CML reference; and
4. paired comparisons with the existing Core and Tangent rows from evidence
   44.

The experiment does not alter or refit Tangent, Core-Lite, Core-Plus, the
measurement matrices, the whitener, the physical manifold, the noise models,
the white-SNR formula, the evidence-44 registry, or any production interface.
It introduces no new estimator, automatic model order, bootstrap, online SNR
threshold, or algorithm-selection rule.

All code, checkpoints, and results remain on the isolated work branch. Merge,
rebase, cherry-pick, or fast-forward integration into the long-term Tangent
branch is not authorized by this protocol.

## 2. Frozen trial identity and common observations

The experiment reads the following evidence as immutable input:

- `44_stage8_k2_white_snr_monte_carlo_registry.csv`;
- `44_stage8_k2_white_snr_monte_carlo_snr_trials.csv`;
- `44_stage8_k2_white_snr_monte_carlo_method_results.csv`; and
- `44_stage8_k2_white_snr_monte_carlo_runtime_manifest.json`.

Before any baseline is run, the implementation verifies the manifest status,
all 15 artifact SHA-256 values, `1680` registry rows, `1680` SNR rows, `5040`
existing method rows, `1680` unique scientific trial hashes, `240` base
realizations, and zero truth leakage.

Each evidence-44 row is reconstructed with the frozen white-SNR generator.
The reconstructed `trial_id`, measurement identity, and `element_trial_hash`
must match exactly, and expected white-SNR target error must not exceed
`1e-10 dB`. A failed identity check invalidates the experiment before baseline
execution.

Within a trial, every method uses the same `Y_element`, source seed, noise
seed, white-SNR target, truth, snapshot count, noise model, known `K=2`, local
angle domain, and single range-Doppler cell. Truth and profile labels are
evaluation-only and are never accepted by a baseline fit entry point.

## 3. Same-domain Full4D beamspace CML

For the registered element observation

\[
Y_e=X_e+N_e,
\]

the exact whitened sequential-beamspace observation is

\[
Z_w=T_IW_I^H Y_e.
\]

For two two-dimensional endpoints

\[
\Theta=\{\xi_1,\xi_2\}, \qquad \xi_k=[\phi_k,\theta_k]^T,
\]

the complete candidate manifold is

\[
G(\Theta)=T_IW_I^H[a(\xi_1),a(\xi_2)].
\]

Concentrating out deterministic source coefficients gives

\[
RSS(\Theta)=\|(I-P_G)Z_w\|_F^2,
\qquad
P_G=G(G^HG)^{-1}G^H.
\]

The implementation reuses `build_full_sequential_local_manifold`,
`concentrated_dml_rss`, and the frozen
`stage8_k2_cb_full4d_cml` center-difference search. It runs all `1680` trials
under method ID `FULL4D_BEAMSPACE_CML_MULTISTART`.

The deterministic numerical budget is frozen at:

- six top coarse starts;
- twelve coordinate sweeps;
- nine scan nodes per coordinate;
- `fminbnd TolX = 1e-4 deg` and `MaxFunEvals = 80`;
- minimum endpoint separation `1e-3 deg`;
- relative score tolerance `1e-8`;
- endpoint update tolerance `1e-3 deg`; and
- rank multiplier one.

Starts are derived only from the fixed local grid. The budget is never changed
by SNR, convergence outcome, or observed accuracy. Truth, Tangent, and Core
estimates are prohibited as starts. The returned estimate is a deterministic
finite-budget numerical CML result, not a proof of global ML optimality.

## 4. Numerical-completeness audit

The Full4D feasible set contains both the fixed-grid candidates and the final
Tangent endpoint candidate. Let `ell_F` be the Full4D concentrated log
likelihood and `ell_T` the likelihood evaluated at the frozen Tangent output.
The tolerance is

\[
\tau_\ell=64\epsilon\max(1,|\ell_T|).
\]

When

\[
\ell_F < \ell_T-\tau_\ell,
\]

the Full4D row is retained but marked
`NUMERICAL_OPTIMIZATION_INCOMPLETE`. No extra start, sweep, or trial-specific
repair is permitted. Results are reported both for all finite Full4D rows and
for the complete-likelihood subset satisfying `ell_F >= ell_T - tau_ell`.
This separates finite-sample regularization effects from incomplete numerical
optimization.

## 5. Same-domain standard MUSIC

For each applicable trial,

\[
\widehat R_z=Z_wZ_w^H/L.
\]

Known `K=2` selects the two leading eigenvectors `E_s`; the noise projector is

\[
P_n=I-E_sE_s^H.
\]

For candidate `g(phi,theta)=T_IW_I^Ha(phi,theta)`, the spectrum is

\[
P_{\rm MUSIC}(\phi,\theta)=
\frac{1}{g^H(\phi,\theta)P_ng(\phi,\theta)}.
\]

The method ID is `BEAMSPACE_MUSIC_K2`. It reuses the frozen two-dimensional
dictionary, `stage8_k2_cb_music`, and `stage8_k2_cb_peak_picker` with grid step
`0.005 deg`, chunk size `2048`, and known `K=2`.

`L=1` is registered as
`NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK` without eigendecomposition
or peak search. `L in {4,8}` supplies exactly `1120` applicable rows. A valid
K2 output requires two independent 8-neighbor local maxima. Rank-deficient,
single-peak, and not-applicable rows remain in the result table but do not
enter RMSE pairing and are not counted as Tangent wins. Peak selection uses no
truth separation, prominence threshold, or SNR-dependent tuning.

## 6. More-informative element-domain reference

The element-domain observation and manifold are whitened with the exact
element noise covariance:

\[
Y_{e,w}=R_e^{-1/2}Y_e,
\qquad
A_w(\Theta)=R_e^{-1/2}[a(\xi_1),a(\xi_2)].
\]

The objective is

\[
RSS_e(\Theta)=\|\Pi_{A_w(\Theta)}^\perp Y_{e,w}\|_F^2.
\]

The implementation reuses `stage8_k2_cb_whiten_element_data` and the same
frozen Full4D budget under method ID
`FULL4D_ELEMENT_CML_MULTISTART`. It runs only the mechanically selected
`160`-trial subset:

- white SNR `+10, +14, +18, +22 dB`;
- `L=4`;
- profiles `P1` through `P4`;
- both registered noise profiles; and
- replicates one through five.

All other element rows are explicit
`NOT_IN_REGISTERED_ELEMENT_REFERENCE_SUBSET` placeholders. Because Element CML
uses `2080` active elements while Tangent and the beamspace baselines use a
15-dimensional interface, it is marked
`MORE_INFORMATIVE_ELEMENT_DOMAIN_REFERENCE` and
`NOT_SAME_HARDWARE_INTERFACE`. Element and beamspace likelihood magnitudes are
never compared directly.

## 7. Registered output and recovery

Every trial produces three fixed-schema baseline rows, including explicit
not-applicable element placeholders, for `5040` new rows total. Each row
records identity, applicability, fit and optimizer status, endpoints, RSS and
concentrated likelihood where defined, effective/sample rank, endpoint and
geometry errors, numerical call counts, runtime, peak count, and all truth or
initializer isolation flags.

Formal execution uses MATLAB R2022b, `-singleCompThread`, one MATLAB process,
and no pool, `parfor`, coordinator, scheduler, or worker fan-out. Runtime is
isolated at
`E:\bs_innovation_runtime\stage8_k2_white_snr_classical_baselines_v1`.

Each trial is atomically committed to one validated checkpoint. Resume
validates protocol, code identity, registry hash, trial hash, schema, and
scientific hash before skipping a checkpoint. Temporary files are rerun;
invalid final checkpoints cause a hard stop and are never silently replaced.

After all `1680` checkpoints, a fresh MATLAB session performs only merge,
summary, plotting, and manifest generation. A third fresh session performs an
independent read-only reconstruction and artifact audit without rerunning a
baseline.

## 8. Summaries and paired comparisons

Full4D beamspace CML is summarized by white SNR overall, SNR by profile, SNR
by noise, SNR by `L`, and exact cell. Reports include valid and optimizer
status counts, numerical-incomplete count, median and P90 geometry errors,
score/SVD calls, and runtime.

Tangent versus Full4D and Tangent versus valid two-peak MUSIC comparisons are
strictly paired by trial. Wins, ties, and losses use a `1e-6 deg` joint-RMSE
tie tolerance. Exact cells with `N=10` are descriptive. MUSIC not-applicable
or invalid outputs are excluded from pairing.

The element subset reports Tangent, beamspace Full4D CML, and element Full4D
CML by SNR, profile, and noise. Its role remains descriptive and creates no
production or algorithm gate.

## 9. Preregistered interpretation

The primary white-SNR interval is `+10, +14, +18, +22 dB`, inherited from
evidence 44. At each point, a Tangent advantage condition requires:

- Tangent median joint RMSE no greater than Full4D;
- Tangent P90 joint RMSE no greater than Full4D; and
- more Tangent wins than losses.

`STAGE8_K2_TANGENT_ADVANTAGE_OVER_NUMERICAL_BEAMSPACE_CML_SUPPORTED` requires
all four points to meet those conditions and the pooled complete-likelihood
subset to meet the same direction of median, P90, and paired-win conditions.
`PARTIAL` requires at least two complete points without meeting `SUPPORTED`.
`NOT_SUPPORTED` applies when fewer than two points qualify or the pooled
complete-likelihood subset favors Full4D.

These states describe only the frozen finite-budget numerical Beamspace CML.
They cannot be stated as a theoretical superiority over globally optimized
ML.

MUSIC is descriptive: a white-SNR point identifies a two-peak region only
when at least half of applicable trials produce valid two-peak outputs.
Element CML is always `ELEMENT_REFERENCE_DESCRIPTIVE`.

## 10. Completion boundary

Scientific completion requires all `1680` trial identities and checkpoints,
`5040` baseline rows, exactly `1120` applicable MUSIC rows, exactly `160`
applicable Element CML rows, zero truth leakage, unchanged frozen paths, and a
passing independent artifact audit.

Performance cannot invalidate the experiment. Invalidity is reserved for an
identity, target-SNR, budget, truth-isolation, checkpoint, row-count, frozen
path, or artifact-hash failure.

At completion:

```text
Tangent algorithm modified = false
Production modified = false
Long-term Tangent branch changed = false
Merge back = false
Next = USER_REVIEW
```
