# Stage8 K2 Tangent Pipeline Runtime Decomposition & Canonical Registered-Manifold Dictionary Placement Audit

> **Codex 完整执行提示词**
>
> 本文档用于直接交给 Codex 执行。
>
> 本阶段是 `TANGENT_PROFILE_SAFE` 的 **Runtime Decomposition / Cache Placement Audit**，不是 Level-B，不是插值阶段，也不是 fixed-path dictionary 的正式生产接入阶段。

---

## 0. 执行身份、基线与阶段定义

### 0.1 Repository

```text
Repository:
makabaka165/bs_innovation
```

本地典型路径：

```text
E:\bs_innovation
```

### 0.2 当前工作分支

本阶段**不创建新分支**，继续在：

```text
experiment/stage8-k2-tangent-canonical-cache-v1
```

上 fast-forward 推进。

### 0.3 Level-A 不可变闭包锚点

当前已确认的 Level-A closure commit：

```text
LEVEL_A_CLOSURE_COMMIT
cf35e37a74366a8d9829de3a1f8b740a788bade1
```

其语义永久冻结为：

```text
STAGE8_K2_TANGENT_CANONICAL_CACHE_LEVEL_A_COMPLETE
```

后续即使当前 branch HEAD 前移，也不得修改该提交的历史含义。

后续文档必须使用：

```text
Level-A closure commit = cf35e37a74366a8d9829de3a1f8b740a788bade1
```

不得把 Level-A closure commit 与当前 Audit 起点混为同一语义。

### 0.4 Placement Audit 不可变起点

当前已推送并确认的 Audit start commit：

```text
AUDIT_START_COMMIT
aff3bb42df2b3d9b435cc57eacd3237826e7d87d
```

它满足：

```text
parent = cf35e37a74366a8d9829de3a1f8b740a788bade1
origin/experiment/stage8-k2-tangent-canonical-cache-v1 = aff3bb42df2b3d9b435cc57eacd3237826e7d87d
```

`cf35e37..aff3bb4` 只新增本执行提示词，不修改算法代码。后续 Audit instrumentation、evidence 与提交差异均以 `aff3bb42df2b3d9b435cc57eacd3237826e7d87d` 为不可变起点。

不得再把 Level-A closure commit 误写为当前 branch HEAD。当前 Audit 的阶段身份是 `AUDIT_START_COMMIT = aff3bb42df2b3d9b435cc57eacd3237826e7d87d`；同时也不得用 Audit start commit 替换 Level-A closure commit 的历史语义。

Git tag 可选，不是硬要求。

### 0.5 当前理论状态

冻结：

```text
THEORY_STATUS
TANGENT_PIPELINE_CACHE_PLACEMENT_THEORY_CLOSED

CURRENT_PERFORMANCE_STATUS
CANDIDATE_MECHANISM_ONLY_NOT_YET_INTEGRATED

NEXT_STAGE
TANGENT_PIPELINE_RUNTIME_DECOMPOSITION_AND
CANONICAL_REGISTERED_MANIFOLD_DICTIONARY_PLACEMENT_AUDIT
```

### 0.6 创新边界冻结

当前创新叙事必须固定为：

> Canonical registered-manifold dictionary 是完整 `TANGENT_PROFILE_SAFE` 流水线中 registered full-sequential backbone 与 K2 safety baseline 的候选计算复用机制；Tangent 本身继续负责连续低维 refinement。当前不宣称 dictionary 加速 Tangent T4 continuous core。

可用英文表述：

> A canonical registered-manifold dictionary is a candidate acceleration mechanism for the registered full-sequential backbone and K2 safety baseline required by the complete `TANGENT_PROFILE_SAFE` pipeline, while Tangent itself performs continuous low-dimensional refinement.

严禁写成：

```text
canonical cache accelerates the Tangent continuous core
```

也不要写成：

```text
cache only accelerates an unrelated legacy method
```

因为当前 `TANGENT_PROFILE_SAFE` 强制依赖：

- K1 public estimate 提供 Tangent center；
- fixed K2 提供 fallback；
- fixed K2 likelihood 是 Tangent upgrade 的 safety guard。

---

# 1. 本阶段执行授权

本提示词授权 Codex：

1. 检查 Git / branch / worktree；
2. 审计当前 `aff3bb42df2b3d9b435cc57eacd3237826e7d87d` tree；
3. 在**当前 branch** 上增加 diagnostic-only runtime/query instrumentation；
4. 建立 diagnostic 21-key canonical registered-manifold dictionary；
5. 运行静态有限集合全认证；
6. 运行 72/72 frozen Tangent trial 的 query/trajectory audit；
7. 运行 72/72 trial 的独立 runtime decomposition；
8. 运行 microbenchmark；
9. 建立 structural → G-only → dictionary 的**反事实**性能模型；
10. 按 `fixed_measurement_hash` 建立 lifecycle economics；
11. 输出 Placement Audit 结论；
12. 更新必要的 `innovation-mining/52_*` 结果；
13. 按逻辑提交；
14. 非 force-push 推送当前分支。

本提示词**不授权**：

- 创建新 Git branch；
- 修改 `main`；
- 修改 `experiment/stage8-k2-tangent`；
- 修改旧 `experiment/stage8-k2-tangent-canonical-cache`；
- rewrite / rebase / amend Level-A closure `cf35e37` 或 Audit start `aff3bb4`；
- force-push；
- merge；
- 创建 PR；
- 实现 Level-B interpolation；
- nearest-neighbor approximation；
- 将 dictionary 正式接入 fixed K1/K2 estimator production path；
- 实现 context reuse；
- 实现 helper-K1 reuse；
- 用 G-only builder 替换生产 estimator；
- 修改任何算法阈值；
- 修改 local grid；
- 修改 solver update order；
- 修改 Tangent direction；
- 修改 `fminbnd`；
- 修改 safe selector；
- 重跑经典算法对比；
- 新增 SNR/profile/random seed；
- FPGA cache mapping；

本阶段原则：

```text
MEASURE
CERTIFY
CLASSIFY
MODEL COUNTERFACTUALS
DECIDE PLACEMENT

DO NOT INTEGRATE YET
```

---

# 2. Git 预检

执行前：

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --porcelain=v1 --untracked-files=all
git remote -v
git fetch origin --prune
git rev-parse HEAD
git rev-parse origin/experiment/stage8-k2-tangent-canonical-cache-v1
git rev-parse origin/main
git rev-parse origin/experiment/stage8-k2-tangent
git rev-parse origin/experiment/stage8-k2-tangent-canonical-cache
```

不可变起点与执行时关系：

```text
branch:
experiment/stage8-k2-tangent-canonical-cache-v1

AUDIT_START_COMMIT:
aff3bb42df2b3d9b435cc57eacd3237826e7d87d

