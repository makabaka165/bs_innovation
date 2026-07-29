# Stage8-Core-V2.2：归档 F0 Launcher 自计数失败现场并重启最终冻结（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 与 Git 的执行 AI。
>
> 本协议不是新算法阶段，也不允许继续修改 solver、production fit、registry、
> seed 或判定门。它只授权：
>
> 1. 原样归档 `879e069` 之前一次 F0 launcher-self-count 失败所占用的 corrected runtime；
> 2. 从规范 runtime 路径重新执行已经提交并推送的 corrected protocol；
> 3. 依次完成 F0、F1A、F1B、原注册 144-trial、Finalize；
> 4. 提交真实 `29_*` 最终证据并永久停止 Stage8 算法扩展。
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
> STAGE8_CORE_V2_2_ARCHIVE_FAILED_F0_AND_RESTART_FINAL_FREEZE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_2_ARCHIVE_FAILED_F0_AND_RESTART_FINAL_FREEZE_V1
> ```

---

## 0. 当前状态与问题性质

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

当前探索分支：

```text
experiment/stage8-core-v2
```

预期当前 HEAD：

```text
879e06972128f4d0a721c3f4e894f3abfb7d802c
```

稳定 main：

```text
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

当前状态：

```text
previous corrected START:
F0_FAIL_STOPPED

root cause:
Windows MATLAB R2022b 启动 launcher + engine；
旧 F0 把同一会话的 launcher 当作外部 MATLAB。

fix:
879e069 已将当前 MATLAB engine 及其全部祖先进程
从 external MATLAB 计数中排除。

formal F1A:
NOT_EXECUTED

formal F1B:
NOT_EXECUTED

independent 144-trial:
0/144

checkpoint:
0

protocol:
ABSENT

29_* evidence:
ABSENT
```

该问题属于：

```text
PROCESS-AUDIT ORCHESTRATION BUG
```

不属于：

```text
DML 公式错误
生产算法错误
F1 canonical oracle 错误
registry 错误
seed 错误
科学结果失败
```

---

## 1. Git 与现场 Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git switch experiment/stage8-core-v2
git reset --hard origin/experiment/stage8-core-v2

$head = (git rev-parse HEAD).Trim()
$remoteHead = (git rev-parse origin/experiment/stage8-core-v2).Trim()
$main = (git rev-parse origin/main).Trim()
$status = @(git status --porcelain=v1 --untracked-files=all)
```

要求：

```text
$head == $remoteHead
$head == 879e06972128f4d0a721c3f4e894f3abfb7d802c
$main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
$status.Count == 0
```

若探索分支由用户明确推进为 `879e069` 的后代：

1. 记录实际 starting HEAD；
2. 只允许额外提交为 docs-only，且位于
   `innovation-mining/stage8_execution_prompts/`；
3. 不允许存在新的 `.m`、CSV 或 evidence 修改；
4. 不得自动 reset 掉未知提交；
5. 不满足则硬停止。

确认没有活动进程：

```powershell
$active = @(
  Get-CimInstance Win32_Process |
  Where-Object {
    $_.Name -match '^(MATLAB|mwpython).*' -or
    (
      $_.CommandLine -match 'stage8.*coordinator|coordinator.*stage8' -and
      $_.CommandLine -notmatch 'Get-CimInstance Win32_Process'
    )
  }
)

$active |
  Select-Object ProcessId, ParentProcessId, Name, CommandLine |
  Format-List
```

必须为：

```text
MATLAB = 0
mwpython = 0
Stage8 coordinator = 0
```

不得为了满足该门而终止未知 MATLAB。若存在进程，停止并报告。

---

## 2. 科学边界审计

关键提交：

```text
production interface:
5f042b75ba6733ffdd531229f81cec7660418ca1

invalid V2.2 evidence:
4d37901fb24b6ac22ec126c4a275cfe4359d4c7f

canonical-oracle / summary / finalizer correction:
5ca46cc（完整 SHA 由 git log 解析）

