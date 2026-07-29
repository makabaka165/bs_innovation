# Stage8-Core-V2.2：单 CPI、单距离–多普勒单元 Known-K 最终接口与独立冻结验证（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 和 Git 的执行 AI。
>
> 本协议是当前 Stage8/Core-V2 路线的最后一个算法工程与独立验证阶段。
> 本阶段完成后，不再创建 Core-V3，不再设计新的 K2 solver，不恢复自动 K、
> parametric bootstrap、resolved/unresolved、6000-trial 或 Stage8.2。
>
> 唯一目标分支：
>
> ```text
> experiment/stage8-core-v2
> ```
>
> 协议：
>
> ```text
> STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_V1
> ```

---

## 0. 本阶段的最终问题定义

本项目最终研究的不是航迹处理，也不是跨 CPI 目标数推断。

唯一场景为：

```text
同一个 CPI
        ↓
距离–多普勒处理
        ↓
选定一个距离–多普勒处理单元
        ↓
该单元内包含 K=1 或 K=2 个主导角向回波分量
        ↓
常规顺序波束峰给出一个局部角域 Ω
        ↓
在 Ω 内执行高分辨二维波束域 ML 精测角
```

必须固定以下解释：

```text
single_cpi_flag = true
same_range_doppler_cell_flag = true
cross_cpi_data_used_flag = false
tracking_input_used_flag = false
K_estimated_inside_module_flag = false
```

其中：

```text
K=1：
单个距离–多普勒单元内有一个主导点目标/角向回波分量。

K=2：
两个目标或两个主导回波分量具有无法由当前距离和多普勒分辨率区分的
距离/径向速度，因而叠加在同一个处理单元内；它们的角度也位于同一个
常规局部波束角单元内，需要局部超分辨测角。
```

`K` 在本文中是：

```text
研究场景的固定条件
或
外部模块传入的条件量
```

本模块不说明外部模块如何获得 `K`，也不把仿真 truth 偷渡进拟合过程。

论文和软件均不得声称：

```text
自动发现同一距离–多普勒单元中的目标数
自动多目标检测
航迹条件测角
跨 CPI 融合
```

推荐最终问题表述：

> 本文研究单个 CPI 内，经距离–多普勒处理选定的单个处理单元中，
> 在给定局部角域和局部回波分量数 \(K\in\{1,2\}\) 条件下，
> 利用实际顺序接收波束数据进行二维局部超分辨 ML 测角。

---

## 1. Git 锚点与硬边界

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

目标分支：

```text
experiment/stage8-core-v2
```

预期起点：

```text
c0f77ee4bcd94cc621f459c6e365c63c2bc4c669
docs(innovation): consolidate validated theory and archive superseded plans
```

稳定 main：

```text
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git switch experiment/stage8-core-v2
git reset --hard origin/experiment/stage8-core-v2

git rev-parse HEAD
git rev-parse origin/experiment/stage8-core-v2
git rev-parse origin/main
git status --porcelain=v1 --untracked-files=all
```

要求：

```text
HEAD == origin/experiment/stage8-core-v2
HEAD == c0f77ee4bcd94cc621f459c6e365c63c2bc4c669
origin/main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
工作树 clean
```

若探索分支已由用户明确推进到 `c0f77ee` 的后代：

1. 记录实际起点；
2. 只允许新增 docs-only 内容或本协议明确允许的 Step12.7 内容；
3. 发现不明算法修改时硬停止；
4. 不得自动丢弃提交。

本次禁止：

```text
push main
merge main
创建新分支
force push
修改旧 evidence 数值
修改 Step12.0–Step12.6 冻结源码
修改 calibration/results/figures
恢复 Stage8.1B formal validation
运行 Stage8.2
```

---

## 2. 当前证据与不可变结论

以下结果必须保持不变：

