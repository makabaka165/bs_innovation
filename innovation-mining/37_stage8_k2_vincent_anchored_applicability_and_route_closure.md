# Stage8 K2 Vincent Anchored Applicability and Route Closure

Protocol: STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_AND_CLOSURE_V1

Starting evidence HEAD: 33ce9238fa09d4ec5b4de865fb41a98710621b8b

## Analysis mode

- analysis_only_flag = true
- fitting_rerun = false
- new_trial_count = 0
- new_seed_count = 0
- external_runtime_inputs_required = false

## Integrity

- Method rows 288/288; trials 72/72; diagnostics 72/72.
- Method contract 1; shared hashes 1; truth isolation 1.
- Historical summary reconstruction max abs error 4.5474735088646412e-12 (limit 1e-10).
- Profile summary 1; complexity summary 1; historical report 1.

## Authorized group classifications

| Scope | Value | N | Classification | Tangent median/P90 | Anchored median/P90 | W/T/L |
|---|---|---:|---|---:|---:|---:|
| PROFILE | P1 | 18 | MEDIAN_GAIN_BUT_TAIL_UNSTABLE | 0.0980031638 / 0.150765604 | 0.0660984441 / 0.147637547 | 7/4/7 |
| PROFILE | P2 | 18 | MEDIAN_GAIN_BUT_TAIL_UNSTABLE | 0.11142088 / 0.221167974 | 0.105770857 / 0.414144967 | 6/0/12 |
| PROFILE | P3 | 18 | SEPARATION_STRUCTURE_ONLY | 0.0750349435 / 0.101362399 | 0.0851670287 / 0.225052919 | 5/1/12 |
| PROFILE | P4 | 18 | NOT_SUPPORTED | 0.113064045 / 0.287226635 | 0.193828703 / 0.347668631 | 5/3/10 |
| L | 1 | 24 | SEPARATION_STRUCTURE_ONLY | 0.124151075 / 0.209680651 | 0.151666388 / 0.386950248 | 5/8/11 |
| L | 4 | 24 | MEDIAN_GAIN_BUT_TAIL_UNSTABLE | 0.092594003 / 0.192163284 | 0.0899860152 / 0.219300643 | 9/0/15 |
| L | 8 | 24 | SEPARATION_STRUCTURE_ONLY | 0.0701089604 / 0.145639399 | 0.0795766707 / 0.231460756 | 9/0/15 |
| SNR | -6 | 24 | SEPARATION_STRUCTURE_ONLY | 0.113570283 / 0.197116431 | 0.158179181 / 0.370615476 | 6/4/14 |
| SNR | 0 | 24 | SEPARATION_STRUCTURE_ONLY | 0.0846069825 / 0.20922949 | 0.0995136385 / 0.217611949 | 11/2/11 |
| SNR | 6 | 24 | NOT_SUPPORTED | 0.0747429184 / 0.134518747 | 0.0880293806 / 0.203100822 | 6/2/16 |
| NOISE | WHITE | 36 | SEPARATION_STRUCTURE_ONLY | 0.092594003 / 0.193744799 | 0.106917085 / 0.271266719 | 10/6/20 |
| NOISE | STAGE5_TOEPLITZ_CORRELATED | 36 | NOT_SUPPORTED | 0.0860094425 / 0.161361523 | 0.118775035 / 0.232449625 | 13/2/21 |

## Mechanism diagnostics

- Median b_parallel_abs: 0.195348936.
- Median b_perp: 0.0546481824.
- Median diagnostic axis error: 3.89891801 deg.
- Median anchor valid ratio: 0.230769231.
- Median selected curvature proxy: 3.711313e-05.
- Median normalized alpha correction error: 0.322118308.

Quartiles are descriptive only and do not authorize an online threshold or selector.

## Final applicability state

STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_CLOSED_NO_ROBUST_REGIME

Vincent-Anchored positioning: NO ROBUST APPLICABILITY REGIME.

## Paper-authorized boundary

Supported: the Vincent/Bonacci-inspired moving-anchor extension is theoretically and computationally operational on the frozen cylindrical-array sequential beamspace. Registered favorable regimes identified above may improve endpoint RMSE and separation structure. It improves on Core-Lite overall and uses fewer score/SVD calls than the diagnostic Full4D baseline.

Not supported: a unified Tangent replacement; applicability across every power, correlation, SNR, or snapshot condition; stable P2/P3/P4 improvement; post-hoc online switching from center bias, axis error, anchor ratio, or curvature; superiority to theoretical global ML; or production integration.

## Route closure

- Default K2 method: TANGENT_PROFILE_SAFE
- Vincent-Anchored: NOT_DEFAULT / NOT_PRODUCTION / NO_V2
- Automatic selector: NOT_AUTHORIZED
- Further Stage8-K2 algorithm execution: NOT_AUTHORIZED
