# Stage8 K2 Tangent canonical-cache Level-A v1 validation

## Scope

This artifact covers factor-1 canonical geometry, direct G-only construction, exact cache/direct hybrid lookup, and T4 Tangent pair-manifold integration.
No Level-B interpolation, FPGA mapping, classical baseline rerun, or full white-SNR Monte Carlo was executed.

## Git and identity

Branch: `experiment/stage8-k2-tangent-canonical-cache-v1`
Parent: `experiment/stage8-k2-tangent@3e7153ae11f8a49633a2edd2d2f710673e5d1bad`
Architecture source: `8a398f4a86345520f29925f1ca7b41b700f22cb9`
Fixed measurement hash: `208ac1cfafa1a4e0367aa0af9d46f0a362b14343fad97aaa06a7888e73a536fe`
Measurement center: requested 8 deg, physical 7.5 deg, column 5.

## Mathematical implementation

The direct path uses the repository factor-1 steering convention and the existing reshape_cyl_vector_to_matrix mapping before Wseq and Tseq.
Canonical geometry is Rz(-phi_M) times the actual active subarray, with unchanged local element order. Cache keys use global azimuth converted by wrap180(global_az - phi_M).
The one-time cache build stores exact grid columns through the frozen actual-frame direct ordering to preserve numerical Tangent decisions at near-rank-deficient pairs; rotation equivalence is independently tested.
Identity mismatch fails closed to DIRECT_FALLBACK. No provider interface receives truth or observations.

## Equivalence

New TCC tests: 8/8 passed. Existing Tangent regression tests: 5/5 passed.
Compact equivalence cases: 8/8 passed.
Maximum G relative error: 0.
Maximum RSS absolute difference: 0.
Maximum log-likelihood absolute difference: 0.
Maximum rho difference: 0 deg; maximum angle difference: 0 deg.
Legacy direct, DIRECT_ONLY, and exact-cache/direct decisions remained result-equivalent for the four fixed trials.
Identity rejection test: 10/10 independent mutations failed closed to direct fallback.

## Cache and runtime

Cache build: 0.71855829999999998 sec, 1.1354827880859375 MB.
Actual Tangent profile exact hits: 0; misses: 346; direct fallbacks: 346; hit rate: 0.
End-to-end DIRECT_ONLY median: 4.6765299999999996 sec; hybrid median: 5.8454223000000001 sec.
Break-even query count (single-target benchmark): Inf.
Performance classification: `LEVEL_A_CORRECT_EXACT_HIT_RATE_ZERO`.

## Conclusion

`STAGE8_K2_TANGENT_CANONICAL_CACHE_LEVEL_A_COMPLETE`

Further interpolation or approximate screening belongs to a separately authorized Level-B study.
