# Stage8 紧凑 K1/K2 算法诊断：4-worker 候选、可中断恢复执行协议（V2）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 与 Git 的 Codex。
>
> 本协议优先验证 Stage8 算法本身是否有效，不执行完整 6000-trial 正式认证。
> 它复用已完成的 committed thresholds、现有 K1 common-trial evaluator 和 checkpoint
> 设计，只新增独立的 K2 诊断生成、选择性 separation、4-worker 编排与紧凑汇总。
>
> 授权令牌：
>
> ```text
> AUTHORIZE_STAGE8_COMPACT_K1_K2_DIAGNOSTIC_4WORKER_V2
> ```

---

## 0. 当前状态与决策

### 0.1 当前远端和本地锚点

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

当前已知 clean HEAD：

```text
237e351e91cc330315332b40dda1413189b04eb3
fix(stage8.1): preserve formal separation in pilot
```

其前序执行工具提交：

```text
bb43c16a28789ab614c29955c36ef219237b5ae7
feat(stage8.1): add resumable sharded k1 validation runner

ca300aa6d66f56a218b793125a02e1328443e7c5
fix(stage8.1): harden sharded runner controls
```

threshold evidence commit：

```text
64cd2d6eae0813f8fd9266ec9ffe6bab4f616267
docs(stage8.1): freeze k1 bootstrap thresholds
```

当前执行现场：

```text
Gate 0                         PASS
Gate 1                         INTERRUPTED_BY_SCOPE_CHANGE
Gate 1 checkpoint              NONE
Gate 2A / Gate 2B              NOT_STARTED
formal 6000-trial validation   NOT_STARTED
Stage8.2                       NOT_STARTED
results/                       only .gitkeep
calibration                    unchanged
MATLAB / lock / coordinator    0 / 0 / 0
Git                            clean
status scheduled task          not registered
```

旧 Pilot 现场必须保留：

```text
E:\bs_innovation_runtime\
stage8_1b_k1_validation_sharded_resumable_v2_9bfa65e6\pilot
```

### 0.2 Git 决策

不得回退、revert、force-push 或删除以下提交：

```text
bb43c16
ca300aa
237e351
```

正式 6000-trial 状态记录为：

```text
FULL_STAGE8_1B_K1_VALIDATION_DEFERRED_NOT_FAILED
FORMAL_6000_TRIAL_AUTHORIZATION_SUSPENDED
```

不得写成：

```text
STAGE8_1_K1_VALIDATION_FAIL
```

当前不恢复旧 Gate 1。旧 Pilot 只作为中断审计现场，不参与紧凑诊断。

---

## 1. 授权范围与硬边界

本次允许：

1. 在 Stage8 冻结身份范围之外新增紧凑诊断工具；
2. 复用现有 committed thresholds；
3. 复用 `tools/stage8_1b_validation_sharded/` 中已验证的只读 helper；
4. 使用 1 至 4 个独立 MATLAB R2022b `-singleCompThread` worker；
5. 每个 element trial 完成后写原子 checkpoint；
6. 手动 Pause、关机、次日 Resume；
7. 每 15 分钟由 Windows Task Scheduler 更新一次状态和 ETA；
8. 生成独立的诊断报告和 CSV；
9. 提交、推送后停止。

本次禁止：

1. 不执行完整 6000-trial formal validation；
2. 不执行 Stage8.2；
3. 不重新校准 threshold；
4. 不修改 13 个 calibration artifacts；
5. 不修改冻结 Stage8 step 下任何 `.m` 或根 `README.md`；
6. 不修改 Stage8 dependency、plan、solver、measurement model、正式 seed 或 gate；
7. 不写正式 `results/`；
8. 不使用 `parpool`、`parfor` 或 trial 内 MATLAB 多线程；
9. 不把 truth 输入初始化器、fit、LRT、bootstrap 或 classifier；
10. 不把诊断结果称为正式 Wilson PASS；
11. 不允许 Codex 使用持续 `while/sleep` 轮询；
12. 不建立额外多层 manifest/hash 证据体系。

---

## 2. 必须保持的冻结身份