HEAD = origin/experiment/stage8-k2-tangent-canonical-cache-v1
AUDIT_START_COMMIT is ancestor of HEAD
```

若尚无 post-anchor 提交，则 HEAD 与远端都精确等于 `aff3bb42df2b3d9b435cc57eacd3237826e7d87d`；若已有已知 fast-forward 文档或 Audit 提交，则允许为其后继，但必须执行下述差异审查。

若存在非本任务产生的修改：

```text
BLOCKED_DIRTY_WORKTREE
```

不得 reset、clean、stash 用户文件或覆盖未知内容。

若 HEAD 或远端 branch 已超过 `aff3bb42df2b3d9b435cc57eacd3237826e7d87d`，检查 `aff3bb42..HEAD`。若含不明算法修改：

```text
BLOCKED_POST_AUDIT_START_UNKNOWN_SOURCE_CHANGES
```

必须验证：

```bash
git merge-base --is-ancestor cf35e37a74366a8d9829de3a1f8b740a788bade1 HEAD
git merge-base --is-ancestor aff3bb42df2b3d9b435cc57eacd3237826e7d87d HEAD
```

任一失败：

```text
BLOCKED_LEVEL_A_ANCHOR_NOT_ANCESTOR
BLOCKED_AUDIT_START_NOT_ANCESTOR
```

---

# 3. 代码理论不变量

## 3.1 Registered domain

当前 frozen full-sequential registered domain：

\[
\mathcal A =
\{7.4,7.6,7.8,8.0,8.2,8.4,8.6\},
\]

\[
\mathcal E =
\{9.8,10.0,10.2\},
\]

\[
\Omega=\mathcal A\times\mathcal E,
\qquad |\Omega|=21.
\]

执行时必须重新从代码审计：

```text
build_common_registered_local_domain
build_stage8_locked_plan
```

不要只相信提示词常量。

## 3.2 Fixed path 的 \(\Omega^K\) 闭合

必须在审计文档中重新给出证明。

如果：

\[
\Theta^{(0)}\in\Omega^K
\]

且 `refine_joint_sequential_dml` 每次仅将某个目标某一坐标替换为 registered axis value，则 update 后仍有：

\[
\Theta^{(n+1)}\in\Omega^K.
\]

canonical row sorting 仅改变行排列，不改变坐标值，因此：

\[
\Theta^{(0)}\in\Omega^K
\Rightarrow
\Theta^{(n)}\in\Omega^K,\ \forall n.
\]

必须重新核实：

- conventional singleton 返回 registered grid；
- grouped elevation 返回 registered elevation；
- conditional azimuth 返回 registered azimuth；
- grouped starts ∈ \(\Omega^K\)；
- K2 helper K1 是 fixed `fit_local_model_k(K=1)`，不是 public continuous K1；
- nested K1 row ∈ \(\Omega\)；
- nested anchor ∈ \(\Omega\)。

任一不成立：

```text
BLOCKED_REGISTERED_CLOSURE_CONTRACT_CHANGED
```

---

# 4. 当前 Tangent pipeline 的理论归因

定义：

\[
T_{\mathrm{total}}
=
T_{\mathrm{required\ fixed}}
+
T_{\mathrm{Tangent\ core}}.
\]

当前 exact registered dictionary 的候选作用：

\[
T_{\mathrm{required\ fixed}}
\rightarrow
T_{\mathrm{required\ fixed}}-\Delta T_{\mathrm{cache}}.
\]

Tangent continuous core：

- center manifold / derivatives；
- projected direction；
- T4 continuous profile；

默认不由该 dictionary 加速。

未来若真实 integration 成功：

\[
S_{\mathrm{E2E}}
=
\frac{
T_{\mathrm{required\ fixed}}+T_{\mathrm{Tangent\ core}}
}{
T_{\mathrm{required\ fixed}}-\Delta T_{\mathrm{cache}}
+
T_{\mathrm{Tangent\ core}}
}
>1,
\]

但：

\[
S_{\mathrm{Tangent-core}}\approx1.
\]

Placement Audit 阶段只能写：

```text
candidate mechanism for end-to-end Tangent-safe pipeline acceleration
```

不能写 measured speedup。

---

# 5. 三层公平成本模型

对 manifold 调用类别 \(c\)：

## 5.1 Legacy full-manifold

\[
T_c^F
=
T_{\mathrm{steering}}
+
T_{\mathrm{derivatives}}
+
T_{\mathrm{projection}}
+
T_{\mathrm{derivative\ projection}}
+
T_{\mathrm{rank}}.
\]

## 5.2 Fair direct G-only

\[
T_c^D
=
T_{G\text{-only},c}
+
T_{\mathrm{rank},c}.
\]

使用 Level-A 已认证的：

```text
stage8_k2_tcc_build_g_direct
```

作为诊断 benchmark 基线。

## 5.3 Proposed certified dictionary

\[
T_c^C
=
T_{\mathrm{lookup+assembly},c}
+
T_{\mathrm{rank},c}.
\]

`lookup+assembly` 必须包括：

- registered key/index guard；
- dictionary column read；
- pair column assembly；
- memory copy；
- cheap identity guard。

## 5.4 Ordinary cleanup

\[
\Delta T_{\mathrm{cleanup}}
=
\sum_c n_c(T_c^F-T_c^D).
\]

这是普通工程收益，不是 cache 创新。

## 5.5 Canonical dictionary incremental saving

\[
\Delta T_{\mathrm{cache}}
=
\sum_c n_c
\left(
T_{G\text{-only},c}
-
T_{\mathrm{lookup+assembly},c}
\right).
\]

rank / DML 为共同成本。

至少区分：

```text
SINGLE_REGISTERED
PAIR_REGISTERED
```

---

# 6. 当前 Level-A lookup 与 proposed O(B) dictionary 必须分开

严禁把当前：

```text
stage8_k2_tcc_lookup_exact
```

解释为未来 O(B) indexed dictionary。

当前 Level-A lookup 会重做完整 identity validation，并扫描 delta/el grids。

因此：

```text
CURRENT_LEVEL_A_LOOKUP
!=
PROPOSED_CERTIFIED_21_KEY_INDEXED_DICTIONARY
```

未来 diagnostic 21-key dictionary：

\[
D_M=[g(\omega_1),...,g(\omega_{21})].
\]

若 caller 已持有 integer index：

\[
D_M(:,i)
\]

raw read 为 \(O(B)\)。

必须同时测：

```text
RAW_INDEXED_21_KEY_LOOKUP
CERTIFIED_REGISTERED_ANGLE_TO_INDEX_LOOKUP
```

真正 cache 反事实优先使用后者。

---

# 7. 复杂度理论

固定 \(K\)：

\[
T_{\mathrm{direct}}
=
O(NB+B^2),
\qquad
T_{\mathrm{lookup}}
=
O(B).
\]

dictionary 构建：

\[
T_{\mathrm{build}}
=
O(21(NB+B^2)).
\]

dictionary memory：

\[
M_{\mathrm{dictionary}}
=
O(21B)
\]

complex numbers。

此结论只描述 column generation，不代表 rank/DML/whole estimator 同阶加速。

---

# 8. 有限集合全集认证规模

对每个 active `fixed_measurement_hash`：

## 8.1 21 singles

\[
21.
\]

## 8.2 231 canonical unordered K2 pairs including diagonal

\[
\binom{21+2-1}{2}
=
231
=
210+21.
\]

包括 210 distinct pairs 和 21 diagonal rank-deficient pairs。

## 8.3 441 ordered nested assemblies

\[
21\times21=441.
\]

231 用于 canonicalized K2 rank/score state universe。

441 用于 first/second-column / nested geometry contract。

---

# 9. 72-trial measurement identity 分组

当前 frozen registry：

```text
2 noise profiles × 3 L × 3 SNR × 4 profiles = 72
```

Tangent trial generator固定：

```text
PRIMARY_RECT_E14_A31
```

因此预期：

```text
2 fixed measurement identities × 36 trials
```

执行时必须从实际 trial model 收集：

```text
fixed_measurement_hash
measurement_config_id
noise_profile_id
```

验证 distinct hash count = 2，每个 36 trials。

否则：

```text
BLOCKED_MEASUREMENT_IDENTITY_SET_CHANGED
```

---

# 10. Pass 0 — Instrumentation Qualification

先使用：

```text
WHITE / L=8 / SNR=6 / P1-P4
```

四个 deterministic trials。

必须与 Audit start `aff3bb42df2b3d9b435cc57eacd3237826e7d87d` 比较：

```text
element_trial_hash
K1 center
K1 validity
fixed K2 candidate
fixed K2 loglik
direction_hat
metric rank/condition
rho_hat
raw Tangent validity/loglik
final angles
final RSS/loglik/rank
selected start/source
upgrade/fallback/reason
score_call_count
SVD_call_count
```

除 runtime / diagnostic metadata 外完全一致。

失败：

```text
BLOCKED_PROFILING_CHANGED_ESTIMATOR
```

---

# 11. Diagnostic instrumentation 边界

优先：

1. MATLAB profiler 做调用归因；
2. 现有 debug struct 加 additive 字段；
3. 少量显式 `tic/toc`；
4. 必要时 diagnostic helper。

不得改变：

```text
candidate order
strict >
tie behavior
sort
rank/SVD
solver
threshold
grid
selector
```

如修改 frozen core，只允许：

```text
diagnostic-only
additive
default behavior preserved
```

不要建设通用 logging framework。

---

# 12. TIMING_OFF / TIMING_STAGE

## TIMING_OFF

只记录 root wall-clock。

## TIMING_STAGE

同样 estimator，启用内部 stage timers。

每个 `trial k / repeat r` 必须把两个 timing mode 放进同一个配对块，使用同一 frozen trial data、measurement identity 与 timing configuration：

```text
trial k / repeat r:
    OFF -> STAGE
