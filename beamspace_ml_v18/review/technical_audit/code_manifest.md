# Code Manifest

## 路径约定

- 原始算法代码根目录：`E:/matlab_code/bishe_quanxi/stepwise_signal_model`
- 原始 Step11 证据链目录：`E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps`
- 当前论文项目目录：`E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper`

## 主入口脚本

| 论文/审计称呼 | 实际代码路径 | 用途 | 状态 |
|---|---|---|---|
| Step11.1 主算法有效性证据 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/stage7_final_paper_evidence_summary/run_stage7_final_paper_evidence_summary.m` | 汇总 common-el、controlled pair2d、full4D、coherence stress 等证据 | 已定位 |
| Step11.2 W/B-budget 证据 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_2_beamspace_w_design/stage3_b_budget_strategy_tradeoff/run_stage3_b_budget_strategy_tradeoff.m` | 生成 W 选择与 B-budget tradeoff | 已定位 |
| Step11.3 搜索加速证据 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_3_beamspace_ml_search_acceleration/stage4_final_search_acceleration_evidence_summary/run_stage4_final_search_acceleration_evidence_summary.m` | 汇总 full fine vs fixed topK3 coarse-to-fine | 已定位 |
| Step11.5 C05 自适应预算 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_5_likelihood_uncertainty_adaptive_beamspace_ml_search/run_step11_5_stage2_policy_tuning.m` | C05 policy tuning 与 fixed topK3 对照 | 已定位 |
| Step11.5 多 seed/guard 复验 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_5_likelihood_uncertainty_adaptive_beamspace_ml_search/run_step11_5_stage3_supplementary_rechecks.m` | Metkl=30 复验、ILL_CONDITIONED guard probe | 已定位 |
| Step11.6 cache 验证 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_6_shared_center_rotatable_beamspace_manifold_cache/run_step11_6_shared_center_manifold_cache_validation.m` | canonical beamspace manifold cache 等价性与 runtime | 已定位 |
| Step11.7 最终后端入口 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_7_final_cached_c05_beamspace_ml_route/run_step11_7_final_cached_c05_beamspace_ml_route.m` | final cached C05 beamspace ML route | 已定位 |
| 用户示例名 `run_step11_main.m` | 未发现同名文件 | 可能对应 Step11.7 或 Step11.1/2/3 汇总入口，需要人工确认命名映射 | 待确认 |
| 用户示例名 `run_pair2d_dml.m` | 未发现同名文件 | 当前实现拆在 `search_pair_grid_el_separation_precomputed.m`、`search_pair2d_*` 和 backend 包装中 | 待确认 |

## 核心函数

| 功能 | 实际代码路径 | 说明 | 状态 |
|---|---|---|---|
| 全局仿真配置 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/core/config/sim_cfg.m` | `fc=10e9`、`lambda=c/fc`、`Naz=192`、`Nel=32`、`R=0.4`、`dz=17e-3`、`azSectorCenter=8`、`elSectorCenter=10` | 已定位 |
| 圆柱阵几何/工作子阵 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/core/array/arr_cyl.m` | 生成全阵和围绕当前方位中心的工作子阵坐标 | 已定位 |
| 圆柱阵导向矢量 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/build_cyl_steering_vec.m` | 对应论文 `a_cyl(az,el)` | 已定位 |
| 圆柱阵双目标流形 common-el | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/build_cyl_pair_manifold_common_el.m` | common-el baseline 流形 | 已定位 |
| 圆柱阵双目标流形 pair2d | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/build_cyl_pair_manifold_el_separated.m` | controlled pair2d 候选流形的基础构造 | 已定位 |
| DML 评分 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/beamspace_dml_score.m` | 对应 beamspace DML 投影评分 | 已定位 |
| common-el 搜索 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/search_pair_grid_common_el_precomputed.m` | common-el baseline 搜索 | 已定位 |
| controlled pair2d 搜索 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/search_pair_grid_el_separation_precomputed.m` | controlled pair2d/full-grid 相关搜索 | 已定位 |
| full4D 搜索 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/search_pair_grid_full4d_precomputed.m` | local full4D upper-bound | 已定位 |
| W 候选池 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_2_beamspace_w_design/common/build_existing_2d_beam_pool.m` | 生成当前二维 beam pool | 已定位 |
| greedy W 选择 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_2_beamspace_w_design/common/select_w_greedy_from_pool.m` | 支持 greedy_projection / greedy_lowcorr / greedy_combined | 已定位 |
| B-budget sweep | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_2_beamspace_w_design/common/build_w_cases_for_b_budget_sweep.m` | 构造不同 B 的 W cases | 已定位 |
| fixed topK3 coarse-to-fine | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_3_beamspace_ml_search_acceleration/common/search_pair2d_coarse_to_fine.m` | 粗到细搜索主逻辑 | 已定位 |
| coarse topK | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_3_beamspace_ml_search_acceleration/common/search_pair2d_coarse_grid_topk.m` | coarse grid topK 候选 | 已定位 |
| topK local refine | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_3_beamspace_ml_search_acceleration/common/search_pair2d_local_refine_from_topk.m` | 从 topK 候选进入细化窗口 | 已定位 |
| C05 likelihood features | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_5_likelihood_uncertainty_adaptive_beamspace_ml_search/common/compute_likelihood_landscape_features_v2.m` | 提取 H_norm、gap、boundary/condition risk 等特征；旧版 `compute_likelihood_landscape_features.m` 仍存在 | 已定位 |
| C05 policy 选择 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_5_likelihood_uncertainty_adaptive_beamspace_ml_search/common/select_adaptive_topk_window_policy_v2.m` | 从特征到 EASY/NORMAL/SCORE_AMBIGUOUS/BOUNDARY/ILL_CONDITIONED | 已定位 |
| C05 固定推荐配置 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_5_likelihood_uncertainty_adaptive_beamspace_ml_search/common/build_step11_5_stage3_selected_c05_config.m` | 固定 Stage2 selected C05：`C05_easy_very_aggressive` | 已定位 |
| canonical cache 构建 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_6_shared_center_rotatable_beamspace_manifold_cache/common/build_step11_6_canonical_beamspace_cache.m` | 构造 `G_cache(delta_az,el)` | 已定位 |
| cache lookup | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_6_shared_center_rotatable_beamspace_manifold_cache/common/lookup_step11_6_beamspace_cache.m` | exact-grid lookup | 已定位 |
| cached search | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_6_shared_center_rotatable_beamspace_manifold_cache/common/search_pair2d_adaptive_c05_cached.m` | cached C05 pair2d 搜索 | 已定位 |
| final backend | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_7_final_cached_c05_beamspace_ml_route/common/step11_7_final_cached_c05_beamspace_ml_backend.m` | Step11.7 对外后端封装 | 已定位 |
| direct reference backend | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_7_final_cached_c05_beamspace_ml_route/common/step11_7_direct_reference_c05_backend.m` | cached/direct 一致性参考 | 已定位 |

