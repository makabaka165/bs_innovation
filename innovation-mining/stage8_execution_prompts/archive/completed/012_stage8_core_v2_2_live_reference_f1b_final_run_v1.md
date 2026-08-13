# Stage8-Core-V2.2：移除有损 CSV 位级 Oracle，使用同会话 Live Reference 完成最终冻结（V1）

> 唯一目标：修正 F1B 的参考对象，然后直接完成既定 144-trial。
> 不再修改 F0，不再增加控制门，不修改任何算法、solver、registry、seed 或判定规则。
>
> 目标分支：
>
> ```text
> experiment/stage8-core-v2
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_2_LIVE_REFERENCE_F1B_AND_FINAL_RUN_V1
> ```

---

## 0. 当前结论

当前 HEAD 预期为：

```text
4138885716159fb1f163f5b8754382c36865a5c6
```

稳定 main：

```text
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

已通过：

```text
Structured F0 Preflight
F0_BOUNDARY_AND_ENVIRONMENT_PASS
F1A_CANONICAL_ORACLE_CONTRACT_PASS
```

当前 F1B 停在：

```text
R1_K1_N1_L1_SM6_ON_GRID
K1_CORE_LITE_H1.RSS
exact bit-level mismatch
```

根因不是 production fit，而是历史 `26_* / 27_*` CSV 的数值序列化：

```text
final_angles:
以 mat2str(...,17) 字符串保存，可 round-trip

RSS / loglik:
作为 numeric table column 由 writetable 默认写入，
例如 RSS=10.1843442178699，仅 15 个有效十进制数字，
不能作为任意 IEEE-754 double 的原始 bit pattern。
```

现有 F1B 却执行：

```matlab
num2hex(new_result.rss)
==
num2hex(str2double(historical_csv.RSS))
```

该比较在数据格式上没有定义良好的“原始位级真值”。

正确回归 oracle 是：

```text
在同一个 MATLAB 会话、同一 Y_element、同一 measurement 下，
直接运行冻结的历史 B0/B1/B2 工具实现，
在内存中构造 H1/H2，
再与 Step12.7 新公开接口进行 exact num2hex 比较。
```

历史 CSV 继续用于：

```text
trial identity
element_trial_hash
method/status/selection evidence
```

但不再作为 RSS/loglik 的位级 oracle。

---

## 1. Git 和边界

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
HEAD == 4138885716159fb1f163f5b8754382c36865a5c6
origin/main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
working tree clean
```

若 HEAD 是 `413888` 的已知 docs-only 后代，记录实际 HEAD 并继续；若存在未知 `.m`、CSV 或 evidence 修改，停止。

确认：

```text
MATLAB / mwpython / legacy orchestrator / lock = 0 / 0 / 0 / 0
29_* evidence absent
```

---

## 2. 本次禁止修改

不得修改：

```text
Step12.7 common/**
K1 continuous solver
K2 center-difference solver
safe selection
public interface

F0 structured process snapshot/classifier
F1A
directory inventory
summary/finalizer

144-trial registry
trial generator
source/noise seeds
decision rules

Step12.0–Step12.6
tools/stage8_r1_continuous_decisive/**
tools/stage8_core_v2_known_k/**
15/16/23/24/26/27/28 evidence
origin/main
```

本次不允许：

```text
新增 ULP 门
新增 relative/absolute tolerance
修改历史 CSV
调 solver
增加 start
新增 trial
修改 profile
```

---

## 3. 允许修改

只允许修改：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/tests/
test_historical_24_trial_regression.m
```

允许新增一个纯测试 helper：

```text
tests/build_stage8_core_v2_live_reference_rows.m
```

允许新增本提示词：

```text
innovation-mining/stage8_execution_prompts/active/
012_stage8_core_v2_2_live_reference_f1b_final_run_v1.md
```

不得修改 runner；正式执行时传入新的 runtime 路径即可。

---

## 4. Live Reference 构建

新增：

```matlab
[reference_rows, reference_hybrid_rows, audit] = ...
    build_stage8_core_v2_live_reference_rows(repo_dir)
```

### 4.1 路径作用域

临时、只读加入：

```text
tools/stage8_r1_continuous_decisive/matlab
tools/stage8_core_v2_known_k/matlab
Step12.7 common/tests
```

函数结束后恢复原 MATLAB path。

### 4.2 重建历史 24-trial

使用：

```matlab
context = stage8_r1_context(repo_dir, true);
registry = stage8_r1_build_registry(context, 'FORMAL');
```

要求：

```text
24 trials
16 K1
8 K2
```

逐 trial 调用：

```matlab
[rows, diagnostics] = stage8_core_v2_evaluate_trial(spec, context);
```

收集为：

```text
72 live B0/B1/B2 rows
```

要求：

```text
每 trial 3 rows
每 trial 一个 element_trial_hash
truth leakage = 0
```

### 4.3 内存内构造 H1/H2

直接调用冻结的：

```matlab
[reference_hybrid_rows, hybrid_audit] = ...
    stage8_core_v2_build_hybrid_rows(reference_rows);
