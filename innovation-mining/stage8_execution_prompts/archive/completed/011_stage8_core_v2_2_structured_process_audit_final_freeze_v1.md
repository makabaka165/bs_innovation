# Stage8-Core-V2.2：结构化进程清单修复 F0 自指匹配并完成最终冻结（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 与 Git 的执行 AI。
>
> 本协议不是 Core-V3，不修改 DML、solver、safe selection、registry、seed 或最终
> 科学判定。它只替换 F0 中容易自匹配的命令行关键词扫描，使用一次结构化
> Windows 进程快照和明确进程身份完成并发审计；通过只读 Preflight 后，继续既定
> F1A、F1B、144-trial 和 Finalize。
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
> STAGE8_CORE_V2_2_STRUCTURED_PROCESS_AUDIT_AND_FINAL_FREEZE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_2_STRUCTURED_PROCESS_AUDIT_AND_FINAL_FREEZE_V1
> ```

---

## 0. 当前状态和根因

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
563b94ec02948ba0d638b26a106b34d7cb79d279
fix(stage8-core): count real tmp entries before final preflight
```

稳定 main：

```text
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

当前已确认：

```text
真实目录项 inventory：PASS
Preflight 不占用规范 runtime：PASS
旧 V1 runtime 的 tmp files/directories：0/0
MATLAB launcher self-count 修复：有效
最近一次 Preflight：
  external_matlab_count = 0
  lock_count = 0
  coordinator_count = 2
规范 runtime：不存在
F1A/F1B：未执行
144-trial：0/144
29_*：不存在
```

现行 coordinator 审计使用：

```powershell
Get-CimInstance Win32_Process |
Where-Object {
  $_.CommandLine -match 'stage8.*coordinator|coordinator.*stage8'
}
```

而执行该查询时，MATLAB `system()` 会生成至少一层：

```text
cmd.exe
powershell.exe
```

它们的命令行包含查询表达式本身：

```text
stage8.*coordinator|coordinator.*stage8
```

当前实现只排除查询 PowerShell 的 `$PID` 和 MATLAB engine PID，没有排除包装
`cmd.exe`、外层启动命令或整个当前查询进程树。字符串形式的
`-notmatch 'Get-CimInstance Win32_Process'` 又依赖命令行的具体引用、转义与截断
方式，不能作为稳定身份排除。因此查询机制会制造满足自身谓词的进程，产生两个
假阳性。

该问题定义为：

```text
F0_SELF_REFERENTIAL_COMMANDLINE_PROCESS_MATCH_BUG
```

不属于：

```text
MATLAB 安装异常
缺失文件
DML 公式错误
生产 fit 错误
F1 canonical oracle 错误
registry/seed 错误
科学验证失败
```

---

## 1. 本次唯一目标

一次性完成：

```text
1. 保存最近一次 read-only Preflight 失败日志/审计，不占用或归档不存在的规范 runtime；
2. 删除通用 “stage8.*coordinator” 命令行扫描；
3. 通过不含任何匹配关键词的一次 PowerShell 进程快照获取结构化 PID/PPID/Name/CommandLine；
4. 在 MATLAB 中按 PID、父子关系和明确进程身份分类；
5. 区分：
   - 当前 MATLAB engine/launcher 进程族；
   - 外部 MATLAB；
   - mwpython；
   - 明确的旧 Stage8 orchestration 脚本；
6. 运行合成进程表单元测试和真实只读 Preflight；
7. Preflight PASS 后直接执行既定 F1A、F1B 和原注册 144-trial；
8. Finalize 写入 29_* 并永久停止算法扩展。
```

不得继续通过新增 `-notmatch` 字符串补丁修复。

---

## 2. Git 和现场 Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git switch experiment/stage8-core-v2
git reset --hard origin/experiment/stage8-core-v2

$head = (git rev-parse HEAD).Trim()
$remote = (git rev-parse origin/experiment/stage8-core-v2).Trim()
$main = (git rev-parse origin/main).Trim()
$status = @(git status --porcelain=v1 --untracked-files=all)
```

要求：

