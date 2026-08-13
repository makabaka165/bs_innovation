# Stage8 K2 Tangent Fixed-Backbone Exact Cache Integration & Runtime Validation

> **Codex 完整执行提示词**
>
> 目标：在不改变 `TANGENT_PROFILE_SAFE` 数学算法、阈值、搜索节点、更新顺序、DML 目标函数和最终安全选择器的前提下，把已经认证的 21-key exact registered-manifold dictionary 接入真正具有高复用率的 K1/K2 fixed registered backbone，并用严格的三路对照测量 cache 的独立运行时贡献。
>
> 本阶段不是继续把 cache 接到连续 T4；不是插值；不是 nearest-neighbor；不是重新设计 Tangent；不是 C2–C7 多层缓存扩张。

---

## 0. Repository、基线和新分支

### 0.1 Repository

```text
Repository:
makabaka165/bs_innovation
```

本地典型路径：

```text
E:\bs_innovation
```

### 0.2 基线分支与固定起点

当前已完成 exact-cache-stack 负收益验证的分支：

```text
experiment/stage8-k2-tangent-canonical-cache-v1
```

本阶段固定起点：

```text
BASELINE_COMMIT
b4424c6d87511ecf8034a61bc5384ba347cb2467
```

该提交语义：

```text
perf(stage8-k2): validate exact cache stack runtime and evidence
```

必须验证：

```bash
git fetch origin --prune
git rev-parse origin/experiment/stage8-k2-tangent-canonical-cache-v1
```

预期：

```text
b4424c6d87511ecf8034a61bc5384ba347cb2467
```

如果远端已前移，先审计：

```bash
git log --oneline --decorate b4424c6d87511ecf8034a61bc5384ba347cb2467..origin/experiment/stage8-k2-tangent-canonical-cache-v1
git diff --stat b4424c6d87511ecf8034a61bc5384ba347cb2467..origin/experiment/stage8-k2-tangent-canonical-cache-v1
```

若包含未知算法修改：

```text
BLOCKED_BASELINE_BRANCH_DRIFT
```

### 0.3 创建独立实验分支

当前 `experiment/stage8-k2-tangent-canonical-cache-v1` 已经完成并冻结为“当前 T4 exact cache 非正收益”的历史结论，不得改写其语义。

从 `b4424c6...` 创建：

```text
experiment/stage8-k2-tangent-fixed-backbone-cache-v1
```

命令：

```bash
git switch --detach b4424c6d87511ecf8034a61bc5384ba347cb2467
git switch -c experiment/stage8-k2-tangent-fixed-backbone-cache-v1
```

不得：

- 修改 `main`；
- 修改 `experiment/stage8-k2-tangent`；
- 改写旧 canonical-cache 分支历史；
- rebase / amend 已完成提交；
- force-push；
- merge；
- 创建 PR，除非用户之后单独授权。

---

# 1. 必须先修正的架构归因

## 1.1 当前失败不是 Tangent 理论失败

当前负收益实验的真实调用路径是：

```text
stage8_k2_tp_fit_safe
├── K1_PUBLIC fixed estimator
├── K2_PUBLIC fixed estimator
├── center manifold + derivatives
├── projected Tangent direction
├── T4 continuous profile
│   └── context.manifold_provider
└── final safe selector
```

现有 cache provider 实际只通过：

```text
context.manifold_provider
```

进入 T4 continuous profile。

最终证据已确认：

```text
Integrated C1 hook:
0 hit
5904 miss
```

因此当前非正收益表示：

> 21-key exact registered dictionary 被接入了连续 T4 endpoint 路径，而连续 endpoint 基本不属于 21-key registered domain；于是每次查询都先做 cache 检查，再回退 legacy manifold。

这不能解释为：

```text
canonical registered dictionary 对 fixed-grid backbone 无效
```

因为 fixed-grid backbone 当时没有接入 dictionary。

## 1.2 本阶段必须修正 provider 拓扑

必须把 provider 语义拆开：

```text
fixed_registered_manifold_provider
t4_manifold_provider
```

其中：

```text
fixed_registered_manifold_provider
```

只服务于：

- K1 fixed registered refinement；
- K1 fixed final certification；
- K2 helper-K1 fixed subfit；
- K2 nested-anchor 的 registered pair candidates；
- K2 fixed registered refinement；
- K2 fixed final certification；
- 经审计确认同一 measurement identity、只需要 G、不需要 derivatives 的 conventional registered initialization scoring。