```text
stage8_stable_code_identity_hash
fa28f6f202c37dc800b801c47eb4e0f9381a3fc46d1fdc230e145e49d3a215bf

stage8_plan_hash
7dc1e4c361d22ec52ec255381e3cea3ce176a8877b4cfe56f12d25564749ca5d

stage8_calibration_plan_hash
5cf12356433c9680cc3f1ca783667de1910b8135e76141d0fc72271fbe596760

stage8_validation_plan_hash
9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7

measurement_registry_hash
d0eaebc931b1cf4cb3b25865f7127789bb81d97151405fd5f0db255e0221e5d0

calibration_evidence_bundle_hash
a0cc8530293f7b34b46e2dff3f95653421f1122acfa7011487c131c29846047f

threshold_set_hash
e53a786f574883e07203818a11ffd96cb89d7e2b815d8785d7376e845999fdd1
```

正式 thresholds：

```text
PRIMARY_RECT_E14_A31
q_global = 38.430562169212443
hex      = 4043371ca941d4c5
artifact = 074158e7c069e5d2d1eb9487171814cfda7a3795a33d5e2fce70bb9f72740c11

SENSITIVITY_FULL_PARENT_5X5
q_global = 38.484033510562568
hex      = 40433df4cf610464
artifact = fa112e2fc1828199f3d4dc4367c83dbea582e692ebeb7903929dbf9fd193d185
```

---

## 3. 旧正式 Pilot 的范围切换记录

不要修改或删除旧 `pilot/` 内容。

在旧 runtime 根之外或其根目录新增：

```text
scope_change_record_compact_diagnostic_v2.json
```

内容至少为：

```json
{
  "status": "FULL_STAGE8_1B_K1_VALIDATION_DEFERRED_NOT_FAILED",
  "old_protocol": "STAGE8_1B_K1_VALIDATION_SHARDED_RESUMABLE_V2",
  "old_gate0": "PASS",
  "old_gate1": "INTERRUPTED_BY_SCOPE_CHANGE",
  "old_gate2": "NOT_STARTED",
  "formal_trials_started": false,
  "formal_results_written": false,
  "stage8_2_executed": false,
  "old_runtime_preserved": true,
  "next_protocol": "STAGE8_COMPACT_K1_K2_DIAGNOSTIC_4WORKER_V2"
}
```

旧 runtime 不得作为新诊断的 checkpoint 来源。

---

## 4. 新工具和 runtime 布局

新增目录：

```text
tools/stage8_compact_diagnostic/
```

新增提示词：

```text
innovation-mining/stage8_execution_prompts/
003_stage8_compact_k1_k2_diagnostic_4worker_v2.md
```

建议最小文件集：

```text
tools/stage8_compact_diagnostic/
├── README.md
├── matlab/
│   ├── stage8_compact_constants.m
│   ├── stage8_compact_build_registry.m
│   ├── stage8_compact_generate_k2_trial.m
│   ├── stage8_compact_evaluate_k2_trial.m
│   ├── stage8_compact_checkpoint_hash.m
│   ├── stage8_compact_validate_checkpoint.m
│   ├── stage8_compact_worker.m
│   ├── stage8_compact_build_status.m
│   └── stage8_compact_merge_report.m
├── powershell/
│   └── Stage8CompactDiagnostic.ps1
└── tests/
    ├── test_compact_k1_evaluator_evidence.m
    ├── test_compact_k2_generation_contract.m
    ├── test_compact_checkpoint_resume.m
    └── test_compact_worker_equivalence.m
```

允许只读复用：

```text
tools/stage8_1b_validation_sharded/matlab/
stage8_1b_evaluate_common_trial.m
stage8_1b_write_json_atomic.m
stage8_1b_protocol_source_tree_hash.m
```

不得修改现有正式 sharded runner，除非发现可独立复现、与本诊断无关的真实 bug；
这种 bug 必须单独提交，不能与本工具混合。

新 runtime：

```text
E:\bs_innovation_runtime\
stage8_compact_k1_k2_diagnostic_4worker_v2_237e351
```

---

## 5. 重新设计后的最小必要 Gates

本诊断不恢复旧 Gate 1，也不重新执行原 60-trial 双重 reference/external Pilot。

### Gate C0：冻结身份与 clean preflight

工具提交并推送、Git clean 后运行一次。

检查：