或
    STAGE -> OFF
```

配对顺序按冻结的 order seed 随机选择，并在 trial/repeat 层面对 AB/BA 做尽可能平衡的分配。

定义逐配对 instrumentation 扰动：

\[
\Delta T_{\mathrm{instr},k,r}
=
T_{\mathrm{root},k,r}^{\mathrm{STAGE}}
-
T_{\mathrm{root},k,r}^{\mathrm{OFF}}.
\]

必须报告 `paired median / min / max / p90`；不得用两个独立样本集合的 median 相减代替 paired statistic。

每轮同时随机化 72 trial 顺序，以降低 CPU 温度、MATLAB JIT、后台负载和时间漂移的影响。该差值仅用于判断 instrumentation 扰动，不做复杂微秒级校正。

## Timing protocol freeze

在产生任何 Pass C/D timed sample 前，必须冻结并 hash：

```text
repeat target
warm-up count/rule
trial-order seed
pair-order seed
AB/BA balance rule
timer implementation
summary quantile convention
conservative lower-bound formula
sensitivity envelope definition
```

`conservative lower-bound formula` 至少明确 point estimate、timing uncertainty、instrumentation perturbation 与 sensitivity envelope 如何组合。任何 timed result 产生后的规则变更都会使已有 timing/checkpoint 失效，必须按新 hash 重跑；不得 post hoc 选择有利规则。

---

# 13. Runtime stage hierarchy

顶层：

```text
ROOT_TANGENT_PROFILE_SAFE
├── K1_PUBLIC
├── K2_PUBLIC
├── TAIL_FULL_DATA
├── CENTER_MANIFOLD_DERIVATIVES
├── PROJECTED_DIRECTION
├── T4_PROFILE
├── FINAL_SAFE_SELECTOR
└── UNATTRIBUTED
```

K1：

```text
K1_CONTEXT
  K1_FULL_DATA
  K1_INITIALIZATION_TOTAL
    K1_INIT_CONVENTIONAL
    K1_INIT_GROUP_PREPARE
    K1_INIT_GROUP_Q1
    K1_INIT_GROUP_Q2

K1_CORE_LITE
  K1_FIXED_FIT
    K1_FIXED_START_BUILD
    K1_FIXED_REGISTERED_REFINEMENT
    K1_FIXED_FINAL_CERTIFICATION
  K1_CONTINUOUS
  K1_SELECTION
```

K2：

```text
K2_CONTEXT
  K2_FULL_DATA
  K2_INITIALIZATION_TOTAL
    K2_INIT_CONVENTIONAL
    K2_INIT_GROUP_PREPARE
    K2_INIT_GROUP_Q1
    K2_INIT_GROUP_Q2

K2_CORE_LITE
  K2_HELPER_K1
  K2_START_BUILD
    K2_NESTED_ANCHOR
  K2_REGISTERED_REFINEMENT
  K2_FINAL_CERTIFICATION
  K2_SELECTION
