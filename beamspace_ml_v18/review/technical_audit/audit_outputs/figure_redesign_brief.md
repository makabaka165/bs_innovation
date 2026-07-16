# v0.14 图表证据链专项审查与重画建议

本轮只审查插图、表格、图周围文字和论文主张之间的关系；不修改正文，不润色语言，不重新审查全文结构。

## 读取材料

- `02_manuscript/beamspace_ml_paper_v0.14_nature写作重构稿.docx`
- `02_manuscript/full_manuscript_v0.14_nature写作重构稿.md`
- `10_tech_audit/audit_outputs/mapping_figures_scripts_data_claims.md`
- `10_tech_audit/audit_outputs/mapping_claim_formula_code_data.md`
- `10_tech_audit/CONTEXT.md`

辅助核对：

- v14 DOCX 实际含 13 张图片，顺序为图 1-1 至图 6-6。
- v14 导出映射来自 `03_paper_visual_demo_code/v0_12_structure_refine/common/v14_export_docx_and_validate.py`。
- 图像总览已生成：`10_tech_audit/audit_outputs/figure_contact_sheet_v14.png`。

## 总体判断

当前图表证据链的主线是清楚的：概念图解释局部后端边界，方法图解释 controlled pair2d、W 选择、搜索压缩与缓存机制，第6章图表提供主要实验证据，图6-6只作为代表性案例和边界说明。

主要风险不在“结果是否存在”，而在“图能否让审稿人一眼相信对应主张”。第6章多数结果图仍偏聚合柱状图，缺少分布、场景拆分、误差条、逐 trial 证据或局部放大；因此表格往往比图本身更强。若后续重画，应优先增强图6-1、图6-4、图6-5，并修正图5-1的图文错位。

## 优先级摘要

| 优先级 | 图号 | 问题 | 建议 |
|---|---|---|---|
| P0 | 无 | 未发现必须删除或会直接推翻主张的图 | 暂无 |
| P1 | 图5-1 | 图周文字声称 fixed topK3 与 C05 关系，但当前图主要只画 fixed topK3 流程 | 重画为 fixed topK3 + C05 预算分支的完整搜索框架 |
| P1 | 图6-1 | 主算法有效性的主证据，但当前是聚合柱状图，缺少场景拆分和不确定性 | 重画为“场景 x 模型”热力图 + 成本-成功率 Pareto |
| P1 | 图6-4 | C05 的主证据，但当前只给均值、比例和策略分布 | 重画为候选比例分布/CDF + policy 分层箱线图 + 安全指标矩阵 |
| P1 | 图6-5 | 缓存等价性和运行时间混在一个聚合图内，log 轴一致性面板可读性弱 | 拆成等价性误差热力图 + runtime CDF/箱线图 + 一致性摘要 |
| P2 | 图6-2 | W 选择图能支持结论，但左图策略对比容易隐藏 B 和场景差异 | 重画为 B-budget 曲线/热力图，标出 B=7 推荐点 |
| P2 | 图6-3 | 支持 fixed topK3，但图型偏摘要，缺少逐样本候选压缩分布 | 可保留；若版面允许，增加候选数 paired scatter/CDF |
| P2 | 图6-6 | 作为案例图可用，但不能升级为主统计证据 | 保留为案例/边界图，或移附录并用 stress 分布图替代主文位置 |

## 逐图审查

