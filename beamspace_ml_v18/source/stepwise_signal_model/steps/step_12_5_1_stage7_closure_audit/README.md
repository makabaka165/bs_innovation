# Stage7.1 Closure Audit Contract

This isolated stage audits the frozen Stage 7 evidence. It does not rerun FIM
enumeration, change the registered exact selection, modify the Stage 7
FIM/DML/Pareto algorithms, or authorize Stage 8.

## Stable code identity

`build_stage7_1_code_identity.m` defines the Stage7.1 source tree as every
tracked `.m` file below this directory plus this README, excluding `results/`
and `figures/`. The source-tree hash is SHA-256 over the path-sorted Git
`mode/blob/path` manifest. The stable code identity is SHA-256 over that tree
hash, the source-scope version, and the identity-contract version.

The historical baseline is fixed at
`25e063730309dac2595390d46744040ba6fbe4b3`. The runtime HEAD is provenance
metadata only: it is not an input to the stable identity or deterministic
evidence bundle. Formal execution requires the baseline to be an ancestor of
runtime HEAD, a clean worktree, and no untracked `.m` or README source.

## Sequential 3/5 semantics

The sequential 3/5 configuration means:

> 3 个俯仰中间通道，每通道 5 个条件方位输出

The corresponding map is `Zel=V'*Y`, followed by
`z(b,c)=u(c|b)'*Zel(b,:)'`, with equivalent element-space weight
`w(b,c)=kron(u(c|b),v(b))`. Thus `B_el=3`, `B_az=5`, and `B_out=15`.

The audit reports physical-subset aliases, the complete `eta0=0.80`
minimum-cost feasible family, post-hoc Pareto sensitivity from persisted
paired summaries, and corrected complexity/memory accounting. Alias-zero
differences identify the same physical measurements; they are not an
independent statistical non-significance result.

Before Pareto pooling, every comparison method must have exactly the same
`scenario_id` set and the same `n_trials` for each scenario. The scheme-B
comparison with the full parent retains the conservative shared-reference
standard-deviation interval label. Formal complexity accounting receives
`N_el`, `N_az`, `B_el`, and `B_az` explicitly from the frozen Stage 7 plan;
built-in dimensions are restricted to explicit unit-test opt-in.

## Paired edge diagnostics

`common/build_stage7_1_edge_diagnostic_plan.m` freezes the six registered
scenario IDs, methods `FIXED_RECT_3X5`, `GREEDY_ETA_080`, and
`FULL_PARENT_5X5`, SNR `[0,5,10]` dB, `Nmc=200`, and seed base `20260719`.
The 18 scenario-by-SNR paired groups use `seed_block_stride=1000`:

```text
group_seed_start = seed_base + seed_block_stride*(group_index-1)
trial_seed       = group_seed_start + trial_index - 1
```

The 3,600 common trial seeds are unique and nonoverlapping. Each common
element-domain realization is generated once, then the three fixed physical
subsets are evaluated, producing 10,800 method rows. Method labels and method
ordering do not enter the seed formula. Runtime timings are kept outside the
deterministic trial and summary artifacts.

The domain audit preserves `historical_registered_domain_pass` and adds
`tolerant_registered_domain_pass`, `boundary_numeric_disagreement_flag`, and
`domain_tolerance_deg`. The tolerance is exactly
`parameter_dimension*eps(domain_scale_deg)`; no empirical angular tolerance
is used. The executor gates on the tolerant result, including the registered
D0286 historical/tolerant boundary disagreement.

All edge outputs are tagged
`POST_HOC_EDGE_SENSITIVITY_NOT_USED_FOR_SELECTION`; they cannot alter the
Stage 7 selection or operating point.

## Closure and evidence

`compare_stage7_core_results_to_commit.m` reads the eleven registered Stage 7
CSV artifacts directly from Git commit
`85615e0f5027e7d6dee840dcb71aa1a2c07e85c3`. Primary keys are explicit;
status, flags, identifiers, counts, the 961-subset set, selected subset, and
finite-sample success counts are exact. Other numeric fields use absolute
`1e-12` or relative `1e-10` tolerance. Explicit runtime, file-size, and
source/provenance/plan identity values are excluded from the numeric equality
gate; unexpected core columns are rejected.

`run_stage7_1_closure_audit.m` applies all identity, frozen-evidence,
historical-comparison, semantic, alignment, complexity, and paired-execution
gates before invoking the writer. `stage7_1_artifact_registry.m` defines 16
formal artifacts. Thirteen deterministic artifacts enter the evidence bundle;
runtime provenance, runtime diagnostics, and the self-referential manifest do
not. Every deterministic core artifact binds the stable code identity.

`run_stage7_1_closure_unit_tests.m` uses only temporary synthetic fixtures and
does not write formal results. This README records the stable execution
contract, not a run state. Current closure state belongs in Stage7.1 result
artifacts and `innovation-mining/16_stage7_exact_subset_fim_audit.md`.

The Stage 7 README is a separate source-hashed contract and must not be
modified by Stage7.1 execution. A successful closure leaves Stage 7 at
`PASS_SYSTEM_ANALYSIS_ONLY`; it neither executes nor authorizes Stage 8.
