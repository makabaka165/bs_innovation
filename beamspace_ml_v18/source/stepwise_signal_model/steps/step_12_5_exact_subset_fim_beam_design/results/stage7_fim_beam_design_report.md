---
phase_factor: 1
stage7_status: PASS_SYSTEM_ANALYSIS_ONLY
stage7_plan_hash: 1c6f99f158a118e5dc79efaa02076009cf103f87c9861d1dd52da27fb8608f23
stage6_evidence_bundle_hash: 0c1f444603398e03865043af4e4c6e4a414dd15a3cc90e0539b19c56e990c839
---

# Step12.5 Exact Rectangular Subset FIM Beam Design

## A. Stage conclusion

**PASS_SYSTEM_ANALYSIS_ONLY.** Stage 8 permission: `0`; any continuation still requires separate user authorization. This run stops at Stage 7.

## B. Reading scope and prior-art boundary

The repository audits, Stage 5/6 frozen evidence, Step12.0-12.2 interfaces, three registered arXiv works, and the complete Liu 2026 publisher PDF were reviewed. FIM retention and minimum selection are prior art; `exact` means only complete enumeration of this frozen finite family.

## C. Files

Implementation is isolated under `step_12_5_exact_subset_fim_beam_design/`; Stage 6, Stage 5, and Step11 evidence remained read-only. Required CSV, Markdown, and PNG artifacts are in `results/` and `figures/`.

## D. Formula-to-code mapping

- Subset covariance/whitening: `build_exact_subset_model`.
- Element/subset derivatives: `build_stage7_element_manifold`, `apply_stage7_element_whitener`.
- Effective FIM/Schur reference: `effective_deterministic_fim`, `effective_deterministic_fim_schur_reference`.
- Relative eta: `relative_fim_retention`.
- Structured cost: `stage7_subset_cost`.

## E. Dimensions, units, pool, and family

`W0` is 2080x25; derivatives and FIM parameters use radians. The parent beam IDs form a 5x5 fallback bank, and all 961 nonempty `I_e x I_a` rectangles were evaluated.

## F. Tests and command

Registered test rows: 477; Code Analyzer messages: 0; scope violations: 0. Command: `run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_5_exact_subset_fim_beam_design/run_step12_5_exact_subset_fim_design.m')`.

## G. Key results

Full-parent design eta ceiling: 0.823236874. FIM operating points passed: 1/3; finite-sample Pareto points passed: 0/3. Strongest fixed rectangle: `FIXED_RECT_3X5`. No false-split or false-resolved metric was computed or reported.

| eta0 | exact subset | MAC | eta design | eta validation | eta holdout | risk decision |
|---:|---|---:|---:|---:|---:|---|
| 0.80 | RECT_E14_A31 | 7215 | 0.812182 | 0.854926 | 0.816395 | SYSTEM_DESIGN_ANALYSIS_ONLY |
| 0.90 |  | NaN | NaN | NaN | NaN | FIM_GATE_REJECTED |
| 0.95 |  | NaN | NaN | NaN | NaN | FIM_GATE_REJECTED |

Qualified exact finite-grid success: 0.65569, Wilson 95% [0.643362, 0.667811]; wrong-peak rate: 0.0348276; unconditional penalized error: 0.281384. Paired success difference versus `FIXED_RECT_3X5`: 0 [0, 0]. MAC reduction versus fixed/full parent: 0.000%/40.000%.

Paired penalized-error difference: 0 [0, 0]; wrong-peak increase: 0 [0, 0].

Paired success difference versus full parent: 0.000862069 [-0.00375933, 0.00548347].

Threshold SNR_80 T0/T1: 7.28571/3.65625 dB. Mismatch M0-M3 success: 1/0.995/0.995/1. Stress success: 0, Wilson 95% [0, 0.0188453].

Selected output/memory/data movement: 240/499200/33520 bytes; measured online DBF runtime: 6.06894531e-06 s/sample; offline subset evaluation runtime: 0.273582 s.

## H. Complete complexity

FIM evaluations: 1292928; covariance/whitener decompositions: 2184/2184; generalized-eigenvalue evaluations: 2585856; finite-sample score/SVD calls: 11734516/11734516; runtime: 1428.998 s; peak-memory estimate: 110417088 bytes; result volume: 1401807 bytes.

## I. Risks, failure boundaries, and downgrades

Q/K/Kq were oracle; no bootstrap, model-order selection, K=3, cache, hardware, C05/topK/gap adaptation, or output-SNR renormalization was used. Physical exact-null remains unverified. FIM retention is not finite-sample success; divergences are retained in `fim_vs_finite_sample_risk.csv`.

## J. Next-stage decision

Stage 8 is not technically authorized by this result. This run stops at Stage 7.

Keypoint rows: 34.
