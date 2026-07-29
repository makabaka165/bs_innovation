# Stage8-Core-V2.1：安全回退 Known-K 核心闭环与 Grouped 初始化最终定位（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 和 Git 的 Codex。
>
> 本协议只允许在：
>
> ```text
> experiment/stage8-core-v2
> ```
>
> 上执行。
>
> 本阶段不设计第三版连续 K2 solver，不增加 trial，不恢复 unknown-K LRT、bootstrap、
> 6000-trial 或 Stage8.2。它只把已经提交的 B0/B1/B2 known-K 结果收束为一个
> 工程可用的安全算法：
>
> ```text
> fixed-grid valid fit 作为保底
> +
> continuous fit 有效且 likelihood 更高时升级
> ```
>
> 并据此最终判断 grouped/conditional initialization 是：
>
> ```text
> RETAIN
> OPTIONAL
> PRUNE
> ```
>
> 协议：
>
> ```text
> STAGE8_CORE_V2_1_SAFE_HYBRID_KNOWN_K_CLOSURE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_1_SAFE_HYBRID_KNOWN_K_CLOSURE_V1
> ```

---

## 0. 当前不可变状态

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

稳定 main：

```text
origin/main
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

唯一探索分支：

```text
experiment/stage8-core-v2
```

预期起点：

```text
1581550b675b12e7c7c1bfd0541b4fbc52f39923
docs(stage8-core): record grouped-initialization pruning result
```

现有工具提交：

```text
7271fd5e60a73c0bf20d24f38d15d2c24c76fd25
```

现有结果：

```text
innovation-mining/26_stage8_core_v2_known_k_pruning_experiment.md
innovation-mining/26_stage8_core_v2_known_k_pruning_trials.csv
innovation-mining/26_stage8_core_v2_known_k_pruning_summary.csv
innovation-mining/26_stage8_core_v2_known_k_pruning_comparison.csv
```

已知状态：

```text
K1:
B1 16/16 valid
B2 16/16 valid
off-grid median RMSE = 0.0113885676 degree

K2:
B0 8/8 valid
B1 2/8 valid
B2 4/8 valid

B2 valid-case K2 median RMSE = 0.0936479172 degree
B1 valid-case K2 median RMSE = 0.1494372541 degree

current conclusion:
STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP
```

当前科学解释：

```text
continuous K1 core is operational
continuous K2 refinement is partially useful but not reliably returning
fixed-grid known-K K2 remains an always-valid fallback
unknown-K model order remains deferred
```

---

## 1. 本阶段唯一目标

回答：

```text
Q1. 在不修改任何现有 solver 的条件下，
    “fixed-grid fallback + valid continuous upgrade”
    是否能形成 24/24 有效的 known-K 核心？

Q2. Direct hybrid 与 grouped hybrid 在同一安全回退策略下，
    哪个具有更好的 K2 精度/复杂度折中？

Q3. Grouped initialization 最终应作为核心必需项、可选 rescue start，
    还是从精简算法中剪枝？
```

本阶段不回答：

```text
unknown K
false split
missed split
LRT threshold
bootstrap
resolved/unresolved
Stage8.2
```

---

## 2. Git 边界

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
HEAD == 1581550b675b12e7c7c1bfd0541b4fbc52f39923
origin/main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
working tree clean
```

若探索分支已由用户明确推进到 `1581550` 的后代：

- 只允许新增本协议允许的路径；
- 记录实际 starting HEAD；
- 不允许丢弃未知提交；
- 发现不明算法修改则停止。

禁止：

```text
push main
merge main
创建新分支
force push
修改历史结果
修改 frozen Stage8 step
```

---

## 3. 严格禁止修改

不得修改：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_6_k12_bootstrap_resolution/

beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_3_grouped_conditional_dml/

beamspace_ml_v18/.../calibration/
beamspace_ml_v18/.../results/

innovation-mining/23_stage8_compact_algorithm_diagnostic*
innovation-mining/24_stage8_r1_continuous_refinement_decisive*
innovation-mining/25_stage8_core_v2_known_k_refactor.md
innovation-mining/26_stage8_core_v2_known_k_pruning_*

innovation-mining/stage8_execution_prompts/archive/

