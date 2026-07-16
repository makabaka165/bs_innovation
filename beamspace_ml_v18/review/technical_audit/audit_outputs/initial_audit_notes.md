# Initial Audit Notes

## 已完成

- 创建审计目录 `10_tech_audit`。
- 复制最新 v0.13 DOCX 到 `paper/current_manuscript.docx`。
- 生成审计用 PDF 到 `paper/current_manuscript.pdf`。
- PDF 基本验证：`pdfinfo` 显示 13 页 A4，第一页可由 `pdftoppm` 渲染。
- 初步定位原始 Step11 链路、当前论文绘图脚本、关键 CSV 指标和最新稿件。

## 重要说明

- `paper/current_manuscript.pdf` 是文本抽取版，不是 Word 精排版导出。中文文本抽取层可能有编码噪声，但 PDF 可视渲染正常。
- 原始 Markdown 稿 `full_manuscript_v0.13_形式清稿.md` 在 PowerShell 里显示为乱码，疑似编码不是 UTF-8。本轮没有改动原稿。
- 示例中的 `run_step11_main.m`、`run_pair2d_dml.m`、`beamspace_dml_pair2d.m`、`select_greedy_combined_B7.m`、`plot_fig6_1_model_comparison.m` 等精确文件名未在当前目录或原始 Step11 目录中发现；本包已改用真实存在的拆分脚本/函数路径。

## 下一步审计建议

1. 用脚本逐项读取 final DOCX 的图题/表题，更新 `figure_manifest.md` 的最终图号。
2. 从 Step11.1/2/3/5/6/7 的 final CSV 复算摘要中的关键数值，生成 `audit_outputs/metric_trace.csv`。
3. 逐行核对 `beamspace_dml_score.m` 与论文 DML 公式。
4. 逐行核对 pair2d 参数化、`q` orientation、候选集合规模与复杂度公式。
5. 检查 v0.12/v0.13 绘图脚本是否存在硬编码 fallback 被使用的风险。
6. 对每个主张给出状态：`通过`、`需降调`、`缺证据`、`需重画图`。

