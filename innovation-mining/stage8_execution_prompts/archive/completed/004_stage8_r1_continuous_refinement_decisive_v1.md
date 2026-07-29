# Stage8-R1：连续参数 DML 与分组初始化去留的 24-trial 决定性实验（V1）

> 将本文件完整交给负责本地 Git、MATLAB R2022b 和实验执行的 Codex。
>
> 本协议只做一次小型、决定性的算法选择实验。它不继续旧的 6000-trial 验证，
> 不重跑 300-cell calibration，不使用旧 threshold 作判决，不执行 separation
> bootstrap，也不执行 Stage8.2。
>
> 协议名称：
>
> ```text
> STAGE8_R1_CONTINUOUS_REFINEMENT_DECISIVE_EXPERIMENT_V1
> ```
>
> 执行授权：
>
> ```text
> AUTHORIZE_STAGE8_R1_CONTINUOUS_REFINEMENT_DECISIVE_EXPERIMENT_V1
> ```

---

## 0. 本次实验要回答的唯一问题

当前 audit 结果已经表明，固定 0.2° 网格下的 K1/K2 LRT 在连续 off-grid K1
场景中发生系统性 false split。本次不再继续精确估计旧算法失败率，而只回答：

```text
Q1. 把固定网格降级为初始化、改用连续完整顺序流形 refinement 后，
    是否能显著消除 off-grid K1 的伪 K2 RSS 增益？

Q2. 在同一连续 refinement 下，真实 K2 的模型阶数区分和角度估计是否仍然有效？

Q3. 分组/条件初始化 M2 相比常规直接局部 DML 初始化 M1，
    是否提供足以保留为核心算法贡献的收益？
```

本实验结束后必须在以下几种结论中选择一个，不允许继续通过增加小修小补拖延：

```text
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_RETAIN
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_OPTIONAL
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_PRUNE_CANDIDATE
STAGE8_R1_CONTINUOUS_MODEL_ORDER_NOT_RECOVERED
STAGE8_R1_EXPERIMENT_INVALID
```

---

## 1. 当前 Git 状态与不可变锚点

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

远端 main：

```text
b5d434720ba9c6e249f0a2197ff886dd133ffd88
fix(stage8): isolate compact MATLAB batch output
```

当前 audit 分支：

```text
audit/stage8-compact-clear-failure-f6ec19f
```

audit 分支锚点：

```text
f6ec19fc28e8c317a5f92416658be06a72ee19a1
docs(stage8): record compact K1-K2 algorithm diagnostic
```

该 audit commit 相比 `b5d4347` 只增加以下 4 个负结果文件：

```text
innovation-mining/23_stage8_compact_algorithm_diagnostic.md
innovation-mining/23_stage8_compact_algorithm_diagnostic_trials.csv
innovation-mining/23_stage8_compact_algorithm_diagnostic_summary.csv
innovation-mining/23_stage8_compact_algorithm_diagnostic_profiles.csv
```

当前负结果必须完整保留，不得 amend、删除、覆盖或改写。

### 1.1 新建独立实验分支

必须从 audit commit 创建新分支，不得直接在 audit 分支或 main 上开发：

```powershell
Set-Location E:\bs_innovation

git fetch origin

git switch --detach `
  f6ec19fc28e8c317a5f92416658be06a72ee19a1

git switch -c experiment/stage8-r1-continuous-refinement-decisive-v1
```

随后确认：

```powershell
git rev-parse HEAD
git status --porcelain=v1 --untracked-files=all
git merge-base --is-ancestor `
  f6ec19fc28e8c317a5f92416658be06a72ee19a1 HEAD
```

要求：

```text
HEAD 初始为 f6ec19f
工作树为空
audit commit 是当前分支祖先
```

不得执行：

```text
reset --hard 到旧 main
rebase / force-push audit 分支
修改 origin/main
删除 audit 分支
```

---

## 2. 本次明确停用的旧 Stage8 部分

本实验不得调用或依赖：

```text
旧 q_global threshold 作模型阶数判决
旧 threshold artifact 作 PASS/FAIL gate
Bsep=199 separation bootstrap
K2_RESOLVED / K2_UNRESOLVED 六状态机
正式 300-cell calibration
正式 6000-trial K1 validation
Stage8.2
Wilson gate
OUT_OF_LOCAL_CELL 状态
```

旧 threshold 与 calibration 文件只作为历史证据保留，不得修改。

本实验只计算：