```text
$head == $remote
$head == 563b94ec02948ba0d638b26a106b34d7cb79d279
$main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
$status.Count == 0
```

若探索分支已经由用户明确推进为 `563b94` 的后代：

1. 记录实际起点；
2. 只允许额外提交为本协议明确允许的 docs/F0 修复；
3. 发现 production common/、registry、generator、F1、evidence 或 solver 的未知修改时停止；
4. 不得自动 reset 丢弃未知提交。

在启动 MATLAB 前，用 PowerShell 外部检查：

```powershell
$active = @(
  Get-CimInstance Win32_Process |
  Where-Object {
    $_.Name -match '^(MATLAB|mwpython)(\.exe)?$'
  }
)

$active |
  Select-Object ProcessId, ParentProcessId, Name, CommandLine |
  Format-List
```

必须为 0。

不得为了过门而终止未知进程。

---

## 3. 保留最近一次 Preflight 失败证据

最近一次 Preflight 是只读动作，规范 runtime 在前后均不存在。因此：

```text
不得创建一个虚构的 runtime archive；
不得把日志复制进规范 runtime；
不得删除既有 preflight log。
```

保留：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_final_preflight_logs_20260729T135556Z\
preflight.log
```

若存在对应的：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_preflight_failures\
*_f0_audit.mat
```

则：

1. 只读记录最新一份 audit 路径；
2. 记录 SHA-256 和 byte count；
3. 读取并确认：
   ```text
   f0.pass = false
   f0.status = F0_FAIL_STOPPED
   external_matlab_count = 0
   coordinator_count = 2
   lock_count = 0
   old_runtime_audit.tmp_file_count = 0
   old_runtime_audit.tmp_directory_count = 0
   ```
4. 不移动、不修改、不覆盖该 audit。

若不存在 audit，只保留日志路径；这不是阻塞项。

规范 runtime：

```text
E:\bs_innovation_runtime\
stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1
```

在本协议代码提交和 Preflight 前必须不存在。

---

## 4. 科学冻结边界

以下全部不得修改：

```text
step_12_7_known_k_local_cell_refinement/common/**

validation/build_stage8_core_v2_2_final_registry.m
validation/generate_stage8_core_v2_2_trial.m
validation/build_stage8_core_v2_2_validation_context.m
validation/summarize_stage8_core_v2_2_final_validation.m
validation/finalize_stage8_core_v2_2_final_validation.m

tests/test_f1_canonical_oracle_contract.m
tests/test_historical_24_trial_regression.m
tests/parse_historical_angle_matrix.m
tests/test_summary_fixed_grid_rmse_contract.m

tools/stage8_r1_continuous_decisive/**
tools/stage8_core_v2_known_k/**

Step12.0–Step12.6
calibration/**
results/**
figures/**

innovation-mining/15_*
innovation-mining/16_*
innovation-mining/23_*
innovation-mining/24_*
innovation-mining/26_*
innovation-mining/27_*
innovation-mining/28_*
```

不得改变：

```text
144-trial registry
K1/K2 profiles
source/noise seeds
solver tolerance
candidate starts
safe-selection rule
decision rule
F1A/F1B oracle
```

---

## 5. 允许修改和新增的文件

只允许修改：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/validation/
run_stage8_core_v2_2_final_validation.m
```

允许新增：

```text
validation/stage8_core_v2_2_process_snapshot.m

validation/stage8_core_v2_2_classify_process_snapshot.m

tests/test_f0_process_classifier_contract.m

tests/test_f0_process_snapshot_no_self_match.m

tests/test_f0_structured_process_preflight_contract.m
```

若一个 helper 足以完成 snapshot + classifier，可合并，但测试必须能对纯合成进程表独立验证 classifier。

不得修改已通过的：

```text
stage8_core_v2_2_directory_inventory.m
test_f0_directory_inventory_contract.m
test_f0_preflight_does_not_claim_runtime.m
```

---

## 6. 一次结构化 Windows 进程快照

新增：

```matlab
snapshot = stage8_core_v2_2_process_snapshot()
```

### 6.1 PowerShell 查询命令

PowerShell 命令只允许获取结构化字段，不得包含以下分类关键词：

```text
stage8
coordinator
Stage8K1Sharded
Stage8CompactDiagnostic
Stage8R1Decisive
Stage8CoreV2
```

建议命令语义：

```powershell
$rows = @(
  Get-CimInstance Win32_Process |
  Select-Object ProcessId, ParentProcessId, Name, ExecutablePath, CommandLine
)

