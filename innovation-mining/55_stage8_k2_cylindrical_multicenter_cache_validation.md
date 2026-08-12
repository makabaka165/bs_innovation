# Stage8 K2 Cylindrical Multi-Center Cache Validation

Runtime root: `E:/bs_innovation_runtime/stage8_k2_cylindrical_multicenter_cache_v1`

Evidence reuse: `REUSED_EXISTING_GATE_A_B_C_D_OUTPUTS_NO_LARGE_RERUN`.

## Gate Status

- Gate A: `STAGE8_K2_MULTICENTER_STATIC_ROTATION_PASS` (`192/192` geometry, `16/16` production, `3/3` negative controls).
- Gate B: `STAGE8_K2_MULTICENTER_SEMANTIC_PASS_24_OF_24` (`24/24`, controls `6/6`, covariance `8/8`).
- Gate C: `STAGE8_K2_MULTICENTER_LIFECYCLE_POSITIVE` (existing 10-repeat output reused).
- Gate D: `ONLINE_SENTINEL_POSITIVE` (`12` cases, `48` pairs, `96` roots; existing output reused).

## Direct Answers

1. Reference requested center = 8.0 deg; actual physical center = 7.5 deg; reference column = 5. Values come from `stage8_k2_mc_reference_spec(repo_dir)`.
2. Selected physical center offsets = `[+0,+1,-1,+8,-8,+32,-32,+96]`; runtime sentinel uses `[+1,-8,+96]`, read from the saved runtime rows/schedule.
3. All 192 geometry columns passed; maximum canonical geometry error = 0.
4. Beam codebooks co-rotate with the physical center; maximum layout error is checked at 1e-12 deg.
5. Canonical online production W/C/T errors are 0 / 0 / 0. Independently rebuilt W and C agree at double-precision scale. The independently eig-rebuilt T has elementwise diagnostic 0.0016202398850246778 and may differ in basis under clustered eigenvalues. The online rotation class selects the reference PSD-whitening coordinate; this canonical T value is not independent eig-rebuild elementwise equality.
6. Raw/reference whitener diagnostics pass across 16 bundles: direct forward residuals 2.9821355578206544e-08 / 5.3455719120555631e-08 are conditioning diagnostics (maximum covariance condition number 6808557096.1595936), while basis-invariant covariance backward errors 3.2835085743399303e-15 / 9.2016686367430636e-15 pass at 1e-10. The near-unitary Q error 5.2242947192625456e-08 passes the investigated 1e-7 limit (10x the default), and alignment residual 8.5417756076081577e-16 passes at 1e-10.
7. The raw T elementwise difference and direct forward whitening residuals are diagnostic-only and are not used as production-equivalence gates; the latter are amplified by covariance condition numbers up to 6808557096.1595936.
8. Rotation-class hashes are identical within each noise identity (2 classes); actual-center hashes are distinct for all 16 bundles.
9. Two shared providers serve 16 certified adapters; adapters contain no G tables.
10. Compact semantics passed 24/24; decision and trajectory mismatches are 0 and 0.
11. T4 finite-cache query count = 0; truth leakage = 0.
12.1. WHITE lifecycle build/load/storage reductions = 0.862028 / 0.151024 / 0.819507.
12.2. STAGE5_TOEPLITZ_CORRELATED lifecycle build/load/storage reductions = 0.861223 / 0.223375 / 0.820982.
13. 192-center storage reductions are 0.940316 and 0.941861, marked `ANALYTIC_EXTRAPOLATION_FROM_CERTIFIED_ROTATION_CLASS`.
14. Runtime sentinel is `ONLINE_SENTINEL_POSITIVE`: point 1.002499700 sec, AB 1.026623700 sec, BA 1.035212900 sec, reduction 1.672545%. These saved values were not rerun.
15. The parent approximately 2.15% online reduction is generic registered precomputation/fixed-backbone work, not the multicenter claim.
16. The bounded paper claim remains shared-center rotational reuse for the certified factor-1 cylindrical receive model, with fixed DML/Tangent mathematics unchanged.

## Test Closure

Original named tests: `16/16` passed.

Repository: `E:/bs_innovation`