```text
K1 fit
K2 fit
RSS1
RSS2
Lambda_12
已知 K 下的角度误差
初始化到最终 refinement 的改善
score/SVD/runtime
```

---

## 3. 允许与禁止修改的路径

### 3.1 允许新增

```text
tools/stage8_r1_continuous_decisive/
innovation-mining/stage8_execution_prompts/
004_stage8_r1_continuous_refinement_decisive_v1.md
```

### 3.2 禁止修改

不得修改以下已有内容：

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
```

本次连续算法先作为外部实验原型实现。只有实验结论支持后，才另行授权将其集成到
Stage8 正式代码。

---

## 4. 最小工具文件集

新增：

```text
tools/stage8_r1_continuous_decisive/
├── README.md
├── matlab/
│   ├── stage8_r1_constants.m
│   ├── stage8_r1_build_registry.m
│   ├── stage8_r1_generate_trial.m
│   ├── stage8_r1_refine_continuous_dml.m
│   ├── stage8_r1_build_direct_grid_pair_start.m
│   ├── stage8_r1_fit_continuous_method.m
│   ├── stage8_r1_evaluate_trial.m
│   ├── stage8_r1_checkpoint_hash.m
│   ├── stage8_r1_validate_checkpoint.m
│   ├── stage8_r1_worker.m
│   ├── stage8_r1_merge_analyze.m
│   └── stage8_r1_run_gates.m
├── powershell/
│   └── Stage8R1Decisive.ps1
└── tests/
    ├── test_continuous_refinement_determinism.m
    ├── test_continuous_refinement_monotonicity.m
    ├── test_trial_pairing_and_truth_isolation.m
    └── test_one_two_worker_equivalence.m
```

允许合并文件，但不得把实验代码放入 frozen Stage8 路径。

---

## 5. 三种被比较的方法

每个 element-domain trial 使用完全相同的数据，依次评价 M0、M1、M2。

### 5.1 M0：当前固定网格 Stage8

标识：

```text
M0_FIXED_GRID_REGISTERED_STAGE8
```

实现：

```matlab
[context, ~] = build_stage8_initialization_context_from_data(...);

[fit1, debug1] = fit_local_model_k( ...
    full_data, 1, local_domain, model, context, struct());

context.k1_fit = fit1;

[fit2, debug2] = fit_local_model_k( ...
    full_data, 2, local_domain, model, context, struct());

lrt = nested_dml_likelihood_ratio(fit1, fit2, struct());
```

M0 只作为当前失败基线，不修改其行为。

### 5.2 M1：常规直接局部 DML + 连续 refinement

标识：

```text
M1_CONVENTIONAL_CONTINUOUS_FULL_SEQUENTIAL_DML
```

#### K1 start

只使用：

```text
context.conventional_singleton_peak_deg
```

#### K2 starts

必须恰好使用以下两个、不含 grouped 结果的 starts：

```text
M1_K2_DIRECT_GRID_PAIR_BEST
M1_K2_K1_EMBEDDED_FISHER_ANCHOR
```

`M1_K2_DIRECT_GRID_PAIR_BEST`：

1. 对 `local_domain.candidate_points_deg` 的全部无序、互异点对进行枚举；
2. 每个点对按 elevation、azimuth canonical order 排序；
3. 使用完整顺序流形和 K=2 DML score；
4. 排除 effective rank < 2 的点对；
5. 取 score 最大的点对；
6. score 在数值容差内相同，取 lexicographic first。

`M1_K2_K1_EMBEDDED_FISHER_ANCHOR`：

1. 先得到 M1 的连续 K1 fit；
2. 将它写入独立 context 的 `k1_fit`；
3. 调用现有 `build_k2_initializations(...)`；
4. 只读取第三个 `K2_K1_EMBEDDED_NESTED_START`；
5. 不读取其中两个 grouped starts。

两个 K2 starts 都执行相同的连续 refinement，最后在 valid starts 中选择
concentrated log likelihood 最大者。

### 5.3 M2：分组/条件初始化 + 连续 refinement

标识：

```text
M2_GROUPED_CONDITIONAL_CONTINUOUS_FULL_SEQUENTIAL_DML
```

#### K1 start

只使用：

```text
context.grouped_q1_kq1_angles_deg
```

#### K2 starts

必须恰好使用：

```text
context.grouped_q1_kq2_angles_deg
context.grouped_q2_kq1_plus_kq1_angles_deg
```

两个 starts 都执行与 M1 完全相同的连续 refinement，最后在 valid starts 中选择
concentrated log likelihood 最大者。

### 5.4 公平性规则

M1 与 M2 必须共享：

```text
同一 Y_element
同一 W_I / T_I
同一 local-domain bounds
同一连续优化器
同一收敛容差
同一 max sweeps
同一 K1/K2 DML score
同一 rank contract
同一 source coefficient recovery
```

不得：

```text
给 M2 使用 truth
给 M1 使用更粗容差
给 M2 增加额外 rescue start
给 M1/M2 使用不同连续优化预算
```

M1 与 M2 的初始化成本和 refinement 成本分别记录，但本实验的首要 gate 是有效性，
不是最终复杂度优越性。

---

## 6. 连续 refinement 的精确定义

新增：

```matlab
stage8_r1_refine_continuous_dml( ...
    full_data, initial_angles_deg, local_domain, model, opts)
