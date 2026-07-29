# Stage8 Core-V2.2 Corrected Final Single-CPI Known-K Validation

Protocol: `STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_F1_ORACLE_CORRECTION_V1`

Old invalid report: `28_stage8_core_v2_2_final_single_cpi_known_k_validation.md`

Correction: F1 canonical K1 oracle changed from impossible H1+H2 equality to final conventional H1 only.

Production scientific code changed: `false`

Registry/seeds changed: `false`

Decision rules changed: `false`

F0: `F0_BOUNDARY_AND_ENVIRONMENT_PASS`

F1A: `F1A_CANONICAL_ORACLE_CONTRACT_PASS`

- Canonical K1 oracle: `H1_DIRECT_SAFE_HYBRID_KNOWN_K`
- Noncanonical H2 K1 difference trials: `16`
- Scientific H1/H2 K1 difference trials: `1`

F1B: `F1B_PRODUCTION_24_TRIAL_REGRESSION_PASS`

- Element hashes: `24/24`
- K1 mode identity: `16/16`
- K1 H1 canonical: `16/16`
- K2 CORE_LITE B0: `8/8`
- K2 CORE_PLUS H2: `8/8`

Independent validation: K1 `72/72`, K2 `72/72`, rows `288/288`.

## CORE_LITE

- Valid: K1 `72/72`, K2 `72/72`
- K1 overall median/p90 RMSE: `0.011616187362665439 / 0.052506027053567626 deg`
- K1 off-grid median/p90 RMSE: `0.010389316715065527 / 0.051751616263288336 deg`
- K1 paired wins/ties/losses: `54/0/0`
- Mean score/SVD calls: `177.74305555555554 / 391.81944444444446`
- Runtime median/p90: `0.14633940000000001 / 0.17363699999999999 sec`

## CORE_PLUS

- Valid: K2 `72/72`
- K2 overall median/p90 RMSE: `0.14168130832543541 / 0.36164220317772783 deg`
- K2 profile `P1` median RMSE: `0.14168130832543513 deg`
- K2 profile `P2` median RMSE: `0.22364880406823245 deg`
- K2 profile `P3` median RMSE: `0.10307764064044168 deg`
- K2 profile `P4` median RMSE: `0.2001013025997373 deg`
- K2 paired wins/ties/losses: `26/33/13`
- K2 upgrades/fallbacks: `39/33`
- Mean score/SVD calls: `1445.2916666666667 / 2927.3194444444443`
- Runtime median/p90: `0.2270906 / 2.9113251199999999 sec`

## Q Quartiles

- `Q1`: n=18, median q=12.42209489758825, median RMSE=0.18381185099009095 deg, fallback=0.61111111111111116
- `Q2`: n=18, median q=18.644763130356516, median RMSE=0.14873589360201769 deg, fallback=0.44444444444444442
- `Q3`: n=18, median q=69.978726259291733, median RMSE=0.14168130832543513 deg, fallback=0.33333333333333331
- `Q4`: n=18, median q=123.90506691725017, median RMSE=0.14168130832543541 deg, fallback=0.44444444444444442

Final state: `STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL`

SINGLE_CPI
SINGLE_RANGE_DOPPLER_CELL
KNOWN_K_CONDITIONAL_ESTIMATION
NO_TRACKING_INPUT
NO_CROSS_CPI_INPUT
NO_MODEL_ORDER_CLAIM
NO_FORMAL_STAGE8_1_PASS
NO_STAGE8_2_AUTHORIZATION

Model-order: DEFERRED
Formal 6000-trial: DEFERRED_NOT_FAILED
Stage8.2: NOT_EXECUTED
