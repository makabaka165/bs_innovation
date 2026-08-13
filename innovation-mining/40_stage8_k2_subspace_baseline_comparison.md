# Stage8 K2 Structured Subspace Baseline Comparison

Terminal status: `STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_COMPLETE`

Protocol: `STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_V1`

Execution HEAD: `28da0671255e0efad9334fa8c792b71fc8a0d853`

Runtime root: `E:/bs_innovation_runtime/stage8_k2_subspace_baselines_v1`

The new methods are `MORE-INFORMATIVE ELEMENT-DOMAIN CLASSICAL REFERENCES`; they do not share Tangent's 15-dimensional beamspace hardware interface.

## Integrity and structure

- Trial reconstruction: `72/72` exact element hashes.
- New method rows: `216/216`; reference rows read from evidence 34: `312`.
- Truth isolation: `1`; applicability: `1`; explicit outcomes: `1`.
- Cylindrical Kronecker residual max: `2.4821208662036907e-14`.
- Vertical shift residual max: `7.6595465921402161e-15`.
- Noise Kronecker residual max: `0`; colored residual: `0`.
- Azimuth whitening residual max: `8.118057839275325e-16`.

## Overall method results

| Method | Applicable | Valid | Invalid | Joint RMSE median/p90 deg | Az RMSE median/p90 | El RMSE median/p90 | Runtime median/p90 s |
|---|---:|---:|---:|---:|---:|---:|---:|
| TANGENT_PROFILE_SAFE | 72 | 72 | 0 | 0.0775187 / 0.25282 | 0.0485304 / 0.220684 | 0.0400455 / 0.105816 | 4.95313 / 5.3553 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 72 | 72 | 0 | 0.13587 / 0.336852 | 0.0746135 / 0.305372 | 0.0799714 / 0.160078 | 5.48005 / 7.47654 |
| FULL4D_ELEMENT_CML_MULTISTART | 24 | 24 | 0 | 0.164849 / 0.339413 | 0.0840727 / 0.326824 | 0.0669651 / 0.158689 | 14.7131 / 96.6114 |
| BEAMSPACE_MUSIC_K2 | 48 | 0 | 48 | NaN / NaN | NaN / NaN | NaN / NaN | NaN / NaN |
| ELEMENT_MUSIC_K2 | 48 | 0 | 48 | NaN / NaN | NaN / NaN | NaN / NaN | NaN / NaN |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML | 54 | 0 | 54 | NaN / NaN | NaN / NaN | NaN / NaN | NaN / NaN |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 27 | 2 | 25 | 0.0974328 / 0.113081 | 0.0415451 / 0.0746836 | 0.0801784 / 0.0820237 | 2.58925 / 2.86483 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | 27 | 1 | 26 | 0.130172 / 0.130172 | 0.00935588 / 0.00935588 | 0.129835 / 0.129835 | 1.59864 / 1.59864 |

## Elevation and conditional-CML diagnostics

| Method | Applicable | Elevation valid | Conditional az CML valid |
|---|---:|---:|---:|
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML | 54 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 27 | 2 | 2 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | 27 | 1 | 1 |

## Pairwise common-subset comparisons

| Comparison (left vs right) | Common valid | Wins | Ties | Losses |
|---|---:|---:|---:|---:|
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML_vs_TANGENT_PROFILE_SAFE | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML_vs_FULL4D_BEAMSPACE_CML_MULTISTART | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML_vs_FULL4D_ELEMENT_CML_MULTISTART | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML_vs_BEAMSPACE_MUSIC_K2 | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML_vs_ELEMENT_MUSIC_K2 | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML_vs_TANGENT_PROFILE_SAFE | 2 | 0 | 0 | 2 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML_vs_FULL4D_BEAMSPACE_CML_MULTISTART | 2 | 1 | 0 | 1 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML_vs_FULL4D_ELEMENT_CML_MULTISTART | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML_vs_BEAMSPACE_MUSIC_K2 | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML_vs_ELEMENT_MUSIC_K2 | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML_vs_TANGENT_PROFILE_SAFE | 1 | 0 | 0 | 1 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML_vs_FULL4D_BEAMSPACE_CML_MULTISTART | 1 | 1 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML_vs_FULL4D_ELEMENT_CML_MULTISTART | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML_vs_BEAMSPACE_MUSIC_K2 | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML_vs_ELEMENT_MUSIC_K2 | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML_vs_ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML_vs_ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | 0 | 0 | 0 | 0 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML_vs_ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | 0 | 0 | 0 | 0 |