```

不得调用 `fmincon` 或第三方工具箱。

允许使用 MATLAB R2022b 基础函数：

```text
fminbnd
```

### 6.1 固定参数

```text
max_sweeps                    = 8
coordinate_radius_deg         = 0.20
scan_point_count              = 9
fminbnd_TolX_deg              = 1e-4
fminbnd_MaxFunEvals           = 80
relative_score_tolerance      = 1e-9
angle_update_tolerance_deg    = 1e-3
rank_multiplier               = 1
update_order                  = target → azimuth → elevation
canonical_order               = elevation → azimuth
```

这些值写入 solver contract hash，不得在 trial 间变化。

### 6.2 每个坐标更新

对 target `k` 的一个角维度 `d`：

1. 当前值为 `x0`；
2. 取：
   ```text
   lower = max(domain lower bound, x0 - 0.20)
   upper = min(domain upper bound, x0 + 0.20)
   ```
3. 在 `[lower, upper]` 上评估 9 个等距 scan nodes；
4. rank < K 或非有限 score 的候选记为无效；
5. 选择最大 score node；
6. 并列时按以下顺序：
   ```text
   最小 |candidate - x0|
   再取较小角度
   ```
7. 以最佳 node 左右相邻 scan node 构造局部 bracket；
8. 在局部 bracket 内执行 `fminbnd` 最小化 `-score`；
9. `fminbnd` 中 rank < K 或非有限 score 返回有限大惩罚值；
10. 将以下候选统一比较：
    ```text
    当前 x0
    最佳 scan node
    fminbnd candidate
    bracket 两端
    ```
11. 只有 candidate score 大于当前 score 加数值容差时才接受；
12. 每次接受后 canonicalize K 个目标；
13. 不允许 score 单调下降。

### 6.3 扫描跨网格移动

若局部最优落在 `x0 ± 0.20` 的 bracket 边界，下一 sweep 以新位置为中心继续搜索，
因此算法可以跨越多个旧 grid cells，不得把连续搜索限制在初始点的单个邻域。

### 6.4 收敛

每个完整 sweep 后计算：

```text
max_angle_update
relative_score_change
```

同时满足：

```text
max_angle_update <= 1e-3 degree
relative_score_change <= 1e-9
```

则收敛。

达到 8 sweeps 未同时满足时：

```text
返回当前最优估计用于调试记录
status = CONTINUOUS_REFINEMENT_MAX_SWEEPS
fit_valid_for_lrt = false
```

该估计不得进入 Lambda、AUC、operating-point 或 model-order recovery 计算。
本实验不放宽现有“有效 LRT fit 必须收敛”的原则。

### 6.5 最终结果

最终角度必须保留连续 double，不得重新 snap 到 0.2° grid。

使用现有：

```text
build_full_sequential_local_manifold
concentrated_dml_rss
solve_fitted_source_coefficients
```

构造完整 fit。

M1 和 M2 的 K1/K2 fit 必须共享同一个 continuous solver contract hash，
以便调用现有：

```matlab
nested_dml_likelihood_ratio
```


### 6.6 实验 fit 合同与 start 选择

M1/M2 的每个 continuous start 最终必须构造成与现有 Stage8 fit 兼容的结构，
至少包含：

```text
K
angles_hat_deg
G_hat
S_hat
score
rss
sigma2_hat
loglik_concentrated
effective_rank
fit_status
estimate_returned_flag
converged_flag
fixed_measurement_hash
local_domain_hash
solver_contract_hash
observation_hash
effective_whitening_dimension
snapshot_count
n_complex_observations
phase_factor
```

一个 start 只有同时满足以下条件才是 valid：

```text
初始化存在且有限
continuous refinement status = CONTINUOUS_REFINEMENT_CONVERGED
estimate_returned_flag = true
converged_flag = true
effective_rank >= K
RSS、sigma2、loglik 有限
RSS >= 0
fixed measurement / domain / solver / observation identity 完整
phase_factor = 1
```

每个方法内部的 K2 多 start 选择规则固定为：

```text
MAXIMUM_CONCENTRATED_LOG_LIKELIHOOD_AMONG_VALID_STARTS
```

并列容差：

```text
64 * eps(max(1, abs(max_loglik)))
```

并列时按本协议注册的 start 顺序选择第一项。

K1/K2 fit 构造完成后必须调用：

```matlab
validate_stage8_fit_for_lrt
nested_dml_likelihood_ratio
```

不得在 helper 中另写不同的 Lambda 公式。若任一 fit 无效，该 trial/method 的
`lambda_12` 必须为 NaN，并计入 invalid-fit 统计。

---

## 7. 24 个 element-domain trials

本实验只评价：

```text
PRIMARY_RECT_E14_A31
```

不评价 FULL_PARENT，不使用旧 threshold。

### 7.1 K1：16 trials

固定 truth support：

```text
ON_GRID:
center = [8.0, 10.0] degree

