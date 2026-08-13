# Stage8 Core-V2.1 Safe Known-K Hybrid Closure

KNOWN_K_SAFE_HYBRID_DIAGNOSTIC_ONLY

MODEL_ORDER_DEFERRED

NO_FORMAL_THRESHOLD

NO_STAGE8_1_VALIDATION_PASS

NO_STAGE8_2_AUTHORIZATION

Branch: experiment/stage8-core-v2

Starting/runner HEAD: 1581550b675b12e7c7c1bfd0541b4fbc52f39923 / ca4f6ae7ad07f887fe0a820c8bab09d31c7e6d3c

H0: PASS, H0_BOUNDARY_PASS

H1: PASS, H1_SELECTION_CORRECTNESS_PASS

Source fits reused: 24 trials and 72 B0/B1/B2 rows. No fit rerun.

| Hybrid | K1 valid | K2 valid | K1 off-grid RMSE | K2 RMSE | K2 easy | K2 moderate | upgrades | fallbacks | operational |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| H1_DIRECT_SAFE_HYBRID_KNOWN_K | 16 | 8 | 0.0113885676 | 0.141681308 | 0.141681308 | 0.156242749 | 18 | 6 | 1 |
| H2_GROUPED_SAFE_HYBRID_KNOWN_K | 16 | 8 | 0.0113885676 | 0.140071055 | 0.0936479172 | 0.156242749 | 20 | 4 | 1 |

## Candidate Cost Audit

All values are means over the 24 registered element trials. The conservative upper bound is labeled `DOUBLE_COUNTS_SHARED_INITIALIZATION` and does not trigger RETAIN or PRUNE.

| Hybrid | B0 score/SVD/runtime | Continuous score/SVD/runtime | Conservative score/SVD/runtime |
|---|---:|---:|---:|
| H1_DIRECT_SAFE_HYBRID_KNOWN_K | 120.875 / 275.125 / 0.142283 | 794.042 / 1613.83 / 0.678169 | 914.917 / 1888.96 / 0.820453 |
| H2_GROUPED_SAFE_HYBRID_KNOWN_K | 120.875 / 275.125 / 0.142283 | 1142 / 2302.83 / 0.930513 | 1262.88 / 2577.96 / 1.0728 |

H2 vs H1: wins=4, ties=4, losses=0.

Final conclusion: STAGE8_CORE_V2_1_OPERATIONAL_GROUPED_OPTIONAL

Model-order = DEFERRED
Formal 6000-trial = DEFERRED_NOT_FAILED
Stage8.2 = NOT_EXECUTED
