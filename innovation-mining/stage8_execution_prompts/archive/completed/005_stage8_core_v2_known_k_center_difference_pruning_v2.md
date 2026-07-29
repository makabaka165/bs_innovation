# Stage8-Core-V2：已知 K 连续 DML、中心–分离 K2 求解与分组初始化剪枝（V2）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 和 Git 的 Codex。
>
> 本协议只允许在唯一探索分支 `experiment/stage8-core-v2` 上执行。
> `main` 是稳定科学基线，不得修改。
>
> 协议：
>
> ```text
> STAGE8_CORE_V2_KNOWN_K_CENTER_DIFFERENCE_PRUNING_V2
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_KNOWN_K_CENTER_DIFFERENCE_PRUNING_V2
> ```

---

## 0. 当前分支和阶段

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

稳定主线：

```text
branch:
main

tip:
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

scientific parent:
64cd2d6eae0813f8fd9266ec9ffe6bab4f616267

role:
STABLE_STAGE8_1_THRESHOLD_EVIDENCE_BASE
```

唯一探索分支：

```text
branch:
experiment/stage8-core-v2

expected starting tip:
b6068407a0dc40b94471119d593acaeee8707ddb

role:
ACTIVE_EXPLORATION_BRANCH_NO_EXECUTION_AUTHORIZED
```

探索分支已继承：

```text
1. Compact diagnostic:
   STAGE8_COMPACT_DIAGNOSTIC_CLEAR_FAILURE
   PRIMARY K1 false split = 30/60 = 0.50

2. R1 continuous experiment:
   STAGE8_R1_CONTINUOUS_MODEL_ORDER_NOT_RECOVERED

3. R1 主要观察：
   - fixed-grid off-grid K1 Lambda 显著抬升；
   - continuous K1 显示积极修复迹象；
   - continuous K2 solver V1 未形成可用 K2 fit；
   - M1/M2 的 grouped 初始化价值尚未被公平评价。
```

本阶段状态定义：

```text
STAGE8_CORE_V2_DESIGN_READY_NOT_IMPLEMENTED
MODEL_ORDER_DEFERRED
FORMAL_6000_TRIAL_DEFERRED_NOT_FAILED
STAGE8_2_NOT_AUTHORIZED
```

---

## 1. 本阶段只回答三个问题

```text
Q1. 已知 K=1 或 K=2 时，连续完整顺序流形 DML 是否能稳定返回有效角度估计？

Q2. 将 K2 改成中心–分离参数化后，是否消除上一版逐目标更新和目标交换造成的求解不稳定？

Q3. 在同一个连续 K2 solver、同一数据和同一预算下，
    grouped/conditional 初始化相对 direct/conventional 初始化应 RETAIN、OPTIONAL 还是 PRUNE？
```

本阶段不回答：

```text
未知 K 的正式判定
false split
missed split
bootstrap threshold
resolved/unresolved
六状态分类
formal Wilson gate
Stage8.2
```

---

## 2. Git 硬边界

### 2.1 切换并验证唯一探索分支

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags

git switch experiment/stage8-core-v2

git reset --hard origin/experiment/stage8-core-v2

git status --porcelain=v1 --untracked-files=all
git rev-parse HEAD
git rev-parse origin/experiment/stage8-core-v2
git rev-parse origin/main
```

要求：

```text
HEAD == origin/experiment/stage8-core-v2
初始 HEAD == b6068407a0dc40b94471119d593acaeee8707ddb
origin/main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
工作树 clean
```

若远端探索分支已由用户明确推进到 `b606840` 的后代：

- 只允许其新增内容位于本协议允许路径；
- 必须记录实际起点 SHA；
- 不允许自动 reset 或丢弃未知提交；
- 发现不明算法修改时硬停止。

### 2.2 禁止修改

不得修改：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_6_k12_bootstrap_resolution/

beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_3_grouped_conditional_dml/

beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_5_exact_subset_fim_beam_design/

beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_5_1_stage7_closure_audit/

beamspace_ml_v18/.../calibration/
beamspace_ml_v18/.../results/

innovation-mining/23_stage8_compact_algorithm_diagnostic*
innovation-mining/24_stage8_r1_continuous_refinement_decisive*
innovation-mining/stage8_execution_prompts/archive/
tools/stage8_1b_validation_sharded/
tools/stage8_compact_diagnostic/
tools/stage8_r1_continuous_decisive/
```