INSIDE_OFF_GRID:
center = [8.1, 10.1] degree
```

因素：

```text
support ∈ {ON_GRID, INSIDE_OFF_GRID}
L       ∈ {1, 8}
SNR     ∈ {-6, +6} dB
noise   ∈ {WHITE, STAGE5_TOEPLITZ_CORRELATED}
```

总数：

```text
2 × 2 × 2 × 2 = 16
```

循环顺序固定：

```text
noise outer
→ L
→ SNR
→ support inner
```

每个 `(noise,L,SNR)` 的 ON_GRID 与 INSIDE_OFF_GRID 使用同一个 noise seed，
构成配对对照。

K1 noise seed base：

```text
2726072800
```

对 8 个 `(noise,L,SNR)` 组合按上述顺序编号 `c=0..7`：

```text
noise_seed = 2726072800 + c
```

数据生成必须调用：

```matlab
generate_stage8_k1_element_trial( ...
    center, snr_db, L, model, noise_seed)
```

### 7.2 K2：8 trials

固定 center：

```text
[8.0, 10.0] degree
```

固定方向：

```text
45 degree
```

固定 source：

```text
secondary_power_db      = 0
correlation_magnitude   = 0
correlation_phase_rad   = 0
```

难度：

```text
EASY:
separation = 0.30 degree
SNR        = +6 dB

MODERATE:
separation = 0.15 degree
SNR        = 0 dB
```

因素：

```text
difficulty ∈ {EASY, MODERATE}
L          ∈ {4, 8}
noise      ∈ {WHITE, STAGE5_TOEPLITZ_CORRELATED}
```

总数：

```text
2 × 2 × 2 = 8
```

循环顺序固定：

```text
noise outer
→ L
→ difficulty inner
```

每个 `(noise,L)` 的 EASY 与 MODERATE 使用同一个 noise seed。

K2 noise seed base：

```text
2726072900
```

对 4 个 `(noise,L)` 组合按上述顺序编号 `c=0..3`：

```text
noise_seed = 2726072900 + c
```

K2 targets：

```matlab
direction = [cosd(45), sind(45)];

targets = [center - separation_deg * direction / 2;
           center + separation_deg * direction / 2];
```

K2 source：

```matlab
[S, source_info] = construct_deterministic_source_matrix( ...
    2, L, 0, 0, 0, diagnostic_profile_id);
