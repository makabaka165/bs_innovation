# Innovation-Mining Document Status Index

Branch:
`main`

Role:
`STABLE_STAGE8_K2_TANGENT_CACHE_CLOSEOUT`

Status:
`STAGE8_K2_TANGENT_CACHE_BRANCH_CLOSEOUT_COMPLETE`

The accepted Stage8 K2 source is
`c88050b286404336ceb2019f099ec6d5cbfabbd2`. Main contains no active Stage8 K2
execution prompt after this integration. Vincent remains on a separate,
read-only research line and is not part of this integration.

## Current authoritative K2 evidence

- `innovation-mining/31_*` through `40_*`: historical element-input-SNR
  experiments and baseline evidence, retained for provenance only.
- `innovation-mining/41_*` and `41A_*`: SNR-domain definitions and the V1
  numerical-quality correction.
- `innovation-mining/42_*`: immutable SNR-domain foundation; it contains both
  the original audit and the paired white-beamspace control.
- `innovation-mining/43_*` and `44_*`: canonical Tangent white-SNR Monte Carlo
  theory, results, and route closure.
- `innovation-mining/45_*` and `46_*`: canonical white-SNR classical baseline
  comparison.
- `innovation-mining/47_*` and `48_*`: canonical white-SNR all-classical
  comparison, including the structured subspace baselines.
- `innovation-mining/49_*`: branch consolidation record.
- `innovation-mining/50_*` through `55_*`: completed/final Tangent canonical
  cache, exact-cache, fixed-backbone, and cylindrical multicenter evidence.
- `innovation-mining/56_*`: final Stage8 K2 Tangent/cache branch closeout.

## White-SNR Monte Carlo route closure

The registered white-SNR Monte Carlo completed with:

- registry, checkpoints, and SNR rows: `1680/1680` each;
- method rows: `5040/5040`;
- unique trial hashes: `1680/1680`;
- base realizations: `240`, with ten replicates per exact factor cell;
- truth leakage: `0`;
- maximum white-SNR target error: `2.1765e-12 dB`;
- independent read-only reconstruction and artifact hash audit: `PASS`.

Final working-region state:
`IDENTIFIED`

The first overall `STABLE_RELATIVE_GAIN` point is `+10 dB` white SNR and
the overall classification remains stable through `+22 dB`. Profile-level
first stable points are `P1: +14 dB`, `P2: +22 dB`, `P3: +10 dB`, and
`P4: +14 dB`; P1 is explicitly `NON_MONOTONIC_EMPIRICAL_REGION` after its
first stable point. These are descriptive experimental regions, not an
online selector or production threshold.

The MATLAB trial session recorded a post-computation shutdown anomaly only
after all 1680 checkpoints and the ready-to-finalize state were written.
Finalization then completed in a fresh single-thread session with exit code
zero, and the independent read-only audit passed in another fresh session.

## White-SNR classical baseline comparison

The registered classical baseline comparison completed as part of the
canonical branch with:

- trial identity reconstruction: `1680/1680`;
- validated checkpoints: `1680/1680`;
- baseline rows: `5040/5040`;
- MUSIC applicable rows: `1120`;
- Element CML applicable rows: `160`;
- truth leakage: `0`;
- independent audit: `PASS`;
- independent artifact hashes: `15/15`;
- baseline reruns during independent audit: `0`.

The Tangent and production implementations were not modified. The comparison
is complete and awaits user review.

Next:
`USER_REVIEW`

## Stage8 K2 Tangent canonical-cache Level-A v1

`innovation-mining/50_stage8_k2_tangent_canonical_cache_fusion_architecture.md`
is reanchored on
`experiment/stage8-k2-tangent@3e7153ae11f8a49633a2edd2d2f710673e5d1bad`
for an authorized result-preserving Level-A backend implementation on
`experiment/stage8-k2-tangent-canonical-cache-v1`. The scope is limited to
factor-1 canonical geometry, direct G-only construction, exact cache/direct
providers, and the T4 pair-manifold integration. Tangent decisions, the
fixed-grid fallback, completed comparison evidence, and all parent branches
remain frozen. Level-B interpolation is not authorized.

Canonical-cache Level-A status:
`COMPLETE`

Level-A completion evidence:

- target branch: `experiment/stage8-k2-tangent-canonical-cache-v1`;
- TCC tests: `8/8`; compact equivalence cases: `8/8`;
- existing Tangent regression tests: `5/5`;
- maximum direct/cache G, RSS, loglik, rho, and angle differences: `0`;
- identity rejection: `10/10` fail-closed; truth leakage: `0`;
- cache build: `0.7185583 sec`, `1.1354827880859375 MB`;
- real continuous Tangent profile: exact hits `0`, misses `346`, direct
  fallbacks `346` (exact hit rate `0`);
