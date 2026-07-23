# Stage8 执行提示词目录

本目录保存 Stage8 进入正式运行后的、可直接交给执行 AI 的提示词合同。

## 目录规则

- 新提示词只新增到本目录，不再继续把新的正式执行合同追加到历史总文件 `innovation-mining/13_next_step_execution_prompts.md`。
- 文件名使用递增编号：`NNN_<stage>_<purpose>.md`。编号只表示提示词顺序，不表示统计结果或算法优先级。
- 每份提示词必须写明当前 Git 基线、外部 runtime 根、授权边界、禁止事项、成功验收条件、失败/中断语义和停止点。
- 提示词正文不能替代仓库内的 MATLAB 合同。执行时始终以入口函数、plan builder、artifact registry、loader 和 writer 的硬编码检查为最终裁决。
- 本目录只存提示词和提示词索引，不存 checkpoint、MATLAB 日志、生成的 CSV 或运行时锁。

## 当前提示词

| 文件 | 用途 | 当前授权边界 |
|---|---|---|
| `001_stage8_1b_threshold_freeze_and_k1_validation.md` | 从 R2/C2 300-cell 完成态进入阈值冻结，并在第一份证据提交后执行 K1 validation | 当前首先只执行 Phase A；Phase B 必须从干净阈值提交重新授权；任何情况下停在 Stage8.2 之前 |

## 重要身份规则

Stage8 stable code identity 包含 Stage8 步骤根的 `README.md` 以及该步骤目录内的 `.m` 文件；它排除 `calibration/`、`results/` 和 `figures/`。因此不能把步骤根 README 当作普通 docs 文件修改。提示词目录位于 `innovation-mining/`，不属于该 identity，但正式运行仍要求整个 Git 工作树干净，所以本目录中的新提示词必须先单独提交。
