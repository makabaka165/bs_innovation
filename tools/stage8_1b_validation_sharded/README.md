# Stage8.1B resumable sharded K1 validation

This directory implements the external execution protocol
`STAGE8_1B_K1_VALIDATION_SHARDED_RESUMABLE_V2`.

The tools do not modify the frozen Stage8 scientific implementation. Each
common trial remains one atomic pair containing PRIMARY and FULL_PARENT rows.
Formal workers use MATLAB R2022b with `-singleCompThread`, fixed `Bsep=199`, no
parallel pool, no `parfor`, and no fit, seed, threshold, or solver override.

## Lifecycle

Run the control script from PowerShell:

```powershell
$runner = 'E:\bs_innovation\tools\stage8_1b_validation_sharded\powershell\Stage8K1Sharded.ps1'
$runtime = 'E:\bs_innovation_runtime\stage8_1b_k1_validation_sharded_resumable_v2_9bfa65e6'

& $runner -Action Pilot -RuntimeRoot $runtime
& $runner -Action Init -RuntimeRoot $runtime
& $runner -Action Start -RuntimeRoot $runtime
```

`Pilot` runs Gate 0, Gate 1, Gate 2A, Gate 2B, and the resource decision tree.
Gate 1 or Gate 2A failure hard-stops. Only a Gate 2B or resource failure can
select one resumable worker instead of two odd/even workers.

The only scheduled task is `BSInnovation-Stage8K1-Status`. It invokes the
PowerShell-only `Status` action every 15 minutes and never starts, resumes,
pauses, stops, or finalizes computation.

## Manual controls

```powershell
& $runner -Action Status -RuntimeRoot $runtime
& $runner -Action Pause -RuntimeRoot $runtime
& $runner -Action Resume -RuntimeRoot $runtime
& $runner -Action ForceStop -RuntimeRoot $runtime
& $runner -Action Finalize -RuntimeRoot $runtime
```

Normal shutdown requires `PAUSED_SAFE_TO_SHUTDOWN` and
`safe_to_shutdown=true` in `status/latest_status.txt`. `ForceStop` is only for
an immediate shutdown and targets protocol-registered worker PIDs whose command
line matches the runtime root.

`Finalize` is blocked until all 6000 immutable checkpoints validate, workers
are stopped, and no temporary write exists. It invokes the existing validator
and finalizer and never executes Stage8.2.
