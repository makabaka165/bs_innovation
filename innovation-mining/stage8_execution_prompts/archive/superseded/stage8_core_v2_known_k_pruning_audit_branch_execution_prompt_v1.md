# Stage8-Core-V2：已知 K 连续 DML 核心与分组初始化剪枝实验（AUDIT 分支专用，V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 和 Git 的 Codex。
>
> 本协议必须直接在现有 audit 分支上推进，不创建新的算法开发分支，不修改
> `origin/main`，不重写任何既有负结果。它先以 fast-forward only 将 Stage8-R1
> 连续实验历史纳入 audit 分支，然后实现一个精简的“已知 K 连续完整顺序流形
> DML”原型，用中心–分离参数化修复 K2 连续求解，并最终决定分组/条件初始化
> 应保留、降级为可选项，还是作为核心路线剪枝。
>
> 协议：
>
> ```text
> STAGE8_CORE_V2_KNOWN_K_CONTINUOUS_DML_PRUNING_V1
> ```
>
> 执行授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_KNOWN_K_CONTINUOUS_DML_PRUNING_V1
> ```

---

## 0. 本阶段的唯一目标

本阶段不再验证旧 K1/K2 threshold，不再恢复旧六状态闭环，也不再增加 Monte Carlo
规模。只回答：

```text
Q1. 已知 K 时，连续完整顺序流形 DML 是否能稳定返回准确的 K1/K2 角度？

Q2. 使用中心–分离参数化后，连续 K2 solver 是否能够稳定工作？

Q3. 在完全相同的连续 solver 下，分组/条件初始化相较常规直接初始化，
    是否提供足够的收敛率、精度或计算成本收益，值得保留为核心算法？
```

本阶段结束后必须输出且只输出以下五种结论之一：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_RETAIN
STAGE8_CORE_V2_OPERATIONAL_GROUPED_OPTIONAL
STAGE8_CORE_V2_OPERATIONAL_GROUPED_PRUNE
STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP
STAGE8_CORE_V2_EXPERIMENT_INVALID
```

不得在本协议下继续设计第三版 solver、增加 trial、调正式 threshold 或恢复
bootstrap。

---

## 1. 目标 Git 分支与提交关系

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

目标分支必须是：

```text
audit/stage8-compact-clear-failure-f6ec19f
```

当前 audit 锚点：

```text
f6ec19fc28e8c317a5f92416658be06a72ee19a1
docs(stage8): record compact K1-K2 algorithm diagnostic
```

该 audit 锚点记录：

```text
PRIMARY K1 false split = 30/60 = 0.50
STAGE8_COMPACT_DIAGNOSTIC_CLEAR_FAILURE
```

后续连续实验分支：

```text
experiment/stage8-r1-continuous-refinement-decisive-v1
```

该分支是 `f6ec19f` 的线性后代，包含：

```text
Stage8-R1 连续实验工具
24/24 element trials
72/72 method rows
STAGE8_R1_CONTINUOUS_MODEL_ORDER_NOT_RECOVERED
report correction commit 8e18cdb（简称）
```

远端 main 必须继续保持：

```text
b5d434720ba9c6e249f0a2197ff886dd133ffd88
```

---

## 2. 在 audit 分支上进行 fast-forward only

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune

git status --short --branch
```

要求工作树 clean。

切换到本地 audit 分支；若本地不存在，则创建 tracking branch：

```powershell
git switch audit/stage8-compact-clear-failure-f6ec19f
```

若失败且仅因为本地分支不存在：

```powershell
git switch -c audit/stage8-compact-clear-failure-f6ec19f `
  --track origin/audit/stage8-compact-clear-failure-f6ec19f
```

确认：

```powershell
git rev-parse HEAD
git merge-base --is-ancestor `
  f6ec19fc28e8c317a5f92416658be06a72ee19a1 HEAD
```

随后确认 experiment 分支是 audit 锚点的线性后代：

```powershell
git merge-base --is-ancestor `
  f6ec19fc28e8c317a5f92416658be06a72ee19a1 `
  origin/experiment/stage8-r1-continuous-refinement-decisive-v1
```

必须返回成功。

将 experiment 分支 fast-forward 到当前 audit 分支：

```powershell
git merge --ff-only `
  origin/experiment/stage8-r1-continuous-refinement-decisive-v1
```