- end-to-end median runtime: `DIRECT_ONLY 4.67653 sec`, hybrid
  `5.8454223 sec`;
- performance classification:
  `LEVEL_A_CORRECT_EXACT_HIT_RATE_ZERO`.

Conclusion:
`STAGE8_K2_TANGENT_CANONICAL_CACHE_LEVEL_A_COMPLETE`

Level-B interpolation remains unauthorized and is a separate future study.

## SNR domain validation

V1 stopped at its too-strict `1e-10` frozen-whitener numerical-quality gate;
Phase B was not executed under V1. V2 used the registered `1e-8` numerical
quality tolerance without changing the whitener or any SNR formula.

V2 completion evidence records:

- original element hashes: `72/72 exact`;
- white-control registry and SNR rows: `72/72` each;
- method rows: `216/216`;
- truth leakage: `0`;
- Monte Carlo: `NOT_EXECUTED`.

SNR reporting distinguishes element-input, raw sequential-beamspace,
whitened sequential-beamspace, and the K2 projected truth-only diagnostic.
The active comparison coordinate is expected total-energy SNR after the frozen
sequential measurement and whitener. The original element-input SNR results
remain audit/provenance material and are not an active comparison route. The
original Tangent retain decision and `TANGENT_PROFILE_SAFE` default remain
unchanged.

Default K2:
`TANGENT_PROFILE_SAFE`

Core-Lite:
`FIXED_GRID_SAFETY_BASELINE`

Core-Plus:
`HISTORICAL_INTERNAL_BASELINE`

Full4D CML:
`DIAGNOSTIC_NUMERICAL_BASELINE`

MUSIC:
`STANDARD_UNSMOOTHED_REFERENCE`

Vertical FBSS-MUSIC / Root-MUSIC / ESPRIT:
`MORE_INFORMATIVE_ELEMENT_DOMAIN_CLASSICAL_REFERENCES`

Vincent-Anchored:

- not present in this branch;
- research backup only at `research/stage8-k2-vincent-anchored`.

## Core evidence retained

- `innovation-mining/23_*`: compact Stage8 diagnostic.
- `innovation-mining/24_*`: continuous-refinement decision.
- `innovation-mining/26_*`: Core-V2 known-K pruning evidence.
- `innovation-mining/27_*`: safe hybrid closure.
- `innovation-mining/29_*`: corrected final single-CPI known-K validation.
- `innovation-mining/28_*`: historical invalid protocol evidence only.

The frozen Step12.7 known-K interface, Tangent implementation, and `31_*` and
`32_*` evidence are not authorized for modification.

## Future permitted work

Stage8-K2 algorithm development is closed. Only thesis or paper work is
permitted: formula presentation, experimental figures, and writing the
applicability range and limitations.

Tangent algorithm modification:
`NOT_AUTHORIZED`

Further Stage8-K2 algorithm work:
`NOT_AUTHORIZED`

Next:
`THESIS_DOCUMENTATION_ONLY`

## Long-term branch topology

- `main`: stable Stage8 K2 Tangent/cache line, retaining
  `247fad2208e77b04f7062e22b0fd3fd8a81bfc1f` and accepting
  `c88050b286404336ceb2019f099ec6d5cbfabbd2`.
- `research/stage8-k2-vincent-anchored`: read-only Vincent research backup.

Completed Tangent/cache experiment branches are preserved by annotated tags
and retired after main integration. All branches not explicitly listed for
deletion remain unchanged. Vincent is retained as an independent research
line.

## Prompt archive

All prompts under `innovation-mining/stage8_execution_prompts/archive/` are
historical records without execution authority. No active Stage8 prompt
exists. Prompt `020` is archived as completed with byte-identical SHA-256
evidence in the prompt archive manifest. Prompts `021` and `022` are archived
as completed with independent-audit PASS and byte-identical SHA-256 evidence.
The three Stage8 K2 Tangent/cache execution prompts are archived under
`archive/completed/stage8_k2_cache/` with byte-identical hashes recorded in the
manifest.

## Unified white-SNR all-classical comparison

The registered comparison completed on the canonical Tangent branch with 1680 validated
checkpoints, 6720 new-method rows, 6720 diagnostics, 16800 unified plot rows,
56 representative spectra, zero truth leakage, zero existing-method reruns,
and an independent artifact audit PASS. Execution used the bounded 15-minute
Windows Scheduled Task controller, which unregistered itself after push.

The comparison tiers remain scientifically distinct; structural N/A rows are
not failures or Tangent wins. No production selector or threshold was added.

Next:
`USER_REVIEW`
