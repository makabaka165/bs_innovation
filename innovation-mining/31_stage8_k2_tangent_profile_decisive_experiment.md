# Stage8 K2 Tangent-Profile Decisive Experiment

Protocol: `STAGE8_K2_TANGENT_PROFILE_DECISIVE_EXPERIMENT_V1`

Execution HEAD: `95a9d1e314fb7c7aa2addcacd00ac559a97db21f`

Runtime root: `E:\bs_innovation_runtime\stage8_k2_tangent_profile_v1`

Theory tests: noiseless direction PASS; isotropic noise shift PASS; rank deficiency PASS; full-manifold smoke PASS.

Registry: K2 `72/72`; method rows `216/216`; tangent diagnostics `72/72`.

Integrity: counts `1`; truth isolation `1`; shared element data `1`; registry/seeds `1`; scenario `1`; M2 safe returns `1`.

## Overall accuracy and cost

| Method | Valid | Median RMSE deg | P90 RMSE deg | Mean score | Mean SVD | Median runtime sec | P90 runtime sec |
|---|---:|---:|---:|---:|---:|---:|---:|
| CORE_LITE | 72/72 | 0.18381185099009095 | 0.37919229496972062 | 152.05555555555554 | 350.83333333333331 | 0.16847655 | 0.20971774000000001 |
| CORE_PLUS | 72/72 | 0.14962699647489097 | 0.37617628510775392 | 2741.3055555555557 | 5530.1805555555557 | 2.5799736500000003 | 3.7313039100000003 |
| TANGENT_PROFILE_SAFE | 72/72 | 0.077518689009694899 | 0.25282012017906685 | 394.23611111111109 | 861.19444444444446 | 4.9531336499999998 | 5.3553026399999997 |

## Tangent diagnostics

- Raw valid: `70/72`; upgrades/fallbacks: `59/13`.
- Direction median/p90: `7.7820411806905136 / 166.43295447715025 deg`.
- Rho median/p90: `0.10684032544331977 / 0.22774932519295688 deg`.
- Separation-vector median/p90: `0.12421429606116124 / 0.3482861119204595 deg`.

## Paired comparisons

| Comparison | Wins | Ties | Losses |
|---|---:|---:|---:|
| TANGENT_PROFILE_SAFE_vs_CORE_LITE | 53 | 13 | 6 |
| TANGENT_PROFILE_SAFE_vs_CORE_PLUS | 54 | 7 | 11 |

Tie tolerance is reporting-only at `1e-6 deg`.

## Profile, L, and SNR summaries

| Scope | Value | Method | Valid | N | Median RMSE deg | P90 RMSE deg |
|---|---|---|---:|---:|---:|---:|
| PROFILE | P1 | CORE_LITE | 18 | 18 | 0.14168130832543541 | 0.24085227997088404 |
| PROFILE | P2 | CORE_LITE | 18 | 18 | 0.2440909644282187 | 0.43861739379323589 |
| PROFILE | P3 | CORE_LITE | 18 | 18 | 0.14591175076110513 | 0.28281195934094205 |
| PROFILE | P4 | CORE_LITE | 18 | 18 | 0.25343785268195113 | 0.37919229496972062 |
| L | 1 | CORE_LITE | 24 | 24 | 0.24039129220794059 | 0.37919229496972062 |
| L | 4 | CORE_LITE | 24 | 24 | 0.14989759566692679 | 0.4128406225010498 |
| L | 8 | CORE_LITE | 24 | 24 | 0.14168130832543541 | 0.27235742165800392 |
| SNR_DB | -6 | CORE_LITE | 24 | 24 | 0.25233670784255841 | 0.42737573234290321 |
| SNR_DB | +0 | CORE_LITE | 24 | 24 | 0.18381185099009095 | 0.37919229496972062 |
| SNR_DB | +6 | CORE_LITE | 24 | 24 | 0.14168130832543541 | 0.23125489451380404 |
| PROFILE | P1 | CORE_PLUS | 18 | 18 | 0.14168130832543527 | 0.2301427201197476 |
| PROFILE | P2 | CORE_PLUS | 18 | 18 | 0.21302304502305203 | 0.42138466325513402 |
| PROFILE | P3 | CORE_PLUS | 18 | 18 | 0.10307764064044168 | 0.20195161832045538 |
| PROFILE | P4 | CORE_PLUS | 18 | 18 | 0.24830892901466428 | 0.37919229496972062 |
| L | 1 | CORE_PLUS | 24 | 24 | 0.19491744516676679 | 0.36370619103793334 |
| L | 4 | CORE_PLUS | 24 | 24 | 0.1552976143408209 | 0.38868411013018811 |
| L | 8 | CORE_PLUS | 24 | 24 | 0.14168130832543527 | 0.25038813922186287 |
| SNR_DB | -6 | CORE_PLUS | 24 | 24 | 0.23710920416492398 | 0.40593085790850536 |
| SNR_DB | +0 | CORE_PLUS | 24 | 24 | 0.1553835369167717 | 0.37876860767345782 |
| SNR_DB | +6 | CORE_PLUS | 24 | 24 | 0.11665786364340461 | 0.20622404766812133 |
| PROFILE | P1 | TANGENT_PROFILE_SAFE | 18 | 18 | 0.05212463084571331 | 0.17859333433396474 |
| PROFILE | P2 | TANGENT_PROFILE_SAFE | 18 | 18 | 0.1138122561774932 | 0.33369316876852967 |
| PROFILE | P3 | TANGENT_PROFILE_SAFE | 18 | 18 | 0.058131940266647392 | 0.085703743424046783 |
| PROFILE | P4 | TANGENT_PROFILE_SAFE | 18 | 18 | 0.087919828420263788 | 0.22108469343307446 |
| L | 1 | TANGENT_PROFILE_SAFE | 24 | 24 | 0.10153882032022089 | 0.26570652320061328 |
| L | 4 | TANGENT_PROFILE_SAFE | 24 | 24 | 0.076509167067210213 | 0.32592160697847611 |
| L | 8 | TANGENT_PROFILE_SAFE | 24 | 24 | 0.074680176947345148 | 0.11611750645764835 |
| SNR_DB | -6 | TANGENT_PROFILE_SAFE | 24 | 24 | 0.1118980163365712 | 0.28985742165800366 |
| SNR_DB | +0 | TANGENT_PROFILE_SAFE | 24 | 24 | 0.078137814460309013 | 0.26138891174911882 |
| SNR_DB | +6 | TANGENT_PROFILE_SAFE | 24 | 24 | 0.066073722846644034 | 0.11076454976918927 |