```

得到：

```text
48 live H1/H2 rows
```

此过程不得经过：

```text
writetable
CSV
JSON
文本 round-trip
```

### 4.4 历史 CSV 只做身份审计

读取：

```text
26_stage8_core_v2_known_k_pruning_trials.csv
27_stage8_core_v2_1_safe_hybrid_trials.csv
```

只检查：

```text
24 trial IDs
element_trial_hash
method IDs
fit_valid
fit_status
solver_status
selected_source
selected_start_id
upgrade/fallback flags
```

不得用 CSV 中的：

```text
RSS
loglik
estimate_target*
known_K_*RMSE
```

作为 exact binary oracle。

记录：

```text
csv_numeric_fields_used_as_bit_oracle = false
live_reference_used = true
live_reference_serialization_roundtrip_count = 0
```

---

## 5. 重写 F1B

对每个历史 trial，先由 `stage8_r1_generate_trial` 得到 `Y_element`，再调用新接口：

```matlab
lite = estimate_stage8_known_k_local_cell(..., 'CORE_LITE');
plus = estimate_stage8_known_k_local_cell(..., 'CORE_PLUS');
```

### 5.1 K1

Live canonical row：

```text
reference H1_DIRECT_SAFE_HYBRID_KNOWN_K
```

要求：

```text
new CORE_LITE == new CORE_PLUS
new CORE_LITE == live H1
new CORE_PLUS == live H1
```

Exact 比较：

```text
angles num2hex
RSS num2hex
loglik num2hex
fit_valid
fit_status
selected_source
selected_start_id
selected solver status
element_trial_hash
```

### 5.2 K2 CORE_LITE

Live canonical row：

```text
reference B0_FIXED_GRID_KNOWN_K
```

要求 exact：

```text
angles
RSS
loglik
fit_valid
fit_status
selected start
solver status
element_trial_hash
```

新 `selected_source` 必须：

```text
FIXED_GRID_CORE_LITE
```

### 5.3 K2 CORE_PLUS

Live canonical row：

```text
reference H2_GROUPED_SAFE_HYBRID_KNOWN_K
```

要求 exact：

```text
angles
RSS
loglik
fit_valid
fit_status
selected_source
selected_start_id
solver status
upgrade/fallback
element_trial_hash
```

### 5.4 F1B 输出

通过：

```text
F1B_PRODUCTION_24_TRIAL_LIVE_REFERENCE_PASS

24/24 element hashes
16/16 K1 mode identity
16/16 K1 live H1
8/8 K2 CORE_LITE live B0
8/8 K2 CORE_PLUS live H2
truth/tracking/cross-CPI/K-estimation = 0
CSV numeric bit-oracle usage = 0
```

失败时必须报告：

```text
trial_id
field
new num2hex
live reference num2hex
```

若 live exact 比较失败：

```text
停止
不修改算法
不改容差
不执行 144-trial
```

---

## 6. 轻量测试

只新增以下测试：

### A. Lossy CSV oracle audit

读取首个历史 K1 row，确认：

```text
final_angles 是 17-digit text
RSS/loglik 是 numeric CSV fields
```

只输出：

```text
CSV_NUMERIC_NOT_REGISTERED_AS_BIT_ORACLE_PASS
```

不要围绕 ULP 数量建立门。

### B. One-trial live smoke

对：

```text
R1_K1_N1_L1_SM6_ON_GRID
```

运行：

```text
live old H1
new CORE_LITE
new CORE_PLUS
```

要求内存内 exact match。

该测试通过后，再提交代码。

---

## 7. 提交

### Prompt commit

```text
docs(stage8-core): define lossless live-reference F1B
```

### Test fix commit

只提交：

```text
test_historical_24_trial_regression.m
build_stage8_core_v2_live_reference_rows.m
```

提交：

```text
fix(stage8-core): replace lossy CSV bit oracle with live reference
```

推送：

```powershell
git push origin experiment/stage8-core-v2
```

要求：

```text
Git clean
HEAD == origin/experiment/stage8-core-v2
origin/main unchanged
```

---

## 8. 正式执行

不复用当前 F1B-failure runtime。

保留原路径不改，使用新路径：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_live_reference_v1
```

该路径必须不存在。

先执行只读：

```text
Preflight
```

F0 已通过一次，若本次出现真实外部进程则停止；不得再修改 F0。

然后执行：

```text
Start
```

顺序：

```text
F0
F1A
corrected live-reference F1B
unchanged 144-trial
```

只有 live-reference F1B PASS 才运行 144-trial。

---

## 9. 144-trial 与 Finalize

完全复用当前：

```text
72 K1
72 K2
144 checkpoints
288 rows
registry/seeds/profiles/decision unchanged
```

单 MATLAB R2022b：

```text
-singleCompThread
```

完成后：

```text
Status:
completed=144
remaining=0
tmp=0
lock=0
```

执行 Finalize，写入现有注册的：

```text
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_*
```

不得根据结果调参或重跑不同 seed。

---

## 10. 最终处理

根据真实 144-trial 结果，仅允许：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_LITE_ONLY
STAGE8_CORE_V2_2_FINAL_KNOWN_K_CORE_NOT_CONFIRMED
STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

完成后：

```text
归档 active prompts 008–012
active README = NO_ACTIVE_STAGE8_EXECUTION
永久停止 F0/F1 扩展、Core-V3、automatic K、bootstrap、第三版 K2 solver、
6000-trial 和 Stage8.2
```

---

## 11. 最终报告必须回答

```text
1. 原 F1B 为什么无效：
   numeric CSV was lossy and was incorrectly used as a bit oracle

2. 科学 production code 是否改变：
   false

3. F0/F1A 是否改变：
   false

4. Live F1B：
   24/24 exact in-memory regression

5. Independent validation：
   72 K1 + 72 K2

6. Final state
```