```text
Stage6:
THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY

Stage7:
PASS_SYSTEM_ANALYSIS_ONLY

Compact unknown-K diagnostic:
K1 false split = 30/60 = 0.50
CLEAR_FAILURE

Core-V2 known-K:
K1 continuous 16/16 valid
off-grid median RMSE:
0.141421356° → 0.011388568°

K2 continuous:
direct 2/8 valid
grouped 4/8 valid

Safe hybrid:
H1 K1/K2 valid = 16/16, 8/8
H2 K1/K2 valid = 16/16, 8/8
H2 vs H1 = 4 wins / 4 ties / 0 losses

Final grouped status:
STAGE8_CORE_V2_1_OPERATIONAL_GROUPED_OPTIONAL
```

本阶段不允许根据新结果改动旧 CSV，也不允许重新解释旧结果为：

```text
automatic-K success
continuous K2 8/8 success
formal validation pass
```

---

## 3. 本阶段只完成三件事

### A. 场景和接口收束

将权威编号 11 文档、软件接口和最终报告统一为：

```text
单 CPI
单距离–多普勒处理单元
局部角域已给定
K∈{1,2} 已给定
```

不得出现航迹作为必需输入。

### B. 生产接口整合

将已验证的 Core-Lite/Core-Plus 原型整理为一个最小公开 MATLAB 入口。

### C. 一次独立 known-K 验证

使用新的、与 24-trial 开发集完全不重叠的 144 个 element-domain trials，
完成最终独立验证和冻结。

本阶段不设计新算法。

---

## 4. 新代码路径

只允许新增：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/
```

建议结构：

```text
step_12_7_known_k_local_cell_refinement/
├── README.md
├── common/
│   ├── estimate_stage8_known_k_local_cell.m
│   ├── validate_stage8_known_k_local_cell_input.m
│   ├── build_stage8_known_k_local_context.m
│   ├── fit_stage8_core_lite.m
│   ├── fit_stage8_core_plus.m
│   ├── select_stage8_safe_known_k_candidate.m
│   ├── refine_stage8_k1_continuous.m
│   ├── refine_stage8_k2_center_difference.m
│   ├── compute_stage8_projected_separation_geometry.m
│   ├── stage8_core_v2_2_result_template.m
│   └── stage8_core_v2_2_stable_hash.m
├── tests/
│   ├── test_public_input_contract.m
│   ├── test_historical_24_trial_regression.m
│   ├── test_no_truth_or_tracking_dependency.m
│   ├── test_safe_selection_contract.m
│   └── test_final_registry_contract.m
├── validation/
│   ├── build_stage8_core_v2_2_final_registry.m
│   ├── generate_stage8_core_v2_2_trial.m
│   ├── run_stage8_core_v2_2_final_validation.m
│   ├── summarize_stage8_core_v2_2_final_validation.m
│   └── finalize_stage8_core_v2_2_final_validation.m
└── run_step12_7_known_k_local_cell_refinement.m
```

允许合并辅助文件，但必须保持：

```text
一个公开入口
一个固定 registry
一个最终 runner
```

不得创建新的通用框架、插件系统或多层证据基础设施。

---

## 5. 科学代码提升规则

现有已验证原型位于：

```text
tools/stage8_core_v2_known_k/
tools/stage8_r1_continuous_decisive/
```

新 Step12.7 不得直接把 `tools/` 加入生产运行路径。

执行以下规则：

1. 将已经验证的科学逻辑机械提升到 Step12.7；
2. 不改变公式、候选数、solver tolerance、rank contract 或 safe-selection 规则；
3. 允许重命名函数以形成清晰公开接口；
4. 必须保存来源函数和来源 commit；
5. 必须通过历史 24-trial 位级/字段级回归后，才允许运行新验证；
6. 任何科学输出不一致都必须停止，不得通过更新历史 CSV 解决。

不得修改原工具目录；它们保留为历史复现依据。

---

## 6. 唯一公开接口

实现：

```matlab
result = estimate_stage8_known_k_local_cell( ...
    Y_element, model, local_domain, stage5_locked, noise_model, K, opts)
```

### 6.1 输入

```text
Y_element:
[M, L] complex double
同一 CPI、同一距离–多普勒处理单元的阵元域复观测

model:
固定顺序 measurement model