$rows | ConvertTo-Json -Compress -Depth 3
```

MATLAB 中通过：

```matlab
jsondecode
```

解析。

### 6.2 输出合同

`snapshot` 必须为结构化 table 或 struct array，至少含：

```text
process_id
parent_process_id
name
executable_path
command_line
```

规则：

```text
PID/PPID 转 double
Name/Path/CommandLine 转 string
null CommandLine 转空字符串
按 PID 升序
PID 唯一
```

查询失败、JSON 无法解析或 PID 重复时 error，不返回猜测值。

### 6.3 不允许的实现

不得：

```text
在 PowerShell Where-Object 中搜索 stage8/coordinator；
依赖命令行字符串排除查询进程；
仅返回一个 count；
通过 tasklist 文本列宽解析 PID；
把未知查询错误当成 0。
```

---

## 7. 纯 MATLAB 进程分类器

新增：

```matlab
audit = stage8_core_v2_2_classify_process_snapshot( ...
    snapshot, current_matlab_pid)
```

### 7.1 当前 MATLAB 进程族

从 `current_matlab_pid` 开始沿 `parent_process_id` 向上构造：

```text
current_lineage_ids
```

包括：

```text
当前 MATLAB engine
MATLAB launcher
启动该 MATLAB 的 cmd/PowerShell 祖先
```

防止 parent cycle；最多遍历进程数次。

可额外构造当前 MATLAB 的后代集合用于诊断，但不得依赖它解决 coordinator 假阳性。

### 7.2 外部 MATLAB

仅将进程名精确归一化后属于：

```text
matlab.exe
matlab
```

且 PID 不在 `current_lineage_ids` 中的进程记为外部 MATLAB。

不要把：

```text
MathWorksServiceHost
MATLABWebUI
crash reporter
```

仅因名称前缀匹配而记为 MATLAB engine。

输出：

```text
external_matlab_count
external_matlab_matches
```

其中 match 至少含：

```text
PID
PPID
Name
ExecutablePath
CommandLine
```

### 7.3 mwpython

进程名精确为：

```text
mwpython.exe
mwpython
```

且不属于当前 lineage，计为：

```text
mwpython_count
mwpython_matches
```

### 7.4 明确的旧 Stage8 orchestration

本最终协议本身不使用 coordinator。只识别已经存在过的明确控制脚本 basename：

```text
Stage8K1Sharded.ps1
Stage8CompactDiagnostic.ps1
Stage8R1Decisive.ps1
Stage8CoreV2.ps1
```

匹配规则：

```text
process name ∈ {
  powershell.exe,
  powershell,
  pwsh.exe,
  pwsh,
  cmd.exe,
  cmd
}

且 normalized command line
包含上述任一 exact basename（case-insensitive）
```

只匹配 basename，不使用：

```text
stage8.*coordinator
coordinator.*stage8
contains("coordinator")
contains("stage8")
```

输出：

```text
legacy_orchestrator_count
legacy_orchestrator_matches
```

为兼容现有 F0 报告，可设置：

```matlab
coordinator_count = legacy_orchestrator_count
```

但字段说明必须写成：

```text
EXACT_KNOWN_LEGACY_ORCHESTRATOR_COUNT
```

### 7.5 自查询命令不可能匹配

因为 PowerShell snapshot 查询命令本身不包含任何上述 exact basename，查询产生的
`cmd.exe/powershell.exe` 即使出现在 snapshot 中，也不会被识别为 legacy orchestrator。

---

## 8. 修改 F0

删除：

```matlab
external_matlab_count_local()
coordinator_count_local()
```

或使其不再被 F0 调用。

在 `f0_local` 中只调用一次：

```matlab
snapshot = stage8_core_v2_2_process_snapshot();

