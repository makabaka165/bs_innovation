# Raw Tangent: SC_A / SC_B, L=8

Status: STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_COMPLETE; INDEPENDENT_AUDIT=PASS.

Source parent: f1b13422a91540073ecf417c3b25f5cac552b9d6. Frozen implementation: d31737f1dc4d37cb3c3c9dd4b5c6136a5eed9eff. Source hash: 4f483ade0969a1f6dda9a400149fa2cd8b959981f41754b21f524af5ba805efe.

280 scenarios; 40 bases; 560 native-domain observations/checkpoints; 1400 method rows; 20 replicates per exact condition.

Both scenarios: center [8,10] deg, separation 0.45 deg, axis 30 deg. SC_A: secondary power 0 dB, correlation magnitude 0. SC_B: -3 dB and 0.7, with the original source-seeded random correlation phase.

These representative scenarios were designed after viewing the parent experiment. They are not a blind holdout. SC_B changes both power and correlation; it cannot isolate either causal effect.

Noise variance remains clean signal energy / (linear nominal SNR * sample count), independently in each native domain. Realized SNR fluctuates. The signal stays fixed across SNR; noise alone is scaled. All five methods are structurally applicable; numerical failures count as failures in the full denominator.

Localization: d_max_bw <= 0.1. Strict resolution: d_max_bw <= min(0.1,0.4*rho_true_bw). RMSE uses minimum total squared-error label matching; d_max independently uses minimax matching. Quantiles use valid fits only. Every count below has denominator 20: one outcome is 5 percentage points, not a population probability estimate.

## SC_A: Tangent

| SNR dB | Valid | Localization | Strict resolution | RMSE median deg | P90 deg |
|---:|---:|---:|---:|---:|---:|
| -6 | 5/20 | 1/20 | 0/20 | 0.28420128 | 0.36080141 |
| 0 | 18/20 | 8/20 | 3/20 | 0.24423695 | 0.29545304 |
| 6 | 20/20 | 14/20 | 8/20 | 0.21472807 | 0.25422286 |
| 10 | 20/20 | 18/20 | 12/20 | 0.11788216 | 0.23056068 |
| 14 | 20/20 | 20/20 | 15/20 | 0.085813398 | 0.22695046 |
| 18 | 20/20 | 20/20 | 19/20 | 0.053535832 | 0.13804439 |
| 22 | 20/20 | 20/20 | 20/20 | 0.034551993 | 0.073017366 |

First registered SNR with at least one valid outcome: -6 dB. 
First registered SNR with at least one localization_success_count outcome: -6 dB. 
First registered SNR with at least one resolution_success_count outcome: 0 dB. 

Descriptive criterion valid>=0.90 and strict resolution>=0.80: SNR points [18 22]. Isolated points do not establish a continuous stable interval. This is neither an experiment validity gate nor an online enabling threshold.

### Within-domain references

| Method | Native SNR dB | Valid | Localization | Resolution | RMSE median/P90 deg |
|---|---:|---:|---:|---:|---:|
| BEAMSPACE_MUSIC_K2 | -6 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 0 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 6 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 10 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 14 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 18 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 22 | 12/20 | 5/20 | 0/20 | 0.22850589 / 0.2622374 |
| FULL4D_BEAMSPACE_CML_MULTISTART | -6 | 20/20 | 5/20 | 2/20 | 0.35068321 / 0.58603624 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 0 | 20/20 | 5/20 | 2/20 | 0.24879927 / 0.60813214 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 6 | 20/20 | 11/20 | 7/20 | 0.22542509 / 0.36206875 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 10 | 20/20 | 15/20 | 11/20 | 0.14116573 / 0.27531854 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 14 | 20/20 | 19/20 | 16/20 | 0.1095125 / 0.14682953 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 18 | 20/20 | 20/20 | 20/20 | 0.070587904 / 0.11439823 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 22 | 20/20 | 20/20 | 20/20 | 0.043087178 / 0.075036367 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | -6 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 0 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 6 | 8/20 | 8/20 | 1/20 | 0.16074179 / 0.21698526 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 10 | 13/20 | 13/20 | 3/20 | 0.16190537 / 0.20942093 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 14 | 18/20 | 18/20 | 13/20 | 0.11341753 / 0.18961106 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 18 | 20/20 | 20/20 | 20/20 | 0.055332054 / 0.08632459 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 22 | 20/20 | 20/20 | 20/20 | 0.03069511 / 0.063858863 |
| FULL4D_ELEMENT_CML_MULTISTART | -6 | 20/20 | 19/20 | 15/20 | 0.11517019 / 0.17072057 |
| FULL4D_ELEMENT_CML_MULTISTART | 0 | 20/20 | 20/20 | 20/20 | 0.052101138 / 0.08727301 |
| FULL4D_ELEMENT_CML_MULTISTART | 6 | 20/20 | 20/20 | 20/20 | 0.026691954 / 0.043604211 |
| FULL4D_ELEMENT_CML_MULTISTART | 10 | 20/20 | 20/20 | 20/20 | 0.017801186 / 0.027874539 |
| FULL4D_ELEMENT_CML_MULTISTART | 14 | 20/20 | 20/20 | 20/20 | 0.012175258 / 0.018354299 |
| FULL4D_ELEMENT_CML_MULTISTART | 18 | 20/20 | 20/20 | 20/20 | 0.0090149741 / 0.012364508 |
| FULL4D_ELEMENT_CML_MULTISTART | 22 | 20/20 | 20/20 | 20/20 | 0.0063926028 / 0.0088717048 |