```text
237e351 是当前 HEAD 的祖先
64cd2d6 是当前 HEAD 的祖先
git status 为空
237e351..HEAD 的 frozen Stage8 step diff 为空
calibration 13 个 CSV 均 tracked 且 hash 不变
results/ 只有 .gitkeep
MATLAB / coordinator / lock 为 0
MATLAB release = R2022b
maxNumCompThreads = 1
formal threshold loader PASS
所有冻结 identity/hash 不变
```

输出：

```text
COMPACT_GATE_C0_FROZEN_IDENTITY_PASS
```

任一失败：

```text
COMPACT_GATE_C0_FAIL_STOPPED
```

并硬停止。

### Gate C1：K1 evaluator 等价证据复用

优先复用已有科学 smoke 证据：

```text
E:\bs_innovation_runtime\
stage8_1b_sharded_implementation_tests\
nonformal_scientific_smoke.log
```

要求可确认：

```text
SMOKE_PASS = 1
reference row hash
d78ace209ee3ac352255a77d0c7ef09ee060c8fd12be39502722076b8d96f328

external row hash
d78ace209ee3ac352255a77d0c7ef09ee060c8fd12be39502722076b8d96f328

lambda num2hex equality = true
```

若该本地证据缺失或无法验证，只补跑：

```text
每个 stratum 1 个 K1 common trial
6 common trials
12 rows
```

比较原 reference runner 与：

```matlab
stage8_1b_evaluate_common_trial( ...
    ..., struct( ...
    'formal_run', false, ...
    'separation_formal_run', true, ...
    'Bsep', 199, ...
    'run_separation', true))
```

要求：

```text
row stable hash 一致
element_trial_hash 一致
lambda num2hex 一致
state 一致
separation_status 一致
threshold artifact hash 一致
```

不再执行旧的 60-common-trial Gate 1。

输出：

```text
COMPACT_GATE_C1_K1_EQUIVALENCE_PASS
```

失败：硬停止并修复新工具。

### Gate C2：K2 生成与 truth 隔离合同

使用 4 个诊断 trial：

```text
L1  WHITE       easy
L4  CORRELATED  moderate
L8  WHITE       close/high-correlation
L8  CORRELATED  hard
```

每个 trial 生成两次，要求：

```text
Y_element num2hex 完全一致
element_trial_hash 完全一致
source 总能量合同 PASS
secondary power 合同 PASS
correlation 合同 PASS
两个 target endpoint 位于 local domain
PRIMARY/FULL_PARENT sentinel 使用同一个 Y_element
noise seed、profile seed、separation seed 分离
truth_used_in_fit_flag = false
truth_used_in_classifier_flag = false
```

对于 `L=1`：

```text
correlation_magnitude = 1
```

输出：

```text
COMPACT_GATE_C2_K2_GENERATION_PASS
```

失败：硬停止。

### Gate C3：checkpoint / pause / resume

选择：

```text
1 个 K1 common trial
1 个 K2 sentinel trial
```

执行：

```text
A. 单 worker 不间断
B. 完成第一个 trial 后 Pause
C. worker 安全退出
D. 新 MATLAB 会话 Resume
E. 完成第二个 trial
```

比较：

```text
checkpoint scientific hash
row num2hex
element_trial_hash
state / diagnostic_state
runtime-independent fields
```

必须完全一致。

输出：

```text
COMPACT_GATE_C3_RESUME_PASS
```

失败：硬停止。

### Gate C4：单 worker 与候选多 worker 等价性

Pilot 集：

```text
6 个 K1 element trials：每个 stratum 1 个
6 个 K2 element trials：每个 stratum 1 个
共 12 个 element trials
```

先由一个 worker 完成，作为 reference checkpoint set。

候选 worker 数按启动前可用物理内存选择：

```text
Available Physical Memory >= 8.0 GiB  → candidate = 4
6.0–8.0 GiB                           → candidate = 3
4.5–6.0 GiB                           → candidate = 2
< 4.5 GiB                             → candidate = 1
```

多 worker 仍全部：

```text
MATLAB R2022b
-singleCompThread
no parpool
no parfor
```

比较单 worker 与 candidate worker：

```text
12/12 checkpoint scientific hash 完全一致
element_trial_hash 完全一致
lambda num2hex 完全一致
state / diagnostic_state 完全一致
K2 angle metrics num2hex 完全一致
无 missing / duplicate trial
无 worker 异常退出
```