process_audit = stage8_core_v2_2_classify_process_snapshot( ...
    snapshot, feature('getpid'));
```

F0 保存：

```text
process_snapshot_count
current_lineage_ids
external_matlab_count
external_matlab_matches
mwpython_count
mwpython_matches
legacy_orchestrator_count
legacy_orchestrator_matches
coordinator_count（兼容 alias）
process_audit_method =
STRUCTURED_SNAPSHOT_EXACT_IDENTITY_V1
```

F0 pass 进程条件：

```matlab
external_matlab_count == 0
mwpython_count == 0
legacy_orchestrator_count == 0
```

不得再运行第二次独立 PowerShell 进程查询。

### 8.1 详细失败信息

不要再只写：

```text
Branch, remote, frozen-path, runtime, process, or clean-tree check failed.
```

若 F0 失败，`last_error` 至少列出：

```text
branch_match
head_remote_match
origin_main_match
worktree_clean
anchor_is_ancestor
frozen_paths_clean
old_runtime_audit_pass
new_evidence_absent
lock_count
external_matlab_count + matched PIDs
mwpython_count + matched PIDs
legacy_orchestrator_count + matched PIDs/basenames
```

不得包含模糊的无字段错误。

### 8.2 F0 生命周期保持现状

当前已经正确实现：

```text
Preflight 只读
F0 PASS 后才创建规范 runtime
F0 fail 写入独立 preflight_failures
```

不得退回先创建 runtime 再 F0 的旧顺序。

---

## 9. 单元测试

### 9.1 `test_f0_process_classifier_contract`

使用纯合成 snapshot，不调用 PowerShell。

至少包含：

#### Case A：当前 MATLAB engine + launcher

```text
PID 100 matlab.exe
PPID 90 matlab.exe
PPID 80 powershell.exe
```

current PID = 100。

预期：

```text
external_matlab_count = 0
```

#### Case B：独立 MATLAB

增加：

```text
PID 200 matlab.exe
PPID 50 explorer.exe
```

预期：

```text
external_matlab_count = 1
matched PID = 200
```

#### Case C：mwpython

增加：

```text
PID 300 mwpython.exe
```

预期：

```text
mwpython_count = 1
```

#### Case D：查询命令包含旧通用正则文字

增加两个进程：

```text
cmd.exe
powershell.exe
```

其 command line 可以包含：

```text
stage8.*coordinator|coordinator.*stage8
Get-CimInstance Win32_Process
coordinator_count
```

但不包含四个 exact legacy script basenames。

预期：

```text
legacy_orchestrator_count = 0
```

这是本次根因回归测试。

#### Case E：真实已知旧 runner

增加：

```text
powershell.exe ...\Stage8K1Sharded.ps1 -Action Start
```

预期：

```text
legacy_orchestrator_count = 1
matched PID 正确
```

#### Case F：普通文档或日志命令

command line 包含：

```text
stage8
coordinator
```

但不包含 exact script basename。

预期：

```text
legacy_orchestrator_count = 0
```

### 9.2 `test_f0_process_snapshot_no_self_match`

在一个 R2022b `-singleCompThread` 会话中调用真实 snapshot 和 classifier。

要求：

```text
snapshot 行数 > 0
当前 MATLAB PID 存在
current_lineage_ids 包含当前 PID
查询产生的 cmd/PowerShell 不被识别为 legacy orchestrator
```

若机器确实存在一个外部 MATLAB、mwpython 或 exact legacy script，则允许测试标记：

```text
SKIP_ENVIRONMENT_NOT_ELIGIBLE
```

但必须列出真实匹配，不得伪造 PASS。

### 9.3 `test_f0_structured_process_preflight_contract`

使用一个不存在的候选 runtime 调用：

```text
Preflight
```

要求：

```text
candidate runtime 前后均不存在
process_audit_method 正确
external_matlab_count = 0
mwpython_count = 0
legacy_orchestrator_count = 0
coordinator_count = 0
old tmp files/directories = 0/0
F0 PASS
```

若环境有真实外部进程，停止并列出明确 PID，不修改代码。

---

## 10. 静态边界审计

运行 MATLAB `checkcode`：

```text
run_stage8_core_v2_2_final_validation.m
stage8_core_v2_2_process_snapshot.m
stage8_core_v2_2_classify_process_snapshot.m
三个新 tests
```

要求 0 warnings。

执行：

```powershell
git diff --exit-code `
  5f042b75ba6733ffdd531229f81cec7660418ca1..HEAD -- `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/common

