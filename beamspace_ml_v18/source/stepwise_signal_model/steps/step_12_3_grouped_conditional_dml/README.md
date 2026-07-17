# Step12.3 Grouped Conditional and Joint DML

## Scope

This directory contains the revised phase-4 Step12.3 A-C chain and the
completed phase-5 Step12.3 D-E validation:

1. build fixed row and column effective-subspace whiteners for a separable
   matrix-normal noise model;
2. prepare distinct score and physical-recovery MMV coordinates;
3. estimate oracle-known `Q=1` or `Q=2` elevation groups on a registered
   local full-reference grid;
4. diagnose registered-model structural support; and
5. recover one physical `[Nphi,L]` circumferential data matrix per group.
6. propagate the full correlated group-recovery noise model;
7. estimate oracle-known `Kq=1` or `Kq=2` azimuths with a fixed
   elevation-conditioned beam bank;
8. return to original factor-1 element data for correction on the fixed full
   sequential manifold; and
9. compare the grouped initialization with classical fixed-center coordinate
   ascent, a local full-grid reference, and conventional DBF in one registered
   physical domain.

It does not implement information-based beam selection, tangent asymptotics,
model-order resampling calibration, automatic `Q/K/Kq` selection, `K=3`, a
persistent cache, or hardware mapping. All stage-5 noisy outputs remain
`NOT_CALIBRATED_STAGE5`.

## Public Interfaces

- `build_separable_mmv_whiteners`
- `prepare_elevation_group_mmv_data`
- `stack_elevation_mmv_data` (legacy stacking utility, not the estimator input)
- `build_elevation_group_manifold`
- `diagnose_elevation_group_identifiability`
- `estimate_elevation_groups_dml`
- `recover_group_azimuth_data`
- `propagate_group_recovery_noise`
- `build_fixed_conditional_azimuth_beam_bank`
- `prepare_conditional_azimuth_data`
- `build_conditional_azimuth_manifold`
- `estimate_conditional_azimuth_dml`
- `prepare_full_sequential_dml_data`
- `build_full_sequential_local_manifold`
- `build_common_registered_local_domain`
- `build_stage5_configuration_hash`
- `refine_joint_sequential_dml`
- `match_target_sets` (evaluation only)

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

The stage-5 domain constructor accepts only a conventional center and frozen
engineering offsets. Target-set matching, truth-in-domain labels, wrong-peak
labels, and paired performance resampling are evaluation-only operations.
Conditional estimation and grouped joint correction run only when both
`estimate_returned_flag` and `structural_gate_pass_flag` are true; otherwise
they return the explicit upstream-uncertified status without changing the
domain or rank rule.

## Stage-5 Fixed Coordinates

For the registered full-aperture experiments:

```text
Xphi_q       [65,L]       recovered physical group data
Uq           [65,3]       fixed conditional azimuth bank
Zphi_white   [3,L]        fixed conditional observation
Tphi_q       [3,3]        conditional covariance whitener
Wseq         [2080,9]     true sequential beam matrix
Zseq_white   [9,L]        original full sequential observation
Tseq         [9,9]        fixed full covariance whitener
Gphi         [3,Kq]       conditional candidate manifold
Gseq         [9,K]        full receive-geometry candidate manifold
```

The conditional path uses recovered `Xphi_q` only for initialization. Final
joint scores always use the original element snapshots through the same fixed
`Wseq`, `Cseq`, and `Tseq`.

## Run

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml/run_step12_3_elevation_group_validation.m')
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml/run_step12_3_stage5_validation.m')
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
- `results_stage5/conditional_azimuth_trial.csv`
- `results_stage5/conditional_azimuth_elevation_error_propagation.csv`
- `results_stage5/group_noise_propagation.csv`
- `results_stage5/joint_refinement_history.csv`
- `results_stage5/joint_refinement_trial.csv`
- `results_stage5/method_budget_comparison.csv`
- `results_stage5/method_score_gap.csv`
- `results_stage5/wrong_local_peak_summary.csv`
- `results_stage5/offgrid_holdout.csv`
- `results_stage5/normal_holdout_summary.csv`
- `results_stage5/stress_holdout_summary.csv`
- `results_stage5/baseline_reproduction_status.csv`
- `results_stage5/stage5_keypoints.csv`
- `results_stage5/stage5_report.md`

The revision passed all registered tests. The small explicit Kronecker
reference produced relative data/score/RSS errors of `1.199e-16`, `0`, and
`0`; it is used only in the unit test. The correlated row-and-column case used
both whiteners and returned an uncalibrated supported result. Current truth
angles are primarily grid aligned, so these results do not establish off-grid
super-resolution performance. Exact AP/PR-DML reproduction remains an open
baseline gap.

Stage 5 passed all technical tests and Pareto scheme 1. Two core noisy
scenarios used 200 paired realizations per method. The main and direct-AP
holdout success rates were identical, giving a paired difference interval of
`[0,0]`, while the main end-to-end score-call count was `44.95%` lower than
the two-start direct baseline and `74.95%` lower than the local full-grid
reference. Normal-holdout main success was `1.0000` (Wilson 95% lower bound
`0.9816`); stress-holdout success was `0.1800` (Wilson interval
`0.1373-0.2324`). The coherent-and-weak core stress case failed for the main,
direct, and local-full methods alike (`0/200`) and remains a recorded boundary.
PR-DML and Kim 2012 are marked `EXACT_REPRODUCTION_UNAVAILABLE`; no simplified
replacement was used.