而：

```text
t4_manifold_provider
```

本阶段必须保持为空或 legacy continuous direct path。

严禁再次把 21-key registered cache 默认传入 T4。

## 1.3 正确的创新叙事

冻结为：

> The exact-key canonical registered-manifold cache accelerates the repeatedly evaluated fixed registered backbone required by the complete Tangent-safe estimator, while the Tangent continuous refinement itself remains mathematically unchanged and is not served by the finite registered dictionary.

中文：

> exact-key canonical registered-manifold cache 用于加速 Tangent-safe 完整估计器所依赖的高复用 fixed registered backbone；Tangent 连续低维 refinement 的数学结构保持不变，有限注册字典不服务于连续 T4 endpoint。

不得写成：

```text
cache accelerates the continuous Tangent core
```

也不得写成：

```text
4.345% is cache-only speedup
```

---

# 2. 理论不变量

## 2.1 Registered domain

从代码重新构造，不得只信提示词常量：

```text
build_common_registered_local_domain
build_stage8_locked_plan
context.plan.local_domain
```

当前预期：

\[
\mathcal A
=
\{7.4,7.6,7.8,8.0,8.2,8.4,8.6\},
\]

\[
\mathcal E
=
\{9.8,10.0,10.2\},
\]

\[
\Omega=\mathcal A\times\mathcal E,
\qquad |\Omega|=21.
\]

## 2.2 Dictionary

对每个 `fixed_measurement_hash = M`，定义：

\[
D_M
=
\begin{bmatrix}
g_M(\omega_1)&\cdots&g_M(\omega_{21})
\end{bmatrix}.
\]

对 registered K-target tuple：

\[
\Theta
=
[\omega_{q_1},\ldots,\omega_{q_K}]^T
\in\Omega^K,
\]

直接组装：

\[
G_M(\Theta)
=
D_M(:,[q_1,\ldots,q_K]).
\]

DML score、RSS、source solve 和 likelihood 仍使用原始观测：

\[
Z_{\mathrm{white}},
\]

不得缓存：

- score；
- RSS；
- likelihood；
- selected candidate；
- final estimate；
- truth/profile labels。

## 2.3 Fixed-path closure

当前 coordinate update：

\[
\theta_{k,d}
\leftarrow
v,\qquad
v\in\mathcal A\ \text{或}\ \mathcal E.
\]

如果：

\[
\Theta^{(0)}\in\Omega^K,
\]

则：

\[
\Theta^{(n)}\in\Omega^K,\qquad \forall n.
\]

但是当前代码的 `build_k1_initializations` 和 `build_k2_initializations` 只检查 domain bounds，没有接口级强制 exact grid membership。

本阶段必须修正：

- K1 context starts 必须精确属于 \(\Omega\)；
- K2 grouped context starts 必须精确属于 \(\Omega^2\)；
- fixed refinement 初始点必须精确属于 \(\Omega^K\)；
- nested K1 fixed estimate 必须精确属于 \(\Omega\)；
- nested anchor 来自 `candidate_points_deg`；
- final fixed estimates 必须精确属于 \(\Omega^K\)。

不得使用宽松 nearest-neighbor 解释。

## 2.4 Exact 的术语边界

当前 artifact 使用的是已经通过静态和轨迹认证的数值代表：

```text
BALANCED_SINGLE_PAIR_DIRECT_ACCUMULATION_MIDPOINT
```

因此正式称谓使用：

```text
EXACT-KEY NUMERICALLY CERTIFIED REGISTERED-MANIFOLD CACHE
```

不要声称：

```text
bit-exact cached value for every BLAS accumulation shape
```

除非新实现额外证明逐 bit 一致。

不得放宽现有：

- G relative-error tolerance；
- singular-value tolerance；
- rank threshold；
- tie tolerance；
- nested RSS tolerance；
- final-selector condition。

---

# 3. 本阶段授权与禁止事项

## 3.1 授权

Codex 必须完成：

1. Git/branch/worktree 预检；
2. 重新审计 `b4424c6...` 的真实 caller chain；
3. 修复 registered closure 接口；
4. 建立低开销 immutable fixed-backbone provider；
5. 将 provider 接入真正的 fixed registered G-only 主干；
6. 将 T4 与 fixed provider 分离；
7. 建立三路公平对照：
   - `LEGACY_FULL`
   - `DIRECT_G_ONLY`
   - `REGISTERED_CACHE`
