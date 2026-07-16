# v18 MATLAB Figure Code

This folder collects the MATLAB plotting code in the current paper project that is relevant to the MATLAB-generated figures used by the v18 manuscript.

Extracted-package scope note:

- The scripts were copied from the current paper project and retain their original numerical and plotting logic.
- Their path setup was changed only in this extracted package: scripts now locate the package root from `mfilename('fullpath')`.
- Required Step11 engineering source and recorded results are included under `../../source/stepwise_signal_model`.
- Required v07 representative-case CSV files are included under `../../evidence/visual_v07/csv`.
- Generated files are written below `outputs/`; the original paper and engineering projects are not modified.

## Copied MATLAB Files

| Copied file | Original source | Main v18 figure mapping |
|---|---|---|
| `single_figure_scripts/run_generate_pair2d_parameterization_demo.m` | `03_paper_visual_demo_code/run_generate_pair2d_parameterization_demo.m` | 图 3-3 / `fig_3_3.png` |
| `single_figure_scripts/run_generate_w_selection_mechanism_demo.m` | `03_paper_visual_demo_code/run_generate_w_selection_mechanism_demo.m` | 图 4-2 / `fig_4_2.png` |
| `single_figure_scripts/run_generate_c05_adaptive_budget_mechanism_demo.m` | `03_paper_visual_demo_code/run_generate_c05_adaptive_budget_mechanism_demo.m` | 图 5-2 / `fig_5_2_c05_adaptive_budget_mechanism_cn.png` |
| `chapter6_result_redraw/v08_redraw_result_figures_matlab_default.m` | `03_paper_visual_demo_code/v0_12_structure_refine/common/v08_redraw_result_figures_matlab_default.m` | 图 6-1 至图 6-6；同时含图 3-1 的 MATLAB 候选绘图函数 |

## Per-Figure Entrypoints

The original current-project plotting code is concentrated into four MATLAB source files, so this folder also provides one wrapper per v18 MATLAB-related figure under `per_figure_entrypoints/`.

These wrappers are intentionally thin: they call the copied source scripts above. The engineering source is stored separately in this package so that plotting and algorithm ownership remain clear.

| Entrypoint | Figure |
|---|---|
| `per_figure_entrypoints/plot_v18_fig_3_1_pair2d_parameterization_candidate.m` | 图 3-1 MATLAB candidate |
| `per_figure_entrypoints/plot_v18_fig_3_3_pair2d_dml_demo.m` | 图 3-3 |
| `per_figure_entrypoints/plot_v18_fig_4_2_w_selection_mechanism.m` | 图 4-2 |
| `per_figure_entrypoints/plot_v18_fig_5_2_c05_adaptive_budget_mechanism.m` | 图 5-2 |
| `per_figure_entrypoints/plot_v18_fig_6_1_model_comparison.m` | 图 6-1 |
| `per_figure_entrypoints/plot_v18_fig_6_2_w_selection_budget.m` | 图 6-2 |
| `per_figure_entrypoints/plot_v18_fig_6_3_coarse_to_fine.m` | 图 6-3 |
| `per_figure_entrypoints/plot_v18_fig_6_4_c05_policy.m` | 图 6-4 |
| `per_figure_entrypoints/plot_v18_fig_6_5_cache_runtime.m` | 图 6-5 |
| `per_figure_entrypoints/plot_v18_fig_6_6_case_boundary.m` | 图 6-6 |
| `per_figure_entrypoints/run_all_v18_matlab_figure_entrypoints.m` | Run all wrappers |

## Verification Notes

The v18 Markdown and DOCX use the same 17 embedded figures. The extracted final images are in `../../paper/figures_v16_image2`; this historical folder name is retained so the v18 Markdown links remain valid.

For the copied MATLAB plotting code:

- 图 3-3 and 图 4-2 were regenerated successfully. The regenerated RGB pixels match the v18 final PNG exactly; only PNG file bytes/metadata differ.
- 图 5-2 C05 mechanism was regenerated successfully from the copied MATLAB script. It corresponds to the same MATLAB plotting code, but the v18 final PNG has different resolution/layout, so it appears to be a post-processed or resized version.
- 图 6-1 to 图 6-6 are produced by `v08_redraw_result_figures_matlab_default.m`. Re-running the current script works. 图 6-6 matches the final image at the RGB pixel level; 图 6-1 to 图 6-5 are the corresponding MATLAB result plots but the v18 final PNGs appear to have later export/post-processing differences.
- 图 3-1 is included only as a traceable MATLAB candidate inside `draw_pair2d_parameterization`; the v18 final `fig_3_1.png` is not an exact regenerated MATLAB output from the current script.

Figures not copied here are not MATLAB plotting-code figures in the current-project search result. They are conceptual/Python/AI/manual/post-processed figures rather than current-project MATLAB plotting scripts.

## Useful Run Commands

From MATLAB:

```matlab
packageRoot = 'E:\bs_innovation\beamspace_ml_v18';

cd(fullfile(packageRoot, 'fig_code', 'matlab_v18', 'single_figure_scripts'))
run_generate_pair2d_parameterization_demo
run_generate_w_selection_mechanism_demo
run_generate_c05_adaptive_budget_mechanism_demo

addpath(fullfile(packageRoot, 'fig_code', 'matlab_v18', 'chapter6_result_redraw'))
v08_redraw_result_figures_matlab_default('model_comparison')
v08_redraw_result_figures_matlab_default('w_selection')
v08_redraw_result_figures_matlab_default('coarse_to_fine')
v08_redraw_result_figures_matlab_default('c05_policy')
v08_redraw_result_figures_matlab_default('cache_runtime')
v08_redraw_result_figures_matlab_default('case_boundary')
```

To run every collected entrypoint:

```matlab
run(fullfile(packageRoot, 'fig_code', 'matlab_v18', ...
    'per_figure_entrypoints', 'run_all_v18_matlab_figure_entrypoints.m'))
```

The regenerated files are traceability outputs. They must not automatically replace the final images under `paper/figures_v16_image2`, because several v18 images include later export or post-processing changes.