禁止：

```text
普通 merge commit
rebase
cherry-pick 部分实验提交
reset --hard 改写历史
force push
删除 audit 或 experiment 分支
```

fast-forward 后确认：

```powershell
git rev-parse HEAD
git rev-parse origin/experiment/stage8-r1-continuous-refinement-decisive-v1
git status --porcelain=v1 --untracked-files=all
```

两个 SHA 必须相同，工作树必须为空。

随后只推进 audit 分支：

```powershell
git push origin audit/stage8-compact-clear-failure-f6ec19f
```

确认：

```powershell
git rev-parse HEAD
git rev-parse origin/audit/stage8-compact-clear-failure-f6ec19f
git rev-parse origin/main
```

要求：

```text
HEAD == origin/audit/stage8-compact-clear-failure-f6ec19f
origin/main == b5d434720ba9c6e249f0a2197ff886dd133ffd88
```

任何一步不满足：停止，不开始算法修改。

---

## 3. 历史证据必须保持不可变

不得修改、删除、重命名或覆盖：

```text
innovation-mining/23_stage8_compact_algorithm_diagnostic.md
innovation-mining/23_stage8_compact_algorithm_diagnostic_trials.csv
innovation-mining/23_stage8_compact_algorithm_diagnostic_summary.csv
innovation-mining/23_stage8_compact_algorithm_diagnostic_profiles.csv

innovation-mining/24_stage8_r1_continuous_refinement_decisive_experiment.md
innovation-mining/24_stage8_r1_continuous_refinement_decisive_trials.csv
innovation-mining/24_stage8_r1_continuous_refinement_decisive_summary.csv
innovation-mining/24_stage8_r1_continuous_refinement_method_comparison.csv
```

不得修改既有工具目录：

```text
tools/stage8_compact_diagnostic/
tools/stage8_r1_continuous_decisive/
tools/stage8_1b_validation_sharded/
```

它们作为历史复现依据保留。

---

## 4. 本阶段保留、降级和冻结的算法内容

### 4.1 直接保留

```text
接收单程圆柱阵流形
顺序 DBF 接口
固定 measurement 与 W_I/T_I 白化
完整顺序二维流形
集中 DML
SVD 稳定投影和系数恢复
数据驱动 Stage4/5 initialization factory
连续 K1 refinement 的基本实现
```

### 4.2 降级

固定 `0.2°` grid：

```text
允许：
- 粗搜索
- 初始化
- baseline

禁止：
- 作为最终连续角度参数空间
- 作为新正式 K1/K2 model-order 参数空间
```

分组/条件 DML：

```text
当前只作为 candidate start generator
不预设为核心创新
结果出来后按本协议决定 RETAIN / OPTIONAL / PRUNE
```

### 4.3 冻结、不执行

```text
旧 q_global threshold
300-cell calibration
6000-trial K1 formal validation
Bsep=199 separation bootstrap
K2_RESOLVED / K2_UNRESOLVED
六状态 classifier
Stage8.2
Wilson gate
新的 calibration 或 threshold
```

### 4.4 本阶段核心输出

本阶段算法只输出：

```text
已知 K 下的连续角度估计
fit validity
RSS
concentrated likelihood
初始化误差
最终误差
score/SVD/runtime
```

不输出硬 K1/K2 判定。

---

## 5. 新增设计文档和工具路径

只允许新增：

```text
innovation-mining/25_stage8_core_v2_known_k_refactor.md

innovation-mining/stage8_execution_prompts/
005_stage8_core_v2_known_k_pruning_v1.md

tools/stage8_core_v2_known_k/
```

工具最小文件集：

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
    ├── test_k2_solver_determinism_and_monotonicity.m
    ├── test_shared_trial_data.m
    └── test_one_two_worker_equivalence.m
```

允许只读复用：

```text
tools/stage8_r1_continuous_decisive/matlab/
stage8_r1_build_registry.m
stage8_r1_generate_trial.m
stage8_r1_refine_continuous_dml.m
stage8_r1_build_direct_grid_pair_start.m
```

不得修改这些既有函数。

不得修改 frozen Stage8 step：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_6_k12_bootstrap_resolution/
```

---

## 6. 新设计文档必须先写清楚的算法