tools/stage8_1b_validation_sharded/
tools/stage8_compact_diagnostic/
tools/stage8_r1_continuous_decisive/
```

不得修改现有 Core-V2 solver：

```text
tools/stage8_core_v2_known_k/matlab/
stage8_core_v2_k2_center_difference_solver.m
stage8_core_v2_fit_known_k.m
```

本阶段不放宽：

```text
sweeps
tolerance
rank
minimum separation
start count
```

---

## 4. 安全 Hybrid 算法定义

新增两个 known-K 方法。

### 4.1 H1 Direct Hybrid

```text
H1_DIRECT_SAFE_HYBRID_KNOWN_K
```

候选：

```text
B0 fixed-grid known-K fit
B1 direct continuous known-K fit
```

选择规则：

1. B0 必须有效，否则 experiment invalid；
2. 若 B1 无效，选择 B0；
3. 若 B1 有效：
   - 比较 concentrated log-likelihood；
   - 选择 log-likelihood 更高者；
   - 数值并列时选择 B1；
4. 选择不得使用 truth 或 RMSE；
5. 输出 selected source：
   ```text
   CONTINUOUS_UPGRADE
   FIXED_GRID_FALLBACK
   ```

### 4.2 H2 Grouped Hybrid

```text
H2_GROUPED_SAFE_HYBRID_KNOWN_K
```

候选：

```text
B0 fixed-grid known-K fit
B2 grouped continuous known-K fit
```

选择规则与 H1 完全相同。

### 4.3 重要性质

因为 B0 是注册 fixed-grid valid fit：

```text
H1/H2 必须始终返回一个 valid known-K fit
```

如果 B0 无效：

```text
STAGE8_CORE_V2_1_EXPERIMENT_INVALID
```

Hybrid 只解决求解可靠性，不声称连续 solver 在所有 trial 中收敛。

---

## 5. 不重新执行 24 个底层拟合

本阶段优先直接读取已经提交的：

```text
innovation-mining/26_stage8_core_v2_known_k_pruning_trials.csv
```

该文件已经包含同一 element trial 的：

```text
B0
B1
B2
RSS
loglik
fit_valid
angles
RMSE
score/SVD/runtime
```

不得重复运行 24 个底层 B0/B1/B2 fits。

只执行确定性的 hybrid selection 和汇总。

这样：

```text
不增加 Monte Carlo
不重复连续优化
不引入新的随机误差
```

---

## 6. 最小代码

只允许新增：

```text
tools/stage8_core_v2_known_k/matlab/
stage8_core_v2_select_safe_hybrid.m

tools/stage8_core_v2_known_k/matlab/
stage8_core_v2_build_hybrid_rows.m

tools/stage8_core_v2_known_k/tests/
test_safe_hybrid_selection.m
```

允许为 Finalize 增加一个独立文件：

```text
tools/stage8_core_v2_known_k/matlab/
stage8_core_v2_finalize_hybrid.m
```

不得修改原 26_* Finalize 和原 solver。

### 6.1 `stage8_core_v2_select_safe_hybrid`

输入：

```text
one B0 row
one continuous row
hybrid method ID
```

检查：

```text
同 trial_id
同 element_trial_hash
同 truth_K
B0 fit_valid = true
truth leakage flags = false
```

选择只使用：

```text
fit_valid
loglik
method identity
```

不得读取：

```text
truth
RMSE
difficulty
noise
L
SNR
```

输出：

```text
hybrid row
selected_source
continuous_upgrade_flag
fallback_flag
```

### 6.2 成本记账

Hybrid 的实际实现应共享一次 initialization factory，然后分别评价：

```text
B0 fixed-grid candidate
continuous candidate
```

现有 `26_*` CSV 中每个 method row 的 `score_calls/SVD_calls/runtime`
都已经包含同一份 shared-initialization 成本，因此直接把 B0 和 continuous
两行相加会重复计费。

本阶段不得伪造“精确 hybrid 总成本”。输出以下两组可审计指标：

```text
B0 candidate cost
continuous candidate cost
```

并可额外给出：

```text
conservative_upper_bound = B0 row + continuous row
```

但必须标记：

```text
DOUBLE_COUNTS_SHARED_INITIALIZATION
```

Grouped RETAIN/OPTIONAL/PRUNE 不由这一保守上界单独触发。

---

## 7. 最小 Gate

只保留两个 Gate。

### Gate H0：边界

检查：

```text
branch = experiment/stage8-core-v2
1581550 is ancestor
origin/main unchanged at 247fad
working tree clean before execution
26_* files unchanged
frozen paths unchanged
MATLAB/lock/coordinator = 0/0/0
```

### Gate H1：selection correctness

使用 4 个既有 K2 trial：

```text
R1_K2_N1_L4_EASY
R1_K2_N1_L4_MODERATE
R1_K2_N1_L8_MODERATE
R1_K2_N2_L8_MODERATE
```

必须覆盖：

```text
continuous invalid → fallback
continuous valid and loglik better → upgrade
B1 valid / B2 invalid
B1 invalid / B2 valid
```

检查：

```text
selection deterministic
truth not read
selected loglik >= B0 loglik
all H1/H2 rows valid
element identity unchanged
```

不需要重新做 1-worker/2-worker gate，因为本阶段不运行并行 fit，只做确定性表格选择。

---

## 8. 汇总指标

对 H1/H2 分别计算：

```text
K1 valid / 16
K2 valid / 8

K1 off-grid median RMSE
K2 overall median RMSE
K2 easy median RMSE
K2 moderate median RMSE

continuous upgrade count
fixed-grid fallback count

K2 wins / ties / losses
relative to the other hybrid