local_domain:
由常规波束峰/角单元给出的固定局部角域 Ω

stage5_locked:
冻结的顺序 DBF 配置

noise_model:
固定阵元噪声协方差模型

K:
仅允许标量整数 1 或 2

opts.mode:
CORE_LITE
CORE_PLUS
默认 CORE_LITE
```

允许的其他 `opts` 仅为：

```text
rank_multiplier = 1
return_diagnostics = true/false
scenario_contract =
  SINGLE_CPI_SINGLE_RANGE_DOPPLER_CELL
K_conditioning =
  EXTERNALLY_GIVEN_NOT_ESTIMATED
```

拒绝：

```text
K='AUTO'
K=0
K>2
tracking data
previous-CPI data
truth angles
truth separation
truth difficulty
threshold lookup
bootstrap options
```

### 6.2 输出

至少包含：

```text
angles_hat_deg
K
mode
fit_valid
fit_status
selected_source
selected_start_id
rss
loglik_concentrated
effective_rank
score_call_count
svd_call_count
runtime_sec

single_cpi_flag = true
same_range_doppler_cell_flag = true
cross_cpi_data_used_flag = false
tracking_input_used_flag = false
K_estimated_inside_module_flag = false
truth_used_in_fit_flag = false
```

---

## 7. 最终算法定义

### 7.1 K=1，CORE_LITE / CORE_PLUS

两个 mode 使用相同 K1 路径：

```text
B0 fixed-grid known-K K1
+
conventional singleton continuous K1 candidate
+
safe selection
```

若 continuous candidate：

```text
valid
且 loglik_continuous >= loglik_B0
```

则输出：

```text
CONTINUOUS_UPGRADE
```

否则：

```text
FIXED_GRID_FALLBACK
```

K1 禁止运行 grouped start。

### 7.2 K=2，CORE_LITE

只运行：

```text
B0 fixed-grid known-K K2
```

输出：

```text
FIXED_GRID_CORE_LITE
```

不运行：

```text
direct continuous K2
grouped continuous K2
K1/K2 LRT
```

### 7.3 K=2，CORE_PLUS

运行：

```text
B0 fixed-grid known-K K2
+
grouped/conditional K2 starts
+
center–difference continuous refinement
+
safe selection
```

若 continuous candidate 有效且：

```text
loglik_continuous >= loglik_B0
```

则：

```text
CONTINUOUS_UPGRADE
```

否则：

```text
FIXED_GRID_FALLBACK
```

不运行 direct continuous K2；它只保留为历史实验 baseline。

### 7.4 明确禁止

生产接口中不得出现：

```text
unknown-K LRT
q_global
parametric bootstrap
separation bootstrap
K2_RESOLVED
K2_UNRESOLVED
六状态 classifier
EASY/HARD 在线标签
q threshold
SNR threshold
likelihood-gain threshold
第三版 K2 solver
```

---

## 8. 文档中的场景修订

更新：

```text
innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
```

在“系统层级与问题定义”中明确写入：

> 本文不使用航迹、跨 CPI 预测或跨帧基数信息。研究对象是单个 CPI 内，
> 经距离–多普勒处理后选定的单个处理单元。该单元包含一个或两个主导角向
> 回波分量；它们在当前距离和多普勒分辨率下不可区分，但可在阵列角维进行
> 局部超分辨估计。局部角域由常规波束峰给出，\(K\in\{1,2\}\) 是研究场景
> 或外部模块提供的条件量，本文不估计 \(K\)。

同时加入文献边界：

```text
Heidenreich & Zoubir, Signal Processing, 2013,
DOI 10.1016/j.sigpro.2013.03.009

