# Stage8-Core-V2.2：F1 Canonical Oracle 修正与最终独立冻结验证（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 与 Git 的执行 AI。
>
> 本协议不是 Core-V3，也不是新算法实验。它只修正 V2.2 F1 中错误的历史回归
> oracle，并处理一个尚未触发的纯汇总解析缺陷；拟合公式、生产接口、候选 start、
> solver、144-trial registry、seed、判定规则和旧证据均保持不变。
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
> STAGE8_CORE_V2_2_F1_CANONICAL_ORACLE_CORRECTION_AND_FINAL_FREEZE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_2_F1_CANONICAL_ORACLE_CORRECTION_AND_FINAL_FREEZE_V1
> ```

---

## 0. 修复性质与最终目标

上一轮终态：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_FAIL
STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

只表示 V2.2 的 F1 regression oracle 内部不相容：

```text
最终 K1 生产路径：
CORE_LITE == CORE_PLUS == conventional singleton continuous K1

旧历史：
H1 K1 = conventional start
H2 K1 = grouped start

错误 F1：
要求同一个最终 conventional 路径同时逐位等于历史 H1 和历史 H2
```

历史 H1/H2 在 trial：

```text
R1_K1_N2_L1_SP6_INSIDE_OFF_GRID
```

上存在极小但非逐位相同的 angles/RSS/loglik，因此旧 F1 在逻辑上无解。

本修复后的 canonical 回归关系必须为：

```text
K1:
new CORE_LITE
==
new CORE_PLUS
==
historical H1_DIRECT_SAFE_HYBRID_KNOWN_K

historical H2 K1:
只保留为 NONCANONICAL_GROUPED_K1_DEVELOPMENT_ROUTE
不作为最终生产 K1 oracle

K2:
new CORE_LITE
==
historical B0_FIXED_GRID_KNOWN_K

new CORE_PLUS
==
historical H2_GROUPED_SAFE_HYBRID_KNOWN_K
```

本阶段最终目标仍是：

```text
修正 F1
→ 精确完成历史 24-trial 生产接口回归
→ 仅在 F1 精确通过后执行原注册 144-trial 独立 known-K 验证
→ 形成最终冻结结论
```

本阶段不允许：

```text
修改算法
修改 solver
放宽数值容差
增加 start
改变 144-trial registry
改变 seeds
改变最终判定门
恢复 automatic K
恢复 bootstrap
恢复 6000-trial
执行 Stage8.2
```

---

## 1. Git 锚点

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
4d37901fb24b6ac22ec126c4a275cfe4359d4c7f
```

关键祖先：

```text
c0f77ee4bcd94cc621f459c6e365c63c2bc4c669
docs(innovation): consolidate validated theory and archive superseded plans

5f042b75ba6733ffdd531229f81cec7660418ca1
Step12.7 production interface commit

4d37901fb24b6ac22ec126c4a275cfe4359d4c7f
V2.2 invalid-protocol evidence commit
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
HEAD == 4d37901fb24b6ac22ec126c4a275cfe4359d4c7f
origin/main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
工作树 clean
```

若探索分支已经由用户明确推进为 `4d37901` 的后代：

1. 记录实际起点；
2. 只允许既有额外提交为 docs-only 或本协议允许的修复；
3. 发现不明科学代码变化则硬停止；
4. 不得自动丢弃提交。

禁止：

```text
push main
merge main
创建新分支
force push
重写 4d37901
删除旧失败报告
删除旧 runtime
```

---

## 2. 必须保留的失败现场

旧失败报告必须保持字节不变：

```text
innovation-mining/
28_stage8_core_v2_2_final_single_cpi_known_k_validation.md

28_stage8_core_v2_2_final_single_cpi_known_k_trials.csv
28_stage8_core_v2_2_final_single_cpi_known_k_summary.csv
28_stage8_core_v2_2_final_single_cpi_known_k_q_analysis.csv
28_stage8_core_v2_2_final_single_cpi_known_k_complexity.csv
```

旧 runtime：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_v1
```

必须原样保留。

审计旧 runtime：

```text
f0_audit.mat present
f1_audit.mat present
protocol.mat absent
checkpoint count = 0
```

若发现旧 runtime 已被修改或已有 checkpoint：

```text
硬停止
```

新执行使用全新 runtime：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1
```

新 runtime 必须不存在；若已存在：

- 只有空目录才允许删除后重建；
- 若含任何文件，硬停止并报告；
- 不复用旧 F1 audit。

---

## 3. 科学代码冻结边界

以下生产科学代码不得修改：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/common/
estimate_stage8_known_k_local_cell.m