`innovation-mining/25_stage8_core_v2_known_k_refactor.md` 必须明确：

### 6.1 精简核心算法

```text
常规顺序 DBF 局部角单元
→ 数据驱动候选初始化
→ 已知 K 的连续完整顺序流形 DML
→ 输出连续二维角度
```

### 6.2 当前论文/创新边界

核心候选仅保留：

```text
可辨俯仰组
→ 条件方位候选初始化
→ 连续完整顺序流形 DML
```

其是否保留为核心贡献，取决于本次相对常规直接初始化的结果。

### 6.3 明确移出当前核心

```text
未知 K 模型阶数判定
parametric-bootstrap threshold
resolved/unresolved
六状态机
```

这些记为 deferred extension，不属于本次算法核心。

### 6.4 K2 参数化

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
c = [center_az, center_el]
d = [delta_az, delta_el]
```

固定无序目标符号约定：

```text
delta_el >= 0

若 abs(delta_el) <= 1e-12：
delta_az >= 0
```

该参数化只消除目标交换冗余，不减少 K2 的连续自由度。

---

## 7. 三种已知 K 方法

每个 element trial 使用完全相同的 `Y_element`，比较以下方法。

### 7.1 B0：固定网格已知 K baseline

```text
B0_FIXED_GRID_KNOWN_K
```

- K1 truth trial：使用原 `fit_local_model_k(..., K=1)`。
- K2 truth trial：先生成原固定网格 K1 helper fit，随后使用原
  `fit_local_model_k(..., K=2)`。
- 只用作 baseline。
- 不使用 threshold，不进行 model-order 判定。

### 7.2 B1：常规直接初始化 + 连续 known-K DML

```text
B1_DIRECT_CONTINUOUS_KNOWN_K
```

K1 start：

```text
conventional_singleton_peak_deg
```

K2 starts：

```text
M1_K2_DIRECT_GRID_PAIR_BEST
M1_K2_K1_EMBEDDED_FISHER_ANCHOR
```

两个 K2 starts 均使用新的中心–分离 continuous solver。

### 7.3 B2：分组/条件初始化 + 连续 known-K DML

```text
B2_GROUPED_CONTINUOUS_KNOWN_K
```

K1 start：

```text
grouped_q1_kq1_angles_deg
```

K2 starts：

```text
grouped_q1_kq2_angles_deg
grouped_q2_kq1_plus_kq1_angles_deg
```

两个 K2 starts 均使用与 B1 完全相同的中心–分离 continuous solver。

### 7.4 公平性

B1 与 B2 必须共享：

```text
同一 Y_element
同一 measurement
同一 local-domain bounds
同一白化
同一 DML score
同一 center-difference solver
同一收敛和有效性合同
同一最大 sweep 和函数调用预算
```

不得加入：

```text
truth start
额外 rescue start
方法特定容差
方法特定 solver budget
```

---

## 8. K1 continuous solver

K1 直接复用已通过前一实验的：

```matlab
stage8_r1_refine_continuous_dml
```

只允许 K=1 调用。

不得修改其 solver contract。

K1 known-K fit 只要求：

```text
初始化有效
连续 refinement 返回
full rank
score/RSS/variance/loglik 有限
无 monotonicity violation
```

记录原 solver status。

---

## 9. 新 K2 中心–分离 continuous solver

新增：

```matlab
stage8_core_v2_k2_center_difference_solver( ...
    full_data, initial_angles_deg, local_domain, model, opts)
