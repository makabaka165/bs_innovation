# Step12.4 Fixed-Whitening Near-Pair Tangent Asymptotics

This step validates deterministic local geometry on the fixed, factor-1,
fully sequential receive manifold

\[
g(\phi,\theta)=T_{\rm seq}W_{\rm seq}^{H}a_{\rm receive}(\phi,\theta).
\]

`Wseq`, `Cseq=Wseq'*Rn_elem*Wseq`, `Tseq`, the whitening rank and all
measurement hashes remain fixed inside each registered configuration. The
candidate angle changes only the receive manifold. This step does not select
beams, estimate model order, run bootstrap, tune stage 5, or implement FIM
beam design.

## Status

- Stage result: `PASS`
- Theory status: `THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY`
- Statistical scope: `DETERMINISTIC_GEOMETRIC_VALIDATION`
- Primary physical exact-null status: `NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND`
- Synthetic null status: sixth-order relation supported with fitted order 6

The projected Jacobian metric is the classical deterministic effective-FIM
geometry after eliminating an unknown complex amplitude. It is not presented
as a new information matrix. The retained claim is limited to the explicit
use of one quadratic form for the second singular value, normalized
coherence deficit and normalized-Gram condition on the present fixed
sequential cylindrical receive manifold.

## Registered Plan

- Measurements: `SEQ_3X3_WHITE`, `SEQ_3X3_CORRELATED`, `SEQ_2X3_WHITE`,
  `SEQ_3X2_WHITE`, and a one-channel collapse diagnostic.
- Centers: the 3-by-3 product of azimuth `[7.6,8.0,8.4]` degrees and
  elevation `[9.8,10.0,10.2]` degrees.
- Fixed directions: azimuth, elevation, positive diagonal and negative
  diagonal in per-radian coordinates.
- Separations: `0.4 * 2.^(-(0:8))` degrees.
- Primary secant cases: 1,296; registered tail summaries: 144.

The locked plan and all controls are hashed before any result is evaluated.
The four primary configurations contain 9, 9, 6 and 6 sequential channels;
the diagnostic contains one. The canonical work array has 2,080 elements.

## Reproduction

From the repository root:

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/run_step12_4_tangent_asymptotics_validation.m')
```

The runner executes the 14 required tests, MATLAB Code Analyzer, public scope
scan, CSV schema scan, fixed-measurement hash scan, stage-5 result SHA-256
verification and the official 351-file Step11 frozen-result verification.

## Key Results

| Quantity | Maximum registered error |
|---|---:|
| First derivative | `5.8897e-09` |
| Second directional derivative | `3.2122e-05` |
| Third directional derivative | `6.5834e-04` |
| Second-singular-value tail ratio | `4.0102e-06` |
| Coherence-deficit tail ratio | `1.0421e-05` |
| Normalized-Gram tail ratio | `6.1180e-06` |
| Unsaturated exact identity | `1.3977e-12` |
| Geometry invariance | `9.4336e-13` |
| Synthetic sixth-order ratio | `2.2204e-16` |

All high-condition exact-identity rows remain in the CSV and are marked by
the registered `cond * eps` roundoff bound; they are not deleted. No physical
beam configuration was changed after observing tangent eigenvalues.

## Outputs

`results/` contains 15 CSV files, the prior-art mapping and the A-J validation
report. `figures/` contains the seven registered PNGs. No output in stage 4,
stage 5 or Step11 is modified by this runner.

The next unimplemented phase is Step12.5 exact-subset FIM beam design. It may
only start after separate user authorization.
