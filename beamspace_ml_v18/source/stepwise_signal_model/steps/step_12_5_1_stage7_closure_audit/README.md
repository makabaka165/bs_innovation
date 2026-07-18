# Stage7.1A2 Closure Audit Tools

This isolated code-only stage audits the already frozen Stage 7 evidence. It
does not rerun FIM enumeration, generate finite-sample trials, change the
registered exact selection, or write formal results.

The sequential 3/5 configuration means:

> 3 个俯仰中间通道，每通道 5 个条件方位输出

The corresponding map is `Zel=V'*Y`, followed by
`z(b,c)=u(c|b)'*Zel(b,:)'`, with equivalent element-space weight
`w(b,c)=kron(u(c|b),v(b))`. Thus `B_el=3`, `B_az=5`, and `B_out=15`.

The common tools report physical-subset aliases, the complete eta0=0.80
minimum-cost feasible family, post-hoc Pareto sensitivity from persisted
paired summaries, and corrected complexity/memory accounting. Alias-zero
differences are classified as identical physical measurements, not as an
independent statistical non-significance result.

The fixed-3x5 paired intervals are pooled exactly from the persisted
per-scenario paired-normal summaries. Raw trial rows were not persisted, so
the scheme-B comparison with the full parent uses a conservative
shared-reference standard-deviation bound; the gate formula itself is
unchanged and the output records this interval status. Before pooling, every
comparison method must have the same `scenario_id` set and the same
`n_trials` for each scenario.

`tests/private/build_stage7_1_edge_diagnostic_plan.m` freezes 54 planned rows
from six existing Stage 7 scenario IDs, three fixed methods, and SNR
`[0,5,10]` dB at `Nmc=200`. Each of the 18 scenario-by-SNR groups has one
paired seed and one `paired_group_id` shared by all three methods. A future
authorized executor must generate one common element-domain trial per paired
group before applying the three physical subsets. Stage7.1A2 only tests this
plan; it does not execute Monte Carlo.

The domain audit preserves `historical_registered_domain_pass` and adds
`tolerant_registered_domain_pass`, `boundary_numeric_disagreement_flag`, and
`domain_tolerance_deg`. The tolerance is exactly
`parameter_dimension*eps(domain_scale_deg)`; no empirical angular tolerance
is used. The edge gate uses the tolerant result, including the frozen D0286
boundary disagreement.

Formal complexity accounting requires `N_el`, `N_az`, `B_el`, and `B_az`
extracted explicitly from the frozen Stage 7 plan. Built-in dimensions require
both explicit unit-test mode and explicit default opt-in. The helper
`build_stage7_1_code_identity.m` exposes the source commit and a deterministic
Git `mode/blob/path` tree hash so later Stage7.1B output can bind the exact
Stage7.1 source identity.

The Stage 7 README is a stable source-hashed contract. Runtime status belongs
in Stage7.1 result artifacts and
`innovation-mining/16_stage7_exact_subset_fim_audit.md`; Stage7.1B must not
modify that README. The runner `run_stage7_1_closure_unit_tests.m` uses
temporary test state and leaves `results/` empty.

All sensitivity outputs are tagged
`POST_HOC_SENSITIVITY_NOT_USED_FOR_SELECTION` or
`POST_HOC_EDGE_SENSITIVITY_NOT_USED_FOR_SELECTION`. Stage 7 remains
`PASS_SYSTEM_ANALYSIS_ONLY`, and Stage 8 remains unauthorized. A2 does not
claim that Stage7.1 closure is complete.
