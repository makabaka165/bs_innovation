# Stage8.1B Phase B：可恢复、条件双单线程进程分片 K1 validation 执行提示词（V2）

> 将本文件完整交给负责本地仓库与 MATLAB 执行的 Codex。
> 本提示词建立一个新的、明确版本化的执行协议：
>
> `STAGE8_1B_K1_VALIDATION_SHARDED_RESUMABLE_V2`
>
> 它只改变执行编排、checkpoint、暂停/恢复和进程级分片；不得改变统计计划、随机 seed、measurement model、solver、K1/K2 fit、LRT、separation bootstrap、threshold 或最终 gate。

---

## 0. 授权、执行顺序与边界

本次授权令牌：

```text
AUTHORIZE_STAGE8_1B_K1_VALIDATION_SHARDED_RESUMABLE_V2
```

本提示词中的“修改代码”仅指：

```text
在 Stage8 冻结身份范围之外新增执行编排、checkpoint、状态和合并工具。
```

不得修改已经冻结的 Stage8 科学/算法代码。尤其不得修改：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_6_k12_bootstrap_resolution/
```

下的任何现有 `.m` 或步骤根 `README.md`，也不得修改 Stage8 注册 dependency、统计计划、seed、solver、measurement model、threshold、Bsep 或 gate。

本次操作必须按以下顺序推进：

```text
安全停止旧的无 checkpoint 串行尝试
        ↓
只新增外部 orchestration/checkpoint 工具
        ↓
提交并推送工具代码，使 Git clean
        ↓
Gate 0：冻结身份与 committed-threshold preflight
        ↓ PASS
Gate 1：外部单进程 evaluator 与原 reference runner 一致
        ↓ PASS
Gate 2A：单进程 checkpoint/pause/resume 与 uninterrupted 结果一致
        ↓ PASS
Gate 2B：双进程分片与已验证单进程结果一致
        ↓
按决策树选择两个 worker 或一个可恢复 worker
        ↓
正式可恢复 validation
        ↓
6000 checkpoints 完整后单进程 merge/validate/finalize
```

授权范围：

1. 安全停止当前无 checkpoint 的串行 Phase B 尝试；
2. 在 Stage8 身份范围之外新增可恢复分片执行工具；
3. 提交并推送工具/协议代码；
4. 执行串行参考、单进程可恢复、双进程分片及暂停恢复 pilot；
5. 根据 pilot 的明确决策树自动选择两个 worker 或一个 worker；
6. 在仓库外保存每个 common trial 的原子 checkpoint、进度、ETA、worker 状态和日志；
7. 允许用户随时手动请求安全暂停、关机，次日手动恢复；
8. 仅注册一个每 15 分钟更新状态和 ETA 的 Windows 定时任务；
9. 禁止注册固定时间自动启动、自动暂停或自动关机任务；
10. 全部 checkpoint 完成后，确定性合并 12000 行，调用现有 validator 与 finalizer；
11. 如实提交 PASS 或 FAIL 的 8 个 validation artifacts；
12. 推送后停止。

明确禁止：

- 不执行 Stage8.2；
- 不重新校准 threshold；
- 不修改 13 个 calibration artifacts；
- 不修改冻结 Stage8 step 下任何现有 `.m` 或根 `README.md`；
- 不修改 Stage8 注册 dependency 文件；
- 不修改 plan、seed、Bsep、solver、measurement configuration 或 gate；
- 不使用 `parpool`、`parfor` 或单个 trial 内的 MATLAB 多线程；
- 不让多个 worker 写同一个 checkpoint 或 `results/`；
- 不删除、覆盖或重跑已经存在且验证通过的正式 common-trial checkpoint；
- 不为了 PASS 删除失败/非决策样本；
- 不把 `SEARCH_NOT_CONVERGED`、`NUMERIC_RANK_DEFICIENT` 当成环境失败重跑；这些是有效统计输出状态；
- 不允许 Codex 使用持续 `while/sleep` 轮询；状态由 15 分钟定时任务维护。

## 1. 冻结起点

仓库：

```text
E:\bs_innovation
```

Phase A threshold evidence commit：

```text
64cd2d6eae0813f8fd9266ec9ffe6bab4f616267
```

必须保持不变的科学身份：

```text
stage8_stable_code_identity_hash
fa28f6f202c37dc800b801c47eb4e0f9381a3fc46d1fdc230e145e49d3a215bf

stage8_plan_hash
7dc1e4c361d22ec52ec255381e3cea3ce176a8877b4cfe56f12d25564749ca5d

stage8_calibration_plan_hash
5cf12356433c9680cc3f1ca783667de1910b8135e76141d0fc72271fbe596760

stage8_validation_plan_hash
9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7

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

冻结统计计划：

```text
6 strata = L in {1,4,8} × noise in {WHITE, STAGE5_TOEPLITZ_CORRELATED}
1000 common trials / stratum
6000 common trials
2 configurations / common trial
12000 evaluation rows
Bsep = 199
threshold lookup only
PRIMARY alone authorizes Stage8.2
FULL_PARENT is sensitivity only
```

---

## 2. 先安全停止当前串行尝试

当前串行 runner 没有 checkpoint，不能把已完成的内存 rows 恢复为正式证据。

执行：

1. 在实际计算 MATLAB 窗口按 `Ctrl+C`；
2. 等待 MATLAB 返回命令提示符；
3. 不优先使用任务管理器强杀；
4. 记录中断 UTC、本地时间、MATLAB PID、累计 CPU 时间、私有内存、运行时长；
5. 关闭 MATLAB；
6. 确认 MATLAB/coordinator/active lock 均为 0；
7. 确认 `results/` 仍只有 `.gitkeep`；
8. 确认 13 个 calibration CSV 字节未变化；
9. 确认 Git 工作树干净。

