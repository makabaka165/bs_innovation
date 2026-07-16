# Tech Audit README

## 本轮目标

检查论文、公式、实验图、MATLAB 代码之间是否一致。

本轮不做文字润色，不重新设计论文结构。重点输出：

- 不一致项
- 未验证项
- 缺失材料
- 需要重画的图
- 需要降调的结论

## 当前审计对象

- 最新稿件 DOCX：`paper/current_manuscript.docx`
- 审计用 PDF：`paper/current_manuscript.pdf`
- 最新稿件来源：`E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/02_manuscript/beamspace_ml_paper_step11_visual_v13_20260625.docx`
- 论文项目最新文本参考：`E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/02_manuscript/full_manuscript_v0.13_形式清稿.md`
- 原始算法代码根目录：`E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps`
- 本论文绘图代码根目录：`E:/matlab_code/bishe_quanxi_papers/beamspace_ml_paper/03_paper_visual_demo_code`

说明：本机未发现可用的 Word/LibreOffice 命令行导出器，因此 `paper/current_manuscript.pdf` 是从 DOCX 抽取段落/表格后用 Python 生成的审计索引用 PDF，不是 Word 精排版导出。排版权威文件仍是 `paper/current_manuscript.docx`。

## 审计边界

- 只审论文主张、公式、实验图、结果表和 MATLAB 实现之间的证据链一致性。
- 不新增算法设计，不替换实验方案。
- 对没有直接证据的内容标为“待审”或“待复核”，不强行补成结论。

## 第一版已确认线索

- 最新稿件为 v0.13 形式清稿，时间戳为 2026-06-25。
- 原始 Step11 链路从 `step_11_1` 到 `step_11_7`，其中 Step11.7 是最终 cached C05 beamspace ML backend 入口。
- 论文项目 v0.12/v0.13 图件由 `03_paper_visual_demo_code/v0_12_structure_refine` 生成，主要读取原始 Step11 输出 CSV/MAT，不应视作算法原始实现。
- 示例中若干文件名是概念名，不是当前代码中的精确文件名；本审计包在 `code_manifest.md` 中列出实际路径。

