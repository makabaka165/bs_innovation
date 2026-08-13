# Stage8 K2 Tangent Pipeline Canonical Dictionary Placement Audit

Status: `STAGE8_K2_TANGENT_PIPELINE_CACHE_PLACEMENT_AUDIT_COMPLETE`

Technical status: `TECHNICALLY_CERTIFIED`

Predicted performance status: `PREDICTED_SAVING_INCONCLUSIVE`

This is a diagnostic placement audit. The 21-key dictionary was not integrated into the production estimator; every dictionary decision check was a shadow replay.

## A. Git

- Repository: `E:/bs_innovation`
- Branch: `experiment/stage8-k2-tangent-canonical-cache-v1`
- Level-A closure commit: `cf35e37a74366a8d9829de3a1f8b740a788bade1`
- Audit start commit: `aff3bb42df2b3d9b435cc57eacd3237826e7d87d`
- Audit code commit: `354109c80203c7100f255aaf54aef4150b436ea6`
- Evidence write base HEAD: `354109c80203c7100f255aaf54aef4150b436ea6`
- Push: performed after evidence commit by the execution agent
- Prompt input file: preserved locally and excluded from commits

## B. Theory

- Registered domain: azimuth `7.4:0.2:8.6` (7) and elevation `9.8:0.2:10.2` (3); `|Omega| = 21`.
- Single universe: `21` per identity.
- Canonical unordered K2 universe including diagonal: `231` per identity.
- Ordered nested universe: `441` per identity.
- Measurement identities: `2`, with `36` frozen trials each.
- Closure: fixed registered starts remain in `Omega^K`; grouped elevation/conditional azimuth outputs are selected from the registered grids.
- Shared dictionary numeric representative: `BALANCED_SINGLE_PAIR_DIRECT_ACCUMULATION_MIDPOINT`, resolving the frozen single-column/two-column BLAS accumulation split without changing any tolerance or production path.

## C. Static certification

- Singles passed: `42/42`.
- Canonical pairs passed: `462/462`.
- Ordered nested assemblies passed: `882/882`.
- Max legacy/direct G relative error: `0`.
- Max legacy/direct G absolute error: `0`.
- Max direct/dictionary G relative error: `7.5390264803513174e-11`.
- Max singular-value difference: `8.830003395132735e-11`.
- Max exact-key error: `0 deg`.
- Max rank-threshold difference: `1.1662519622787439e-25`.
- Rank mismatch: `0`.
- First/second-column identity mismatch: `0`.
- Continuous numeric certification: `PASS`.
- Discrete decision certification: `PASS`.

## D. 72-trial trajectory

- Key mismatch: `0`.
- Rank mismatch: `0`.
- Candidate-order mismatch: `0`.
- Tie-set mismatch: `0`.
- Best-index mismatch: `0`.
- Accepted-update mismatch: `0`.
- Trajectory mismatch: `0`.
- Selected-start mismatch: `0`.
- Nested-pass mismatch: `0`.
- Final-selector mismatch: `0`.
- Helper K1 fixed-subfit reuse: `CERTIFIED_K1_FIXED_HELPER_REUSE` (`72/72`).
- K1/K2 full-data and initialization output identity: `CERTIFIED`.

## E. Query reuse

