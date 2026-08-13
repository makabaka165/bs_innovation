# Stage8-Core-V2.2：F0 真实目录项计数修复、只读 Preflight 与最终冻结执行（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、PowerShell 与 Git 的执行 AI。
>
> 本协议不是新算法、不是放宽科学门，也不是 Core-V3。它只修复当前 F0 的
> 文件系统枚举错误，并避免 F0 失败继续占用规范 scientific runtime。
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
> STAGE8_CORE_V2_2_F0_REAL_ENTRY_COUNT_PREFLIGHT_AND_FINAL_FREEZE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_CORE_V2_2_F0_REAL_ENTRY_COUNT_PREFLIGHT_AND_FINAL_FREEZE_V1
> ```

---

## 0. 当前问题的唯一定位

当前探索分支已完成：

```text
F1 canonical-oracle correction
summary numeric RMSE correction
finalizer correction
MATLAB launcher self-count correction
restart authorization
```

但最近一次正式 restart 仍停在：

```text
F0_FAIL_STOPPED
F1A NOT_EXECUTED
F1B NOT_EXECUTED
independent validation 0/144
checkpoint 0
protocol ABSENT
29_* ABSENT
```

当前 F0 的实际失败项是：

```matlab
audit.tmp_count = numel(dir(fullfile(root, 'tmp', '*')));
```

在 Windows MATLAB R2022b 中，空目录可能返回：

```text
.
..
```

因此：

```text
真实 tmp 文件 = 0
真实 tmp 子目录 = 0
numel(dir(tmp,'*')) = 2
```

当前门又要求：

```matlab
audit.tmp_count == 0
```

从而错误失败。

该问题属于：

```text
F0_FILESYSTEM_ENUMERATION_BUG
```

不属于：

```text
文件缺失
MATLAB 安装损坏
DML 公式错误
生产接口错误
F1 oracle 错误
registry/seed 错误
科学验证失败
```

同时，当前 `START` 的控制顺序为：

```text
prepare_new_runtime_local(runtime_root)
→ F0
```

所以任何 F0 orchestration 错误都会先创建规范 runtime，再写入 `f0_audit.mat`，
使规范路径无法重用。这一生命周期也要在本次做最小修复。

---

## 1. Git 锚点与边界

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

目标分支：

```text
experiment/stage8-core-v2
```

预期当前 HEAD：

```text
af459db19d56b0952b9bad3ff93093eaea30e92a
```

关键祖先：

```text
5f042b75ba6733ffdd531229f81cec7660418ca1
Step12.7 production interface

4d37901fb24b6ac22ec126c4a275cfe4359d4c7f
V2.2 incompatible-oracle evidence

5ca46cc
F1 oracle / summary / finalizer correction

879e06972128f4d0a721c3f4e894f3abfb7d802c
MATLAB launcher self-count correction

af459db19d56b0952b9bad3ff93093eaea30e92a
restart authorization docs
```

稳定 main：

```text
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

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
$head == af459db19d56b0952b9bad3ff93093eaea30e92a
$main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
$status.Count == 0
```

若探索分支已经由用户明确推进为 `af459db` 的后代：

1. 记录实际 starting HEAD；
2. 只允许新增内容是本协议允许的 docs-only 或 F0 修复；
3. 发现其他 `.m`、CSV、evidence 或算法修改时硬停止；
4. 不得自动丢弃未知提交。

禁止：

```text
push main
merge main
创建新分支
force push
修改旧 15/16/23/24/26/27/28 evidence
修改 production fit/solver
修改 registry/generator/seeds
修改 final decision rules
```

---

## 2. 进程与工作现场

确认没有活动计算：

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

必须：

```text
MATLAB = 0
mwpython = 0
Stage8 coordinator = 0
```

不得终止未知进程来满足该条件。

确认仓库中没有 `29_*`：

```text
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_validation.md
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_trials.csv
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_summary.csv
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_q_analysis.csv
29_stage8_core_v2_2_corrected_final_single_cpi_known_k_complexity.csv
```

任一存在则停止，不覆盖。

---

## 3. 归档本次第二个 F0-only 失败 runtime

规范 corrected runtime：

```powershell
$runtime = 'E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1'
```

### 3.1 严格现场合同

要求：

```text
runtime root 存在