```

按目标 element SNR 缩放，然后调用：

```matlab
generate_stage8_element_noise(model, L, 1, noise_seed)
```

生成同一个 `Y_element`，供 M0/M1/M2 共用。

---

## 8. Truth 隔离

truth 只允许用于运行后的误差评价。

不得把以下字段传入 initialization、fit、score、LRT 或 start selection：

```text
truth target angles
trial_type K1/K2
ON_GRID / OFF_GRID 标签
difficulty
true separation
```

每个结果 row 必须包含：

```text
truth_used_in_initialization_flag = false
truth_used_in_fit_flag            = false
truth_used_in_lrt_flag            = false
```

任何一个为 true：

```text
STAGE8_R1_EXPERIMENT_INVALID
```

---

## 9. 每 trial 的输出

一个 element trial 是一个原子 checkpoint。每个 checkpoint 包含 M0/M1/M2 三行。

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

fit1_valid
fit2_valid
fit1_status
fit2_status
fit1_selected_start
fit2_selected_start
fit1_start_count
fit2_start_count

rss1
rss2
rss_gap = rss1 - rss2
lambda_12
n_complex_observations

k1_estimate_az_deg
k1_estimate_el_deg

k2_estimate_target1_az_deg
k2_estimate_target1_el_deg
k2_estimate_target2_az_deg
k2_estimate_target2_el_deg

known_K_joint_rmse_deg
known_K_azimuth_rmse_deg
known_K_elevation_rmse_deg
known_K_separation_vector_error_deg

initial_known_K_joint_rmse_deg
refinement_improved_flag

score_call_count
svd_call_count
runtime_sec
continuous_solver_status
monotonicity_violation_count

truth_used_in_initialization_flag
truth_used_in_fit_flag
truth_used_in_lrt_flag
```

K2 truth matching只允许在 fit 完成后，对两个 target permutation 取最小二维平方角成本。

---

## 10. Checkpoint 与恢复

Runtime root：

```text
E:\bs_innovation_runtime\
stage8_r1_continuous_refinement_decisive_v1_f6ec19f
```

目录：

```text
protocol.json
registry.csv
checkpoints\
tmp\
workers\
status\
logs\
merged\
control\
```

每个 checkpoint：

```text
checkpoints\<trial_id>.mat
```

写入：

```text
tmp\<trial_id>.mat.tmp
→ reload
→ validate
→ atomic move
→ checkpoints\<trial_id>.mat
```

scientific hash 包含：

```text
trial identity
element_trial_hash
三种方法的所有科学结果
solver contract
source code hash
completion status
```

scientific hash 排除：

```text
worker_id
PID
attempt number
start/end timestamp
runtime_sec
```

已验证 checkpoint 永不覆盖、永不重跑。

---

## 11. Worker 与暂停恢复

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

静态分片：

```text
worker_id = mod(global_trial_index - 1, worker_count) + 1
```

### 11.1 手动控制

```powershell
$runner = 'E:\bs_innovation\tools\stage8_r1_continuous_decisive\powershell\Stage8R1Decisive.ps1'
$runtime = 'E:\bs_innovation_runtime\stage8_r1_continuous_refinement_decisive_v1_f6ec19f'

& $runner -Action Init     -RuntimeRoot $runtime
& $runner -Action Gates    -RuntimeRoot $runtime
& $runner -Action Start    -RuntimeRoot $runtime
& $runner -Action Status   -RuntimeRoot $runtime
& $runner -Action Pause    -RuntimeRoot $runtime
& $runner -Action Resume   -RuntimeRoot $runtime
& $runner -Action Finalize -RuntimeRoot $runtime
```

Pause 只创建：

```text
control\pause.request
```

worker 完成当前 trial、写入 checkpoint 后退出。

只有：

```text
active_worker_count = 0
tmp_checkpoint_count = 0
current_lock_count = 0
safe_to_shutdown = true
```

才允许关机。

本实验不注册 Windows 定时任务，不允许 Codex 持续轮询。

---

## 12. 最小必要 Gates

### Gate R0：起点与边界

检查：

```text
当前分支 = experiment/stage8-r1-continuous-refinement-decisive-v1
f6ec19f 是祖先
工作树 clean
audit 四文件存在且 SHA 未变
calibration 未变
formal results/ 未变
无 MATLAB / coordinator / active lock
```

失败：

```text
R0_FAIL_STOPPED
```

### Gate R1：连续 optimizer 正确性

使用两个无正式结果意义的内部 fixture：

```text
F1: K1 on-grid, L=4, SNR=+6, WHITE
F2: K1 inside-off-grid, L=4, SNR=+6, WHITE
```

要求：

```text
重复运行两次 scientific hash 完全一致
final score >= initial score - numeric tolerance
monotonicity_violation_count = 0
最终角度在 domain bounds 内
最终角度不强制等于 grid
on-grid fixture 的连续结果不劣于 fixed-grid RSS
off-grid fixture 的连续 K1 RSS 不高于 fixed-grid K1 RSS
truth flags 全部 false
```