| 图号 | 图周围文字想表达的 claim | 实际能支撑什么 | 是否存在表达错位 | 当前类型 | 当前问题 | 建议 | 推荐图型 | MATLAB 额外保存/整理数据 |
|---|---|---|---|---|---|---|---|---|
| 图1-1 | 论文方法整体框架：前端给局部中心/窗口，后端执行 beamspace ML、搜索预算、缓存和输出；不覆盖全空域盲搜、完整前端闭环或 FPGA 实现。 | 支持“后端链路边界”和模块顺序，是概念层证据。 | 轻微错位：图内出现 final backend output / debug 之类工程接口感表达，和当前克制论文风格不完全一致。 | 流程图 / 辅助说明 | 太线性，未突出“局部双目标”和“不做全空域盲搜”的边界；未显示输入输出维度。 | 保留，但建议重画为论文级边界图。 | 流程图 + 边界框；左侧为 front-end prior，右侧为 backend estimate；下方列 exclusion。 | 不需要实验数据；建议保存一份 `backend_input_output_contract.csv`，列出输入、输出、是否本文覆盖。 |
| 图2-1 | 圆柱阵阵元域到 beamspace 的信号模型，说明 $Y$、$Z=W^HY$、$G(\Theta)=W^HA_{\mathrm{cyl}}(\Theta)$ 和 DML 评分关系。 | 支持信号流和模型变量关系。 | 有风险：正文强调双程相位 $\eta_{\mathrm{rt}}=2$，图像若未显式标注该因子，会弱化公式-代码一致性证据。 | 模型示意图 | 信息不足：缺少矩阵维度、单位、$\eta_{\mathrm{rt}}=2$、局部窗口边界。 | 重画或局部更新。 | 模型框图 + 公式标签；在 steering vector 箭头处标出 $\eta_{\mathrm{rt}}=2$。 | 不需要数值数据；建议保存 `model_symbol_dimension_table.csv` 用于图中维度标注。 |
| 图3-1 | controlled pair2d 的中心、方位分离、俯仰分离和方向变量几何含义；common-el 是退化情况，full4D 是上界参考。 | 支持 pair2d 参数化的几何解释。 | 基本一致。 | 机制示意图 | 只展示一个样例；对 $q=\pm1$、common-el 退化和 full4D 对比表达不够强。 | 保留；若重画，可加两个小 inset。 | 散点/几何示意 + inset：common-el、pair2d、full4D 候选自由度。 | 不需要实验数据；保存示意参数即可，如 center、$\Delta az$、$\Delta el$、q。 |
| 图3-2 | controlled pair2d beamspace DML 的算法流程：输入局部窗口，生成候选，构造 $G$，计算 DML，输出角度。 | 支持算法步骤的可复现流程。 | 一致。 | 流程图 | 太简略：未显示 DML 准则不变、输出是双目标角度，未显示不负责前端模型选择。 | 保留；可小修为“算法流程图”。 | 流程图。 | 不需要额外数据。 |
| 图4-1 | 面向 ML 后端的 W 选择逻辑：投影保持、低相关、条件数诊断，最后推荐 greedy_combined_B7。 | 支持 W 选择机制的设计逻辑；不直接证明 B7 实验最优。 | 轻微错位：图中出现 B=7 推荐，会让读者以为本章概念图已给出实验结论；真正证据在图6-2和表6-4。 | 流程图 / 辅助说明 | 缺少与实验指标的桥接：projection loss、corr、cond 与 success/RMSE 的关系没有在图中呈现。 | 保留；推荐把 B7 推荐移到图6-2，或在图4-1标注“selection criteria”。 | 流程图或指标三角图。 | 若重画为指标图，需要保存每个 W 的 projection_loss、mean_corr、max_corr、cond_WHW、cond_best_GHG。现有 `step11_2_w_pool_diagnostics_*` 可用。 |
| 图5-1 | 图周文字声称展示 low-complexity search framework，包括 fixed topK3 coarse-to-fine 与 C05 自适应预算关系。 | 当前实际主要支持 fixed topK3 coarse-to-fine 流程。 | 明确错位：C05 的预算决策、likelihood-landscape features、policy 到 topK/window 的映射未在图中体现。 | 流程图 / 方法机制 | 图型过简单；缺少 C05 与 fixed topK3 的关系；无法支撑“C05 只改变 topK/window、不改变 DML”的关键边界。 | 重画。 | 分支流程图：coarse scores -> landscape features -> policy -> topK/window -> local refine -> DML argmax；旁边保留 fixed topK3 baseline。 | 不需要实验结果；建议保存 C05 policy rule table：policy_name、触发条件、topK、az/el window_scale、是否边界保护。 |
| 图5-2 | canonical cache direct/cached 机制，说明 exact-grid lookup 复用 $G_{\mathrm{cache}}$，不改变 ML 评分、C05 或候选集合。 | 支持缓存机制和 direct/cached 对照；图中摘要指标可辅助说明等价性。 | 基本一致。 | 流程图 / 工程验证图 | exact-grid/no interpolation 的边界不够突出；图中数值摘要放在机制图里，容易和第6章统计证据混在一起。 | 保留；若重画，分成机制路径和适用条件两块。 | 流程图 + 条件 checklist。 | 需要保存 cache 覆盖条件：center grid、delta_az grid、el grid、W id、canonical order、cache_miss_count。现有 Step11.6 metadata 可用。 |
| 图6-1 | 主算法有效性：controlled pair2d 在记录场景中达到 local full4D 上界一致的最高联合成功率，并以较低候选复杂度完成估计；common-el 作为受限 baseline。 | 支持聚合层面的 success 和候选复杂度对比；能说明 pair2d 与 full4D 在当前记录场景下成功率一致、full4D 成本更高。 | 结论方向一致，但图本身证据强度偏弱：正文有“记录场景”限定，图却没有场景拆分，读者不易判断是否由少数场景支撑。 | 主证据图 | 信息不足：只有柱状聚合；缺少 per-scenario 成功率、RMSE、候选数、误差分布；缺少置信区间/seed 信息；右图 ratio 单独成图信息密度低。 | 重画为主证据图。 | 热力图（scenario x model joint success/RMSE）+ Pareto 图（candidate proxy vs success/RMSE）+ 小表标注 full4D/pair2d ratio。 | 现有 `step11_1_full4d_comparison_summary.csv` 可画场景热力图；若要误差条，需要额外保存 per-trial model comparison：scenario、seed、model_mode、az/el error、success flags、num_pairs、score_margin、boundary_hit。 |
| 图6-2 | W 选择与 B-budget：greedy_combined_B7 在当前波束池、场景集和后端估计器下推荐；更大 B 不必然单调提升性能。 | 支持当前 W 策略和 B-budget 趋势。 | 基本一致，但左侧策略成功率对比可能掩盖 B 和场景差异；“SVD upper bound”与工程策略最好视觉上区分。 | 主证据图 / 输入设计证据 | 图型偏摘要：策略对比、B 曲线、推荐点三块互相割裂；缺少场景分布和误差条；B=7 推荐点的理由不够直观。 | 保留或重画。 | 折线图/热力图：x=B，y=success/RMSE，不同 W 策略分色；另加 Pareto 图（projection_loss/cond vs success）。 | 现有 `step11_2_b_budget_summary.csv` 和 `step11_2_w_selection_validation_summary.csv` 可用；若要统计置信，额外保存 per-trial W sweep：method_name、B、scenario、seed、success、RMSE、projection/corr/cond 指标。 |
| 图6-3 | fixed topK3 搜索加速：相对 full fine 大幅减少候选评分，并保持 full-grid match=1、topK miss=0、boundary hit=0。 | 支持聚合层面的候选压缩和安全指标保持。 | 一致。 | 主证据图 / 搜索加速图 | 太简单：三个柱状面板即可支持当前表述，但不展示候选压缩的逐样本分布；success=1和match=1缺少样本规模视觉提示。 | 可保留；若主文版面允许，建议增强。 | Paired scatter/CDF：每个样本 full fine vs fixed topK3 候选数；旁边安全指标矩阵。 | 需要保存或整理 Step11.3 per-trial 表：scenario、seed、full_num_pairs、fixed_num_pairs、full_success、fixed_success、full_grid_match、topK_miss、boundary_hit、estimate error。 |
| 图6-4 | C05 相对 fixed topK3 进一步减少候选数，同时保持 full-grid match=1、topK miss=0、boundary hit=0，并展示策略分布。 | 支持 C05 在当前验证配置下的候选数降低和策略分布；可说明 EASY/NORMAL/SCORE_AMBIGUOUS 等策略占比。 | 结论一致，但图本身不够强：正文提到 450 个多随机种子复验，图未显示复验分布；安全指标只以三个柱子显示。 | 主证据图 / 自适应预算证据 | 信息不足：只有均值和比例；缺少 candidate ratio 分布、policy 分层、U_search/U_confidence 与策略的关系、失败/边界样本位置。 | 重画。 | CDF 或箱线图（adaptive/fixed candidate ratio）+ policy 分层箱线图 + safety flag 热力图；可加 U_search/U_confidence 散点按 policy 着色。 | 已有 `step11_5_stage2_trial.csv`、`step11_5_stage3_supp_metkl30_repeat_trial.csv`、`step11_5_stage3_supp_illcond_real_stress_trial.csv`。建议额外保存绘图专用 CSV：selected C05 config 的 validation + metkl30 合并 trial，字段包括 policy、ratio、success、match/topK/boundary、U_search、U_confidence、H_norm、gap、cond_risk、scenario、seed。 |
| 图6-5 | 缓存等价性与运行时间：direct manifold 与 cached lookup 在估计/评分/策略上保持一致，缓存降低 manifold/search/backend 运行时间。 | 支持缓存等价性和 runtime reduction 的聚合结论；底层 trial 数据存在。 | 一致，但视觉表达混杂：runtime、reduction、equivalence checks 放在一起，log 轴把 rate 和 relative diff 混在同一面板，阅读负担较高。 | 工程验证图 / 运行时间证据 | 图型不理想：缺少 runtime 分布、IQR、不同场景/候选数下的变化；等价性误差更适合热力图或误差分布。 | 重画，或拆为主图+附图。 | 等价性误差热力图（delta_az x el）+ runtime reduction CDF/箱线图 + direct/cached paired scatter。 | 已有 `step11_6_stage1_manifold_equivalence_trial.csv`、`step11_6_stage2_search_consistency_trial.csv`、`step11_6_stage3_runtime_benchmark_trial.csv`、`step11_7_stage2_cached_direct_consistency_trial.csv`、`step11_7_stage5_runtime_trial.csv`。额外建议保存 cache amortization 数据：repeat_count、cache_build_time、memory_MB、net_speedup。 |
| 图6-6 | 代表性案例和边界现象：解释 C05 在 EASY/NORMAL 等样本上的预算行为，并提示困难/边界样本不能过度宣称。 | 支持“案例解释”和“边界说明”，不能支持主统计结论。 | 当前正文已明确“不作为主要统计证据”，因此一致。 | 案例图 / 边界图 | 图内信息较多但样本数少；EASY 似然地形、候选比例、误差向量、policy 样例混在一图，读者可能难以区分案例解释与统计证据；缺少 strong-coherence stress 分布。 | 保留为案例/边界图；若主文篇幅紧，可移附录，并在主文用 stress/boundary 分布图替代。 | 案例图：等高线 + truth/fixed/C05 点；边界图：stress case heatmap、failure/success distribution、candidate ratio by policy。 | 已有 `v07_likelihood_surface_easy_case.csv`、`v07_likelihood_surface_topk_and_refine.csv`、`v07_representative_backend_outputs.csv`、`step11_5_stage3_supp_illcond_real_stress_trial.csv`。若要更强，需要额外保存 NORMAL、SCORE_AMBIGUOUS、BOUNDARY/失败样本的 likelihood surface 和 topK/refine window。 |

