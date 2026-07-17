---
phase_factor: 1
validation_status: PASS
whitening_coordinate: effective_subspace_rows
---

# Step12.2 Stable Whitening and DML Validation

## Scope

This report validates numerical rank, effective-subspace PSD whitening, economy-SVD DML scoring, an optional QR comparison, and concentrated RSS. No grouping, angle search, FIM design, bootstrap, or model-order decision is implemented.

## Legacy audit

The frozen Step11 whitener uses a fixed absolute eigenvalue floor, the frozen DML score uses a fixed ridge normal equation, and five frozen search functions contain a 2-by-2 Gram determinant score. Step12.2 calls none of these paths.

## Rank and whitening

| case | expected rank | effective rank | T rows | whitening error | status | pass |
| --- | --- | --- | --- | --- | --- | --- |
| stable_rank_scale_1e-08 | 2 | 2 | 2 | NaN | RANK_DEFICIENT | 1 |
| stable_rank_scale_1 | 2 | 2 | 2 | NaN | RANK_DEFICIENT | 1 |
| stable_rank_scale_100000000 | 2 | 2 | 2 | NaN | RANK_DEFICIENT | 1 |
| nonorthogonal_W_covariance | 5 | 5 | 5 | 1.347844e-14 | OK | 1 |
| rank_deficient_Cb | 4 | 4 | 4 | 8.305855e-16 | RANK_DEFICIENT | 1 |
| general_psd_noise | 5 | 5 | 5 | 2.198413e-14 | OK | 1 |
| zero_psd_covariance | 0 | 0 | 0 | 0.000000e+00 | ZERO_RANK | 1 |
| dml_exact_duplicate | 1 | 1 | 1 | NaN | RANK_DEFICIENT | 1 |
| dml_B_less_K | 2 | 2 | 2 | NaN | RANK_DEFICIENT | 1 |

The rank-deficient covariance returns a 4-by-5 whitener; `T*C*T'` relative error is 8.305855e-16.

## Stable score matrix

| case | rank | status | SVD/pinv error | SVD/QR error | RSS | pass |
| --- | --- | --- | --- | --- | --- | --- |
| random_full_rank | 2 | OK | 2.374897e-16 | 1.187449e-16 | 2.413524e+01 | 1 |
| scale_1e-8 | 2 | OK | 2.374897e-16 | 1.187449e-16 | 2.413524e+01 | 1 |
| scale_1 | 2 | OK | 2.374897e-16 | 1.187449e-16 | 2.413524e+01 | 1 |
| scale_1e8 | 2 | OK | 0.000000e+00 | 4.749794e-16 | 2.413524e+01 | 1 |
| near_delta_1e-2 | 2 | OK | 1.680579e-15 | 7.202480e-16 | 3.169574e+01 | 1 |
| near_delta_1e-6 | 2 | OK | 2.176121e-11 | 1.400661e-10 | 3.169574e+01 | 1 |
| near_delta_1e-10 | 2 | OK | 1.431969e-06 | 0.000000e+00 | 3.169574e+01 | 1 |
| near_delta_1e-14 | 2 | OK | 1.362375e-02 | 3.512558e-03 | 3.172093e+01 | 1 |
| exact_duplicate | 1 | RANK_DEFICIENT | 5.806755e-16 | 5.806755e-16 | 3.603556e+01 | 1 |
| B_less_K | 2 | RANK_DEFICIENT | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 | 1 |

- Maximum well-conditioned SVD/pinv error: 1.680579e-15.
- Maximum well-conditioned SVD/QR error: 7.202480e-16.
- Scale score relative spread: 5.937243e-16.
- Non-finite stable results: 0; roundoff RSS clips: 0.

## Concentrated RSS

| case | rC | rank(Gw) | sigma2 ML error | status | pass |
| --- | --- | --- | --- | --- | --- |
| rank_deficient_whitening_full_G | 3 | 2 | 0.000000e+00 | OK | 1 |
| rank_deficient_whitening_duplicate_G | 3 | 1 | 0.000000e+00 | RANK_DEFICIENT | 1 |

The variance denominator is `rC*L` with rC=3 in the rank-deficient-whitening test; no unbiased correction is applied.

## Legacy score comparison

- Stable SVD scale spread: 7.351304e-16.
- Legacy ridge scale spread: 9.999989e-01.
- Legacy 2-by-2 fast-score scale spread: 9.999989e-01.
- Near-rank pinv/stable relative difference: 1.261504e-04.

All 6 comparison rows retained the stable score as finite.

## Source and complexity checks

- Common-source dependency rules passed: 6/6.
- Registered SVD/QR score calls: 18/10.
- Per-candidate SVD/projection complexity: `O(B*K^2 + rank(G)*B*L)`; whitening eigendecomposition: `O(B^3)`.
- Working-storage orders: `O(B*K + rank(G)*L)` for scoring and `O(B^2)` for whitening; peak process memory was not profiled.
- Multi-start, grouping, FIM, and bootstrap calls: 0.

## Result

**PASS.** Runtime 0.763460 s. This deterministic numerical validation reports no confidence interval.