失败：

```text
R1_FAIL_STOPPED
```

### Gate R2：checkpoint/resume

使用 F1 和 F2：

```text
不中断运行
vs
完成 F1 后 Pause → 退出 MATLAB → 新会话 Resume → 完成 F2
```

要求：

```text
两个 checkpoint scientific hash 完全一致
合并 rows 完全一致
```

失败：

```text
R2_FAIL_STOPPED
```

### Gate R3：1-worker / 2-worker 等价性

使用以下 4 个正式 registry trial 的复制 fixture：

```text
K1 ON_GRID,      L=1, SNR=-6, WHITE
K1 OFF_GRID,     L=8, SNR=+6, CORRELATED
K2 EASY,         L=4, WHITE
K2 MODERATE,     L=8, CORRELATED
```

比较：

```text
1 worker
vs
2 workers
```

要求所有 scientific hashes 完全一致。

若不一致：

```text
selected_worker_count = 1
selected_execution_mode = ONE_WORKER_RESUMABLE
```

保留差异报告，但只要单 worker R1/R2 PASS，可继续正式 24 trials。

若一致：

```text
selected_worker_count = 2
selected_execution_mode = TWO_WORKER_RESUMABLE
```

---

## 13. 分析公式

### 13.1 Lambda

每种方法独立计算：

\[
\Lambda_{12}
=
2n_C\log\frac{RSS_1}{RSS_2}.
\]

不得使用旧 q_global 作判决。

### 13.2 Off-grid pseudo-gap closure

只对 8 个 K1 inside-off-grid trials，令：

\[
\Delta_{\mathrm{M0}}
=
RSS_{1,\mathrm{M0}}-RSS_{2,\mathrm{M0}},
\]

\[
\Delta_m
=
RSS_{1,m}-RSS_{2,m},
\qquad m\in\{\mathrm{M1},\mathrm{M2}\}.
\]

定义：

\[
\mathrm{closure}_m
=
1-
\frac{\max(\Delta_m,0)}
{\max(\Delta_{\mathrm{M0}},\epsilon_{\rm numeric})}.
\]

若 `Delta_M0` 小于数值容差，该 trial 不进入 closure 中位数，但必须保留记录。

### 13.3 AUC

使用全部：

```text
16 个 K1 Lambda
8 个 K2 Lambda
```

按所有 K2/K1 pair 的严格比较计算经验 AUC：

```text
K2 Lambda > K1 Lambda : 1
相等                   : 0.5
更小                   : 0
```

不得调用依赖工具箱的 ROC 函数。

### 13.4 诊断 operating point

候选 threshold 集：

```text
-inf
所有唯一观测 Lambda
+inf
```

判决规则固定为：

```text
Lambda > threshold → K2
```

在满足：

```text
K1 FPR <= 2/16 = 0.125
```

的候选中选择最大 K2 TPR。

并列时：

```text
先选更低 FPR
再选更高 threshold
```

此 threshold 只用于本次诊断，不得保存为正式 calibration threshold。

---

## 14. 决策规则

### 14.1 方法级 model-order recovery

对 M1 或 M2，只有同时满足以下条件才定义为：

```text
MODEL_ORDER_RECOVERED = true
```

条件：

```text
16/16 K1 的 K1/K2 fits 均 valid
至少 7/8 K2 trials 的 K1/K2 fits 均 valid

empirical AUC >= 0.80

在 K1 FPR <= 0.125 时：
best K2 TPR >= 0.75

8 个 off-grid K1 trials 中：
median pseudo-gap closure >= 0.70
且至少 6/8 的 closure >= 0.50
```

### 14.2 Grouped 初始化去留

先看 M1/M2 的 `MODEL_ORDER_RECOVERED`。

#### 情况 A：M2 recovered，M1 未 recovered

```text
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_RETAIN
```

#### 情况 B：M1 recovered，M2 未 recovered

```text
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_PRUNE_CANDIDATE
```

#### 情况 C：二者都未 recovered

```text
STAGE8_R1_CONTINUOUS_MODEL_ORDER_NOT_RECOVERED
```

#### 情况 D：二者都 recovered

对 8 个 K2 trials 比较 known-K joint RMSE。

定义：

```text
M2 win:
RMSE_M2 < RMSE_M1 - 1e-6 degree

tie:
abs(RMSE_M2 - RMSE_M1) <= 1e-6 degree
```

若：

