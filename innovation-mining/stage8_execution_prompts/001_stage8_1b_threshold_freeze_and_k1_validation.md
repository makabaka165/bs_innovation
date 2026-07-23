# Stage8.1B 后续执行提示词：阈值冻结 → K1 validation

> **用途**：把本文件完整交给负责执行的 AI。它是当前 `Stage8.1B-R2/C2` 完成后的下一步执行合同。
>
> **当前授权边界**：本文件定义两个有明确边界的正式操作。第一次调用本文件时只执行 **Phase A 阈值聚合与证据冻结**；Phase A 提交完成并通过干净提交审计后，只有用户再次明确授权，才执行 **Phase B K1 validation + finalize**。不得因为 Phase A 成功而自动进入 Phase B，更不得进入 Stage8.2。
>
> **本文件不是源码修改任务**：除生成 `calibration/` 和 `results/` 中由正式 writer 注册的证据文件外，不修改 Stage8 源码、README、统计计划、seed、checkpoint 或冻结 schedule。

## 0. 当前状态和身份锚点

执行前先读本节，不要用旧的 `13_next_step_execution_prompts.md` 中已经过时的 “Stage8.1B 未执行” 状态覆盖本节。

- 仓库：`makabaka165/bs_innovation`
- 本地路径：`E:\bs_innovation`
- 当前审计提交：`30c2c75add959988012c5d79f91240f190aa2c1f`，提交标题 `docs(stage8.1): audit R2 calibration execution`
- 校准运行使用的代码基线：`5b2f4c19f9d2b35ef616aa406ac971606056a4fa`
- 外部 checkpoint 根：`E:\bs_innovation_runtime\stage8_1b_a5r2_cellwise_7dc1e4c3`
- checkpoint 子目录：`E:\bs_innovation_runtime\stage8_1b_a5r2_cellwise_7dc1e4c3\checkpoints`
- 已完成状态：`COMPLETE_PASS_300_CELL_CALIBRATION`
- 总体状态仍是：`PARTIAL_STAGE8_1_CALIBRATION_OR_VALIDATION`
- 尚未完成：threshold collection/aggregation/evidence freeze、K1 validation、Stage8.2
- 300-cell 审计结果：checkpoint `300/300`，registry 行 `300`，有限 Lambda `59700/59700`，唯一 bootstrap seed `59700/59700`，有限 `q_cell` `300/300`，artifact/cell/A5 mean identity `300/300`，未解决 scientific/runtime failure 均为 `0`，active lock/coordinator/MATLAB 均为 `0/0/0`
- 冻结 identity（必须保持不变）：
  - `stage8_stable_code_identity_hash = fa28f6f202c37dc800b801c47eb4e0f9381a3fc46d1fdc230e145e49d3a215bf`
  - `stage8_plan_hash = 7dc1e4c361d22ec52ec255381e3cea3ce176a8877b4cfe56f12d25564749ca5d`
  - `stage8_calibration_plan_hash = 5cf12356433c9680cc3f1ca783667de1910b8135e76141d0fc72271fbe596760`
  - `stage8_validation_plan_hash = 9bfa65e64dc97523e36c62e44217e5e4dc93d221de90b29de923a5b0d6a121e7`
  - `mean_identity_contract = 8da2779c03ee3853b0cc2f75e886e749edb967b304c183cb0fb4dfa2a9444e74`

创建本提示词后，正式运行前必须先把本目录的提示词文件作为一个独立 docs 提交落库，使工作树重新干净。这个准备性提交不是 calibration evidence commit，也不能包含任何 Stage8 源码或生命周期证据。若工作树不干净，停止，不要用 `git clean`、`reset --hard` 或删除文件强行继续。

## 1. 算法和统计合同（不得改写）

### 1.1 校准统计量

Stage8 的主统计量是固定白化/测量链上的非正则 K1/K2 concentrated-likelihood LRT：

```text
n_C          = r_C * L
sigma2_hat_K = RSS_K / n_C
ell_K        = -n_C * (log(pi * sigma2_hat_K) + 1)
Lambda_12    = 2 * n_C * log(RSS_1 / RSS_2)
```

