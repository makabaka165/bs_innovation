# Stage8 K2 Unified White-SNR All-Classical Comparison

Status: `FINALIZED_AWAITING_INDEPENDENT_AUDIT`

The comparison reconstructed 1680 immutable evidence-44 trials and ran
only the four preregistered new methods. The six evidence-44/46 methods
were read without refitting (`existing_method_rerun_count = 0`).

## Integrity

- checkpoints: `1680/1680`;
- new method rows: `6720`;
- new diagnostic rows: `6720`;
- unified plot rows: `16800`;
- representative spectra: `56`;
- truth/profile/start leakage: `0`;
- Element MUSIC applicable: `1120`;
- GFBSS-MUSIC applicable: `1260`;
- Root-MUSIC applicable: `630`;
- LS-ESPRIT applicable: `630`.

## Interpretation boundary

White SNR is the common experimental coordinate, not an estimator input
for element-domain methods. Structural N/A rows are excluded from RMSE
and are not counted as Tangent wins. Pairwise statements use common-valid
trials only. Exact-cell P90 values with N=10 are descriptive, not stable
tail estimates. The three comparison tiers are not interchangeable
hardware interfaces. No global superiority claim, online selector, or
production threshold is created.

## New-method scientific states

- `ELEMENT_MUSIC_K2`: `APPLICABILITY_LIMITED`.
- `ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML`: `APPLICABILITY_LIMITED`.
- `ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML`: `APPLICABILITY_LIMITED`.
- `ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML`: `APPLICABILITY_LIMITED`.

Next: `INDEPENDENT_AUDIT`