```

若低扰动拆分不可能，可合并相邻 stage，但报告：

```text
MERGED_FOR_LOW_INTRUSION_INSTRUMENTATION
```

不得伪造 exclusive time。

---

# 14. Inclusive / exclusive / reconciliation

\[
T_{\mathrm{exclusive}}(s)
=
T_{\mathrm{inclusive}}(s)
-
\sum_{\text{direct child }j}
T_{\mathrm{inclusive}}(j).
\]

逐 repetition：

\[
T_{\mathrm{root},r}
=
\sum_sT_{\mathrm{exclusive},s,r}
+
T_{\mathrm{unattributed},r}.
\]

定义 reconciliation error 并记录。

不得把各 stage median 相加重建 root median。

---

# 15. Pass A — Static Finite-Set Certification

每个 identity：

## A1 — 21 singles

比较：

```text
LEGACY_FULL_MANIFOLD
DIRECT_G_ONLY
DIAGNOSTIC_21_KEY_DICTIONARY
```

检查 key / G / relative error / finite / identity。

## A2 — 231 canonical pairs

比较 legacy/direct/dictionary：

```text
G
singular values
rank threshold
rank decision
column order
diagonal rank-deficiency
```

要求 rank mismatch = 0。

## A3 — 441 ordered nested assemblies

检查：

```text
first-column identity
second-column identity
ordered G
singular values
rank/full-rank set
geometric anchor inputs
```

不得在 A3 静态阶段宣称完整验证：

```text
initial RSS
nested_rss_pass
```

这两项依赖 observation，放 Pass B。

## 15.1 Frozen Level-A numerical contracts

直接继承 Level-A 现有测试合同，不在本阶段重新选择 tolerance：

```text
exact key error                <= 1e-11 deg
legacy vs direct G-only rel G  <= 1e-12
legacy vs direct G-only abs G  <= 1e-12 * scale_G
direct vs dictionary rel G     <= 1e-10
singular-value absolute error  <= 1e-10 * scale_sigma
rank-threshold difference      <= 1e-12
rank decision                  exact match
```

其中按现有 Level-A 测试定义：

\[
scale_G=\max\left(1,\max|G_{\mathrm{reference}}|\right),
\]

\[
scale_\sigma=\max\left(1,\max|\sigma_{\mathrm{reference}}|\right).
\]

Nested first-column 继续执行生产代码现有合同：

```matlab
e_col <= 64 * eps(max(size(G)))
```

其 machine-epsilon 尺度上界记为：

\[
e_{\rm col}
\le
64\,\epsilon_{\rm mach}\cdot\max(\operatorname{size}G).
\]

认证必须分成两层：

1. 连续数值量按上述冻结 tolerance；
2. 离散决策量必须 exact match。

离散决策量至少包括：

```text
rank
tie set
best index
accepted update
trajectory
selected start
nested pass
final selector
```

即使 `G` error 很小，也不得用连续误差通过掩盖搜索路径或最终选择发生变化。

---

# 16. Rank stability 辅助理论

当前：

\[
\tau(G)=\alpha\sigma_1(G),
\]

\[
\alpha=
rankMultiplier\cdot\max(size(G))\cdot\epsilon_{\rm mach}.
\]

若：

\[
\widetilde G=G+E,
\]

则：

\[
\left|
(\widetilde\sigma_i-\widetilde\tau)
-
(\sigma_i-\tau)
\right|
\le
(1+\alpha)\|E\|_2.
\]

可报告 margin/bound，但 hard certification 仍是 231/231 rank match。

---

# 17. Pass B — 72-Trial Query & Trajectory Audit

72/72 各运行一次带 logger 的**原始 direct estimator**。

不要在该 Pass 做 absolute runtime。

按 `trial × stage` 记录：

```text
manifold_build_count
requested_column_count
dml_score_count
derivatives_required_count

single_count
pair_count

registered_exact_column_count
off_grid_column_count

unique_registered_key_count
reuse_multiplicity

pair_exact_count
pair_off_grid_count
diagonal_pair_count
```

定义：

\[
R=
N_{\mathrm{requested\ registered\ columns}}
/
N_{\mathrm{unique\ registered\ keys}}.
\]

记录 21-bin key histogram，避免逐 query 大 trace 入 Git。

至少区分：

```text
CONVENTIONAL_SINGLETON
K1_FIXED_REFINEMENT
K1_FIXED_FINAL_CERT
K1_CONTINUOUS
K2_HELPER_K1
K2_NESTED_ANCHOR
K2_REGISTERED_REFINEMENT
K2_FINAL_CERT
CENTER_MANIFOLD_DERIVATIVES
T4_PROFILE
```

grouped Q1/Q2：

```text
CURRENT_TCC_MODEL_INCOMPATIBLE
```

每次 full sequential call 分类：

```text
DERIVATIVES_REQUIRED
G_ONLY_ELIGIBLE
```

---

# 18. Shadow dictionary replay

production estimator 继续 direct。

dictionary 只 shadow replay，禁止影响任何决定。

逐 candidate group 比较：

```text
direct score vector
shadow score vector
direct rank vector
shadow rank vector
tie set
best index
accepted update
sweep trajectory
```

若：

\[
\widetilde s_i=s_i+e_i,\ |e_i|\le\epsilon_i,
\]

排序充分条件：

\[
s_i-s_j>\epsilon_i+\epsilon_j.
\]

但 hard contract 是实际 trajectory match。

72/72 要求：

```text
key mismatch              = 0
rank mismatch             = 0
candidate-order mismatch  = 0
tie-set mismatch          = 0
best-index mismatch       = 0
accepted-update mismatch  = 0
trajectory mismatch       = 0
selected-start mismatch   = 0
final-selector mismatch   = 0
```

---

# 19. Nested dynamic replay

72 trials 动态验证：

```text
helper K1 angle
selected nested anchor
initial nested G
initial RSS
K1 RSS
nested RSS tolerance
nested_rss_pass
first-column error
anchor metric distance
```

要求所有 executed nested cases：

```text
selected anchor match
nested_rss_pass match
```

---

# 20. Helper-K1 structural reuse certification

必须比较：

```text
PUBLIC_K1_FIXED_SUBFIT
vs.
K2_INTERNAL_HELPER_K1
```

不是 public K1 final selected。

比较：

```text
angles
G
RSS
sigma2
loglik
rank
selected start
fixed_measurement_hash
local_domain_hash
observation_hash
initialization identity
```

72/72 全一致才允许 Pass E 使用：

```text
CERTIFIED_K1_FIXED_HELPER_REUSE
```

否则从 structural counterfactual 排除。

---

# 21. Pass C — 72-Trial Runtime Decomposition

query logger 关闭。

覆盖 72/72。

目标：

```text
20 timed repeats per trial
```

每个 trial warm-up。

若 repeats < 10：

- 不报告可靠 p90；
- 报 median/min/max；
- 标：

```text
RUNTIME_REPEATS_BELOW_P90_TARGET
```

每个 repeat round 随机或 block-randomize 72 trial 顺序，固定 order seed，不改变 trial source/noise seed。

每个 `trial × repeat` 按第 12 节形成一个 OFF/STAGE 配对块；AB/BA 顺序必须平衡。两个 mode 都应在正式计时前完成对应 warm-up。

每个 trial 分别统计 OFF 与 STAGE 的 `median/p90/min/max`，并对逐配对的

\[
\Delta T_{\mathrm{instr},k,r}
\]

统计 `paired median/p90/min/max`。不得以 `median(STAGE)-median(OFF)` 代替配对差值汇总。

每 repetition 先算：

\[
share_{s,r,k}
=
T_{s,r,k}/T_{\mathrm{root},r,k}.
\]

再汇总 share。

二级汇总：

```text
trial
noise identity
L
SNR
profile
overall 72-trial distribution
```

不得把所有 1440 repeats 混为一个同质总体 p90。

---

# 22. Pass D — Microbenchmark

50–100 repeats，warm-up 后：

```text
LEGACY_FULL_SINGLE
LEGACY_FULL_PAIR

DIRECT_G_ONLY_SINGLE
DIRECT_G_ONLY_PAIR

RANK_SINGLE
RANK_PAIR

IDENTITY_FULL_VALIDATE

CURRENT_LEVEL_A_LOOKUP_SINGLE
CURRENT_LEVEL_A_LOOKUP_PAIR

RAW_INDEXED_21_KEY_LOOKUP_SINGLE
RAW_INDEXED_21_KEY_LOOKUP_PAIR

CERTIFIED_REGISTERED_LOOKUP_SINGLE
CERTIFIED_REGISTERED_LOOKUP_PAIR

