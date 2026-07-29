# Stage8 Core-V2 Known-K Center-Difference Pruning Experiment

KNOWN_K_DIAGNOSTIC_ONLY

MODEL_ORDER_DEFERRED

NO_FORMAL_THRESHOLD

NO_STAGE8_1_VALIDATION_PASS

NO_STAGE8_2_AUTHORIZATION

Branch: experiment/stage8-core-v2

Starting/runner HEAD: b6068407a0dc40b94471119d593acaeee8707ddb / 7271fd5e60a73c0bf20d24f38d15d2c24c76fd25

Selected workers: TWO_WORKER_RESUMABLE (2)

G0: PASS, G0_BOUNDARY_IDENTITY_PASS

G1: PASS, G1_SOLVER_SCIENTIFIC_USABILITY_PASS

G2: PASS, G2_TWO_WORKER_EQUIVALENCE_PASS

Trials: K1 16/16; K2 8/8; method rows 72/72.

| Method | K1 valid | K2 valid | K1 off-grid median RMSE | K2 median RMSE | score calls | SVD calls | runtime | operational |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| B0_FIXED_GRID_KNOWN_K | 16 | 8 | 0.141421356 | 0.148962029 | 120.875 | 275.125 | 0.13803615 | 0 |
| B1_DIRECT_CONTINUOUS_KNOWN_K | 16 | 2 | 0.0113885676 | 0.149437254 | 794.041667 | 1613.83333 | 0.19060095 | 0 |
| B2_GROUPED_CONTINUOUS_KNOWN_K | 16 | 4 | 0.0113885676 | 0.0936479172 | 1142 | 2302.83333 | 0.18338445 | 0 |

B2 vs B1: wins=3, ties=1, losses=1.

Scientific checkpoint hashes: 24 valid.

Final conclusion: STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP

Model-order status = DEFERRED
Formal 6000-trial status = DEFERRED_NOT_FAILED
Stage8.2 executed = false