资源门：

```text
peak total memory utilization <= 88%
minimum available physical memory >= 2 GiB
无持续 page-file thrashing
candidate run wall time 不得比单 worker慢 20% 以上
```

决策：

```text
candidate=4 且科学/资源门 PASS
→ FOUR_WORKER_RESUMABLE

candidate<4 且科学/资源门 PASS
→ N_WORKER_RESUMABLE

科学结果不一致
→ ONE_WORKER_RESUMABLE

只发生资源门失败
→ 全部 worker 安全暂停
→ candidate 减 1
→ 复用单 worker reference，只重跑多 worker side
```

不得因为 4-worker 资源失败而删除已通过的 checkpoint。

---

## 6. 紧凑诊断规模

### 6.1 K1 sanity

六个 strata：

```text
L ∈ {1,4,8}
noise ∈ {WHITE, STAGE5_TOEPLITZ_CORRELATED}
```

每 stratum：

```text
10 个 common element trials
```

总计：

```text
60 K1 element trials
120 paired configuration rows
```

参数范围与冻结 K1 validation 相同：

```text
center az ∈ [7.5,8.5]
center el ∈ [9.7,10.3]
SNR ∈ [-12,12] dB
```

使用独立诊断 seed：

```text
K1 diagnostic seed base = 2426072700
stride per stratum       = 1000

parameter seeds             block + 0..9
element-noise seeds         block + 100..109
separation auxiliary seeds  block + 200..209
```

PRIMARY 与 FULL_PARENT 必须共享：

```text
center
SNR
Y_element
parameter seed
element-noise seed
```

K1 每个自然满足：

```text
Lambda > q_global
```

的 row 必须运行完整：

```text
Bsep=199 separation bootstrap
```

以区分：

```text
K2_RESOLVED
K2_UNRESOLVED
nondecision
```

不得选择性跳过 K1 的自然 separation trigger。

### 6.2 K2 effectiveness

仍使用六个 `L × noise` strata。

每 stratum 8 个固定难度 profile：

```text
48 K2 element trials
```

全部 48 个 trial 评价 PRIMARY。

每个 stratum 的 profile 1 和 profile 8 同时评价 FULL_PARENT：

```text
12 个 paired K2 sentinel element trials
```

K2 rows：

```text
48 PRIMARY
+12 FULL_PARENT sentinel
=60 rows
```

全诊断总规模：

```text
108 unique element trials
180 evaluation rows
```

K2 seed：

```text
K2 diagnostic seed base = 2526072700
stride per stratum       = 1000

profile/parameter seeds      block + 0..7
element-noise seeds          block + 100..107
separation auxiliary seeds   block + 200..207
```

这些 seed 不得与 calibration、formal validation 或 holdout seed 空间重叠。

---

## 7. K2 八个固定 profile

| Profile | Separation (deg) | SNR (dB) | Secondary power (dB) | Correlation L>1 | 作用 |
|---|---:|---:|---:|---:|---|
| 1 | 0.35 | +6 | 0 | 0 | easy + FULL_PARENT sentinel |
| 2 | 0.30 | +6 | -6 | 0.9 | easy coherent |
| 3 | 0.24 | 0 | -6 | 0.9 | moderate |
| 4 | 0.20 | 0 | -12 | 0.9 | moderate weak |
| 5 | 0.15 | 0 | -6 | 0.99 | close/high correlation |
| 6 | 0.18 | -6 | -6 | 0.9 | low SNR |
| 7 | 0.10 | -6 | -12 | 0.99 | hard |
| 8 | 0.05 | -9 | -12 | 0.99 | boundary + FULL_PARENT sentinel |

对于 `L=1`：

```text
correlation_magnitude = 1
profile 中原 correlation 只作为标签保留
```

建议固定方向：

```text
[0,30,60,90,120,150,45,135] deg
```

中心偏移：

```text
[ 0.00,  0.00]
[-0.10,  0.00]
[ 0.10,  0.00]
[ 0.00, -0.10]
[ 0.00,  0.10]
[-0.10, -0.05]
[ 0.10,  0.05]
[ 0.00,  0.00]
```

目标：

```matlab
direction = [cosd(direction_deg), sind(direction_deg)];

targets = [center - separation_deg * direction / 2;
           center + separation_deg * direction / 2];
```