## 画图脚本

| 图件/用途 | 实际代码路径 | 输入数据 | 状态 |
|---|---|---|---|
| v0.12/v0.13 结果图重画总入口 | `E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/03_paper_visual_demo_code/v0_12_structure_refine/common/v08_redraw_result_figures_matlab_default.m` | 原始 Step11 CSV + v07 representative CSV | 已定位 |
| 图 6-1 模型对比 | 同上函数 `draw_model_comparison` | Step11.1 keypoints | 已定位 |
| 图 6-2 W/B-budget | 同上函数 `draw_w_selection_budget` | Step11.2 W selection / B-budget CSV | 已定位 |
| 图 6-3 coarse-to-fine | 同上函数 `draw_coarse_to_fine` | Step11.3 final key metrics | 已定位 |
| 图 6-4 C05 policy | 同上函数 `draw_c05_policy_curve` | Step11.5 policy summary + v07 representative outputs | 已定位 |
| 图 6-5 三案例估计 | 同上函数 `draw_three_case` | v07 representative backend outputs | 已定位 |
| 图 6-6 误差向量 | 同上函数 `draw_error_vectors` | v07 representative backend outputs | 已定位 |
| 图 6-7 cache/backend runtime | 同上函数 `draw_cache_backend_runtime` | Step11.6/Step11.7 runtime summary/trial | 已定位 |
| 用户示例 `plot_fig6_1_model_comparison.m` | 未发现同名文件 | 当前以 `v08_redraw_result_figures_matlab_default.m` 内部函数实现 | 待确认命名映射 |
| 用户示例 `plot_fig6_2_W_budget.m` | 未发现同名文件 | 当前以 `v08_redraw_result_figures_matlab_default.m` 内部函数实现 | 待确认命名映射 |

## 需要重点核查的代码-论文一致性

| 项 | 需要核查的问题 | 当前状态 |
|---|---|---|
| DML 公式 | `beamspace_dml_score.m` 是否与论文投影矩阵/目标函数符号完全一致 | 待逐行审 |
| pair2d 参数化 | 论文中的 center、az_sep、el_sep、orientation `q` 是否与搜索代码候选枚举一致 | 待逐行审 |
| W 维度 | 论文写法 `W in C^{M x B}` 与代码 `W` 形状、`Z=W'Y` 是否一致 | 待审 |
| C05 | 论文中 `U_search`/`U_confidence` 的定义是否与 `compute_likelihood_landscape_features` 和 policy 代码一致 | 待审 |
| cache | 论文的 shared-center rotational equivalence 是否与 `build_step11_6_canonical_geometry` / cache lookup 假设一致 | 待审 |
| 结果图 | v0.12 绘图脚本是否读取了最新原始结果，而不是旧 v07/v10 中间数据 | 待审 |
