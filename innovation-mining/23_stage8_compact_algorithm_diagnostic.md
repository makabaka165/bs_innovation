# Stage8 Compact K1/K2 Algorithm Diagnostic

**DIAGNOSTIC_ONLY**  
**NOT_FORMAL_STAGE8_1_K1_VALIDATION**  
**DOES_NOT_AUTHORIZE_STAGE8_2**  
**FULL_6000_TRIAL_VALIDATION_DEFERRED_NOT_FAILED**

- Protocol: `STAGE8_COMPACT_K1_K2_DIAGNOSTIC_4WORKER_V2`
- Runner commit: `b5d434720ba9c6e249f0a2197ff886dd133ffd88`
- Execution mode: `N_WORKER_RESUMABLE` (2 workers)
- Element trials / rows: 108 / 180
- Scientific checkpoint hashes: 108 valid

## Diagnostic Conclusion

`STAGE8_COMPACT_DIAGNOSTIC_CLEAR_FAILURE`

These thresholds are screening heuristics, not a formal Wilson gate.

| Metric | Value |
|---|---:|
| PRIMARY K1 false-split point rate | 0.500000 |
| PRIMARY K1 nondecision point rate | 0.000000 |
| PRIMARY K2 valid-fit fraction | 1.000000 |
| PRIMARY K2 LRT split-detection rate | 0.562500 |
| PRIMARY K2 joint-refinement improvement fraction | 0.791667 |
| PRIMARY K2 median joint 2D RMSE (deg) | 0.191107 |
| PRIMARY K2 median separation-vector error (deg) | 0.267754 |
| PRIMARY sentinel LRT detection | 0.500000 |
| FULL_PARENT sentinel LRT detection | 0.583333 |

All six strata contain a valid K2 fit: `true`.

The summary CSV contains 34 diagnostic metric rows; the profile CSV contains 60 configuration/profile rows.

Stage8.2 executed: `false`.
