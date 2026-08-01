# Stage8 K2 Long-Term Branch Topology and Prompt Archive

Protocol:
`STAGE8_K2_THREE_BRANCH_TOPOLOGY_AND_PROMPT_ARCHIVE_V1`

Current branch:
`research/stage8-k2-vincent-anchored`

Role:
`READ_ONLY_RESEARCH_BACKUP`

## Scientific contents

This branch contains:

- `31_*` and `32_*` Tangent evidence and diagnostic correction;
- `33_*` and `34_*` classical CML/MUSIC comparison;
- `35_*` and `36_*` Vincent-Anchored theory, code, and experiment;
- `37_*` applicability analysis and negative route closure;
- Tangent, classical-baseline, and Vincent research tools.

No scientific algorithm or evidence was changed while establishing this
branch.

Default K2:
`TANGENT_PROFILE_SAFE`

Vincent-Anchored:

- `CLOSED_NO_ROBUST_REGIME`
- `NOT_DEFAULT`
- `NOT_PRODUCTION`
- `NO_V2`

Further algorithm execution:
`NOT_AUTHORIZED`

## Long-term topology

| Branch | Role | Anchor |
|---|---|---|
| `main` | Stable branch, unchanged | `247fad2208e77b04f7062e22b0fd3fd8a81bfc1f` |
| `experiment/stage8-k2-tangent` | Primary Tangent and classical-baseline branch | `bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b` plus docs/archive commit |
| `research/stage8-k2-vincent-anchored` | Read-only Vincent research backup | `89e47e1827aa8c2a36c49c369e60525713d20d38` plus this docs/archive commit |

The three legacy refs were deleted locally and remotely after explicit user
authorization. Their milestone commits remain protected by annotated tags and
the verified pre-reorganization Git bundle. Main changes, cross-branch merges,
and force pushes were not authorized.

## Recovery anchors

Annotated tags preserve Core-V2, Tangent retention, classical comparison, and
Vincent closure milestones. A verified pre-reorganization Git bundle and raw
prompt copies are stored under:

`E:/bs_innovation_runtime/stage8_k2_three_branch_reorg_20260801T032037Z`

## Prompt archive

Completed, deferred, superseded, and raw-input prompts are inventoried in
`innovation-mining/stage8_execution_prompts/archive/PROMPT_ARCHIVE_MANIFEST.csv`.
Every archived prompt has `execution_authority = false`. Raw inputs are kept
byte-identical to their external backup copies.