Positive resolution count difference favors Tangent; negative favors the reference. RMSE wins/ties/losses use only jointly valid estimates, tolerance 1e-6 deg.

| Reference on same Z | SNR dB | Resolution count difference | Common valid | Tangent RMSE wins/ties/losses |
|---|---:|---:|---:|---:|
| FULL4D_BEAMSPACE_CML_MULTISTART | -6 | -2 | 5 | 3/0/2 |
| BEAMSPACE_MUSIC_K2 | -6 | +0 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 0 | +1 | 18 | 7/0/11 |
| BEAMSPACE_MUSIC_K2 | 0 | +3 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 6 | +1 | 20 | 15/0/5 |
| BEAMSPACE_MUSIC_K2 | 6 | +8 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 10 | +1 | 20 | 13/0/7 |
| BEAMSPACE_MUSIC_K2 | 10 | +12 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 14 | -1 | 20 | 12/0/8 |
| BEAMSPACE_MUSIC_K2 | 14 | +15 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 18 | -1 | 20 | 13/0/7 |
| BEAMSPACE_MUSIC_K2 | 18 | +19 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 22 | +0 | 20 | 16/0/4 |
| BEAMSPACE_MUSIC_K2 | 22 | +20 | 12 | 12/0/0 |
## SC_B: Tangent

| SNR dB | Valid | Localization | Strict resolution | RMSE median deg | P90 deg |
|---:|---:|---:|---:|---:|---:|
| -6 | 11/20 | 1/20 | 1/20 | 0.27668704 | 0.49926275 |
| 0 | 19/20 | 6/20 | 2/20 | 0.26054386 | 0.35191548 |
| 6 | 20/20 | 11/20 | 1/20 | 0.21765013 | 0.29724208 |
| 10 | 20/20 | 12/20 | 4/20 | 0.19947399 | 0.2920835 |
| 14 | 20/20 | 13/20 | 9/20 | 0.15081551 | 0.23677936 |
| 18 | 20/20 | 16/20 | 11/20 | 0.1098608 | 0.24041067 |
| 22 | 20/20 | 15/20 | 13/20 | 0.095117475 | 0.25011823 |

First registered SNR with at least one valid outcome: -6 dB. 
First registered SNR with at least one localization_success_count outcome: -6 dB. 
First registered SNR with at least one resolution_success_count outcome: -6 dB. 

Descriptive criterion valid>=0.90 and strict resolution>=0.80: no registered SNR points. Isolated points do not establish a continuous stable interval. This is neither an experiment validity gate nor an online enabling threshold.

### Within-domain references