普通 chi-square cutoff 只能作为诊断，不能替代正式 bootstrap threshold。

每个 calibration cell 使用 `alpha=0.05`、`Bboot_per_cell=199` 和 type-1 order statistic。每个 bootstrap 样本必须在 element domain 生成：

```text
Y_element = A_element(theta_hat) * S_hat + N_element
N_element ~ CN(0, sigma2_hat * Rn_elem)
```

随后通过该物理 measurement configuration 固定的 `W_I/T_I` 链，并对 K1 和 K2 完整重拟合。不得从 bootstrap 样本中删除失败样本来人为改变分位数；formal refit 失败会使对应 cell 不完整并阻止 aggregate。

### 1.2 阈值聚合规则

正式结果必须只有两个 threshold artifact，分别对应 plan 注册的两个 measurement configuration。每个 configuration 聚合其 150 个 cell（两种 noise profile 的全部注册 cell）：

```text
q_cell_0p95 = TYPE1_ORDER_STATISTIC(Lambda samples, 1 - alpha)
q_global    = max(q_cell_0p95 over the 150 cells of that configuration)
```

threshold contract 版本必须是 `STAGE8_LOCKED_THRESHOLD_ARTIFACT_V3`，并且 threshold artifact hash 绑定 stable code identity、Stage8 plan、calibration plan、measurement registry、configuration ID、`q_global_hex`、`alpha_hex`、cell/sample counts、calibration hash 和 threshold status。不能把 runtime HEAD、临时日志或人工编辑的十进制数写入 hash 合同。

### 1.3 K1 validation 规则

Phase B 只使用已提交的两个 threshold，不重新校准。冻结的 validation plan 是：

- 6 个互斥 strata：`L ∈ {1,4,8}` × `noise ∈ {WHITE, STAGE5_TOEPLITZ_CORRELATED}`；
- 每个 stratum `1000` 个 common element trials，共 `6000` 个 common trials；
- 每个 common trial 对 `PRIMARY_RECT_E14_A31` 和 `SENSITIVITY_FULL_PARENT_5X5` 各评估一次，共 `12000` 个 config rows；
- seed base `2226072200`，每个 stratum 预留连续 3000 个 seed：1000 parameter、1000 element-noise、1000 separation-auxiliary；三类 RNG role 不得复用或重置为一个共享 seed；
- validation threshold lookup-only，`threshold_recalibration_allowed=false`；正式 `Bsep=199` 且必须运行真实 separation bootstrap；
- 只有 `PRIMARY_RECT_E14_A31` 可以授权 Stage8.2。`SENSITIVITY_FULL_PARENT_5X5` 必须标记 `SENSITIVITY_ONLY_NOT_USED_FOR_STAGE8_2_AUTHORIZATION`，不能抵消 PRIMARY 失败；
- 状态词汇只能是 `K1`、`K2_RESOLVED`、`K2_UNRESOLVED`、`OUT_OF_LOCAL_CELL`、`SEARCH_NOT_CONVERGED`、`NUMERIC_RANK_DEFICIENT`。不要把隐藏 truth 输入分类器，也不要恢复旧文档中未启用的 `MODEL_MISMATCH` classifier。

当前预注册门由代码从 PRIMARY summary 重算：overall false-split Wilson upper `<=0.07`、每个 stratum false-split Wilson upper `<=0.08`、false-resolved Wilson upper `<=0.07`、nondecision Wilson upper `<=0.05`。这些是有限样本验收门，不是证明真实总体 false-split `<=0.05` 的数学证明。

`run_stage8_1_k1_validation.m` 只在 `lambda_12 > q_global` 时触发 separation bootstrap；每个触发行做 `199` 个完整 K1/K2 refit。因此 validation 时间不能从 R2 校准时间线性外推。按 R2 约 `0.67 s/fit` 的粗略量级，基础 24000 次拟合约为数小时；每个触发行再增加 398 次拟合，触发率未知，实际应按半天到两天准备。这个时间估计不是成功条件，不得为了赶时间关闭 separation 或降低 `Bsep`。

## 2. 全局禁止事项