21_KEY_BUILD
PROVIDER_SETUP
```

`CERTIFIED_REGISTERED_LOOKUP` 必须包含：

```text
registered key mapping
cheap identity guard
column read
pair assembly
```

不能只测数组切片。

若创建 diagnostic `.mat`，可测：

```text
DIAGNOSTIC_21_KEY_ARTIFACT_LOAD
```

不能称 production load time。

否则：

```text
LOAD_NOT_MEASURED_NO_PERSISTENT_DICTIONARY_FORMAT
```

---

# 23. Diagnostic 21-key dictionary

只用于：

```text
static certification
shadow replay
microbenchmark
counterfactual
```

不得接 production estimator。

每个 identity：

\[
D_M=[g(\omega_1),...,g(\omega_{21})].
\]

绑定：

```text
fixed_measurement_hash
measurement_config_id
noise_profile_id
phase_factor
lambda
W_hash
T_hash
element order
measurement center
registered az/el grids
key table
numeric class
```

一次：

```text
VALIDATE_ONCE
```

之后 diagnostic lookup 仅 cheap guard。

---

# 24. Pass E — 顺序反事实

本阶段不实现优化。

因此必须：

\[
\widehat T_S,\quad
\widehat T_{SG},\quad
\widehat T_{SGC}.
\]

所有结果标：

```text
COUNTERFACTUAL_ESTIMATE_NOT_INTEGRATED_RUNTIME
```

Baseline：

\[
T_0
\]

是真实 measured runtime。

Structural 顺序：

```text
S1 full_data reuse
S2 initialization-context reuse
S3 certified K1 fixed/helper reuse
```

S2 必须先证明 K1/K2 initialization identity/output 等价。

S3 只有 Pass B 认证后可用。

得到：

\[
\widehat T_S.
\]

然后仅对 remaining `G_ONLY_ELIGIBLE` calls 使用 direct G-only benchmark，得到：

\[
\widehat T_{SG}.
\]

再仅对：

```text
G_ONLY_ELIGIBLE
REGISTERED_EXACT
MODEL_COMPATIBLE
```

使用 certified dictionary benchmark，得到：

\[
\widehat T_{SGC}.
\]

---

# 25. 条件增量

\[
\widehat{\Delta T}_S
=
T_0-\widehat T_S,
\]

\[
\widehat{\Delta T}_{G|S}
=
\widehat T_S-\widehat T_{SG},
\]

\[
\widehat{\Delta T}_{C|S,G}
=
\widehat T_{SG}-\widehat T_{SGC}.
\]

总 modeled reduction：

\[
T_0-\widehat T_{SGC}
=
\widehat{\Delta T}_S
+
\widehat{\Delta T}_{G|S}
+
\widehat{\Delta T}_{C|S,G}.
\]

禁止把几个“相对 original baseline”的收益直接相加。

---

# 26. Lifecycle economics

每个 identity \(m\)：

\[
C_{0,m}
=
T_{\mathrm{build},m}
+
T_{\mathrm{load},m}
+
T_{\mathrm{validate-once},m}
+
T_{\mathrm{setup},m}.
\]

若 load 未测，不得暗设为 0。

Build-inclusive：

\[
NetSaving_m^{build}
=
\sum_r
\widehat{\Delta T}_{C|S,G,r}
-
C_{0,m}.
\]

Online-only 若 offline-prebuilt：

\[
C_{online,m}
=
T_{\mathrm{load}}
+
T_{\mathrm{validate-once}}
+
T_{\mathrm{setup}},
\]

\[
NetSaving_m^{online}
=
\sum_r
\widehat{\Delta T}_{C|S,G,r}
-
C_{online,m}.
\]

若：

\[
\bar{\Delta T}_m>0,
\]

\[
N_{\mathrm{BE},m}
=
\left\lceil
C_{0,m}/\bar{\Delta T}_m
\right\rceil.
\]

否则 \(N_{\mathrm{BE},m}=\infty\)。

没有实际 deployment horizon \(H\) 时，不输出经济 PASS/FAIL。

---

# 27. Hard certification 与经济指标

Hard：

```text
G1 MODEL_COMPATIBILITY
G2 EXACT_KEY_COMPATIBILITY
G5 NUMERICAL_TRAJECTORY_PRESERVATION
```

经济指标：

```text
G3 RUNTIME_RELEVANCE
G4 LIFECYCLE_ECONOMICS
```

G3/G4 不设人为百分比 Gate。

---

# 28. Pass F — Innovation Attribution

只输出 predicted/counterfactual 2×2。

Core-Lite 定义：

```text
estimate_stage8_known_k_local_cell(
  ..., K=2, mode='CORE_LITE')
```

Tangent-safe：

```text
stage8_k2_tp_fit_safe(...)
```

四个 cell 必须全部在：

```text
STRUCTURAL_REUSED
+
FAIR_G_ONLY
```

条件层级。

| Pipeline | Direct G-only | Dictionary |
|---|---:|---:|
| Core-Lite | \(\widehat T_{CD}\) | \(\widehat T_{CC}\) |
| Tangent-safe | \(\widehat T_{TD}\) | \(\widehat T_{TC}\) |

\[
\Delta_{\mathrm{Core}}
=
\widehat T_{CD}-\widehat T_{CC},
\]

\[
\Delta_{\mathrm{Tangent}}
=
\widehat T_{TD}-\widehat T_{TC},
\]

\[
I=
\Delta_{\mathrm{Tangent}}
-
\Delta_{\mathrm{Core}}.
\]

命名：

```text
PREDICTED_DIFFERENCE_IN_DIFFERENCES_INTERACTION
```

不能称 causal synergy。

---

# 29. Exposure-adjusted residual

每类 eligible query：

\[
\delta_c=d_c-l_c.
\]

Tangent-safe exposure：

\[
n_{T,c}.
\]

本 Placement Audit 没有把 dictionary 实际集成进 Tangent-safe runtime，因此当前阶段只计算 exposure prediction：

\[
\widehat{\Delta T}_{\mathrm{exposure},T}
=
\sum_c n_{T,c}\delta_c.
\]

当前阶段必须冻结：

```text
exposure_adjusted_residual_JT = NaN
JT_status = NOT_AVAILABLE_PRE_INTEGRATION
```

不得用两个同源 counterfactual/model-derived 量之差构造一个看似 measured 的 `J_T`。

只有未来把 dictionary 实际集成并完成 measured 2×2 后，才允许定义：

\[
J_T^{\mathrm{measured}}
=
\Delta T_{\mathrm{Tangent}}^{\mathrm{measured}}
-
\sum_c n_{T,c}\delta_c.
\]

即使未来 \(J_T^{\mathrm{measured}}\neq0\)，也只能命名为：

```text
EXPOSURE_ADJUSTED_RUNTIME_RESIDUAL
```

不得称 causal synergy。

非零可能来自：

```text
in-context vs microbenchmark
memory locality
allocation
JIT
counterfactual error
batching
```

真正 measured 2×2 与 measured Tangent-specific residual 留给 future integration。

---

# 30. Truth isolation

truth 不得进入：

```text
dictionary key
query classification
shadow decision
placement choice
cache eligibility
counterfactual timing
nested selection
coordinate update
safe selector
```

记录：

```text
truth_used_in_fit_flag = false
cache_truth_used_flag = false
placement_truth_used_flag = false
```

---

# 31. 不重新做统计性能实验

72 frozen trials 仅用于：

```text
runtime
query
trajectory
identity
```

不新增：

```text
classical methods
new Monte Carlo seeds
new SNR
new profiles
new model order
new calibration
```

如果 2×2 attribution 需要 Core-Lite，只运行 K2 CORE_LITE runtime attribution，不形成新的算法精度竞争结论。

---

# 32. 结果文件最小集

提交：

```text
innovation-mining/