不得推送：

```text
main
```

不得创建新长期分支。

所有提交只推送：

```text
experiment/stage8-core-v2
```

---

## 3. 本阶段保留、降级和冻结的内容

### 3.1 保留为核心基础

```text
接收单程圆柱阵流形
顺序 DBF 接口
固定 measurement
W_I/T_I 白化
完整顺序二维流形
集中 DML
SVD 稳定投影
source coefficient recovery
Stage4/5 数据驱动初始化 factory
continuous K1 refinement
```

### 3.2 固定网格降级

固定 `0.2°` grid 只允许作为：

```text
粗搜索
initial start
可复现 baseline
```

不得作为：

```text
最终连续角度参数空间
新的正式 K1/K2 model-order 空间
```

### 3.3 grouped/conditional 初始化降级为候选

当前不得预设 grouped 初始化属于核心创新。

它只作为：

```text
candidate start generator
```

本实验后按结果输出：

```text
GROUPED_RETAIN
GROUPED_OPTIONAL
GROUPED_PRUNE
```

### 3.4 冻结

本阶段完全冻结：

```text
旧 q_global
300-cell calibration
6000-trial validation
Bsep=199 separation bootstrap
K2_RESOLVED / K2_UNRESOLVED
六状态 classifier
Stage8.2
```

---

## 4. 理论结构

### 4.1 K1

已知 K=1 时优化：

\[
\widehat{\boldsymbol\theta}_1
=
\arg\min_{\boldsymbol\theta\in\Omega}
RSS_1(\boldsymbol\theta).
\]

连续参数：

```text
theta = [azimuth, elevation]
```

### 4.2 K2 中心–分离参数化

定义：

\[
\boldsymbol\theta_1
=
\mathbf c-\frac{\mathbf d}{2},
\qquad
\boldsymbol\theta_2
=
\mathbf c+\frac{\mathbf d}{2},
\]

其中：

```text
c = [c_az, c_el]
d = [d_az, d_el]
```

内部符号约定：

```text
d_el > 0

或

abs(d_el) <= 1e-12 且 d_az >= 0
```

该参数化：

```text
不减少 K2 连续自由度
只消除目标交换冗余
使 center 与 separation 明确对应已有局部几何推导
```

内部优化不得在每个坐标更新后重新排序两个 target。

只在最终输出时按：

```text
elevation → azimuth
```

排序，用于确定性展示和 truth matching。

---

## 5. 新增路径

新增 active prompt：

```text
innovation-mining/stage8_execution_prompts/active/
005_stage8_core_v2_known_k_center_difference_pruning_v2.md
```

新增设计说明：

```text
innovation-mining/25_stage8_core_v2_known_k_refactor.md
```

新增工具：

```text
tools/stage8_core_v2_known_k/
```

建议最小文件集：

```text
tools/stage8_core_v2_known_k/
├── README.md
├── matlab/
│   ├── stage8_core_v2_constants.m
│   ├── stage8_core_v2_context.m
│   ├── stage8_core_v2_registry.m
│   ├── stage8_core_v2_k2_center_difference_solver.m
│   ├── stage8_core_v2_fit_known_k.m
│   ├── stage8_core_v2_evaluate_trial.m
│   ├── stage8_core_v2_row_template.m
│   ├── stage8_core_v2_checkpoint_hash.m
│   ├── stage8_core_v2_validate_checkpoint.m
│   ├── stage8_core_v2_worker.m
│   ├── stage8_core_v2_run_gates.m
│   └── stage8_core_v2_finalize.m
├── powershell/
│   └── Stage8CoreV2.ps1
└── tests/
    ├── test_center_difference_transform.m
    ├── test_k2_solver_determinism.m
    ├── test_k2_solver_monotonicity.m
    └── test_one_two_worker_equivalence.m
```

允许只读调用旧工具函数，但禁止修改旧工具目录。