| Stage | Manifold builds | Requested columns | Unique keys | Reuse | Registered exact fraction |
|---|---:|---:|---:|---:|---:|
| `K1_INIT_CONVENTIONAL` | 1512 | 1512 | 21 | 72.000 | 1.000000 |
| `K1_INIT_GROUP_Q1_CURRENT_TCC_MODEL_INCOMPATIBLE` | 2232 | 2232 | 0 | 0.000 | 0.000000 |
| `K1_INIT_GROUP_Q2_CURRENT_TCC_MODEL_INCOMPATIBLE` | 1224 | 1224 | 0 | 0.000 | 0.000000 |
| `K1_FIXED_REGISTERED_REFINEMENT` | 1604 | 1604 | 21 | 76.381 | 1.000000 |
| `K1_FIXED_FINAL_CERTIFICATION` | 144 | 144 | 7 | 20.571 | 1.000000 |
| `PUBLIC_K1_FIXED_SUBFIT` | 0 | 0 | 0 | 0.000 | 0.000000 |
| `K1_CONTINUOUS` | 7913 | 7913 | 0 | 0.000 | 0.000000 |
| `K2_INIT_CONVENTIONAL` | 1512 | 1512 | 21 | 72.000 | 1.000000 |
| `K2_INIT_GROUP_Q1_CURRENT_TCC_MODEL_INCOMPATIBLE` | 2232 | 2232 | 0 | 0.000 | 0.000000 |
| `K2_INIT_GROUP_Q2_CURRENT_TCC_MODEL_INCOMPATIBLE` | 1224 | 1224 | 0 | 0.000 | 0.000000 |
| `K2_HELPER_K1` | 1748 | 1748 | 21 | 83.238 | 1.000000 |
| `K2_INTERNAL_HELPER_K1` | 0 | 0 | 0 | 0.000 | 0.000000 |
| `K2_NESTED_ANCHOR` | 1584 | 3096 | 21 | 147.429 | 1.000000 |
| `K2_REGISTERED_REFINEMENT` | 6104 | 12208 | 21 | 581.333 | 1.000000 |
| `K2_FINAL_CERTIFICATION` | 144 | 288 | 21 | 13.714 | 1.000000 |
| `K2_REGISTERED_FIT` | 0 | 0 | 0 | 0.000 | 0.000000 |
| `CENTER_MANIFOLD_DERIVATIVES` | 72 | 72 | 0 | 0.000 | 0.000000 |
| `T4_PROFILE` | 2952 | 5904 | 0 | 0.000 | 0.000000 |
| `FINAL_SAFE_SELECTOR` | 0 | 0 | 0 | 0.000 | 0.000000 |

## F. Runtime decomposition

All values below are medians of trial-level medians for the 72-trial overall distribution; raw repeats were not pooled into one homogeneous p90.

- K1 public share: `48.7381%` (median inclusive `2.474421 s`).
- K2 public share: `50.0188%` (median inclusive `2.533040 s`).
- Initialization inclusive share: `1.8732%` (sum of component medians `0.097888 s`).
- Fixed registered-refinement inclusive share: `2.2895%` (sum of component medians `0.117121 s`).
- Continuous K1 share: `1.3395%` (median inclusive `0.069528 s`).
- Center/derivative share: `0.0200%` (median inclusive `0.001042 s`).
- T4 share: `1.1030%` (median inclusive `0.056622 s`).
- Unattributed share: `0.0406%` (median inclusive `0.002106 s`).
- Paired instrumentation overhead median/p90/min/max: `0.00304657 / 0.0252823 / -0.044687 / 0.039652 s`.
- Level-A P1 `T4 ~= 0.54%`: current P1 median share is `1.0422%`, overall is `1.1030%`; representativeness is `BROADLY_REPRESENTATIVE`.

## G. Microbenchmark

