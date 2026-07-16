# 版本日志

## Word v0.16 - 2026-06-28

- 由 `02_manuscript/beamspace_ml_paper_v0.15_nature写作终润稿.docx` 复制生成 `02_manuscript/beamspace_ml_paper_v0.16_公式行内格式整理稿.docx`。
- 同步生成 `02_manuscript/full_manuscript_v0.16_公式行内格式整理稿.md` 与 `02_manuscript/word_revision_log_v0.16_公式行内格式整理稿.md`。
- 按论文公式排版规则整理正文公式：短拉丁变量（M、m、az、el、B、W、Y、S、N、Z、G、q）在正文中作为普通斜体文本显示；复杂 LaTeX 片段保留原 `$...$` 字符串，便于后续手动转换 MathType/LaTeX。
- 已经独立成段的长公式保持独立段落；将候选波束池定义和粗/细俯仰分离候选集合两处较长行内定义改为独立公式段落，公式字符串本身不改。
- 跳过参考文献区，避免误处理作者姓名缩写；检查结果显示媒体对象 13 个保留，短变量运行均带 Word 斜体，参考文献区无新增斜体运行。
- Word 自动化可正常打开 v0.16；LibreOffice 渲染因图片转换报 `libpng error: Write Error`，Word PDF 导出耗时过长未完成，因此本轮未产出最终 PDF 视觉检查件。

## v0.1 - 2026-06-06

- 创建论文目录结构，且目录位于当前 stepwise_signal_model 项目之外。
- 导出 Step11.1、Step11.2、Step11.3 的关键 Markdown、CSV 和 PNG 结果材料。
- 生成 10 张中文图表版本，包括模型对比、W 选择、B 预算、搜索加速、候选数压缩、鲁棒性和最终流程图。
- 生成论文大纲、贡献总结、符号表、公式规则、正文 Markdown 骨架和 LaTeX 可选骨架。
- 记录材料索引、缺失项和下一步建议。

## v0.2 - 2026-06-06

- 扩写 `02_manuscript/manuscript_sections/` 下 7 个 Markdown 正文章节，形成中文小论文初稿。
- 第1章补充研究背景、阵元级复杂度、beam-index smoothing MUSIC 局限、beamspace ML 转向动机、三条贡献和适用边界。
- 第2章补充圆柱阵真实流形、阵元域双目标观测、beamspace 投影模型和局部搜索窗口定义。
- 第3章补充 DML 投影准则、controlled pair2d 参数化、common-el baseline、full4D upper bound 和候选复杂度分析。
- 第4章补充 regular 3dB beam grid、greedy_projection、greedy_lowcorr、greedy_combined、SVD upper bound 和最终 greedy_combined_B7 推荐。
- 第5章补充 degree-based el_sep、coarse topK、local refine、topK=3、候选数 131461 到 19161.9 以及约 6.86 倍复杂度降低。
- 第6章按 6.1 至 6.5 扩写实验设置、Step11.1 模型对比、Step11.2 W/B-budget、Step11.3 搜索加速和边界局限性分析。
- 第7章总结三条创新、局限性和后续工作。
- 更新 `02_manuscript/manuscript_skeleton.md`，记录正文初稿状态和人工复核清单。
- 未生成正式 Word/PDF，未修改公式规则文件，未修改 stepwise_signal_model 代码仓库，未提交 Git。

## v0.3 - 2026-06-06

- 对 7 个 Markdown 正文章节进行逻辑审查，生成 `00_admin/draft_review_report.md`。
- 小幅修订第1章、第3章、第6章和第7章中可能被误读为自动单双目标模型选择的表述。
- 小幅修订第2章局部搜索窗口半宽符号，改为 $\Delta_{az}^{\mathrm{win}}$ 和 $\Delta_{el}^{\mathrm{win}}$，避免与目标分离量混淆。
- 小幅修订第3章 controlled pair2d 参数化，补充方向变量 $q\in\{+1,-1\}$。
- 小幅修订第4章 W 选择符号说明，明确 greedy_combined 综合评分是概念/诊断表达，不是闭式最优准则。
- 小幅修订第5章，明确 coarse-to-fine 是搜索加速策略，不是交替投影 AP。
- 核对 Step11.1、Step11.2、Step11.3 关键结果数字与正文一致。
- 核对行间公式块中无中文正文。
- 未生成正式 Word/PDF，未修改公式规则文件，未修改 stepwise_signal_model 代码仓库，未提交 Git。

## v0.4 - 2026-06-06

