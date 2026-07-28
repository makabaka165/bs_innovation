# Stage8 Compact K1/K2 Diagnostic Runner

This tool implements `STAGE8_COMPACT_K1_K2_DIAGNOSTIC_4WORKER_V2`.
It is diagnostic-only. It does not run the formal 6000-trial Stage8.1B
validation, does not recalibrate thresholds, and does not authorize or execute
Stage8.2.

The runner evaluates 60 paired K1 element trials and 48 K2 element trials.
Every element trial is an immutable atomic checkpoint. K2 profiles 1 and 8
also evaluate the `FULL_PARENT` sensitivity configuration. The full checkpoint
set contains 108 element trials and 180 rows.

## Control Surface

```powershell
$runner = 'E:\bs_innovation\tools\stage8_compact_diagnostic\powershell\Stage8CompactDiagnostic.ps1'
$runtime = 'E:\bs_innovation_runtime\stage8_compact_k1_k2_diagnostic_4worker_v2_237e351'

& $runner -Action Pilot    -RuntimeRoot $runtime
& $runner -Action Init     -RuntimeRoot $runtime
& $runner -Action Start    -RuntimeRoot $runtime
& $runner -Action Status   -RuntimeRoot $runtime
& $runner -Action Pause    -RuntimeRoot $runtime
& $runner -Action Resume   -RuntimeRoot $runtime
& $runner -Action Finalize -RuntimeRoot $runtime
```

`Pilot` runs C0-C4. C4 chooses one to four independent MATLAB R2022b
`-singleCompThread` workers from available physical memory and measured
scientific/resource equivalence. `Init` requires the passing Pilot decision and
registers only `BSInnovation-Stage8Compact-Status`. The scheduled task is
read-only with respect to workers and checkpoints.

`Pause` creates `control\pause.request`. Workers finish their current complete
element trial, atomically validate its checkpoint, and exit. A safe shutdown
requires `PAUSED_SAFE_TO_SHUTDOWN`, zero active workers, zero temporary
checkpoints, and zero current-trial locks. `Resume` validates the immutable
protocol and all existing checkpoints before starting only missing trials.

`Finalize` requires 108 valid checkpoints, 180 rows, zero workers, zero
temporary files, and zero locks. It writes only:

- `innovation-mining/23_stage8_compact_algorithm_diagnostic.md`
- `innovation-mining/23_stage8_compact_algorithm_diagnostic_trials.csv`
- `innovation-mining/23_stage8_compact_algorithm_diagnostic_summary.csv`
- `innovation-mining/23_stage8_compact_algorithm_diagnostic_profiles.csv`

The frozen Stage8 step, its 13 calibration CSVs, and its formal `results/`
directory remain read-only.
