# Stage8 K2 Tangent White-SNR Monte Carlo and Route Closure

Status: `STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_COMPLETE`

Terminal result: `STAGE8_K2_TANGENT_WHITE_SNR_WORKING_REGION_IDENTIFIED`

Final working-region state: `IDENTIFIED`

## Integrity

- Registry/checkpoints/SNR rows: `1680/1680`.
- Method rows: `5040/5040`; truth leakage: `0`.
- Seven white-SNR points and 240 base realizations.
- Ten replicates per exact factor cell.
- Resume count: `2`.
- Total active trial runtime: `20439.655 s`; median trial: `11.953 s`.
- Trial-session shutdown: `POST_COMPUTATION_SHUTDOWN_ANOMALY` after the
  ready-to-finalize marker; fresh-session finalization exited with code `0`.

## Overall white-SNR results

| SNR | Method | Valid | Median RMSE | P90 | Fallback |
|---:|---|---:|---:|---:|---:|
| -6 | CORE_LITE | 1.000000 | 0.455992 | 0.628987 | 0.000000 |
| -6 | CORE_PLUS | 1.000000 | 0.457681 | 0.649480 | 0.387500 |
| -6 | TANGENT_PROFILE_SAFE | 1.000000 | 0.438478 | 0.626654 | 0.879167 |
| 0 | CORE_LITE | 1.000000 | 0.413068 | 0.620534 | 0.000000 |
| 0 | CORE_PLUS | 1.000000 | 0.387429 | 0.643298 | 0.391667 |
| 0 | TANGENT_PROFILE_SAFE | 1.000000 | 0.321091 | 0.609659 | 0.683333 |
| 6 | CORE_LITE | 1.000000 | 0.351096 | 0.556776 | 0.000000 |
| 6 | CORE_PLUS | 1.000000 | 0.356647 | 0.574680 | 0.379167 |
| 6 | TANGENT_PROFILE_SAFE | 1.000000 | 0.242737 | 0.552834 | 0.591667 |
| 10 | CORE_LITE | 1.000000 | 0.300000 | 0.511585 | 0.000000 |
| 10 | CORE_PLUS | 1.000000 | 0.273089 | 0.514124 | 0.429167 |
| 10 | TANGENT_PROFILE_SAFE | 1.000000 | 0.183822 | 0.500000 | 0.470833 |
| 14 | CORE_LITE | 1.000000 | 0.242612 | 0.452308 | 0.000000 |
| 14 | CORE_PLUS | 1.000000 | 0.227689 | 0.481722 | 0.450000 |
| 14 | TANGENT_PROFILE_SAFE | 1.000000 | 0.116329 | 0.382897 | 0.287500 |
| 18 | CORE_LITE | 1.000000 | 0.223607 | 0.387605 | 0.000000 |
| 18 | CORE_PLUS | 1.000000 | 0.211648 | 0.394784 | 0.475000 |
| 18 | TANGENT_PROFILE_SAFE | 1.000000 | 0.092104 | 0.293417 | 0.225000 |
| 22 | CORE_LITE | 1.000000 | 0.183812 | 0.301040 | 0.000000 |
| 22 | CORE_PLUS | 1.000000 | 0.154802 | 0.304127 | 0.416667 |
| 22 | TANGENT_PROFILE_SAFE | 1.000000 | 0.079622 | 0.223607 | 0.158333 |

## Working-region classification

| Scope | First stable SNR | Empirical region state |
|---|---:|---|
| ALL | 10 | MONOTONIC_FROM_FIRST_OBSERVED_POINT |
| P1 | 14 | NON_MONOTONIC_EMPIRICAL_REGION |
| P2 | 22 | MONOTONIC_FROM_FIRST_OBSERVED_POINT |
| P3 | 10 | MONOTONIC_FROM_FIRST_OBSERVED_POINT |
| P4 | 14 | MONOTONIC_FROM_FIRST_OBSERVED_POINT |

This classification is descriptive and does not create an online threshold.

## Stage8 K2 SNR-domain reference

The 42 single-realization rows are reference samples only. `0.759` fall within the corresponding ten-replicate MC min/max and `0.639` fall within the MC P10-P90 interval. Neither rate is a pass/fail gate.

## Route closure

```text
DEFAULT_K2 = TANGENT_PROFILE_SAFE
Tangent algorithm modified = false
Production interface modified = false
New online SNR threshold = false
Automatic selector = false
Further Stage8-K2 algorithm development = NOT_AUTHORIZED
Next = THESIS_DOCUMENTATION_ONLY
```