| Identity | Primitive | Median us | P10 us | P90 us |
|---|---|---:|---:|---:|
| `208ac1cfafa1` | `LEGACY_FULL_SINGLE` | 359.900 | 342.300 | 577.200 |
| `208ac1cfafa1` | `LEGACY_FULL_PAIR` | 672.350 | 599.450 | 1083.950 |
| `208ac1cfafa1` | `DIRECT_G_ONLY_SINGLE` | 243.200 | 168.750 | 269.600 |
| `208ac1cfafa1` | `DIRECT_G_ONLY_PAIR` | 383.200 | 266.950 | 436.100 |
| `208ac1cfafa1` | `RANK_SINGLE` | 21.100 | 16.850 | 29.800 |
| `208ac1cfafa1` | `RANK_PAIR` | 21.250 | 18.550 | 26.150 |
| `208ac1cfafa1` | `IDENTITY_FULL_VALIDATE` | 15148.600 | 13488.800 | 17287.650 |
| `208ac1cfafa1` | `CURRENT_LEVEL_A_LOOKUP_SINGLE` | 13747.100 | 13289.200 | 14928.850 |
| `208ac1cfafa1` | `CURRENT_LEVEL_A_LOOKUP_PAIR` | 27550.700 | 26765.700 | 32180.150 |
| `208ac1cfafa1` | `RAW_INDEXED_21_KEY_LOOKUP_SINGLE` | 4.050 | 2.900 | 5.250 |
| `208ac1cfafa1` | `RAW_INDEXED_21_KEY_LOOKUP_PAIR` | 2.800 | 2.600 | 3.150 |
| `208ac1cfafa1` | `CERTIFIED_REGISTERED_LOOKUP_SINGLE` | 100.750 | 94.950 | 120.300 |
| `208ac1cfafa1` | `CERTIFIED_REGISTERED_LOOKUP_PAIR` | 95.300 | 92.200 | 115.200 |
| `208ac1cfafa1` | `21_KEY_BUILD` | 328796.000 | 323619.750 | 336338.200 |
| `208ac1cfafa1` | `PROVIDER_SETUP` | 13554.000 | 13096.850 | 14374.300 |
| `208ac1cfafa1` | `DIAGNOSTIC_21_KEY_ARTIFACT_LOAD` | 2970.300 | 2593.700 | 3464.900 |
| `e965700fc8d3` | `LEGACY_FULL_SINGLE` | 380.350 | 332.000 | 565.250 |
| `e965700fc8d3` | `LEGACY_FULL_PAIR` | 656.100 | 589.200 | 879.250 |
| `e965700fc8d3` | `DIRECT_G_ONLY_SINGLE` | 129.150 | 126.450 | 213.300 |
| `e965700fc8d3` | `DIRECT_G_ONLY_PAIR` | 251.500 | 240.100 | 318.400 |
| `e965700fc8d3` | `RANK_SINGLE` | 14.000 | 11.650 | 23.650 |
| `e965700fc8d3` | `RANK_PAIR` | 10.900 | 10.150 | 12.100 |
| `e965700fc8d3` | `IDENTITY_FULL_VALIDATE` | 13598.250 | 13037.300 | 14616.650 |
| `e965700fc8d3` | `CURRENT_LEVEL_A_LOOKUP_SINGLE` | 13588.450 | 13131.050 | 14875.750 |
| `e965700fc8d3` | `CURRENT_LEVEL_A_LOOKUP_PAIR` | 27243.700 | 26423.550 | 28705.100 |
| `e965700fc8d3` | `RAW_INDEXED_21_KEY_LOOKUP_SINGLE` | 2.900 | 2.700 | 3.200 |
| `e965700fc8d3` | `RAW_INDEXED_21_KEY_LOOKUP_PAIR` | 3.000 | 2.550 | 4.600 |
| `e965700fc8d3` | `CERTIFIED_REGISTERED_LOOKUP_SINGLE` | 59.900 | 57.450 | 75.900 |
| `e965700fc8d3` | `CERTIFIED_REGISTERED_LOOKUP_PAIR` | 60.650 | 58.350 | 104.500 |
| `e965700fc8d3` | `21_KEY_BUILD` | 327429.400 | 322509.700 | 336388.200 |
| `e965700fc8d3` | `PROVIDER_SETUP` | 13393.150 | 12998.800 | 14440.500 |
| `e965700fc8d3` | `DIAGNOSTIC_21_KEY_ARTIFACT_LOAD` | 2980.900 | 2523.850 | 3476.600 |

Diagnostic MAT load was measured as `DIAGNOSTIC_21_KEY_ARTIFACT_LOAD`; it is not a production load format.

## H. Counterfactual

All values are `COUNTERFACTUAL_ESTIMATE_NOT_INTEGRATED_RUNTIME`.

- Measured T0: `364.872219 s` (sum over 72 trial medians).
- Predicted TS: `356.630711 s`.
- Predicted TSG: `351.210592 s`.
- Predicted TSGC: `349.018408 s`.
- Delta structural: `8.241508 s`.
- Delta G-only | structural: `5.420119 s`.
- Delta cache | structural,G-only: `2.192184 s`.