## Gamma_K2_proxy quartiles

| Quartile | N | Gamma median | Direction median/p90 deg | Rho median/p90 deg | RMSE median deg | Raw valid rate | Fallback rate |
|---|---:|---:|---:|---:|---:|---:|---:|
| Q1 | 18 | 3.8049956565289689 | 20.352265797908483 / 94.217527506892395 | 0.1177802070952661 / 0.26083023614188128 | 0.10050354884677053 | 1 | 0.22222222222222221 |
| Q2 | 18 | 32.368613124289716 | 8.6034635384698603 / 156.97345179291392 | 0.094595530628773683 / 0.18527497554023065 | 0.063073345111808413 | 1 | 0.16666666666666666 |
| Q3 | 18 | 95.984739955475391 | 4.229612413576243 / 62.200073760114599 | 0.11619798912144297 / 0.3246282560785132 | 0.07539660434010316 | 1 | 0.1111111111111111 |
| Q4 | 18 | 742.89846322690005 | 2.0872369899187531 / 178.83600710954701 | 0.13665495475807116 / 0.19900000000000001 | 0.08927789622212845 | 0.88888888888888884 | 0.22222222222222221 |

Gamma is truth-only descriptive analysis and is not an online threshold.

## Decision

Final conclusion: `STAGE8_K2_TANGENT_PROFILE_RETAIN`

The decision applies the frozen RETAIN, RETAIN_AS_EFFICIENT_OPTION, NOT_RETAINED, and EXPERIMENT_INVALID rules without tuning or rerunning.

## Prior-art position

The result is positioned only as a system-specific combination of a K1 projected residual, a Fisher-metric generalized eigenvector on the actual fixed exactly whitened two-dimensional sequential beamspace manifold, and a one-dimensional exact full-manifold K2 profile likelihood with fixed-grid fallback. Vincent et al. (2014, DOI 10.1016/j.sigpro.2013.10.017) and Bonacci et al. (2017, DOI 10.1049/iet-rsn.2016.0446) already cover close-source Taylor approximate ML and one-dimensional reductions; Partial Relaxation (arXiv:1711.01982) covers eigenvalue-based dimension reduction; Kim et al. (2012, DOI 10.1049/iet-rsn.2010.0163) covers two targets in beamspace. No first-in-field claim is made. If the identical combination is found, the classification is `SYSTEM-SPECIFIC IMPLEMENTATION / ENGINEERING SPECIALIZATION`.

## Stop rule

No V2, extra starts, center correction, second direction, Hessian solver, automatic K, bootstrap, additional trials, production change, or merge is authorized by this result.
