# Figure Manifest

## 图表台账

| 图号 | 论文中用途 | 对应脚本 | 输入数据 | 想证明什么 | 是否主证据 | 状态 |
|---|---|---|---|---|---|---|
| 图 1-1 | 论文后端方法整体框架 | `03_paper_visual_demo_code/v0_12_structure_refine/common/v08_generate_figures_and_manuscript.py` 或相关生成脚本 | 概念/流程示意 | 说明本文边界：局部前端输入到后端精估计 | 否 | 待复核 |
| 图 2-1 | 圆柱阵 beamspace ML 模型 | AI/绘图脚本生成，旧版本见 `09_chinese_figures/v5_restored_v3_boxes/fig_cylindrical_beamspace_ml_model_cn_v5.png` | 概念/几何示意 | 说明 `Y=A_cyl S+N`、`Z=W^H Y`、`G=W^H A_cyl` | 否 | 待复核 |
| 图 3-1 | controlled pair2d 参数化 | `03_paper_visual_demo_code/v0_12_structure_refine/common/v08_redraw_result_figures_matlab_default.m` / `draw_pair2d_parameterization` | 脚本内示意数据 | 解释 center、az_sep、el_sep、q 与 common-el/full4D 差异 | 否 | 待复核 |
| 图 3-2 | controlled pair2d DML 流程 | `03_paper_visual_demo_code/v0_12_structure_refine/common/v08_generate_figures_and_manuscript.py` | 概念流程 | 说明候选生成、`G=W^H A`、DML argmax 输出 | 否 | 待复核 |
| 图 4-1 | W 选择逻辑 | `03_paper_visual_demo_code/v0_12_structure_refine/common/v08_generate_figures_and_manuscript.py` | 概念流程 + Step11.2 指标 | 说明 greedy_combined_B7 推荐逻辑 | 否 | 待复核 |
| 图 5-1 | low-complexity search framework：fixed topK3 与 C05 关系 | `03_paper_visual_demo_code/v0_12_structure_refine/common/v13_export_docx_and_validate.py` 插入 `fig_v08_05_coarse_to_fine_flow_cn.png` | 概念流程 | 说明 fixed topK3 与 C05 自适应预算的层次关系 | 否 | 已按 v0.13 DOCX 复核 |
| 图 5-2 | canonical cache direct/cached 机制对照 | `03_paper_visual_demo_code/v0_12_structure_refine/common/v13_export_docx_and_validate.py` 插入 `fig_v08_11_cache_mechanism_cn.png` | 概念流程 + Step11.6 指标 | 说明 direct manifold vs cached lookup | 否 | 已按 v0.13 DOCX 复核 |
| 图 6-1 | 主算法有效性 | `03_paper_visual_demo_code/v0_12_structure_refine/common/v08_redraw_result_figures_matlab_default.m` / `draw_model_comparison` | Step11.1 `step11_1_full4d_comparison_keypoints.csv` + `step11_1_full4d_comparison_summary.csv` | pair2d 接近 full4D 上界，优于 common-el | 是 | 已修正脚本：common-el candidate proxy 从 summary 读取，不再硬编码 18000 |
| 图 6-2 | W 选择必要性 | 同上 / `draw_w_selection_budget` | Step11.2 W selection / B-budget CSV | greedy_combined_B7 在精度和复杂度间折中较优 | 是 | 待核对输入列名和数值 |
| 图 6-3 | fixed topK3 搜索加速 | 同上 / `draw_coarse_to_fine` | Step11.3 final key metrics | full fine 与 fixed topK3 一致，候选数降低约 6.86 倍 | 是 | 已定位，待复算 |
| 图 6-4 | C05 候选数与 policy 分布 | 同上 / `draw_c05_policy_curve` | Step11.5 `step11_5_stage2_keypoints.csv` + `step11_5_stage2_policy_summary.csv` | C05 相对 fixed topK3 进一步降低候选数且保持安全指标 | 是 | 已修正脚本：候选数和安全指标从 keypoints 读取 |
| 图 6-5 | cache/backend runtime 分解 | 同上 / `draw_cache_backend_runtime` | Step11.6 runtime/keypoints；Step11.7 runtime/keypoints/trial | cache 不改变估计并降低 repeated manifold/backend runtime | 是 | 已修正脚本：一致性指标从 keypoints 读取；v0.13 无图 6-7 |
| 图 6-6 | C05 代表性样本与边界案例分析 | 同上 / `draw_case_boundary_summary`，输出 `fig_v12_06_case_boundary_summary_cn.png` | `v07_representative_backend_outputs.csv` + likelihood surface CSV | 展示边界样本和风险，不作为主统计证据 | 否 | 已按 v0.13 DOCX 复核；仍需标注为代表性/边界案例 |

## 已知风险

| 风险 | 说明 | 建议 |
|---|---|---|
| 图号漂移 | 已确认 v0.13 DOCX 结果图到图 6-6；cache/backend runtime 为图 6-5，不再存在图 6-7 | 后续台账以 `v13_export_docx_and_validate.py` 的 `FIG_BY_NO` 为准 |
| 输入数据年代混用 | 部分代表性图仍读取 `step11_visual_v07_outputs` | 将代表性图标注为“过程展示/案例图”，不要作为主统计证据 |
| 脚本内硬编码 fallback | `draw_model_comparison` 等函数内有 fallback 数值 | 审计时应确认实际 CSV 存在且字段读取成功，避免 fallback 被静默使用 |
| 概念图数值标注 | W 维度、RMSE、cache memory 等概念图中的数字必须回溯 Step11 CSV/日志 | 逐项在 `audit_outputs` 中记录来源 |
