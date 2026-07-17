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
- Provenance patch status:
  `STAGE6_PROVENANCE_PATCH_IMPLEMENTED_EVIDENCE_RERUN_PENDING`
- Statistical scope: `DETERMINISTIC_GEOMETRIC_VALIDATION`
- Primary physical exact-null status: `NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND`
- Synthetic null status: sixth-order relation supported with fitted order 6

The projected Jacobian metric is the classical deterministic effective-FIM
geometry after eliminating an unknown complex amplitude. It is not presented
as a new information matrix. The retained claim is limited to the explicit
use of one quadratic form for the second singular value, normalized
coherence deficit and normalized-Gram condition on the present fixed
sequential cylindrical receive manifold.

The numerical result above is the retained evidence from commit `17c2022`.
That commit's locked plan incorrectly required `HEAD` to equal the stage-5
baseline and included runtime `HEAD` in stable plan hashes. Stage 6.1A fixes
the code contract but intentionally does not regenerate any CSV, report, or
PNG. The retained evidence must therefore be rerun from a clean checkout in
a separately authorized stage 6.1B before the provenance patch is called
evidence-validated.

## Reproduction Contract

- The stage-5 baseline remains
  `0430f25272690a3ddf378dcf0bab465ca93edb68` and must be an ancestor of
  runtime `HEAD`; equality is not required.
- Formal evidence execution starts only from an empty
  `git status --porcelain=v1 --untracked-files=all` result.
- `runtime_head_commit` is written only to runtime diagnostics and is
  excluded from stable controls, measurement, experiment, provenance, and
  deterministic-evidence identities.
- Executable stage-6 source and direct dependencies are identified from
  sorted Git mode/blob/path manifests, so checkout CRLF/LF conversion does
  not change their hashes.
- Controls, physical measurement plan, experiment plan, executable source,
  dependencies, and runtime diagnostics have separate identities.
- The stable provenance hash binds the baseline, source/dependency trees,
  stable plans, `phase_factor=1`, and the MATLAB R2022b release contract.

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

After the pending clean-checkout rerun, the runner will execute the original
14 registered checks plus six provenance contract test groups, MATLAB Code
Analyzer, public scope scan, explicit artifact/schema scans, fixed-measurement
hash scan, stage-5 result SHA-256 verification and the official 351-file
Step11 frozen-result verification.

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

The retained `17c2022` evidence in `results/` contains 15 CSV files, the
prior-art mapping and the A-J validation report; `figures/` contains seven
PNGs. Stage 6.1B will additionally generate source/dependency manifests, a
stable provenance contract and an isolated runtime diagnostics CSV through
an explicit artifact registry rather than a fixed CSV-count assertion. No
output in stage 4, stage 5 or Step11 may be modified by that runner.

The next unimplemented phase is Step12.5 exact-subset FIM beam design. It may
only start after separate user authorization.