在仓库外创建：

```text
E:\bs_innovation_runtime\stage8_1b_k1_validation_interrupted_serial_attempt_64cd2d6
```

保存：

```text
interrupted_attempt.json
process_snapshot.txt
git_status.txt
calibration_snapshot.csv
```

该目录仅用于说明旧尝试被中断，不得作为 validation evidence，也不得尝试恢复其中不存在的 trial rows。

若 `results/` 已出现任何正式 artifact，或 calibration bytes 变化，立即停止，不执行后续步骤。

---

## 3. 正确的并行边界与自动选择规则

并行原子必须是一个完整的 common trial：

```text
COMMON_TRIAL_ATOMIC_PAIR
├── 同一个 Y_element
├── PRIMARY_RECT_E14_A31 evaluation
└── SENSITIVITY_FULL_PARENT_5X5 evaluation
```

不得把同一个 common trial 的两个 configuration 分配给两个 worker。

每个 worker 必须是：

```text
MATLAB R2022b
-singleCompThread
不启动 parpool
不使用 parfor
不启用 trial 内并行
```

候选双 worker 静态奇偶分片：

```text
worker 1: global_common_trial_index 为奇数
worker 2: global_common_trial_index 为偶数
```

### 3.1 三类“不一致”必须采用不同处理

不能把所有不一致都笼统地称为“回退”。必须遵守以下决策树：

| Gate | 检查内容 | 失败处理 |
|---|---|---|
| Gate 0 | stable identity、Stage8/plan/calibration/validation hash、threshold、formal loader、Git clean | **硬停止**。不能并行，也不能用新工具正式单进程运行 |
| Gate 1 | 外部单进程 evaluator 与原 reference runner 的 raw rows/状态/hash 一致 | **硬停止并修复工具**。不能回退，因为外部 evaluator 自身尚未证明正确 |
| Gate 2A | 外部单进程 checkpoint/pause/resume 与其 uninterrupted 单进程结果一致 | **硬停止并修复 checkpoint/resume** |
| Gate 2B | 外部双进程结果与已经通过 Gate 1/2A 的外部单进程结果一致 | **自动回退到一个可恢复 worker**，保留 pilot 差异证据，不执行双 worker |
| Resource gate | 双 worker 正确，但速度、内存或换页门不合格 | **自动回退到一个可恢复 worker** |
| 全部通过 | 双 worker 数值/状态/恢复一致，资源收益合格 | 选择两个 worker 正式执行 |

因此：

```text
reference/evaluator 不一致  → STOP_AND_FIX_TOOL
checkpoint 恢复不一致       → STOP_AND_FIX_RECOVERY
只有并行相对单进程不一致    → FALLBACK_ONE_WORKER_RESUMABLE
并行正确但收益不足           → FALLBACK_ONE_WORKER_RESUMABLE
全部通过                     → TWO_WORKER_SHARDED_RESUMABLE
```

即使自动退回一个 worker，也必须继续使用 per-common-trial checkpoint/resume；不得退回旧的全内存、不可恢复 runner。

## 4. 源码修改边界与文件布局

本任务**不会修改之前已经冻结的 Stage8 算法代码来“打开并行”**。它会新增一层外部执行工具，调用现有科学函数完成相同的 common-trial 计算，并通过 pilot 证明一致性。

新增文件只能位于：

```text
tools/stage8_1b_validation_sharded/
innovation-mining/stage8_execution_prompts/
```

建议最小文件集：

```text
tools/stage8_1b_validation_sharded/
├── README.md
├── matlab/
│   ├── stage8_1b_evaluate_common_trial.m
│   ├── stage8_1b_sharded_worker.m
│   ├── stage8_1b_sharded_pilot.m
│   ├── stage8_1b_validate_checkpoint.m
│   ├── stage8_1b_build_status.m
│   └── stage8_1b_sharded_merge_finalize.m
├── powershell/
│   └── Stage8K1Sharded.ps1
└── tests/
    ├── test_external_runner_matches_reference.m
    ├── test_single_worker_checkpoint_resume.m
    ├── test_sharded_serial_parallel_equivalence.m
    └── test_checkpoint_pause_resume.m

innovation-mining/stage8_execution_prompts/
└── 002_stage8_1b_resumable_sharded_k1_validation_v2.md
```