fit_stage8_core_lite.m
fit_stage8_core_plus.m
select_stage8_safe_known_k_candidate.m
refine_stage8_k1_continuous.m
refine_stage8_k2_center_difference.m
build_stage8_known_k_local_context.m
validate_stage8_known_k_local_cell_input.m
compute_stage8_projected_separation_geometry.m
stage8_core_v2_2_result_template.m
stage8_core_v2_2_stable_hash.m
```

以下 registry 和数据生成代码不得修改：

```text
validation/build_stage8_core_v2_2_final_registry.m
validation/generate_stage8_core_v2_2_trial.m
validation/build_stage8_core_v2_2_validation_context.m
```

以下旧工具和证据不得修改：

```text
tools/stage8_r1_continuous_decisive/
tools/stage8_core_v2_known_k/

innovation-mining/15_*
innovation-mining/16_*
innovation-mining/23_*
innovation-mining/24_*
innovation-mining/26_*
innovation-mining/27_*
innovation-mining/28_*
```

以下路径仍完全冻结：

```text
Step12.0–Step12.6
calibration/
results/
figures/
```

---

## 4. 允许修改的代码范围

只允许修改：

```text
step_12_7_known_k_local_cell_refinement/tests/
test_historical_24_trial_regression.m

step_12_7_known_k_local_cell_refinement/validation/
run_stage8_core_v2_2_final_validation.m

step_12_7_known_k_local_cell_refinement/validation/
summarize_stage8_core_v2_2_final_validation.m

step_12_7_known_k_local_cell_refinement/validation/
finalize_stage8_core_v2_2_final_validation.m
```

允许新增：

```text
step_12_7_known_k_local_cell_refinement/tests/
test_f1_canonical_oracle_contract.m

step_12_7_known_k_local_cell_refinement/tests/
test_summary_fixed_grid_rmse_contract.m
```

允许按需要新增一个纯测试 helper：

```text
parse_historical_angle_matrix.m
```

只能放在 `tests/` 中。

本次修改的性质只能是：

```text
回归 oracle 修正
协议身份/新 runtime 区分
汇总数值字段的机械修复
新输出文件名防覆盖
```

不得改变任何 fit 结果。

---

## 5. Canonical 历史证据

历史源文件：

```text
innovation-mining/
26_stage8_core_v2_known_k_pruning_trials.csv

innovation-mining/
27_stage8_core_v2_1_safe_hybrid_trials.csv
```

### 5.1 K1 canonical oracle

唯一 canonical K1 历史方法：

```text
H1_DIRECT_SAFE_HYBRID_KNOWN_K
```

理由：

```text
最终生产 K1 已明确只使用 conventional singleton continuous path。
```

历史：

```text
H2_GROUPED_SAFE_HYBRID_KNOWN_K
```

的 K1 行必须保留，但只标记：

```text
NONCANONICAL_GROUPED_K1_DEVELOPMENT_ROUTE
```

不得：

```text
要求 H1 == H2
用 H2 替代 H1
用容差把 H1/H2 合并
删除 H2 行
修改历史 CSV
```

### 5.2 K2 canonical oracle

CORE_LITE K2：

```text
26_* trials 中的 B0_FIXED_GRID_KNOWN_K
```

CORE_PLUS K2：

```text
27_* trials 中的 H2_GROUPED_SAFE_HYBRID_KNOWN_K
```

### 5.3 历史形状

必须精确存在：

```text
16 个 historical H1 K1 rows
16 个 historical H2 K1 rows
8 个 historical B0 K2 rows
8 个 historical H2 K2 rows
24 个唯一 trial IDs
```

同 trial 的历史行必须共享相同：

```text
trial_id
truth K
element_trial_hash
```

---

## 6. Gate F1A：静态 canonical oracle 合同

新增：

```matlab
audit = test_f1_canonical_oracle_contract(repo_dir)
```

只读取 26/27 CSV，不运行 fit。

必须检查：

```text
历史 row 数正确
K1 H1/H2 pairing 完整
K2 B0/H2 pairing 完整
同 trial element hash 一致
canonical method IDs 唯一
```

对 K1 H1/H2 差异：

```text
允许存在
必须记录
不得作为失败
```

audit 至少输出：

```text
status =
F1A_CANONICAL_ORACLE_CONTRACT_PASS

canonical_k1_method_id =
H1_DIRECT_SAFE_HYBRID_KNOWN_K

noncanonical_k1_method_id =
H2_GROUPED_SAFE_HYBRID_KNOWN_K