执行 AI 必须把以下事项当成硬性拒绝条件：

1. 不修改任何 Stage8 `.m`、任何 plan/registry/seed 定义、checkpoint 格式、冻结 schedule、solver、`phase_factor` 或 Stage8 步骤根 `README.md`。
2. 不修改 `innovation-mining/11_*`、`12_*`、`13_*`、Audit 22 来伪造阶段状态，也不要把 docs 同步混进 evidence commit。若将来要做 docs-only 状态同步，必须另行授权、单独提交，并在下一次正式运行前保持工作树干净；步骤根 README 在阈值依赖链闭合前保持不动。
3. 不删除、移动、覆盖或手工编辑外部 checkpoint、registry、lock、terminal record、schedule 或 runtime manifest；不重跑已经 PASS 的 cell。
4. 不清空 `calibration/` 或 `results/` 以绕过 no-overwrite 检查。正式 writer 的目标生命周期目录在开始时必须只有已跟踪的 `.gitkeep`。
5. 不手工调用 aggregate/writer 绕过正式入口，不传入 formal 入口禁止的 `frozen_plan`、callback、fit override、`Bsep` override 或 `run_separation=false`。
6. 不启动 `parpool`、`parfor`、第二个 MATLAB、第二个 coordinator 或任何并发 worker。Phase A 使用一个 MATLAB R2022b 进程；Phase B 也使用一个 MATLAB 进程，并在同一会话中保留 `output` 给 finalizer。
7. 不执行 Stage8.2、holdout、threshold re-calibration 或论文结论升级；本文件最远只到 `docs(stage8.1): validate k1 false-split control`。
8. 不用 `git reset --hard`、`git checkout --` 或递归删除来处理失败状态。任何 lifecycle 目录半写入都要保留现场并报告。

## 3. Phase A：串行 threshold aggregation / evidence freeze（当前下一步）

### A0. 提交提示词后做 formal preflight

在启动 MATLAB 前，用 PowerShell 做以下审计：

```powershell
Set-Location E:\bs_innovation
git status --short --branch
git log -1 --oneline --decorate
git merge-base --is-ancestor 5b2f4c19f9d2b35ef616aa406ac971606056a4fa HEAD
git diff --name-only 5b2f4c19f9d2b35ef616aa406ac971606056a4fa -- beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution
git ls-files --others --exclude-standard
```

要求：工作树无任何输出（分支行除外）；`5b2f4c1` 必须是 HEAD 的祖先；相对于校准代码基线，步骤目录不得出现 `.m` 或 `README.md` 改动。准备性提示词 docs 提交若已存在于 HEAD，只能在 `innovation-mining/` 下。若出现未跟踪 Stage8 source、步骤根 README 改动或任何未提交证据，立即停止。

检查生命周期目录和 MATLAB/锁状态：

```powershell
$step = 'E:\bs_innovation\beamspace_ml_v18\source\stepwise_signal_model\steps\step_12_6_k12_bootstrap_resolution'
Get-ChildItem (Join-Path $step 'calibration') -Force | Select-Object Name,Length
Get-ChildItem (Join-Path $step 'results') -Force | Select-Object Name,Length
Get-Process matlab,mwpython -ErrorAction SilentlyContinue
Get-ChildItem 'E:\bs_innovation_runtime\stage8_1b_a5r2_cellwise_7dc1e4c3' -Recurse -File |
  Where-Object { $_.Name -match 'lock|\.lck$|coordinator|terminal' } |
  Select-Object FullName,Length,LastWriteTime
```

`calibration/` 和 `results/` 在 Phase A 开始前都只能有 `.gitkeep`；不得把结果目录里的残留当作可覆盖物。外部 runtime 必须对应 Audit 22 的 300-cell evidence，且当前没有 active lock/coordinator/MATLAB。若有 MATLAB 残留，先安全停止并确认进程数为零；不要在旧会话上附加新入口。

### A1. 仅启动一个 MATLAB 会话

使用 MATLAB R2022b。入口函数被找到之前必须先 `addpath(step)` 或 `cd(step)`；不要假设 `stage8_runtime_path_scope()` 能在入口函数被解析前自动添加路径。不要启动并行池。