优先只读复用：

```text
stage8_r1_build_registry
stage8_r1_generate_trial
stage8_r1_refine_continuous_dml 仅用于 K1
stage8_r1_build_direct_grid_pair_start
build_stage8_initialization_context_from_data
build_full_sequential_local_manifold
concentrated_dml_rss
solve_fitted_source_coefficients
validate_stage8_fit_for_lrt
```

---

## 6. 三种已知 K 方法

每个 element trial 使用同一个 `Y_element`，评价三个方法。

### B0：固定网格 baseline

```text
B0_FIXED_GRID_KNOWN_K
```

K1 truth trial：

```text
运行原 fit_local_model_k(K=1)
只评价 K1 fit
```

K2 truth trial：

```text
运行原 fixed-grid K1 helper
运行原 fit_local_model_k(K=2)
只评价 K2 fit
```

B0 不参与 Core-V2 operational 判定，只作为历史 baseline。

### B1：direct/conventional + continuous known-K

```text
B1_DIRECT_CONTINUOUS_KNOWN_K
```

K1 start：

```text
conventional_singleton_peak_deg
```

K2 starts 恰好两个：

```text
B1_K2_DIRECT_GRID_PAIR_BEST
B1_K2_K1_EMBEDDED_FISHER_ANCHOR
```

两个 starts 均使用新的中心–分离 solver。

### B2：grouped/conditional + continuous known-K

```text
B2_GROUPED_CONTINUOUS_KNOWN_K
```

K1 start：

```text
grouped_q1_kq1_angles_deg
```

K2 starts 恰好两个：

```text
B2_K2_GROUPED_Q1_KQ2
B2_K2_GROUPED_Q2_KQ1_PLUS_KQ1
```

两个 starts 均使用与 B1 完全相同的中心–分离 solver。

### 公平性

B1/B2 必须共享：

```text
同一 Y_element
同一 measurement
同一 local-domain bounds
同一 white data
同一 score
同一 K2 solver contract
同一 max sweeps
同一函数调用上限
同一有效性规则
```

禁止：

```text
truth start
额外 rescue start
方法特定容差
方法特定 budget
```

---

## 7. K1 solver

K1 复用上一轮的 continuous K1 solver：

```matlab
stage8_r1_refine_continuous_dml(...)
```

只允许 K=1。

本阶段不修改该 solver。

K1 known-K fit 有效条件：

```text
start available
estimate finite
full rank
score/RSS/sigma2/loglik finite
RSS >= 0
monotonicity_violation_count = 0
```

若 solver 返回：

```text
CONTINUOUS_REFINEMENT_MAX_SWEEPS
```

但：

```text
estimate finite
full rank
最后 score 有限
无 monotonicity violation
最后 relative score change <= 1e-7
最后 angle update <= 2e-3 degree
```

则可标记：

```text
K1_CONTINUOUS_MAX_SWEEPS_USABLE
```

仅用于 known-K 角度估计，不用于 LRT。

---

## 8. K2 中心–分离 solver

新增：

```matlab
stage8_core_v2_k2_center_difference_solver( ...
    full_data, initial_angles_deg, local_domain, model, opts)
```

禁止：

```text
fmincon
patternsearch
particleswarm
第三方 toolbox
```

允许：

```text
fminbnd
```

### 8.1 固定合同

```text
max_sweeps                    = 20
scan_point_count              = 9
center_radius_deg             = 0.20
delta_az_radius_deg           = 0.40
delta_el_radius_deg           = 0.20
fminbnd_TolX_deg              = 1e-4
fminbnd_MaxFunEvals           = 80
relative_score_tolerance      = 1e-8
endpoint_update_tolerance_deg = 1e-3
usable_relative_tolerance     = 1e-7
usable_endpoint_tolerance_deg = 2e-3
minimum_separation_deg        = 1e-3
rank_multiplier               = 1
update_order                  = c_az → c_el → d_az → d_el
```

全部进入 solver contract hash。

### 8.2 初始转换

1. 初始 `2×2` angles 按 elevation、azimuth 排序；
2. 计算：
   ```matlab
   c = (theta1 + theta2) / 2;
   d = theta2 - theta1;
   ```