可以减少文件数，但不得把新 `.m` 放到：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_6_k12_bootstrap_resolution/
```

也不得修改 `collect_stage8_dependency_scope.m` 所注册的任何 dependency。

工具提交后必须证明：

```text
Stage8 step diff = empty
stage8_stable_code_identity_hash unchanged
stage8_plan_hash unchanged
stage8_calibration_plan_hash unchanged
stage8_validation_plan_hash unchanged
threshold_set_hash unchanged
formal threshold loader PASS
```

任何一项变化都属于 Gate 0 FAIL，必须停止。

## 5. 外部 common-trial evaluator 的实现要求

`stage8_1b_evaluate_common_trial.m` 必须机械复刻当前提交 `64cd2d6` 中：

```text
run_stage8_1_k1_validation.m
```

以下局部逻辑：

```text
draw_trial_parameters_local
evaluate_method_local
identity_from_fit_local
failed_evaluation_local
validation_row_local
```

并复刻主循环内单个 common trial 的逻辑：

1. 从 frozen registry 取得恰好两行；
2. 按 `evaluation_row_index` 排序；
3. 用第一行的 noise profile/model 解析 base model；
4. 使用注册的 `parameter_seed` 生成 center 和 SNR；
5. 使用注册的 `element_noise_seed` 生成一次 `Y_element`；
6. 计算一次 `element_trial_hash`；
7. 对两个 configuration 依次：
   - 解析 model；
   - 校验 paired element covariance factorization hash 一致；
   - 构造 full data；
   - 按 measurement config lookup committed threshold；
   - 完整执行 Stage4/5 initialization；
   - 完整执行 K1 fit；
   - 完整执行 K2 fit；
   - 计算 nested LRT；
   - 仅在 `Lambda > q_global` 时执行正式 `Bsep=199` separation bootstrap；
   - 使用注册的 separation auxiliary seed 和正式 substream schedule；
   - 调用现有 classifier；
   - 构造与原 runner 完全相同字段和类型的 row；
8. 返回恰好两行 MATLAB table。

不得重新实现以下科学函数；必须调用仓库现有函数：

```text
build_stage8_initialization_context_from_data
fit_local_model_k
validate_stage8_fit_for_lrt
nested_dml_likelihood_ratio
bootstrap_separation_confidence
classify_local_cluster_state
generate_stage8_k1_element_trial
build_stage8_full_data_from_element
resolve_stage8_measurement_model
```

正式 worker 必须固定：

```text
formal_run = true
Bsep = 199
run_separation = true
fit_options = struct()
```

不得提供命令行 override。

输出 table 的 variable names、顺序和数据类型必须与原 `validation_row_local` 一致，且不得添加额外列。

---

## 6. Formal preflight 与协议身份

在工具代码提交前，可以做非 formal 单元测试；正式 pilot/正式运行只能从工具代码已提交、Git clean 的 HEAD 开始。

工具提交建议标题：

```text
feat(stage8.1): add resumable sharded k1 validation runner
```

提交并推送后，记录：

```text
protocol_runner_commit = 当前 HEAD
protocol_source_tree_hash = tools/stage8_1b_validation_sharded 下 tracked blobs 的确定 hash
```

要求：

```powershell
git merge-base --is-ancestor 64cd2d6eae0813f8fd9266ec9ffe6bab4f616267 HEAD

git diff --name-only 64cd2d6eae0813f8fd9266ec9ffe6bab4f616267..HEAD -- `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution
```

第二条必须为空。

在 MATLAB R2022b `-singleCompThread` 中重新构建 formal plan，并断言：

```text
stable code identity 完全不变
Stage8 plan hash 完全不变
calibration plan hash 完全不变
validation plan hash 完全不变
measurement registry hash 完全不变
calibration bundle 完全不变
threshold set hash 完全不变
两个 threshold artifact hash 完全不变
formal loader PASS
COMMITTED_THRESHOLD_PREFLIGHT_PASS
```

若任何冻结 hash 变化，停止，不运行 pilot，不运行正式 validation。

正式运行期间：

- HEAD 必须始终等于 `protocol_runner_commit`；
- Git 工作树必须始终干净；
- 不得 checkout、pull、commit 或编辑仓库；
- runtime checkpoint 必须全部写到仓库外。

---

## 7. Runtime 根目录与协议清单

正式 runtime 根：

```text
E:\bs_innovation_runtime\stage8_1b_k1_validation_sharded_resumable_v2_9bfa65e6
```

目录结构：

```text
runtime_root/
├── protocol.json
├── frozen_calibration_snapshot.csv
├── control/
│   └── pause.request                 # 仅在请求暂停时存在
├── checkpoints/
│   ├── K1V_L1_N1_T0001.mat
│   └── ...
├── tmp/
├── incomplete/
├── workers/
│   ├── worker_01_status.json
│   ├── worker_02_status.json
│   ├── worker_01.pid
│   └── worker_02.pid
├── logs/
│   ├── worker_01_*.log
│   ├── worker_02_*.log
│   ├── coordinator.log
│   └── status_history.csv
├── status/
│   ├── latest_status.json
│   └── latest_status.txt
├── pilot/
└── merged/
```

`protocol.json` 至少绑定：

```text
protocol_version
execution_authorization
repo_dir
protocol_runner_commit
protocol_source_tree_hash
threshold_evidence_commit
stage8_stable_code_identity_hash
stage8_plan_hash
stage8_calibration_plan_hash
stage8_validation_plan_hash
measurement_registry_hash
calibration_evidence_bundle_hash
threshold_set_hash
calibration_snapshot_hash
matlab_release
threads_per_worker = 1
requested_worker_count = 2
selected_worker_count
selected_execution_mode
pilot_decision
fallback_reason
status_interval_minutes = 15
automatic_start_enabled = false
automatic_pause_enabled = false
automatic_shutdown_enabled = false
status_task_name = BSInnovation-Stage8K1-Status
partition_rule = ODD_EVEN_GLOBAL_COMMON_TRIAL_INDEX
common_trial_count = 6000
row_count = 12000
Bsep = 199
pause_check_boundary = BETWEEN_COMMON_TRIALS
checkpoint_contract_version
created_utc
```

初始化后 `protocol.json` 不得被 worker 修改。

---

## 8. Common-trial checkpoint 合同

每个 common trial 完成后写一个 `.mat` checkpoint，包含：

```text
checkpoint.protocol_version
checkpoint.checkpoint_contract_version
checkpoint.common_trial_id
checkpoint.global_common_trial_index
checkpoint.rows                         # 恰好两行
checkpoint.stage8_stable_code_identity_hash
checkpoint.stage8_plan_hash
checkpoint.stage8_validation_plan_hash
checkpoint.measurement_registry_hash
checkpoint.calibration_evidence_bundle_hash
checkpoint.threshold_set_hash
checkpoint.calibration_snapshot_hash
checkpoint.threshold_lookup_only_flag = true
checkpoint.threshold_modification_flag = false
checkpoint.completion_status = COMPLETE_PASS
checkpoint.content_hash
checkpoint.runtime_sec                  # 诊断，不进入 content_hash
checkpoint.worker_id                    # 诊断，不进入 content_hash
checkpoint.attempt_id                   # 诊断，不进入 content_hash
checkpoint.created_utc                  # 诊断，不进入 content_hash
```

