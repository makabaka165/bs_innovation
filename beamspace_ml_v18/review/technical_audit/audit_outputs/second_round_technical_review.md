# Second-Round Technical Review

Audit date: 2026-06-25

Scope: check consistency across the manuscript, equations, figures, MATLAB code, and result data. This review does not polish writing, redesign the paper structure, or invent missing experiment results.

Primary audited materials:

- `E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/10_tech_audit/paper/current_manuscript.docx`
- `E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/10_tech_audit/code_manifest.md`
- `E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/10_tech_audit/figure_manifest.md`
- Original Step11 code under `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps`
- Paper figure-generation code under `E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/03_paper_visual_demo_code`

## One-Page Verdict

The main evidence chain is mostly consistent: controlled pair2d, W selection, fixed topK3, C05 adaptive budget, canonical cache, and final cached backend all have traceable MATLAB code and CSV support. The paper's boundary wording is also mostly disciplined: it does not claim full FPGA deployment, complete real-time radar closure, universal C05 safety, or natural ILL_CONDITIONED triggering.

The biggest technical inconsistency is the steering-vector formula: the manuscript writes the standard `exp(j 2*pi/lambda p^T u)` form, while the actual Step11 code uses a configurable phase factor and the default experiment config sets `spatialPhaseFactor=2` for a double-path phase model. The biggest figure inconsistency is Fig. 6-1: its plotting script hardcodes the common-el candidate proxy as `18000`, while the Step11.1 summary rows show common-el `mean_num_pairs=7905`.

## Confirmed Consistent Items

| Item | Evidence | Status |
|---|---|---|
| DML score formula | `beamspace_dml_score.m` computes `P=G/(G'*G+reg*I)*G'` and `score=real(trace(P*(Z*Z')))`. | Pass |
| Beamspace dimensions | Step11.7 direct and cached backends compute `Z=context.W'*validation.Y`; context metadata records `B=size(W,2)` and `N_elements=size(W,1)`. | Pass |
| Controlled pair2d orientation | `make_el_pair_list_degree_based.m` maps `orientation=+1` to `el1=center-sep/2`, `el2=center+sep/2`, and `orientation=-1` to the reversed order. | Pass |
| Common-el and full4D roles | Current manuscript calls common-el a baseline and full4D a local upper-bound reference, not the deployed/default algorithm. | Pass |
| Step11.1 main numbers | `step11_1_full4d_comparison_keypoints.csv`: pair2d success 1, full4D success 1, common-el success 0.5625, full4D/pair2d ratio 3.9589. | Pass |
| Step11.2 W recommendation | `step11_2_b_budget_keypoints.csv`: recommended strategy `greedy_combined`, B=7, success 1, RMSE about 0.0991; high B can worsen success. | Pass |
| Step11.3 fixed topK3 | `step11_3_final_key_metrics.csv`: full fine candidates 131461, fixed topK3 candidates 19161.9, ratio 6.8605, full-grid match 1, topK miss 0, boundary hit 0. | Pass |
| C05 role | C05 code computes likelihood-landscape features and selects topK/window/confidence; manuscript says it does not change DML score or W. | Pass |
| Step11.5 C05 numbers | `step11_5_stage2_keypoints.csv`: validation fixed/adaptive candidates 18558/13242.6, ratio 0.713579, full-grid match 1, topK miss 0, boundary hit 0. | Pass |
| ILL_CONDITIONED boundary | Stage3 final recommendation states real stress did not naturally trigger ILL_CONDITIONED; manuscript reports only guard-probe validation. | Pass |
| Step11.6 cache equivalence | `step11_6_keypoints.csv`: max relative G error 3.2267e-14, same estimate 1, same policy 1, cache miss 0, memory 2.0815 MB. | Pass |
| Step11.7 final backend | `step11_7_keypoints.csv`: direct/cached estimate, policy, and score rates all 1; max score diff about 8.15e-16; runtime reduction 0.6184. | Pass |
| Current figure numbering in DOCX | Extracted captions show results figures Fig. 6-1 through Fig. 6-6 only. | Pass |

## Inconsistencies