```text
M2 wins >= 5/8
且 median_RMSE_M2 <= 0.90 * median_RMSE_M1
```

则：

```text
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_RETAIN
```

若：

```text
M2 wins <= 2/8
且 median_RMSE_M2 >= 1.10 * median_RMSE_M1
```

则：

```text
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_PRUNE_CANDIDATE
```

其他情况：

```text
STAGE8_R1_CONTINUOUS_MODEL_ORDER_RECOVERED_GROUPED_OPTIONAL
```

### 14.3 Experiment invalid

以下任一发生：

```text
缺失 trial
重复 trial
checkpoint hash invalid
truth leakage
M0 无法复现 frozen fit 路径
continuous optimizer 非确定
score 单调性破坏
数据未在三种方法间共享
```

则唯一结论为：

```text
STAGE8_R1_EXPERIMENT_INVALID
```

不得解释科学结果。

---

## 15. 输出文件

正式运行期间所有 checkpoint 位于仓库外。

Finalize 后只允许新增：

```text
innovation-mining/24_stage8_r1_continuous_refinement_decisive_experiment.md
innovation-mining/24_stage8_r1_continuous_refinement_decisive_trials.csv
innovation-mining/24_stage8_r1_continuous_refinement_decisive_summary.csv
innovation-mining/24_stage8_r1_continuous_refinement_method_comparison.csv
```

### 15.1 报告必须包含

```text
branch / HEAD
audit anchor
protocol source hash
R0/R1/R2/R3
worker count
24/24 trial completeness
72 method rows completeness
M0/M1/M2 valid rates
on-grid / off-grid Lambda
pseudo-gap closure
AUC
best TPR at FPR<=0.125
K2 RMSE
M2 vs M1 win/tie/loss
score/SVD/runtime
最终唯一结论
```

醒目标记：

```text
DIAGNOSTIC_DECISIVE_EXPERIMENT_ONLY
NO_FORMAL_THRESHOLD
NO_STAGE8_1_VALIDATION_PASS
NO_STAGE8_2_AUTHORIZATION
```

---

## 16. 工具提交、运行与结果提交

### 16.1 工具提交

只暂存：

```text
tools/stage8_r1_continuous_decisive/
innovation-mining/stage8_execution_prompts/
004_stage8_r1_continuous_refinement_decisive_v1.md
```

提交：

```text
feat(stage8-r1): add continuous refinement decisive experiment
```

推送：

```powershell
git push -u origin `
  experiment/stage8-r1-continuous-refinement-decisive-v1
```

工具提交后工作树必须 clean，才允许运行 R0–R3 和 24 trials。

### 16.2 结果提交

只暂存 4 个 `innovation-mining/24_*` 文件。

提交：

```text
docs(stage8-r1): record continuous refinement decisive experiment
```

推送同一 experiment 分支。

不得：

```text
合并 main
推进 audit 分支
修改 origin/main
创建正式 threshold
执行 Stage8.2
```

---

## 17. 最终报告给用户的格式

```text
Experiment branch:
Tool commit:
Result commit:
Push status:
Git clean:

R0:
R1:
R2:
R3:
Selected workers:

Trials:
- K1 16/16
- K2 8/8
- method rows 72/72

M0:
- AUC
- best TPR at FPR<=0.125
- off-grid median Lambda

M1:
- model-order recovered true/false
- AUC
- best TPR at FPR<=0.125
- median pseudo-gap closure
- K2 median RMSE

M2:
- model-order recovered true/false
- AUC
- best TPR at FPR<=0.125
- median pseudo-gap closure
- K2 median RMSE

M2 vs M1:
- wins / ties / losses
- score/SVD/runtime comparison

Final conclusion:
Formal 6000-trial status:
Stage8.2 executed:
MATLAB / lock / coordinator:
```

---

## 18. 时间预算与停止要求

本实验不执行 bootstrap separation，规模只有 24 element trials。

预计：

```text
工具实现与测试：1–3 active hours
R0–R3：10–30 minutes
24 trials：
- 2 workers：20–60 minutes
- 1 worker fallback：40–120 minutes
```

若连续优化明显超过 2 小时仍未完成：

```text
安全 Pause
保存 status
检查单 trial score-call explosion
不得临时减少 trial、改变容差或跳过方法
```

本实验完成后必须停止，等待用户根据唯一结论决定：

```text
集成连续 Stage8
保留/降级/剪枝 grouped initialization
或放弃当前 LRT model-order 路线
```
