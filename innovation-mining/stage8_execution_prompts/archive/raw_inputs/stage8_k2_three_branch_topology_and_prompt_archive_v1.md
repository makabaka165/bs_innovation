# Stage8-K2 长期三分支拓扑建立与执行提示词归档（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、Git、PowerShell 和 GitHub 推送的执行 AI。
>
> 本协议只执行：
>
> ```text
> 1. 建立新的长期 Tangent 主实验分支；
> 2. 建立 Vincent-Anchored 只读研究后备分支；
> 3. 保持 main 不变；
> 4. 对已经完成、延期、被替代及本地原始输入提示词进行归档；
> 5. 建立 tags、Git bundle、分支拓扑和提示词归档清单；
> 6. 保留所有旧分支，等待用户之后人工判定和删除。
> ```
>
> 本协议不删除任何分支、文件、tag、commit 或科学证据。
>
> 本协议不运行 MATLAB，不执行任何 trial，不修改任何算法。
>
> 协议：
>
> ```text
> STAGE8_K2_THREE_BRANCH_TOPOLOGY_AND_PROMPT_ARCHIVE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_THREE_BRANCH_TOPOLOGY_AND_PROMPT_ARCHIVE_V1
> ```

---

## 0. 最终目标

本次建立两个新的长期远端分支，并保持 `main`：

```text
main

experiment/stage8-k2-tangent

research/stage8-k2-vincent-anchored
```

### `main`

保持当前稳定提交，不做任何修改：

```text
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

### `experiment/stage8-k2-tangent`

从以下精确提交创建：

```text
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b
```

其科学内容应当包含：

```text
Core-V2 known-K 基础；
Tangent-Profile 算法及决定性实验；
Tangent 方向轴诊断修正；
Full4D Beamspace/Element CML 比较；
标准未平滑 Beamspace/Element MUSIC 比较；
31_*–34_* 科学证据。
```

其科学内容不得包含：

```text
Vincent-Anchored AML 实现；
35_* / 36_* / 37_*；
tools/stage8_k2_vincent_anchored_aml/。
```

该分支是未来唯一允许继续增加“经典算法对比”的长期实验分支。

### `research/stage8-k2-vincent-anchored`

从以下精确提交创建：

```text
89e47e1827aa8c2a36c49c369e60525713d20d38
```

该分支完整保留：

```text
Tangent；
经典 CML/MUSIC；
Vincent-Anchored 理论、代码、实验；
Vincent 适用区间分析和负结果收束；
31_*–37_*；
tools/stage8_k2_vincent_anchored_aml/。
```

其状态固定为：

```text
READ_ONLY_RESEARCH_BACKUP

DEFAULT_K2 = TANGENT_PROFILE_SAFE

VINCENT_ANCHORED =
NOT_DEFAULT
NOT_PRODUCTION
NO_V2

FURTHER_EXECUTION =
NOT_AUTHORIZED
```

---

## 1. 当前提交拓扑

执行前确认以下 commit object 均存在：

```text
Core-V2 known-K final:
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

Tangent result + corrected diagnostics:
721c30aa96f1687c757004613c23e9fb6a814afd

Tangent + classical CML/MUSIC comparison:
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

Vincent-Anchored implementation + experiment + applicability closure:
89e47e1827aa8c2a36c49c369e60525713d20d38
```

验证：

```powershell
git cat-file -e 9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7^{commit}
git cat-file -e 721c30aa96f1687c757004613c23e9fb6a814afd^{commit}
git cat-file -e bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b^{commit}
git cat-file -e 89e47e1827aa8c2a36c49c369e60525713d20d38^{commit}
```

验证祖先关系：

```powershell
git merge-base --is-ancestor `
  9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7 `
  721c30aa96f1687c757004613c23e9fb6a814afd

git merge-base --is-ancestor `
  721c30aa96f1687c757004613c23e9fb6a814afd `
  bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

