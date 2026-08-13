# Stage8 K2 Tangent Fixed-Backbone Cache

This experiment integrates the certified 21-key registered-manifold
dictionary into the repeatedly evaluated fixed K1/K2 backbone. The finite
dictionary is not a provider for the continuous Tangent profile.

## Architecture

- `fixed_registered_manifold_provider` is an immutable, measurement-scoped
  plain struct. Its identity is validated once before online execution.
- `LEGACY_FULL` calls `build_full_sequential_local_manifold` unchanged.
- `DIRECT_G_ONLY` calls the certified factor-1 G-only builder and the frozen
  stable-rank implementation.
- `REGISTERED_CACHE` performs O(K) exact-grid indexing, K-column assembly,
  and the same stable-rank calculation. Formal execution stops on a contract
  miss; it does not round, snap, interpolate, or use nearest neighbours.
- `t4_manifold_provider` is a separate optional field. Formal runs leave it
  unset, so T4 continues to use the legacy continuous manifold path.

## Fixed Registered Closure

The domain is reconstructed by the frozen Stage8 plan:

- azimuth: `7.4:0.2:8.6`
- elevation: `9.8:0.2:10.2`
- Cartesian cardinality: `21`

K1/K2 context starts, nested K1 estimates, nested registered anchors,
coordinate candidates, and final fixed estimates are required to be exact
members of this domain. Interface checks fail closed and never modify an
angle.

## Frozen Boundaries

The Tangent direction, center derivatives, rho scan, bracket, `fminbnd`, DML
objective, update order, rank/tie rules, and final safe selector remain
unchanged. Runtime attribution reports `LEGACY_FULL` versus
`REGISTERED_CACHE` separately from `DIRECT_G_ONLY` versus
`REGISTERED_CACHE`.
