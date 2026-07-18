---
phase_factor: 1
theory_status: THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY
statistical_scope: DETERMINISTIC_GEOMETRIC_VALIDATION
baseline_commit: 0430f25272690a3ddf378dcf0bab465ca93edb68
stage6_source_tree_hash: 605d76b653c633c5eabf6c95422403256b9d0da6000e6e2561a518635cf6e5ce
stage6_dependency_tree_hash: c5ed245229e0273dbfe6295530c14630054b091045981f837c83c69a6b8d3453
stage6_controls_hash: 941f53cad599294a76b1aa07e5b1f06c5c51b73b12de63caf3d6e8886b6fa03d
stage6_measurement_plan_hash: 28425e98c333d60e88417dfa7dfa7e50ea30d420cc66e630f456c8c9836e30b2
stage6_experiment_plan_hash: baee3ecbaa7e949bab7df0d44496ccd5fddec4d935ca777dbe9d1d0e7d7b211e
stage6_provenance_hash: f2209ac492954ccca41e6a6e3860e1286ebdbbc22b29189117049bc01cec48be
provenance_contract_version: STAGE6_PROVENANCE_CONTRACT_V1
---

# Step12.4 Fixed-Whitening Tangent-Asymptotic Validation

## A. Stage conclusion

**PASS.** Theory status: `THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY`. The three nondegenerate asymptotic relations and the synthetic sixth-order exact-null extension passed. Physical status: `NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND`. A separately authorized phase 7 is technically permissible; this run stops at phase 6.

## B. Prior-art boundary

Center-difference coordinates, the sum-difference unitary transform, the projected Jacobian/effective FIM, two-column Gram spectra and coherence geometry are prior art. The retained statement is only a scenario-specific explicit corollary for one fixed, exactly whitened sequential cylindrical receive manifold. Formula-targeted OpenAlex/Crossref retrieval was bounded and Semantic Scholar returned HTTP 429.

## C. Files

Public geometry code is under `common/`; locked plans and fixtures are under `tests/private/`; fourteen required tests are under `tests/`; CSV and reports are under `results/`; seven registered PNGs are under `figures/`.

## D. Formula-to-code mapping

- `build_fixed_whitened_sequential_derivatives`: fixed `g` and per-radian `J`.
- `compute_projected_jacobian_metric`: `P_g_perp` and real symmetric `T`.
- `evaluate_secant_tangent_case`: direct-SVD `sigma2`, coherence and normalized-Gram relations.
- `compute_tangent_null_sixth_order`: `alpha`, `v3_eff` and the registered sixth-order candidate.
- `build_stage6_fixed_measurement_model`: fixed `Wseq/Cseq/Tseq` and SHA-256 contract.

## E. Dimensions, units and fixed objects

The four primary configurations have 9, 9, 6 and 6 sequential outputs; the diagnostic has one. `Wseq` is `2080 x B`, `Cseq` is `B x B`, `Tseq` is `rank(Cseq) x B`, `g` is `rank(Cseq) x 1`, `J` is `rank(Cseq) x 2`, `G2` is `rank(Cseq) x 2`, and `T` is `2 x 2`. External angles use degree; derivatives, directions and separations use radian.

## F. Tests and command

The unified runner executed the registered numerical and provenance tests, Code Analyzer, scope/schema/hash scans, 14-file stage-5 SHA-256 verification and 351-file Step11 official-manifest verification. Command: `run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/run_step12_4_tangent_asymptotics_validation.m')`. Analyzer messages: 0.

## G. Key results

- Maximum first/second/third derivative relative errors: 5.88975e-09 / 3.21222e-05 / 0.000658338.
- Maximum registered tail errors for sigma2/coherence/normalized Gram: 4.01019e-06 / 1.04212e-05 / 6.11803e-06.
- Minimum tail point count: 3; maximum unsaturated exact-identity error: 1.39769e-12; maximum invariance error: 9.43357e-13.
- Synthetic exact-null order: 6; maximum sixth-order ratio error: 2.22045e-16. No statistical confidence interval is reported because this is deterministic geometry validation.

## H. Complexity

Registered secant SVDs: 1296; metric eigendecompositions: 90; derivative cases: 225; receive-manifold evaluations: 6813. Runtime and memory diagnostics are isolated in `stage6_runtime_diagnostics.csv`.

## I. Risks and unfinished work

No exact tangent null occurred in the four primary physical configurations; the single-channel case is only an exact measurement collapse. The sixth-order extension is therefore physically untested here despite analytic-fixture support. Finite-sample resolution, threshold SNR, source coherence, model order, FIM beam selection, patent search and paid-database full-text/cited-by review remain outside this stage.

## J. Next-stage decision

The fixed measurement contract, all three nondegenerate relations, prior-art boundary and honest null classification passed. Technically, a later phase 7 may be entered only after separate user authorization. This run stops here.