B0 candidate score/SVD/runtime
continuous candidate score/SVD/runtime
conservative double-counted upper bound（仅说明，不作单独 gate）
```

单 trial H2 vs H1：

```text
RMSE_H2 < RMSE_H1 - 1e-3 → H2_WIN
RMSE_H1 < RMSE_H2 - 1e-3 → H2_LOSS
otherwise → TIE
```

---

## 9. Operational Gate

H1/H2 分别 operational，当且仅当：

```text
K1 valid = 16/16
K2 valid = 8/8
K1 off-grid median RMSE <= 0.05 degree
K2 overall median RMSE <= 0.20 degree
truth leakage = 0
```

由于 B0 fallback 存在，若 K2 valid 仍低于 8：

```text
STAGE8_CORE_V2_1_EXPERIMENT_INVALID
```

---

## 10. Grouped 最终定位

### RETAIN

只有同时满足：

```text
H2 operational
H1 not operational

或

H1/H2 operational，且：
H2 wins >= 5/8
H2 K2 median RMSE <= 0.95 * H1 K2 median RMSE
```

输出：

```text
STAGE8_CORE_V2_1_OPERATIONAL_GROUPED_RETAIN
```

### PRUNE

只有同时满足：

```text
H1 operational
H2 not operational

或

H1/H2 operational，且：
H2 losses >= 5/8
H2 K2 median RMSE >= 1.05 * H1 K2 median RMSE
```

输出：

```text
STAGE8_CORE_V2_1_OPERATIONAL_GROUPED_PRUNE
```

### OPTIONAL

若 H1/H2 都 operational，但 grouped 没有达到 RETAIN 或 PRUNE 的明确证据：

```text
STAGE8_CORE_V2_1_OPERATIONAL_GROUPED_OPTIONAL
```

成本只作为说明，不单独触发 RETAIN/PRUNE。

原因：

```text
当前样本仅 8 个 K2 trials
不能用小样本的运行时间微差直接淘汰初始化路线
```

---

## 11. 预期的解释边界

允许表述：

```text
known-K safe hybrid core is operational on the registered 24-trial diagnostic set
continuous K1 materially reduces off-grid error
grouped starts may improve K2 refinement success, but are optional unless the paired hybrid comparison meets RETAIN
```

禁止表述：

```text
unknown-K solved
false split controlled
formal validation passed
grouped initialization universally superior
Stage8.2 authorized
```

---

## 12. 输出

只允许新增：

```text
innovation-mining/27_stage8_core_v2_1_safe_hybrid_closure.md
innovation-mining/27_stage8_core_v2_1_safe_hybrid_trials.csv
innovation-mining/27_stage8_core_v2_1_safe_hybrid_summary.csv
innovation-mining/27_stage8_core_v2_1_safe_hybrid_comparison.csv
```

报告必须醒目标记：

```text
KNOWN_K_SAFE_HYBRID_DIAGNOSTIC_ONLY
MODEL_ORDER_DEFERRED
NO_FORMAL_THRESHOLD
NO_STAGE8_1_VALIDATION_PASS
NO_STAGE8_2_AUTHORIZATION
```

同时更新：

```text
innovation-mining/stage8_execution_prompts/active/README.md
```

状态改为：

```text
CORE_V2_1_SAFE_HYBRID_CLOSURE_COMPLETED
```

不得修改 archived prompts。

---

## 13. 提交顺序

### 13.1 Prompt commit

新增：

```text
innovation-mining/stage8_execution_prompts/active/
006_stage8_core_v2_1_safe_hybrid_closure_v1.md
```

提交：

```text
docs(stage8-core): define safe known-k hybrid closure
```

### 13.2 Tool commit

只提交新增 hybrid selection 文件和测试：

```text
feat(stage8-core): add safe known-k fallback selection
```

### 13.3 Result commit

只提交：

```text
innovation-mining/27_stage8_core_v2_1_safe_hybrid_*
innovation-mining/stage8_execution_prompts/active/README.md
```

提交：

```text
docs(stage8-core): record safe known-k hybrid closure
```

每次仅推送：

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

## 14. 完成后硬停止

完成后不得自动：

```text
修改 continuous solver
恢复 unknown-K
运行 bootstrap
运行 6000-trial
执行 Stage8.2
```

等待用户决定是否将：

```text
known-K safe hybrid core
```

作为精简算法主线。

---

## 15. 最终报告

```text
Branch:
Starting HEAD:
Prompt commit:
Tool commit:
Result commit:
Push:
Git clean:
origin/main unchanged:

H0:
H1:

H1 Direct Hybrid:
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE
- continuous upgrades / fallbacks
- B0 与 continuous candidate 的分离成本
- conservative cost upper bound

H2 Grouped Hybrid:
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE
- continuous upgrades / fallbacks
- B0 与 continuous candidate 的分离成本
- conservative cost upper bound

H2 vs H1:
- wins/ties/losses

Final conclusion:
Model-order = DEFERRED
Formal 6000-trial = DEFERRED_NOT_FAILED
Stage8.2 = NOT_EXECUTED
MATLAB / lock / coordinator:
```