| Method | Native SNR dB | Valid | Localization | Resolution | RMSE median/P90 deg |
|---|---:|---:|---:|---:|---:|
| BEAMSPACE_MUSIC_K2 | -6 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 0 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 6 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 10 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| BEAMSPACE_MUSIC_K2 | 14 | 1/20 | 0/20 | 0/20 | 0.24428762 / 0.24428762 |
| BEAMSPACE_MUSIC_K2 | 18 | 2/20 | 0/20 | 0/20 | 0.25319472 / 0.2730411 |
| BEAMSPACE_MUSIC_K2 | 22 | 5/20 | 4/20 | 3/20 | 0.10337345 / 0.24479878 |
| FULL4D_BEAMSPACE_CML_MULTISTART | -6 | 20/20 | 1/20 | 0/20 | 0.43386837 / 0.56313637 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 0 | 20/20 | 2/20 | 0/20 | 0.34149571 / 0.50777971 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 6 | 20/20 | 8/20 | 1/20 | 0.23441988 / 0.29210366 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 10 | 20/20 | 16/20 | 10/20 | 0.14790781 / 0.23609147 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 14 | 20/20 | 20/20 | 14/20 | 0.096807289 / 0.17584949 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 18 | 20/20 | 20/20 | 19/20 | 0.070310439 / 0.13972716 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 22 | 20/20 | 20/20 | 20/20 | 0.040147237 / 0.10210783 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | -6 | 0/20 | 0/20 | 0/20 | NaN / NaN |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 0 | 1/20 | 0/20 | 0/20 | 0.22520449 / 0.22520449 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 6 | 8/20 | 8/20 | 7/20 | 0.10519255 / 0.17123264 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 10 | 14/20 | 11/20 | 10/20 | 0.11214295 / 0.21113639 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 14 | 17/20 | 15/20 | 12/20 | 0.078804278 / 0.20205155 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 18 | 20/20 | 18/20 | 15/20 | 0.070189922 / 0.19514293 |
| ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 22 | 20/20 | 19/20 | 18/20 | 0.039977247 / 0.16992967 |
| FULL4D_ELEMENT_CML_MULTISTART | -6 | 20/20 | 20/20 | 18/20 | 0.081811282 / 0.13836806 |
| FULL4D_ELEMENT_CML_MULTISTART | 0 | 20/20 | 20/20 | 20/20 | 0.044930554 / 0.092531113 |
| FULL4D_ELEMENT_CML_MULTISTART | 6 | 20/20 | 20/20 | 20/20 | 0.022715046 / 0.051093483 |
| FULL4D_ELEMENT_CML_MULTISTART | 10 | 20/20 | 20/20 | 20/20 | 0.015735808 / 0.031603431 |
| FULL4D_ELEMENT_CML_MULTISTART | 14 | 20/20 | 20/20 | 20/20 | 0.011736039 / 0.026237625 |
| FULL4D_ELEMENT_CML_MULTISTART | 18 | 20/20 | 20/20 | 20/20 | 0.0098416558 / 0.02428607 |
| FULL4D_ELEMENT_CML_MULTISTART | 22 | 20/20 | 20/20 | 20/20 | 0.0081139292 / 0.019257931 |

Positive resolution count difference favors Tangent; negative favors the reference. RMSE wins/ties/losses use only jointly valid estimates, tolerance 1e-6 deg.

| Reference on same Z | SNR dB | Resolution count difference | Common valid | Tangent RMSE wins/ties/losses |
|---|---:|---:|---:|---:|
| FULL4D_BEAMSPACE_CML_MULTISTART | -6 | +1 | 11 | 8/0/3 |
| BEAMSPACE_MUSIC_K2 | -6 | +1 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 0 | +2 | 19 | 15/0/4 |
| BEAMSPACE_MUSIC_K2 | 0 | +2 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 6 | +0 | 20 | 12/0/8 |
| BEAMSPACE_MUSIC_K2 | 6 | +1 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 10 | -6 | 20 | 6/0/14 |
| BEAMSPACE_MUSIC_K2 | 10 | +4 | 0 | 0/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 14 | -5 | 20 | 5/0/15 |
| BEAMSPACE_MUSIC_K2 | 14 | +9 | 1 | 1/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 18 | -8 | 20 | 6/0/14 |
| BEAMSPACE_MUSIC_K2 | 18 | +11 | 2 | 2/0/0 |
| FULL4D_BEAMSPACE_CML_MULTISTART | 22 | -7 | 20 | 2/0/18 |
| BEAMSPACE_MUSIC_K2 | 22 | +10 | 5 | 2/0/3 |

## Computation and interpretation

On SC_A, Tangent first reaches 20/20 valid at 6 dB, 20/20 localization at 14 dB and 20/20 strict resolution at 22 dB. It meets the descriptive validity/resolution criterion at the registered 18 and 22 dB points. Against Full4D on the same Z, its strict-resolution count differs by only one trial at 0 through 18 dB, with gains at 0/6/10 dB and losses at 14/18 dB; both reach 20/20 at 22 dB. Tangent has lower median RMSE at every registered SNR, but its low-SNR valid subset is smaller and its P90 is not uniformly lower. These results do not show a uniform resolution advantage.

On SC_B, Tangent first reaches 20/20 valid at 6 dB, but never reaches 20/20 localization or strict resolution, or the descriptive criterion. At 22 dB it yields 15/20 localized and 13/20 resolved versus Full4D's 20/20 and 20/20 on the same Z. At 10/14/18/22 dB, Full4D has 6/5/8/7 more strictly resolved trials and lower median/P90 RMSE. Tangent exceeds Beamspace MUSIC's resolution count at every registered SC_B SNR, but is not the best Beamspace method at moderate/high SNR.

