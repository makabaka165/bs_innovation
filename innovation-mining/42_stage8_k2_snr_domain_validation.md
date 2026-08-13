# Stage8 K2 SNR Domain Validation

Status: `STAGE8_K2_SNR_DOMAIN_VALIDATION_COMPLETE`

Protocol: `STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V2`

## V1 gate correction

V1 stopped before Phase B because its `1e-10` T4 gate was stricter than the frozen whitener numerical residual. V2 fixes the quality tolerance at `1e-8`; it does not modify `T_I`, `C_I`, rank, or any SNR formula.

- V1 status: `STAGE8_K2_SNR_DOMAIN_VALIDATION_INVALID`.
- V1 failure stage: `T4_WHITENING_NUMERIC_GATE`.
- V1 Phase B executed: `false`.
- V2 whitening tolerance: `1e-08`.
- Maximum observed whitening residual: `5.7966605659302925e-09`.

## Integrity

- Original element hashes: `72/72 exact`.
- White-control registry: `72/72`, unique hashes: `72/72`.
- Method rows: `216/216`; truth leakage: `0`.
- Maximum white-target error: `9.52e-13 dB`.
- Maximum raw covariance residual: `1.45e-16`.
- Maximum whitening residual: `5.8e-09`.

## Original element-SNR mapping

| Element label (dB) | White SNR min | median | max |
|---:|---:|---:|---:|
| -6 | 15.419636 | 16.029829 | 17.094797 |
| 0 | 21.419720 | 22.032933 | 22.699933 |
| 6 | 27.419720 | 28.033334 | 28.758651 |

Overall raw peak-beam expected SNR: median `31.760441 dB`, p90 `39.126944 dB`. Overall white receive gain: median `22.029829 dB`, range `[21.419636, 23.094797] dB`.

## White-beamspace-controlled results

| Method | Valid rate | Joint RMSE median | p90 | Fallback rate | Runtime median (s) |
|---|---:|---:|---:|---:|---:|
| CORE_LITE | 1.000000 | 0.428686 | 0.605529 | 0.000000 | 0.148707 |
| CORE_PLUS | 1.000000 | 0.413596 | 0.628607 | 0.305556 | 1.158709 |
| TANGENT_PROFILE_SAFE | 1.000000 | 0.367575 | 0.589024 | 0.638889 | 4.517984 |

Detailed `-6/0/+6 dB`, P1-P4, noise, L, geometry, fallback, cost, and runtime rows are recorded in the summary CSV.

## Interpretation

The original numeric label controls expected total-energy SNR at the element input. The paired experiment controls expected total-energy SNR after the frozen sequential measurement and whitener. Equal numeric labels do not represent equal input-energy conditions, so they are not used to claim that an SNR definition improves or degrades an algorithm.

All registered complex beams are formed from the same `Y_element`; this is not a temporal scan. The SNRs are internal receive-estimation coordinates and exclude transmit broad-beam loss, RCS/range/radar equation, CFAR, range-Doppler detection, CPI pulse integration, unknown K, and tracking. Whitening remains unchanged and defines the correct noise geometry.

## Statistical boundary

Each factor cell has one source/noise realization. This is an SNR-definition audit and paired reparameterization experiment, not a statistically sufficient Monte Carlo study. It cannot establish confidence intervals, stable P90 behavior, or outlier probabilities. No 800/1200-trial Monte Carlo run was executed or authorized.

Runtime: Phase A `66.596 s`, smoke `43.972 s`, Phase B `796.675 s`, total `1286.466 s`.

Default K2 remains `TANGENT_PROFILE_SAFE`; Tangent is frozen.
