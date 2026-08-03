# Innovation-Mining Document Status Index

Branch:
`experiment/stage8-k2-tangent`

Role:
`PRIMARY_TANGENT_AND_CLASSICAL_BASELINES`

Status:
`STAGE8_K2_TANGENT_RETAIN_WITH_CLASSICAL_AND_SUBSPACE_BASELINES`

This is the long-term Stage8 K2 branch for the frozen Tangent method and fair
classical or external baseline comparisons.

## Current authoritative K2 evidence

- `innovation-mining/31_*`: `TANGENT DECISIVE EVIDENCE`.
- `innovation-mining/32_*`: `TANGENT DIAGNOSTIC CORRECTION`.
- `innovation-mining/33_*` and `innovation-mining/34_*`: `CLASSICAL CML/MUSIC COMPARISON`.
- `innovation-mining/39_*` and `innovation-mining/40_*`: `STRUCTURED SUBSPACE BASELINE COMPARISON`.
- `innovation-mining/41_*`: `ORIGINAL SNR DOMAIN THEORY AND V1 PROTOCOL`.
- `innovation-mining/41A_*`: `V1 T4 NUMERIC-QUALITY GATE CORRECTION`.
- `innovation-mining/42_*`: `CORRECTED SNR DOMAIN VALIDATION V2 COMPLETE`.

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
The original Tangent retain decision and `TANGENT_PROFILE_SAFE` default remain
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

Only classical or external algorithm comparison is permitted, and only after
separate user authorization. Such work must begin on a temporary branch named
`work/stage8-k2-<baseline-name>` created from this branch. Integration into
this branch is allowed only by a separately authorized `git merge --ff-only`.

Tangent algorithm modification:
`NOT_AUTHORIZED`

The completed `work/stage8-k2-subspace-baselines-v1` branch is retained for
audit after authorized fast-forward integration.

## Long-term branch topology

- `main@247fad2208e77b04f7062e22b0fd3fd8a81bfc1f`: stable and unchanged.
- `experiment/stage8-k2-tangent`: this primary K2 experiment branch.
- `research/stage8-k2-vincent-anchored`: read-only Vincent research backup.

The three legacy experiment refs were deleted locally and remotely after
explicit user authorization. Their milestone commits remain recoverable from
the annotated tags and the verified pre-reorganization Git bundle.

## Prompt archive

All prompts under `innovation-mining/stage8_execution_prompts/archive/` are
historical records without execution authority. No active Stage8 prompt
exists.