root files:
- f0_audit.mat，且只有该文件

directories:
- checkpoints
- tmp

checkpoints 中真实文件 = 0
tmp 中真实文件 = 0
tmp 中真实子目录 = 0

不存在：
- protocol.mat
- registry.csv
- f1a_oracle_audit.mat
- f1b_production_regression_audit.mat
- pause.request
- finalized.mat
- *.lock
```

PowerShell 检查必须使用：

```powershell
Get-ChildItem -File
Get-ChildItem -Directory
```

不得使用未过滤的条目总数。

若现场与上述不一致，停止，不猜测、不删除。

### 3.2 读取失败原因

用一个短暂的 R2022b `-singleCompThread` 只读会话读取 `f0_audit.mat`。

必须确认：

```text
f0.pass = false
f0.status = F0_FAIL_STOPPED
f0.matlab_external_count = 0
f0.coordinator_count = 0
f0.lock_count = 0
f0.old_runtime_audit.tmp_count = 2
f0.old_runtime_audit.pass = false
```

不得调用 fit、registry 或 trial generator。

### 3.3 字节身份

记录：

```text
f0_audit.mat SHA-256
f0_audit.mat byte count
整个 runtime 相对路径、类型、长度、文件 SHA-256 inventory
```

### 3.4 原样移动

创建：

```powershell
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$archiveRoot = "E:\bs_innovation_runtime\stage8_core_v2_2_f0_tmp_enumeration_failure_af459db_$stamp"
$archivedRuntime = Join-Path $archiveRoot 'original_runtime'
```

使用：

```powershell
Move-Item -LiteralPath $runtime -Destination $archivedRuntime
```

禁止：

```text
Copy + delete
修改 f0_audit
在 original_runtime 内新增 manifest
```

在 `$archiveRoot` 外层写：

```text
archive_manifest.json
```

至少包含：

```json
{
  "status": "ARCHIVED_F0_TMP_ENUMERATION_FAILURE",
  "source_head": "af459db19d56b0952b9bad3ff93093eaea30e92a",
  "reason": "MATLAB_DIR_STAR_COUNTED_DOT_DIRECTORY_ENTRIES",
  "external_matlab_count": 0,
  "coordinator_count": 0,
  "lock_count": 0,
  "formal_f1a_executed": false,
  "formal_f1b_executed": false,
  "formal_trial_count": 0,
  "checkpoint_count": 0,
  "protocol_present": false,
  "runtime_preserved_byte_for_byte": true
}
```

移动后验证：

```text
原规范 runtime 路径不存在
f0 SHA-256 不变
f0 byte count 不变
完整 inventory 不变
```

---

## 4. 允许修改的代码

只允许修改：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/validation/
run_stage8_core_v2_2_final_validation.m
```

允许新增：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/validation/
stage8_core_v2_2_directory_inventory.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/tests/
test_f0_directory_inventory_contract.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/tests/
test_f0_preflight_does_not_claim_runtime.m
```

不得修改：

```text
common/ 下全部生产科学代码

validation/
build_stage8_core_v2_2_final_registry.m
generate_stage8_core_v2_2_trial.m
build_stage8_core_v2_2_validation_context.m
summarize_stage8_core_v2_2_final_validation.m
finalize_stage8_core_v2_2_final_validation.m

