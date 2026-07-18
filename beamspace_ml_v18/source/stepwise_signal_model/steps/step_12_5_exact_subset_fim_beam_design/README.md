# Step12.5 Exact Rectangular Subset FIM Beam Design

This stage evaluates the finite registered family of 961 rectangular subsets of
one factor-1, elevation-then-azimuth sequential 5x5 parent beam pool. For every
physical subset it reconstructs the correlated output covariance, effective
subspace whitener, factor-1 manifold derivatives, deterministic nuisance-
amplitude FIM, and relative element-space FIM retention.

`exact` means complete enumeration only within the frozen 5x5 rectangular
family and registered scenarios. It is not a claim of general global
optimality. Deterministic FIM, nuisance elimination, CRB retention, PSD
whitening, minimum-FIM selection, and greedy exchange are prior art. The only
candidate contribution is their exact reconstruction for this correlated
physical sequential pool, its structured cost, and independent oracle-K
finite-sample risk validation.

The runner is `run_step12_5_exact_subset_fim_design.m`. It writes all locked
plan registries before the first Stage 7 FIM calculation. Stage 6, Stage 5, and
Step11 evidence are read-only dependencies.

## Stable provenance contract

The historical baseline is fixed at
`ea1c0320b7ba9639d6d955a1a45037cdc6cfdb31`. A formal run requires that this
baseline is an ancestor of the runtime `HEAD` and that the working tree is
clean at entry. `HEAD` and `origin/main` are recorded as runtime metadata, but
neither is required to equal the historical baseline and neither enters a
stable controls, plan, or provenance hash.

The source identity is a sorted Git `mode/blob/path` manifest covering tracked
Stage 7 `.m` files and this README while excluding `results/` and `figures/`.
The dependency manifest covers the Step12.0 factor-1 manifold and derivatives,
Step12.1 sequential DBF/Wseq/permutation interfaces, Step12.2
whitener/rank/SVD-DML interfaces, Stage 5 joint refinement, and the frozen
Stage 6 bundle identity. Formal plan artifacts expose
`stage7_source_tree_hash`, `stage7_dependency_tree_hash`, and
`stage7_provenance_hash`.

This README is part of the source-hashed contract and intentionally contains
no execution, rerun, or closure status. Runtime status and hashes belong in
Stage7.1 result artifacts and `innovation-mining/16_stage7_exact_subset_fim_audit.md`.
Subsequent Stage7.1B work must not modify this README.

The registered evidence includes 640 design, 288 validation, and 256 frozen
FIM-holdout scenarios. Finite-sample evaluation keeps Q/K/Kq oracle and uses 6
normal, 18 threshold, 4 mismatch, and 1 coherent-weak stress scenario with 200
paired realizations per scenario. It does not run model-order selection,
bootstrap, resolved/unresolved metrics, K=3, cache, or output-SNR
renormalization.

The stable decision rule retains a physically duplicated exact/fixed result as
system-design analysis rather than an independent method improvement. A
failed finite-sample Pareto gate cannot authorize Stage 8. Concrete execution
outcomes are recorded outside this source-hashed README.