git diff --exit-code `
  5f042b75ba6733ffdd531229f81cec7660418ca1..HEAD -- `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/build_stage8_core_v2_2_final_registry.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/generate_stage8_core_v2_2_trial.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/build_stage8_core_v2_2_validation_context.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/summarize_stage8_core_v2_2_final_validation.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/finalize_stage8_core_v2_2_final_validation.m
```

必须无差异。

确认：

```text
15/16/23/24/26/27/28 evidence 无 diff
29_* 不存在
origin/main 不变
```

---

## 11. 提交顺序

### 11.1 Prompt commit

新增：

```text
innovation-mining/stage8_execution_prompts/active/
011_stage8_core_v2_2_structured_process_audit_final_freeze_v1.md
```

内容为本提示词全文。

更新：

```text
innovation-mining/stage8_execution_prompts/active/README.md
```

状态：

```text
STAGE8_CORE_V2_2_STRUCTURED_PROCESS_AUDIT_AUTHORIZED
NO_ALGORITHM_CHANGE
NO_GENERIC_COORDINATOR_REGEX
```

提交：

```text
docs(stage8-core): define structured F0 process audit
```

只推送：

```powershell
git push origin experiment/stage8-core-v2
```

### 11.2 Code fix commit

只暂存：

```text
validation/run_stage8_core_v2_2_final_validation.m
validation/stage8_core_v2_2_process_snapshot.m
validation/stage8_core_v2_2_classify_process_snapshot.m
tests/test_f0_process_classifier_contract.m
tests/test_f0_process_snapshot_no_self_match.m
tests/test_f0_structured_process_preflight_contract.m
```

提交：

```text
fix(stage8-core): replace self-referential coordinator scan
```

推送后要求：

```text
HEAD == origin/experiment/stage8-core-v2
origin/main == 247fad...
Git clean
```

记录 code-fix commit 为正式 Start HEAD。

---

## 12. 推送后的只读 Preflight

### 12.1 外部进程检查

在启动 MATLAB 前执行一次 PowerShell 外部检查，要求：

```text
MATLAB/mwpython = 0
```

不再用通用 coordinator 关键词阻塞。

### 12.2 调用

日志写到规范 runtime 之外。

运行：

```matlab
out = run_step12_7_known_k_local_cell_refinement( ...
    'Preflight', ...
    'E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1');
disp(out);
```

要求：

```text
out.pass = true
out.status = F0_BOUNDARY_AND_ENVIRONMENT_PASS

process_audit_method =
STRUCTURED_SNAPSHOT_EXACT_IDENTITY_V1

external_matlab_count = 0
mwpython_count = 0
legacy_orchestrator_count = 0
coordinator_count = 0

old_runtime_audit.tmp_file_count = 0
old_runtime_audit.tmp_directory_count = 0

规范 runtime 路径仍不存在
29_* 仍不存在
```

若 Preflight 失败：

- 打印完整 match table；
- 若是实际外部 MATLAB/mwpython/exact legacy runner，停止并报告 PID；
- 若无真实 match 但 count 非零，停止；
- 不继续增加字符串排除规则；
- 不执行 Start。

---

## 13. 正式 START

只有只读 Preflight PASS 后执行。

运行：

```matlab
out = run_step12_7_known_k_local_cell_refinement( ...
    'Start', ...
    'E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1');
disp(out);
```

START 顺序保持：

```text
F0
→ 创建规范 runtime
→ f0_audit
→ F1A
→ F1B
→ unchanged 144-trial registry
→ checkpoints
```

### F1A

必须：

```text
F1A_CANONICAL_ORACLE_CONTRACT_PASS
```

### F1B

必须：

```text
F1B_PRODUCTION_24_TRIAL_REGRESSION_PASS