tests/
test_f1_canonical_oracle_contract.m
test_historical_24_trial_regression.m
parse_historical_angle_matrix.m
test_summary_fixed_grid_rmse_contract.m
```

---

## 5. 真实目录项 inventory helper

新增：

```matlab
function inventory = stage8_core_v2_2_directory_inventory(path_now)
```

合同：

1. `path_now` 必须是已存在目录，否则 error；
2. 调用：
   ```matlab
   entries = dir(path_now);
   ```
3. 显式移除：
   ```text
   .
   ..
   ```
4. 分别统计：
   ```text
   file_count
   directory_count
   ```
5. 返回确定性排序后的：
   ```text
   file_names
   directory_names
   ```
6. 隐藏文件也按真实文件统计；
7. 不递归；
8. 不修改目录。

建议实现语义：

```matlab
names = string({entries.name});
entries = entries(~ismember(names, [".", ".."]));

is_directory = [entries.isdir];

files = entries(~is_directory);
directories = entries(is_directory);

inventory = struct( ...
    'path', char(string(path_now)), ...
    'file_count', numel(files), ...
    'directory_count', numel(directories), ...
    'file_names', sort(string({files.name})), ...
    'directory_names', sort(string({directories.name})));
```

不得通过：

```text
允许 tmp_count = 2
只匹配 *.tmp
忽略异常扩展名
```

来绕过问题。

---

## 6. 修正 `old_runtime_audit_local`

将旧：

```matlab
'tmp_count', numel(dir(fullfile(root, 'tmp', '*')))
```

替换为真实 inventory：

```matlab
tmp_inventory = stage8_core_v2_2_directory_inventory( ...
    fullfile(root, 'tmp'));

audit.tmp_file_count = tmp_inventory.file_count;
audit.tmp_directory_count = tmp_inventory.directory_count;
audit.tmp_file_names = tmp_inventory.file_names;
audit.tmp_directory_names = tmp_inventory.directory_names;
```

为兼容报告，可保留：

```matlab
audit.tmp_count = audit.tmp_file_count;
```

通过条件必须同时要求：

```matlab
audit.tmp_file_count == 0
audit.tmp_directory_count == 0
```

不得改变：

```text
旧 V1 runtime 路径
f0/f1 SHA-256
protocol absent
checkpoint count
其他 old-runtime 证据门
```

---

## 7. 修正 F0 生命周期

当前错误顺序：

```text
prepare_new_runtime_local
→ F0
```

修改为：

```text
F0
→ 只有 F0 PASS 才 prepare_new_runtime_local
→ save f0_audit 到规范 runtime
→ F1A
→ F1B
```

即：

```matlab
function output = start_local(repo_dir, runtime_root)
    f0 = f0_local(repo_dir, runtime_root);

    if ~f0.pass
        save_preflight_failure_audit_local(runtime_root, f0);
        error(...);
    end

    prepare_new_runtime_local(runtime_root);
    save(fullfile(runtime_root, 'f0_audit.mat'), 'f0', '-mat');

    ...
end
```

### 7.1 失败 audit 不占用规范 runtime

若正式 `START` 中 F0 失败，将 audit 写到规范 runtime 的同级目录：

```text
stage8_core_v2_2_preflight_failures/
<UTC timestamp>_f0_audit.mat
```

不得创建规范 runtime。

这只是控制证据，不进入 Git。

### 7.2 新增只读动作

增加 action：

```text
PREFLIGHT
```

行为：

```matlab
output = f0_local(repo_dir, runtime_root);
```

要求：

```text
不创建 runtime
不写任何文件
不执行 F1A
不执行 F1B
不构建 registry
不运行 fit
```

更新错误提示为：

```text
Action must be Preflight, Start, Status, Pause, Resume, or Finalize.
```

---

## 8. 单元测试

### 8.1 `test_f0_directory_inventory_contract`

在仓库外临时目录测试：

#### 空目录

预期：

```text
file_count = 0
directory_count = 0
```

#### 一个普通文件

创建：

```text
sample.mat.tmp
```

预期：

```text
file_count = 1
directory_count = 0
```

#### 一个异常子目录

创建：

```text
unexpected/
```

预期：

```text
file_count = 0
directory_count = 1
```

#### 一个文件和一个子目录

预期：

```text
file_count = 1
directory_count = 1
```

所有测试后清理临时目录。

### 8.2 `test_f0_preflight_does_not_claim_runtime`

使用一个不存在的仓库外 runtime 路径。

调用：

```matlab
run_stage8_core_v2_2_final_validation( ...
    repo_dir, candidate_runtime, 'Preflight')