## 表格证据链审查

| 表号 | 当前角色 | 证据链判断 | 建议 |
|---|---|---|---|
| 表2-1、表2-2 | 符号和维度表 | 对公式-代码一致性很重要；目前能辅助图2-1，但若图2-1不标 $\eta_{\mathrm{rt}}=2$，表格也应承担提醒作用。 | 保留；后续可在表2-1加入双程相位因子所在公式/代码变量。 |
| 表3-1 | common-el、pair2d、full4D 角色定位 | 支撑“common-el 是 baseline、full4D 是上界参考”的边界。 | 保留。 |
| 算法1表格 | pair2d DML 步骤 | 与图3-2互补，图负责流程，表负责可复现步骤。 | 保留；若后续排版紧，可让图3-2更简洁、算法表承担细节。 |
| 表4-1 | W 策略设计思想 | 支撑图4-1的设计逻辑，但不支撑 B7 结果。 | 保留；不要把它写成实验结论表。 |
| 表5-1 | 低复杂度机制与验证章节对应 | 对审稿人有帮助，说明每个机制在哪里验证。 | 保留；可作为图表证据链索引。 |
| 表6-1、表6-2 | 实验问题与评价指标 | 证据链组织最清楚的两张表，能防止图6-6被误读为主统计证据。 | 保留。 |
| 表6-3 | 模型参数化关键结果 | 比图6-1更精确，支撑主算法有效性。 | 保留；建议补充 scenario/trial 数或数据范围说明。 |
| 表6-4 | W 选择推荐依据 | 支撑 greedy_combined_B7，但缺少 B-budget 非单调性的更详细拆分。 | 保留；建议与重画后的图6-2互补。 |
| 表6-5 | fixed topK3 搜索加速关键指标 | 支撑图6-3，结论清楚。 | 保留；建议补充 trial/scenario 数。 |
| 表6-6 | C05 自适应预算关键结果 | 很关键，当前比图6-4更有说服力，因为写出 450 样本复验。 | 保留；建议图6-4重画以可视化表中 450 样本复验。 |
| 表6-7 | 缓存等价性与运行时间结果 | 支撑图6-5；但把 equivalence、memory、runtime 混在同表，信息密度高。 | 保留；若正文允许，可拆成“等价性”和“运行时间”两组，或在图6-5中分开呈现。 |
| 表6-9 | 适用范围与局限性 | 对边界声明非常重要，和图6-6形成互补。 | 保留；图6-6不得越过表6-9边界。 |