Vincent, Besson & Chaumette, Signal Processing, 2014,
DOI 10.1016/j.sigpro.2013.10.017
```

说明：

```text
这些工作同样在距离/频率预处理后的单 processing cell/bin 中研究一目标或
两近邻目标的 ML DOA；目标数检测可作为独立问题或直接排除在估计器范围之外。
```

不得在该段引入航迹。

---

## 9. Gate F0：边界和现场

工具提交前检查：

```text
branch = experiment/stage8-core-v2
c0f77ee 是祖先
origin/main 保持 247fad
工作树 clean
MATLAB / mwpython / coordinator / active lock = 0
15/16/23/24/26/27 evidence 未改
Step12.0–12.6 frozen paths 未改
calibration/results 未改
```

失败：

```text
F0_FAIL_STOPPED
```

---

## 10. Gate F1：历史 24-trial 回归

精确复用：

```text
innovation-mining/27_stage8_core_v2_1_safe_hybrid_trials.csv
```

并重建原 24 个 element trials。

要求：

### K1

新接口：

```text
CORE_LITE
CORE_PLUS
```

均必须逐 trial 匹配历史 H1/H2 的 K1 selected scientific fields：

```text
angles num2hex
RSS num2hex
loglik num2hex
fit_valid
selected_source
solver_status
element_trial_hash
```

### K2 CORE_LITE

必须匹配历史 B0 selected candidate：

```text
fixed-grid angles
RSS
loglik
validity
```

### K2 CORE_PLUS

必须匹配历史 H2 selected row：

```text
angles num2hex
RSS num2hex
loglik num2hex
selected_source
fallback/upgrade
solver_status
```

允许不同：

```text
runtime
PID
timestamp
source-file path
```

不允许不同：

```text
任何科学字段
```

通过：

```text
F1_HISTORICAL_24_TRIAL_REGRESSION_PASS
```

失败：

```text
F1_FAIL_STOPPED
```

不得运行独立 144 trials。

---

## 11. 最终独立验证 registry

总计：

```text
144 element trials
72 K1
72 K2
```

所有 seed 必须与 calibration、formal validation、24-trial 开发集完全不重叠。

### 11.1 K1：72 trials

因素：

```text
noise ∈ {
  WHITE,
  STAGE5_TOEPLITZ_CORRELATED
}

L ∈ {1,4,8}

SNR ∈ {-6,0,+6} dB

center profile ∈ {
  C1_ON_GRID        = [8.00,10.00],
  C2_OFF_GRID_NE    = [8.10,10.10],
  C3_OFF_GRID_SW    = [7.90, 9.90],
  C4_NEAR_CELL_EDGE = [8.45,10.15]
}
```

总数：

```text
2 × 3 × 3 × 4 = 72
```

每 trial 使用唯一 element-noise seed：

```text
K1 noise seed base = 2926073000
seed = base + global_K1_trial_index - 1
```

### 11.2 K2：72 trials

因素：

```text
noise ∈ {
  WHITE,
  STAGE5_TOEPLITZ_CORRELATED
}

L ∈ {1,4,8}

SNR ∈ {-6,0,+6} dB

profile ∈ {P1,P2,P3,P4}
```

固定 profiles：

| Profile | Center [az,el] | Separation | Direction | Secondary power | Correlation for L>1 |
|---|---|---:|---:|---:|---:|
| P1 | [8.00,10.00] | 0.30° | 45°  | 0 dB  | 0 |
| P2 | [8.20,10.00] | 0.20° | 0°   | -6 dB | 0 |
| P3 | [7.90,10.10] | 0.15° | 90°  | 0 dB  | 0.9 |
| P4 | [8.10, 9.95] | 0.10° | 135° | -6 dB | 0.9 |

目标角：

```matlab
v = [cosd(direction_deg), sind(direction_deg)];

targets = [center - separation_deg*v/2;
           center + separation_deg*v/2];
