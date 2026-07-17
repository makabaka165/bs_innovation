# Step12.3A-C Elevation-Group DML and Identifiability

## Scope

This step implements only the first three subphases of Step12.3:

1. stack fixed-whitened elevation DBF outputs into MMV data;
2. build the fixed elevation-group manifold and diagnose `rank(Ge)`,
   `rank(Ce)` or `rank(Ce_hat)`, whitening rank, and finite local
   manifold-subspace aliasing;
3. estimate oracle-known `Q=1` or `Q=2` elevation groups with stable SVD
   DML and recover one `[Nphi,L]` circumferential data matrix per group.

The public interfaces are:

- `stack_elevation_mmv_data`;
- `build_elevation_group_manifold`;
- `diagnose_elevation_group_identifiability`;
- `estimate_elevation_groups_dml`;
- `recover_group_azimuth_data`.

The beam matrix and effective-subspace whitener are fixed before candidate
evaluation. The search never rebuilds the observation or whitening
coordinates. All ranks use the Step12.2 scale-relative SVD rule.

## Oracle and State Boundary

`Q` is an input, not an estimated model order. `Q=1` uses a registered
one-dimensional local grid. `Q=2` evaluates every unordered pair in a small
registered local grid. There is no angular-separation rule, candidate
truncation, score-gap rule, or scenario repair branch.

The phase-4 implementation returns:

- `GROUP_IDENTIFIABLE` when the registered beamspace, manifold,
  coefficient-rank, whitening-rank, and finite local alias checks pass;
- `GROUP_UNIDENTIFIABLE` when the oracle model is not supported.

No automatic merge decision is made in this oracle phase. In particular,
`rank(Ce)<Q` returns `GROUP_UNIDENTIFIABLE` and cannot produce `Q`
high-confidence groups.

For `L=1`, the `Nphi` columns are MMV coefficient observations sharing the
same elevation manifold. They are not described as independent temporal
snapshots, and `Nphi>Q` is not used as an identifiability proof.

## Baseline Boundary

The validation runs vertical element-domain DML and a Q1 elevation-beam peak
baseline. The Q1/Q2 estimator under test is itself the exhaustive local full
elevation-DML reference. No audited exact AP-DML or PR-DML implementation is
available in this repository, so the report records that reproducibility gap
and does not introduce a simplified substitute.

## Run

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml/run_step12_3_elevation_group_validation.m')
```

## Outputs

- `results/elevation_group_trial.csv`
- `results/elevation_group_identifiability.csv`
- `results/group_recovery_error.csv`
- `results/elevation_group_keypoints.csv`
- `results/elevation_group_report.md`

Every result row carries `phase_factor=1` and an explicit status or pass
field. This step does not implement conditional azimuth estimation, joint
refinement, information-based beam design, resampling-based order selection,
or automatic `Q` selection.