必须在生成后检查两个 endpoint 都在 frozen local domain。

---

## 8. K2 element-domain 生成合同

使用冻结函数：

```matlab
build_stage8_element_manifold
construct_deterministic_source_matrix
generate_stage8_element_noise
build_stage8_full_data_from_element
```

步骤：

```matlab
A = build_stage8_element_manifold(targets, base_model);

[S, source_info] = construct_deterministic_source_matrix( ...
    2, L, secondary_power_db, correlation_magnitude, ...
    correlation_phase_rad, profile_id);

signal_unscaled = A.A * S;

target_energy = 10^(snr_db/10) * ...
    size(signal_unscaled,1) * size(signal_unscaled,2);

S = S * sqrt(target_energy / ...
    max(norm(signal_unscaled,'fro')^2, realmin));

signal = A.A * S;

noise = generate_stage8_element_noise( ...
    base_model, L, 1, element_noise_seed);

Y_element = signal + noise;
```

实际字段名按现有函数返回结构机械适配，不得改变物理含义。

PRIMARY 与 FULL_PARENT sentinel：

```text
必须共享同一 Y_element
必须共享 truth
必须共享 source matrix
必须共享 element-noise realization
```

truth 只能用于计算完成后的误差指标。

---

## 9. 评价路径与选择性 separation

### 9.1 K1

直接复用：

```matlab
stage8_1b_evaluate_common_trial
```

调用语义：

```matlab
formal_run            = false
separation_formal_run = true
Bsep                  = 199
run_separation        = true
fit_options           = struct()
```

### 9.2 K2 所有 PRIMARY rows

全部执行：

```text
build_stage8_initialization_context_from_data
→ fit_local_model_k(K=1)
→ validate K1
→ fit_local_model_k(K=2)
→ validate K2
→ nested_dml_likelihood_ratio
→ threshold lookup
→ 记录 K2 angles 和误差
```

### 9.3 K2 选择性 separation

只有以下 rows 允许执行 `Bsep=199`：

```text
profile 1 的 PRIMARY 和 FULL_PARENT
profile 8 的 PRIMARY 和 FULL_PARENT
```

即最多：

```text
6 strata × 2 profiles × 2 configs
=24 sentinel rows
```

实际仍只在：

```text
Lambda > q_global
```

时调用 separation。

其他 K2 rows：

```text
Lambda <= q_global
→ diagnostic_state = K1_FAVORED_MISSED_SPLIT

Lambda > q_global
→ diagnostic_state = K2_LRT_DETECTED_SEPARATION_NOT_RUN
```

不得把未执行 separation 的非 sentinel row 计入：

```text
resolved rate
unresolved rate
separation coverage
```

但它们必须计入：

```text
LRT split-detection rate
missed-split rate
K2 fit validity
角度 RMSE
joint-refinement improvement
```

### 9.4 强制 separation fixture

若 Gate C1/C4 中没有自然 separation trigger，可额外创建：

```text
FORCED_SEPARATION_TOOL_EQUIVALENCE_FIXTURE
```

仅用于工具一致性，禁止进入 108 个诊断 trial、summary 或报告结论。

---

## 10. 创新相关的最小指标

每个 K2 row 记录：

```text
truth target angles
K1 estimate
K2 selected start ID
K2 selected-start initial angles
K2 final angles
matched final angles
azimuth RMSE
elevation RMSE
joint 2D RMSE
initial joint 2D RMSE
joint_refinement_improved_flag
true separation vector
estimated separation vector
separation-vector error
lambda_12
threshold
LRT split-detected flag
separation evaluated flag
diagnostic state
fit validity
score count
SVD count
row runtime
```

truth matching只允许在 fit 完成后，采用两个排列中的最小二维角度成本。

当前紧凑诊断不引入完整 AP-DML/PR-DML baseline suite，避免扩张范围。

本轮保留两个直接对照：

```text
selected start vs final joint refinement
PRIMARY vs FULL_PARENT sentinel
```

---

## 11. Checkpoint 合同

一个 element trial 是不可拆分 checkpoint。

K1 checkpoint：

```text
2 rows：PRIMARY + FULL_PARENT
```

K2 checkpoint：

```text
普通 profile：1 PRIMARY row
sentinel profile：2 rows，PRIMARY + FULL_PARENT
```