52_stage8_k2_tangent_pipeline_cache_placement_audit.md
52_stage8_k2_tangent_pipeline_cache_static_certification.csv
52_stage8_k2_tangent_pipeline_cache_query_audit.csv
52_stage8_k2_tangent_pipeline_runtime_summary.csv
52_stage8_k2_tangent_pipeline_cache_economics.csv
52_stage8_k2_tangent_pipeline_cache_placement_manifest.json
```

仓库外：

```text
raw timing
query/trajectory trace
profiler data
optional diagnostic MAT
microbenchmark raw samples
checkpoint/resume state
```

Git 中只提交本节列出的最终或聚合 summary/evidence；raw timing、trajectory、profiler、microbenchmark samples 与 checkpoint 必须留在仓库外 runtime 目录。不要提交大型 raw trace。

---

# 33. Static certification CSV

至少：

```text
measurement_identity
case_type
case_id
angle1_az
angle1_el
angle2_az
angle2_el
key1
key2
exact_key_error_deg
legacy_vs_direct_G_rel_error
legacy_vs_direct_G_abs_error
direct_vs_dictionary_G_rel_error
direct_vs_dictionary_G_abs_error
singular_value_abs_error
sigma1_direct
sigma2_direct
sigma1_dictionary
sigma2_dictionary
rank_threshold_direct
rank_threshold_dictionary
rank_threshold_abs_difference
rank_direct
rank_dictionary
rank_match
first_column_rel_error
second_column_rel_error
continuous_numeric_pass
discrete_decision_pass
static_pass
failure_reason
```

`case_type`：

```text
SINGLE
CANONICAL_PAIR
ORDERED_NESTED
```

---

# 34. Query audit CSV

每 `trial × stage` 一行：

```text
trial_id
noise_profile_id
L
snr_db
profile_id
fixed_measurement_hash
stage_id
manifold_build_count
requested_column_count
dml_score_count
derivatives_required_count
single_count
pair_count
registered_exact_column_count
off_grid_column_count
unique_registered_key_count
reuse_multiplicity
diagonal_pair_count
key_mismatch_count
rank_mismatch_count
candidate_order_mismatch_count
tie_mismatch_count
best_index_mismatch_count
accepted_update_mismatch_count
trajectory_mismatch_count
selected_start_mismatch_count
nested_pass_mismatch_count
final_selector_mismatch_count
```

21-bin histogram可追加字段或紧凑 JSON string。

---

# 35. Runtime summary

仓库只提交 summary。

仓库外 raw timing 每个最小单元至少记录：

```text
trial_id
fixed_measurement_hash
repeat_index
pair_block_id
runtime_session_id
pair_order
timing_mode
root_runtime_sec
stage_runtime_sec_or_NaN
unit_complete
paired_block_complete
paired_block_contiguous
```

只有 `paired_block_complete = true` 且 `paired_block_contiguous = true` 的 OFF/STAGE pair 才进入 instrumentation overhead 汇总。

至少：

```text
trial_id
fixed_measurement_hash
noise_profile_id
L
snr_db
profile_id
timing_mode
stage_id
repeat_count
median_runtime_sec
p90_runtime_sec
min_runtime_sec
max_runtime_sec
median_stage_share
p90_stage_share
min_stage_share
max_stage_share
median_unattributed_sec
median_reconciliation_error_sec
pair_order_ab_count
pair_order_ba_count
paired_repeat_count
paired_instrumentation_overhead_median_sec
paired_instrumentation_overhead_p90_sec
paired_instrumentation_overhead_min_sec
paired_instrumentation_overhead_max_sec
```

repeats < 10 时 p90 = NaN。

---

# 36. Economics schema

至少：

```text
fixed_measurement_hash
pipeline
scenario_aggregate
measured_T0
predicted_TS
predicted_TSG
predicted_TSGC
predicted_delta_structural
predicted_delta_g_only_given_structural
predicted_delta_cache_given_structural_g_only
predicted_delta_cache_point_sec
conservative_timing_sensitivity_lower_bound_sec
all_measurement_identities_nonnegative
end_to_end_saving_percentage
cache_build_sec
cache_load_sec
cache_validate_once_sec
cache_setup_sec
online_only_break_even
build_inclusive_break_even
requested_columns
unique_keys
reuse_multiplicity
predicted_core_lite_direct
predicted_core_lite_dictionary
predicted_tangent_direct
predicted_tangent_dictionary
predicted_delta_core
predicted_delta_tangent
predicted_did_interaction_I
predicted_delta_tangent_exposure
exposure_adjusted_residual_JT
JT_status
predicted_performance_status
economics_status
```

---

# 37. Manifest

至少：

```text
branch
level_a_closure_commit
audit_start_commit
audit_final_commit
audit_code_hash
registry_hash
timing_configuration_hash
theory_status
performance_status
MATLAB_release
single_comp_thread
trial_count
timed_repeat_target
timed_repeat_actual_min
measurement_identity_count
registered_single_count
canonical_pair_count
ordered_nested_count
static_pass_count
query_audit_pass_count
key_mismatch_total
rank_mismatch_total
candidate_order_mismatch_total
tie_mismatch_total
best_index_mismatch_total
accepted_update_mismatch_total
trajectory_mismatch_total
selected_start_mismatch_total
nested_pass_mismatch_total
final_selector_mismatch_total
truth_leakage_count
classical_baseline_rerun
full_new_monte_carlo
level_b_interpolation
fixed_path_dictionary_integrated
context_reuse_integrated
g_only_integrated
technical_certification_status
predicted_performance_status
deployment_status
recommended_next_action
```

必须：

```text
level_a_closure_commit = cf35e37a74366a8d9829de3a1f8b740a788bade1
audit_start_commit = aff3bb42df2b3d9b435cc57eacd3237826e7d87d
classical_baseline_rerun = false
full_new_monte_carlo = false
level_b_interpolation = false
fixed_path_dictionary_integrated = false
context_reuse_integrated = false
g_only_integrated = false
truth_leakage_count = 0
```

---

# 38. 最终状态层级

技术状态本阶段最多：

```text
TECHNICALLY_CERTIFIED
```

当性能判读已成立时，`predicted_performance_status` 必须且只能取以下三级之一：

```text
PREDICTED_SAVING_ROBUST_POSITIVE
PREDICTED_SAVING_INCONCLUSIVE
PREDICTED_SAVING_NONPOSITIVE
```

上述三级互斥分类只在 correctness contracts 通过且 Pass E/F 已完成时适用。若第 41 节 hard stop 使性能判读未发生，则 `predicted_performance_status = null` 并报告对应 `BLOCKED_*`；不得把缺失证据强行归入三级之一。`null` 是未判读状态，不是第四个 performance conclusion。

按以下优先顺序分类，避免状态重叠。

## PREDICTED_SAVING_NONPOSITIVE

任一成立：

```text
point estimate Delta_cache|S,G <= 0
certified lookup is not faster than direct G-only for the eligible workload
```

## PREDICTED_SAVING_ROBUST_POSITIVE

仅当以下条件同时成立：

```text
G1 / G2 / G5 hard certification 全部通过
point estimate Delta_cache|S,G > 0
conservative timing/sensitivity lower bound > 0
每个 measurement identity 的 Delta_cache|S,G >= 0
```

lower bound 必须来自预先冻结的 paired timing 与 sensitivity 规则，并在结果中报告计算方法；不得在看到结果后修改规则。

## PREDICTED_SAVING_INCONCLUSIVE

未落入 `NONPOSITIVE`，但未满足 `ROBUST_POSITIVE` 的任一情况，包括：

```text
point estimate > 0 but lower bound <= 0
timing/sensitivity uncertainty envelope 覆盖 0（等价于 lower bound <= 0）
存在 measurement identity 为负
其他 robustness 条件未满足
```

只有 `PREDICTED_SAVING_ROBUST_POSITIVE` 才允许建议进入 integration study。

未来实际 integration 并完成 measured runtime 后才允许：

```text
PERFORMANCE_VALIDATED
```

有 workload horizon \(H\) 后才允许：

```text
DEPLOYMENT_JUSTIFIED
```

没有 \(H\)：

```text
DEPLOYMENT_STATUS
NOT_ASSESSED_NO_WORKLOAD_HORIZON
```

且不得输出 `DEPLOYMENT_JUSTIFIED`。此时只报告：

```text
absolute saving in milliseconds
end-to-end saving percentage
NetSaving(N) curve/table
```

---

# 39. Placement decision taxonomy

允许：

```text
CACHE_PLACEMENT_K1_FIXED_PREDICTED
CACHE_PLACEMENT_K2_REGISTERED_REFINEMENT_PREDICTED
CACHE_PLACEMENT_FIXED_K1_K2_SHARED_DICTIONARY_PREDICTED
CACHE_PLACEMENT_NESTED_REGISTERED_PREDICTED
MULTIPLE_CACHE_PLACEMENT_CANDIDATES