git merge-base --is-ancestor `
  bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b `
  89e47e1827aa8c2a36c49c369e60525713d20d38
```

三项必须全部返回成功。

---

## 2. 当前远端分支锚点

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags

git rev-parse origin/main
git rev-parse origin/experiment/stage8-core-v2
git rev-parse origin/experiment/stage8-k2-classical-baselines-v1
git rev-parse origin/experiment/stage8-k2-vincent-anchored-aml-v1
```

要求：

```text
origin/main
==
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/experiment/stage8-core-v2
==
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/experiment/stage8-k2-classical-baselines-v1
==
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

origin/experiment/stage8-k2-vincent-anchored-aml-v1
==
89e47e1827aa8c2a36c49c369e60525713d20d38
```

若任一远端锚点不同：

```text
硬停止；
打印实际 SHA；
不得 reset、force-push、猜测新的起点。
```

---

## 3. 当前工作树特殊合同

预期当前本地分支：

```text
experiment/stage8-k2-vincent-anchored-aml-v1
```

预期当前 HEAD：

```text
89e47e1827aa8c2a36c49c369e60525713d20d38
```

允许存在且必须保留的唯一未跟踪文件：

```text
innovation-mining/stage8_execution_prompts/
stage8_k2_vincent_anchored_projector_aml_prompt_v1.md
```

除该文件外：

```text
所有 tracked 文件无 diff；
不得存在其他 untracked 文件。
```

执行：

```powershell
git switch experiment/stage8-k2-vincent-anchored-aml-v1

$head = (git rev-parse HEAD).Trim()
$remote = (git rev-parse origin/experiment/stage8-k2-vincent-anchored-aml-v1).Trim()
$status = @(git status --porcelain=v1 --untracked-files=all)
```

要求：

```text
$head == $remote
$head == 89e47e1827aa8c2a36c49c369e60525713d20d38
```

`$status` 只允许精确一项：

```text
?? innovation-mining/stage8_execution_prompts/stage8_k2_vincent_anchored_projector_aml_prompt_v1.md
```

若该未跟踪文件已经被用户手动移动：

```text
不要重建；
继续前先确认它已存在于一个 archive/raw_inputs 路径，
且有 SHA-256 记录。
```

若文件既不在原路径也不在归档路径：

```text
硬停止；
不得假设它已被删除授权。
```

---

## 4. 严格禁止删除

本协议禁止执行：

```text
git branch -d
git branch -D
git push origin --delete
git tag -d
git push origin :<ref>
Remove-Item 删除 prompt
del / rm 删除 prompt
git clean
git reset --hard 到未知 ref
force push
rebase
filter-branch
filter-repo
```

本协议也禁止删除或改写以下旧远端分支：

```text
experiment/stage8-core-v2
experiment/stage8-k2-classical-baselines-v1
experiment/stage8-k2-vincent-anchored-aml-v1
```

这些旧分支必须保留，并在最终报告中标记为：

```text
LEGACY_REF_RETAINED_PENDING_USER_REVIEW
```

用户之后人工判定是否删除。

---

## 5. 仓库外备份

在任何 branch/tag/file 移动前创建：

```powershell
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$backupRoot = "E:\bs_innovation_runtime\stage8_k2_three_branch_reorg_$stamp"

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
```

保存：

```text
refs_before.txt
branches_before.txt
status_before.txt
prompt_inventory_before.csv
```

### 5.1 Git bundle

执行：

```powershell
git bundle create `
  (Join-Path $backupRoot 'bs_innovation_pre_three_branch_reorg.bundle') `
  --all

git bundle verify `
  (Join-Path $backupRoot 'bs_innovation_pre_three_branch_reorg.bundle')
