# Stage8 Execution Prompt Index

## Stable main

Accepted Stage8 K2 line:

- Tangent scientific and classical-baseline closure:
  `3e7153ae11f8a49633a2edd2d2f710673e5d1bad`
- Exact-cache Level-A and continuous-T4 zero-hit result:
  `b4424c6d87511ecf8034a61bc5384ba347cb2467`
- Fixed registered-backbone cache robust-positive result:
  `b6156655b2d51d5333522166f6509b100ead7d08`
- Cylindrical multicenter cache final closeout:
  `c88050b286404336ceb2019f099ec6d5cbfabbd2`

Accepted production behavior:

- `TANGENT_PROFILE_SAFE` remains the K2 estimator;
- Tangent direction, continuous rho profile, DML score and final selector are unchanged;
- finite registered cache is retained for the fixed registered backbone;
- finite registered cache is not used by continuous T4;
- cylindrical multicenter shared-center reuse is certified in the bounded factor-1 scope.

## Active execution

`NONE`

No prompt under `archive/` authorizes execution.

## Archived prompts

Historical prompts are stored under:

- `archive/completed/`
- `archive/deferred/`
- `archive/superseded/`
- `archive/raw_inputs/`

The Stage8 K2 Tangent/cache prompts are stored under:

`archive/completed/stage8_k2_cache/`

Archive identity and status are recorded in:

`archive/PROMPT_ARCHIVE_MANIFEST.csv`

## Retained independent research

`research/stage8-k2-vincent-anchored`

This branch is not part of the Tangent/cache integration and is not modified by this closeout.

## Execution rule

A future Stage8 experiment requires:

1. a new short-lived branch;
2. a newly committed execution prompt;
3. explicit authorization;
4. separate integration review.

Completed experimental branches are preserved by annotated tags rather than long-lived remote branches.
