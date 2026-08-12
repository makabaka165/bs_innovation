# Stage8 K2 Cylindrical Multi-Center Cache Validation

Runtime root: `E:\bs_innovation_runtime\stage8_k2_cylindrical_multicenter_cache_v1`

## Gate Status

- Gate A: `STAGE8_K2_MULTICENTER_STATIC_ROTATION_PASS` (`192/192` geometry, `16/16` production, `3/3` negative controls).
- Gate B: `STAGE8_K2_MULTICENTER_SEMANTIC_PASS_24_OF_24` (`24/24`, controls `6/6`, covariance `8/8`).
- Gate C: `STAGE8_K2_MULTICENTER_LIFECYCLE_POSITIVE` (10 repeats per noise identity).
- Gate D: `ONLINE_SENTINEL_POSITIVE` (`12` cases, `48` pairs, `96` roots).

## Direct Answers

1. Reference requested center = 7.0 deg; actual physical center = 7.5 deg; reference column = 5.
2. Selected physical center offsets = `[0,+1,-1,+8,-8,+32,-32,+96]`; runtime sentinel uses `[+1,-8,+96]`.
3. All 192 geometry columns passed; maximum canonical geometry error = 0.
4. Beam codebooks co-rotate with the physical center; maximum layout error is checked at 1e-12 deg.
5. Canonical online production W/C/T errors are 0 / 0 / 0. Independent raw rebuild W/C/T diagnostics are 1.0319744356090441e-14 / 9.101772293327603e-15 / 0.0016202398850246778; raw T is an eigenbasis-stability diagnostic and is not used as the canonical coordinate contract.
6. Rotation-class hashes are identical within each noise identity (2 classes).
7. Actual-center hashes are distinct for all 16 production bundles.
8. Two shared providers serve 16 certified adapters; adapters contain no G tables.
9. Compact semantics passed 24/24; decision and trajectory mismatches are 0 and 0.
10. T4 finite-cache query count = 0; truth leakage = 0.
11. WHITE lifecycle build/load/storage reductions = 0.862028 / 0.151024 / 0.819507.
11. STAGE5_TOEPLITZ_CORRELATED lifecycle build/load/storage reductions = 0.861223 / 0.223375 / 0.820982.
12. 192-center storage reductions are 0.940316 and 0.941861, marked `ANALYTIC_EXTRAPOLATION_FROM_CERTIFIED_ROTATION_CLASS`.
13. Runtime sentinel is `ONLINE_SENTINEL_POSITIVE`: point 1.002499700 sec, AB 1.026623700 sec, BA 1.035212900 sec, reduction 1.672545%.
14. The parent approximately 2.15% online reduction is generic registered precomputation/fixed-backbone work, not the multicenter claim.
15. Cylindrical-specific evidence is co-rotated geometry/codebook/Stage5/domain equivalence, two-level identity, shared provider, adapters, and cross-center covariance.
16. The evidence supports the bounded paper claim: shared-center rotational reuse for the certified factor-1 cylindrical receive model, with fixed DML/Tangent mathematics unchanged.

## Test Closure

Named tests: `16/16` passed.

Repository: `E:\bs_innovation`