F0 launcher self-count correction:
879e06972128f4d0a721c3f4e894f3abfb7d802c
```

执行：

```powershell
git diff --exit-code `
  5f042b75ba6733ffdd531229f81cec7660418ca1..HEAD -- `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/common

git diff --exit-code `
  5f042b75ba6733ffdd531229f81cec7660418ca1..HEAD -- `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/build_stage8_core_v2_2_final_registry.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/generate_stage8_core_v2_2_trial.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/build_stage8_core_v2_2_validation_context.m
```

两项必须无差异。

再检查：

```powershell
git diff --exit-code `
  4d37901fb24b6ac22ec126c4a275cfe4359d4c7f..HEAD -- `
  innovation-mining/15_stage6_tangent_theory_validation_audit.md `
  innovation-mining/16_stage7_exact_subset_fim_audit.md `
  innovation-mining/23_stage8_compact_algorithm_diagnostic.md `
  innovation-mining/24_stage8_r1_continuous_refinement_decisive_experiment.md `
  innovation-mining/26_stage8_core_v2_known_k_pruning_experiment.md `
  innovation-mining/27_stage8_core_v2_1_safe_hybrid_closure.md `
  innovation-mining/28_stage8_core_v2_2_final_single_cpi_known_k_validation.md
```

必须无差异。

确认以下文件不存在：

```text
innovation-mining/
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_validation.md
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_trials.csv
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_summary.csv
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_q_analysis.csv
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_complexity.csv
```

任何一项存在：硬停止，不覆盖。

---

## 3. 记录并原样归档失败 corrected runtime

失败 runtime 的规范路径：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1
```

设：

```powershell
$runtime = 'E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1'
```

### 3.1 严格检查允许的现场

要求根目录存在。

允许的内容仅为：

```text
f0_audit.mat
checkpoints\      # 空
tmp\              # 空
```

不允许存在：

```text
protocol.mat
registry.csv
f1a_oracle_audit.mat
f1b_production_regression_audit.mat
pause.request
finalized.mat
任何 checkpoint
任何 tmp 文件
任何 lock
```

执行：

```powershell
if (-not (Test-Path -LiteralPath $runtime -PathType Container)) {
    throw 'Expected failed corrected runtime is absent.'
}

$rootFiles = @(
  Get-ChildItem -LiteralPath $runtime -File -Force
)

$rootDirs = @(
  Get-ChildItem -LiteralPath $runtime -Directory -Force
)

$checkpoints = @(
  Get-ChildItem -LiteralPath (Join-Path $runtime 'checkpoints') `
    -File -Force -ErrorAction SilentlyContinue
)

