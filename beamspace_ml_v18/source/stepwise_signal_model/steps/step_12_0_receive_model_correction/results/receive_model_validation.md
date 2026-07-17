---
phase_factor: 1
phase_model: receive_array_one_way_spatial_phase
derivative_angle_unit: radian
validation_status: PASS
---

# Step12.0 Receive-Model Validation

## Scope and boundary

The active manifold uses factor 1. The monostatic round-trip range phase is common to the receive elements in the far-field narrowband model and is absorbed into the complex source envelope. The factor-2 curve is an isolated legacy comparison only. No sequential DBF, DML, FIM design, bootstrap, cache, or model-order logic is implemented here.

## Configuration

- Carrier frequency: 10000000000 Hz
- Wavelength: 0.03 m
- Full array: 192 azimuth positions x 32 elevation elements
- Work array: 65 azimuth positions x 32 elevation elements = 2080 elements
- Steering center: az 8.000000 deg, el 10.000000 deg
- Active phase factor: 1

## Formula and derivative checks

- Elementwise formula cases: 9; maximum absolute error: 0.000000e+00; maximum relative error: 0.000000e+00.
- A seventh phase-factor input is rejected: 1.
- Derivative centers: 9; finite-difference step: 1.000000e-06 rad.
- Maximum azimuth derivative relative error: 1.019834e-09.
- Maximum elevation derivative relative error: 1.475924e-09.

| az (deg) | el (deg) | rel. error az/rad | rel. error el/rad | pass |
|---:|---:|---:|---:|---:|
| -40 | -5 | 9.741336e-10 | 1.452166e-09 | 1 |
| 8 | -5 | 6.189781e-10 | 1.475924e-09 | 1 |
| 55 | -5 | 1.019834e-09 | 1.449877e-09 | 1 |
| -40 | 20 | 8.554100e-10 | 1.058014e-09 | 1 |
| 8 | 20 | 5.679539e-10 | 7.603312e-10 | 1 |
| 55 | 20 | 9.140109e-10 | 9.986046e-10 | 1 |
| -40 | 50 | 4.431253e-10 | 6.011378e-10 | 1 |
| 8 | 50 | 3.175502e-10 | 4.681723e-10 | 1 |
| 55 | 50 | 4.462375e-10 | 5.907568e-10 | 1 |

## Single-target pattern and 3 dB width

![Single-target receive pattern](single_target_receive_pattern.png)

| role | comparison factor | cut | 3 dB width (deg) | peak offset (deg) | pass |
|---|---:|---|---:|---:|---:|
| active_receive | 1 | azimuth | 2.027503341 | 0.000000000 | 1 |
| active_receive | 1 | elevation | 2.837838530 | 0.000000000 | 1 |
| legacy_comparison | 2 | azimuth | 1.013713726 | 0.000000000 | 1 |
| legacy_comparison | 2 | elevation | 1.418814743 | 0.000000000 | 1 |

- Azimuth width ratio factor1/factor2: 2.000074863.
- Elevation width ratio factor1/factor2: 2.000147336.

- Pattern scan angle evaluations: 40004; chunk size: 256.

## Result

**PASS.** All active result metadata use `phase_factor=1`. This deterministic validation has no confidence interval.
