---
phase_factor: 1
validation_status: PASS
statistical_calibration_status: NOT_CALIBRATED_STAGE5
configuration_hash: 77e50c6af0c1f6078ebedcd05084b1d11abe606d026677d4017ca2d83d459a86
---

# Step12.3D-E Stage-5 Conditional and Joint DML Validation

## A. Stage conclusion

**PASS.** The retained contribution is the organization and engineering effect of elevation-group initialization, within-group conditional azimuth handling, and correction on the fixed full sequential manifold. Conditional DML, SVD projection, alternating projection, and coordinate ascent are treated as prior art.

The technical and Pareto gates permit a later, separately authorized phase 6. This run stops at phase 5 and implements no FIM, tangent asymptotics, model-order calibration, K=3, persistent cache, or hardware mapping.

## B. Prior-art and evidence boundary

Ziskind-Wax alternating projection, coordinate ascent, conditional DML, and stable SVD projection are not novelty claims. PR-DML and Kim 2012 were not replaced by simplified implementations; both remain `EXACT_REPRODUCTION_UNAVAILABLE`. All noisy outputs are `NOT_CALIBRATED_STAGE5`; oracle Q and Kq are inputs.

## C. Implementation surface

Public code contains group-noise propagation, a fixed conditional azimuth bank/data/manifold/search, original full-sequential data and manifold construction, common-domain construction, classical joint coordinate refinement, and evaluation-only set matching. Truth, wrong-peak labels, paired matching, and local-full comparison remain in the test layer. Results are isolated under `results_stage5/`.

## D. Formula-to-code mapping

- `propagate_group_recovery_noise`: `H_e=Ge^dagger`, `R_group=H_e H_e^H`, using stable SVD and retaining cross-group terms.
- `prepare_conditional_azimuth_data`: `Zphi=Tphi Uq^H Xphi`, with covariance `alpha_q Uq^H Rphi Uq`.
- `prepare_full_sequential_dml_data`: `Zseq=Tseq Wseq^H Yelem`, with fixed `Cseq=Wseq^H Rn Wseq`.
- `refine_joint_sequential_dml`: fixed-axis classical coordinate ascent in canonical elevation-then-azimuth order.

## E. Dimensions and fixed objects

| Object | Registered dimension | Fixed scope |
|---|---:|---|
| `Xphi` | `65 x L` | one recovered elevation group |
| `Uq` | `65 x 3` | one conditional search |
| `Zphi`, `Tphi` | `3 x L`, `3 x 3` | all azimuth candidates |
| `Wseq` | `2080 x 9` | complete joint search |
| `Zseq`, `Tseq` | `9 x L`, `9 x 9` | complete joint search |
| `Gphi`, `Gseq` | `3 x Kq`, `9 x K` | candidate columns only |

## F. Tests and commands

The runner executed all 14 required tests plus one method-suite integration test. Registered test rows: 54; Code Analyzer messages: 0; public scope violations: 0. The command is:

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml/run_step12_3_stage5_validation.m')
```

The official manifest subset for frozen Step11 result files passed 351/351 entries (117091926 bytes), with missing/size/hash mismatches 0/0/0.

## G. Results and intervals

Two core noisy scenarios used 200 paired realizations per method. Normal holdout: main success 1.0000 (Wilson 95% 0.9816--1.0000, N=205), direct AP 1.0000. Stress holdout: main success 0.1800 (Wilson 95% 0.1373--0.2324, N=250), direct AP 0.1800.

Across all 455 holdout pairs, the main-minus-direct success difference was 0.0000 with paired 95% interval [0.0000, 0.0000]. The coherent-and-weak core stress case failed for main, direct AP, and local full alike (0/200); five partially out-of-domain samples were unconditional failures. No window was expanded.

Oracle, estimated, and six pre-registered perturbed-elevation chains all returned. Oracle-to-estimated azimuth-RMSE degradation: 0 deg; estimated-to-perturbed mean degradation: 0 deg.

## H. End-to-end complexity

The main budget includes stage-4 group search, recovery, noise propagation, conditional search, joint correction, and its one registered start. Direct AP used two pre-registered starts and both were charged. Mean holdout score calls were reduced by 44.95% versus direct AP and 74.95% versus local full. The mean normalized main score gap to local full was 3.72988e-07.

## I. Risks and unfinished work

Q and Kq remain oracle inputs. The conditional weak/coherent case is a registered failure boundary. PR-DML and Kim 2012 exact reproductions remain unavailable. Statistical model-order calibration, false-resolved/unresolved bootstrap, FIM beam design, near-pair tangent theory, K=3, persistent cache, and hardware mapping are not implemented.

## J. Next-stage decision

Technical correctness and Pareto scheme 1 passed: paired success was not worse and end-to-end score calls fell by more than 20%. A later phase 6 is technically permissible only after separate authorization. This run stops here.

Baseline status rows: 7. Overall result: **PASS**.