```

不得使用第三方工具箱、`fmincon`、`patternsearch`、`particleswarm`。

允许使用 MATLAB 基础函数：

```text
fminbnd
```

### 9.1 固定 solver contract

```text
max_sweeps                    = 24
scan_point_count              = 9
center_coordinate_radius_deg  = 0.20
delta_az_radius_deg           = 0.40
delta_el_radius_deg           = 0.20
fminbnd_TolX_deg              = 1e-4
fminbnd_MaxFunEvals           = 80
relative_score_tolerance      = 1e-8
endpoint_update_tolerance_deg = 5e-4
usable_relative_tolerance     = 1e-7
usable_endpoint_tolerance_deg = 2e-3
minimum_separation_deg        = 1e-3
rank_multiplier               = 1
update_order                  = c_az → c_el → d_az → d_el
phase_factor                  = 1
```

所有值进入 solver contract hash，不得 trial-dependent 修改。

### 9.2 角度到中心–分离转换

输入 `2×2` 角度：

1. 按 elevation、azimuth 排序；
2. 计算：
   ```matlab
   c = (theta1 + theta2) / 2;
   d = theta2 - theta1;
   ```
3. 若：
   ```text
   d_el < 0
   或 abs(d_el)<=1e-12 且 d_az<0
   ```
   则 `d = -d`。
4. 计算两个 endpoint 并检查均在 domain 内。
5. 要求：
   ```text
   norm(d) >= minimum_separation_deg
   ```

### 9.3 中心–分离到 endpoints

每次评分只通过：

```matlab
theta1 = c - d/2;
theta2 = c + d/2;
```

构造 endpoints。

内部优化期间不得调用 target-row canonicalization，不得交换 target 1/2 的内部
变量。

只在最终输出时按 elevation、azimuth 排序用于统一展示。

### 9.4 可行域

令 domain：

```text
az ∈ [az_min, az_max]
el ∈ [el_min, el_max]
```

给定 `d_az` 时：

```text
c_az ∈ [
  az_min + abs(d_az)/2,
  az_max - abs(d_az)/2
]
```

给定 `d_el` 时：

```text
c_el ∈ [
  el_min + d_el/2,
  el_max - d_el/2
]
```

给定 `c_az` 时：

```text
d_az ∈ [
 -2*min(c_az-az_min, az_max-c_az),
 +2*min(c_az-az_min, az_max-c_az)
]
```

给定 `c_el` 时：

```text
d_el ∈ [
 0,
 2*min(c_el-el_min, el_max-c_el)
]
```

任何 candidate 若：

```text
endpoint 出界
norm(d) < 1e-3
流形 rank < 2
score 非有限
```

则为无效 candidate。

### 9.5 每个坐标更新

对当前坐标 `x0`：

1. 取得其全局可行上下界；
2. 再与对应局部 radius 相交；
3. 在局部区间生成 9 个等距 scan nodes；
4. 评分所有节点；
5. 选最大 score node；
6. score 并列时：
   ```text
   优先 |candidate-x0| 更小
   再优先 candidate 数值更小
   ```
7. 用最佳节点相邻 scan nodes 形成 bracket；
8. 在 bracket 中 `fminbnd(-score)`；
9. 统一比较：
   ```text
   当前值
   最佳 scan node
   fminbnd candidate
   bracket 两端
   ```
10. 只有 score 增加超过数值容差时接受；
11. 不允许 score 下降；
12. 不在坐标更新后重排 endpoints。

### 9.6 Sweep 结束和收敛

每个完整 sweep 后计算：

```text
relative_score_change
max_endpoint_update_deg
accepted_update_count
```

以下任一满足即为有效收敛：

```text
A.
relative_score_change <= 1e-8
且 max_endpoint_update_deg <= 5e-4

B.
accepted_update_count == 0
```

状态：

```text
K2_CENTER_DIFFERENCE_CONVERGED
K2_CENTER_DIFFERENCE_STATIONARY
```

### 9.7 Max-sweeps 可用状态

达到 24 sweeps 后，若：

```text
全程 monotonicity_violation_count == 0
最后三次 relative_score_change 均 <= 1e-7
最后一次 max_endpoint_update_deg <= 2e-3
最终 full rank
最终 score/RSS 有限
```

则：

```text
K2_CENTER_DIFFERENCE_MAX_SWEEPS_USABLE
```

该状态可作为 known-K 角度估计结果。

否则：

```text
K2_CENTER_DIFFERENCE_NOT_CONVERGED
```

并判 fit 无效。

### 9.8 最终 fit

对有效状态：

```text
CONVERGED
STATIONARY
MAX_SWEEPS_USABLE
```

使用现有：

```text
build_full_sequential_local_manifold
concentrated_dml_rss
solve_fitted_source_coefficients
validate_stage8_fit_for_lrt
```

构造 K2 fit。

本阶段不要求与 K1 fit 共享 solver hash，因为不调用 K1/K2 LRT；但 B1/B2 的所有 K2
starts 必须共享相同 K2 solver hash。

K2 多 start 选择：

```text
MAXIMUM_CONCENTRATED_LOG_LIKELIHOOD_AMONG_VALID_STARTS
```

并列容差：

```text
64 * eps(max(1, abs(max_loglik)))
```

并列时按注册 start 顺序取第一项。

---

## 10. 复用原 24 个 trial，不增加样本

新 registry 必须逐行读取并验证：

```matlab
stage8_r1_build_registry(context, 'FORMAL')
```

不得重新设计 seeds 或场景。

要求：

```text
24 element trials
16 K1
8 K2
```

K1：

```text
ON_GRID      [8.0,10.0]
INSIDE_OFF_GRID [8.1,10.1]
L ∈ {1,8}
SNR ∈ {-6,+6}
noise ∈ {WHITE,CORRELATED}
```

K2：

```text
EASY:
sep=0.30, SNR=+6