DIRECT_G_ONLY_MANIFOLD_CLEANUP_DOMINATES
CONTEXT_REUSE_DOMINATES_RUNTIME
K1_FIXED_HELPER_REUSE_DOMINATES_STRUCTURAL_COST
GROUPED_INITIALIZATION_DOMINATES_TCC_INCOMPATIBLE
CACHE_LIFECYCLE_BREAK_EVEN_UNFAVORABLE
NO_MATERIAL_TCC_PLACEMENT
```

如多个 candidate 成立，必须给优先级，不授权一次集成全部。

---

# 40. Integration 推荐条件

只有：

```text
TECHNICALLY_CERTIFIED
```

且：

```text
PREDICTED_SAVING_ROBUST_POSITIVE
```

同时成立，才允许最终建议：

```text
RECOMMEND_FIXED_PATH_DICTIONARY_INTEGRATION
```

但本阶段不得真正 integration。

---

# 41. Hard stop

任一发生即停止：

```text
BLOCKED_DIRTY_WORKTREE
BLOCKED_LEVEL_A_ANCHOR_NOT_ANCESTOR
BLOCKED_AUDIT_START_NOT_ANCESTOR
BLOCKED_POST_AUDIT_START_UNKNOWN_SOURCE_CHANGES
BLOCKED_REGISTERED_CLOSURE_CONTRACT_CHANGED
BLOCKED_MEASUREMENT_IDENTITY_SET_CHANGED
BLOCKED_PROFILING_CHANGED_ESTIMATOR
BLOCKED_STATIC_SINGLE_EQUIVALENCE_FAILED
BLOCKED_STATIC_PAIR_EQUIVALENCE_FAILED
BLOCKED_STATIC_RANK_EQUIVALENCE_FAILED
BLOCKED_REGISTERED_FIXED_QUERY_OFF_GRID
BLOCKED_TRAJECTORY_MISMATCH
BLOCKED_NESTED_CONTRACT_MISMATCH
BLOCKED_TRUTH_LEAKAGE
BLOCKED_RUNTIME_UNAVAILABLE
```

不得通过放宽 tolerance、改 rank、改 tie、改 grid、插值等规避。

---

# 42. Runtime 环境

```text
MATLAB R2022b
-singleCompThread
```

大型 runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_tangent_pipeline_cache_placement_audit
```

## 42.1 Checkpoint / resume contract

`72 trials × 20 repeats × 2 timing modes` 可能运行数小时，必须支持细粒度 checkpoint/resume。

最小工作单元键冻结为：

```text
pass
measurement_identity
trial_id
repeat_index
timing_mode
```

不适用的维度显式写 `NOT_APPLICABLE`，不得通过省略字段产生不同键语义。对 Pass C，OFF 与 STAGE 各自完成后写入对应单元；只有两个 mode 在同一 MATLAB runtime session 中按冻结顺序连续完成时，该 paired block 才可用于 paired statistic。

若进程在 pair 的两个 mode 之间中断，保留已完成 mode 仅供诊断，但恢复时必须重跑整个 pair；不得把重启前后的两个 mode 拼成 paired sample。

每完成一个最小单元，在上述仓库外 runtime 目录原子写入 checkpoint：先写同一文件系统中的临时文件，完整 flush/close 后再 rename/replace 为目标文件。不得把半写入文件视为完成单元。

恢复前必须逐项匹配：

```text
Level-A closure commit
Audit start commit
audit code hash
registry hash
measurement identity
MATLAB release
singleCompThread
timing configuration
```

`timing configuration` 至少覆盖 repeat target、warm-up、order seed、AB/BA 规则、timer implementation、stage schema、summary quantile convention、conservative lower-bound formula 与 sensitivity envelope，并记录为稳定 hash。

任何字段缺失或不匹配，都不得复用旧 checkpoint。恢复只能跳过已原子完成且 metadata 验证通过的最小单元；不得把部分结果补写成完整结果。

checkpoint、raw timing 和 trajectory 继续留在 runtime 目录；Git 只保存第 32 节定义的最终/聚合 summary 与 manifest。

---

# 43. Pass 顺序

严格：

```text
Pass 0 Instrumentation Qualification
Pass A Static Finite-Set Certification
Pass B 72-Trial Query & Trajectory Audit
Pass C 72-Trial Runtime Decomposition
Pass D Microbenchmark
Pass E Sequential Counterfactual + Lifecycle
Pass F Innovation Attribution + Placement Decision
```

correctness 失败，不进入 performance interpretation。

---

# 44. Git 修改范围

优先新增：

```text
tools/stage8_k2_tangent_canonical_cache/
```

中的 audit runner / dictionary / certification / economics helpers。

允许最小修改：

```text
tools/stage8_k2_tangent_profile/
```

若必要，可对以下 frozen core 仅做 additive diagnostic instrumentation：

```text
estimate_stage8_known_k_local_cell.m
fit_stage8_core_lite.m
fit_local_model_k.m
build_stage8_known_k_local_context.m
build_stage8_initialization_context_from_data.m
build_k2_initializations.m
refine_joint_sequential_dml.m
```