$tmpFiles = @(
  Get-ChildItem -LiteralPath (Join-Path $runtime 'tmp') `
    -File -Force -ErrorAction SilentlyContinue
)

if (
  $rootFiles.Count -ne 1 -or
  $rootFiles[0].Name -ne 'f0_audit.mat' -or
  $checkpoints.Count -ne 0 -or
  $tmpFiles.Count -ne 0 -or
  (Test-Path (Join-Path $runtime 'protocol.mat')) -or
  (Test-Path (Join-Path $runtime 'registry.csv')) -or
  (Test-Path (Join-Path $runtime 'f1a_oracle_audit.mat')) -or
  (Test-Path (Join-Path $runtime 'f1b_production_regression_audit.mat')) -or
  (Test-Path (Join-Path $runtime 'pause.request')) -or
  (Test-Path (Join-Path $runtime 'finalized.mat'))
) {
    throw 'Failed corrected runtime inventory differs from the authorized F0-only现场.'
}
```

若 `checkpoints/` 或 `tmp/` 目录不存在，也停止；不要猜测或补建旧现场。

### 3.2 读取 F0 audit

用一个短暂 R2022b `-singleCompThread` 非计算会话，只读取：

```text
f0_audit.mat
```

要求：

```text
变量 f0 存在
f0.pass = false
f0.status = F0_FAIL_STOPPED
f0.matlab_external_count > 0
protocol/checkpoint = 0
```

该读取不得调用生产拟合或 registry。

### 3.3 记录完整字节身份

执行：

```powershell
$f0Path = Join-Path $runtime 'f0_audit.mat'
$f0HashBefore = (Get-FileHash $f0Path -Algorithm SHA256).Hash.ToLower()
$f0BytesBefore = (Get-Item $f0Path).Length

$inventoryBefore = @(
  Get-ChildItem -LiteralPath $runtime -Recurse -Force |
  Sort-Object FullName |
  ForEach-Object {
    [pscustomobject]@{
      relative_path = $_.FullName.Substring($runtime.Length).TrimStart('\')
      is_directory = $_.PSIsContainer
      length = if ($_.PSIsContainer) { 0 } else { $_.Length }
      sha256 = if ($_.PSIsContainer) {
        ''
      } else {
        (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
      }
    }
  }
)
```

### 3.4 原样移动到独立 archive

创建：

```powershell
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$archiveRoot = "E:\bs_innovation_runtime\stage8_core_v2_2_f0_launcher_selfcount_failure_879e069_$stamp"

New-Item -ItemType Directory -Path $archiveRoot | Out-Null

$archivedRuntime = Join-Path $archiveRoot 'original_runtime'

Move-Item -LiteralPath $runtime -Destination $archivedRuntime
```

禁止：

```text
Copy + delete
删除 f0_audit
修改 f0_audit
在 original_runtime 内增加 manifest
```

在 `$archiveRoot`，而不是 `original_runtime` 内，写：

```text
archive_manifest.json
```

至少包含：

```json
{
  "status": "ARCHIVED_F0_LAUNCHER_SELFCOUNT_FAILURE",
  "source_head": "879e06972128f4d0a721c3f4e894f3abfb7d802c",
  "reason": "CURRENT_MATLAB_LAUNCHER_WAS_COUNTED_AS_EXTERNAL_MATLAB",
  "formal_f1a_executed": false,
  "formal_f1b_executed": false,
  "formal_trial_count": 0,
  "checkpoint_count": 0,
  "protocol_present": false,
  "runtime_preserved_byte_for_byte": true
}
```

### 3.5 移动后验证

要求：

```text
原规范 runtime 路径不存在
archive/original_runtime 存在
f0 SHA-256 不变
f0 byte count 不变
完整 inventory 与移动前一致
```

执行：

```powershell
if (Test-Path -LiteralPath $runtime) {
    throw 'Canonical runtime still exists after archive move.'
}

$f0Archived = Join-Path $archivedRuntime 'f0_audit.mat'
$f0HashAfter = (Get-FileHash $f0Archived -Algorithm SHA256).Hash.ToLower()
$f0BytesAfter = (Get-Item $f0Archived).Length

if ($f0HashAfter -ne $f0HashBefore -or $f0BytesAfter -ne $f0BytesBefore) {
    throw 'Archived F0 audit byte identity changed.'
}
```

比较完整 inventory；任何差异均停止。

---

## 4. 新增并提交本次 restart 授权文档

新增：

```text
innovation-mining/stage8_execution_prompts/active/
009_stage8_core_v2_2_archive_f0_and_restart_final_freeze_v1.md
```

内容为本提示词全文。

更新：

```text
innovation-mining/stage8_execution_prompts/active/README.md
```

状态：

```text
STAGE8_CORE_V2_2_FINAL_RESTART_AUTHORIZED
NO_ALGORITHM_CHANGE
F0_LAUNCHER_SELFCOUNT_FIX_COMMITTED
FAILED_RUNTIME_ARCHIVED
```

只提交这两个 Markdown：

```powershell
git add -- `
  innovation-mining/stage8_execution_prompts/active/009_stage8_core_v2_2_archive_f0_and_restart_final_freeze_v1.md `
  innovation-mining/stage8_execution_prompts/active/README.md

git diff --cached --check
git diff --cached --name-only
git commit -m "docs(stage8-core): authorize corrected final-freeze restart"
git push origin experiment/stage8-core-v2
```

推送后要求：

```text
HEAD == origin/experiment/stage8-core-v2
origin/main 仍为 247fad...
工作树 clean
```

记录该 commit 为正式 Start HEAD。

再次确认：

```powershell
git diff --exit-code 879e06972128f4d0a721c3f4e894f3abfb7d802c..HEAD -- `
  beamspace_ml_v18
```

必须无差异。

---

## 5. 正式 START

### 5.1 新日志目录

日志不得写入规范 runtime，以免在 runner 创建 runtime 前使其非空。

创建独立日志目录：

```powershell
$runStamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$logRoot = "E:\bs_innovation_runtime\stage8_core_v2_2_final_restart_logs_$runStamp"

New-Item -ItemType Directory -Path $logRoot | Out-Null
```

### 5.2 启动命令

```powershell
$repo = 'E:\bs_innovation'
$step = 'E:\bs_innovation\beamspace_ml_v18\source\stepwise_signal_model\steps\step_12_7_known_k_local_cell_refinement'
$runtime = 'E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1'
$matlab = 'E:\MATLABR2022b\bin\matlab.exe'

$expression = @"
addpath('$step');
out = run_step12_7_known_k_local_cell_refinement( ...
    'Start', '$runtime');
disp(out);
"@

& $matlab `
  -singleCompThread `
  -logfile (Join-Path $logRoot 'start.log') `
  -batch $expression

$startExitCode = $LASTEXITCODE
```

不得同时启动第二个 scientific MATLAB。

`START` 内部必须按顺序执行：

```text
F0
F1A
F1B
144-trial registry
checkpoint execution
```

---

## 6. Gate 处理规则

### 6.1 F0

新 runtime 中必须出现：

```text
f0_audit.mat
```

且：

```text
f0.pass = true
f0.status = F0_BOUNDARY_AND_ENVIRONMENT_PASS
f0.matlab_external_count = 0
f0.coordinator_count = 0
f0.lock_count = 0
```

如果仍然 F0 fail：

```text
停止
保留新 runtime
不再次修复
不再次重试
```

### 6.2 F1A

必须出现：

```text
f1a_oracle_audit.mat
```

且：

```text
F1A_CANONICAL_ORACLE_CONTRACT_PASS
canonical K1 = H1_DIRECT_SAFE_HYBRID_KNOWN_K
historical H2 K1 difference 被记录但不作为失败
```

失败则停止，不继续修改 oracle。

### 6.3 F1B

必须出现：

```text
f1b_production_regression_audit.mat
```

且：

```text
F1B_PRODUCTION_24_TRIAL_REGRESSION_PASS

24/24 element hashes
16/16 K1 CORE_LITE == CORE_PLUS
16/16 K1 matched canonical historical H1
8/8 K2 CORE_LITE matched historical B0
8/8 K2 CORE_PLUS matched historical H2
truth leakage = 0
tracking input = 0
cross-CPI input = 0
```

若 F1B 精确失败：

```text
这才视为 production promotion mismatch
停止
不改容差
不改 solver
不改历史 CSV
不运行 144-trial
```

### 6.4 Protocol

只有 F1B PASS 后才允许存在：

```text
protocol.mat
registry.csv
```

protocol version 必须为：

```text
STAGE8_CORE_V2_2_SINGLE_CPI_KNOWN_K_FINAL_FREEZE_F1_ORACLE_CORRECTION_V1
```

registry 必须：

```text
144 trials
72 K1
72 K2
288 result rows
```

---

## 7. 144-trial 执行与恢复

### 7.1 不变合同

不得修改：

```text
registry
center
separation
direction
SNR
L
noise profile
power ratio
correlation
source seed
noise seed
single-CPI flags
same range-Doppler cell flags
```

一个 MATLAB、一个线程：

```text
MATLAB R2022b
-singleCompThread
worker count = 1
no parpool
no parfor
```

### 7.2 Checkpoint

每 trial 写一个：

```text
checkpoints\<trial_id>.mat
```

要求：

```text
144/144 unique
72 K1
72 K2
tmp = 0 at completion
```

不得手工创建、复制或编辑 checkpoint。

### 7.3 状态

只在必要时调用一次 `Status`，不持续轮询：

```powershell
$statusExpression = @"
addpath('$step');
out = run_step12_7_known_k_local_cell_refinement( ...
    'Status', '$runtime');
disp(out);
"@

& $matlab -singleCompThread -batch $statusExpression
```

### 7.4 安全暂停

只有用户明确需要关机时才请求 Pause。

允许使用一个短暂控制 MATLAB 会话写 pause request；它不执行 scientific fit：

```powershell
$pauseExpression = @"
addpath('$step');
out = run_step12_7_known_k_local_cell_refinement( ...
    'Pause', '$runtime');
disp(out);
"@

& $matlab -singleCompThread -batch $pauseExpression
```

主执行会话必须在当前 trial 完成并写完 checkpoint 后退出。

确认：

```text
主 MATLAB 已退出
tmp = 0
checkpoint 均可验证
pause.request 存在
```

才允许关机。

### 7.5 恢复

恢复前：

```text
HEAD 必须等于 protocol.git_head
工作树 clean
不存在其他 MATLAB/coordinator
```

执行：

```powershell
$resumeExpression = @"
addpath('$step');
out = run_step12_7_known_k_local_cell_refinement( ...
    'Resume', '$runtime');
disp(out);
"@

& $matlab `
  -singleCompThread `
  -logfile (Join-Path $logRoot 'resume.log') `
  -batch $resumeExpression
```

若非安全中断留下 tmp：

```text
停止
不得删除 tmp 后自行恢复
```

---

## 8. 完整性检查

START/Resume 返回后调用 Status，要求：

```text
f0_status =
F0_BOUNDARY_AND_ENVIRONMENT_PASS

f1a_status =
F1A_CANONICAL_ORACLE_CONTRACT_PASS

f1b_status =
F1B_PRODUCTION_24_TRIAL_REGRESSION_PASS

completed_trial_count = 144
remaining_trial_count = 0
tmp_checkpoint_count = 0
lock_count = 0
pause_requested = false
finalized = false
```

若 completed < 144 且无 pause：

```text
停止并报告
不得把部分结果 finalize
```

---

## 9. FINALIZE

执行：

```powershell
$finalizeExpression = @"
addpath('$step');
out = run_step12_7_known_k_local_cell_refinement( ...
    'Finalize', '$runtime');
disp(out);
"@

& $matlab `
  -singleCompThread `
  -logfile (Join-Path $logRoot 'finalize.log') `
  -batch $finalizeExpression

if ($LASTEXITCODE -ne 0) {
    throw 'Finalize failed.'
}
```

Finalize 必须：

```text
验证 144 checkpoints
验证 F0/F1A/F1B
验证 registry identity
验证 K1 mode identity
写 29_* 文件
写 finalized.mat
拒绝覆盖旧 28_* 或已有 29_*
```

---

## 10. 最终结果审计

要求以下 5 个文件存在：

```text
innovation-mining/
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_validation.md

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_trials.csv

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_summary.csv

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_q_analysis.csv

29_stage8_core_v2_2_corrected_final_single_cpi_known_k_complexity.csv
```

要求：

```text
trials rows = 288
summary rows = 1
q analysis rows = 4
complexity rows = 2
```

报告必须包含：

```text
old invalid report = 28_*
production scientific code changed = false
registry/seeds changed = false
decision rules changed = false
F0 PASS
F1A PASS
F1B PASS
144/144 completeness
```

最终状态只允许：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL

STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_LITE_ONLY

STAGE8_CORE_V2_2_FINAL_KNOWN_K_CORE_NOT_CONFIRMED

STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

不得因结果不理想而重跑不同 seed、删除 profile 或调门。

---

## 11. 文档收束

根据真实 final state 更新：

```text
innovation-mining/
11_sequential_beamspace_ml_innovations_theory.md

00_DOCUMENT_STATUS_INDEX.md

stage8_execution_prompts/active/README.md
```

规则：

### 若 Core-Plus Optional PASS

写入：

```text
independent 144-trial known-K validation complete
Core-Lite final pass
Core-Plus optional confirmed
```

### 若 Core-Lite Only PASS

写入：

```text
Core-Lite final pass
Core-Plus not retained in final interface
```

### 若 Known-K Core Not Confirmed

诚实写入负结果：

```text
V2.1 development evidence preserved
independent final validation did not confirm final core
```

不得删除旧正/负证据。

将：

```text
innovation-mining/stage8_execution_prompts/active/
008_stage8_core_v2_2_f1_canonical_oracle_correction_v1.md

009_stage8_core_v2_2_archive_f0_and_restart_final_freeze_v1.md
```

移动到：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

最终 active README：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_CORE_V2_2_CORRECTED_FINAL_FREEZE_COMPLETED
```

---

## 12. Evidence 提交

只允许暂存：

```text
innovation-mining/29_stage8_core_v2_2_corrected_final_single_cpi_known_k_*

innovation-mining/11_sequential_beamspace_ml_innovations_theory.md

innovation-mining/00_DOCUMENT_STATUS_INDEX.md

innovation-mining/stage8_execution_prompts/active/README.md

innovation-mining/stage8_execution_prompts/archive/completed/
008_stage8_core_v2_2_f1_canonical_oracle_correction_v1.md

innovation-mining/stage8_execution_prompts/archive/completed/
009_stage8_core_v2_2_archive_f0_and_restart_final_freeze_v1.md
```

提交前：

```powershell
git status --short
git diff --check
git diff --name-only -- '*.m'
```

最终 evidence 提交中 `.m` diff 必须为空。

提交：

```powershell
git add -- innovation-mining

git commit -m `
  "docs(stage8-core): record corrected final single-CPI known-k freeze"

git push origin experiment/stage8-core-v2
```

推送后：

```text
HEAD == origin/experiment/stage8-core-v2
origin/main == 247fad...
Git clean
```

---

## 13. 完成后永久停止

不得继续：

```text
Core-V3
第三版 K2 solver
automatic K
q_global
parametric bootstrap
separation bootstrap
resolved/unresolved
adaptive W/B
K=3
6000-trial
Stage8.2
```

后续只允许：

```text
论文正文与图表
公式—代码映射
baseline 与参考文献讨论
单独审查是否把最终 Step12.7 集成 main
```

---

## 14. 最终报告格式

```text
STAGE8_CORE_V2_2_FINAL_RESTART_PASS / FAIL

Branch:
Starting HEAD:
Restart authorization commit:
Evidence commit:
Push:
Git clean:
origin/main unchanged:

Archived failed F0 runtime:
- archive root
- original f0 SHA-256
- archived f0 SHA-256
- byte identity
- protocol/checkpoint/tmp counts

Scientific production code changed:
Registry changed:
Seeds changed:
Decision rules changed:

F0:
- status
- external MATLAB count
- coordinator count
- lock count

F1A:
- canonical K1 oracle
- noncanonical H2 K1 difference count

F1B:
- element hashes
- K1 mode identity
- K1 H1 canonical match
- K2 CORE_LITE B0 match
- K2 CORE_PLUS H2 match

Independent validation:
- K1 72/72
- K2 72/72
- rows 288/288
- checkpoints 144
- tmp 0

CORE_LITE:
- valid count
- K1 overall median/p90
- K1 off-grid median/p90
- wins/ties/losses
- score/SVD/runtime

CORE_PLUS:
- valid count
- K2 overall median/p90
- profile medians
- wins/ties/losses
- upgrades/fallbacks
- q quartile analysis
- score/SVD/runtime

Final state:
Model-order:
Formal 6000-trial:
Stage8.2:
MATLAB / mwpython / coordinator / lock:
```