MODERATE:
sep=0.15, SNR=0

L ∈ {4,8}
noise ∈ {WHITE,CORRELATED}
equal power
correlation=0
center=[8,10]
direction=45°
```

必须调用既有：

```matlab
stage8_r1_generate_trial
```

重建相同 element-domain 数据。

新运行中每个 trial 的：

```text
trial_id
noise_seed
element_trial_hash
truth
```

必须与 `innovation-mining/24_stage8_r1_continuous_refinement_decisive_trials.csv`
中的对应 trial 一致。

不一致：

```text
STAGE8_CORE_V2_EXPERIMENT_INVALID
```

---

## 11. 每 trial 只评价已知真值 K

对 K1 truth trial：

```text
B0 只做 K1 fit
B1 只做 K1 fit
B2 只做 K1 fit
```

不得额外做 K2 fit。

对 K2 truth trial：

```text
B0 做固定网格 K1 helper + K2 fit，但只评价 K2
B1 做其 start 所需的 K1 helper + 新 K2 fit，但只评价 K2
B2 直接从 grouped K2 starts + 新 K2 fit，只评价 K2
```

本阶段不得计算或输出：

```text
Lambda threshold decision
false split
missed split
AUC
ROC
K1/K2 state
```

允许保存辅助：

```text
RSS
concentrated loglik
```

但不得将其解释为 model-order 结论。

---

## 12. 结果 row

每 trial 产生 3 行：

```text
24 × 3 = 72 rows
```

每行至少包含：

```text
trial_id
global_trial_index
truth_K
support_or_difficulty
noise_profile_id
L
snr_db
noise_seed
element_trial_hash

method_id
fit_valid
fit_status
selected_start_id
start_count
valid_start_count
solver_status

initial_angles
final_angles
known_K_joint_rmse_deg
known_K_azimuth_rmse_deg
known_K_elevation_rmse_deg
known_K_separation_vector_error_deg
initial_known_K_joint_rmse_deg
refinement_improved_flag

rss
loglik_concentrated
effective_rank
score_call_count
svd_call_count
runtime_sec

monotonicity_violation_count
truth_used_in_initialization_flag
truth_used_in_fit_flag
shared_element_data_flag
phase_factor
```

truth 只允许在 fit 完成后用于 target matching 和误差计算。

---

## 13. 最小 Gates

本阶段只设置三道必要 gate。

### Gate V0：audit 分支和历史边界

检查：

```text
当前分支精确为 audit/stage8-compact-clear-failure-f6ec19f
f6ec19f 是祖先
experiment 分支 tip 已 fast-forward 纳入
工作树 clean
origin/main 仍为 b5d4347
23_* 与 24_* 历史结果 SHA 未变
frozen Stage8 step 无 diff
calibration 无 diff
formal results/ 无 diff
MATLAB / lock / coordinator = 0 / 0 / 0
```

失败：硬停止。

### Gate V1：solver 结构与科学可用性

使用 2 个 fixture：

```text
F1：K1 INSIDE_OFF_GRID, WHITE, L=8, SNR=+6
F2：K2 EASY, WHITE, L=8
```

要求：

```text
F1：
- B1/B2 K1 连续结果可重复
- RSS/angles 与上一 R1 实验对应 K1 结果一致
- no monotonicity violation