3. 应用固定符号约定；
4. 检查两个 endpoints 均在 domain 内；
5. 检查 `norm(d) >= 1e-3`；
6. 满秩后开始优化。

### 8.3 可行域

给定 `d_az`：

```text
c_az ∈ [
  az_min + abs(d_az)/2,
  az_max - abs(d_az)/2
]
```

给定 `d_el >= 0`：

```text
c_el ∈ [
  el_min + d_el/2,
  el_max - d_el/2
]
```

给定 `c_az`：

```text
d_az ∈ [
 -2*min(c_az-az_min, az_max-c_az),
 +2*min(c_az-az_min, az_max-c_az)
]
```

给定 `c_el`：

```text
d_el ∈ [
 0,
 2*min(c_el-el_min, el_max-c_el)
]
```

无效 candidate：

```text
endpoint 越界
norm(d)<1e-3
rank<2
score 非有限
```

### 8.4 坐标更新

每个坐标：

1. 计算全局可行上下界；
2. 与局部 radius 相交；
3. 生成 9 个等距 scan nodes；
4. 评分；
5. 选最高 score；
6. 并列时优先：
   ```text
   更接近当前值
   再选更小数值
   ```
7. 用相邻 scan nodes 形成 `fminbnd` bracket；
8. 统一比较：
   ```text
   当前值
   最佳 scan node
   fminbnd candidate
   bracket 两端
   ```
9. 仅当 score 增加超过：
   ```text
   64*eps(max(1,abs(current_score)))
   ```
   时接受；
10. 不允许 score 下降；
11. 内部不得重新排列 endpoints。

### 8.5 收敛

每个完整 sweep 后计算：

```text
accepted_update_count
relative_score_change
max_endpoint_update_deg
```

满足任一：

```text
A.
accepted_update_count == 0

B.
relative_score_change <= 1e-8
且 max_endpoint_update_deg <= 1e-3
```

则有效收敛。

状态：

```text
K2_CENTER_DIFFERENCE_STATIONARY
K2_CENTER_DIFFERENCE_CONVERGED
```

达到 20 sweeps 后，只有同时满足：

```text
monotonicity_violation_count = 0
最后三次 relative score change <= 1e-7
最后一次 max endpoint update <= 2e-3
full rank
score/RSS finite
```

才允许：

```text
K2_CENTER_DIFFERENCE_MAX_SWEEPS_USABLE
```

否则：

```text
K2_CENTER_DIFFERENCE_NOT_OPERATIONAL
```

### 8.6 最终 fit 与 start 选择

对有效 start：

```text
重建 full sequential manifold
计算 concentrated RSS/loglik
恢复 source coefficients
验证 rank 和有限性
```

K2 多 start 选择：

```text
MAXIMUM_CONCENTRATED_LOG_LIKELIHOOD_AMONG_VALID_STARTS
```

并列容差：

```text
64*eps(max(1,abs(max_loglik)))
```

并列时按注册 start 顺序选择第一项。

本阶段不调用：

```text
nested_dml_likelihood_ratio
```

也不要求 K1/K2 solver hash 相同。

---

## 9. 精确复用上一轮 24 个 trial

不得新增 Monte Carlo 场景。

registry 必须来自：

```matlab
stage8_r1_build_registry(context, 'FORMAL')
```

规模：

```text
16 K1 trials
8 K2 trials
24 element trials
72 method rows
```

数据必须通过：

```matlab
stage8_r1_generate_trial(...)
```

重建。

每个 trial 的：

```text
trial_id
noise_seed
element_trial_hash
truth
```

必须与：

```text
innovation-mining/24_stage8_r1_continuous_refinement_decisive_trials.csv
```

一致。

不一致立即：

```text
STAGE8_CORE_V2_EXPERIMENT_INVALID
```

---

## 10. 只评价已知真值 K

K1 truth trial：

```text
B0 只运行 K1
B1 只运行 K1
B2 只运行 K1
```

K2 truth trial：

```text
B0 只评价 K2
B1 只评价 K2
B2 只评价 K2
```

允许为生成 K2 nested start 运行一个 K1 helper，但：