在这个单独会话中执行以下代码（路径按字面使用）：

```matlab
repo_dir = 'E:\bs_innovation';
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
checkpoint_root = fullfile('E:\bs_innovation_runtime', ...
    'stage8_1b_a5r2_cellwise_7dc1e4c3', 'checkpoints');
addpath(step);

% Do not pass frozen_plan or overwrite in formal mode.
evidence = run_stage8_1_freeze_threshold_evidence( ...
    repo_dir, checkpoint_root, step, struct( ...
    'formal_run', true, ...
    'execution_authorization', ...
    'AUTHORIZE_STAGE8_1B_THRESHOLD_FREEZE'));

assert(strcmp(string(evidence.calibration_freeze_status), ...
    "PASS_STAGE8_1_THRESHOLD_EVIDENCE_FREEZE"));
assert(evidence.cell_count == 300);
assert(evidence.bootstrap_sample_count == 59700);
assert(numel(evidence.two_threshold_artifact_hashes) == 2);
assert(all(strlength(string(evidence.two_threshold_artifact_hashes)) > 0));
assert(~evidence.validation_executed_flag);
assert(~evidence.stage8_2_executed_flag);
assert(strcmp(string(evidence.stage8_stable_code_identity_hash), ...
    "fa28f6f202c37dc800b801c47eb4e0f9381a3fc46d1fdc230e145e49d3a215bf"));
```

这次调用必须让正式函数自行完成：重建当前 locked plan、检查 stable identity/plan hashes、递归收集并验证 300 个外部 checkpoint、重算每个 `q_cell`、聚合两个 `q_global`、验证 V3 threshold artifact、生成校准 bundle，并通过 no-overwrite writer 写入 13 个注册 CSV。不要在 MATLAB 外手工计算或手工改阈值。

如果入口在 writer 前失败，保留完整错误和目录现场；如果 writer 已开始而目录出现部分文件，也不得删除后重跑，必须把实际文件清单和错误报告给用户。函数返回 PASS 不是允许执行 Phase B 的授权。

### A2. Phase A 文件验收

成功返回后，`calibration/` 必须恰好有以下 13 个正式 artifact（外加原有 `.gitkeep`，若 writer 保留它）：

```text
calibration/stage8_1_plan_registry.csv
calibration/stage8_1_measurement_registry.csv
calibration/stage8_1_calibration_cells.csv
calibration/stage8_1_seed_registry.csv
calibration/stage8_1_cell_results.csv
calibration/stage8_1_lambda_samples.csv
calibration/stage8_1_cell_quantiles.csv
calibration/stage8_1_locked_thresholds.csv
calibration/stage8_1_complexity.csv
calibration/stage8_1_provenance.csv
calibration/stage8_1_source_manifest.csv
calibration/stage8_1_calibration_evidence_manifest.csv
calibration/stage8_1_runtime_diagnostics.csv
```

必须进一步核对：

- `stage8_1_calibration_cells.csv` 为 300 个注册 cell；`stage8_1_cell_results.csv` 为 300 行；`stage8_1_cell_quantiles.csv` 为 300 行；
- `stage8_1_lambda_samples.csv` 为 59700 个 bootstrap 样本，seed registry 包含 300 个 calibration-data seed 和 59700 个 bootstrap seed，且 bootstrap seed 唯一；
- `stage8_1_locked_thresholds.csv` 恰好 2 行、两个 configuration ID 各 1 行，`threshold_contract_version` 为 `STAGE8_LOCKED_THRESHOLD_ARTIFACT_V3`，`threshold_status` 为 `LOCKED_BOOTSTRAP_THRESHOLD`；
- provenance 的 `calibration_freeze_status` 为 `PASS_STAGE8_1_THRESHOLD_EVIDENCE_FREEZE`，四个 identity/hash 字段与当前合同一致；
- evidence manifest 自身按 writer 规则处理，不把 manifest 自身 hash 错当作 deterministic bundle hash；runtime diagnostics 不作为 deterministic artifact；
- `git diff --name-only` 中不能出现 `.m`、任何 README、`results/`、checkpoint 或 runtime 文件。