不得重构数学核心。

---

# 45. Level-A 文件保护

不要重写 `51_*` Level-A evidence。

50 架构文档如需增加 post-Level-A note，只做最小追加。

优先新增 52 系列。

---

# 46. Git commit 建议

建议：

```text
test(stage8-k2): instrument tangent pipeline placement audit

test(stage8-k2): audit registered dictionary compatibility

perf(stage8-k2): profile tangent pipeline cache placement
```

允许必要修复提交，不要碎片化。

---

# 47. 推送前检查

```bash
git diff --check
git status --short
git diff --stat aff3bb42df2b3d9b435cc57eacd3237826e7d87d...HEAD
git diff --name-only aff3bb42df2b3d9b435cc57eacd3237826e7d87d...HEAD
git fetch origin --prune
```

确认 main / tangent / old architecture branch 未修改。

推送：

```bash
git push origin experiment/stage8-k2-tangent-canonical-cache-v1
```

禁止 force push。

---

# 48. 最终必须回答 Q1–Q8b

```text
Q1 72 trials 中 Tangent-safe runtime 花在哪里？
Q2 full_data / initialization / helper K1 重复成本是多少？
Q3 fixed registered K1/K2 有多少 manifold builds / columns / DML scores？
Q4 21-key reuse multiplicity 是多少？
Q5 structural + fair G-only 后 dictionary 条件增量的 point estimate 与 conservative lower bound 是否均为正？
Q6 每 identity 的 online/build-inclusive lifecycle 和 break-even 如何？
Q7 predicted_performance_status 属于 PREDICTED_SAVING_ROBUST_POSITIVE / PREDICTED_SAVING_INCONCLUSIVE / PREDICTED_SAVING_NONPOSITIVE 中哪一级，逐项依据是什么？
Q8a 当前 predicted saving 如何由各类 eligible query exposure 构成？
Q8b measured Tangent-specific residual 是多少？
    -> DEFERRED_TO_INTEGRATION；当前 JT_status = NOT_AVAILABLE_PRE_INTEGRATION
```

---

# 49. 最终回复格式

## A. Git

```text
Repository
Branch
Level-A closure commit
Audit start commit
Final HEAD
Push
Worktree
```

## B. Theory

```text
Omega size
single universe
canonical pair universe
ordered nested universe
measurement identity count
trials per identity
registered closure
```

## C. Static certification

```text
singles passed
pairs passed
ordered nested passed
max legacy-vs-direct G relative error
max legacy-vs-direct G absolute error
max direct-vs-dictionary G relative error
max singular-value diff
max exact-key error
max rank-threshold difference
rank mismatch
first/second-column identity mismatch
continuous numeric certification status
discrete decision certification status
```

## D. 72-trial trajectory

```text
key mismatch
rank mismatch
candidate-order mismatch
tie mismatch
best-index mismatch
accepted-update mismatch
trajectory mismatch
selected-start mismatch
nested-pass mismatch
final-selector mismatch
```

## E. Query reuse

按 stage：

```text
manifold builds
requested columns
unique keys
reuse multiplicity
registered exact fraction
```

## F. Runtime decomposition

```text
K1 public share
K2 public share
initialization share
fixed registered refinement share
continuous K1 share
center/derivative share
T4 share
unattributed share
paired instrumentation overhead median/p90/min/max
```

并说明 Level-A P1 `T4 ≈ 0.54%` 是否在 72-trial 中具有代表性。

## G. Microbenchmark

完整报告 full / G-only / rank / Level-A lookup / 21-key lookup / build / setup。

## H. Counterfactual

```text
T0
predicted TS
predicted TSG
predicted TSGC
delta structural
delta G-only | structural
delta cache | structural,G-only
```

全部标：

```text
COUNTERFACTUAL_ESTIMATE_NOT_INTEGRATED_RUNTIME
```

## I. Lifecycle

每 identity：

```text
build-inclusive break-even
online-only break-even
absolute saving in milliseconds
end-to-end saving percentage
NetSaving curve/table
```

## J. Attribution

```text
predicted Core-Lite direct/dictionary
predicted Tangent-safe direct/dictionary
predicted Delta Core
predicted Delta Tangent
predicted I
per-class n_T,c / delta_c / n_T,c * delta_c
predicted Delta Tangent exposure = sum_c n_T,c * delta_c
exposure_adjusted_residual_JT = NaN
JT_status = NOT_AVAILABLE_PRE_INTEGRATION
```

明确 `J_T` 在 pre-integration 阶段不可用；future measured residual 也不得称 causal synergy。

## K. Decision

给出：

```text
TECHNICALLY_CERTIFIED / failure
point estimate Delta_cache|S,G
conservative timing/sensitivity lower bound
minimum per-identity Delta_cache|S,G
certified lookup vs direct G-only
PREDICTED_SAVING_ROBUST_POSITIVE / PREDICTED_SAVING_INCONCLUSIVE / PREDICTED_SAVING_NONPOSITIVE
recommended placement
recommended next action
```

---

# 50. Audit 完成状态

若 correctness contracts 全部通过：

```text
STAGE8_K2_TANGENT_PIPELINE_CACHE_PLACEMENT_AUDIT_COMPLETE
```

该状态只表示 audit complete，不表示：

```text
dictionary integrated
measured speedup validated
deployment justified
```

---

# 51. 最终未执行范围

必须明确：

```text
NO_NEW_BRANCH
NO_LEVEL_B_INTERPOLATION
NO_NEAREST_NEIGHBOR
NO_FIXED_PATH_DICTIONARY_INTEGRATION
NO_CONTEXT_REUSE_INTEGRATION
NO_G_ONLY_PRODUCTION_REPLACEMENT
NO_TANGENT_RECALIBRATION
NO_CLASSICAL_BASELINE_RERUN
NO_NEW_MONTE_CARLO_PROTOCOL
NO_FPGA_CACHE_MAPPING
NO_PARENT_BRANCH_MERGE
NO_PR_CREATED
NO_FORCE_PUSH
```

---

# 52. 最终研究原则

允许最终得到：

```text
NO_MATERIAL_TCC_PLACEMENT
```

允许：

```text
CONTEXT_REUSE_DOMINATES_RUNTIME
DIRECT_G_ONLY_MANIFOLD_CLEANUP_DOMINATES
GROUPED_INITIALIZATION_DOMINATES_TCC_INCOMPATIBLE
```

不要为了延续 cache 路线而改变算法。

真正要验证的是：

\[
\boxed{
\text{在公平 structural + G-only 条件基线下，}
\widehat{\Delta T}_{C|S,G}
\text{ 是否满足冻结的 PREDICTED\_SAVING\_ROBUST\_POSITIVE 判据。}
}
\]

只有 `predicted_performance_status = PREDICTED_SAVING_ROBUST_POSITIVE`，才允许建议下一阶段开展 fixed registered-path dictionary integration study；本提示词仍不授权当前阶段 integration。

除硬停止条件外，Codex 不要只输出计划，必须完成本 Audit、测试、结果归档、提交和非 force-push 推送。