- 添加中文摘要 `02_manuscript/abstract_cn.md`，包含研究背景、方法、三条创新、关键结果、局限边界和关键词。
- 添加英文 Abstract `02_manuscript/abstract_en.md`，与中文摘要含义一致并包含 Keywords。
- 添加参考文献占位框架 `02_manuscript/references_placeholder.md`，按主题记录待补充真实文献方向，不编造具体文献条目。
- 合并生成完整 Markdown 技术初稿 `02_manuscript/full_manuscript_v0.1.md`。
- 保留公式 MathType 转换规则，未修改 `01_outline/formula_rules_for_mathtype.md`。
- 检查完整总稿行间公式块，未发现中文正文进入公式块。
- 未生成正式 Word/PDF，未修改 stepwise_signal_model 代码仓库，未提交 Git。

## Word v0.4 - 2026-06-07

- 新建 `02_manuscript/full_manuscript_v0.4_修订稿.md`，由 v0.3 修订稿复制得到，用于保留上一版 Word 的同时生成新版本。
- 使用 MATLAB R2022b 生成 `09_chinese_figures/v4_matlab_style/` 下 13 张 v0.4 风格图，数据对比图由现有 Step11 CSV 结果重画。
- 重画图 2-1，将圆柱阵表示为工作子阵 N_elem=2080 的抽样示意，并补充局部窗口、粗中心和双目标标注。
- 重画流程图，放大框图、缩短箭头并统一采用 MATLAB 默认色序，标题统一为黑色。
- 新增 `00_admin/generate_v04_matlab_figures.m` 和 `00_admin/export_word_v04_revision.py`。
- 生成 `02_manuscript/beamspace_ml_paper_v0.4_技术初稿_修订.docx` 和 `02_manuscript/word_revision_log_v0.4.md`。
- Word 中为实际 Markdown 表格补充“表 x-x”题名，表格保持透明白底并移除表格左缩进。
- 未生成 PDF，未修改公式规则文件，未覆盖 v0.3 Word，未修改 stepwise_signal_model 代码仓库，未提交 Git。

## Word v0.5 - 2026-06-07

- 新建 `09_chinese_figures/v5_restored_v3_boxes/`，框图类图片恢复为 v3 的结构和样式。
- 使用 `00_admin/generate_v05_restored_box_figures.py` 将 v3 框图蓝色系替换为 MATLAB 默认柱状图蓝色，并保留 v0.4 数据对比图不变。
- 新增 `00_admin/export_word_v05_revision.py`，仅替换 Word 中框图图片来源。
- 生成 `02_manuscript/beamspace_ml_paper_v0.5_技术初稿_修订.docx` 和 `02_manuscript/word_revision_log_v0.5.md`。
- 正文、数据图、表格、公式和 MathType 处理状态均沿用 v0.4。
- 未生成 PDF，未修改公式规则文件，未覆盖 v0.4 Word，未修改 stepwise_signal_model 代码仓库，未提交 Git。
- 在 v5 基础上直接覆盖修改图 1-2 贡献链条，放大框图和文字，缩短并减小箭头。
- 在 v5 基础上优化图 2-1 圆柱阵建模示意，使其更贴近工作子阵 N_elem=2080 和真实阵元坐标建模设定。
- 将表 2-1 由占位符改为实际主要符号和参数定义表，更新 `02_manuscript/full_manuscript_v0.5_修订稿.md` 并重新导出 v0.5 Word。

## Word v0.5 follow-up - 2026-06-09

- 直接在 v0.5 源稿上补齐表 4-1 W 选择策略结果对比、表 6-1 实验阶段汇总、表 6-5 适用范围与局限性汇总。
- 将 v0.5 总稿参考文献章节由占位框架替换为真实候选文献列表，新增 `02_manuscript/references_candidate_v0.5.md` 记录 DOI/检索入口和知网学位论文待核验方向。
- 重新导出 `02_manuscript/beamspace_ml_paper_v0.5_技术初稿_修订.docx`，检查结果为插图 13 张、实际 Markdown 表格 8 张、表格占位符 0、公式块 31 个、缺失图片 0、PDF 数量 0。
- 本轮未生成 PDF，未修改公式规则文件，未修改 stepwise_signal_model 代码仓库，未提交 Git。

## Word v0.5 citation follow-up - 2026-06-09

- 直接在 `02_manuscript/full_manuscript_v0.5_修订稿.md` 正文中补入参考文献引用编号，覆盖研究背景、MUSIC 与空间平滑、beamspace DOA/ML、最大似然 DOA、UCA/圆阵流形、波束形成、SVD 与矩阵计算等主题。
- 检查结果：文末 26 条候选参考文献均被正文至少引用一次，无越界引用编号；行间公式块未发现中文正文；表格占位符仍为 0。
- 重新导出 `02_manuscript/beamspace_ml_paper_v0.5_技术初稿_修订.docx`，检查结果为插图 13 张、实际 Markdown 表格 8 张、公式段落 31 个、缺失图片 0、PDF 数量 0。
- 本轮未生成 PDF，未修改公式规则文件，未修改 stepwise_signal_model 代码仓库，未提交 Git。
