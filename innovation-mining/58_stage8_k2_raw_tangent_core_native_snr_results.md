# Raw Tangent Core Native-SNR Results

Status: COMPUTED. Final completion and independent audit status are recorded in the runtime manifest.

Source main: `644fc6e0041e400b6500579bba93d49f45e46990`. Experiment code: `1e14e44315031d6a3f76afa254c1be08918221a1`.

1680 scenarios; 240 base realizations; 20 replicates per exact cell; 3360 native-domain observations with common random numbers across SNR; 13440 method rows.

Noise variance in each domain is clean signal energy / (linear nominal SNR * sample count). Realized SNR fluctuates naturally. Noise is IID circular complex Gaussian only.

K1_WHITE_SINGLE_TARGET_DML_CENTER is the self-contained whitened-domain single-target center estimator. It does not reproduce the historical element-dependent grouped initialization. All profile scores use the full two-target manifold with requested rank 2. Invalid Core outputs remain invalid.

Within each native domain all methods share the same observation hash. Cross-domain curves are SCENARIO_MATCHED_NATIVE_DOMAIN_SNR_REFERENCE; there are no cross-domain trial wins/losses or same-observation claims.

Localization: d_max_bw <= 0.1. Resolution: d_max_bw <= min(0.1, 0.4*rho_true_bw). Denominators are applicable trials; structural N/A and algorithmic invalid are separate. Error quantiles use valid fits only. Exact-cell tails are descriptive at N=20.

| Nominal SNR dB | Valid rate | Localization | Resolution | Median RMSE deg | P90 RMSE deg |
|---:|---:|---:|---:|---:|---:|
| -6 | 0.370833 | 0.179167 | 0.000000 | 0.24547946 | 0.4373899 |
| 0 | 0.691667 | 0.437500 | 0.004167 | 0.19344502 | 0.36686489 |
| 6 | 0.866667 | 0.687500 | 0.029167 | 0.15421606 | 0.26349598 |
| 10 | 0.933333 | 0.829167 | 0.062500 | 0.12737841 | 0.22963188 |
| 14 | 0.975000 | 0.920833 | 0.116667 | 0.10732323 | 0.19338547 |
| 18 | 0.987500 | 0.950000 | 0.204167 | 0.094057016 | 0.16539814 |
| 22 | 0.991667 | 0.970833 | 0.275000 | 0.077636654 | 0.15086662 |

Descriptive region: `RAW_TANGENT_NO_HIGH_RELIABILITY_REGION_IDENTIFIED`; first SNR: NaN dB. This is not an online threshold.

Profile/L, axis/rho, failure composition, within-domain methods, SNR realizations and runtime are retained in the adjacent 58 CSV tables. All figures regenerate from plot_data.csv and rho_trace_representatives.mat without fitting.

Historical 43-48 Safe evidence remains byte-identical and is not merged into these results. Deleted 72-trial and cache routes remain at main@644fc6e and in the verified local bundle. Production integration is not authorized.

## Highest Registered SNR: 22 dB

Rates use applicable trials. RMSE uses valid fits, so methods with sparse valid output must not be compared by RMSE alone.

| Domain / method | Applicable | Valid | Localization | Resolution | Median RMSE deg | P90 RMSE deg |
|---|---:|---:|---:|---:|---:|---:|
| BEAMSPACE / BEAMSPACE_MUSIC_K2 | 160 | 1 | 0.006250 | 0.000000 | 0.18720713 | 0.18720713 |
| BEAMSPACE / FULL4D_BEAMSPACE_CML_MULTISTART | 240 | 240 | 0.737500 | 0.225000 | 0.13102523 | 0.31070923 |
| BEAMSPACE / TANGENT_PROFILE_CORE | 240 | 238 | 0.970833 | 0.275000 | 0.077636654 | 0.15086662 |
| ELEMENT / ELEMENT_MUSIC_K2 | 160 | 0 | 0.000000 | 0.000000 | NaN | NaN |
| ELEMENT / ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | 180 | 104 | 0.577778 | 0.350000 | 0.049325381 | 0.12545386 |
| ELEMENT / ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 180 | 110 | 0.611111 | 0.388889 | 0.043967618 | 0.10437154 |
| ELEMENT / ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML | 180 | 22 | 0.122222 | 0.116667 | 0.031746167 | 0.060748873 |
| ELEMENT / FULL4D_ELEMENT_CML_MULTISTART | 240 | 240 | 0.979167 | 0.658333 | 0.025105038 | 0.11140749 |

Core and Full4D Beamspace CML share Z; their 22 dB strict resolution rates are 27.5% and 22.5%. Full4D Element CML reaches 65.8333% under its own native-domain SNR. This cross-domain number is a scenario-matched reference, not a same-observation result.

## Core Profile and Snapshot Breakdown at 22 dB

| Profile | Valid | Localization | Resolution | Median RMSE deg | Median axis error deg | Median rho error deg |
|---|---:|---:|---:|---:|---:|---:|
| P1 | 0.966667 | 0.966667 | 0.683333 | 0.067996044 | 2.6124339 | 0.1052325 |
| P2 | 1.000000 | 0.916667 | 0.100000 | 0.11097643 | 7.4944741 | 0.199 |
| P3 | 1.000000 | 1.000000 | 0.316667 | 0.074676174 | 3.5519444 | 0.14863152 |
| P4 | 1.000000 | 1.000000 | 0.000000 | 0.090205916 | 14.098409 | 0.099 |

| L | Valid | Localization | Resolution | Median RMSE deg |
|---:|---:|---:|---:|---:|
| 1 | 0.975000 | 0.912500 | 0.125000 | 0.1044015 |
| 4 | 1.000000 | 1.000000 | 0.325000 | 0.074512398 |
| 8 | 1.000000 | 1.000000 | 0.375000 | 0.070922447 |

Across all SNR points, Core has 1396 valid and 284 invalid trials. All 284 invalid statuses are TANGENT_PROFILE_NO_FEASIBLE_SCALE; no fallback is applied. P2/P4 separation estimates often approach the registered lower scale bound, so high localization success does not imply strict two-target resolution. These observations do not change any threshold or optimizer setting.

## Pairing, SNR and Runtime Evidence

[Within-domain pairing](58_stage8_k2_raw_tangent_within_domain_pairing.csv) contains 3 Beamspace and 10 Element method pairs, each with verified identical observation hashes across 1680 matched scenarios. RMSE counts use only common valid fits, with a 1e-12 degree tie tolerance. No cross-domain pair is included.

[Realized SNR summary](58_stage8_k2_raw_tangent_realized_snr_summary.csv) records natural deviations from nominal SNR for every domain/SNR cell. The 240 base realizations share sources and domain-specific standard noise across the seven SNR levels; these observations are not mutually independent across SNR.

The 19:05 controller stop recorded a duplicate-process condition without a historical process inventory. All 3360 checkpoint payloads and frozen code identities were verified before state recovery; the [recovery record](58_stage8_k2_raw_tangent_closeout_recovery.json) and [checkpoint inventory](58_stage8_k2_raw_tangent_checkpoint_inventory.csv) preserve the evidence. Runtime measurements are descriptive and do not establish a controlled speedup or historical host isolation. Scientific outputs were not recomputed or relabeled during closeout.

All 12 figures were regenerated from exported data with no estimator calls. The plot manifest records eight distinct method colors and the renderer configuration. Final scientific audit status and artifact hashes are in [the runtime manifest](58_stage8_k2_raw_tangent_runtime_manifest.json).