`content_hash` 必须按以下内容计算：

```text
STAGE8_1B_K1_COMMON_TRIAL_CHECKPOINT_V1
+ common_trial_id
+ global_common_trial_index
+ sortrows(rows, evaluation_row_index)
+ 所有冻结身份/hash
+ threshold_lookup_only_flag
+ threshold_modification_flag
+ completion_status
```

不得把 runtime、PID、worker ID、attempt、timestamp 写入科学 content hash。

原子写入：

```text
checkpoints/<trial>.mat.tmp
→ 完整 save
→ reload
→ validate
→ movefile/rename 为 checkpoints/<trial>.mat
```

规则：

- 已存在且验证通过的 final checkpoint：跳过，永不覆盖，永不重算；
- 残留 `.tmp`：移动到 `incomplete/` 后按相同 seed 重算；
- 已存在但验证失败的 final checkpoint：硬停止，保留现场，禁止覆盖；
- scientific nondecision row 是有效完成，不得重试；
- 进程/环境异常且没有 final checkpoint：次日可按同一 seed 重算该 trial。

---

## 9. Worker 行为

每个 worker 启动时必须：

1. 验证当前 HEAD 等于 `protocol_runner_commit`；
2. 验证 Git clean；
3. 验证 MATLAB R2022b 和单线程；
4. 构建 formal Stage8 plan；
5. formal load committed thresholds；
6. 验证全部冻结 hash；
7. 捕获 calibration snapshot，并与 `protocol.json` 一致；
8. 验证 `results/` 只有 `.gitkeep`；
9. materialize 完整 6000-pair registry；
10. 只选择自己的静态奇偶 shard；
11. 校验自己与其他 worker 的 shard 互斥且并集覆盖完整 registry。

每个 trial 前：

- 若 `control/pause.request` 存在，设置 worker 状态为 `PAUSED_SAFE` 并退出；
- 若 valid checkpoint 已存在，验证并跳过；
- 否则写 `current_common_trial_id` 到 status，开始计算。

每个 trial 后：

- 原子写 checkpoint；
- 更新 completed/remaining、last runtime、rolling runtime、separation trigger rows；
- 更新 heartbeat；
- 再检查 pause request。

worker 不得写仓库内 `results/`。

---

## 10. 串行参考—单进程恢复—双进程并行 pilot 与模式选择

正式 6000 trials 前必须执行 pilot。不得跳过。

Pilot subset：

```text
每个 stratum 前 10 个 common trials
6 × 10 = 60 common trials
120 rows
```

### Gate 0：冻结身份与正式 preflight

在工具代码已提交并推送、Git clean 后：

- 重建 formal plan；
- formal load committed thresholds；
- 重算 calibration snapshot；
- 校验所有冻结 hash；
- 校验 `results/` 只有 `.gitkeep`。

任何不一致：

```text
pilot_decision = GATE0_FAIL_STOP
selected_worker_count = 0
```

立即停止。

### Gate 1：外部 evaluator 对原 runner 的参考一致性

使用原始 `run_stage8_1_k1_validation`：

```text
formal_run = false
max_common_trials_per_stratum = 10
Bsep = 199
run_separation = true
frozen_plan = 当前 plan
```

使用外部 evaluator 的 nonformal compatibility 模式运行完全相同 subset。

比较：

```text
120 rows cardinality
所有 registry 字段
center/SNR
element_trial_hash
两个 threshold mapping
lambda 的 num2hex
state
所有 boolean flags
fit validity status
separation status
完整 trial-table stable hash
summary/gate/paired sensitivity
```

必须完全一致。

若 Gate 1 失败：

```text
pilot_decision = REFERENCE_EQUIVALENCE_FAIL_STOP_AND_FIX_TOOL
selected_worker_count = 0
```

不能回退到新工具的单 worker，因为新 evaluator 尚未证明与原算法入口一致。

### Gate 2A：单进程 checkpoint / pause / resume 一致性

在独立 pilot root 中，对同一 60 common trials：

1. 一个 `-singleCompThread` worker uninterrupted 完成一次；
2. 另一个单 worker 运行至少 10 个 checkpoints 后创建 `pause.request`；
3. 等待 `safe_to_shutdown=true`；
4. 终止该 MATLAB 会话，模拟关机边界；
5. 清除/归档 pause request；
6. 启动新的 MATLAB R2022b `-singleCompThread` 会话恢复；
7. 验证 valid checkpoints 全部跳过且未覆盖；
8. 完成相同 60 trials；
9. 比较 uninterrupted 与 resumed 结果。

必须满足：

```text
所有 checkpoint content_hash 完全一致
所有 raw rows 完全一致
所有 lambda num2hex 完全一致
所有 state/separation_status 完全一致
无重复、无遗漏
恢复后未重算任何 valid checkpoint
```

若 Gate 2A 失败：

```text
pilot_decision = RESUME_EQUIVALENCE_FAIL_STOP_AND_FIX_RECOVERY
selected_worker_count = 0
```

立即停止。

### Gate 2B：单进程与双进程分片一致性

在另一个独立 pilot root 中：

1. 启动两个 `-singleCompThread` worker，按奇偶 common trial 分片；
2. 运行至少 10 个 checkpoints 后手动创建 `pause.request`；
3. 等两个 worker 安全退出；
4. 清除/归档 pause request；
5. 手动恢复两个 worker；
6. 完成全部 60 common trials；
7. 与 Gate 2A 已验证的单进程基线比较。