## I. Lifecycle

- `208ac1cfafa1`: build-inclusive break-even `10`, online-only break-even `1`, 36-trial conditional saving `1319.031 ms`, end-to-end modeled saving `4.0081%`, build-inclusive net `958.562 ms`, online-only net `1287.358 ms`.
- `e965700fc8d3`: build-inclusive break-even `15`, online-only break-even `2`, 36-trial conditional saving `873.153 ms`, end-to-end modeled saving `4.6807%`, build-inclusive net `515.751 ms`, online-only net `843.181 ms`.
- Deployment: `NOT_ASSESSED_NO_WORKLOAD_HORIZON`; no economic PASS/FAIL or deployment justification is claimed.

## J. Attribution

- Predicted Core-Lite direct/dictionary: `172.373527 / 170.525682 s`.
- Predicted Tangent-safe direct/dictionary: `351.210592 / 349.018408 s`.
- Predicted Delta Core: `1.847845 s`.
- Predicted Delta Tangent: `2.192184 s`.
- `PREDICTED_DIFFERENCE_IN_DIFFERENCES_INTERACTION` I: `0.344339 s`; this is not causal synergy.
- Predicted Tangent exposure sum: `2.192184 s`.
- `exposure_adjusted_residual_JT = NaN`.
- `JT_status = NOT_AVAILABLE_PRE_INTEGRATION`.
- Q8b measured Tangent-specific residual: `DEFERRED_TO_INTEGRATION`.

## K. Decision

- Technical certification: `TECHNICALLY_CERTIFIED`.
- Cache conditional point estimate: `2.192184 s` (`2192.184 ms`).
- Conservative timing/sensitivity lower bound: `-5.638252 s`.
- Minimum per-identity cache conditional delta: `0.873153 s`.
- Certified lookup faster than direct G-only: `1`.
- Predicted performance status: `PREDICTED_SAVING_INCONCLUSIVE`.
- Recommended placement: `CACHE_PLACEMENT_K2_REGISTERED_REFINEMENT_PREDICTED`.
- Recommended next action: `DO_NOT_INTEGRATE_FIXED_PATH_DICTIONARY_FROM_THIS_AUDIT`.

## Q1-Q8b direct answers

1. Q1: the runtime shares are reported in Section F; K1/K2 public fits and their initialization/refinement dominate according to the measured stage table.
2. Q2: full-data, initialization, and helper-K1 repeated costs are the structural delta `8.241508 s` over 72 trial medians.
3. Q3: fixed registered builds, requested columns, and DML scores are enumerated by stage in the query CSV and Section E.
4. Q4: 21-key reuse multiplicity is reported per stage and is `262.381` overall for eligible registered columns.
5. Q5: point estimate sign `POSITIVE`; conservative lower-bound sign `NEGATIVE`.
6. Q6: per-identity lifecycle and break-even are in Section I.
7. Q7: `PREDICTED_SAVING_INCONCLUSIVE`, classified by the frozen priority rules.
8. Q8a: per-stage and single/pair exposure rows are retained outside Git and aggregated in the economics evidence. Q8b: `DEFERRED_TO_INTEGRATION`; `JT_status = NOT_AVAILABLE_PRE_INTEGRATION`.

## Explicitly not executed

- `NO_NEW_BRANCH`
- `NO_LEVEL_B_INTERPOLATION`
- `NO_NEAREST_NEIGHBOR`
- `NO_FIXED_PATH_DICTIONARY_INTEGRATION`
- `NO_CONTEXT_REUSE_INTEGRATION`
- `NO_G_ONLY_PRODUCTION_REPLACEMENT`
- `NO_TANGENT_RECALIBRATION`
- `NO_CLASSICAL_BASELINE_RERUN`
- `NO_NEW_MONTE_CARLO_PROTOCOL`
- `NO_FPGA_CACHE_MAPPING`
- `NO_PARENT_BRANCH_MERGE`
- `NO_PR_CREATED`
- `NO_FORCE_PUSH`

Completion means audit complete, not dictionary integrated, measured speedup validated, or deployment justified.
