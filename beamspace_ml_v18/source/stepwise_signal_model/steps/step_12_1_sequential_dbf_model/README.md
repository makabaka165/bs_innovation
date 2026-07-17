# Step12.1 Strict Elevation-Then-Azimuth Sequential DBF

## Scope

This step establishes and validates the data path required by later local estimation stages. It implements only:

1. the audited legacy-vector to canonical-matrix permutation;
2. elevation DBF applied independently to every azimuth column;
3. conditional azimuth DBF applied to each elevation channel;
4. the equivalent Kronecker beam matrix;
5. the factor-1 full-geometry sequential beamspace manifold;
6. receive-only narrowband element snapshots for deterministic tests.

No whitening, DML score, elevation grouping, conditional multi-target search, joint refinement, FIM design, bootstrap, cache, or model-order logic is implemented.

## Audited legacy functions

- `core/beamforming/bf_elevation.m` applies a full 2080-element two-dimensional weight and immediately sums both physical dimensions. It does not retain azimuth columns.
- `core/beamforming/bf_azimuth.m` independently applies another full 2080-element two-dimensional weight. It does not consume an elevation-DBF tensor.
- `core/beamforming/bf_joint_2d.m` forms direct full-aperture two-dimensional beams using `beamWeights' * pcFlat`.

These functions remain available for legacy reproduction but are not called by Step12.1.

## Interface and element order

The legacy `arr_cyl` vectors are derived from `[N_az,N_el]` matrices with MATLAB column-major `XAct(:)` ordering, so azimuth varies fastest in the legacy vector. Step12 uses the canonical matrix

```text
Yelem: [N_el,N_az,N_range,N_snapshot]
```

and its canonical vector `Yelem(:)`, in which elevation varies fastest. The private layout module derives both permutations from `array_meta.XAct`; no dimension or ordering is inferred from convention alone.

For one observation cell, `Zseq` has shape `[B_el,B_az]`. The equivalent beam matrix columns are ordered with `b_el` fastest and `b_az` next, exactly matching `Zseq(:)`:

```text
w_(b_el,b_az) = u_(b_az|b_el) kron v_b_el
```

## Active input model

`generate_receive_only_element_snapshots.m` constructs

```text
Yelem = A_receive(Theta) * S + N
```

and every column of `A_receive` is built by calling the Step12.0 six-input `build_receive_cyl_steering_vec`. The active path does not call `echo_elem.m` or `echo_elem_cube.m`; those functions retain a legacy per-element round-trip delay/phase model and are not valid Step12 inputs.

## Run

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_1_sequential_dbf_model/run_step12_1_sequential_dbf_validation.m')
```

## Required results

- `results/sequential_equivalence_keypoints.csv`
- `results/array_order_validation.csv`
- `results/noise_covariance_validation.csv`
- `results/conditional_azimuth_validation.csv`
- `results/sequential_model_report.md`

All result tables use `phase_factor=1`. Stage 2 passes only when random complex data, factor-1 single-target snapshots, factor-1 two-target snapshots, full/factorized manifolds, conditional azimuth weights, and white-noise covariance all satisfy their registered gates.