F2：
- direct K2 至少一个 start 有效
- grouped K2 至少一个 start 有效
- 两次独立重复 scientific hash 一致
- endpoint 全在 domain 内
- norm(d)>=1e-3
- no monotonicity violation
- K2 known-K RMSE 有限
```

若 F2 direct 和 grouped 均无有效 start：

```text
STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP
```

停止，不运行 24 trials。

若仅一类 start 有效，仍可继续正式 24 trials。

### Gate V2：1-worker / 2-worker 等价性

使用：

```text
F1
F2
```

比较：

```text
1 worker
2 workers
```

要求 scientific result fields 完全一致；runtime/PID/timestamp 排除。

若不一致：

```text
selected_worker_count = 1
ONE_WORKER_RESUMABLE
```

若一致：

```text
selected_worker_count = 2
TWO_WORKER_RESUMABLE
```

不得因为并行不一致而修改科学算法。

---

## 14. Runtime、checkpoint 与恢复

Runtime root：

```text
E:\bs_innovation_runtime\
stage8_core_v2_known_k_pruning_v1_audit
```

每个 element trial 是一个原子 checkpoint：

```text
checkpoints\<trial_id>.mat
```

每个 checkpoint 包含 3 个方法 rows。

写入：

```text
tmp\<trial_id>.mat.tmp
→ reload
→ validate
→ atomic rename
```

已有有效 checkpoint：

```text
永不覆盖
永不重跑
```

默认：

```text
2 × MATLAB R2022b -singleCompThread
```

禁止：

```text
parpool
parfor
backgroundPool
trial 内多线程
```

手动控制：

```powershell
$runner = 'E:\bs_innovation\tools\stage8_core_v2_known_k\powershell\Stage8CoreV2.ps1'
$runtime = 'E:\bs_innovation_runtime\stage8_core_v2_known_k_pruning_v1_audit'

& $runner -Action Init     -RuntimeRoot $runtime
& $runner -Action Gates    -RuntimeRoot $runtime
& $runner -Action Start    -RuntimeRoot $runtime
& $runner -Action Status   -RuntimeRoot $runtime
& $runner -Action Pause    -RuntimeRoot $runtime
& $runner -Action Resume   -RuntimeRoot $runtime
& $runner -Action Finalize -RuntimeRoot $runtime
```

本阶段不注册 Windows 定时任务，不允许 Codex 持续轮询。

---

## 15. operational 判定

对 B1/B2 分别计算：

```text
K1 valid count / 16
K2 valid count / 8
K1 overall median RMSE
K1 off-grid median RMSE
K2 overall median RMSE
K2 easy median RMSE
K2 moderate median RMSE
refinement-improved fraction
mean score calls
mean SVD calls
median runtime
```

某方法定义为：

```text
KNOWN_K_CORE_OPERATIONAL = true
```

当且仅当：

```text
K1 valid >= 15/16
K2 valid >= 7/8
K1 off-grid median joint RMSE <= 0.05 degree
K2 overall median joint RMSE <= 0.20 degree
所有 valid rows monotonicity_violation_count = 0
truth leakage = 0
```

若 B1/B2 均不 operational：

```text
STAGE8_CORE_V2_K2_SOLVER_NOT_OPERATIONAL_STOP
```

不得继续第三版 solver。

---

## 16. 分组初始化 RETAIN / OPTIONAL / PRUNE

只比较 B1 与 B2。

对 8 个 K2 trials：

```text
若一方 valid、另一方 invalid：
valid 方获胜

若双方 valid：
B2 RMSE < B1 RMSE - 1e-4 → B2_WIN
B1 RMSE < B2 RMSE - 1e-4 → B2_LOSS
否则 → TIE
```

### 16.1 RETAIN

以下任一满足：

```text
B2 operational，B1 不 operational

或

二者均 operational，且：
- B2 wins >= 5/8
- B2 K2 median RMSE <= 0.95 * B1 K2 median RMSE

或

二者精度在 1e-4 degree 内等价，且：
B2 mean score calls <= 0.80 * B1 mean score calls
```

结论：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_RETAIN
```

### 16.2 PRUNE

以下任一满足：

```text
B1 operational，B2 不 operational

或

二者均 operational，且：
- B2 losses >= 5/8
- B2 K2 median RMSE >= 1.05 * B1 K2 median RMSE

或

二者精度在 1e-4 degree 内等价，且：
B2 mean score calls >= 1.20 * B1 mean score calls
```