```text
不得把 K1 helper 作为 K2 trial 的科学输出
不得计算 Lambda
不得作 model-order 判决
```

本阶段不输出：

```text
false split
missed split
AUC
ROC
threshold
K1/K2 state
```

---

## 11. 最小 Gates

只保留三道 gate。

### G0：分支与历史完整性

检查：

```text
当前分支 = experiment/stage8-core-v2
b606840 是祖先
origin/main = 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
工作树 clean
23_* 历史结果未改
24_* 历史结果未改
archive prompts 未改
frozen Stage8 step 未改
calibration 未改
formal results/ 未改
MATLAB / lock / coordinator = 0 / 0 / 0
```

失败硬停止。

### G1：求解器科学可用性

只用两个 fixture：

```text
F1:
K1 INSIDE_OFF_GRID
WHITE
L=8
SNR=+6

F2:
K2 EASY
WHITE
L=8
separation=0.30
SNR=+6
```

要求：

F1：

```text
B1/B2 K1 valid
结果可重复
无 monotonicity violation
RSS 不高于 B0
角度非 grid-snap
```

F2：

```text
B1 或 B2 至少一个 K2 fit valid
结果可重复
endpoints in domain
norm(d)>=1e-3
无 monotonicity violation
K2 RMSE finite
```

若 B1/B2 对 F2 都无有效 K2 fit：

```text
STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP
```

停止，不运行 24 trials，不设计第三版 solver。

### G2：1-worker / 2-worker 等价

只用 F1/F2。

比较：

```text
scientific fields
angles num2hex
RSS num2hex
selected start
solver status
```

必须相同。

若不同：

```text
ONE_WORKER_RESUMABLE
```

若相同：

```text
TWO_WORKER_RESUMABLE
```

不调查无关的 runtime/PID/timestamp 差异。

---

## 12. Runtime 与 checkpoint

Runtime root：

```text
E:\bs_innovation_runtime\
stage8_core_v2_known_k_center_difference_v2_b606840
```

每个 trial 一个原子 checkpoint：

```text
checkpoints\<trial_id>.mat
```

仅需保存：

```text
trial identity
3 method rows
scientific hash
completion status
```

排除：

```text
PID
timestamp
worker ID
runtime
```

写入：

```text
.tmp
→ reload
→ validate
→ atomic rename
```

不注册 Windows 定时任务。

不实现复杂 ETA、sidecar 或多层 manifest。

默认：

```text
2 MATLAB R2022b -singleCompThread workers
```

支持手动：

```text
Init
Gates
Start
Status
Pause
Resume
Finalize
```

---

## 13. 结果字段

每个 method row 至少包含：

```text
trial_id
truth_K
support_or_difficulty
noise
L
SNR
noise_seed
element_trial_hash

method_id
fit_valid
fit_status
solver_status
selected_start_id
start_count
valid_start_count

initial_angles
final_angles
known_K_joint_RMSE
known_K_azimuth_RMSE
known_K_elevation_RMSE
known_K_separation_vector_error
refinement_improved_flag

RSS
loglik
effective_rank
score_calls
SVD_calls
runtime_sec

monotonicity_violation_count
truth_used_in_initialization_flag
truth_used_in_fit_flag
shared_element_data_flag
```

truth 只用于 fit 完成后的 target matching 和误差。

---

## 14. Operational 判定

B1/B2 分别定义：

```text
KNOWN_K_CORE_OPERATIONAL
```

当且仅当：

```text
K1 valid >= 15/16
K2 valid >= 7/8
K1 off-grid median joint RMSE <= 0.05 degree
K2 overall median joint RMSE <= 0.20 degree
所有 valid rows 无 monotonicity violation
truth leakage = 0
```

若 B1/B2 均不 operational：

```text
STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP
```

不再设计第三版 solver。

---

## 15. Grouped RETAIN / OPTIONAL / PRUNE

只比较 B1 与 B2 的 8 个 K2 paired trials。

单 trial：

```text
一方 valid、另一方 invalid：
valid 方胜

双方 valid：
RMSE_B2 < RMSE_B1 - 1e-3 → B2_WIN
RMSE_B1 < RMSE_B2 - 1e-3 → B2_LOSS
否则 → TIE
```