8. 运行静态认证；
9. 运行 72/72 完整语义和轨迹一致性；
10. 运行 paired AB/BA runtime；
11. 分离 warm-online 与 cold build/load；
12. 输出最小充分证据；
13. 按逻辑提交；
14. 非 force-push 推送新分支。

## 3.2 禁止

不得：

- 修改 Tangent direction 公式；
- 修改 `stage8_k2_tp_projected_direction`；
- 修改 `rho_min`、scan nodes、`fminbnd`；
- 修改 local-domain 范围或步长；
- 修改 K1/K2 start 集；
- 修改 coordinate update order；
- 修改 `max_iter`；
- 修改 score / RSS / likelihood；
- 修改 rank rule；
- 修改 tie rule；
- 修改 final safe selector；
- 修改 SNR/profile/random seed；
- 重跑经典算法对比；
- 实现插值；
- nearest-neighbor；
- 近似 cache；
- 引入 C2–C7；
- 构造复杂通用 cache framework；
- 在 hot path 中使用 `containers.Map`、SHA-256、`whos`、动态 JSON、逐调用日志或逐调用 `tic/toc`；
- 以证据基础设施替代算法推进。

---

# 4. Git 和源代码预检

执行：

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --porcelain=v1 --untracked-files=all
git rev-parse HEAD
git merge-base --is-ancestor b4424c6d87511ecf8034a61bc5384ba347cb2467 HEAD
git remote -v
```

预期：

```text
branch:
experiment/stage8-k2-tangent-fixed-backbone-cache-v1

HEAD:
b4424c6d87511ecf8034a61bc5384ba347cb2467
```

若工作树不干净：

```text
BLOCKED_DIRTY_WORKTREE
```

不得 reset、clean、stash 或覆盖未知文件。

必须定位并记录：

```bash
git grep -n "function .*estimate_stage8_known_k_local_cell"
git grep -n "fit_local_model_k("
git grep -n "refine_joint_sequential_dml("
git grep -n "build_full_sequential_local_manifold("
git grep -n "K1_INIT_CONVENTIONAL"
git grep -n "K2_INIT_CONVENTIONAL"
git grep -n "K2_NESTED_ANCHOR"
git grep -n "K2_REGISTERED_REFINEMENT"
```

必须确认当前关键文件至少包括：

```text
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_fit_safe.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_6_k12_bootstrap_resolution/common/fit_local_model_k.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_3_grouped_conditional_dml/common/refine_joint_sequential_dml.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_6_k12_bootstrap_resolution/common/build_k1_initializations.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_6_k12_bootstrap_resolution/common/build_k2_initializations.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_3_grouped_conditional_dml/common/
build_full_sequential_local_manifold.m
```

若 caller chain 已改变：

```text
BLOCKED_FIXED_BACKBONE_CALL_GRAPH_DRIFT
```

---

# 5. 低开销 fixed-backbone provider

## 5.1 新工具目录

建立：

```text
tools/stage8_k2_tangent_fixed_backbone_cache/
├── matlab/
└── tests/
```

建议最小函数集：

```text
stage8_k2_tfbc_build_provider.m
stage8_k2_tfbc_registered_indices.m
stage8_k2_tfbc_get_manifold.m
stage8_k2_tfbc_provider_snapshot.m
stage8_k2_tfbc_run_tests.m
```

可复用当前已认证的：

```text
stage8_k2_tcc_build_registered_dictionary
stage8_k2_tecs_promote_c1_artifact
stage8_k2_tcc_stable_matrix_rank
stage8_k2_tcc_build_g_direct
```

不得复制一套新的 steering / projection 数学公式。

## 5.2 Provider 必须是 immutable plain struct

不要在 timed hot path 中使用当前通用 handle session 的：

- `containers.Map`；
- cell-per-column 查找；
- 21-row 线性 distance scan；
- `whos` copy accounting；
- per-call counter mutation；
- hash recomputation；
- per-call identity full validation。

推荐：

```matlab
provider = struct( ...
    'schema_version', ...
    'mode', ...
    'fixed_measurement_hash', ...
    'domain_hash', ...
    'phase_factor', ...
    'numeric_class', ...
    'az_grid_deg', ...
    'el_grid_deg', ...
    'index_lut', ...
    'G_single_or_certified', ...
    'artifact_hash', ...
    'validate_once_status', ...
    'timed_diagnostics_enabled', false);