```

所有 endpoint 必须在冻结 local domain 内。

对于 `L=1`：

```text
source correlation 按单快拍确定性源合同强制为 1
并记录：
L1_FULLY_COHERENT_BY_CONTRACT
```

对 `L>1` 使用表中 correlation。

seed：

```text
K2 source seed base = 2926074000
K2 noise seed base  = 2926075000
```

每 trial 使用唯一 source seed 和唯一 noise seed。

### 11.3 单 CPI / 单单元合同

每个 trial 必须记录：

```text
cpi_id = one synthetic CPI
range_doppler_cell_id = one selected cell
same_range_doppler_cell_flag = true
cross_cpi_data_used_flag = false
```

本验证只生成该处理单元对应的 element-domain snapshot matrix。

不需要额外实现：

```text
距离 FFT
多普勒 FFT
CFAR
目标数检测
航迹
```

这些属于输入接口上游，不是本阶段算法。

---

## 12. 验证方法

每个 K1 trial 运行：

```text
CORE_LITE
CORE_PLUS
```

并断言两者输出科学字段完全相同。

每个 K2 trial 运行：

```text
CORE_LITE
CORE_PLUS
```

每种方法都保存：

```text
selected result
B0 candidate metrics
continuous candidate metrics（若运行）
```

总 result rows：

```text
144 × 2 = 288
```

所有方法共享同一 `Y_element`。

truth 只用于运行完成后的角度匹配和误差计算。

---

## 13. q 几何指标

仅对 K2 trial 离线计算：

\[
q
=
\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d.
\]

要求：

1. 使用 Stage6 已验证的 projected metric；
2. 使用 truth center 和 truth separation，仅用于分析；
3. 不输入拟合器；
4. 不作为在线分支；
5. 不设置 q threshold；
6. 不删除低 q trial。

报告：

```text
q
joint RMSE
continuous upgrade/fallback
fixed-grid condition number
```

按 q 的四分位数只做描述性汇总：

```text
Q1 / Q2 / Q3 / Q4
```

不把 quartile 名称写成 easy/hard 在线状态。

---

## 14. 执行协议

本阶段规模较小，统一使用：

```text
1 个 MATLAB R2022b
-singleCompThread
```

禁止：

```text
parpool
parfor
多 MATLAB worker
Windows scheduled task
复杂 coordinator
```

Runtime root：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_v1
```

每个 trial 完成后原子写：

```text
checkpoints\<trial_id>.mat.tmp
→ reload
→ validate
→ checkpoints\<trial_id>.mat
```

恢复时：

```text
验证已有 checkpoint
跳过有效 trial
只运行缺失 trial
```

只需支持：

```text
Start
Status
Pause
Resume
Finalize
```

不实现复杂 ETA、sidecar、分片或定时任务。

---

## 15. 最终指标

### K1

报告：

```text
72/72 valid rate
CORE_LITE vs B0：
- overall median RMSE
- overall p90 RMSE
- off-grid C2/C3/C4 median RMSE
- off-grid p90 RMSE
- paired win/tie/loss
- continuous upgrade/fallback count
```

### K2

报告：

```text
72/72 valid rate
CORE_PLUS vs CORE_LITE：
- overall median RMSE
- overall p90 RMSE
- each profile median RMSE
- paired win/tie/loss
- continuous upgrade/fallback count
- q quartile RMSE
- q quartile fallback rate
```

### 复杂度

报告：

```text
mean score calls
mean SVD calls
median runtime
p90 runtime
```

不得把包含 shared initialization 的候选成本简单相加后称为精确生产成本。

---

## 16. 轻量统计

只对已完成 result rows 做：

```text
trial-level paired bootstrap
B = 1000
fixed seed = 3026073000
```

bootstrap 只重采样 trial-level paired differences：

```text
不重新运行 DML
不重新生成噪声
不进行 parametric bootstrap
```

输出：

```text
paired median RMSE difference 95% percentile CI
```

仅用于描述，不产生新在线 threshold。

---

## 17. 最终判定

### 17.1 CORE_LITE 通过

同时满足：

```text
144/144 CORE_LITE outputs valid
truth leakage = 0
tracking/cross-CPI flags = false
K1 off-grid paired median RMSE:
CORE_LITE < B0
K1 off-grid wins > losses
```

则：

```text
CORE_LITE_FINAL_PASS
```

否则：

```text
FINAL_KNOWN_K_CORE_NOT_CONFIRMED
```

停止，不继续调参。

### 17.2 CORE_PLUS 定位

在 `CORE_LITE_FINAL_PASS` 前提下：

若：