### RETAIN

```text
B2 operational 且 B1 不 operational

或

二者 operational：
B2 wins >= 5/8
且 median_RMSE_B2 <= 0.95 * median_RMSE_B1

或

median RMSE 差 <= 0.002 degree
且 B2 mean score calls <= 0.80 * B1
```

结论：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_RETAIN
```

### PRUNE

```text
B1 operational 且 B2 不 operational

或

二者 operational：
B2 losses >= 5/8
且 median_RMSE_B2 >= 1.05 * median_RMSE_B1

或

median RMSE 差 <= 0.002 degree
且 B2 mean score calls >= 1.20 * B1
```

结论：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_PRUNE
```

### OPTIONAL

二者均 operational，且不满足 RETAIN/PRUNE：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_OPTIONAL
```

---

## 16. 输出

Finalize 后只允许新增：

```text
innovation-mining/25_stage8_core_v2_known_k_refactor.md
innovation-mining/26_stage8_core_v2_known_k_pruning_experiment.md
innovation-mining/26_stage8_core_v2_known_k_pruning_trials.csv
innovation-mining/26_stage8_core_v2_known_k_pruning_summary.csv
innovation-mining/26_stage8_core_v2_known_k_pruning_comparison.csv
```

报告必须标记：

```text
KNOWN_K_DIAGNOSTIC_ONLY
MODEL_ORDER_DEFERRED
NO_FORMAL_THRESHOLD
NO_STAGE8_1_VALIDATION_PASS
NO_STAGE8_2_AUTHORIZATION
```

---

## 17. 提交顺序

### 17.1 Prompt/design commit

只提交：

```text
innovation-mining/stage8_execution_prompts/active/
005_stage8_core_v2_known_k_center_difference_pruning_v2.md

innovation-mining/25_stage8_core_v2_known_k_refactor.md
```

提交标题：

```text
docs(stage8-core): define known-k center-difference experiment
```

### 17.2 Tool commit

只提交：

```text
tools/stage8_core_v2_known_k/
```

提交标题：

```text
feat(stage8-core): add known-k center-difference solver
```

工具提交后工作树 clean 才允许运行。

### 17.3 Result commit

只提交：

```text
innovation-mining/26_stage8_core_v2_known_k_pruning_*
```

提交标题：

```text
docs(stage8-core): record grouped-initialization pruning result
```

每次只推送：

```powershell
git push origin experiment/stage8-core-v2
```

禁止：

```text
push main
merge main
创建 PR 到 main
创建新分支
force push
```

---

## 18. 最终结论

本阶段只允许：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_RETAIN
STAGE8_CORE_V2_OPERATIONAL_GROUPED_OPTIONAL
STAGE8_CORE_V2_OPERATIONAL_GROUPED_PRUNE
STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP
STAGE8_CORE_V2_EXPERIMENT_INVALID
```

完成后停止。

不得自动恢复：

```text
unknown-K LRT
bootstrap
6000-trial
Stage8.2
```

---

## 19. 时间预算

```text
Prompt/design: 20–45 min
工具实现与小测试: 1–3 active hours
G0–G2: 10–30 min
24 trials:
- 2 workers: 15–45 min
- 1 worker fallback: 30–90 min
```

若 easy K2 fixture 在 G1 中 direct/grouped 均失败，立即停止，不消耗完整 trial 时间。

---

## 20. 最终报告格式

```text
Branch:
Starting HEAD:
Prompt/design commit:
Tool commit:
Result commit:
Push status:
Git clean:
origin/main unchanged:

G0:
G1:
G2:
Selected workers:

Trials:
- K1 16/16
- K2 8/8
- method rows 72/72

B0:
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE

B1:
- operational
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE
- score/SVD/runtime

B2:
- operational
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE
- score/SVD/runtime

B2 vs B1:
- wins/ties/losses

Final conclusion:
Model-order status = DEFERRED
Formal 6000-trial status = DEFERRED_NOT_FAILED
Stage8.2 executed = false
MATLAB / lock / coordinator:
```