```

Identity 必须在 provider construction 时完整验证一次。

Timed lookup 只允许：

1. scalar field guard；
2. O(K) registered index；
3. column read；
4. K-column assembly；
5. stable rank。

## 5.3 O(1) registered index

不要逐行扫描 21 个 key。

对规则网格：

\[
i_{az}
=
1+\operatorname{round}
\left(
\frac{az-a_0}{\Delta a}
\right),
\]

\[
i_{el}
=
1+\operatorname{round}
\left(
\frac{el-e_0}{\Delta e}
\right).
\]

必须再做 exact-key tolerance 检查：

\[
|az-\mathcal A(i_{az})|\le\tau,
\qquad
|el-\mathcal E(i_{el})|\le\tau.
\]

不要假设 `candidate_points_deg` 的线性顺序。

Provider construction 时建立：

```text
index_lut(i_az, i_el) -> dictionary column
```

并验证每个 dictionary column 恰好被映射一次。

## 5.4 三种 provider mode

### A. `LEGACY_FULL`

严格调用现有：

```matlab
build_full_sequential_local_manifold
```

这是当前生产 baseline。

### B. `DIRECT_G_ONLY`

调用：

```matlab
stage8_k2_tcc_build_g_direct
stage8_k2_tcc_stable_matrix_rank
```

只用于性能归因控制，不作为本阶段创新结论。

### C. `REGISTERED_CACHE`

条件：

- identity validate-once 已完成；
- fixed measurement hash 匹配；
- domain hash 匹配；
- phase factor 为 1；
- 每个 row exact registered；
- derivatives 不被请求。

执行：

```matlab
indices = stage8_k2_tfbc_registered_indices(...)
G = provider.G(:, indices)
[rank, singular_values, threshold] = ...
    stage8_k2_tcc_stable_matrix_rank(G, rank_multiplier)
```

返回 `info` 字段必须与 caller 需要的 legacy contract 对齐：

```text
rank_Gseq
singular_values_Gseq
rank_threshold_Gseq
target_angles_deg
fixed_measurement_hash
phase_factor
num_svd = 1
Gseq_size
full_receive_geometry_used_flag = false
factorized_scoring_used_flag = false
```

Formal timing 模式中，如果 registered contract 不成立：

```text
REGISTERED_BACKBONE_CONTRACT_MISS_STOP
```

Safety/debug 模式可允许 exact legacy fallback，但 formal correctness 和 runtime 不得出现 fallback。

---

# 6. 必须修改的实际主干

## 6.1 `stage8_k2_tp_fit_safe`

当前：

```matlab
base_opts = struct('mode','CORE_LITE',...)
```

必须允许将：

```text
context.fixed_registered_manifold_provider
```

传入 K1/K2 fixed estimator options。

伪代码：

```matlab
base_opts = struct( ...
    'mode','CORE_LITE', ...
    'return_diagnostics',true);

if isfield(context, 'fixed_registered_manifold_provider')
    base_opts.fixed_registered_manifold_provider = ...
        context.fixed_registered_manifold_provider;
end
```

T4 只允许读取：

```text
context.t4_manifold_provider
```

本阶段默认不得设置该字段。

移除 fixed provider 与旧：

```text
context.manifold_provider
```

的语义混用。

为兼容旧测试，可以保留旧字段但必须：

```text
LEGACY_COMPATIBILITY_ONLY
```

且新 formal runner 不得使用旧字段。

## 6.2 `estimate_stage8_known_k_local_cell`

定位真实文件和调用链。

必须把：

```text
fixed_registered_manifold_provider
```

向下传播到：

```text
fit_local_model_k
```

包括 K2 内部 helper-K1 fixed fit。

不得使 provider 进入：

- continuous K1 refinement；
- Tangent center derivatives；
- T4 profile。

## 6.3 `fit_local_model_k`

在 options 白名单中加入：

```text
fixed_registered_manifold_provider
fixed_manifold_mode
```

默认：

```text
fixed_manifold_mode = LEGACY_FULL
```

### K2 initialization

传入：

```matlab
build_k2_initializations(..., struct( ...
    'rank_multiplier', opts.rank_multiplier, ...
    'fixed_registered_manifold_provider', ...
        opts.fixed_registered_manifold_provider, ...
    'fixed_manifold_mode', opts.fixed_manifold_mode))
```

### Coordinate refinement

传入：

```matlab
refinement_opts.fixed_registered_manifold_provider = ...
    opts.fixed_registered_manifold_provider;

