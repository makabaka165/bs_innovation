# 提取范围与来源映射

## 内容统计

| 目录 | 文件数 | 大小约值 | 用途 |
|---|---:|---:|---|
| `paper/` | 24 | 18.83 MiB | v18 三种正文格式、17 张当前引用图、图 4-2 矢量版和引用检查报告 |
| `source/` | 538 | 113.03 MiB | 论文相关原始 MATLAB core、Step11 源码、结果与说明 |
| `fig_code/` | 38 | 3.66 MiB | 17 个 v18 MATLAB 图代码/入口/映射文件，以及运行验证生成的 21 个输出 |
| `evidence/` | 76 | 1.50 MiB | 论文侧导出摘要和代表性案例 CSV |
| `review/` | 21 | 0.12 MiB | 技术审计、贡献摘要、符号和文献支撑笔记 |
| `demo/` | 9 | 1.12 MiB | 固定方位俯仰双目标独立演示 |

以上统计不含本目录根部的说明文件和 SHA-256 清单。`fig_code/matlab_v18/outputs/` 中的文件是本次可移植性验证产物，不是额外的论文最终图。

## 原始来源

| 原始位置 | 提取位置 | 选择说明 |
|---|---|---|
| `02_manuscript/full_manuscript_v0.18_引用文献支撑修订稿.md` | `paper/` | 当前可检索正文 |
| `02_manuscript/beamspace_ml_paper_v0.18_引用文献支撑修订稿.docx` | `paper/` | 当前 Word 正文 |
| `02_manuscript/beamspace_ml_paper_v0.18_引用文献支撑修订稿.pdf` | `paper/` | 当前 PDF 正文 |
| `02_manuscript/figures_v16_image2/` | `paper/figures_v16_image2/` | 仅提取 v18 Markdown 实际引用的 17 张图片；额外保留图 4-2 PDF，并保持正文相对链接有效 |
| `03_paper_visual_demo_code/v18_matlab_figure_code/` | `fig_code/matlab_v18/` | 当前已按图收敛的 MATLAB 绘图代码 |
| 原工程 `core/` | `source/stepwise_signal_model/core/` | 配置、圆柱阵和公共基础函数 |
| 原工程 Step11.1/11.2/11.3/11.5/11.6/11.7 | `source/stepwise_signal_model/steps/` | 主算法、W 设计、搜索、C05、cache 和最终后端证据链 |
| `06_exported_results/step11_1*`、`step11_2*`、`step11_3*` | `evidence/paper_exports/` | 论文项目侧的结果摘要与写作证据 |
| `06_exported_results/step11_visual_v07_outputs/csv/` | `evidence/visual_v07/csv/` | 第 6 章代表性案例绘图依赖 |
| `10_tech_audit/` 中 Markdown | `review/technical_audit/` | 代码、公式、数据、图和主张的映射与既有审计 |
| 贡献、符号、范围、版本和 W/C05 文献笔记 | `review/supporting_notes/` | 创新分析辅助材料 |
| `12_EI/code/` | `demo/fixed_az_el_pair/` | 自包含基础演示，不代表 v18 全部方法 |

论文项目原始根目录为 `E:\matlab_code\bishe_quanxi_papers\beamspace_ml_paper`；工程原始根目录为 `E:\matlab_code\bishe_quanxi\stepwise_signal_model`。

## 提取后调整

以下调整只发生在 `fig_code/matlab_v18/` 的复制件中：

- 三个单图脚本从脚本位置推导包根目录，不再引用原工程绝对路径。
- 第 6 章重绘函数改为读取包内 `source/` 和 `evidence/visual_v07/csv/`。
- 所有新生成图片与日志写入 `fig_code/matlab_v18/outputs/`。
- README 和图代码清单中的运行路径改为提取包路径。

算法公式、实验参数、结果数据和绘图数值逻辑均未在提取过程中改写。

## 未提取内容

- v0.1-v0.17 旧正文、Word/PDF 渲染检查目录和图片编辑备份。
- `03_paper_visual_demo_code` 下 v0.7、v0.8、v0.10、v0.12 的重复历史绘图目录；当前 v18 汇总目录已经保留其仍在使用的源文件。
- 未被 v18 正文引用的候选图片和多轮颜色/剪贴板备份。
- 原工程中与本文证据链无直接关系的早期 Step、失败原型、硬件集成和 Step14 内容。
- 概念图的 AI、手工或后处理过程；包中保留的是最终插图，而不是无法确认唯一来源的历史制作过程。
- Git 元数据、临时文件和渲染缓存。

## 使用边界

该包适合做内部贡献拆解、实现核查、实验追溯和后续算法迭代。判断对外学术新颖性仍需结合正式文献检索；`review/supporting_notes/literature_support_W_C05_v17.md` 只能作为已有起点，不能代替完整的现有技术检索。