```

必须：

```text
Bundle verification = PASS
```

### 5.2 提示词 inventory

枚举：

```text
innovation-mining/stage8_execution_prompts/**/*.md
```

以及允许的未跟踪原始 prompt。

保存：

```text
relative_path
tracked/untracked
byte_count
SHA-256
current_archive_category
```

到：

```text
prompt_inventory_before.csv
```

### 5.3 原始未跟踪 prompt 外部副本

对：

```text
stage8_k2_vincent_anchored_projector_aml_prompt_v1.md
```

记录 SHA-256 和 byte count，并复制到：

```text
$backupRoot\raw_input_prompts\
```

复制后确认 SHA-256 完全相同。

不得从原路径删除；正式移动将在 research 分支中进行。

---

## 6. 建立里程碑 tags

创建以下 annotated tags：

```text
stage8-core-v2-known-k-9bcb4f7
→ 9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

stage8-k2-tangent-retain-721c30a
→ 721c30aa96f1687c757004613c23e9fb6a814afd

stage8-k2-classical-baselines-bdb2a51
→ bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

stage8-k2-vincent-anchored-closed-89e47e1
→ 89e47e1827aa8c2a36c49c369e60525713d20d38
```

若 tag 已存在：

```text
只允许它已经指向同一 commit；
否则硬停止。
```

禁止移动已有 tag。

推送：

```powershell
git push origin `
  stage8-core-v2-known-k-9bcb4f7 `
  stage8-k2-tangent-retain-721c30a `
  stage8-k2-classical-baselines-bdb2a51 `
  stage8-k2-vincent-anchored-closed-89e47e1
```

---

# Part A：建立 Vincent 研究后备分支

## 7. 创建 research 分支

确认本地和远端均不存在：

```text
research/stage8-k2-vincent-anchored
```

执行：

```powershell
git show-ref --verify --quiet `
  refs/heads/research/stage8-k2-vincent-anchored

git show-ref --verify --quiet `
  refs/remotes/origin/research/stage8-k2-vincent-anchored
```

若任一存在：

```text
硬停止；
不得覆盖、reset 或 force-push。
```

创建：

```powershell
git switch --detach 89e47e1827aa8c2a36c49c369e60525713d20d38

git switch -c research/stage8-k2-vincent-anchored
```

此时允许的未跟踪原始 prompt 应继续存在。

---

## 8. Research 分支提示词归档

提示词根目录：

```text
innovation-mining/stage8_execution_prompts
```

最终允许的顶层结构：

```text
README.md

active/
  README.md

archive/
  completed/
  deferred/
  superseded/
  raw_inputs/
  README.md
  PROMPT_ARCHIVE_MANIFEST.csv
