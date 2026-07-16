# Figure -> Script -> Input Data -> Paper Claim Mapping

This file records the current v0.13 DOCX figure numbering. The authoritative current manuscript contains figures through Fig. 6-6; there is no current Fig. 6-7 in the DOCX captions extracted during this audit.

| Figure | Current DOCX caption / use | Script or source | Input data | Paper claim supported | Status | Audit note |
|---|---|---|---|---|---|---|
| Fig. 1-1 | Paper method framework | `v13_export_docx_and_validate.py` mapping to `fig_v08_01_overall_backend_framework_cn.png` | Conceptual figure | Backend boundary and processing chain | Pass | Conceptual only, not statistical evidence. |
| Fig. 2-1 | Cylindrical-array beamspace ML model | `v13_export_docx_and_validate.py` mapping to restored v5 figure | Conceptual geometry / signal model | `Y`, `W^H Y`, `G=W^H A_cyl` | Risk | Formula should reflect or explain the code's double-path phase factor. |
| Fig. 3-1 | Controlled pair2d parameterization | `v08_redraw_result_figures_matlab_default.m` / `draw_pair2d_parameterization` | Script-internal schematic data | Center/separation/orientation geometry | Pass | Matches code orientation mapping. |
| Fig. 3-2 | Controlled pair2d DML flow | `v13_export_docx_and_validate.py` mapping to `fig_v08_03_pair2d_dml_flow_cn.png` | Conceptual flow | Candidate generation -> DML argmax | Pass | Conceptual only. |
| Fig. 4-1 | W selection logic | `v13_export_docx_and_validate.py` mapping to `fig_v08_04_w_selection_logic_cn.png` | Conceptual flow + Step11.2 metrics | Why greedy_combined_B7 is recommended | Pass | The numerical claim is supported by Step11.2 keypoints. |
| Fig. 5-1 | Low-complexity search framework: fixed topK3 and C05 | `v13_export_docx_and_validate.py` mapping to `fig_v08_05_coarse_to_fine_flow_cn.png` | Conceptual flow | Fixed topK3 and C05 relationship | Pass | Current DOCX uses Fig. 5-1 for both fixed topK3 and C05 relation. |
| Fig. 5-2 | Canonical cache direct/cached mechanism | `v13_export_docx_and_validate.py` mapping to `fig_v08_11_cache_mechanism_cn.png` | Conceptual flow + Step11.6 metrics | Direct/cached manifold equivalence boundary | Pass | This replaces older manifest entries that had cache as Fig. 5-5. |
| Fig. 6-1 | Common-el, controlled pair2d, and full4D comparison | `v08_redraw_result_figures_matlab_default.m` / `draw_model_comparison` | `step11_1_full4d_comparison_keypoints.csv`; summary CSV for common-el candidate reality | Pair2d matches full4D success in recorded scenarios with lower cost | Needs redraw | Script reads pair2d/full4D metrics but hardcodes common-el candidate proxy as `18000`; Step11.1 summary gives common-el `mean_num_pairs=7905`. |
| Fig. 6-2 | W selection and B-budget comparison | `v08_redraw_result_figures_matlab_default.m` / `draw_w_selection_budget` | Step11.2 W-selection and B-budget summary CSVs | `greedy_combined_B7` recommended; larger B not monotonic | Pass | Values are traceable. Keep claim scoped to current beam pool and recorded scenarios. |
| Fig. 6-3 | Full fine vs fixed topK3 coarse-to-fine | `v08_redraw_result_figures_matlab_default.m` / `draw_coarse_to_fine` | `step11_3_final_key_metrics.csv` | Candidate count reduced from 131461 to 19161.9 with full-grid match 1 | Pass | Script reads final key metrics. |
| Fig. 6-4 | C05 candidate compression and search consistency | `v08_redraw_result_figures_matlab_default.m` / `draw_c05_policy_curve` | `step11_5_stage2_policy_summary.csv`; hardcoded values from `step11_5_stage2_keypoints.csv` | C05 reduces candidate count versus fixed topK3 and preserves safety checks | Risk | Numbers are supported but plotting script hardcodes fixed/adaptive candidates and safety values. Regenerate after reading keypoints directly. |
| Fig. 6-5 | Direct/cached equivalence and runtime decomposition | `v08_redraw_result_figures_matlab_default.m` / `draw_cache_backend_runtime` | Step11.6 runtime summary; Step11.7 runtime trial/summary | Cached lookup preserves output and reduces runtime | Risk | Runtime values are read; consistency vector is hardcoded as `[1,1,1,...]` though Step11.6/7 keypoints support these rates. |
| Fig. 6-6 | C05 representative case and boundary analysis | `v08_redraw_result_figures_matlab_default.m` / `draw_case_boundary_summary` | `v07_likelihood_surface_easy_case.csv`, `v07_likelihood_surface_topk_and_refine.csv`, `v07_representative_backend_outputs.csv` | Explain C05 behavior and boundary cases | Risk | Correct only as a representative/case figure. It must not be cited as main statistical evidence. |

## Current Figure Number Drift

| Old or stale manifest item | Current status |
|---|---|
| Fig. 5-2 as C05 adaptive budget decision flow | Current DOCX Fig. 5-2 is cache direct/cached mechanism. C05 relation is in Fig. 5-1 and Fig. 6-4. |
| Fig. 5-5 cache mechanism | No longer current; cache concept is Fig. 5-2. |
| Fig. 6-5 three-case estimation and Fig. 6-6 error vectors | These older separate v08 figures were not inserted into the v0.13 DOCX; their role is merged into current Fig. 6-6. |
| Fig. 6-7 cache/backend runtime | No current Fig. 6-7 exists; cache/backend runtime is current Fig. 6-5. |
| `fig_v08_07` through `fig_v08_10` | Validation JSON says these older v08 figures are not inserted. |

## Figure Redraw / Regeneration Queue

| Priority | Figure | Action |
|---|---|---|
| P0 | Fig. 6-1 | Replace hardcoded common-el candidate proxy with a traceable value from Step11.1 summary/keypoints, then regenerate. |
| P1 | Fig. 6-4 | Read fixed/adaptive candidates and safety values from `step11_5_stage2_keypoints.csv` instead of hardcoding, then regenerate. |
| P1 | Fig. 6-5 | Read same-estimate/same-policy/same-score metrics from Step11.6/7 keypoints instead of hardcoding, then regenerate. |
| P2 | Fig. 6-6 | Keep only if caption and text clearly say representative/boundary case; redraw from newer representative outputs if it is promoted to main evidence. |
