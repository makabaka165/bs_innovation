# Step12.0 Receive Model Correction

## Scope

This step validates only the receive-array spatial phase model used by the new active route. The active manifold is

\[
\mathbf a(az,el)=\exp\left(j\frac{2\pi}{\lambda}\mathbf p^T\mathbf u(az,el)\right),
\]

with `phase_factor=1`. The monostatic round-trip range phase is common to the receive elements under the far-field narrowband model and is absorbed into the complex source envelope.

This step does **not** implement sequential DBF, grouped DML, conditional azimuth DML, joint correction, FIM beam selection, K1/K2 bootstrap, cache integration, or model-order selection.

## Active and legacy boundary

- `common/build_receive_cyl_steering_vec.m` is the only new steering-vector entry point. It has exactly six inputs and has no `PhaseFactor` option or factor=2 branch.
- `common/build_receive_cyl_steering_with_derivatives.m` returns derivatives with respect to azimuth and elevation in radians.
- A factor=2 manifold exists only as a local helper in the beamwidth comparison test. It is labeled `legacy_comparison`, is not on the active route, and is never passed into the new common functions.
- Saved Step11 results remain factor=2 legacy evidence and are not overwritten by this runner.

## Run

From MATLAB R2022b or later:

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_0_receive_model_correction/run_step12_0_receive_model_correction.m')
```

The runner uses the authoritative `core/config/sim_cfg.m` and `core/array/arr_cyl.m`, validates the six-input formula, checks analytic derivatives at nine azimuth/elevation centers, measures factor 1 and legacy factor 2 3 dB beamwidths, and writes the result package.

## Outputs

- `results/phase_model_keypoints.csv`
- `results/old_vs_new_beamwidth.csv`
- `results/derivative_validation.csv`
- `results/receive_model_validation.md`
- `results/single_target_receive_pattern.png`

Every new result table contains an active metadata column `phase_factor=1`. The beamwidth table uses a separate `comparison_model_phase_factor` column to label the isolated legacy comparison.