refinement_opts.fixed_manifold_mode = ...
    opts.fixed_manifold_mode;
```

### Final certification

当前：

```matlab
build_full_sequential_local_manifold(estimate.angles_hat_deg,...)
```

替换为统一 fixed provider：

```matlab
stage8_k2_tfbc_get_manifold( ...
    estimate.angles_hat_deg, model, local_domain, ...
    opts.fixed_registered_manifold_provider, ...
    struct('mode',opts.fixed_manifold_mode, ...
           'rank_multiplier',opts.rank_multiplier, ...
           'derivatives_required',false))
```

DML score、source solve、selection 不变。

## 6.4 `refine_joint_sequential_dml`

在 options 白名单加入：

```text
fixed_registered_manifold_provider
fixed_manifold_mode
local_domain
```

`score_angles_local` 当前直接调用：

```matlab
build_full_sequential_local_manifold
```

必须改为：

```matlab
stage8_k2_tfbc_get_manifold
```

输入包括：

- candidate angles；
- model；
- local domain；
- fixed provider；
- mode；
- rank multiplier；
- `derivatives_required=false`。

必须确保以下所有调用使用同一 provider mode：

- initial current score；
- 每个 axis candidate；
- 每轮 accepted state；
- K1 和 K2；
- helper-K1。

candidate order、严格 `>` 更新规则、canonical row sorting、numeric tolerance 和 convergence 不得改变。

## 6.5 `build_k2_initializations`

options 白名单加入 fixed provider。

### 保持 legacy derivative path

下面这个 center 调用必须继续使用：

```matlab
build_full_sequential_local_manifold
```

因为需要：

```text
derivatives.azimuth
derivatives.elevation
```

即：

```text
K2_NESTED_CENTER_DERIVATIVES
```

不得缓存。

### 接入 nested candidate loop

下面的 21 个 registered pair：

```matlab
angles = [k1_angle; candidates(index,:)]
```

必须通过 fixed provider 获取 G。

保持：

- projected metric；
- distance；
- full-rank check；
- lexicographic first tie；
- nested RSS check；
- first-column consistency；
- selected anchor；

全部不变。

## 6.6 Registered initialization contract 修复

修改：

```text
build_k1_initializations
build_k2_initializations
refine_joint_sequential_dml
```

新增共同 helper，例如：

```text
stage8_k2_tfbc_assert_registered_angles
```

要求：

```text
exact grid membership
not merely inside bounds
```

执行前先对当前 72-trial context 全审计。

若任何冻结 start 不在 \(\Omega^K\)：

```text
BLOCKED_CURRENT_START_NOT_REGISTERED
```

不得自动 round、snap 或 nearest-neighbor。

## 6.7 Conventional registered initialization

根据已有 query stage：

```text
K1_INIT_CONVENTIONAL
K2_INIT_CONVENTIONAL
```

定位其真实 G-only scoring seam。

仅在以下条件全部成立时接入：

- same `fixed_measurement_hash`；
- same local-domain hash；
- factor-1；
- exact registered point；
- no derivatives required；
- output only G/rank/score。

以下 stage 当前明确不兼容，不得强行接入：

```text
K1_INIT_GROUP_Q1_CURRENT_TCC_MODEL_INCOMPATIBLE
K1_INIT_GROUP_Q2_CURRENT_TCC_MODEL_INCOMPATIBLE
K2_INIT_GROUP_Q1_CURRENT_TCC_MODEL_INCOMPATIBLE
K2_INIT_GROUP_Q2_CURRENT_TCC_MODEL_INCOMPATIBLE
```

如果 conventional path 的 seam 修改会扩大算法边界，先完成 refinement/nested/final 主干，再将 conventional 标记：

```text
DEFERRED_NONESSENTIAL_INITIALIZATION_SEAM
```

但不得因此停止主任务。

---

# 7. T4 和 Tangent 必须保持不变

以下文件主体哈希应保持不变，除非仅修改 provider 字段命名适配：

```text
stage8_k2_tp_projected_direction.m
stage8_k2_tp_profile_scale.m
stage8_k2_tp_constants.m
```

本阶段 T4 必须走：

```text
LEGACY CONTINUOUS MANIFOLD
```

或已存在且算法等价的 continuous direct path。

正式结果中预期：

```text
T4 registered-cache query count = 0
T4 registered-cache hit count   = 0
T4 registered-cache miss count  = 0
```

不是：

```text
0 hit / 5904 miss
```

因为 T4 不应再调用 finite registered cache。

Tangent 数学输出必须完全保持：

- K1 center；
- center derivatives；
- projected direction；
- rho scan；
- bracket；
- fminbnd；
- raw Tangent candidate；
- fixed-vs-Tangent likelihood guard；
- final selector。

---

# 8. Correctness 认证

## 8.1 静态 finite-domain

对两个 measurement identities：

- 42/42 singles；
- 462/462 canonical unordered pairs；
- 882/882 ordered pairs；
- rank；
- singular values；
- threshold；
- first/second column semantics；
- identity rejection；
- off-grid rejection；
- domain mismatch；
- phase mismatch。

必须继续通过。

## 8.2 Closure tests

新增：

- K1 grouped start exact registered；
- K1 conventional start exact registered；
- K2 grouped starts exact registered；
- nested K1 exact registered；
- nested anchors exact registered；
- every coordinate candidate exact registered；
- every final fixed estimate exact registered。

## 8.3 Fixed-backbone exposure

72-trial formal correctness 中必须统计：

```text
K1_FIXED_REGISTERED_REFINEMENT
K1_FIXED_FINAL_CERTIFICATION
K2_HELPER_K1
K2_NESTED_ANCHOR_REGISTERED_CANDIDATES
K2_REGISTERED_REFINEMENT
K2_FINAL_CERTIFICATION
```

对 `REGISTERED_CACHE`：

```text
eligible_registered_call_count > 0
cache_hit_count == eligible_registered_column_count
cache_miss_count == 0
fallback_count == 0
identity_rejection_count == 0
```

Derivative-required center calls不得计入 cache miss。

## 8.4 72/72 full semantic equality

比较 `LEGACY_FULL` 与 `REGISTERED_CACHE`：

- `fit_valid`；
- final angles；
- selected source；
- selected start；
- RSS；
- loglik；
- effective rank；
- score-call count；
- SVD-call count；
- candidate order；
- tie set；
- best index；
- accepted update；
- full trajectory；
- nested anchor；
- nested RSS pass；
- final selector；
- truth isolation。

必须生成完整 decision projection checksum：

```text
result_checksum_hash
```

并在每一个 formal timed pair 中直接比较：

```matlab
strcmp(a.result_checksum_hash, b.result_checksum_hash)
```

不能只比较：

- selected source；
- selected start；
- score/SVD count。

任何不匹配：

```text
FIXED_BACKBONE_CACHE_SEMANTIC_MISMATCH_STOP
```

不得调整 tolerance 来通过。

---

# 9. 三路公平运行时对照

## 9.1 Primary comparison

```text
LEGACY_FULL
vs
REGISTERED_CACHE
```

回答：

> 在当前算法结构和 Tangent 数学不变时，仅将 fixed registered manifold producer 替换为预先认证 dictionary，整体 runtime 是否改善？

## 9.2 Attribution comparison

```text
DIRECT_G_ONLY
vs
REGISTERED_CACHE
```

回答：

> 在已经排除 derivatives/full-manifold 普通工程开销后，dictionary lookup 本身相对 direct G-only 的独立增益是多少？

必须分别报告：

\[
\Delta T_{\mathrm{cache\ vs\ legacy}},
\]

\[
\Delta T_{\mathrm{cache\ vs\ direct-G}}.
\]

不得把二者混为一个数字。

## 9.3 Provider 生命周期

Provider 和 artifact：

- 按 `fixed_measurement_hash` 构造；
- identity scope 内复用；
- 不得每个 manifold call 构造；
- warm-online 正式计时前完成 build/load/validate；
- 不得每个 trial 重做完整 dictionary；
- 同一 identity 的 36 trials 应复用同一 immutable artifact/provider。

需要单独测：

```text
COLD_BUILD
COLD_LOAD
WARM_ONLINE
```

但 primary online speedup 不能混入一次性 build/load。

---

# 10. 计时协议

## 10.1 环境

冻结并记录：

- MATLAB release；
- single-comp-thread 状态；
- CPU；
- OS；
- working directory；
- code commit；
- provider artifact hash；
- trial registry hash。

## 10.2 Trial set

复用现有冻结：

```text
72 trials
2 fixed measurement identities
36 trials per identity
```

不得新增：

- SNR；
- L；
- noise profile；
- source profile；
- random seed。

## 10.3 Paired protocol

对每个 comparison：

- formal warmup；
- 每 trial 20 paired repeats；
- AB 10；
- BA 10；
- pair contiguous；
- root external timer；
- raw per-pair checksum；
- trial median；
- identity sum；
- overall sum；
- fixed-registry paired bootstrap 10000。

不需要重新建立多阶段巨大 freeze chain。

最小充分冻结：

```text
baseline_commit
source_hashes
trial_registry_hash
provider_artifact_hashes
timing_schedule_hash
```

## 10.4 Hot-path 禁止 instrumentation

正式 runtime：

```text
per_call_timing_enabled = false
raw_event_logging_enabled = false
counter mutation disabled
```

cache exposure 可通过：

- correctness run；
- deterministic expected call counts；
- 非 timed diagnostic run；

获得。

---

# 11. 理论速度边界和结果解释

这些数字只作为先验，不是强制通过阈值。

当前证据给出：

```text
cache incremental after DIRECT_G_ONLY:
0.600809%
```

即：

\[
\Delta_{\mathrm{cache|direct-G}}
=
2.192184\ \mathrm{s}
\]

相对于：

\[
T_0
=
364.872219\ \mathrm{s}.
\]

如果 cache 直接替换当前 `LEGACY_FULL` registered producer，它同时避免 legacy derivative/full-manifold 构造，因此基于已有分解：

\[
\Delta_{\mathrm{cache\ vs\ legacy}}
\approx
\Delta_{G\text{-only}}
+
\Delta_{\mathrm{cache|direct-G}}
\]

\[
=
5.420119
+
2.192184
=
7.612303\ \mathrm{s}.
\]

对应：

\[
\frac{7.612303}{364.872219}
\approx
2.0863\%.
\]

换算 speedup：

\[
S
=
\frac{1}{1-0.020863}
\approx
1.0213.
\]

因此本阶段合理先验：

```text
conservative incremental cache vs direct-G:
about 0.6%

