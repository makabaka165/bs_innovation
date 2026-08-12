# Stage8 K2 Tangent Fixed-Backbone Cache Validation

## Outcome

- Completion: `STAGE8_K2_TANGENT_FIXED_BACKBONE_CACHE_VALIDATION_COMPLETE`
- Correctness: `STAGE8_K2_TFBC_CORRECTNESS_PASS`
- Performance: `STAGE8_K2_FIXED_BACKBONE_CACHE_ROBUST_POSITIVE`
- Retention: `RETAIN_FIXED_BACKBONE_REGISTERED_CACHE`
- Certified-scope default: `REGISTERED_CACHE`
- API fallback without a certified provider: `LEGACY_FULL`

The measured result supports retaining and enabling the exact-key registered
cache for the certified fixed-backbone scope. It does not make the finite
dictionary a provider for continuous Tangent refinement, and it does not
claim that every unconfigured caller should silently change behavior.

## Architecture Answers

1. The cache is connected to conventional registered G-only initialization,
   K1 fixed refinement and final certification, K2 helper-K1, registered
   nested-anchor candidates, K2 fixed refinement, and final certification.
2. Tangent center manifolds and derivatives, projected direction, rho scan,
   bracket, `fminbnd`, DML scoring/selection rules, and the continuous T4
   profile remain on their legacy mathematical paths.
3. T4 completely bypasses the finite registered cache: 0 query, 0 hit,
   0 miss, and 0 fallback in the 72-trial correctness run.
4. The 72 trials exercised 14,280 eligible fixed registered calls and 22,040
   eligible columns. All 22,040 columns were cache hits; misses and fallbacks
   were both zero.
5. Semantic equality is 72/72, including full result checksum and full query
   trajectory equality. Query mismatch, final-selector mismatch, truth
   leakage, collision, and fixed off-grid counts are zero.
6. `REGISTERED_CACHE` versus `LEGACY_FULL` saves 6.88042915 s by the frozen
   paired estimator, a 2.152679547% reduction and 1.022067506x speedup. The
   one-sided 95% bootstrap lower bound is 6.60548815 s.
7. Cache-only attribution, `REGISTERED_CACHE` versus `DIRECT_G_ONLY`, saves
   3.0954294 s, a 0.995643227% reduction and 1.010591224x speedup. Its
   one-sided 95% lower bound is 2.92642865 s.
8. Median cold build is 0.3268985 s and 0.32429465 s for the two measurement
   identities; median cold load is 0.00164865 s and 0.0016317 s. Per-identity
   break-even is 4 trials for build and 1 trial for load.
9. The final decision is `RETAIN_FIXED_BACKBONE_REGISTERED_CACHE`. Certified
   Tangent fixed-backbone runs should configure the immutable provider and
   `REGISTERED_CACHE`; the compatibility default remains `LEGACY_FULL` when
   no certified provider is supplied.
10. The evidence supports the architectural claim that a finite exact-key
    dictionary accelerates the repeatedly evaluated registered backbone while
    continuous Tangent mathematics remains unchanged. It does not support a
    claim that the cache accelerates the continuous Tangent core itself.

## Correctness Gates

Static certification passed 42/42 singles, 462/462 canonical unordered pairs,
and 882/882 ordered pairs for the two fixed measurement identities. Rank,
singular-value, threshold, identity rejection, off-grid rejection, domain
rejection, and phase rejection checks all passed without relaxing a tolerance.

The formal 72-trial comparison passed all required gates:

- semantic pass: 72/72;
- timed checksum match: 1,440/1,440 in each comparison;
- full trajectory mismatch: 0;
- final-selector mismatch: 0;
- truth leakage: 0;
- eligible cache miss: 0;
- eligible fallback: 0;
- T4 registered-cache query: 0.

The post-runtime formal TFBC suite passed 10/10, including the 72-trial
semantic test. Pre-runtime compatibility verification also passed the TCC,
TECS, fixed-model, nested-RSS, and Tangent smoke/direction suites.

## Runtime Decision

Both formal comparisons used 72 frozen trials, 20 contiguous paired repeats
per trial, AB 10 / BA 10, root timing, per-pair checksum equality, and the
fixed-registry 10,000-resample bootstrap. The primary comparison satisfies
every robust-positive gate: overall point and lower bound are positive, both
measurement identities are positive, and AB and BA aggregates are positive.
The attribution comparison independently satisfies the same sign checks.

The 2.1527% primary reduction includes replacing legacy full-manifold
engineering work with the fixed registered producer plus dictionary lookup.
The 0.9956% direct-G comparison is the cache-only increment. No separate
paired `LEGACY_FULL` versus `DIRECT_G_ONLY` experiment was run here, so the
remaining difference is not reported as an independently measured G-only or
structural-cleanup effect. No structural cleanup was introduced in the timed
comparison.

## Frozen Boundaries And Environment

- Baseline: `b4424c6d87511ecf8034a61bc5384ba347cb2467`
- Runtime code: `de683550cd6eb8002e40a05eb37605ca6595d703`
- Branch: `experiment/stage8-k2-tangent-fixed-backbone-cache-v1`
- MATLAB: R2022b, `-singleCompThread`
- CPU: AMD Ryzen 7 8845H with Radeon 780M Graphics
- OS: Windows 11 64-bit, version 10.0.22631
- Trial registry: `41af84fcc41fb3c820fd2d635064b03950367a78a36c15a94821c3bb9975f6fe`
- Timing schedule: `478a632a6efa8344ed30097c3f1a39c87933d78203aeeb8ea9c8db40bfc5305e`

`stage8_k2_tp_projected_direction.m`, `stage8_k2_tp_profile_scale.m`, and
`stage8_k2_tp_constants.m` are unchanged from the baseline. Raw checkpoints,
warmups, runtime outputs, and logs remain outside Git under
`E:\bs_innovation_runtime\stage8_k2_tangent_fixed_backbone_cache_v1`.
