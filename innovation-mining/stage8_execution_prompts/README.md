# Stage8 Execution Prompt Index

Current branch:
`research/stage8-k2-vincent-anchored`

Branch role:
`READ_ONLY_VINCENT_RESEARCH_BACKUP`

Active execution:
`NONE`

Default K2:
`TANGENT_PROFILE_SAFE`

Vincent-Anchored:
`CLOSED_NO_ROBUST_REGIME / NOT_DEFAULT / NOT_PRODUCTION / NO_V2`

## Archive layout

- `archive/completed/`: 15 completed prompts (`001`, `003` through `016`).
- `archive/deferred/`: one deferred prompt with no execution authority.
- `archive/superseded/`: one superseded prompt with no execution authority.
- `archive/raw_inputs/`: preserved user-supplied source prompts.
- `archive/PROMPT_ARCHIVE_MANIFEST.csv`: hash and status inventory.

No file under `archive/` authorizes execution. Further Vincent or Stage8-K2
algorithm work requires a new, explicit user authorization and is currently
`NOT_AUTHORIZED`.
