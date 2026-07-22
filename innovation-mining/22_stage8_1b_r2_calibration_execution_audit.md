# Stage8.1B-R2 Calibration Execution Audit (Audit 22)

> Date: 2026-07-22
> Repository: `makabaka165/bs_innovation`
> Frozen baseline: `5b2f4c19f9d2b35ef616aa406ac971606056a4fa`
> Runtime: MATLAB R2022b, `phase_factor=1`
> Scope: formal calibration execution and completeness audit only

## A. Conclusion

`PARTIAL_STAGE8_1_CALIBRATION_OR_VALIDATION` remains the only valid overall
Stage8.1 conclusion. Formal calibration completed all 300 cells and passed the
full R2 completeness gate, but threshold collection, aggregation, and evidence
freeze have not started. K1 validation and Stage8.2 have not run.

The terminal calibration state is `COMPLETE_PASS_300_CELL_CALIBRATION`. There
are 296 normal-exit cells, four verified cleanup/environment-anomaly cells,
zero scientific failures, and zero unresolved runtime failures.

## B. Frozen Runtime Contract

| Field | Frozen value |
|---|---|
| `execution_protocol` | `STAGE8_1B_CELL_ISOLATED_CONCURRENCY2_V1` |
| `maximum_concurrent_workers` | `2` |
| `threads_per_worker` | `1` |
| `statistical_plan_changed_flag` | `false` |
| `seed_changed_flag` | `false` |
| `checkpoint_format_changed_flag` | `false` |
| `source_code_changed_flag` | `false` |
| source tree | `878d2fce3125edb65975ecc8fc75d9d07439bfd3f81a54ec5ba78af5265d41ea` |
| stable code identity | `fa28f6f202c37dc800b801c47eb4e0f9381a3fc46d1fdc230e145e49d3a215bf` |
| Stage8 plan | `7dc1e4c361d22ec52ec255381e3cea3ce176a8877b4cfe56f12d25564749ca5d` |
| calibration plan | `5cf12356433c9680cc3f1ca783667de1910b8135e76141d0fc72271fbe596760` |
| validation plan | `9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7` |
| mean-identity contract | `8da2779c03ee3853b0cc2f75e886e749edb967b304c183cb0fb4dfa2a9444e74` |

The repository remained clean at the frozen baseline throughout calibration.
The external checkpoint format, frozen schedule membership, and all cell and
bootstrap seeds were unchanged.

## C. Protocol Switch And Pilot

The protocol switch was recorded at `2026-07-21T04:26:52.8615422Z` with 65
accepted cells and no active process. A formerly suspended Cell 66 attempt had
disappeared without a checkpoint or cell output, so the no-active-cell switch
branch authorized Cell 66 attempt 2 with the same frozen identity and seeds.

The remaining schedule contained 235 cells and was frozen at SHA-256
`b47f09c23432ffd8c7cf2aff4cd20aace8c1981dd5e9fec4f14b7c969acecb62`.
The eight-cell pilot covered Cells 66-73 and produced eight normal PASS cells,
zero cleanup anomalies, zero scientific failures, and zero runtime failures.
The single pilot retry is the recorded pre-switch external restart of Cell 66;
there was no post-switch retry.

| Pilot metric | Value |
|---|---:|
| pilot wall-clock | `1740.0534865 s` |
| serial-reference median | `275.9174282 s/cell` |
| pilot process median | `266.0845204 s/cell` |
| projected-reference speedup | `1.2685468824524x` |
| observed-workload speedup | `1.32014223081182x` |
| peak combined MATLAB private memory | `4077293568 bytes` (`3.797276 GiB`) |
| peak process private memory | `1937031168 bytes` (`1.804001 GiB`) |
| peak total memory utilization | `72.396676944981%` |
| minimum available physical memory | `4523270144 bytes` (`4.212624 GiB`) |
| sustained page-file thrashing | `false` |