| Priority | Issue | Evidence | Required fix |
|---|---|---|---|
| P0 | Steering-vector formula omits code's double-path phase factor. | `build_cyl_steering_vec.m` uses `phase_factor*2*pi/lambda`; `sim_cfg.m` sets `cfg.beam.spatialPhaseFactor=2`; manuscript formula shows only `2*pi/lambda`. | Either add the factor to the formula or explicitly state that the printed formula is a normalized one-way convention while experiments use double-path phase. |
| P0 | Fig. 6-1 common-el candidate proxy is unsupported. | `draw_model_comparison` uses `comp=[18000, pair2d_metric, full4d_metric]`; Step11.1 summary rows show common-el `mean_num_pairs=7905`. | Fix script and regenerate Fig. 6-1. |
| P1 | `figure_manifest.md` is stale relative to current DOCX. | Current DOCX has Fig. 6-5 as cache/runtime and Fig. 6-6 as case/boundary; there is no current Fig. 6-7. | Update manifest to current numbering before the next audit round. |
| P1 | Fig. 6-4 uses hardcoded candidate/safety values. | `draw_c05_policy_curve` hardcodes `fixedMean=18558`, `adaptiveMean=13242.6`, `safety=[1,0,0]`; values are traceable to Step11.5 keypoints. | Read values from `step11_5_stage2_keypoints.csv` and regenerate. |
| P1 | Fig. 6-5 hardcodes consistency rates. | `draw_cache_backend_runtime` reads runtime but sets `consistency=[1,1,1,...]`; same rates exist in Step11.6/7 keypoints. | Read consistency metrics from keypoints and regenerate. |
| P2 | Representative v07 data remain in current Fig. 6-6. | Fig. 6-6 uses `v07_likelihood_surface_*` and `v07_representative_backend_outputs.csv`. | Accept only as case/boundary explanation; do not cite it as statistical evidence. |

## Fix Status After Grill-Me Revision

Revision date: 2026-06-25

| Original issue | Fix applied | Verification |
|---|---|---|
| Steering-vector formula omitted the double-path phase factor. | Updated `02_manuscript/full_manuscript_v0.13_形式清稿.md` to define `eta_rt=2` and include `eta_rt * 2*pi/lambda` in the steering-vector exponent. Regenerated DOCX and copied it to `10_tech_audit/paper/current_manuscript.docx`. | DOCX text extraction confirms the new double-path formula and explanation are present. |
| Fig. 6-1 hardcoded common-el candidate proxy as `18000`. | Updated `draw_model_comparison` to read Step11.1 summary CSV and compute common-el `mean_num_pairs` from `model_mode=common_el_restricted`. Regenerated Fig. 6-1. | Visual check shows common-el candidate proxy is now about `0.79 x 10^4`, consistent with `7905`, rather than `18000`. |
| Fig. 6-4 hardcoded fixed/adaptive candidate counts and safety rates. | Updated `draw_c05_policy_curve` to read `step11_5_stage2_keypoints.csv`; also fixed category order for safety checks and policy distribution. Regenerated Fig. 6-4. | Visual check shows fixed/adaptive candidates, ratio, full-grid/topK/boundary rates, and policy distribution render in the intended order. |
| Fig. 6-5 hardcoded consistency rates. | Updated `draw_cache_backend_runtime` to read Step11.6/Step11.7 keypoints for same-estimate, same-policy, same-score, and max score difference. Regenerated Fig. 6-5. | Visual check shows same-estimate/policy/score at 1 and max score diff at the small tail of the log axis. |
| `figure_manifest.md` was stale. | Updated manifest to current v0.13 numbering: Fig. 6-5 is cache/runtime, Fig. 6-6 is representative boundary case, no current Fig. 6-7. | Export validation still reports figure order OK for chapters 3/5/6 and no missing images. |

## Unverified Items

| Item | Why still unverified | Next action |
|---|---|---|
| Beam-index smoothing MUSIC fairness | Step7 path is located, but this pass did not audit its window, SNR, target conditions, or compute budget against Step11. | Run a separate baseline fairness audit before using MUSIC as a strong comparative claim. |
| Complete SNR/rho/beta sweep coverage | Key metrics confirm selected scenarios, but a full coverage table was not generated in this pass. | Produce a sweep manifest from all Step11 trial CSVs. |
| Statistical variance / confidence intervals | Many reported values are point estimates or small-sample summaries; the manuscript does not yet expose variance consistently. | Add seed/std/CI where available, especially for main comparison and W/B-budget claims. |
| Exact DOCX equation layout | Text and Markdown manuscript were searched; equation layout in Word was not visually redlined equation-by-equation. | Render/check equations if formula formatting matters for submission. |
| Current generated PNG visual fidelity | Scripts and CSVs were audited, but the actual PNGs were not visually re-rendered and pixel-checked in this pass. | Re-run figure script after fixes and inspect exported PNGs. |