比较要求：

```text
所有 checkpoint content_hash 完全一致
所有 120 raw rows 完全一致
所有 element_trial_hash 完全一致
所有 lambda 的 num2hex 完全一致
所有 state 完全一致
所有 separation_status 完全一致
summary/gate/paired sensitivity 完全一致
无重复、无遗漏
```

若 Gate 2B 失败，但 Gate 0、Gate 1、Gate 2A 均 PASS：

```text
pilot_decision = PARALLEL_EQUIVALENCE_FAIL_FALLBACK_ONE_WORKER
selected_worker_count = 1
fallback_reason = PARALLEL_NUMERIC_OR_STATE_MISMATCH
```

保留串并行差异审计，不修 threshold、不修改算法，正式运行使用一个可恢复 worker。

### Separation coverage

Pilot 必须至少覆盖一个自然 `Lambda > q_global` 的 row。

若 120 rows 中自然触发数为 0，则额外执行一个仅用于诊断、不得进入正式结果的 forced-separation fixture，验证：

```text
199 formal substreams
完整 K1/K2 refit
uninterrupted/resumed/双 worker separation 输出一致
```

### 性能与资源 gate

记录：

```text
single-worker active wall sec
two-worker active wall sec
speedup
每个 worker peak private memory
peak total memory utilization
minimum available physical memory
separation trigger count
mean/median/p90 common-trial runtime
page-file activity
```

选择两个 worker 的最低 gate：

```text
Gate 0/1/2A/2B 全 PASS
speedup >= 1.15
peak total memory utilization <= 85%
minimum available physical memory >= 2 GiB
无持续 page-file thrashing
无 worker crash/OOM
```

决策：

```text
全部正确性与资源门 PASS
→ pilot_decision = PILOT_PASS_TWO_WORKERS
→ selected_worker_count = 2

Gate 0/1/2A PASS，Gate 2B PASS，但资源/速度 FAIL
→ pilot_decision = PILOT_PASS_ONE_WORKER_RESOURCE_FALLBACK
→ selected_worker_count = 1

Gate 0/1/2A PASS，Gate 2B FAIL
→ pilot_decision = PILOT_PASS_ONE_WORKER_PARALLEL_FALLBACK
→ selected_worker_count = 1

Gate 0、Gate 1 或 Gate 2A FAIL
→ selected_worker_count = 0
→ 不启动正式 validation
```

Pilot 结果全部保存在仓库外，不进入最终 12000 rows。

## 11. 中间状态、精确阶段定位与 ETA

整个协议必须始终能回答以下问题：

```text
现在处于实现、preflight、pilot、正式计算、暂停、合并还是 finalization？
当前选用两个 worker 还是一个 worker？为什么？
已经完成多少 common trials、多少 rows、每个 stratum 到哪里？
每个 worker 当前正在计算哪个 trial，已经计算多久？
是否触发 separation bootstrap？
现在是否安全关机？
按当前实际吞吐量，剩余 active compute time 大约是多少？
```

PowerShell `Status` action 每 15 分钟只读扫描 runtime，并生成：

```text
status/latest_status.json
status/latest_status.txt
logs/status_history.csv
```

同时每个 checkpoint 自带 `runtime_sec`，因此关机、暂停和恢复不会丢失 ETA 的历史依据。

### 11.1 `latest_status.json` 必须至少包含

```text
protocol_version
protocol_runner_commit
protocol_stage
pilot_decision
selected_execution_mode
selected_worker_count
fallback_reason
safe_to_shutdown
pause_requested
active_worker_count
worker PIDs
worker process responsive flags
worker CPU time delta over last status interval
worker private memory
worker current_common_trial_id
worker current_stratum_id
worker current_trial_started_utc
worker current_trial_elapsed_sec
worker heartbeat/last status UTC
completed_common_trials / 6000
remaining_common_trials
completed_rows / 12000
completed per stratum
remaining per stratum
completed per worker
valid checkpoint count
tmp checkpoint count
invalid checkpoint count
separation_trigger_row_count
state counts
last checkpoint UTC
minutes since last checkpoint
active wall time
summed successful trial compute time
rolling 15-minute throughput
rolling 60-minute throughput
rolling p50/p75/p90 trial runtime overall
rolling p50/p75/p90 runtime per stratum
rolling separation-trigger rate per stratum
ETA low/point/high active hours
ETA confidence LOW/MEDIUM/HIGH
estimated_finish_if_continuous_local_time
results_directory_clean
calibration_snapshot_match
Git clean
possible_stall_warning
last error
```

### 11.2 ETA 计算规则

不得只用“总运行时间 ÷ 已完成数”粗略外推。因为 `Lambda > q_global` 的 trial 会触发昂贵的 `Bsep=199` separation bootstrap。

ETA 应按以下最小规则计算：

1. 少于 20 个正式 checkpoints：`LOW`；
2. 20–199：`MEDIUM`；
3. 200 以上：`HIGH`；
4. 对每个 stratum 分别统计 common-trial runtime 的 rolling mean、p50、p90；
5. 同时统计各 stratum 的 separation trigger rate；
6. 每个 stratum 的剩余时间由该 stratum 已完成样本的 runtime 分布估计；
7. 两 worker 模式下，总 ETA 取两个 shard 预测剩余 active time 的最大值；
8. 单 worker 模式下，总 ETA 取所有剩余 trial 的分层预测和；
9. `ETA low` 可使用分层 p50，`ETA point` 使用 EWMA/rolling mean，`ETA high` 使用分层 p90；
10. 暂停时间、关机时间不计入 active compute ETA；
11. ETA 仅是运行诊断，不是科学 gate。