cache provider vs current legacy full:
about 2.1% point estimate

practical expected range:
about 1% to 3%

optimized low-overhead upper region:
about 3.5% to 4.0%

hard zero-hit-cost ceiling from prior evidence:
about 4.0%
```

下面这个数字不得作为 cache-only：

```text
4.345031%
```

因为它包含：

- structural cleanup；
- direct G-only；
- cache。

如果实测明显低于 1%，优先检查：

- provider 是否真正在 fixed path 命中；
- 是否仍创建 per-trial session；
- 是否保留线性 key scan；
- 是否有 per-call diagnostics；
- dictionary assembly 是否触发不必要 copy；
- T4 是否误走 cache；
- conventional/grouped incompatible path 是否产生大量 fallback。

如果实测高于约 4%，必须先检查：

```text
是否不小心同时做了 structural cleanup
是否改变了 score/SVD call count
是否减少了 start 或 candidate
是否改变了算法
是否把 build/load 排除方式弄错
```

---

# 12. 性能判定

## 12.1 Correctness gate

必须全部满足：

```text
72/72 semantic pass
full checksum match
trajectory mismatch = 0
final-selector mismatch = 0
truth leakage = 0
collision = 0
eligible cache miss = 0
eligible fallback = 0
T4 cache query = 0
```

## 12.2 Runtime gate

定义：

\[
d_{i,r}
=
T_{\mathrm{legacy},i,r}
-
T_{\mathrm{cache},i,r}.
\]

### Robust positive

```text
overall point saving > 0
one-sided 95% lower bound > 0
both measurement identities point saving >= 0
AB aggregate >= 0
BA aggregate >= 0
```

状态：

```text
STAGE8_K2_FIXED_BACKBONE_CACHE_ROBUST_POSITIVE
```

### Inconclusive

point > 0，但 robust gate 未全部满足：

```text
STAGE8_K2_FIXED_BACKBONE_CACHE_INCONCLUSIVE
```

### Nonpositive

point <= 0：

```text
STAGE8_K2_FIXED_BACKBONE_CACHE_NONPOSITIVE
```

## 12.3 Retention

只有 robust positive 才允许：

```text
RETAIN_FIXED_BACKBONE_REGISTERED_CACHE
```

否则：

```text
KEEP_PRODUCTION_DEFAULT_CACHE_OFF
```

即使不 retain，也必须保留：

- provider prototype；
- correctness evidence；
- runtime evidence；
- clear technical conclusion。

---

# 13. 最小输出证据

新增：

```text
innovation-mining/
54_stage8_k2_tangent_fixed_backbone_cache_validation.md

