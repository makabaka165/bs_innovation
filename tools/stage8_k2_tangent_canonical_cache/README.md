# Stage8 K2 Tangent Canonical Cache Level-A

This directory contains the result-preserving Level-A backend authorized for
`experiment/stage8-k2-tangent-canonical-cache-v1`.

The provider owns only fixed-measurement, observation-independent single-target
whitened manifold columns:

```text
g = Tseq * (Wseq' * a_factor1)
```

`DIRECT_ONLY` builds those columns from the current receive geometry without
derivatives. `EXACT_CACHE_OR_DIRECT` performs an identity-checked exact lookup
and falls back to the same direct G-only path on a miss or any identity
mismatch. Pair columns retain caller order and receive one stable rank/SVD
after concatenation.

Typical setup:

```matlab
scope = stage8_k2_tcc_add_paths(repo_dir);
model = resolve_stage8_measurement_model(registry, config_id, noise_id);
[cache, cache_info] = stage8_k2_tcc_build_cache(model, struct( ...
    'domain_bounds_deg', [7.4, 8.6, 9.8, 10.2]));
provider = stage8_k2_tcc_build_provider( ...
    'EXACT_CACHE_OR_DIRECT', model, cache, struct());
[G, manifold_info, provider_info] = ...
    stage8_k2_tcc_get_pair_manifold(angles_deg, model, provider, struct());
```

The default cache grid is an exact 0.01-degree validation grid over the frozen
local domain. Lookup uses a representation-level `1e-11` degree key tolerance;
there is no nearest-neighbor lookup or interpolation. The cache identity hashes
the fixed measurement, factor-1 convention, geometry/order, `Wseq`, `Tseq`,
measurement center, grids, numeric class, and tolerance.

The grid is keyed by canonical `delta_az`. During the one-time build, each
stored column is numerically certified through the frozen actual-frame direct
element ordering and a fixed two-column GEMM accumulation. Pair fallback uses
the same accumulation, preserving exact-hit Tangent decisions at nearly
rank-deficient endpoint pairs while the separate rotation test verifies the
factor-1 canonical formula.

Run the compact provider tests with:

```matlab
addpath(fullfile(repo_dir, 'tools', ...
    'stage8_k2_tangent_canonical_cache', 'matlab'));
summary = stage8_k2_tcc_run_tests(repo_dir);
```

No cache binary, observation, truth, or full experiment output belongs in this
directory or in Git.