不再使用固定每日运行窗口，也不输出基于固定启动/暂停时刻的 calendar-day 估计。

### 11.3 `latest_status.txt` 人类可读格式

至少类似：

```text
Stage8.1B K1 Validation Status
Protocol stage : FORMAL_SHARDED_RUNNING
Pilot decision : PILOT_PASS_TWO_WORKERS
Execution mode : TWO_WORKER_SHARDED_RESUMABLE
Fallback reason: NONE
Progress       : 842 / 6000 common trials (14.03%)
Rows           : 1684 / 12000
Strata         : K1V_L1_N1 143/1000 | ...
Worker 01      : PID 1234 | K1V_L4_N1_T0571 | elapsed 00:06:42
Worker 02      : PID 5678 | K1V_L4_N1_T0572 | elapsed 00:05:19
Separation rows: 17
Throughput     : 31.4 trials/hour (60-minute rolling)
ETA active     : 128.2 h [low 94.1, high 202.7], confidence MEDIUM
Pause requested: false
Safe shutdown : false
Last checkpoint: 2026-07-27 18:45:12
Possible stall: false
```

### 11.4 阶段词汇

```text
INTERRUPTED_SERIAL_ATTEMPT_RECORDED
PROTOCOL_IMPLEMENTATION
PROTOCOL_COMMITTED
GATE0_FORMAL_PREFLIGHT_RUNNING
GATE0_FORMAL_PREFLIGHT_PASS
GATE0_FAIL_STOPPED
GATE1_REFERENCE_RUNNING
GATE1_REFERENCE_PASS
GATE1_REFERENCE_FAIL_STOPPED
GATE2A_SINGLE_RESUME_RUNNING
GATE2A_SINGLE_RESUME_PASS
GATE2A_SINGLE_RESUME_FAIL_STOPPED
GATE2B_PARALLEL_RUNNING
GATE2B_PARALLEL_PASS
GATE2B_PARALLEL_FALLBACK
PILOT_PASS_TWO_WORKERS
PILOT_PASS_ONE_WORKER_RESOURCE_FALLBACK
PILOT_PASS_ONE_WORKER_PARALLEL_FALLBACK
FORMAL_SHARDED_RUNNING
FORMAL_SINGLE_WORKER_RESUMABLE_RUNNING
PAUSE_REQUESTED
PAUSED_SAFE_TO_SHUTDOWN
RESUMING
COMPLETE_CHECKPOINT_SET_6000
MERGE_RUNNING
MERGE_VALIDATION_PASS
FINALIZED_RESULTS_WRITTEN
RESULTS_COMMITTED
ERROR_STOPPED
```

`safe_to_shutdown=true` 只允许在以下条件全部满足时写出：

```text
pause_requested = true
active_worker_count = 0
所有已完成 checkpoint 均已验证
没有 .tmp 正在写入
没有 worker 持有 current trial lock
results/ 未被提前写入
```

因此用户可以根据 `latest_status.txt` 明确判断当前阶段、剩余时间和是否可以关机。

## 12. 仅保留每 15 分钟状态定时任务，禁止 Codex 持续轮询

`Stage8K1Sharded.ps1` 至少支持：

```text
-Action Init
-Action Pilot
-Action Start
-Action Pause
-Action Resume
-Action Status
-Action ForceStop
-Action RegisterStatusTask
-Action UnregisterStatusTask
-Action Finalize
```

不得注册以下固定时间任务：

```text
自动 Start/Resume
自动 Pause
自动 Shutdown
```

不得保留任何固定时刻自动启动、自动暂停或自动关机的硬编码约束。

只允许注册一个 Windows Task Scheduler 任务：

```text
BSInnovation-Stage8K1-Status
```

它每 15 分钟执行一次：

```powershell
Stage8K1Sharded.ps1 -Action Status -RuntimeRoot <runtime_root>
```

### Status task 行为

- 只读扫描 protocol、checkpoints、worker PID、进程 CPU/内存、Git/calibration/results 状态；
- 更新 `latest_status.json`、`latest_status.txt` 和 `status_history.csv`；
- 不启动或恢复 worker；
- 不创建 pause request；
- 不终止进程；
- 不运行 trial；
- 不修改 repo；
- protocol 不存在、已 final 或 runtime 已归档时安全 no-op；
- 不调用 Codex。

### 用户手动暂停与恢复

用户需要关机时手动执行：

```powershell
& E:\bs_innovation\tools\stage8_1b_validation_sharded\powershell\Stage8K1Sharded.ps1 `
  -Action Pause `
  -RuntimeRoot E:\bs_innovation_runtime\stage8_1b_k1_validation_sharded_resumable_v2_9bfa65e6
```

该命令只创建 `control/pause.request`，不直接 kill MATLAB。

随后查看：

```text
status/latest_status.txt
```

只有出现：

```text
stage = PAUSED_SAFE_TO_SHUTDOWN
safe_to_shutdown = true
active_worker_count = 0
```

才正常关机。

次日或任意时间手动恢复：

```powershell
& E:\bs_innovation\tools\stage8_1b_validation_sharded\powershell\Stage8K1Sharded.ps1 `
  -Action Resume `
  -RuntimeRoot E:\bs_innovation_runtime\stage8_1b_k1_validation_sharded_resumable_v2_9bfa65e6
```

Resume 必须：

- 验证 protocol/HEAD/Git/calibration/results；
- 验证所有 existing final checkpoints；
- 归档 pause request；
- 只启动 selected execution mode 所需且当前缺失的 worker；
- valid checkpoint 永不重算。

### ForceStop

仅当用户必须立即关机且 graceful pause 尚未完成时使用：