24/24 element hashes
16/16 K1 mode identity
16/16 K1 canonical historical H1
8/8 K2 CORE_LITE historical B0
8/8 K2 CORE_PLUS historical H2
truth/tracking/cross-CPI/K-estimation counts = 0
```

F1B 失败才属于真实 production promotion mismatch。

不得：

```text
放宽精度
修改 solver
修改 historical CSV
跳过 trial
继续 144-trial
```

---

## 14. 原注册 144-trial 独立验证

F1B PASS 后，不做任何配置修改，执行：

```text
144 element trials
72 K1
72 K2
288 method rows
```

保持：

```text
1 MATLAB R2022b
-singleCompThread
no parpool
no parfor
```

支持既有：

```text
Status
Pause
Resume
Finalize
```

不得修改：

```text
profiles
centers
separations
directions
SNR
L
noise
source powers/correlations
source/noise seeds
scenario flags
decision rules
```

---

## 15. 完整性和 Finalize

完成后 Status：

```text
F0 PASS
F1A PASS
F1B PASS
completed = 144
remaining = 0
tmp = 0
lock = 0
pause = false
```

执行 Finalize，生成：

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
trials = 288 rows
summary = 1 row
q analysis = 4 rows
complexity = 2 rows
checkpoints = 144
tmp = 0
```

最终状态只允许：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_LITE_ONLY
STAGE8_CORE_V2_2_FINAL_KNOWN_K_CORE_NOT_CONFIRMED
STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

不得因性能不理想修改门或 seed。

---

## 16. 文档和 Evidence 提交

根据真实结果更新：

```text
innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/stage8_execution_prompts/active/README.md
```

将 active prompts：

```text
008_stage8_core_v2_2_f1_canonical_oracle_correction_v1.md
009_stage8_core_v2_2_archive_f0_and_restart_final_freeze_v1.md
010_stage8_core_v2_2_f0_real_entry_preflight_final_freeze_v1.md
011_stage8_core_v2_2_structured_process_audit_final_freeze_v1.md
```

移动到：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

active README 最终：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_CORE_V2_2_CORRECTED_FINAL_FREEZE_COMPLETED
```

Evidence 提交中 `.m` diff 必须为空。

提交：

```text
docs(stage8-core): record corrected final single-CPI known-k freeze
```

只推送：

```powershell
git push origin experiment/stage8-core-v2
```

---

## 17. 完成后永久停止

不得继续：

```text
F0 字符串排除补丁
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
论文、图表、公式—代码映射
baseline 和参考文献讨论
单独审查是否将 Step12.7 集成 main
```

---

## 18. 最终报告格式

```text
STAGE8_CORE_V2_2_STRUCTURED_PROCESS_AUDIT_AND_FINAL_FREEZE_PASS / FAIL

Branch:
Starting HEAD:
Prompt commit:
Process-audit fix commit:
Evidence commit:
Push:
Git clean:
origin/main unchanged:

Previous read-only Preflight failure:
- log/audit path
- audit SHA
- external MATLAB = 0
- coordinator false positives = 2
- canonical runtime absent

Scientific production code changed:
Registry changed:
Seeds changed:
Decision rules changed:

Process classifier tests:
- current MATLAB lineage
- external MATLAB
- mwpython
- generic coordinator text does not match
- exact legacy script matches
- ordinary stage8/coordinator text does not match

Structured Preflight:
- process snapshot rows
- current lineage IDs
- external MATLAB matches
- mwpython matches
- legacy orchestrator matches
- canonical runtime absent afterward
- F0 status

F1A:
F1B:

Independent validation:
- K1 72/72
- K2 72/72
- rows 288/288
- checkpoints 144
- tmp 0

CORE_LITE:
- valid
- K1 overall median/p90
- K1 off-grid median/p90
- wins/ties/losses
- score/SVD/runtime

CORE_PLUS:
- valid
- K2 overall median/p90
- profile medians
- wins/ties/losses
- upgrades/fallbacks
- q quartiles
- score/SVD/runtime

Final state:
Model-order:
Formal 6000-trial:
Stage8.2:
MATLAB / mwpython / legacy orchestrator / lock:
```