```text
144/144 CORE_PLUS outputs valid
K2 paired median RMSE CORE_PLUS <= CORE_LITE
K2 wins >= losses
```

则：

```text
CORE_PLUS_OPTIONAL_CONFIRMED
```

否则：

```text
CORE_PLUS_NOT_RETAINED_IN_FINAL_INTERFACE
```

不修改 solver，不改变 profile，不增加 trial。

### 17.3 最终唯一状态

只允许：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL

STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_LITE_ONLY

STAGE8_CORE_V2_2_FINAL_KNOWN_K_CORE_NOT_CONFIRMED

STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

---

## 18. 输出文件

只允许新增：

```text
innovation-mining/
28_stage8_core_v2_2_final_single_cpi_known_k_validation.md

28_stage8_core_v2_2_final_single_cpi_known_k_trials.csv

28_stage8_core_v2_2_final_single_cpi_known_k_summary.csv

28_stage8_core_v2_2_final_single_cpi_known_k_q_analysis.csv

28_stage8_core_v2_2_final_single_cpi_known_k_complexity.csv
```

更新：

```text
innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/stage8_execution_prompts/active/README.md
```

最终报告必须醒目标记：

```text
SINGLE_CPI
SINGLE_RANGE_DOPPLER_CELL
KNOWN_K_CONDITIONAL_ESTIMATION
NO_TRACKING_INPUT
NO_CROSS_CPI_INPUT
NO_MODEL_ORDER_CLAIM
NO_FORMAL_STAGE8_1_PASS
NO_STAGE8_2_AUTHORIZATION
```

---

## 19. 提交顺序

### 19.1 Prompt / scene-contract commit

新增：

```text
innovation-mining/stage8_execution_prompts/active/
007_stage8_core_v2_2_single_cpi_known_k_final_freeze_v1.md
```

并先更新编号 11 的场景定义，但不写入尚未运行的结果。

提交：

```text
docs(stage8-core): define single-CPI known-k final freeze
```

### 19.2 Production code commit

只提交：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/
```

提交：

```text
feat(stage8-core): integrate known-k local-cell ML interface
```

提交后工作树 clean，才允许运行 F0/F1/144 trials。

### 19.3 Final evidence commit

提交：

```text
innovation-mining/28_stage8_core_v2_2_final_single_cpi_known_k_*
innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/stage8_execution_prompts/active/README.md
```

将 007 prompt 移到：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

`active/README.md` 最终写为：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_CORE_V2_2_FINAL_FREEZE_COMPLETED
```

提交：

```text
docs(stage8-core): freeze final single-CPI known-k validation
```

每次只推送：

```powershell
git push origin experiment/stage8-core-v2
```

禁止：

```text
push main
merge main
创建新分支
force push
```

---

## 20. 最终冻结

完成后永久停止：

```text
Core-V3
自动 K
q_global
bootstrap threshold
resolved/unresolved
第三版 K2 solver
adaptive W/B
K=3
6000-trial
Stage8.2
```

后续只允许：

```text
论文正文整理
图表制作
公式—代码映射
参考文献与 baseline 讨论
在用户单独授权后审查是否把最终 Step12.7 集成到 main
```

---

## 21. 最终报告格式

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS / FAIL

Branch:
Starting HEAD:
Prompt commit:
Production code commit:
Evidence commit:
Push status:
Git clean:
origin/main unchanged:

Scenario:
- single CPI
- single range-Doppler cell
- no tracking
- no cross-CPI
- K externally given / scenario fixed

F0:
F1:

Independent registry:
- K1 72/72
- K2 72/72
- rows 288/288

CORE_LITE:
- valid
- K1 overall median/p90
- K1 off-grid median/p90
- paired wins/ties/losses
- score/SVD/runtime

CORE_PLUS:
- valid
- K2 overall median/p90
- profile medians
- paired wins/ties/losses
- upgrade/fallback
- q-quartile analysis
- score/SVD/runtime

Final state:
Model-order:
Formal 6000-trial:
Stage8.2:
MATLAB / lock / coordinator:
```
