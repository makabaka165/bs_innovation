# Grill-Me Fix Log

Date: 2026-06-25

User decision: use the double-path steering-vector formula in the manuscript.

## Changed Files

| File | Change |
|---|---|
| `02_manuscript/full_manuscript_v0.13_形式清稿.md` | Added `eta_rt=2` double-path phase factor to the cylindrical steering-vector definition and explanatory text. |
| `03_paper_visual_demo_code/v0_12_structure_refine/common/v08_redraw_result_figures_matlab_default.m` | Removed key hardcoded values from Fig. 6-1, Fig. 6-4, and Fig. 6-5 generation; now reads source CSV/keypoints. Also fixed category order/label overlap in result figures. |
| `10_tech_audit/figure_manifest.md` | Updated figure numbering to current v0.13 DOCX: no Fig. 6-7, cache/runtime is Fig. 6-5, case/boundary is Fig. 6-6. |
| `10_tech_audit/paper/current_manuscript.docx` | Rebuilt from updated manuscript source and regenerated figures. |
| `10_tech_audit/audit_outputs/second_round_technical_review.md` | Added post-fix status table. |

## Regenerated Outputs

| Output | Verification |
|---|---|
| `09_chinese_figures/v0_12/fig_v08_13_experiment_model_comparison_cn.png` | Visual check: common-el candidate proxy now reflects Step11.1 summary scale around `7905`. |
| `09_chinese_figures/v0_12/fig_v08_15_c05_candidate_and_policy_curve_cn.png` | Visual check: values are rendered from Step11.5 keypoints; safety and policy categories are ordered. |
| `09_chinese_figures/v0_12/fig_v08_16_cache_and_backend_runtime_decomposition_cn.png` | Visual check: consistency metrics are read from Step11.6/7 keypoints; max score diff appears as the small log-scale bar. |
| `02_manuscript/beamspace_ml_paper_step11_visual_v13_20260625.docx` | Export validation: 13 media, no missing images, no duplicate captions, figure order OK. |
| `10_tech_audit/paper/current_manuscript.docx` | Copied from rebuilt DOCX after validation. |

## Validation Notes

- MATLAB figure regeneration completed without errors.
- DOCX export/validation script completed without missing images.
- DOCX text extraction confirms the double-path formula text is present.
- Full page PNG rendering via the documents renderer could not be completed because this machine does not expose `soffice`/LibreOffice. The available validation is structural DOCX validation plus direct PNG inspection of the regenerated figures.

## Remaining Boundaries

| Item | Status |
|---|---|
| Fig. 6-6 representative data | Still uses v07 representative outputs and should remain a case/boundary figure, not main statistical evidence. |
| MUSIC baseline fairness | Not fixed in this pass; still needs separate baseline fairness audit. |
| Word visual page QA | Not available without Word/LibreOffice command-line rendering. |
