# Stage8 K2 White-SNR Classical Baseline Comparison

Status: `STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPARISON_COMPLETE`

Interpretation: `STAGE8_K2_TANGENT_ADVANTAGE_OVER_NUMERICAL_BEAMSPACE_CML_SUPPORTED`

Branch: `work/stage8-k2-white-snr-classical-baselines-v1`

Source Tangent HEAD: `d2d59fe550d8999dc8589aa76e52e89736539b66`

Formal tool HEAD: `a76fb245db22b6e23f1c067659d34e8b232fe2f0`

## Integrity

- Evidence-44 registry and checkpoints: `1680/1680`.
- Existing method rows: `5040`; new baseline rows: `5040`.
- Beamspace Full4D/MUSIC rows: `1680/1680`.
- MUSIC applicable rows: `1120`; Element CML subset: `160`.
- Truth/profile/Tangent/Core initializer leakage: `0/0/0/0`.
- Full4D is finite-budget numerical CML, not a global optimum proof.
- Element CML is a more-informative, non-identical hardware reference.
- MUSIC N/A or single-peak output is not counted as a Tangent win.

## Tangent Versus Beamspace Full4D CML

| White SNR | Tangent median | Full4D median | Tangent P90 | Full4D P90 | W/T/L | Incomplete | Complete N |
|---:|---:|---:|---:|---:|---:|---:|---:|
| -6 | 0.438478 | 0.414214 | 0.626654 | 0.649404 | 101/29/110 | 2 | 238 |
| +0 | 0.321091 | 0.334765 | 0.609659 | 0.636025 | 134/16/90 | 12 | 228 |
| +6 | 0.242737 | 0.267212 | 0.552834 | 0.568747 | 144/8/88 | 10 | 230 |
| +10 | 0.183822 | 0.239046 | 0.5 | 0.517526 | 149/5/86 | 7 | 233 |
| +14 | 0.116329 | 0.204741 | 0.382897 | 0.496046 | 182/1/57 | 13 | 227 |
| +18 | 0.0921042 | 0.1683 | 0.293417 | 0.395602 | 188/0/52 | 27 | 213 |
| +22 | 0.0796222 | 0.129955 | 0.223607 | 0.315331 | 177/0/63 | 32 | 208 |

The preregistered `+10/+14/+18/+22 dB` condition qualifies at `4/4` points. The pooled complete-likelihood Tangent condition is `true`.

## Beamspace MUSIC

State: `MUSIC_TWO_PEAK_REGION_NOT_IDENTIFIED`

| White SNR | Applicable | Rank valid | Single peak | Valid K2 | Valid rate | Valid RMSE median |
|---:|---:|---:|---:|---:|---:|---:|
| -6 | 160 | 160 | 160 | 0 | 0.000000 | NaN |
| +0 | 160 | 160 | 160 | 0 | 0.000000 | NaN |
| +6 | 160 | 160 | 160 | 0 | 0.000000 | NaN |
| +10 | 160 | 160 | 160 | 0 | 0.000000 | NaN |
| +14 | 160 | 160 | 160 | 0 | 0.000000 | NaN |
| +18 | 160 | 160 | 160 | 0 | 0.000000 | NaN |
| +22 | 160 | 160 | 160 | 0 | 0.000000 | NaN |

## Element Reference

Status: `ELEMENT_REFERENCE_DESCRIPTIVE`

| Method | Valid | Median RMSE | P90 | Median runtime (s) |
|---|---:|---:|---:|---:|
| `TANGENT_PROFILE_SAFE` | 160 | 0.106517 | 0.3616 | 4.34197 |
| `FULL4D_BEAMSPACE_CML_MULTISTART` | 160 | 0.165737 | 0.394345 | 4.13839 |
| `FULL4D_ELEMENT_CML_MULTISTART` | 160 | 0.163062 | 0.376438 | 13.5472 |

Element-domain and beamspace likelihood magnitudes are not compared.

## Scientific Boundary

Tangent and Beamspace Full4D/MUSIC use the same white-SNR trials and the same 15-dimensional whitened sequential beamspace. Element CML uses all 2080 active elements and is more informative. No result changes Tangent, production, or the long-term Tangent branch, and merge-back remains unauthorized.
