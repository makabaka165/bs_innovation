# Stage8 K2 Cylindrical Multi-Center Canonical Cache

This directory contains the compact, production-equivalence validation for
the factor-1 cylindrical-array rotation class.  A center-specific production
model is independently rebuilt with the frozen Stage7 builders.  The online
registered provider stores one canonical relative-key dictionary per noise
identity; certified center adapters translate absolute registered queries.

The finite provider is used only by the fixed registered K1/K2 backbone.
Continuous Tangent/T4 evaluation remains on the existing direct path and is
required to report zero finite-cache queries.  No interpolation,
nearest-neighbour lookup, truth, observation, or full trial is stored in a
provider or adapter.

Run the compact gates with:

```matlab
scope = stage8_k2_mc_add_paths(repo_dir);
fixture = stage8_k2_mc_build_context(repo_dir, runtime_root);
static = stage8_k2_mc_run_static(fixture);
semantic = stage8_k2_mc_run_semantics(fixture);
lifecycle = stage8_k2_mc_run_lifecycle(fixture);
runtime = stage8_k2_mc_run_runtime_sentinel(fixture);
```

The runners write only aggregate CSV/JSON/Markdown evidence to the
`innovation-mining` directory.  Checkpoints and serialized artifacts belong
under the runtime root outside the repository.