### A3. Phase A 提交和停止

只把上面 13 个 registry artifact 纳入第一份正式证据提交。先审查：

```powershell
Set-Location E:\bs_innovation
git status --short
git diff --stat
git diff --name-only
```

预期只有 `beamspace_ml_v18/.../calibration/stage8_1_*.csv` 这 13 个文件（`.gitkeep` 不应被删除或改写）。不得顺手提交 prompt、README、roadmap 或其他 docs；本提示词的准备性提交必须已经在运行前完成。

确认文件清单和内容后执行：

```powershell
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_plan_registry.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_measurement_registry.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_calibration_cells.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_seed_registry.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_cell_results.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_lambda_samples.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_cell_quantiles.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_locked_thresholds.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_complexity.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_provenance.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_source_manifest.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_calibration_evidence_manifest.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/calibration/stage8_1_runtime_diagnostics.csv
git diff --cached --name-only
git diff --cached --stat
git commit -m "docs(stage8.1): freeze k1 bootstrap thresholds"
```

第一份正式证据提交的提交标题必须逐字为 `docs(stage8.1): freeze k1 bootstrap thresholds`。提交后重新检查 `git status --short --branch`，并按项目约定推送到 `origin/main`；若用户当前只授权本地提交，则停在本地提交，不擅自推送。无论是否推送，下一步 validation 都必须从这个干净 threshold evidence commit 开始。

### A4. Phase A 与 Phase B 之间的硬停止点

在第一份提交后必须停止并报告：commit hash、`calibration_freeze_status`、cell/sample counts、两个 threshold artifact hash、`stage8_stable_code_identity_hash`、13 个文件清单、Git clean/push 状态。不要在同一个授权下自动启动 validation。

只有用户明确授权 `AUTHORIZE_STAGE8_1B_K1_VALIDATION_FROM_COMMITTED_THRESHOLDS` 并确认当前 HEAD 是干净的 threshold evidence commit，才可进入 Phase B。

## 4. Phase B：从干净 threshold commit 执行 K1 validation + finalize

以下部分不是 Phase A 的隐含授权；它是后续单独调用的精确合同。

### B0. 重新审计提交和生命周期

启动前必须确认：

- HEAD 是第一份 threshold evidence commit 的祖先/当前提交，工作树完全干净，`git status --porcelain=v1 --untracked-files=all` 为空；
- `calibration/` 中的 13 个 CSV 已被 tracked，不能只存在于工作树；`load_stage8_1_locked_thresholds` 的 formal loader 能从当前仓库重建并验证它们；
- `results/` 仍只有 `.gitkeep`；若有任何 result 文件，停止，绝不清目录；
- stable identity 仍为 `fa28f6f2...`，Stage8/measurement/calibration/validation hashes 与已冻结合同相同；
- 没有 MATLAB、coordinator、active lock 或未归档 terminal process；外部 300-cell runtime 不被本次 validation 改写。

可以用一次无写入 MATLAB preflight 确认 loader：

```matlab
repo_dir = 'E:\bs_innovation';
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);
plan = build_stage8_locked_plan(repo_dir, sim_cfg(), ...
    struct('require_formal_runtime', true));
[thresholds, calibration] = load_stage8_1_locked_thresholds( ...
    repo_dir, step, plan, struct('formal_run', true, ...
    'require_tracked_artifacts', true));
assert(numel(thresholds) == 2);
assert(strcmp(string(calibration.calibration_freeze_status), ...
    "PASS_STAGE8_1_THRESHOLD_EVIDENCE_FREEZE"));
```

### B1. 同一 MATLAB 会话中的 wrapper 和 finalizer

validation 必须由 committed-threshold wrapper 进入；不得直接调用底层 `run_stage8_1_k1_validation` 作为 formal run，不得传入 test callback 或 fit override。使用一个 MATLAB R2022b 会话，先 `addpath(step)`，然后执行：

