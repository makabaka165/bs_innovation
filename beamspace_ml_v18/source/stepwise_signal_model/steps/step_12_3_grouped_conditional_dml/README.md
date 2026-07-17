# Step12.3 Elevation-Group DML Revision

## Scope

This directory contains only the revised phase-4, Step12.3 A-C chain:

1. build fixed row and column effective-subspace whiteners for a separable
   matrix-normal noise model;
2. prepare distinct score and physical-recovery MMV coordinates;
3. estimate oracle-known `Q=1` or `Q=2` elevation groups on a registered
   local full-reference grid;
4. diagnose registered-model structural support; and
5. recover one physical `[Nphi,L]` circumferential data matrix per group.

It does not implement conditional-azimuth DML, full-manifold joint correction,
information-based beam selection, resampling calibration, automatic `Q`
selection, or `K=3`. Phase 5 has not started.

## Public Interfaces

- `build_separable_mmv_whiteners`
- `prepare_elevation_group_mmv_data`
- `stack_elevation_mmv_data` (legacy stacking utility, not the estimator input)
- `build_elevation_group_manifold`
- `diagnose_elevation_group_identifiability`
- `estimate_elevation_groups_dml`
- `recover_group_azimuth_data`

`build_separable_mmv_whiteners` calls the Step12.2 `build_psd_whitener` for
both covariance factors. It does not duplicate the eig/rank policy. All rank
thresholds use the Step12.2 relative machine-scale rule.

## Fixed Data Coordinates

For raw elevation-DBF data

```text
Zel_raw             [B_phys, Nphi, L]
T_row               [r_row, B_phys]
T_col               [r_col, Nphi]
Z_recovery_mmv      [r_row, Nphi*L]
Z_score_mmv         [r_row, r_col*L]
Ge                  [r_row, Q]
Ce_recovery         [Q, Nphi*L]
Ce_score            [Q, r_col*L]
```

each snapshot uses

```text
Z_left  = T_row * Zel_raw
Z_score = Z_left * T_col'
```

`Z_score_mmv` is used only for DML scoring. `Z_recovery_mmv` retains the
physical circumferential columns and is used only for coefficient and group
recovery. Right whitening acts on nuisance-coefficient columns and never on
`Ge`. The physical elevation beams, row covariance, column covariance, both
whiteners, and registered candidate grid remain fixed throughout a search.

## Status Contract

The estimator exposes three independent outputs:

- `estimate_status`: whether a registered candidate was returned;
- `support_status`: what the current registered structural evidence supports;
- `statistical_calibration_status`: fixed to `NOT_CALIBRATED_STAGE4`.

The corresponding flags are `estimate_returned_flag`,
`structural_gate_pass_flag`, and `registered_model_certified_flag`.
`GROUP_REGISTERED_MODEL_CERTIFIED` is restricted to noiseless or exact
structural evidence in the oracle-Q registered model. Noisy full-rank cases
return `GROUP_REGISTERED_MODEL_SUPPORTED_UNCALIBRATED`. This deterministic
certification is not a statistical confidence statement.

For `NOISY_UNCALIBRATED`, `rank(Z_score_mmv)`, `rank(Z_recovery_mmv)`, and
`rank(Ce_hat)` are diagnostics only. Exact rank failure can reject structural
support only under `NOISELESS_STRUCTURAL`. The rank-deficient coefficient
counterexample returns

```text
estimate_status = ESTIMATE_NOT_RUN_STRUCTURAL_RANK_FAILURE
support_status  = GROUP_MMV_RANK_UNCERTIFIED
```

This means that the current registered Q-group MMV grouping/recovery chain is
not certified. It is not a theorem that the physical targets are
unidentifiable under every nonlinear parameterization.

## Public/Test Boundary

The public recovery API only solves for coefficients, restores physical
`[Nphi,L]` group matrices, and reports numerical diagnostics. Reference-based
Frobenius, subspace, crosstalk, and mixing metrics are computed exclusively by
`tests/private/evaluate_group_recovery_against_truth.m` and never enter
candidate scoring or estimator control flow.

## Run

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml/run_step12_3_elevation_group_validation.m')
```

## Results

- `results/elevation_group_trial.csv`
- `results/elevation_group_identifiability.csv`
- `results/group_recovery_error.csv`
- `results/elevation_group_keypoints.csv`
- `results/separable_whitening_validation.csv`
- `results/stage4_status_semantics.csv`
- `results/elevation_group_report.md`
- `results/stage4_revision_report.md`

The revision passed all registered tests. The small explicit Kronecker
reference produced relative data/score/RSS errors of `1.199e-16`, `0`, and
`0`; it is used only in the unit test. The correlated row-and-column case used
both whiteners and returned an uncalibrated supported result. Current truth
angles are primarily grid aligned, so these results do not establish off-grid
super-resolution performance. Exact AP/PR-DML reproduction remains an open
baseline gap.