## Missing Materials

| Missing / incomplete material | Impact |
|---|---|
| No current wrappers named `run_step11_main.m`, `run_pair2d_dml.m`, `plot_fig6_1_model_comparison.m`, or `plot_fig6_2_W_budget.m`. | Existing manifests must keep mapping to actual split scripts/functions instead of example names. |
| No authoritative Word-exported PDF in `paper/`; current PDF is an audit-index PDF. | Use DOCX as layout authority. Do not infer final page layout from the audit PDF. |
| No consolidated metric-trace CSV across Step11.1/2/3/5/6/7. | The evidence exists, but future reviewers must chase several keypoint CSVs. |
| No complete baseline fairness document for Step7 MUSIC. | MUSIC baseline claims should remain tentative. |
| No explicit policy-threshold provenance table generated from Step11.5 config CSV in this pass. | C05 threshold text is plausible and searchable, but a formal trace table would reduce reviewer risk. |

## Figures That Need Redraw Or Regeneration

| Figure | Action | Reason |
|---|---|---|
| Fig. 6-1 | Redrawn after script fix. | Common-el candidate proxy now comes from Step11.1 summary instead of hardcoded `18000`. |
| Fig. 6-4 | Redrawn after script fix. | Candidate and safety values now come from Step11.5 keypoints. |
| Fig. 6-5 | Redrawn after script fix. | Consistency values now come from Step11.6/7 keypoints. |
| Fig. 6-6 | Redraw only if promoted to main evidence. | It uses v07 representative data; acceptable for case explanation, not for a statistical claim. |

## Conclusions To Downgrade Or Delete

| Claim wording to avoid | Safer supported wording |
|---|---|
| Controlled pair2d is equivalent to full4D. | In the recorded local comparison scenarios, controlled pair2d reaches the same best joint success as the local full4D upper-bound reference. |
| `greedy_combined_B7` is the optimal W. | Under the current beam pool, scenario set, and backend estimator, `greedy_combined_B7` is the recommended W. |
| C05 is safe in general. | In Step11.5 validation, C05 keeps full-grid match 1, topK miss 0, and boundary hit 0 while reducing candidate count. |
| ILL_CONDITIONED is validated by real natural triggering. | ILL_CONDITIONED was not naturally triggered in the current real-search stress; only its guard-probe logic passed. |
| Cache is generally equivalent for arbitrary grids. | Cache equivalence is shown for shared-center canonical local order with exact-grid lookup, matching W and element ordering. |
| Runtime reduction proves real-time deployment. | MATLAB backend timing shows reduced repeated manifold construction/backend runtime; FPGA and full real-time closed loop remain future work. |

## Experiments To Supplement

| Need | Concrete experiment / audit |
|---|---|
| Baseline fairness | Re-run or audit beam-index smoothing MUSIC with matched SNR, local window, target conditions, and evaluation tolerance. |
| Robustness beyond recorded scenarios | Sweep SNR, coherence `rho`, amplitude ratio `beta`, azimuth/elevation separation, and front-end bias beyond the current valid range. |
| Variance reporting | Add seed-level mean/std or confidence intervals for main comparison, W selection, fixed topK3, and C05. |
| Boundary and failure analysis | Keep strong-coherence, weak-secondary, low-SNR, near-common-el, and false-high-like cases as explicit subgroups. |
| Cache fallback boundary | Audit cache miss, out-of-grid, and no-interpolation behavior as separate engineering boundary cases. |
| Figure reproducibility | After script fixes, regenerate PNGs and record source CSV, script hash or timestamp, and output image path. |

## Current Review Status

| Category | Status |
|---|---|
| Main claim evidence chain | Improved after formula and figure fixes; remaining risk is baseline fairness and representative-case scope. |
| Formula-code consistency | Pass for steering-vector phase convention after adopting the double-path formula. |
| Figure/data consistency | Pass for Fig. 6-1/6-4/6-5 source-data linkage after script hardening and redraw; Fig. 6-6 remains representative-only. |
| Baseline fairness | Unknown for MUSIC; pass for common-el/pair2d/full4D role separation. |
| Boundary wording | Pass in current manuscript, keep it restrained. |
| Reproducibility | Risk until metric trace and figure regeneration records are consolidated. |