Tie tolerance is reporting-only at `1e-6 deg`.

## Stratified spread

| Method | Dimension | Best median joint RMSE | Worst median joint RMSE |
|---|---|---:|---:|
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML | PROFILE | NaN | NaN |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML | L | NaN | NaN |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML | SNR_DB | NaN | NaN |
| ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML | NOISE | NaN | NaN |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | PROFILE | 0.0778719 | 0.116994 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | L | 0.0974328 | 0.0974328 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | SNR_DB | 0.0974328 | 0.0974328 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | NOISE | 0.0974328 | 0.0974328 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | PROFILE | 0.130172 | 0.130172 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | L | 0.130172 | 0.130172 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | SNR_DB | 0.130172 | 0.130172 |
| ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML | NOISE | 0.130172 | 0.130172 |

## Interpretation

1. Frozen standard MUSIC produced `0` valid rows among `96` applicable method-trials. The coherent/near-coherent K2 sample covariance exposes one dominant peak without spatial smoothing; this is why the frozen two-dimensional peak picker returned fewer than two peaks.
2. The coherent synthetic fixture restores a two-dimensional vertical signal subspace after P=2 FBSS. Formal GFBSS-MUSIC found two elevations in `0/54` applicable trials.
3. Root-MUSIC root-selection success is `2/27`; LS-ESPRIT eigenvalue success is `1/27` on their white-noise structural subset.
4. Conditional azimuth CML was not the principal error source on the three valid new-method rows. Root-MUSIC's valid-subset median azimuth/elevation RMSE was `0.04155 / 0.08018 deg`; the one valid ESPRIT row was `0.00936 / 0.12984 deg`. Elevation extraction dominated, and every valid elevation pair reached a valid conditional CML result (`3/3`).
5. Tangent remains the default compressed K2 method. Its overall median joint RMSE/runtime are `0.0775187 deg / 4.95313 s`. On their common valid subsets, Root-MUSIC lost both comparisons with Tangent and ESPRIT lost its one comparison. Root-MUSIC and ESPRIT successful-row median runtimes were `2.58925 s` and `1.59864 s`, but they used all 2080 active elements and were valid in only `2/27` and `1/27` applicable trials. GFBSS-MUSIC was valid in `0/54`. These references therefore do not provide a hardware-equivalent replacement for Tangent.
6. The only valid new-method trials were white-noise `+6 dB` cases: Root-MUSIC at `L=8` for P1 and P3, and ESPRIT at `L=1` for P3. P4 produced no valid result, correlated-noise Root-MUSIC/ESPRIT were structural N/A, and GFBSS-MUSIC produced no formal two-peak result. The valid sample is too small to support a broader L/SNR/noise performance trend; the complete stratification remains in `40_*_profile_summary.csv` without a performance threshold.
7. P2 has equal elevations and therefore only one unique vertical spatial frequency. All 54 P2 method rows are structural N/A, not failures or Tangent wins.
8. Full-UCA phase-mode methods are excluded because the registered observation uses only a 65-of-192 active sector. Expanding to a complete UCA would change both aperture and input data.

Default K2: `TANGENT_PROFILE_SAFE`.

Production integration: `false`. Tangent scientific code changed: `false`.

## Execution note

The single MATLAB runner reached `72/72`, wrote both runtime and repository
evidence, and printed
`STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_RUNTIME_COMPLETE`. The Windows MATLAB
process then reported heap corruption during shutdown, after the runner had
returned its completed output. All seven runtime/repository evidence pairs
were SHA-256 identical, an independent CSV audit passed every completion
contract, and a separate MATLAB R2022b post-run audit passed and exited
normally. No trial computation or evidence write was interrupted.