## 建议的重画队列

| 顺序 | 图号 | 重画目标 | 可直接使用的数据 | 仍需 MATLAB 额外保存的数据 |
|---|---|---|---|---|
| 1 | 图5-1 | 修复图文错位，画出 fixed topK3 与 C05 的关系 | C05 参数规则可从正文和 stage2 trial 字段整理 | `c05_policy_rule_table.csv`：policy、trigger、topK、window_scale、confidence、boundary_action |
| 2 | 图6-1 | 把主算法有效性从聚合柱状升级为场景拆分证据 | `step11_1_full4d_comparison_summary.csv` | per-trial model comparison：scenario、seed、model、success、RMSE、num_pairs、score_margin、boundary_hit |
| 3 | 图6-4 | 展示 C05 的候选压缩分布和安全指标 | `step11_5_stage2_trial.csv`、`step11_5_stage3_supp_metkl30_repeat_trial.csv`、`step11_5_stage3_supp_illcond_real_stress_trial.csv` | 合并后的 selected-config plotting CSV；若要画 likelihood cue 分布，保留 gap、H_norm、U_search、U_confidence、cond_risk、boundary_risk |
| 4 | 图6-5 | 分离缓存等价性和运行时间证据 | Step11.6/11.7 trial CSV 已足够 | cache amortization：repeat_count、build_once_time、memory_MB、net_speedup；不同 grid/W/B 的 memory/runtime |
| 5 | 图6-2 | 让 B7 推荐和“B 不单调”更直观 | `step11_2_b_budget_summary.csv`、`step11_2_w_selection_validation_summary.csv` | per-trial W sweep，如需误差条和显著性 |
| 6 | 图6-6 | 维持案例属性，必要时补边界分布 | v07 representative + Step11.5 stress trial | NORMAL/SCORE_AMBIGUOUS/BOUNDARY 或失败样本的 likelihood surface 与 topK/refine window |

## 最终审查结论

1. 当前图表没有发现会直接推翻论文主线的证据错误。
2. 主要图文错位是图5-1：正文/图题说 fixed topK3 与 C05 关系，但当前图主要只表达 fixed topK3。
3. 图6-1、图6-4、图6-5是最值得重画的三张证据图；它们当前能支撑结论，但图型偏摘要，未充分使用现有 trial 级数据。
4. 图6-6应继续定位为案例/边界图，不应作为主统计证据。
5. 表6-3至表6-7目前承担了大量关键数值证据；后续重画应让图承担“分布/场景/配对关系”的视觉证据，表格保留精确数值。