```matlab
repo_dir = 'E:\bs_innovation';
step = fullfile(repo_dir, 'beamspace_ml_v18', 'source', ...
    'stepwise_signal_model', 'steps', ...
    'step_12_6_k12_bootstrap_resolution');
addpath(step);

plan = build_stage8_locked_plan(repo_dir, sim_cfg(), ...
    struct('require_formal_runtime', true));
committed_calibration_evidence = struct( ...
    'repo_dir', repo_dir, 'artifact_root', step);

output = run_stage8_1_k1_validation_from_frozen_thresholds( ...
    repo_dir, struct( ...
    'formal_run', true, ...
    'execution_authorization', ...
    'AUTHORIZE_STAGE8_1B_K1_VALIDATION_FROM_COMMITTED_THRESHOLDS', ...
    'calibration_root', step, ...
    'validation_artifact_root', step));

assert(strcmp(string(output.committed_threshold_preflight_status), ...
    "COMMITTED_THRESHOLD_PREFLIGHT_PASS"));
assert(strcmp(string(output.validation_execution_status), ...
    "STAGE8_1_K1_VALIDATION_COMPLETED"));
assert(height(output.trials) == 12000);
assert(numel(unique(string(output.trials.common_trial_id))) == 6000);
assert(height(output.summary) == 14);
assert(output.threshold_lookup_only_flag);
assert(~output.threshold_modification_flag);

% Keep output in this same session. The finalizer checks its calibration
% snapshot hash and recomputes all deterministic validation evidence.
final = run_stage8_1_finalize( ...
    plan, committed_calibration_evidence, output, step, struct( ...
    'formal_run', true, ...
    'execution_authorization', 'AUTHORIZE_STAGE8_1_FINALIZE'));

assert(final.stage8_2_executed_flag == false);
assert(final.stage8_2_separate_authorization_required_flag == true);
assert(final.validation_gate_pass == output.gate.gate_pass);
```

wrapper 必须在第一条 trial 前记录 `COMMITTED_THRESHOLD_PREFLIGHT_PASS` 和 calibration artifact SHA snapshot；validation 期间 calibration bytes 必须不变；finalizer 必须从磁盘 reload committed calibration、重算 14-row summary/paired sensitivity/PRIMARY gate，并且只向 `results/` 写 validation registry。若 validation 在 finalizer 之前中断且 `results/` 仍只有 `.gitkeep`，可以在确认没有残留进程后从同一干净 threshold commit 重新运行整个 wrapper；不要把不完整的内存 `output` 当成可恢复 evidence。

### B2. Phase B 文件验收和第二份提交

正式 `results/` 必须恰好由 validation registry 注册的 8 个 artifact 组成：

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

提交前必须核对：

- trials 是 12000 行、6000 个 paired common trials、每个 6 个 stratum/config 组合均为 1000；
- summary 恰好 14 行：2 个 configuration × (`OVERALL` + 6 strata)；
- paired sensitivity 覆盖每个 common trial，且 FULL_PARENT 仍是 sensitivity-only；
- provenance 显示 `COMMITTED_THRESHOLD_PREFLIGHT_PASS`、`STAGE8_1_K1_VALIDATION_COMPLETED`、threshold/calibration/validation hashes；
- `stage8_1_keypoints.csv` 和 report 如实写 `STAGE8_1_K1_VALIDATION_PASS` 或 `STAGE8_1_K1_VALIDATION_FAIL`，不能将 FAIL 改写为 PASS；
- calibration/ 下 13 个 CSV 的字节、hash、manifest 和 threshold artifact hash 与 validation 前完全一致；
- `stage8_2_executed_flag=false` 且 `stage8_2_separate_authorization_required_flag=true`；
- Git diff 中只有上述 8 个 `results/` 文件，没有源码、README、calibration 修改、prompt 修改或外部 runtime 文件。

第二份正式证据提交必须严格使用：

```powershell
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_k1_validation_trials.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_k1_validation_summary.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_k1_paired_sensitivity.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_validation_provenance.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_keypoints.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_report.md
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_validation_evidence_manifest.csv
git add beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/results/stage8_1_runtime_diagnostics.csv
git diff --cached --name-only
git diff --cached --stat
git commit -m "docs(stage8.1): validate k1 false-split control"
```