```

要求：

```text
返回 f0 struct
candidate_runtime 仍不存在
无 f0_audit.mat
无 protocol
无 checkpoint/tmp 目录
```

该测试只在：

```text
Git clean
正确分支
无外部 MATLAB/coordinator
29_* 不存在
old V1 runtime 证据有效
```

时执行。

若环境不满足，应明确 `SKIP_ENVIRONMENT_NOT_ELIGIBLE`，不得伪造 PASS。

---

## 9. 静态边界测试

提交前运行：

```text
MATLAB checkcode:
- runner
- directory inventory helper
- 两个新测试

PowerShell/Git diff audit
```

要求以下 diff 为空：

```powershell
git diff --exit-code 5f042b75ba6733ffdd531229f81cec7660418ca1..HEAD -- `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/common

git diff --exit-code 5f042b75ba6733ffdd531229f81cec7660418ca1..HEAD -- `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/build_stage8_core_v2_2_final_registry.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/generate_stage8_core_v2_2_trial.m `
  beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_7_known_k_local_cell_refinement/validation/build_stage8_core_v2_2_validation_context.m
```

并要求：

```text
15/16/23/24/26/27/28 evidence 无 diff
origin/main 不变
```

---

## 10. 提交顺序

### 10.1 Prompt commit

新增：

```text
innovation-mining/stage8_execution_prompts/active/
010_stage8_core_v2_2_f0_real_entry_preflight_final_freeze_v1.md
```

更新 active README：

```text
STAGE8_CORE_V2_2_F0_REAL_ENTRY_FIX_AUTHORIZED
NO_ALGORITHM_CHANGE
CANONICAL_RUNTIME_FAILURE_NO_LONGER_CLAIMS_RUNTIME
```

提交：

```text
docs(stage8-core): authorize F0 real-entry preflight fix
```

推送：

```powershell
git push origin experiment/stage8-core-v2
```

### 10.2 Code fix commit

只暂存：

```text
run_stage8_core_v2_2_final_validation.m
stage8_core_v2_2_directory_inventory.m
test_f0_directory_inventory_contract.m
test_f0_preflight_does_not_claim_runtime.m
```

提交：

```text
fix(stage8-core): count real tmp entries before final preflight
```

推送后要求：

```text
HEAD == origin/experiment/stage8-core-v2
origin/main unchanged
Git clean
```

记录该 code-fix commit 为正式 `START` HEAD。

---

## 11. 推送后的只读 PRELIGHT

使用：

```text
MATLAB R2022b
-singleCompThread
```

规范 runtime 此时必须不存在。

日志写到独立目录，不得写入规范 runtime。

调用：

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

old_runtime_audit.tmp_file_count = 0
old_runtime_audit.tmp_directory_count = 0
old_runtime_audit.pass = true

matlab_external_count = 0
coordinator_count = 0
lock_count = 0

规范 runtime 路径仍不存在
```

若 PRELIGHT 失败：

```text
停止
不创建规范 runtime
不再修复或重试
完整报告失败字段
```

---

## 12. 正式 START

只有 PRELIGHT PASS 后执行。

使用同一个已提交、已推送、Git clean 的 HEAD：

```text
MATLAB R2022b
-singleCompThread
1 个 scientific MATLAB
```

调用：

```matlab
out = run_step12_7_known_k_local_cell_refinement( ...
    'Start', ...
    'E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_f1_oracle_correction_v1');
disp(out);
```

START 必须：

```text
再次 F0
→ 创建规范 runtime
→ 写 f0_audit
→ F1A
→ F1B
→ unchanged 144-trial registry
→ checkpoint execution
```

### 12.1 F0

要求：

```text
F0_BOUNDARY_AND_ENVIRONMENT_PASS
```

### 12.2 F1A

要求：

```text
F1A_CANONICAL_ORACLE_CONTRACT_PASS
```

### 12.3 F1B

要求：

```text
F1B_PRODUCTION_24_TRIAL_REGRESSION_PASS