Because both speedup estimates were below the required `1.35x` gate, the run
downgraded to one worker at `2026-07-21T05:03:19.8923701Z`. Cells 66-73 were
preserved and never rerun; Cell 74 was the first post-pilot serial cell.

## D. Execution Accounting And Recovery

Eight cells used the two-worker pilot. The other 292 cells used one worker:
65 before the switch and 227 from Cell 74 through Cell 300. The final retry
count is three, affecting Cells 9, 19, and 66. The four verified environment
anomalies are Cells 5, 9, 12, and 19; every one terminates in a complete PASS
checkpoint and accepted final registry row.

An operator-requested pause completed Cell 195 before stopping. The restart
audited the contiguous `1..195` prefix and resumed at Cell 196 without reruns.
After Cell 196 passed, the repository-external coordinator stopped before
starting Cell 197 because a memory-gate WAIT message entered the PowerShell
success stream. Cell 197 had no MATLAB process, checkpoint, output, summary, or
registry row. Its prelaunch lock was archived for forensics, the external
scheduler routed WAIT text to the host stream, and execution resumed at Cell
197. No repository source, statistical plan, seed, checkpoint, or frozen
schedule changed.

## E. 300-Cell Completeness Gate

| Gate | Result |
|---|---:|
| checkpoints present | `300/300` |
| checkpoint SHA-256 matches registry | `300/300` |
| unique global cell IDs | `300/300` |
| temporary checkpoints | `0` |
| finite Lambda samples | `59700/59700` |
| unique bootstrap seeds | `59700/59700` |
| finite `q_cell` | `300/300` |
| exact `q_cell` recomputations | `300/300` |
| artifact-hash checks | `300/300` |
| cell-identity checks | `300/300` |
| A5 mean-identity checks | `300/300` |
| unresolved scientific failures | `0` |
| unresolved runtime failures | `0` |
| active locks / coordinators / MATLAB processes | `0 / 0 / 0` |

Registry decimal copies were compared with a `1e-12` serialization tolerance;
the maximum relative `q_cell` serialization error was
`4.8754176562053513e-15`. The checkpoint values themselves passed exact
recomputation against their 199 Lambda samples.

## F. Aggregate Execution Metrics

| Metric | Value |
|---|---:|
| normal exit count | `296` |
| verified cleanup/environment-anomaly count | `4` |
| retry count | `3` |
| concurrency-2 pilot cell count | `8` |
| concurrency-1 cell count | `292` |
| elapsed wall-clock, including pauses | `150620.302 s` (`41.838973 h`) |
| summed cell process runtime | `80052.96 s` (`22.236933 h`) |
| maximum G backward-bound ratio | `0` |
| maximum mean backward-bound ratio | `0.000304306434733709` |
| maximum legacy relative mean error | `3.40877105780953e-09` |
| minimum fitted mean norm | `10.0349089161065` |

The elapsed wall-clock starts at the first registered calibration process and
ends at the 300-cell terminal record; it intentionally includes operator
pauses. It must not be interpreted as summed compute time.

## G. Evidence Provenance

The machine-readable execution summary is in
`22_stage8_1b_r2_calibration_execution_summary.csv`. The external runtime files
remain under `E:\bs_innovation_runtime\stage8_1b_a5r2_cellwise_7dc1e4c3` and
are bound by `22_stage8_1b_r2_runtime_evidence_manifest.csv`. Raw checkpoints,
per-cell outputs, logs, process files, and locks are deliberately not copied
into Git.

## H. Boundary And Next Gate

The terminal record has
`threshold_aggregation_started_flag=0` and `stage8_2_started_flag=0`. This
audit does not claim that concurrency changed bootstrap independence or the
effective sample count. It also does not claim `PASS_STAGE8_1_K1_CONTROL`.

The next separately authorized operation is serial threshold collection,
aggregation, and evidence freeze with one MATLAB process. Only that operation
may create the first formal evidence commit,
`docs(stage8.1): freeze k1 bootstrap thresholds`. Validation must then start
from that clean tracked threshold commit and stop before Stage8.2.
