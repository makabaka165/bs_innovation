# Stage8 R1 Continuous Refinement Decisive Experiment

DIAGNOSTIC_DECISIVE_EXPERIMENT_ONLY

NO_FORMAL_THRESHOLD

NO_STAGE8_1_VALIDATION_PASS

NO_STAGE8_2_AUTHORIZATION

Branch: experiment/stage8-r1-continuous-refinement-decisive-v1

HEAD: 72a18821af4c4fe9818c7e9bacf32d96763aa232

Audit anchor: f6ec19fc28e8c317a5f92416658be06a72ee19a1

Protocol source hash: 1bec34dcd6954d259bdd011a828eb1f33816a73f512474c276f6477aea2e7a60

## Gates

R0: PASS, R0_BOUNDARY_IDENTITY_PASS

R1: PASS, R1_OPTIMIZER_DETERMINISM_PASS

R2: PASS, R2_CHECKPOINT_RESUME_PASS

R3: PASS, R3_ONE_TWO_WORKER_EQUIVALENCE_PASS

Selected execution mode: TWO_WORKER_RESUMABLE (2 workers)

## Completeness

Element trials: 24/24

K1 trials: 16/16

K2 trials: 8/8

Method rows: 72/72

Scientific checkpoint hashes: 24 valid

## Method Diagnostics

All Lambda values below are diagnostic-only. No calibration threshold was
created, modified, or used as a model-order decision.

| Method | K1 valid pairs | K2 valid pairs | On-grid median Lambda | Off-grid median Lambda | AUC | Best K2 TPR at K1 FPR<=0.125 | Off-grid closure median | K2 median RMSE (deg) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| M0 fixed grid | 16/16 | 8/8 | 13.093499 | 79.987533 | 0.851562 | 0.750000 | 0.000000 | 0.148962 |
| M1 conventional continuous | 3/16 | 0/8 | 20.128158 | 13.338841 | NaN | NaN | 0.896590 (2 eligible) | NaN |
| M2 grouped continuous | 2/16 | 0/8 | 10.346369 | NaN | NaN | NaN | NaN (0 eligible) | NaN |

M0 diagnostic operating threshold at its selected FPR point: 102.571152.
It is not a formal threshold artifact.

Mean score calls / mean SVD calls / median runtime seconds:

| Method | Score calls | SVD calls | Runtime seconds |
|---|---:|---:|---:|
| M0 fixed grid | 173.291667 | 399.375000 | 0.148975 |
| M1 conventional continuous | 1719.625000 | 3478.416667 | 1.379838 |
| M2 grouped continuous | 1533.083333 | 3085.500000 | 1.227633 |

## M2 Versus M1

K2 RMSE comparison: 0 M2 wins, 0 ties, 0 losses, and 8 invalid comparisons
because neither continuous method produced a valid K2 LRT fit in those trials.

## Decision

Final conclusion:
STAGE8_R1_CONTINUOUS_MODEL_ORDER_NOT_RECOVERED

The model-order recovery condition requires 16/16 valid K1 fit pairs and at
least 7/8 valid K2 fit pairs for M1 or M2. Neither method met those validity
requirements under the fixed eight-sweep continuous solver contract.

Formal 6000-trial status:
FULL_STAGE8_1B_K1_VALIDATION_DEFERRED_NOT_FAILED

Stage8.2 executed: false