24/24 element hashes
16/16 K1 mode identity
16/16 K1 canonical H1
8/8 K2 CORE_LITE B0
8/8 K2 CORE_PLUS H2
truth/tracking/cross-CPI/K-estimation counts = 0
```

若 F1B 失败：

```text
这才属于 production promotion mismatch
停止
不改算法/容差/历史 evidence
不执行 144-trial
```

---

## 13. 144-trial 独立验证

F1B PASS 后运行原有 registry：

```text
144 element trials
72 K1
72 K2
288 rows
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
source power
correlation
source/noise seeds
single-CPI flags
same range-Doppler cell flags
```

执行模式：

```text
1 MATLAB
-singleCompThread
no parpool
no parfor
```

支持已有：

```text
Status
Pause
Resume
Finalize
```

不注册定时任务，不增加 worker。

---

## 14. 完整性与 Finalize

完成后 Status 必须：

```text
completed_trial_count = 144
remaining_trial_count = 0
tmp_checkpoint_count = 0
lock_count = 0
pause_requested = false

F0 PASS
F1A PASS
F1B PASS
```

随后 Finalize。

输出必须为：

```text
innovation-mining/29_stage8_core_v2_2_corrected_final_single_cpi_known_k_validation.md
innovation-mining/29_stage8_core_v2_2_corrected_final_single_cpi_known_k_trials.csv
innovation-mining/29_stage8_core_v2_2_corrected_final_single_cpi_known_k_summary.csv
innovation-mining/29_stage8_core_v2_2_corrected_final_single_cpi_known_k_q_analysis.csv
innovation-mining/29_stage8_core_v2_2_corrected_final_single_cpi_known_k_complexity.csv
```

形状：

```text
trials = 288 rows
summary = 1 row
q analysis = 4 rows
complexity = 2 rows
checkpoints = 144
```

最终状态只允许：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_LITE_ONLY
STAGE8_CORE_V2_2_FINAL_KNOWN_K_CORE_NOT_CONFIRMED
STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

不得根据结果修改门或重跑新 seed。

---

## 15. 文档与 Evidence 提交

根据真实 final state 更新：

```text
innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/stage8_execution_prompts/active/README.md
```

将：

```text
008_stage8_core_v2_2_f1_canonical_oracle_correction_v1.md
009_stage8_core_v2_2_archive_f0_and_restart_final_freeze_v1.md
010_stage8_core_v2_2_f0_real_entry_preflight_final_freeze_v1.md
```

移到：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

最终 active README：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_CORE_V2_2_CORRECTED_FINAL_FREEZE_COMPLETED
```

Evidence 提交中不得包含 `.m` 修改。

提交：

```text
docs(stage8-core): record corrected final single-CPI known-k freeze
```

只推送：

```powershell
git push origin experiment/stage8-core-v2
```

---

## 16. 完成后永久停止

不得继续：

```text
F0 审计扩展
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
论文正文与图表
公式—代码映射
baseline/参考文献讨论
单独审查是否集成 Step12.7 到 main
```

---

## 17. 最终报告格式

```text
STAGE8_CORE_V2_2_F0_REAL_ENTRY_FIX_AND_FINAL_FREEZE_PASS / FAIL

Branch:
Starting HEAD:
Prompt commit:
Code fix commit:
Evidence commit:
Push:
Git clean:
origin/main unchanged:

Archived second F0 failure:
- archive root
- f0 SHA before/after
- byte identity
- protocol/checkpoint/tmp counts

Scientific production code changed:
Registry changed:
Seeds changed:
Decision rules changed:

Directory inventory tests:
- empty directory
- one file
- one subdirectory
- mixed entries

Preflight:
- status
- canonical runtime absent after preflight
- old tmp file count
- old tmp directory count
- external MATLAB/coordinator/lock

F0:
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
MATLAB / mwpython / coordinator / lock:
```