historical_k1_trial_count = 16
historical_k2_trial_count = 8
h1_h2_k1_difference_count
h1_h2_k1_difference_fields
```

必须确认已知差异 trial：

```text
R1_K1_N2_L1_SP6_INSIDE_OFF_GRID
```

被记录为 noncanonical difference，而不是被忽略。

不得设置角度/RSS/loglik 容差。

---

## 7. Gate F1B：真正的 24-trial 生产接口回归

重写：

```matlab
test_historical_24_trial_regression(repo_dir)
```

它必须实际运行新的 Step12.7 公开接口，而不是只比较历史 H1/H2。

### 7.1 历史 trial 重建

在测试作用域内只读加入：

```text
tools/stage8_r1_continuous_decisive/matlab/
```

使用：

```matlab
context = stage8_r1_context(repo_dir, true);
registry = stage8_r1_build_registry(context, 'FORMAL');
trial = stage8_r1_generate_trial(spec, context);
```

要求：

```text
registry = 24 rows
K1 = 16
K2 = 8
```

每个 `trial.element_trial_hash` 必须逐 trial 匹配历史 26/27 CSV。

测试结束后恢复 MATLAB path；生产接口不得永久依赖 `tools/`。

### 7.2 调用新生产接口

对每个 trial：

```matlab
lite = estimate_stage8_known_k_local_cell( ...
    trial.Y_element, trial.model, context.plan.local_domain, ...
    context.stage5_locked, trial.model.noise_factorization, ...
    spec.truth_K, struct('mode','CORE_LITE'));

plus = estimate_stage8_known_k_local_cell( ...
    trial.Y_element, trial.model, context.plan.local_domain, ...
    context.stage5_locked, trial.model.noise_factorization, ...
    spec.truth_K, struct('mode','CORE_PLUS'));
```

### 7.3 K1 精确合同

对 16 个 K1 trial：

第一步，两个新 mode 必须逐位相同：

```text
num2hex(angles)
num2hex(RSS)
num2hex(loglik)
fit_valid
fit_status
selected_source
selected_start_id
solver status
```

即：

```text
new CORE_LITE == new CORE_PLUS
```

第二步，两者均必须逐位匹配历史 H1 canonical row：

```text
new CORE_LITE == historical H1
new CORE_PLUS == historical H1
```

比较字段：

```text
angles
RSS
loglik
fit_valid
fit_status
solver_status
selected_source
selected_start_id
element_trial_hash
```

不得要求匹配历史 H2 K1。

### 7.4 K2 CORE_LITE 精确合同

对 8 个 K2 trial：

```text
new CORE_LITE
==
historical B0_FIXED_GRID_KNOWN_K
```

比较：

```text
angles num2hex
RSS num2hex
loglik num2hex
fit_valid
fit_status
solver_status
selected start
element_trial_hash
```

新 `selected_source` 应为：

```text
FIXED_GRID_CORE_LITE
```

它不需要等于 B0 的 method ID，但候选科学字段必须相同。

### 7.5 K2 CORE_PLUS 精确合同

对 8 个 K2 trial：

```text
new CORE_PLUS
==
historical H2_GROUPED_SAFE_HYBRID_KNOWN_K
```

比较：

```text
angles num2hex
RSS num2hex
loglik num2hex
fit_valid
fit_status
solver_status
selected_source
selected_start_id
continuous upgrade/fallback
element_trial_hash
```

### 7.6 历史角度字符串解析

历史 CSV 的 `final_angles` 必须通过确定性数值 token parser 解析：

```text
提取十进制/科学计数法 numeric tokens
str2double
按 K 重建 1×2 或 2×2 matrix
```

禁止直接使用：

```matlab
sscanf('[...]','%f')
```

禁止 `eval`。

17-digit decimal 必须 round-trip 后用 `num2hex` 比较。

### 7.7 F1B 输出

通过时：

```text
F1B_PRODUCTION_24_TRIAL_REGRESSION_PASS
```

audit 至少包含：

```text
24/24 element hashes matched
16/16 K1 mode identity matched
16/16 K1 H1 canonical matched
8/8 K2 CORE_LITE B0 matched
8/8 K2 CORE_PLUS H2 matched
truth leakage = 0
tracking input = 0
cross-CPI input = 0
```

若任一精确比较失败：

```text
F1B_FAIL_STOPPED
```

不得：

```text
改容差
改 solver
改历史 CSV
跳过 trial
继续 144-trial
```

这时才可判定为真实的 production-code promotion mismatch。

---

## 8. Runner 修正

修改：

```text
run_stage8_core_v2_2_final_validation.m
```

### 8.1 Gate 顺序

`START` 必须执行：

```text
F0
→ F1A
→ F1B
→ build unchanged 144-trial registry
→ initialize corrected protocol
→ execute pending
```

分别保存：

```text
f0_audit.mat
f1a_oracle_audit.mat
f1b_production_regression_audit.mat
```

### 8.2 协议身份

新 protocol version：

```text
STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_F1_ORACLE_CORRECTION_V1
```

默认新 runtime root：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1
```

