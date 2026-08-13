# Step12.7 Known-K Local-Cell Refinement

Protocol: `STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_V1`

This directory is the only production-facing Stage8/Core-V2.2 code. It
estimates one or two externally supplied angular components from one
element-domain observation matrix for one selected range-Doppler cell in one
CPI. It does not estimate model order, accept tracking data, use another CPI,
or consume truth values during fitting.

The sole public interface is:

```matlab
result = estimate_stage8_known_k_local_cell( ...
    Y_element, model, local_domain, stage5_locked, noise_model, K, opts)
```

`K` is exactly `1` or `2`. `CORE_LITE` uses fixed-grid known-K K2 and the
conventional-singleton safe K1 refinement. `CORE_PLUS` uses the same K1 path;
for K2 only, it adds the previously validated grouped starts and the frozen
center-difference refinement before the same likelihood-safe selection.

The implementation mechanically lifts the following committed source logic:

- R1 continuous K1 refinement: `d28e6774c1341a93a8c16ef8b6cb66d5d19de56f`
- Core-V2 K2 center-difference and safe selection:
  `ca4f6ae7ad07f887fe0a820c8bab09d31c7e6d3c`
- Frozen fixed-grid backend:
  `bbe5f031698478ea4e8a57f0c6c9a741f5d6d637`

The final runner is:

```matlab
run_step12_7_known_k_local_cell_refinement('Start')
run_step12_7_known_k_local_cell_refinement('Status')
run_step12_7_known_k_local_cell_refinement('Pause')
run_step12_7_known_k_local_cell_refinement('Resume')
run_step12_7_known_k_local_cell_refinement('Finalize')
```

It uses one MATLAB R2022b process with `-singleCompThread`, writes only
external runtime checkpoints until finalization, requires F0 and F1 before
the independent 144-trial registry, and never overwrites final evidence.

Excluded permanently: automatic K, LRT, bootstrap thresholds, q-based online
branching, resolved/unresolved labels, a third K2 solver, K=3, Stage8.1 formal
validation, and Stage8.2.
