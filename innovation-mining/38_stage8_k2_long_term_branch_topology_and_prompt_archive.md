# Stage8 K2 Long-Term Branch Topology and Prompt Archive

Protocol:
`STAGE8_K2_THREE_BRANCH_TOPOLOGY_AND_PROMPT_ARCHIVE_V1`

Current branch:
`experiment/stage8-k2-tangent`

Role:
`PRIMARY_TANGENT_AND_CLASSICAL_BASELINES`

## Scientific contents

This branch contains:

- `31_*` and `32_*` Tangent evidence and diagnostic correction;
- `33_*` and `34_*` classical CML/MUSIC comparison;
- `tools/stage8_k2_tangent_profile/`;
- `tools/stage8_k2_classical_baselines/`.

This branch does not contain:

- the Vincent-Anchored algorithm or tools;
- `35_*`, `36_*`, or `37_*` evidence.

No scientific algorithm or evidence was changed while establishing this
branch.

Default K2:
`TANGENT_PROFILE_SAFE`

Tangent algorithm modification:
`NOT_AUTHORIZED`

Research backup:
`research/stage8-k2-vincent-anchored`

## Long-term topology

| Branch | Role | Anchor |
|---|---|---|
| `main` | Stable branch, unchanged | `247fad2208e77b04f7062e22b0fd3fd8a81bfc1f` |
| `experiment/stage8-k2-tangent` | Primary Tangent and classical-baseline branch | `bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b` plus this docs/archive commit |
| `research/stage8-k2-vincent-anchored` | Read-only Vincent research backup | `89e47e1827aa8c2a36c49c369e60525713d20d38` plus its docs/archive commit |

Legacy refs are retained pending user review. Branch deletion, main changes,
cross-branch merges, and force pushes were not authorized.

## Future comparison workflow

Future classical or external comparisons require all of the following:

1. separate user authorization;
2. a temporary `work/stage8-k2-<baseline-name>` branch from this branch;
3. no modification of Tangent tools, `31_*`, `32_*`, or Step12.7;
4. a separately authorized fast-forward-only integration;
5. user review before any temporary branch deletion.

No work branch is created by this protocol.

## Recovery anchors

Annotated tags preserve Core-V2, Tangent retention, classical comparison, and
Vincent closure milestones. A verified pre-reorganization Git bundle is stored
under:

`E:/bs_innovation_runtime/stage8_k2_three_branch_reorg_20260801T032037Z`

## Prompt archive

Completed, deferred, and superseded prompts are inventoried in
`innovation-mining/stage8_execution_prompts/archive/PROMPT_ARCHIVE_MANIFEST.csv`.
Every archived prompt has `execution_authority = false`.