- 只终止协议 PID 文件登记且命令行匹配 runtime root 的 worker；
- 不触碰其他 MATLAB；
- 已完成 final checkpoint 保留；
- 当前最多损失一个 common trial/worker；
- `.tmp` 次日移动到 `incomplete/` 并按相同 seed 重算；
- 写 forced-stop audit；
- `safe_to_shutdown` 只有确认目标 worker 全部退出后才为 true。

### Codex 轮询边界

Codex 在完成以下动作后必须停止主动轮询：

```text
工具实现/提交
pilot 决策
正式 Init/Start 或 Resume
注册 15 分钟 Status task
立即生成一次 status 快照
```

不得使用长时间 `while/sleep` 查询。

Codex 最后只报告：

```text
status task name
runtime root
selected execution mode
fallback reason
worker PIDs
latest_status.txt 路径
当前 completed/6000
当前 ETA low/point/high
safe_to_shutdown
Pause 命令
Resume 命令
ForceStop 命令
```

后续状态由 Windows Task Scheduler 每 15 分钟维护；用户需要时再让 Codex读取一次 `latest_status.json`。

## 13. 正式执行初始化、手动暂停与恢复规则

正式 `Init`：

1. Gate 0/1/2 pilot 已完成，并存在明确 `pilot_decision`；
2. `selected_worker_count` 只能是 1 或 2；
3. formal plan/loader PASS；
4. 捕获 calibration snapshot；
5. materialize 6000 common trials；
6. 创建 immutable `protocol.json`；
7. 写入 `pilot_decision`、`selected_execution_mode`、`fallback_reason`；
8. 验证 checkpoint 目录为空，或属于完全相同协议身份；
9. 写入初始 status；
10. 注册或验证唯一 15 分钟 Status task；
11. 不写 `results/`。

正式 `Start/Resume`：

1. 读取 immutable protocol；
2. 验证 HEAD、tool source hash、Git clean；
3. 验证 calibration snapshot；
4. 验证 results 只有 `.gitkeep`；
5. 验证全部 existing final checkpoints；
6. existing valid checkpoint 永不重跑；
7. 若 selected worker count=2，启动缺失的奇偶 worker；
8. 若 selected worker count=1，仅启动一个 worker处理全部未完成 trials；
9. 分片并集必须等于完整 6000 trials；
10. 每次启动后立即执行一次 `Status`，随后由 15 分钟任务维护。

正式 `Pause`：

1. 创建 `control/pause.request`；
2. 更新 stage 为 `PAUSE_REQUESTED`；
3. worker 只在当前 common trial 完成、checkpoint 已原子写入后退出；
4. 不直接 kill MATLAB；
5. Status 任务持续更新当前 trial elapsed 和 worker CPU 状态；
6. 全部 worker 退出且无 `.tmp` 后写：

```text
stage = PAUSED_SAFE_TO_SHUTDOWN
safe_to_shutdown = true
```

暂停可以重复，不能改变统计身份或 seed。

恢复时必须使用新的 MATLAB 会话；不能依赖旧工作区内存。恢复依据只能是 immutable protocol 与已验证 final checkpoints。

## 14. 完成后的确定性合并

只有在以下条件全部满足时才允许 `Finalize`：

```text
6000 valid common-trial checkpoints
12000 rows
每个 common trial 恰好两行
6 个 strata
每 stratum/config 恰好 1000 rows
无 duplicate
无 missing
无 invalid final checkpoint
无 active worker
无 tmp write
Git clean
results/ 只有 .gitkeep
calibration snapshot 与初始化完全一致
HEAD 等于 protocol_runner_commit
```

合并：

```matlab
trials = sortrows(all_rows, 'evaluation_row_index');
[summary, gate, paired_sensitivity] = ...
    summarize_stage8_k1_validation(trials, plan.validation.K1);
```

构造 `output`，至少包含：

```text
trials
summary
gate
paired_sensitivity
stage8_stable_code_identity_hash
stage8_plan_hash
stage8_calibration_plan_hash
stage8_validation_plan_hash
measurement_registry_hash
calibration_evidence_bundle_hash
threshold_set_hash
validation_trial_set_hash
validation_summary_hash
paired_sensitivity_hash
primary_gate_hash
calibration_artifact_snapshot
calibration_artifact_snapshot_hash
committed_threshold_preflight_status = COMMITTED_THRESHOLD_PREFLIGHT_PASS
validation_execution_status = STAGE8_1_K1_VALIDATION_COMPLETED
threshold_lookup_only_flag = true
threshold_modification_flag = false
paired_common_trial_count = 6000
method_row_count = 12000
execution_scope = FORMAL_STAGE8_1_K1_VALIDATION_SHARDED_RESUMABLE_V2
phase_factor = 1
runtime = 多会话 active wall time（暂停时间排除）
```

hash 规则必须与现有 wrapper 完全一致：

```matlab
output.validation_trial_set_hash = stage8_stable_hash( ...
    'STAGE8_1_VALIDATION_TRIAL_SET_V1', ...
    sortrows(output.trials, 'evaluation_row_index'));

output.validation_summary_hash = stage8_stable_hash( ...
    'STAGE8_1_VALIDATION_SUMMARY_V1', output.summary);

output.paired_sensitivity_hash = stage8_stable_hash( ...
    'STAGE8_1_PAIRED_SENSITIVITY_V1', output.paired_sensitivity);

output.primary_gate_hash = stage8_stable_hash( ...
    'STAGE8_1_PRIMARY_GATE_V1', output.gate);
```

先调用：

```matlab
validated = validate_stage8_1_validation_output( ...
    plan, calibration, output);
```

必须 PASS。

随后仅调用现有 finalizer：

