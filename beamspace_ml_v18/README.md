# Beamspace ML v18 创新分析包

本目录于 2026-07-15 从论文项目和原始 MATLAB 工程中提取，用于分析 v18 论文的创新点、核对实现与实验依据，以及继续迭代算法。原始项目文件没有被修改。

## 权威材料

- `paper/full_manuscript_v0.18_引用文献支撑修订稿.md`：便于检索、批注和代码映射的正文源稿。
- `paper/full_manuscript_v0.19_sequential_dbf_revision.md`：当前 factor=1、Step12.3 阶段 5 活跃修订源稿。
- `paper/beamspace_ml_paper_v0.18_引用文献支撑修订稿.docx`：当前 v18 Word 稿。
- `paper/beamspace_ml_paper_v0.18_引用文献支撑修订稿.pdf`：当前 v18 PDF 稿。
- `paper/figures_v16_image2/`：正文 Markdown 当前引用的 17 张最终图片，并额外保留图 4-2 的矢量 PDF。目录名沿用正文中的现有相对路径，内容对应 v18。

正文是论文主张的权威来源；`review/supporting_notes/` 中的材料用于辅助理解，其中部分文件形成时间早于 v18，不能覆盖正文。

当前活跃数值证据来自 Step12，而不是下面保留审计的 Step11/v18 路线。Step11 圆柱阵结果由 `phase_factor=2` 产生，已冻结为 legacy；阶段 5 runner 再次复核了 351 个 Step11 结果文件、117,091,926 bytes，哈希不匹配为 0。

## 目录说明

- `paper/`：v18 的 Markdown、Word、PDF、最终图片和引用检查报告。
- `source/stepwise_signal_model/`：与论文证据链直接相关的原始 MATLAB `core` 及 Step11.1、11.2、11.3、11.5、11.6、11.7 源码和记录结果。
- `fig_code/matlab_v18/`：按图整理的 v18 MATLAB 绘图入口、四个实际绘图源文件及图代码映射表。
- `evidence/`：论文项目中的 Step11.1/11.2/11.3 导出摘要，以及第 6 章代表性案例绘图依赖的 v07 CSV。
- `review/technical_audit/`：主张、公式、变量、代码、数据和图件之间的既有审计映射。
- `demo/fixed_az_el_pair/`：可独立运行的固定方位、俯仰双目标 beamspace ML 演示。

## 创新主线

v18 正文将贡献组织为一条主贡献和三个支撑机制：

1. 圆柱阵真实流形驱动的 controlled pair2d beamspace ML 后端测角。
2. 面向该后端的波束矩阵选择，当前推荐配置为 `greedy_combined_B7`。
3. fixed topK3 coarse-to-fine 与 C05 自适应搜索预算控制。
4. shared-center canonical beamspace manifold cache。

对应工程入口位于：

- `source/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/`
- `source/stepwise_signal_model/steps/step_11_2_beamspace_w_design/`
- `source/stepwise_signal_model/steps/step_11_3_beamspace_ml_search_acceleration/`
- `source/stepwise_signal_model/steps/step_11_5_likelihood_uncertainty_adaptive_beamspace_ml_search/`
- `source/stepwise_signal_model/steps/step_11_6_shared_center_rotatable_beamspace_manifold_cache/`
- `source/stepwise_signal_model/steps/step_11_7_final_cached_c05_beamspace_ml_route/`

## Factor=1 活跃修订主线

Step12 已完成接收单程流形、真实先俯仰后方位 DBF、稳定 SVD/QR-DML、
oracle-Q 俯仰组恢复，以及阶段 5 的条件方位和固定完整顺序流形修正。入口为：

- `source/stepwise_signal_model/steps/step_12_0_receive_model_correction/`
- `source/stepwise_signal_model/steps/step_12_1_sequential_dbf_model/`
- `source/stepwise_signal_model/steps/step_12_2_stable_dml_backend/`
- `source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml/`
- `source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/`

阶段 5 在 oracle `Q/Kq`、统一注册局部角域和 `phase_factor=1` 下通过技术门与 Pareto 方案 1：455 个 holdout 配对中，主链与两初值直接 AP 的成功率相同，配对差异 95% 区间为 `[0,0]`；主链端到端 score calls 平均减少 `44.95%`，相对 local-full 减少 `74.95%`。该证据只支持一种工程初始化和数据组织收益，不把条件 DML、AP、坐标上升或 SVD 投影声明为新算法。所有有噪声输出均为 `NOT_CALIBRATED_STAGE5`；相干弱目标核心 stress 场景中三种 DML 路线均为 `0/200`，自动 Q/K、FIM、bootstrap、K=3、cache 和硬件映射尚未实现。

阶段 6 已在固定白化顺序接收流形上完成确定性渐近验证；6.1B 从同一 A2 提交独立重跑两次，完成历史 Git-object 对照、自复现和最终证据冻结。确定性 bundle hash 为 `0c1f444603398e03865043af4e4c6e4a414dd15a3cc90e0539b19c56e990c839`；physical exact tangent null 仍未出现，阶段 7 尚未开始。

## 绘图代码

提取包中的绘图脚本保持原有数值与绘图逻辑，只将绝对路径改成了包内相对路径。脚本从自身位置定位 `source/` 和 `evidence/`，生成结果统一写入 `fig_code/matlab_v18/outputs/`。

在 MATLAB 中运行全部已收集入口：

```matlab
packageRoot = 'E:\bs_innovation\beamspace_ml_v18';
run(fullfile(packageRoot, 'fig_code', 'matlab_v18', ...
    'per_figure_entrypoints', 'run_all_v18_matlab_figure_entrypoints.m'))
```

逐图入口和最终图对应关系见 `fig_code/matlab_v18/v18_matlab_figure_manifest.csv`。重新生成的图片用于追溯，不应自动覆盖 `paper/figures_v16_image2/` 中的论文最终图片，因为部分图片经过了后续导出或人工后处理。

## 已知审计事项

- 图 6-1 的旧绘图实现使用过 common-el 候选数代理值，需以 Step11.1 原始结果为准。
- 图 6-4 的部分候选数和安全性值由已有 keypoints 硬编码到绘图逻辑中。
- 图 6-5 的一致性向量存在硬编码，但对应 Step11.6/11.7 记录结果可供核对。
- 图 6-6 是代表性案例和边界说明，不能替代统计证据。

详见 `review/technical_audit/audit_outputs/mapping_figures_scripts_data_claims.md`。本提取包保留这些脚本是为了可审计性，不表示默认接受其中所有图表处理方式。

## 补充演示边界

`demo/fixed_az_el_pair/` 不依赖原始工程函数，适合快速理解白化 beamspace DML 和固定方位双目标俯仰搜索。它不包含完整 controlled pair2d、C05 或 canonical cache，因此不能替代 Step11 工程作为 v18 全部创新点的实现依据。

## 来源

- 论文项目：`E:\matlab_code\bishe_quanxi_papers\beamspace_ml_paper`
- 原始工程：`E:\matlab_code\bishe_quanxi\stepwise_signal_model`

文件校验信息见 `FILE_SHA256.csv`；提取范围和来源映射见 `PACKAGE_CONTENTS.md`；复制与 MATLAB 运行结果见 `VERIFICATION.md`。
