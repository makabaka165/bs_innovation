# 提取与运行验证

验证日期：2026-07-15。

## 原文件一致性

对未改写的提取内容进行了 SHA-256 逐文件比较，结果如下：

| 内容 | 校验文件数 | 缺失 | 多余 | 哈希不一致 |
|---|---:|---:|---:|---:|
| v18 Markdown、Word、PDF | 3 | 0 | 0 | 0 |
| v18 正文图片及图 4-2 PDF | 18 | 0 | 0 | 0 |
| 原工程 core | 22 | 0 | 0 | 0 |
| Step11.1 | 142 | 0 | 0 | 0 |
| Step11.2 | 73 | 0 | 0 | 0 |
| Step11.3 | 99 | 0 | 0 | 0 |
| Step11.5 | 115 | 0 | 0 | 0 |
| Step11.6 | 41 | 0 | 0 | 0 |
| Step11.7 | 45 | 0 | 0 | 0 |
| 论文侧 Step11.1/11.2/11.3 导出材料 | 66 | 0 | 0 | 0 |
| v07 绘图依赖 CSV | 10 | 0 | 0 | 0 |
| 固定方位俯仰双目标补充演示 | 9 | 0 | 0 | 0 |

绘图代码复制件的路径设置、README、图清单和汇总入口经过了提取包适配，因此不要求与原文件哈希相同；适配范围见 `PACKAGE_CONTENTS.md`。

## Markdown 完整性

- v18 Markdown 中共检测到 17 个图片引用。
- 17 个引用在 `paper/figures_v16_image2/` 中全部存在。
- 正文 Markdown 本身未改写，仍与原始 v18 文件 SHA-256 一致。

## MATLAB 运行验证

环境：MATLAB R2022b，运行入口：

```matlab
run('E:\bs_innovation\beamspace_ml_v18\fig_code\matlab_v18\per_figure_entrypoints\run_all_v18_matlab_figure_entrypoints.m')
```

结果：MATLAB 返回码为 0，所有收集的逐图入口运行完成。

- pair2d 代表性样例完成 51660 个候选评分；估计方位为 `[7.370, 8.630]` 度，估计俯仰为 `[9.500, 10.100]` 度。
- W 选择图成功加载包内 Step11.2 MAT，推荐案例仍为 `greedy_combined_B7`，选中索引为 `[60 57 36 41 6 89 8]`。
- C05 图成功读取 400 个选定配置样本，其中 EASY、NORMAL、SCORE_AMBIGUOUS 分别为 207、146、47 个。
- 第 6 章模型对比、W/B-budget、coarse-to-fine、C05、cache runtime 和边界案例入口全部完成。
- `fig_code/matlab_v18/outputs/` 共生成 21 个非空文件，约 3.59 MiB。

生成 PNG 与论文最终 PNG 的文件哈希不作为相等条件：PNG 元数据、编码和部分后处理会改变文件字节。逐图已有的像素级或来源级状态记录在 `fig_code/matlab_v18/v18_matlab_figure_manifest.csv` 中。

## 保留风险

运行成功只证明提取包的依赖与入口完整，不消除既有图表审计风险。图 6-1、图 6-4、图 6-5 的硬编码或代理值问题，以及图 6-6 的代表性案例边界，仍应按 `review/technical_audit/audit_outputs/mapping_figures_scripts_data_claims.md` 处理。
