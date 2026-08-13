# Stage8 Core-V2 Known-K Center-Difference Experiment

This directory contains the external known-K experiment authorized by
`STAGE8_CORE_V2_KNOWN_K_CENTER_DIFFERENCE_PRUNING_V2`. It does not modify the
frozen Stage8 implementation, calibration, formal results, or prior R1 tools.

The MATLAB entry point is `matlab/stage8_core_v2_context.m`. It adds the
read-only R1 bridge and the frozen Stage8 runtime scope. The K2 optimizer uses
the fixed center/difference contract in `stage8_core_v2_constants.m`; only
`fminbnd` is used for one-dimensional refinement.

Run the PowerShell controller in this order after the tool commit:

```powershell
.\tools\stage8_core_v2_known_k\powershell\Stage8CoreV2.ps1 -Action Init
.\tools\stage8_core_v2_known_k\powershell\Stage8CoreV2.ps1 -Action Gates
.\tools\stage8_core_v2_known_k\powershell\Stage8CoreV2.ps1 -Action Start
.\tools\stage8_core_v2_known_k\powershell\Stage8CoreV2.ps1 -Action Status
.\tools\stage8_core_v2_known_k\powershell\Stage8CoreV2.ps1 -Action Finalize
```

`Gates` runs the F1/F2 fixtures with real one-worker and two-worker MATLAB
processes. It records G0, G1, G2 and selects the formal worker count. Formal
execution writes only external MAT checkpoints until `Finalize`.

The four MATLAB tests under `tests/` cover center/difference transformation,
solver determinism, monotonicity and one/two-worker scientific equivalence.

All outputs are known-K diagnostics. Model-order inference, formal threshold
calibration, bootstrap, the 6000-trial validation and Stage8.2 remain
deferred.
