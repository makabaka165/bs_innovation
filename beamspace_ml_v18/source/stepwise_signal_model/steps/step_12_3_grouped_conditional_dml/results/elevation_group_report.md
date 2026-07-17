---
phase_factor: 1
validation_status: PASS
scope: Step12.3_phase_4_revision_only
---

# Step12.3 Elevation-Group DML Revision Report

## A. Phase conclusion

**PASS.** The oracle-Q registered elevation-group chain now separates estimator execution, structural support, and statistical calibration. Phase 5 remains unimplemented in this run.

## B. Read basis and prior-art boundary

The revision follows documents 06, 10, 11, 12, 13, and 14; the failed adaptive-W/B record; the code manifest; the v0.19 manuscript; the sequential scope note; and all Step12.2/12.3 source and results. Concentrated DML, SVD projection, whitening, and nuisance-coefficient elimination remain prior-art mechanisms. This revision claims interface and noise-model correctness, not an atomic algorithmic novelty.

## C. Public/private boundary

Public code builds fixed separable whiteners, prepares score and recovery coordinates, evaluates registered candidates, diagnoses support, and recovers physical circumferential group data. Error and mixing metrics against reference coefficients are computed only by `tests/private/evaluate_group_recovery_against_truth.m`. Public boundary tests passed 6/6.

## D. Formula-to-code mapping

| Contract | Implementation | Evidence |
| --- | --- | --- |
| `T_row*C_row*T_row'=I` and `T_col*C_col*T_col'=I` | `build_separable_mmv_whiteners` | 7 whitening cases |
| `Z_score=T_row*Z*T_col'` | `prepare_elevation_group_mmv_data` | separable/Kronecker check |
| `Z_recovery=T_row*Z` in physical columns | same bundle and `recover_group_azimuth_data` | test-only recovery errors |
| execution/support/calibration split | estimator and diagnostic modules | 6 status cases |

## E. Data and convention ledger

- Active receive spatial phase factor: `1`.
- Registered elevation beams: `4 6 8 10 12 14 16 18 20` deg.
- `Zel_raw`: `[B_phys,Nphi,L]`; `T_row`: `[r_row,B_phys]`; `T_col`: `[r_col,Nphi]`.
- `Z_score_mmv`: `[r_row,r_col*L]`; `Z_recovery_mmv`: `[r_row,Nphi*L]`; `Ge`: `[r_row,Q]`.
- `Ce_score`: `[Q,r_col*L]`; `Ce_recovery`: `[Q,Nphi*L]`. Right whitening never enters `Ge`.
- External angles use degrees; derivatives use radians; `phase_factor=1`. At `L=1`, circumferential columns are MMV coefficient observations rather than independent temporal snapshots.

## F. Executed tests

- Public interface: 5/5.
- Whitening/Kronecker: 7/7.
- Status semantics: 6/6.
- Trial/diagnostic/recovery rows: 23/23, 10/10, 16/16.
- Common scope rules: 12/12.
- Code Analyzer: 23 files, 0 messages.

## G. Key numerical results

- Maximum row/column whitening errors: `1.058932e-15` / `1.136200e-15`.
- Separable/Kronecker data, score, and RSS errors: `1.198900e-16`, `0.000000e+00`, `0.000000e+00`.
- Structural counterexample: estimate `ESTIMATE_NOT_RUN_STRUCTURAL_RANK_FAILURE`, support `GROUP_MMV_RANK_UNCERTIFIED`, `rank(Ce)=1`; this rejects certification of the current registered Q-group MMV recovery chain only.
- Correlated row/column case: column whitening applied `1`, angle error `0.000000e+00` deg.
- Common-elevation group-sum recovery error: `3.891164e-15`.
- Maximum test-only recovery Frobenius/chordal errors: `1.041807e-03` / `1.037638e-03`.
- No interval, posterior, or calibrated probability is reported; every active calibration state is `NOT_CALIBRATED_STAGE4`.

## H. Complexity

- Score calls: 1248; SVD calls: 3326; row/column eig calls: 47.
- Multi-start runs: 0; validation runtime: 2.896261 s.
- Maximum score-plus-recovery data storage: 74880 bytes.
- Maximum candidate-manifold storage: 30240 bytes.
- Maximum row-plus-column whitener storage: 68896 bytes.
- Peak MATLAB process memory was not measured.

## I. Risks and unfinished work

Q remains oracle-known, the search is a registered local full reference, and current reference angles are primarily grid aligned. Off-grid super-resolution performance is unverified. Exact AP/PR-DML reproduction remains unavailable. No statistical calibration, automatic Q selection, conditional-azimuth DML, joint correction, information beam design, or K=3 path is implemented.

## J. Next-stage decision

The phase-4 revision passes its technical gates. A later phase-5 run requires separate user authorization; this run stops here.