结论：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_PRUNE
```

### 16.3 OPTIONAL

若二者均 operational，且不满足 RETAIN 或 PRUNE：

```text
STAGE8_CORE_V2_OPERATIONAL_GROUPED_OPTIONAL
```

不得通过修改门限重新分类。

---

## 17. 输出文件

Finalize 后只允许新增：

```text
innovation-mining/26_stage8_core_v2_known_k_pruning_experiment.md
innovation-mining/26_stage8_core_v2_known_k_pruning_trials.csv
innovation-mining/26_stage8_core_v2_known_k_pruning_summary.csv
innovation-mining/26_stage8_core_v2_known_k_pruning_comparison.csv
```

报告必须包含：

```text
audit branch / HEAD
f6ec19f audit anchor
纳入的 experiment tip SHA
V0/V1/V2
worker count
24/24 trial completeness
72/72 row completeness
B0/B1/B2 valid counts
K1 on/off-grid RMSE
K2 easy/moderate RMSE
start win/tie/loss
score/SVD/runtime
最终唯一结论
```

醒目标记：

```text
KNOWN_K_DIAGNOSTIC_ONLY
NO_MODEL_ORDER_CLAIM
NO_FORMAL_THRESHOLD
NO_STAGE8_1_VALIDATION_PASS
NO_STAGE8_2_AUTHORIZATION
```

---

## 18. Git 提交，仅推送 audit 分支

### 18.1 设计提交

只暂存：

```text
innovation-mining/25_stage8_core_v2_known_k_refactor.md
innovation-mining/stage8_execution_prompts/
005_stage8_core_v2_known_k_pruning_v1.md
```

提交：

```text
docs(stage8-core): define known-k continuous DML refactor
```

### 18.2 工具提交

只暂存：

```text
tools/stage8_core_v2_known_k/
```

提交：

```text
feat(stage8-core): add center-difference known-k solver
```

工具提交后工作树必须 clean，才允许运行 V0–V2 和 24 trials。

### 18.3 结果提交

只暂存：

```text
innovation-mining/26_stage8_core_v2_known_k_pruning_*
```

提交：

```text
docs(stage8-core): record grouped-initialization pruning experiment
```

### 18.4 推送

每次仅推送：

```powershell
git push origin audit/stage8-compact-clear-failure-f6ec19f
```

禁止：

```text
push main
merge main
创建 PR 到 main
force push
修改 experiment 分支
```

每次推送后确认：

```powershell
git rev-parse HEAD
git rev-parse origin/audit/stage8-compact-clear-failure-f6ec19f
git rev-parse origin/main
git status --porcelain=v1 --untracked-files=all
```

---

## 19. 最终报告格式

```text
Target branch:
Audit anchor:
Experiment history tip:
Design commit:
Tool commit:
Result commit:
Push status:
Git clean:
origin/main unchanged:

V0:
V1:
V2:
Selected workers:

Trials:
- K1 16/16
- K2 8/8
- rows 72/72

B0:
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE

B1:
- operational true/false
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE
- score/SVD/runtime

B2:
- operational true/false
- K1 valid
- K2 valid
- K1 off-grid median RMSE
- K2 median RMSE
- score/SVD/runtime

B2 vs B1:
- wins / ties / losses

Final conclusion:
Model-order status = DEFERRED
Formal 6000-trial status = DEFERRED_NOT_FAILED
Stage8.2 executed = false
MATLAB / lock / coordinator:
```

---

## 20. 时间和硬停止

预计：

```text
设计与工具实现：1–3 active hours
V0–V2：10–30 minutes
24 trials：
- 2 workers：15–45 minutes
- 1 worker：30–90 minutes
```

硬停止：

```text
若新 center-difference K2 solver 在 V1 的 easy K2 fixture 上，
direct 与 grouped starts 均不能产生一个有效 known-K K2 fit：
立即输出 K2_SOLVER_NOT_OPERATIONAL_STOP。

不得继续：
- 增加 sweeps
- 放宽 rank
- 增加新 start
- 增加 trial
- 启动第三版 solver
```

本协议完成后等待用户决定：

```text
将 known-K core 集成到正式算法
保留/降级/剪枝 grouped initialization
或停止当前 K2 路线
```