checkpoint 至少包含：

```text
protocol_version
diagnostic_trial_id
global_trial_index
trial_type
stratum_id
profile_id
rows
truth_metrics
seeds
element_trial_hash
Stage8 frozen identities
threshold artifact hashes
diagnostic protocol source hash
runtime_sec
separation_trigger_count
completion_status
scientific_content_hash
```

scientific hash 必须排除：

```text
worker_id
PID
attempt number
start/end timestamp
host runtime metadata
```

写入：

```text
checkpoints\<trial_id>.mat.tmp
→ reload
→ validate
→ atomic rename
→ checkpoints\<trial_id>.mat
```

有效 checkpoint：

```text
永不覆盖
永不重跑
恢复时先验证再跳过
```

---

## 12. 4-worker 编排

默认目标：

```text
FOUR_WORKER_RESUMABLE
```

分片：

```text
mod(global_trial_index - 1, selected_worker_count)
```

一个 element trial 的全部 rows 必须由同一个 worker 计算。

每个 worker 启动参数：

```text
MATLAB R2022b
-singleCompThread
-batch
```

禁止：

```text
parpool
parfor
backgroundPool
trial 内多线程
```

worker count 只能在所有 worker 已安全停止时修改。

资源降级流程：

```text
Pause all
→ safe_to_shutdown=true
→ 验证所有 checkpoint
→ 修改 selected_worker_count
→ Resume
```

不得在 worker 活跃时重新分片。

---

## 13. 手动 Pause / Resume

PowerShell 控制面：

```powershell
$runner = 'E:\bs_innovation\tools\stage8_compact_diagnostic\powershell\Stage8CompactDiagnostic.ps1'
$runtime = 'E:\bs_innovation_runtime\stage8_compact_k1_k2_diagnostic_4worker_v2_237e351'

& $runner -Action Init     -RuntimeRoot $runtime
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

worker 在当前 element trial 完成、checkpoint 原子写完并验证后退出。

只有：

```text
protocol_stage = PAUSED_SAFE_TO_SHUTDOWN
safe_to_shutdown = true
active_worker_count = 0
tmp_checkpoint_count = 0
current_trial_lock_count = 0
```

才允许关机。

次日 Resume：

```text
验证 Git / identity / calibration / protocol
验证全部已有 checkpoints
只运行缺失 trial
```

---

## 14. 每 15 分钟状态任务

唯一允许的定时任务：

```text
BSInnovation-Stage8Compact-Status
```

每 15 分钟调用：

```powershell
Stage8CompactDiagnostic.ps1 -Action Status
```

该任务只能：

```text
扫描 checkpoint
读取 heartbeat
更新 latest_status.json
更新 latest_status.txt
追加 status_history.csv
```

不得：

```text
启动 worker
暂停 worker
恢复 worker
终止 worker
finalize
调用 Codex
```

Codex 启动任务后停止主动轮询。

状态必须包含：

```text
protocol_stage
Gate C0–C4
selected_worker_count
selected_execution_mode
completed / 108 element trials
completed / 180 rows
K1 completed / 60
K2 completed / 48
每个 stratum/profile 进度
每个 worker PID、当前 trial、elapsed
valid / invalid / tmp checkpoints
natural separation trigger count
K1 state counts
K2 diagnostic-state counts
最近 checkpoint 时间
15 分钟和 60 分钟吞吐量
ETA low / point / high
ETA confidence
pause_requested
safe_to_shutdown
last_error
```

ETA 分类至少分为：

```text
K1 no-separation
K1 separation-triggered
K2 non-sentinel
K2 sentinel no-separation
K2 sentinel separation-triggered
```

完成：

```text
<12 checkpoints    LOW
12–49              MEDIUM
>=50               HIGH
```

---

## 15. 灾难性早停

只允许明显失败早停：

完成至少 30 个 K1 element trials 后，若 PRIMARY：

```text
false-split point rate > 0.50
或 nondecision point rate > 0.50
```

则：

```text
COMPACT_DIAGNOSTIC_CLEAR_FAILURE_EARLY_STOP
```

完成至少 24 个 K2 PRIMARY trials 后，若：

```text
valid K1/K2 fit fraction < 0.50
或 LRT split-detection rate < 0.15
```

则允许早停。

不要使用接近最终 screening 门的早停。

---

## 16. Finalize 与输出

Finalize 前要求：

```text
108/108 valid element-trial checkpoints
180/180 rows
无 duplicate
无 missing
无 tmp
无 active workers
所有 scientific hashes 有效
```

K1 120 rows 可调用现有：

```matlab
summarize_stage8_k1_validation
```

但不得把输出解释为正式 1000/stratum gate。

K2 使用独立 diagnostic summary。

仓库内只生成：

```text
innovation-mining/23_stage8_compact_algorithm_diagnostic.md
innovation-mining/23_stage8_compact_algorithm_diagnostic_trials.csv
innovation-mining/23_stage8_compact_algorithm_diagnostic_summary.csv
innovation-mining/23_stage8_compact_algorithm_diagnostic_profiles.csv
```

禁止写：

```text
beamspace_ml_v18/.../results/
```

报告必须醒目标记：

```text
DIAGNOSTIC_ONLY
NOT_FORMAL_STAGE8_1_K1_VALIDATION
DOES_NOT_AUTHORIZE_STAGE8_2
FULL_6000_TRIAL_VALIDATION_DEFERRED_NOT_FAILED
```

---

## 17. 诊断解释

### PROMISING

以下均满足：

```text
PRIMARY K1 false-split point rate <= 0.10
PRIMARY K1 nondecision point rate <= 0.10
PRIMARY K2 valid-fit fraction >= 0.85
PRIMARY K2 LRT split-detection rate >= 0.70
至少 60% valid K2 rows 的 final joint error
    <= selected-start initial joint error