```

### 8.1 已执行提示词

在 research 分支中，以下已执行 prompt 应位于：

```text
archive/completed/
```

至少包括：

```text
001
003
004
005
006
007
008
009
010
011
012
013
014
015
016
```

具体完整文件名以 Git inventory 为准。

不得创建不存在的 `002`。

若上述文件已经位于 `archive/completed/`：

```text
不重复移动；
只写入 manifest。
```

若某个已执行 prompt 仍位于：

```text
stage8_execution_prompts/
或
stage8_execution_prompts/active/
```

使用：

```powershell
git mv
```

移动到：

```text
archive/completed/
```

### 8.2 延期提示词

以下提示词保持：

```text
archive/deferred/
stage8_1b_resumable_sharded_execution_prompt_v2.md
```

状态：

```text
DEFERRED_NOT_ACTIVE
NO_EXECUTION_AUTHORITY
```

不得执行该 prompt。

### 8.3 被替代提示词

以下提示词保持：

```text
archive/superseded/
stage8_core_v2_known_k_pruning_audit_branch_execution_prompt_v1.md
```

状态：

```text
SUPERSEDED
NO_EXECUTION_AUTHORITY
```

### 8.4 本地原始输入 prompt

将唯一未跟踪文件：

```text
innovation-mining/stage8_execution_prompts/
stage8_k2_vincent_anchored_projector_aml_prompt_v1.md
```

移动到：

```text
innovation-mining/stage8_execution_prompts/archive/raw_inputs/
stage8_k2_vincent_anchored_projector_aml_prompt_v1.md
```

使用：

```powershell
Move-Item
```

移动前后记录：

```text
SHA-256
byte count
```

必须完全相同。

该文件定位为：

```text
RAW_USER_INPUT_PRESERVED
DUPLICATE_OR_PRECURSOR_OF_COMPLETED_015
NO_EXECUTION_AUTHORITY
```

即使内容与 `015` 完全重复，也必须保留，不得删除。

### 8.5 未知文件

若在 prompt root 或 active 中发现任何无法根据现有报告判断状态的 prompt：

```text
硬停止；
列出路径、SHA 和首行标题；
不得猜测分类、移动或删除。
```

---

## 9. Research 分支归档 manifest

新增或更新：

```text
innovation-mining/stage8_execution_prompts/archive/
PROMPT_ARCHIVE_MANIFEST.csv
```

字段至少包括：

```text
branch_role
original_path
archived_path
archive_status
related_evidence
tracked_before
sha256_before
sha256_after
byte_identical
execution_authority
notes
```

Research 分支的：

```text
branch_role = VINCENT_RESEARCH_BACKUP
execution_authority = false
```

所有移动后的文件必须：

```text
sha256_before == sha256_after
byte_identical = true
```

另新增：

```text
innovation-mining/stage8_execution_prompts/archive/README.md
```

说明：

```text
archive 中全部文档只用于审计和历史追溯；
没有任何 archive prompt 授权继续执行；
Vincent 路线已关闭；
Tangent 是默认 K2。
```

---

## 10. Research 分支文档定位

新增：

```text
innovation-mining/
38_stage8_k2_long_term_branch_topology_and_prompt_archive.md
```

Research 版本必须写明：

```text
Current branch:
research/stage8-k2-vincent-anchored

Role:
READ_ONLY_RESEARCH_BACKUP

Contains:
31_*–37_*
Tangent
classical baselines
Vincent implementation
negative applicability closure

Default K2:
TANGENT_PROFILE_SAFE

Vincent:
NOT_DEFAULT
NOT_PRODUCTION
NO_V2

Further algorithm execution:
NOT_AUTHORIZED
```

更新：

```text
innovation-mining/00_DOCUMENT_STATUS_INDEX.md

innovation-mining/stage8_execution_prompts/README.md

innovation-mining/stage8_execution_prompts/active/README.md
```

Research `active/README.md` 最终状态：

```text
NO_ACTIVE_STAGE8_EXECUTION

BRANCH_ROLE:
READ_ONLY_VINCENT_RESEARCH_BACKUP

DEFAULT_K2:
TANGENT_PROFILE_SAFE

VINCENT:
CLOSED_NO_ROBUST_REGIME
NOT_DEFAULT
NOT_PRODUCTION
NO_V2