54_stage8_k2_tangent_fixed_backbone_cache_correctness.csv

54_stage8_k2_tangent_fixed_backbone_cache_exposure.csv

54_stage8_k2_tangent_fixed_backbone_cache_runtime_summary.csv

54_stage8_k2_tangent_fixed_backbone_cache_lifecycle.csv

54_stage8_k2_tangent_fixed_backbone_cache_manifest.json
```

提示词保存到：

```text
innovation-mining/stage8_execution_prompts/
Stage8_K2_Tangent_Fixed_Backbone_Exact_Cache_
Integration_And_Runtime_Validation_Codex_Execution_Prompt.md
```

不要生成几十个重复 schema 或过度证据文件。

Validation markdown 必须直接回答：

1. cache 接到了哪些真实主干；
2. 哪些路径保持 legacy；
3. T4 是否完全绕过 finite cache；
4. eligible fixed calls 命中多少；
5. semantic equality 是否 72/72；
6. cache vs legacy 的 measured speedup；
7. cache vs direct-G 的 incremental speedup；
8. build/load break-even；
9. 最终是否 retain；
10. 该结果能否支持论文中的架构性叙事。

---

# 14. 必须运行的测试

至少：

```text
test_stage8_k2_tfbc_registered_index
test_stage8_k2_tfbc_identity
test_stage8_k2_tfbc_static_domain
test_stage8_k2_tfbc_k1_refinement
test_stage8_k2_tfbc_k2_refinement
test_stage8_k2_tfbc_nested_anchor
test_stage8_k2_tfbc_final_certification
test_stage8_k2_tfbc_t4_bypass
test_stage8_k2_tfbc_72_trial_semantics
test_stage8_k2_tfbc_runtime_protocol
```

还必须运行已有相关测试：

```text
stage8_k2_tecs_run_tests
canonical-cache tests
Tangent-profile tests
K1/K2 fixed-model tests
nested RSS nonincrease test
```

如果已有测试入口名称不同，定位真实入口并记录。

---

# 15. Commit 计划

建议三次逻辑提交。

## Commit 1：提示词与最小设计

```text
docs(stage8-k2): define fixed-backbone exact cache integration
```

包含：

- 本提示词；
- 最小 architecture note；
- baseline source manifest。

## Commit 2：实现与 correctness

```text
feat(stage8-k2): integrate registered cache into fixed backbone
```

包含：

- immutable provider；
- O(1) registered index；
- caller propagation；
- fixed refinement；
- nested candidate；
- final certification；
- T4 bypass；
- tests。

## Commit 3：runtime 和结论

```text
perf(stage8-k2): validate fixed-backbone cache runtime
```

包含：

- 54_* evidence；
- final status；
- production default decision。

推送：

```bash
git push -u origin experiment/stage8-k2-tangent-fixed-backbone-cache-v1
```

禁止 force-push。

---

# 16. 最终 Codex 回复格式

最终必须给出：

```text
BRANCH
HEAD
BASELINE_COMMIT
WORKTREE_STATUS

FIXED_BACKBONE_INTEGRATION_STATUS
T4_CACHE_BYPASS_STATUS
REGISTERED_CLOSURE_STATUS

STATIC_CERTIFICATION
72_TRIAL_SEMANTIC_STATUS
FULL_CHECKSUM_STATUS

ELIGIBLE_REGISTERED_CALLS
CACHE_HITS
CACHE_MISSES
FALLBACKS
T4_CACHE_QUERIES

LEGACY_FULL_RUNTIME
REGISTERED_CACHE_RUNTIME
CACHE_VS_LEGACY_REDUCTION_PCT
CACHE_VS_LEGACY_SPEEDUP

DIRECT_G_RUNTIME
CACHE_VS_DIRECT_G_REDUCTION_PCT
CACHE_VS_DIRECT_G_SPEEDUP

COLD_BUILD
COLD_LOAD
BREAK_EVEN

FINAL_PERFORMANCE_STATUS
FINAL_RETENTION_STATUS
PRODUCTION_DEFAULT

COMMITS
PUSH_STATUS
```

必须明确区分：

```text
cache-only
G-only engineering cleanup
structural cleanup
```

除硬停止条件外，Codex 不要只输出计划；必须完成实现、correctness、runtime、证据、提交和非 force-push 推送。
