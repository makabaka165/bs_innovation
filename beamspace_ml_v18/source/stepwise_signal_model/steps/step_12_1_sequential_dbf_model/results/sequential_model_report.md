---
phase_factor: 1
validation_status: PASS
element_order: elevation_fastest_azimuth_slowest
---

# Step12.1 Strict Sequential DBF Validation

## Scope

This report validates only array ordering, elevation-then-azimuth DBF, equivalent Kronecker weights, the factor-1 full receive manifold, and white-noise covariance. No DML, grouping, FIM, bootstrap, or model-order implementation is present.

The active snapshot generator calls `build_receive_cyl_steering_vec` and does not call legacy echo generators.

## Configuration

- Array: 192 x 32 full, 65 x 32 work subarray.
- Elevation beams: `6 10 14` deg.
- Azimuth beams: `6 8 10` deg.
- Elevation conditions: `6 10 14` deg.
- Sequential output order: elevation channel fastest, azimuth beam next.

## Array-order validation

| case | roundtrip error | permutation error | coordinate error | pass |
| --- | --- | --- | --- | --- |
| random_complex_vector | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 | 1 |
| random_complex_range_snapshot_cube | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 | 1 |

## Staged versus equivalent beam matrix

| scenario | staged/direct error | physical manifold error | pass |
| --- | --- | --- | --- |
| random_complex_element_data | 1.704822e-15 | NaN | 1 |
| factor1_single_target_snapshot | 1.839589e-15 | 2.503300e-15 | 1 |
| factor1_two_target_snapshot | 1.609096e-15 | 1.633014e-15 | 1 |

Maximum full/factorized manifold error over 9 angles: 9.353313e-15.

## Conditional azimuth dependence

| el condition (deg) | formula error | change from el=0 | independent-model error | pass |
| --- | --- | --- | --- | --- |
| 0 | 0.000000e+00 | 0.000000e+00 | 0.000000e+00 | 1 |
| 30 | 6.706673e-15 | 1.498552e+00 | 1.498552e+00 | 1 |
| 60 | 0.000000e+00 | 1.550375e+00 | 1.550375e+00 | 1 |

## Active snapshot model and legacy dependency

- Factor-1 orthogonal residual: 2.667851e-14.
- Isolated legacy factor-2 orthogonal residual: 9.999939e-01.
- Active-source dependency rules passed: 6/6.

## White-noise covariance

| samples | relative covariance error | trace ratio | threshold | pass |
| --- | --- | --- | --- | --- |
| 1000 | 8.569502e-02 | 1.016971942 | 0.12 | 1 |
| 5000 | 3.867620e-02 | 1.008387806 | 0.07 | 1 |
| 20000 | 2.194684e-02 | 0.998700513 | 0.04 | 1 |

- Maximum sequential/direct white-noise error: 1.604590e-15.
- Covariance convergence flag: 1.

## Result

**PASS.** Runtime 1.793880 s. This deterministic/Monte Carlo engineering validation reports no confidence interval.
