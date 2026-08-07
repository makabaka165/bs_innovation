# Stage8 K2 White-SNR Branch Consolidation

Status: `STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_CANONICAL`

Canonical branch:
`experiment/stage8-k2-tangent`

Promoted source:
`work/stage8-k2-white-snr-all-classical-baselines-v1@6db6d5a996dc3a0870454da06d5e3040a9e0cc94`

Authorization:
User-authorized branch consolidation on 2026-08-07.

## Scope

The canonical Tangent branch now contains the complete white-SNR comparison:

- frozen Tangent, Core, and earlier classical references;
- white-SNR Full4D and MUSIC comparisons;
- white-SNR Element MUSIC, GFBSS-MUSIC, Root-MUSIC, and LS-ESPRIT
  structured-subspace references.

The active experimental coordinate is expected total-energy SNR after the
frozen sequential measurement and whitener. Structured-subspace estimators may
still consume the full element-domain realization; that is an estimator
interface distinction, not a change to the SNR coordinate.

Historical element-input-SNR experiments and their audit artifacts remain in
the commit history for provenance. They are not the active comparison route.

## Branch topology

Retained:

- `main` (stable branch);
- `experiment/stage8-k2-tangent` (canonical white-SNR Tangent branch);
- `research/stage8-k2-vincent-anchored` (read-only Vincent research backup).

Retired after promotion:

- `work/stage8-k2-subspace-baselines-v1`;
- `work/stage8-k2-white-snr-classical-baselines-v1`;
- `work/stage8-k2-white-snr-all-classical-baselines-v1`.

The retired commits are ancestors of the canonical branch. No scientific code,
measurement model, whitener, SNR formula, or production interface was changed
by this consolidation.

## Execution state

No active Stage8 execution prompt exists. Further work is limited to thesis or
paper documentation, figures, and applicability/limitation statements.
