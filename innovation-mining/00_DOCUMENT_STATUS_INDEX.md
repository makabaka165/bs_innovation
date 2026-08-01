# Innovation-Mining Document Status Index

Branch:
`experiment/stage8-k2-tangent`

Role:
`PRIMARY_TANGENT_AND_CLASSICAL_BASELINES`

Status:
`STAGE8_K2_TANGENT_RETAIN_WITH_CLASSICAL_BASELINES`

This is the long-term Stage8 K2 branch for the frozen Tangent method and fair
classical or external baseline comparisons.

## Current authoritative K2 evidence

- `innovation-mining/31_*`: `TANGENT DECISIVE EVIDENCE`.
- `innovation-mining/32_*`: `TANGENT DIAGNOSTIC CORRECTION`.
- `innovation-mining/33_*` and `innovation-mining/34_*`: `CLASSICAL CML/MUSIC COMPARISON`.

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

No temporary comparison branch is created by the topology protocol.

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
