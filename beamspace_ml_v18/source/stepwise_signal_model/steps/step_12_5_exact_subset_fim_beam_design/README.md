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

The registered evidence includes 640 design, 288 validation, and 256 frozen
FIM-holdout scenarios. Finite-sample evaluation keeps Q/K/Kq oracle and uses 6
normal, 18 threshold, 4 mismatch, and 1 coherent-weak stress scenario with 200
paired realizations per scenario. It does not run model-order selection,
bootstrap, resolved/unresolved metrics, K=3, cache, or output-SNR
renormalization.

The current registered result is `PASS_SYSTEM_ANALYSIS_ONLY`: eta0=0.80 has one
FIM-qualified exact 3x5 subset, but that physical subset is identical to the
strongest fixed 3x5 rectangle; eta0=0.90 and 0.95 exceed the parent-pool design
ceiling. The finite-sample Pareto gate therefore retains the implementation as
system-design analysis and does not authorize Stage 8.