FURTHER_EXECUTION:
NOT_AUTHORIZED
```

### Research 文档修改边界

只允许修改或新增：

```text
00_DOCUMENT_STATUS_INDEX.md
38_stage8_k2_long_term_branch_topology_and_prompt_archive.md
stage8_execution_prompts/**
```

不得修改：

```text
*.m（archive/analysis 之外也不得改）
31_*–37_*
Step12.7
Tangent tools
Classical baseline tools
Vincent scientific tools
任何 CSV 科学结果
```

---

## 11. Research 分支提交与推送

执行：

```powershell
git diff --check
git diff --name-status
```

确认只有允许的 docs/archive 路径。

暂存并提交：

```text
docs(stage8-k2): establish Vincent research backup and archive prompts
```

推送：

```powershell
git push -u origin research/stage8-k2-vincent-anchored
```

确认：

```text
HEAD == origin/research/stage8-k2-vincent-anchored
tracked worktree clean
no untracked original prompt remains
```

旧分支：

```text
origin/experiment/stage8-k2-vincent-anchored-aml-v1
```

必须仍存在且仍指向 `89e47e1`。

---

# Part B：建立 Tangent 长期主实验分支

## 12. 创建 Tangent 分支

确认本地和远端均不存在：

```text
experiment/stage8-k2-tangent
```

若存在：

```text
硬停止；
不得覆盖。
```

执行：

```powershell
git switch --detach bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

git switch -c experiment/stage8-k2-tangent
```

确认：

```text
HEAD == bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b
```

---

## 13. Tangent 分支科学边界审计

必须存在：

```text
tools/stage8_k2_tangent_profile/

tools/stage8_k2_classical_baselines/

innovation-mining/31_*
innovation-mining/32_*
innovation-mining/33_*
innovation-mining/34_*
```

必须不存在：

```text
tools/stage8_k2_vincent_anchored_aml/

innovation-mining/35_*
innovation-mining/36_*
innovation-mining/37_*
```

执行：

```powershell
Test-Path tools/stage8_k2_vincent_anchored_aml

Get-ChildItem innovation-mining -Filter '35_*'
Get-ChildItem innovation-mining -Filter '36_*'
Get-ChildItem innovation-mining -Filter '37_*'
```

结果必须为空/false。

同时确认：

```powershell
git merge-base --is-ancestor `
  721c30aa96f1687c757004613c23e9fb6a814afd `
  HEAD

git merge-base --is-ancestor `
  89e47e1827aa8c2a36c49c369e60525713d20d38 `
  HEAD
```

要求：

```text
721c30a 是祖先 → true
89e47e1 是祖先 → false
```

这证明 Tangent 分支包含经典比较，但不包含 Vincent 后续提交。

---

## 14. Tangent 分支提示词归档

最终目录结构与 Research 相同：

```text
README.md

active/
  README.md

archive/
  completed/
  deferred/
  superseded/
  raw_inputs/
  README.md
  PROMPT_ARCHIVE_MANIFEST.csv
```

### 14.1 已执行 prompt

Tangent 分支已执行 prompt 至少包括：

```text
001
003
004
005
006
007
008
009
010
011
012
013
014
```

全部必须位于：

```text
archive/completed/
```

Tangent 分支不应存在：

```text
015
016
Vincent raw input prompt
```

因为这些属于 Research 分支。

### 14.2 延期与 superseded

保持：

```text
archive/deferred/
stage8_1b_resumable_sharded_execution_prompt_v2.md

archive/superseded/
stage8_core_v2_known_k_pruning_audit_branch_execution_prompt_v1.md
```

二者都没有执行授权。

### 14.3 Active 目录

`active/` 中只允许：

```text
README.md
```

若存在其他 prompt：

```text
按已有证据归档；
无法确定则停止。
```

### 14.4 Tangent manifest

新增/更新：

```text
archive/PROMPT_ARCHIVE_MANIFEST.csv
archive/README.md
```

Tangent manifest 的：

```text
branch_role = TANGENT_PRIMARY_AND_CLASSICAL_BASELINES
execution_authority = false
```

---

## 15. Tangent 分支文档定位

新增：

```text
innovation-mining/
38_stage8_k2_long_term_branch_topology_and_prompt_archive.md
```

Tangent 版本必须写明：

```text
Current branch:
experiment/stage8-k2-tangent

Role:
PRIMARY_TANGENT_AND_CLASSICAL_BASELINES

Default K2:
TANGENT_PROFILE_SAFE

Contains:
31_* / 32_* Tangent evidence
33_* / 34_* CML/MUSIC comparison

Does not contain:
Vincent algorithm
35_* / 36_* / 37_*

Research backup:
research/stage8-k2-vincent-anchored

Future allowed work:
classic/external algorithm comparison only,
performed first on a temporary work branch.

Tangent algorithm modification:
NOT_AUTHORIZED
```

更新：

```text
innovation-mining/00_DOCUMENT_STATUS_INDEX.md

innovation-mining/stage8_execution_prompts/README.md

innovation-mining/stage8_execution_prompts/active/README.md
```

Tangent `active/README.md` 最终状态：

```text
NO_ACTIVE_STAGE8_EXECUTION

BRANCH_ROLE:
PRIMARY_TANGENT_AND_CLASSICAL_BASELINES

DEFAULT_K2:
TANGENT_PROFILE_SAFE

CORE TANGENT ALGORITHM:
FROZEN

FUTURE PERMITTED WORK:
CLASSICAL_OR_EXTERNAL_BASELINE_COMPARISON_ONLY
REQUIRES_SEPARATE_USER_AUTHORIZATION

VINCENT:
NOT_PRESENT_IN_THIS_BRANCH
SEE research/stage8-k2-vincent-anchored
```

### Tangent `00_DOCUMENT_STATUS_INDEX.md`

至少将当前权威 K2 内容更新为：

```text
31_*:
TANGENT DECISIVE EVIDENCE

32_*:
TANGENT DIAGNOSTIC CORRECTION

33_* / 34_*:
CLASSICAL CML/MUSIC COMPARISON

Default K2:
TANGENT_PROFILE_SAFE

Core-Lite:
fixed-grid safety baseline

Core-Plus:
historical internal baseline

Full4D CML:
diagnostic numerical baseline

MUSIC:
standard un-smoothed reference

Vincent:
not present in this branch;
research backup only.
```

不得改写 `31_*–34_*` 原始证据。

---

## 16. Tangent 分支提交与推送

确认：

```text
无 .m 修改
无 CSV 修改
无 31_*–34_* 修改
无 Step12.7 修改
```

只允许 docs/archive diff。

提交：

```text
docs(stage8-k2): establish Tangent long-term branch and archive prompts
```

推送：

```powershell
git push -u origin experiment/stage8-k2-tangent
```

确认：

```text
HEAD == origin/experiment/stage8-k2-tangent
tracked worktree clean
```

---

## 17. 未来经典算法比较的工作流

本协议只写入规则，不创建新的算法比较分支。

未来若比较新的经典方法，例如：

```text
Partial Relaxation DML
近双源文献基线
相关源专用 MUSIC/ML
其他公平基线
```

必须：

1. 从：
   ```text
   experiment/stage8-k2-tangent
   ```
   创建临时分支：
   ```text
   work/stage8-k2-<baseline-name>
   ```
2. 在临时分支实现和验证；
3. 禁止修改：
   ```text
   tools/stage8_k2_tangent_profile/**
   31_* / 32_*
   Step12.7
   ```
4. 完成后由用户单独授权；
5. 仅允许：
   ```text
   git merge --ff-only
   ```
   快进 Tangent 长期分支；
6. 临时分支是否删除由用户另行决定。

本次不得创建该 work 分支。

---

## 18. 旧分支保留清单

本次完成后，以下旧远端 refs 必须仍存在：

```text
experiment/stage8-core-v2
experiment/stage8-k2-classical-baselines-v1
experiment/stage8-k2-vincent-anchored-aml-v1
```

在仓库外写：

```text
$backupRoot\PENDING_USER_BRANCH_DELETION.txt
```

内容至少包括：

```text
Legacy ref:
experiment/stage8-core-v2
Expected target:
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7
Covered by:
experiment/stage8-k2-tangent ancestry
stage8-core-v2-known-k-9bcb4f7 tag
Git bundle

Legacy ref:
experiment/stage8-k2-classical-baselines-v1
Expected target:
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b
Covered by:
experiment/stage8-k2-tangent ancestry
stage8-k2-classical-baselines-bdb2a51 tag
Git bundle

Legacy ref:
experiment/stage8-k2-vincent-anchored-aml-v1
Expected target:
89e47e1827aa8c2a36c49c369e60525713d20d38
Covered by:
research/stage8-k2-vincent-anchored ancestry
stage8-k2-vincent-anchored-closed-89e47e1 tag
Git bundle

Deletion performed:
false
```

不要在报告中给出“已删除”。

---

## 19. 远端最终审计

执行：

```powershell
git fetch origin --prune --tags
git branch -r
```

必须至少看到：

```text
origin/main
origin/experiment/stage8-k2-tangent
origin/research/stage8-k2-vincent-anchored

origin/experiment/stage8-core-v2
origin/experiment/stage8-k2-classical-baselines-v1
origin/experiment/stage8-k2-vincent-anchored-aml-v1
```

旧 refs 尚未删除是本协议的预期结果。

确认：

```text
origin/main unchanged:
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

new Tangent branch has bdb2a51 as ancestor

new Research branch has 89e47e1 as ancestor

new Tangent branch does not contain Vincent paths

new Research branch contains 35_*–37_*

all four tags exist at exact commits

bundle verification PASS
```

---

## 20. 最终本地状态

最后切换到：

```text
experiment/stage8-k2-tangent
```

要求：

```text
HEAD == origin/experiment/stage8-k2-tangent
tracked worktree clean
untracked files = 0
```

MATLAB、mwpython、coordinator、lock：

```text
0 / 0 / 0 / 0
```

本协议不得启动 MATLAB，因此非零即属于外部现场，应停止并报告。

---

## 21. 最终允许的改动范围

### Research 分支允许

```text
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/38_stage8_k2_long_term_branch_topology_and_prompt_archive.md
innovation-mining/stage8_execution_prompts/**
```

### Tangent 分支允许

```text
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/38_stage8_k2_long_term_branch_topology_and_prompt_archive.md
innovation-mining/stage8_execution_prompts/**
```

### 两分支都禁止

```text
beamspace_ml_v18/**
tools/** scientific implementation
31_*–37_* scientific evidence
*.csv scientific results
*.mat
*.png
main
```

例外：

```text
archive/PROMPT_ARCHIVE_MANIFEST.csv
```

是提示词归档清单，不是科学结果，可以新增。

---

## 22. 最终报告格式

```text
STAGE8_K2_THREE_BRANCH_TOPOLOGY_AND_PROMPT_ARCHIVE_PASS / FAIL

Repository:
Starting branch:
Starting HEAD:

Backup root:
Bundle:
Bundle verification:

Tags:
- core
- tangent
- classical
- Vincent closure

New long-term branches:

1. main
   SHA:
   changed:
   false

2. experiment/stage8-k2-tangent
   base:
   docs/archive commit:
   remote:
   contains 31/32:
   contains 33/34:
   contains Vincent tools:
   contains 35/36/37:

3. research/stage8-k2-vincent-anchored
   base:
   docs/archive commit:
   remote:
   contains 31–37:
   read-only status:
   default K2:

Prompt archive:

Research:
- completed count
- deferred count
- superseded count
- raw input count
- raw input SHA before/after
- unknown prompts

Tangent:
- completed count
- deferred count
- superseded count
- active prompts
- unknown prompts

Legacy remote refs retained:
- experiment/stage8-core-v2
- experiment/stage8-k2-classical-baselines-v1
- experiment/stage8-k2-vincent-anchored-aml-v1

Branch deletion performed:
false

File deletion performed:
false

Scientific algorithm changed:
false

Scientific evidence changed:
false

main changed:
false

Final checked-out branch:
experiment/stage8-k2-tangent

Tracked worktree clean:
Untracked files:
MATLAB / mwpython / coordinator / lock:
```

---

## 23. 完成后停止

本协议完成后不得自动：

```text
删除旧分支
合并 main
合并 Research 到 Tangent
修改 Tangent
实现 Vincent V2
启动新的经典算法比较
执行 MATLAB
删除 archived prompts
删除 tags
删除 bundle
```

用户之后人工检查：

```text
新 Tangent 分支
新 Research 分支
tags
bundle
prompt archive manifest
PENDING_USER_BRANCH_DELETION.txt
```

再单独决定是否删除旧分支或归档文件。
