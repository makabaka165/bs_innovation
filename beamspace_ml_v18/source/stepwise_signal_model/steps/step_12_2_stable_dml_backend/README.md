# Step12.2 Stable Whitening and DML Backend

## Scope

This step replaces the fixed-floor whitening and fixed-ridge/2-by-2 Gram
scoring patterns on the new Step12 route. It provides a numerical backend
only. It does not implement elevation grouping, conditional angle search,
joint refinement, FIM beam design, bootstrap, or model-order decisions.

The public module interfaces are:

- `stable_numeric_rank(singular_values, matrix_size, multiplier)`;
- `build_psd_whitener(C, opts)`;
- `beamspace_dml_score_svd(Z, G, opts)`;
- optional comparison `beamspace_dml_score_qr(Z, G, opts)`;
- `concentrated_dml_rss(Z, G, opts)`.

## Effective whitening coordinates

For a positive-semidefinite covariance

```text
C = U_r Lambda_r U_r^H,
```

the whitener is

```text
T = Lambda_r^(-1/2) U_r^H,
```

with shape `[rank(C),B]`. Therefore `T*C*T'` is compared with
`I_rank(C)`. A singular `B`-by-`B` coordinate matrix is not returned or
described as an identity-covariance space.

## Stable score contract

The primary score uses economy SVD and the effective left singular basis:

```text
score = norm(U_r' * Z, 'fro')^2
rss   = norm(Z, 'fro')^2 - score
```

The default rank threshold is

```text
max(m,n) * eps(class(sigma1)) * sigma1.
```

If `rank(G) < requested_rank`, the column-space score and RSS are still
returned, but `debug.status` is `RANK_DEFICIENT`. A negative RSS is clipped
only inside a scale-relative machine-roundoff tolerance; a more negative
value raises an error.

For effectively whitened data with `rC=size(Z,1)` and `L=size(Z,2)`, the
concentrated complex-Gaussian variance estimate is the ML estimate

```text
sigma2_hat = rss / (rC * L).
```

No unbiased degrees-of-freedom correction is applied.

For `B >= K`, the primary per-candidate cost is the economy SVD
`O(B*K^2)` plus the projection `O(rank(G)*B*L)`; working storage is
`O(B*K + rank(G)*L)`. PSD whitening uses a `B`-by-`B` Hermitian
eigendecomposition, with `O(B^3)` work and `O(B^2)` storage. These are
algorithmic counts; the validation does not claim a measured peak-memory
value.

## Legacy audit boundary

The frozen Step11 `apply_beamspace_whitening.m` clips eigenvalues at a fixed
absolute floor, and `beamspace_dml_score.m` forms a fixed-ridge normal
equation projector. Five frozen search functions also contain an explicit
2-by-2 Gram determinant score. They are comparison evidence only and are
not called by Step12.2. The new `common/` source contains no fixed `1e-10`,
normal-equation inverse, `pinv`, or 2-by-2 determinant path.

## Run

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_2_stable_dml_backend/run_step12_2_stable_dml_validation.m')
```

## Outputs

- `results/stable_dml_trial.csv`
- `results/stable_dml_keypoints.csv`
- `results/rank_deficiency_cases.csv`
- `results/old_vs_new_score_comparison.csv`
- `results/stable_dml_report.md`

All result rows carry `phase_factor=1`. Passing this engineering backend does
not establish grouped-DML identifiability or multi-target estimation
performance.