六个 strata 均至少存在一个 valid K2 fit
```

输出：

```text
STAGE8_COMPACT_DIAGNOSTIC_PROMISING
```

### CLEAR_FAILURE

任一满足：

```text
PRIMARY K1 false-split point rate > 0.25
PRIMARY K1 nondecision point rate > 0.25
PRIMARY K2 valid-fit fraction < 0.70
PRIMARY K2 LRT split-detection rate < 0.30
```

输出：

```text
STAGE8_COMPACT_DIAGNOSTIC_CLEAR_FAILURE
```

其余：

```text
STAGE8_COMPACT_DIAGNOSTIC_MIXED
```

这些是 screening heuristic，不是正式统计 gate。

---

## 18. 时间预算

以此前约 `0.67 s / fit` 和当前自然 separation 波动估算：

```text
工具实现与最小测试       45–120 min
Gate C0–C4              20–50 min

4-worker 正式诊断       45–120 min
3-worker fallback       1–2.5 h
2-worker fallback       1.5–3 h
1-worker fallback       2–4 h
```

从当前 clean 暂停现场到完整报告：

```text
4-worker 主路线         约 2–4 active hours
保守上限                约 4–6 active hours
```

完成 12 个 checkpoint 后输出初步 ETA；完成 50 个后 ETA 应达到 HIGH confidence。

---

## 19. Git 提交

工具提交：

```text
feat(stage8): add compact four-worker diagnostic runner
```

提交范围只允许：

```text
tools/stage8_compact_diagnostic/
innovation-mining/stage8_execution_prompts/
003_stage8_compact_k1_k2_diagnostic_4worker_v2.md
```

结果提交：

```text
docs(stage8): record compact K1-K2 algorithm diagnostic
```

结果提交只允许：

```text
innovation-mining/23_stage8_compact_algorithm_diagnostic*
```

每次提交前检查：

```powershell
git status --short
git diff --name-only
git diff --cached --name-only
```

不得包含：

```text
frozen Stage8 step 修改
calibration 修改
formal results 修改
外部 checkpoint/log
```

推送后停止。

---

## 20. 最终报告格式

```text
HEAD
tool commit
result commit
push status
Git clean
Gate C0/C1/C2/C3/C4
selected_worker_count
selected_execution_mode
runtime root
completed element trials / rows
pause/resume count
K1 false-split / nondecision
K2 valid-fit / LRT detection
K2 RMSE / separation error
joint-refinement improvement fraction
PRIMARY/FULL_PARENT sentinel difference
diagnostic conclusion
formal 6000-trial status = DEFERRED_NOT_FAILED
Stage8.2 executed = false
MATLAB / lock / coordinator = 0 / 0 / 0
```