`RESUME` 只接受新 protocol version。

不得读取或修改旧 V1 runtime。

### 8.3 Registry 不变

必须调用原有、未修改的：

```matlab
build_stage8_core_v2_2_final_registry(...)
```

断言：

```text
144 trials
72 K1
72 K2
288 result rows
```

不得改变 registry function 或 seed。

---

## 9. Finalizer 前的机械汇总修复

当前 summarizer 把 fixed-grid angles 保存为 `mat2str` 字符串，随后尝试：

```matlab
sscanf(char_value, '%f')
```

直接解析带 `[`、`]`、`;` 的字符串；这可能在 144 个 checkpoint 完成后才失败。

必须做以下机械修复，不改变任何 fit 或 decision。

### 9.1 在 `row_local` 直接计算数值 RMSE

已有：

```matlab
truth = checkpoint.trial.truth_angles_deg;
fixed = result.fixed_grid_candidate;
```

直接执行：

```matlab
fixed_estimate = match_targets_local(fixed.angles_hat_deg, truth);
fixed_error = fixed_estimate - truth;
fixed_grid_joint_rmse_deg = ...
    sqrt(mean(sum(fixed_error.^2, 2)));
```

在 row 中新增：

```text
fixed_grid_joint_rmse_deg
```

### 9.2 Summary 使用数值字段

将：

```matlab
fixed_grid_rmse_local(...)
```

改为直接返回：

```matlab
rows.fixed_grid_joint_rmse_deg
```

不得通过字符串重新解析科学数据。

### 9.3 单元测试

新增：

```matlab
test_summary_fixed_grid_rmse_contract
```

至少覆盖：

```text
K1 1×2 angles
K2 2×2 angles
target permutation matching
finite RMSE
不调用 eval
不依赖 mat2str reparse
```

### 9.4 决策规则不变

不得修改：

```text
CORE_LITE pass gate
CORE_PLUS optional gate
paired win/tie/loss
trial-level bootstrap seed/B
q quartile
validity requirements
```

---

## 10. 新 final evidence 文件名

旧 28_* 是 V2.2 invalid-protocol 证据，不得覆盖。

修改 finalizer，使 corrected run 只写：

```text
innovation-mining/
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_validation.md

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_trials.csv

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_summary.csv

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_q_analysis.csv

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_complexity.csv
```

若任一 29_* 已存在，拒绝覆盖。

报告必须包含：

```text
旧 invalid report:
28_stage8_core_v2_2_final_single_cpi_known_k_validation.md

correction:
F1 canonical K1 oracle changed from impossible H1+H2 equality
to final conventional H1 only

production scientific code changed:
false

registry/seeds changed:
false

F0
F1A
F1B
144/144 completeness
final decision
```

并写出 summary 中的关键指标，而不只写 final state。

---

## 11. 预提交测试

在任何提交前，运行：

```text
MATLAB checkcode
PowerShell/Git scope audit
test_f1_canonical_oracle_contract
test_summary_fixed_grid_rmse_contract
existing public input test
existing no-truth/tracking dependency test
existing safe-selection test
existing final-registry contract test
```

这里不运行 F1B 的 24 个真实 fits，直到修复提交完成、推送、工作树 clean。

静态测试必须证明：

```text
生产 common/ 科学文件无 diff
registry/generator 无 diff
15/16/23/24/26/27/28 无 diff
Step12.0–12.6 无 diff
```

---

## 12. 提交 1：修复协议说明

新增：

```text
innovation-mining/stage8_execution_prompts/active/
008_stage8_core_v2_2_f1_canonical_oracle_correction_v1.md
```

更新：

```text
innovation-mining/stage8_execution_prompts/active/README.md
```

状态：

```text
F1_CANONICAL_ORACLE_CORRECTION_AUTHORIZED
NO_ALGORITHM_CHANGE
```

提交：

```text
docs(stage8-core): define F1 canonical oracle correction
```

只推送：

```powershell
git push origin experiment/stage8-core-v2
```

---

## 13. 提交 2：测试和 finalizer 修复

