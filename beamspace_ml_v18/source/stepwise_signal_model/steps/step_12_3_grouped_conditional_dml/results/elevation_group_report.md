---
phase_factor: 1
validation_status: PASS
scope: Step12.3_subphases_A_to_C_only
---

# Step12.3A-C Elevation-Group DML Report

## A. Phase conclusion

**PASS.** Oracle-known Q=1/Q=2 elevation-group DML, structural identifiability diagnosis, and group-data recovery passed the registered phase-4 gates. This does not validate any later-stage estimator.

## B. Read basis and prior-art boundary

Read the phase-4 prompt in document 13, Step12.3 in document 12, theory Sections 5.1-5.5 in document 11, formula prior-art F01/F02, algorithm prior-art A01/A02, and the Step12.1/12.2 README/results/source.

F01/F02 and A01/A02 classify the cylindrical receive manifold, concentrated DML, nuisance-coefficient absorption, and staged estimation as existing or similar mechanisms. The evidence here supports only their factor-1 sequential-DBF interface combination; no atomic novelty is claimed.

## C. Files

Added five public common modules, three private numerical helpers, three interface/scenario/scope tests plus private fixtures, this README and runner, and the five required result files. The v0.19 manuscript, revision-scope note, and active-route README were updated only with passed phase-4 facts. No frozen Step11 file or later Step12 directory was modified or created.

## D. Formula-to-code mapping

| formula/contract | implementation | test evidence |
| --- | --- | --- |
| `Zemmv=[Zel(:,:,1),...,Zel(:,:,L)]` | `stack_elevation_mmv_data` | mapping/order interface gates |
| `Ge=T*V'*Az(eta)` and per-radian derivative | `build_elevation_group_manifold` | fixed projection and finite difference |
| `rank(Ge)=rank(Ce)=Q` plus local uniqueness | `diagnose_elevation_group_identifiability` | 9 identifiable plus 1 structural counterexample |
| `J=norm(Ur'*Z,'fro')^2`, `RSS=norm(Z)^2-J` | `estimate_elevation_groups_dml` using Step12.2 SVD score | Q1 1-D and Q2 local full reference |
| `Ce_hat=Ge_hat^dagger*Z` through effective SVD | `recover_group_azimuth_data` | Frobenius, vector-subspace chordal, and mixing crosstalk |

## E. Data and convention ledger

- Active spatial phase factor: `1` (receive-only).
- Elevation beams: `4 6 8 10 12 14 16 18 20` deg; physical B=9.
- `Zel`: `[B_e,Nphi,L]`; `Zemmv`: `[B_e,Nphi*L]`; `Ce`: `[Q,Nphi*L]`.
- Stacked order is azimuth column fastest and time snapshot next. At L=1, circumferential columns are MMV coefficient observations, not independent temporal snapshots.
- External angles are degrees; the manifold derivative is per radian. The beam matrix, covariance, whitener, and retained coordinates are fixed across every candidate.
- Group-data chordal error compares the one-dimensional subspaces spanned by vectorized recovered and truth group matrices; it does not estimate a noisy signal-subspace order.

## F. Executed tests and commands

Unified MATLAB command: `run('.../step_12_3_grouped_conditional_dml/run_step12_3_elevation_group_validation.m')`.

- Public-interface gates: 4/4.
- Trial rows: 23/23 passed.
- Identifiability rows: 10/10 passed.
- Recovery rows: 16/16 passed.
- Scope-source rules: 8/8 passed.
- Code Analyzer: 15 files, 0 messages in 0 files.

## G. Results and key values

- Maximum identifiable noiseless truth residual: `1.036750e-14`.
- Structural counterexample: `Nphi=8>Q=2`, `rank(Ge)=2`, `rank(Ce)=1`, status `GROUP_UNIDENTIFIABLE`, high-confidence output 0.
- Extremely close 10.00/10.05 deg case: sigma ratio Ge `1.412556e-02`, maximum angle error `1.776357e-15` deg.
- Correlated-noise maximum angle error: `0.000000e+00` deg.
- Vertical element-domain DML passed all 10 rows; maximum identifiable-case angle error was `1.776357e-15` deg.
- The Q1 elevation-beam peak baseline passed all 3 execution rows; its maximum angle error was `3.000000e-01` deg.
- The Q1/Q2 grouped SVD-DML search is the exhaustive registered local full elevation-DML reference; no duplicate reference call is reported.
- Common-elevation Q1/K2 within-group sum error: `3.891164e-15`.
- Maximum accepted recovery Frobenius/chordal errors: `1.041807e-03` / `1.037638e-03`.
- These are deterministic registered validation cases. No Monte Carlo confidence interval is reported; later resampling/calibration is outside this phase.

## H. Complexity

- Registered DML score calls: 1228; registered SVD calls: 3877.
- Multi-start runs: 0. Validation runtime: 2.607618 s.
- Q1 evaluates `Ne` candidates; Q2 evaluates `Ne*(Ne-1)/2` unordered candidates. Each score uses `O(B*Q^2+rank(Ge)*B*Nphi*L)`.
- Maximum primary input storage: 37440 bytes (complex double).
- Maximum stored candidate-manifold storage: 30240 bytes (complex double).
- Peak MATLAB process memory was not profiled.

## I. Failures, risks, and stop conditions

- AP-DML and PR-DML were not run because this repository contains no audited exact reproduction for the required model; no simplified substitute was invented.
- The finite registered candidate-bank alias check is not a continuous global uniqueness proof. Q is oracle-known, so these results do not support automatic grouping or statistical confidence.
- The structural coefficient counterexample is explicitly an MMV model counterexample, not presented as a complete physical target scene.
- Extremely close, weak, coherent, reduced-aperture, and correlated-noise outcomes remain visible in the CSVs; no failure-repair rule was added.
- This runner stops before every later subphase. No conditional circumferential estimator, joint correction, beam design, or automatic order selection exists here.

## J. Next-stage decision

Phase 4 passes its registered engineering gate. Phase 5 may be started only after explicit user authorization; this run stops here.