For Element-native references, Full4D resolves 20/20 in both scenarios from 0 dB on the registered grid. At 22 dB, FBSS Root resolves 20/20 on SC_A and 18/20 on SC_B. These Element results use different observations from Beamspace and cannot establish cross-domain paired superiority. Tangent's total score calls are about 22 times fewer than Beamspace Full4D in both scenarios; the observed runtimes below remain descriptive.

| Scenario | Method | Trials | Score calls | SVD calls | Eig calls | Runtime median/P90 sec |
|---|---|---:|---:|---:|---:|---:|
| SC_A | BEAMSPACE_MUSIC_K2 | 140 | 2732940 | 0 | 140 | 0.0407209 / 0.0420601 |
| SC_B | BEAMSPACE_MUSIC_K2 | 140 | 2732940 | 0 | 140 | 0.0406267 / 0.041906 |
| SC_A | FULL4D_BEAMSPACE_CML_MULTISTART | 140 | 539585 | 1079170 | 0 | 3.786 / 4.09637 |
| SC_B | FULL4D_BEAMSPACE_CML_MULTISTART | 140 | 550598 | 1101196 | 0 | 3.70947 / 4.17364 |
| SC_A | TANGENT_PROFILE_CORE | 140 | 23790 | 47720 | 280 | 0.0938631 / 0.104323 |
| SC_B | TANGENT_PROFILE_CORE | 140 | 24637 | 49414 | 280 | 0.0941104 / 0.101728 |
| SC_A | ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 140 | 331283 | 322743 | 140 | 1.52527 / 1.92886 |
| SC_B | ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML | 140 | 343313 | 334773 | 140 | 1.58957 / 1.95671 |
| SC_A | FULL4D_ELEMENT_CML_MULTISTART | 140 | 633560 | 633560 | 0 | 3.98921 / 4.08842 |
| SC_B | FULL4D_ELEMENT_CML_MULTISTART | 140 | 645026 | 645026 | 0 | 4.05232 / 4.18225 |

Runtime is descriptive wall time on this workstation, with MATLAB R2022b -singleCompThread and one verified compute worker. Scheduled interruptions, host load and dictionary preparation can affect timing. Score/SVD/eig counts do not by themselves prove an end-to-end speedup. No timing reruns or tuning are performed.

Three Beamspace methods share Z; two Element methods share Y_e. Cross-domain results are scenario-matched references at equal nominal SNR in different native domains and use different observations. They support no cross-domain paired wins/losses or same-physical-observation claim.

Results apply to these two local off-grid, known-K=2, single-CPI conditions, this fixed aperture and the registered SNR grid. They do not establish general superiority, robustness outside these conditions, or production readiness. Poor performance is a scientific outcome, not experimental invalidity.

The adjacent scenario, failure, complexity and pairing CSVs retain valid counts, d_max, axis/rho error, lower-bound hits, Root elevation/conditional failure stages and all within-domain cross-counts. Equal-weight pooled SNR statistics are supplementary. The eight figures regenerate from committed plot_data.csv and representative trace MAT only, without runtime or fitting.

Scientific core and budgets, native SNR formula and success criteria are unchanged. No Tangent cache, fixed-K2 fallback or Toeplitz path is introduced. Earlier evidence is available at the source parent and is never merged with these observations. NEXT=USER_REVIEW; MERGE_BACK=NOT_AUTHORIZED.

## Independent audit recovery

The first independent audit stopped with MATLAB:badsubscript when CSV 0/1 columns were imported as doubles and used as row indices by the frozen summarizer. A separate recovery verifier restores the seven declared logical columns only after checking every value is exactly 0 or 1. It retains all original reconstruction, metric, table, scope and artifact assertions and all tolerances. The fresh MATLAB R2022b session passed this audit without rerunning any estimator. All 560 checkpoint hashes and all original artifact hashes were unchanged during recovery. The subsequent report-only interpretation and status updates have refreshed artifact hashes in the final runtime manifest.

[Recovery record](60_stage8_k2_raw_tangent_two_scenarios_audit_recovery.json) records the preserved formal identity, verifier hash and independent audit result. [Checkpoint SHA-256 inventory](60_stage8_k2_raw_tangent_two_scenarios_audit_recovery/checkpoint_sha256.json) preserves the full checkpoint evidence. The frozen implementation remains d31737f1dc4d37cb3c3c9dd4b5c6136a5eed9eff; the recovery verifier is committed as an audit artifact, outside the formal scientific source enumeration.