只暂存本协议允许的 Step12.7 tests/validation 文件。

提交：

```text
fix(stage8-core): correct F1 oracle and final summary contract
```

提交后检查：

```text
Git clean
HEAD == origin/experiment/stage8-core-v2 after push
origin/main unchanged
生产 common/ 科学代码无 diff
registry/generator 无 diff
```

推送后才允许正式运行 F0/F1A/F1B。

---

## 14. 正式 Gate 执行

使用：

```text
MATLAB R2022b
-singleCompThread
1 个 MATLAB process
```

新 runtime：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1
```

先执行 `START`。

### 14.1 若 F0 失败

停止。

### 14.2 若 F1A 失败

表示历史 canonical mapping 本身不完整，停止。

### 14.3 若 F1B 失败

表示 Step12.7 生产接口不能精确复现选定的 canonical 历史路线。

停止，且不得：

```text
运行 144 trials
修改 solver
修改容差
修改旧 evidence
```

### 14.4 只有 F1B PASS

才允许自动进入原注册 144-trial 独立验证。

---

## 15. 144-trial 独立验证保持完全不变

不得修改：

```text
72 K1 specs
72 K2 specs
centers
separations
directions
SNR
L
noise profiles
source powers
correlations
source seeds
noise seeds
single-CPI flags
same range-Doppler cell flags
```

每 trial 运行：

```text
CORE_LITE
CORE_PLUS
```

K1 必须继续断言：

```text
CORE_LITE == CORE_PLUS
```

每 trial 原子 checkpoint。

允许：

```text
Pause
Resume
Status
Finalize
```

不使用多 worker，不使用 parpool/parfor，不注册定时任务。

---

## 16. Finalize 条件

Finalize 前必须满足：

```text
144/144 valid checkpoints
72 K1
72 K2
288 result rows
tmp checkpoint = 0
pause request absent
protocol version correct
F0 PASS
F1A PASS
F1B PASS
```

Finalize 使用原判定规则，只允许输出：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL

STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_LITE_ONLY

STAGE8_CORE_V2_2_FINAL_KNOWN_K_CORE_NOT_CONFIRMED

STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

不得根据结果调参或重跑不同 registry。

---

## 17. Final evidence 提交

成功或科学门失败都要提交真实 29_* 结果。

更新：

```text
innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/stage8_execution_prompts/active/README.md
```

规则：

```text
若 final pass：
写入最终 independent known-K validation status

若 scientific not confirmed：
诚实写入负结果，不改变旧 V2.1 证据

若 F1B fail：
不创建伪 29 trial/summary；只创建 correction failure report
```

将 008 prompt 移至：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

active README 最终：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_CORE_V2_2_F1_ORACLE_CORRECTION_COMPLETED
```

提交：

```text
docs(stage8-core): record corrected final known-k freeze
```

只推送：

```powershell
git push origin experiment/stage8-core-v2
```

---

## 18. 完成后永久停止

不得自动继续：

```text
Core-V3
第三版 K2 solver
automatic K
q_global
bootstrap threshold
resolved/unresolved
adaptive W/B
K=3
6000-trial
Stage8.2
```

后续只允许：

```text
论文整理
图表
公式—代码映射
baseline 与参考文献讨论
单独审查是否将最终 Step12.7 集成 main
```

---

## 19. 最终报告格式

```text
STAGE8_CORE_V2_2_F1_ORACLE_CORRECTION_PASS / FAIL

Branch:
Starting HEAD:
Prompt commit:
Fix commit:
Evidence commit:
Push status:
Git clean:
origin/main unchanged:

Old invalid evidence:
- report path
- old runtime
- old checkpoint count = 0

Scientific production code changed:
Registry changed:
Seeds changed:
Decision rules changed:

F0:
F1A:
- canonical K1 oracle
- noncanonical H2 difference count

F1B:
- 24/24 element hashes
- K1 new mode identity 16/16
- K1 H1 canonical match 16/16
- K2 CORE_LITE B0 match 8/8
- K2 CORE_PLUS H2 match 8/8

Independent validation:
- K1 72/72
- K2 72/72
- rows 288/288

CORE_LITE:
- valid
- K1 overall median/p90
- K1 off-grid median/p90
- K1 paired wins/ties/losses
- score/SVD/runtime

CORE_PLUS:
- valid
- K2 overall median/p90
- profile medians
- paired wins/ties/losses
- upgrades/fallbacks
- q quartile analysis
- score/SVD/runtime

Final state:
Model-order:
Formal 6000-trial:
Stage8.2:
MATLAB / lock / coordinator:
```