```matlab
committed_calibration_evidence = struct( ...
    'repo_dir', repo_dir, ...
    'artifact_root', step);

final = run_stage8_1_finalize( ...
    plan, committed_calibration_evidence, output, step, struct( ...
    'formal_run', true, ...
    'execution_authorization', 'AUTHORIZE_STAGE8_1_FINALIZE'));
```

断言：

```text
final.validation_gate_pass == output.gate.gate_pass
final.stage8_2_executed_flag == false
final.stage8_2_separate_authorization_required_flag == true
```

---

## 15. Finalizer 后文件验收

`results/` 必须恰好新增以下 8 个文件：

```text
results/stage8_1_k1_validation_trials.csv
results/stage8_1_k1_validation_summary.csv
results/stage8_1_k1_paired_sensitivity.csv
results/stage8_1_validation_provenance.csv
results/stage8_1_keypoints.csv
results/stage8_1_report.md
results/stage8_1_validation_evidence_manifest.csv
results/stage8_1_runtime_diagnostics.csv
```

验收：

```text
trials = 12000 rows
unique common_trial_id = 6000
summary = 14 rows
paired sensitivity = 6000 rows
threshold lookup only
threshold modification false
calibration 13 files byte-for-byte unchanged
Stage8.2 false
PRIMARY gate 由 raw trials 重新计算
FULL_PARENT 未用于授权
```

无论 PASS 或 FAIL，都保留真实结果。

---

## 16. 结果提交

提交前：

```powershell
git status --short
git diff --name-only
git diff --stat
```

只允许 8 个 `results/` artifacts 出现在第二份 evidence commit 中。

提交标题必须为：

```text
docs(stage8.1): validate k1 false-split control
```

提交、推送后检查：

```text
HEAD == origin/main
Git clean
MATLAB/coordinator/active lock = 0/0/0
Stage8.2 not executed
```

停止，不进入 Stage8.2。

---

## 17. 必须报告的中间与最终信息

### 工具实现提交后

```text
tools commit SHA
push 状态
changed files
Stage8 step diff = empty
stable identity before/after
Stage8/calibration/validation plan hashes before/after
formal loader status
threshold hashes
Git clean
```

### Pilot 后

```text
Gate 0 PASS/FAIL
Gate 1 reference row hash
external reference row hash
Gate 2A uninterrupted single-worker row hash
Gate 2A resumed single-worker row hash
Gate 2B sharded row hash
checkpoint hash equality
lambda num2hex equality
state/separation equality
natural separation trigger count
pause/resume test result
single-worker wall sec
two-worker active wall sec
speedup
peak memory
pilot_decision
selected_execution_mode
selected_worker_count
fallback_reason
```

### 正式启动或恢复后

```text
protocol_runner_commit
protocol_source_tree_hash
runtime root
pilot_decision
selected_execution_mode
selected_worker_count
fallback_reason
worker PIDs
status scheduled task name
completed/6000
rows/12000
per-stratum counts
current trial per worker
separation triggers
throughput 15m/60m
ETA low/point/high
ETA confidence
safe_to_shutdown
latest_status.txt path
Pause 命令
Resume 命令
ForceStop 命令
```

### 每次安全暂停后

```text
stage = PAUSED_SAFE_TO_SHUTDOWN
safe_to_shutdown = true
valid checkpoint count
completed/6000
remaining/6000
active worker count = 0
tmp checkpoint count = 0
last checkpoint
ETA point/high
```

### Finalization 后

```text
6000 checkpoint audit
12000 row audit
14 summary rows
PRIMARY gate PASS/FAIL
all validation hashes
8 artifact manifest
results commit SHA
push status
Git clean
Stage8.2 false
```

## 18. 停止、回退与继续条件

### 18.1 必须硬停止并修复

遇到以下任一情况立即停止并保留现场：

```text
Gate 0 frozen identity/hash/preflight 失败
外部 evaluator 与原 reference runner 不一致
单 worker uninterrupted 与 pause/resume 结果不一致
Stage8 stable identity 变化
Stage8/calibration/validation plan hash 变化
threshold/calibration hash 变化
formal loader/preflight 失败
相同 seed 的 element_trial_hash 在单 worker 自身重跑中不一致
valid final checkpoint 校验失败
checkpoint duplicate/missing 无法解释
Git 变脏
results 提前出现 artifact
calibration snapshot 变化
worker 内部多线程
worker 写入同一 checkpoint
单 worker 模式也发生 OOM/持续换页
final validator 失败
```

这些情况不能自动回退，因为科学 evaluator、恢复机制或冻结身份尚未被证明正确。

### 18.2 可以自动回退到一个可恢复 worker

只有在 Gate 0、Gate 1、Gate 2A 全部 PASS 后，出现以下情况才允许自动回退：

```text
双 worker raw rows/checkpoint/lambda/state/separation 与单 worker 不一致
双 worker speedup < 1.15
双 worker 内存门失败
双 worker 出现 OOM/crash，而单 worker pilot安全
双 worker 持续 page-file thrashing
```

回退动作：

```text
selected_worker_count = 1
selected_execution_mode = ONE_WORKER_RESUMABLE
记录 fallback_reason
保留全部 pilot 差异证据
正式运行只使用单 worker checkpoint/resume
```

不得为了保留双 worker 而放宽数值、状态或 hash 一致性门。

### 18.3 正式继续条件

只有以下条件满足才可正式 Start/Resume：

```text
Gate 0 PASS
Gate 1 PASS
Gate 2A PASS
selected_worker_count in {1,2}
immutable protocol 完整
Git clean
calibration snapshot match
results 只有 .gitkeep
所有 existing checkpoints 验证通过
```

不得用删除文件、放宽 tolerance、降低 Bsep、减少 trial、改 seed、提高 threshold 或重复运行到 PASS 的方式绕过失败。