第二份提交完成后，重新确认 MATLAB/locks/coordinator 均为零、工作树干净并按授权推送。然后停止在 Stage8.2 之前。无论 `validation_gate_pass` 为 true 还是 false，都必须提交真实结果并报告；FAIL 不能通过修改阈值或重跑同一 validation 变成 PASS。

## 5. 失败、中断和恢复语义

### 5.1 Phase A

- 300-cell collector、contract、identity、manifest 或 aggregate 任一检查失败：停止，不写/不覆盖证据；报告精确错误、当前目录文件、MATLAB/lock 状态。
- writer 前失败且 `calibration/` 仍只有 `.gitkeep`：不得自行改变 checkpoint；只有修复外部环境或得到新授权后才能重试。
- writer 已经创建一个或多个 CSV：视为生命周期污染；不要删除、覆盖或“补齐”文件。保留现场，报告实际清单和 Git 状态。

### 5.2 Phase B

- wrapper 在第一条 trial 前或运行中失败，而 `results/` 仍只有 `.gitkeep`：关闭残留 MATLAB，确认 calibration 字节未变，再从同一干净 threshold commit 重新运行完整 wrapper；不复用半截内存变量。
- finalizer 写入途中中断导致 `results/` 半满：正式模式会因 `require_empty_lifecycle` 拒绝重跑。此时绝不清目录，停止并等待人工审计/单独恢复决定。
- 任一 calibration snapshot、threshold hash、plan hash、stable identity 或 committed preflight 不匹配：停止；不要重新校准，不要把未跟踪文件当作 committed evidence。

### 5.3 所有阶段

任何停止都要记录：`last_completed_cell`/`next_cell` 仅适用于此前的 calibration runtime；本次 threshold freeze 和 K1 validation 不启动新的 calibration cell。记录 MATLAB PID、active lock 数、coordinator 状态、lifecycle 文件清单、Git HEAD、`git status --short`、最后一条 terminal/error 记录和内存/运行时信息。不要把“进程仍在跑”误报为完成。

## 6. 最终报告格式和论文措辞

Phase A 报告至少包含：两个 `q_global` 的 artifact hash（可报告值但不要手工改 CSV）、300/59700 cardinality、bundle/threshold/checkpoint manifest hash、代码/plan/registry identity、第一份 commit hash、push 状态。

Phase B 报告至少包含：12000/6000/14 cardinality、`COMMITTED_THRESHOLD_PREFLIGHT_PASS`、PRIMARY gate 的每一项 Wilson upper 和最终 gate status、FULL_PARENT sensitivity-only 标记、validation artifact hashes、第二份 commit hash、push 状态、Stage8.2 未执行证明。

严禁把 calibration PASS 写成 K1 control PASS；严禁把 validation gate PASS 写成“证明真实 false-split ≤ 0.05”；正确措辞只能是“通过/未通过预注册有限样本 Wilson 验收门（overall 0.07、stratum 0.08 等）”。

**终点**：第二份 `docs(stage8.1): validate k1 false-split control` 提交之后停止。Stage8.2 必须另行单独授权，不能由本提示词、validation PASS 或 FULL_PARENT sensitivity 自动触发。

## 7. 执行时必须对照的仓库文件

以下文件是本提示词所引用合同的来源；执行 AI 应先阅读当前 checkout 中的版本，不能只相信本提示词复制出的摘要：

- `innovation-mining/22_stage8_1b_r2_calibration_execution_audit.md`
- `innovation-mining/22_stage8_1b_r2_calibration_execution_summary.csv`
- `innovation-mining/22_stage8_1b_r2_runtime_evidence_manifest.csv`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/README.md`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/common/build_stage8_code_identity.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/common/build_stage8_validation_plan.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/aggregate_stage8_1_calibration.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/run_stage8_1_freeze_threshold_evidence.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/stage8_1_calibration_artifact_registry.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/load_stage8_1_locked_thresholds.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/run_stage8_1_k1_validation_from_frozen_thresholds.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/validate_stage8_1_validation_output.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/run_stage8_1_finalize.m`
- `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_6_k12_bootstrap_resolution/stage8_1_validation_artifact_registry.m`
