# Stage8 K2 Cylindrical Multi-Center Canonical Cache Reuse  
## Production Equivalence, Compact Semantic Validation, Lifecycle, and Runtime Sentinel  
### Codex 完整执行提示词

> 本提示词用于验证：在当前 factor-1 圆柱阵、固定相对波束布局和固定相对 registered domain 下，是否可以只构建一份 reference canonical registered-manifold dictionary，并通过轻量 center adapter 服务多个实际物理工作中心。
>
> 本阶段不重新证明上一阶段已经完成的 `2.1527%` fixed-backbone cache 全量加速，不重跑完整 `72 × 20 × 2` 正式计时，不修改 Tangent 数学算法，不实现插值，不扩展 C2–C7。

---

# 0. 正式执行目标

你现在需要在：

```text
Repository:
makabaka165/bs_innovation
```

中完成一个新的、独立的实验阶段：

```text
Stage8 K2 Cylindrical Multi-Center Canonical Cache Reuse
```

需要回答的核心问题不是：

```text
有限 registered cache 能不能加速 fixed backbone？
```

这个问题已经由上一阶段证明：

```text
CACHE_VS_LEGACY reduction:
2.152679547%

CACHE_VS_DIRECT_G reduction:
0.995643227%

fixed registered cache:
22,040 / 22,040 eligible columns hit
```

本阶段只回答：

> 当前 reference center 下建立的同一份 registered-manifold dictionary，能否依靠圆柱阵旋转结构，被多个实际物理工作中心共同复用，同时保持 production model、fixed backbone、Tangent-safe 输出和在线性能语义不变？

必须形成四类证据：

1. **全圆几何结构证据**：所有物理列中心的工作子阵都属于同一旋转等价类；
2. **代表中心完整 production model 证据**：独立重建的 \(W_c,C_c,T_c,G_c\) 与 reference canonical class 一致；
3. **紧凑端到端语义证据**：共享 dictionary + center adapter 与 center-specific legacy direct 结果一致；
4. **跨中心 lifecycle 证据**：由每中心一张表降低为每 rotation class 一张表，实测 build/load/storage 减少，并通过小型 runtime sentinel 证明没有明显在线退化。

本提示词授权 Codex 直接：

- 创建新分支；
- 实现代码；
- 运行测试；
- 生成紧凑证据；
- 提交；
- 非 force-push 推送。

不需要停留在计划阶段。

---

# 1. Git 基线与新分支

## 1.1 固定基线

父分支：

```text
experiment/stage8-k2-tangent-fixed-backbone-cache-v1
```

固定父提交：

```text
b6156655b2d51d5333522166f6509b100ead7d08
```

提交语义：

```text
perf(stage8-k2): validate fixed-backbone cache runtime
```

开始前执行：

```bash
git rev-parse --show-toplevel
git status --porcelain=v1 --untracked-files=all
git fetch origin --prune
git rev-parse origin/experiment/stage8-k2-tangent-fixed-backbone-cache-v1
```

预期 SHA：

```text
b6156655b2d51d5333522166f6509b100ead7d08
```

如果远端已变化，检查：

```bash
git log --oneline --decorate \
  b6156655b2d51d5333522166f6509b100ead7d08..\
origin/experiment/stage8-k2-tangent-fixed-backbone-cache-v1

git diff --stat \
  b6156655b2d51d5333522166f6509b100ead7d08..\
origin/experiment/stage8-k2-tangent-fixed-backbone-cache-v1
```

若存在未知算法源代码变化，停止：

```text
BLOCKED_MULTICENTER_BASELINE_DRIFT
```

## 1.2 工作区保护

若存在任何不属于本任务的未提交修改或未跟踪文件：

- 不要 reset；
- 不要 clean；
- 不要 stash；
- 不要覆盖；
- 立即停止：

```text
BLOCKED_DIRTY_WORKTREE
```

## 1.3 新分支

从固定父提交创建：

```text
experiment/stage8-k2-cylindrical-multicenter-cache-v1
```

命令：

```bash
git switch --detach b6156655b2d51d5333522166f6509b100ead7d08
git switch -c experiment/stage8-k2-cylindrical-multicenter-cache-v1
```

不得：

- 修改 `main`；
- 修改父分支；
- force-push；
- merge；
- rebase 已完成分支；
- 创建 PR；
- 删除任何已有分支。

---

# 2. 当前结论和本阶段边界

## 2.1 已完成、不得重复的大规模证明

上一阶段已经完成：

```text
fixed-backbone integration
registered closure
T4 finite-cache bypass
42/42 singles
462/462 canonical pairs
882/882 ordered pairs
72/72 semantics
1440/1440 timed-pair checksum in both comparisons
2.1527% cache-vs-legacy
0.9956% cache-vs-direct-G
build break-even = 4 trials
load break-even = 1 trial
```

这些结论作为父证据引用，不重复运行完整正式协议。

## 2.2 当前仍未完成的部分

目前只完成：

```text
one fixed physical center
one fixed absolute registered domain
one provider per fixed measurement identity
```

尚未完成：

```text
independent production model at multiple physical centers
one center-independent rotation-class dictionary
lightweight center adapters
multi-center production semantics
multi-center build/load/storage scaling
```

## 2.3 本阶段不声称的内容

不得声称：

- cache 加速 Tangent continuous T4；
- cache 改善估计精度；
- 2.15% 全部来自圆柱阵旋转；
- 任意阵列都可跨中心共享；
- 任意 beam codebook 可共享；
- 任意连续角度可 exact lookup；
- 任意 center request 都是独立物理中心；
- 所有 192 中心都运行了完整 Tangent Monte Carlo；
- shared cache 比 center-specific cache 在线明显更快。

圆柱阵特有贡献应定义为：

> 在共同旋转工作子阵、candidate domain、波束码本和 Stage5 初始化角度的条件下，多个实际物理工作中心属于同一 rotation class，从而将 dictionary build/load/storage 从每中心一份降低为每 rotation class 一份。

---

# 3. 理论合同

## 3.1 实际物理中心，不是 nominal requested center

当前圆柱阵：

```text
Naz = 192
dPhi = 360 / 192 = 1.875 deg
```

`arr_cyl(cfg, azCtr)` 会将 requested center 吸附到最近的物理列。

reference model 的中心必须从：

```matlab
reference_model.array_meta.colCtr
reference_model.array_meta.phiCol(colCtr)
```

得到：

\[
\phi_0
=
\operatorname{wrap}
\left(
\mathrm{phiCol}(\mathrm{colCtr})
\right).
\]

不得直接假设：

```text
phi0 = 8 deg
```

需要同时记录：

```text
reference_requested_center_az_deg
reference_physical_center_az_deg
reference_center_column
```

## 3.2 物理中心集合

物理列角：

\[
\phi_n
=
(n-1)\frac{360^\circ}{N_{az}},
\quad n=1,\ldots,N_{az}.
\]

对 center column \(c\)，定义相对 reference 的整数列偏移：

\[
m_c
=
\operatorname{cyclicColumnDifference}(c,c_0),
\]

以及共同旋转角：

\[
\Delta_c
=
m_c\frac{360^\circ}{N_{az}}.
\]

所有正式多中心模型必须使用整数物理列偏移。

不得用任意 off-column requested angle 冒充新的物理中心。

可以另设一个 snap test，证明 requested center 与 physical center 的区别，但它不属于正式 center set。

## 3.3 几何旋转

在相同 local column/elevation order 中：

\[
r_{c,m}
=
R_z(\Delta_c)r_{0,m}.
\]

若代码发现 local order 存在 permutation，必须显式构造 \(P_c\)，验证：

\[
P_c^T r_c
=
R_z(\Delta_c)r_0.
\]

不得通过排序坐标值破坏当前 repository element order。

## 3.4 Candidate 和波束必须共同旋转

reference registered azimuth grid：

\[
\mathcal A_0.
\]

reference actual center：

\[
\phi_0.
\]

定义相对 registered grid：

\[
\mathcal D
=
\{
\delta_i:
\delta_i=a_i-\phi_0,\ a_i\in\mathcal A_0
\}.
\]

center \(c\) 的 registered grid：

\[
\mathcal A_c
=
\{
\phi_c+\delta_i
\}.
\]

reference azimuth beam centers：

\[
b_q^{(0)}.
\]

定义相对 beam offsets：

\[
\beta_q
=
b_q^{(0)}-\phi_0.
\]

center \(c\) 的 beam centers：

\[
b_q^{(c)}
=
\phi_c+\beta_q.
\]

不得继续使用固定绝对波束：

```text
[6.8, 7.4, 8.0, 8.6, 9.2]
```

去服务所有中心。

必须从 reference actual physical center 计算 relative offsets，而不是从 nominal 8° 计算。

## 3.5 Stage5 初始化配置必须共同旋转

reference `stage5_locked` 中所有绝对方位字段必须共同平移：

```text
conventional_center_deg(:, az)
az_beam_deg
```

所有相对和非方位字段保持不变：

```text
azimuth_offsets_deg
elevation_offsets_deg
el_beam_deg
max_iter
tolerances
gates
multi-start counts
phase_factor
```

不得通过保留旧 `configuration_hash` 来伪装旋转后配置为原配置。

必须建立：

```text
stage5_actual_center_identity
stage5_rotation_class_identity
```

旧 exact reference config 继续兼容。

## 3.6 Beamspace model

对 center \(c\)：

\[
a_c(\phi_c+\delta,e)
=
\exp
\left[
j\frac{2\pi}{\lambda}
r_c^T u(\phi_c+\delta,e)
\right].
\]

根据共同旋转：

\[
a_c(\phi_c+\delta,e)
=
a_0(\phi_0+\delta,e)
\]

在同一 local element order 中成立。

波束共同旋转后，应验证：

\[
W_c
\approx
W_0.
\]

局部索引噪声模型共同旋转后，应验证：

\[
C_c
=
W_c^H R_{n,c} W_c
\approx
C_0,
\]

\[
T_c
\approx
T_0.
\]

最终：

\[
g_c(\phi_c+\delta,e)
=
T_cW_c^H a_c(\phi_c+\delta,e)
\approx
T_0W_0^H a_0(\phi_0+\delta,e).
\]

## 3.7 Shared dictionary

reference rotation class 只构建一份 shape-certified table：

```text
G_single_exact_shape
G_pair_first_exact_shape
G_pair_second_exact_shape
```

key 使用：

```text
relative delta_az
elevation
```

而不是 reference absolute azimuth。

center adapter 负责：

\[
\delta
=
\operatorname{periodicDifference}(az,\phi_c).
\]

然后：

```text
(delta, el)
→ exact registered index
→ shared shape-certified column
```

不得为每个 center 重新生成一份完整 `G_*` table 后再声称共享。

---

# 4. 两级 identity

## 4.1 Actual-center identity

必须包含：

```text
actual center column
physical center azimuth
requested center azimuth
absolute active geometry hash
absolute beam centers
absolute registered domain
actual model hash
actual Stage5 config hash
```

不同 center 的 actual-center identity 必须不同。

## 4.2 Rotation-class identity

必须包含：

```text
factor-1
steering sign
lambda
canonical local geometry
local element order
subarray size
relative beam offsets
elevation beam centers
relative registered delta grid
elevation registered grid
measurement config / subset channels
noise profile and local covariance identity
whitening contract
K1/K2 BLAS shape contract
numeric class
```

不得包含：

```text
absolute center column
absolute physical center azimuth
absolute beam azimuth
absolute registered azimuth
truth
observation
profile
```

同一 rotation class 的所有正式 centers 必须：

```text
rotation_class_hash identical
actual_center_hash distinct
```

Provider admission 必须同时要求：

```text
rotation_class_hash match
center adapter independently certified
model center identity match adapter
```

不能简单删除当前 `fixed_measurement_hash` 检查而不建立替代 identity。

---

# 5. 新代码结构

新增：

```text
tools/stage8_k2_cylindrical_multicenter_cache/
├── README.md
├── matlab/
└── tests/
```

建议最小职责：

```text
stage8_k2_mc_add_paths.m
stage8_k2_mc_reference_spec.m
stage8_k2_mc_select_centers.m
stage8_k2_mc_build_rotated_candidate_pool.m
stage8_k2_mc_build_rotated_stage5_config.m
stage8_k2_mc_build_local_domain.m
stage8_k2_mc_build_measurement_model.m
stage8_k2_mc_build_rotation_class_identity.m
stage8_k2_mc_build_shared_provider.m
stage8_k2_mc_build_center_adapter.m
stage8_k2_mc_get_manifold.m
stage8_k2_mc_build_context.m
stage8_k2_mc_generate_paired_trial.m
stage8_k2_mc_run_static.m
stage8_k2_mc_run_semantics.m
stage8_k2_mc_run_lifecycle.m
stage8_k2_mc_run_runtime_sentinel.m
stage8_k2_mc_run_tests.m
```

不要新增大型通用 cache stack。

优先复用：

```text
stage8_k2_tfbc_build_provider
stage8_k2_tfbc_get_manifold
stage8_k2_tcc_build_registered_dictionary
stage8_k2_tcc_build_g_direct
stage8_k2_tcc_stable_matrix_rank
build_stage8_measurement_model
build_exact_subset_model
enumerate_stage7_rectangular_subsets
form_elevation_dbf_cube
form_azimuth_dbf_cube
build_sequential_beam_matrix
```

---

# 6. Production multi-center model factory

## 6.1 Reference source

从父提交当前 primary model 得到：

```text
reference cfg
reference candidate pool
reference model
reference physical center
reference absolute beam azimuths
reference registered domain
reference stage5 config
```

本阶段正式范围：

```text
measurement_config_id:
PRIMARY_RECT_E14_A31

noise_profile_id:
WHITE
STAGE5_TOEPLITZ_CORRELATED
```

不需要重新验证 sensitivity configuration 的完整语义。

可以在静态阶段选 1–2 个 sensitivity smoke case，但不得扩大为第二套正式 workload。

## 6.2 Rotated candidate pool

不要修改当前冻结 `build_stage7_candidate_pool` 的默认行为。

在新工具目录中建立 parameterized rotated pool：

```text
sector requested center:
reference requested center + Delta_c

physical center:
reference physical center + Delta_c

azimuth beam centers:
reference absolute beam centers + Delta_c

elevation beam centers:
unchanged
```

使用现有：

```text
arr_cyl
form_elevation_dbf_cube
form_azimuth_dbf_cube
build_sequential_beam_matrix
```

重建 center-specific `W0_c`。

然后用：

```text
enumerate_stage7_rectangular_subsets
build_stage8_measurement_model(..., pool=rotated_pool, subset_family=...)
```

建立完整 center-specific production model。

不得只旋转 reference coordinates 后直接复制一个假 model 作为 production oracle。

## 6.3 Rotated Stage5 config

新建 rotation-equivalent Stage5 config。

需要对 `build_stage8_known_k_local_context` 的 exact reference hash gate 做最小向后兼容扩展：

```text
legacy reference config:
old exact hash accepted

multi-center config:
rotation-class validator accepted
```

不得改变原有 reference config 的默认行为。

不得将已修改字段与旧 hash 同时保留。

## 6.4 Center-specific local domain

center-specific domain 使用 reference relative delta grid：

```text
global az grid = physical center + reference relative delta grid
elevation grid = unchanged
```

保持一个连续、未 wrap 断裂的 unwrapped azimuth chart。

不要在 180° 或 360° 附近把一个规则 grid 切成不单调数组。

方向函数可以接受超出 `[-180,180)` 的角度；identity 中另行保存 wrapped physical center。

---

# 7. Shared provider 与 center adapter

## 7.1 Shared provider

一份 provider 对应：

```text
one measurement config
one noise profile
one rotation class
```

当前正式范围因此应有：

```text
2 shared providers
```

而不是：

```text
2 × number_of_centers full providers
```

Shared provider 存储：

```text
relative delta grid
elevation grid
index LUT
shape-certified G tables
rotation-class identity
reference artifact provenance
```

## 7.2 Center adapter

每个 center 只建立小型 adapter：

```text
actual center identity
physical center azimuth
center column
requested center
Delta_c
absolute domain hash
absolute beam layout hash
rotation-class hash
adapter certification status
```

不得复制完整 G tables。

## 7.3 Lookup

对 global query：

```matlab
delta = periodic_difference(global_az, physical_center_az);
indices = exact_relative_registered_indices(delta, el);
G = shared_table(:, indices);
```

K1/K2 shape semantics继续使用当前已认证：

```text
single shape
pair first shape
pair second shape
```

T4 continuous profile继续：

```text
0 shared-cache query
```

## 7.4 当前 TFBC 兼容

允许对：

```text
stage8_k2_tfbc_get_manifold
```

做最小 schema dispatch：

```text
STAGE8_K2_TFBC_PROVIDER_V1
STAGE8_K2_MULTICENTER_SHARED_PROVIDER_V1 + CENTER_ADAPTER_V1
```

不得改动：

- score；
- rank；
- candidate order；
- fixed refinement；
- nested selection；
- Tangent profile；
- final selector。

---

# 8. 均衡验证设计

整个阶段分四个门。后一个门只在前一个门通过后运行。

---

## Gate A：全圆几何与代表中心 production static

### A1. 全部 192 物理中心：geometry-only exhaustive

对所有：

```text
192 physical center columns
```

验证：

- center column selection；
- active column cyclic shift；
- local element order；
- canonical geometry round-trip；
- rotated coordinate equality；
- 3 个 relative delta；
- 3 个 elevation；
- factor-1 element steering equality。

这一层：

- 不运行 Tangent；
- 不构建 192 套完整 provider；
- 不运行随机 trial；
- 可以向量化或并行。

### A2. 8 个代表中心：完整 production model

center column offsets 相对 reference 固定为：

```text
[0, +1, -1, +8, -8, +32, -32, +96]
```

覆盖：

- reference；
- 相邻物理列；
- subarray wrap-around；
- 中等旋转；
- 大角度旋转；
- 对径中心。

对 8 centers × 2 noise profiles，独立构建 16 个 production models。

验证：

```text
canonical geometry
relative beam offsets
Wseq
Cseq
Tseq
whitening rank
subset channels
rotation-class hash
actual-center hash
```

默认数值门限：

```text
canonical geometry relative error <= 1e-13
W relative Frobenius error        <= 1e-11
C relative Frobenius error        <= 1e-11
T relative Frobenius error        <= 1e-10
```

若不能满足，不要放宽超过 10 倍；先调查：

- actual vs requested center；
- beam offsets；
- local order；
- wrap chart；
- whitening eigenvector/sign/basis；
- subset channel order。

### A3. 21-key 和 pair 证据

对 16 个 production models：

```text
21 singles
231 canonical K2 pairs
```

比较：

```text
center-specific direct legacy
reference shared dictionary + center adapter
```

验证：

- G relative error；
- rank；
- singular values；
- rank threshold；
- first/second column semantics。

默认：

```text
single/pair G relative error <= 1e-10
rank mismatch = 0
```

不要求跨中心逐 bit 相等。

### A4. 必须有区分力的 negative controls

至少完成：

1. rotated subarray 但不平移 beam azimuths；
2. requested center 代替 actual physical center；
3. perturb one element coordinate 或 one relative beam offset。

这些错误模型必须：

```text
rotation-class admission rejected
```

并且至少一个 G/W equivalence metric 明显失败。

如果错误模型仍全部通过：

```text
BLOCKED_MULTICENTER_TEST_NOT_DISCRIMINATIVE
```

### Gate A 通过状态

```text
STAGE8_K2_MULTICENTER_STATIC_ROTATION_PASS
```

失败则不进入 Gate B。

---

## Gate B：24-case 紧凑 production semantic

### B1. Case set

只使用 3 个非 reference centers：

```text
+1
-8
+96
```

乘以：

```text
2 noise profiles
4 existing source profiles P1/P2/P3/P4
```

固定：

```text
L = 8
SNR = 6 dB
```

总数：

```text
3 × 2 × 4 = 24 cases
```

复用当前 profile definitions 和 deterministic seed 体系。

不得新增 SNR sweep、L sweep 或经典算法。

### B2. Trial generation

每个 case 必须独立构建：

```text
center-specific model
center-specific global truth angles
center-specific local domain
center-specific Stage5 config
Y_element
```

目标 global azimuth 相对 reference 同样平移：

\[
az_c = az_0+\Delta_c.
\]

噪声在 local element order 中使用同一 deterministic draw，以支持 rotation-covariance paired comparison。

同时保留少数独立 center-specific draws，避免所有证据只依赖一个旋转生成器。

### B3. 两条主要路径

对所有 24 cases 比较：

```text
A. CENTER_SPECIFIC_LEGACY_FULL
B. SHARED_CANONICAL_REGISTERED_CACHE
```

两条路径使用相同 `Y_element`。

比较：

- fit valid；
- K1 center；
- K2 fixed result；
- selected starts；
- candidate order；
- tie set；
- accepted updates；
- nested anchor；
- rank；
- final fixed result；
- Tangent direction；
- rho；
- raw Tangent candidate；
- final selector；
- final angles；
- RSS；
- loglik；
- score/SVD counts；
- truth isolation。

跨中心浮点路径可能不是逐 bit 相同，因此采用：

```text
discrete trajectory and decisions:
exact match

angle:
<= 2e-4 deg

G:
<= 1e-10 relative

RSS/loglik:
<= 1e-8 relative-or-absolute scaled tolerance

rank/status/source/start:
exact match
```

不得为通过而改变算法 tolerance。

### B4. Center-specific cache control

从 24 cases 中固定选 6 cases，额外比较：

```text
CENTER_SPECIFIC_REGISTERED_CACHE
vs
SHARED_CANONICAL_REGISTERED_CACHE
```

这 6 cases 覆盖：

```text
3 centers × 2 noise profiles
```

用于证明共享表不是通过改变 fixed provider 行为获得一致性。

### B5. Rotation covariance

从 24 cases 中固定选 8 paired cases，连同对应 reference case，验证：

\[
\widehat{az}_c-\Delta_c
\approx
\widehat{az}_0,
\]

\[
\widehat{el}_c
\approx
\widehat{el}_0.
\]

并比较：

```text
selected source
upgrade/fallback
rho
local-direction representation
```

### Gate B 通过状态

```text
STAGE8_K2_MULTICENTER_SEMANTIC_PASS_24_OF_24
```

失败则不运行大规模 lifecycle/runtime sentinel。

---

## Gate C：跨中心 lifecycle 和存储

### C1. 实测对象

使用 Gate A 的：

```text
8 centers
2 noise profiles
```

比较：

```text
INDEPENDENT_CENTER_PROVIDERS
vs
ONE_SHARED_PROVIDER_PLUS_8_ADAPTERS
```

每个 noise identity 独立统计。

### C2. Repeat

每个 identity：

```text
10 repeats
```

测量：

```text
independent total build time
shared provider build time
adapter total build time

independent total load time
shared provider load time
adapter load/create time

serialized bytes
logical table bytes
adapter bytes
provider count
```

不在 estimator timed loop 中构建或加载。

### C3. 必须报告

对每个 identity：

\[
\mathrm{buildReduction}
=
1-
\frac{T_{\mathrm{shared}}+T_{\mathrm{adapters}}}
{T_{\mathrm{independent}}}.
\]

\[
\mathrm{storageReduction}
=
1-
\frac{M_{\mathrm{shared}}+M_{\mathrm{adapters}}}
{M_{\mathrm{independent}}}.
\]

同时报告：

```text
8-center measured reduction
192-center analytic extrapolation
```

192-center值只能标记为：

```text
ANALYTIC_EXTRAPOLATION_FROM_CERTIFIED_ROTATION_CLASS
```

不得写成 192-center measured runtime。

### C4. 预期解释

对 \(N_c\) 个中心，理想 table-count reduction：

\[
1-\frac{1}{N_c}.
\]

8 centers：

\[
87.5\%.
\]

192 centers：

\[
99.4792\%.
\]

实际结果应包含 adapter 和 metadata，因此可以略低。

Gate C 不要求 shared provider 比单个 center provider 构建更快；它要求相对于构建 \(N_c\) 份独立表具有正的总 lifecycle 收益。

### Gate C 状态

```text
STAGE8_K2_MULTICENTER_LIFECYCLE_POSITIVE
```

或者：

```text
STAGE8_K2_MULTICENTER_LIFECYCLE_NONPOSITIVE
```

即使非正，也要如实保留理论和语义结果，不得修改算法掩盖。

---

## Gate D：小型在线 runtime sentinel

这不是重新认证 2.15%。

### D1. Case set

使用：

```text
3 centers:
+1, -8, +96

2 noise profiles

2 profiles:
P1, P4
```

总数：

```text
12 cases
```

### D2. Protocol

只运行：

```text
4 paired repeats per case
2 AB
2 BA
```

比较：

```text
CENTER_SPECIFIC_LEGACY_FULL
vs
SHARED_CANONICAL_REGISTERED_CACHE
```

总 paired count：

```text
12 × 4 = 48 pairs
```

总 root calls：

```text
96
```

每个 pair 必须先验证 semantic projection 一致，再计入 runtime 汇总。

### D3. 解释边界

该结果只用于：

```text
directional cross-center runtime sentinel
```

不得替代父阶段的：

```text
72 × 20 robust-positive runtime proof
```

必须报告：

```text
overall point saving
AB point
BA point
per-center point
per-noise point
```

不设置新的 10,000 bootstrap retention gate。

期望：

- shared cache 相对 legacy 仍为正；
- 大小大体与父阶段约 2.15% 同数量级；
- 不要求精确复现 2.1527%。

如果 point 略受噪声影响但 lifecycle 明显正、语义全通过，可以保留：

```text
ONLINE_SENTINEL_INCONCLUSIVE
```

不得因此否定跨中心共享。

---

# 9. 运行规模控制

上一阶段两组正式计时大约包含：

```text
72 trials
× 20 pairs
× 2 root calls
× 2 comparisons
= 5760 root calls
```

本阶段计划中的 estimator root calls 约为：

```text
24 semantic cases × 2 = 48
6 center-cache controls × 1 extra = 6
8 reference covariance controls ≈ 8
12 runtime cases × 4 pairs × 2 = 96
------------------------------------
约 158 root calls
```

约为上一阶段 root-call 规模的：

```text
2.7%
```

其余证据由无 Monte Carlo 的静态模型检查和 lifecycle 完成。

不得擅自将 Gate D 扩大为：

```text
72 × 20
```

除非紧凑结果出现无法解释的中心依赖，而且用户另行授权。

---

# 10. 加速执行的方法

## 10.1 静态任务可并行

可以并行：

- 192-center geometry；
- selected-center production model build；
- 21-key/pair static comparison；
- 24-case semantic case generation；
- non-timed correctness。

正式 runtime sentinel 必须：

```text
MATLAB R2022b
-singleCompThread
single process
contiguous AB/BA pairs
```

## 10.2 批量静态 manifold

静态 oracle 可以批量构造：

\[
A
=
\exp(jkR^TU)
\]

以减少运行时间。

但至少对每个 selected center 的若干 singles/pairs调用当前 production legacy builder交叉验证，避免 batch oracle 与 shared provider 共用同一错误。

## 10.3 一次构建，多次复用

必须在所有 timed runs 之前完成：

```text
models
trials
shared provider
center adapters
identity checks
```

timed loop 不得：

- 构建 model；
- 构建 provider；
- load MAT；
- hash entire artifact；
- 记录逐 query 事件；
-运行 per-call `tic/toc`。

## 10.4 Checkpoint

允许按：

```text
static center
semantic case
lifecycle repeat
runtime pair
```

保存仓库外 checkpoint。

运行根目录建议：

```text
E:\bs_innovation_runtime\
stage8_k2_cylindrical_multicenter_cache_v1
```

仓库中只提交汇总证据。

---

# 11. Tangent 算法冻结

以下必须保持父提交数学行为：

```text
stage8_k2_tp_projected_direction.m
stage8_k2_tp_profile_scale.m
stage8_k2_tp_constants.m
concentrated_dml_rss
beamspace_dml_score_svd
coordinate update order
candidate order
tie rule
nested rule
final safe selector
```

必须证明：

```text
T4 shared finite-cache query = 0
```

允许的现有主干修改只限：

- multi-center Stage5 rotation-class admission；
- provider schema dispatch；
- context center metadata；
- output azimuth frame adapter；
- identity propagation。

不得修改 Tangent 公式和参数。

---

# 12. 必须实现的测试

至少：

```text
test_stage8_k2_mc_actual_center_not_requested_center
test_stage8_k2_mc_all_192_geometry
test_stage8_k2_mc_rotated_beam_layout
test_stage8_k2_mc_W_C_T_equivalence
test_stage8_k2_mc_rotation_class_identity
test_stage8_k2_mc_actual_center_identity
test_stage8_k2_mc_shared_single_pair_G
test_stage8_k2_mc_negative_unshifted_beam
test_stage8_k2_mc_negative_wrong_center
test_stage8_k2_mc_negative_geometry_perturbation
test_stage8_k2_mc_stage5_rotation_contract
test_stage8_k2_mc_center_adapter
test_stage8_k2_mc_t4_bypass
test_stage8_k2_mc_compact_semantics
test_stage8_k2_mc_lifecycle_protocol
test_stage8_k2_mc_runtime_sentinel_protocol
```

并运行父阶段正式测试入口：

```text
stage8_k2_tfbc_run_tests
```

以及相关：

```text
TCC tests
Tangent profile tests
fixed-model tests
nested RSS tests
```

不需要重跑经典算法。

---

# 13. 硬停止条件

遇到以下任一情况，停止后续 gate：

```text
BLOCKED_DIRTY_WORKTREE
BLOCKED_MULTICENTER_BASELINE_DRIFT
BLOCKED_FIXED_REFERENCE_CENTER_UNRESOLVED
BLOCKED_PHYSICAL_CENTER_SELECTION_MISMATCH
BLOCKED_LOCAL_ELEMENT_ORDER_MISMATCH
BLOCKED_ROTATED_BEAM_LAYOUT_MISMATCH
BLOCKED_W_EQUIVALENCE_FAILED
BLOCKED_C_EQUIVALENCE_FAILED
BLOCKED_T_EQUIVALENCE_FAILED
BLOCKED_ROTATION_CLASS_IDENTITY_FAILED
BLOCKED_SHARED_G_EQUIVALENCE_FAILED
BLOCKED_MULTICENTER_TEST_NOT_DISCRIMINATIVE
BLOCKED_STAGE5_ROTATION_CONTRACT
BLOCKED_SHARED_CACHE_SEMANTIC_MISMATCH
BLOCKED_T4_CACHE_QUERY
BLOCKED_TRUTH_LEAKAGE
```

不得通过以下方式绕过：

- nearest-neighbor；
- 插值；
- center-specific full table 偷换 shared table；
- 放宽算法 tolerance；
- 改 candidate；
- 改 Tangent；
- 引入未知 \(Q_c\) 变换；
- 对错误 model fallback 后继续宣称 shared hit。

如果发现必须引入：

\[
g_c=Q_cD
\]

而 \(Q_c\ne I\)，停止并报告：

```text
DEFERRED_CENTER_ADAPTER_TRANSFORM_RESEARCH_REQUIRED
```

不要在本阶段继续扩张。

---

# 14. 结果文件

新增最小证据：

```text
innovation-mining/
55_stage8_k2_cylindrical_multicenter_cache_validation.md

55_stage8_k2_cylindrical_multicenter_cache_static.csv

55_stage8_k2_cylindrical_multicenter_cache_semantics.csv

55_stage8_k2_cylindrical_multicenter_cache_lifecycle.csv

55_stage8_k2_cylindrical_multicenter_cache_runtime_sentinel.csv

55_stage8_k2_cylindrical_multicenter_cache_manifest.json
```

提示词保存：

```text
innovation-mining/stage8_execution_prompts/
Stage8_K2_Cylindrical_MultiCenter_Canonical_Cache_
Production_Equivalence_Lifecycle_And_Runtime_Sentinel_
Codex_Execution_Prompt.md
```

不要生成大批重复 manifest、raw CSV 或图。

Raw/checkpoint 保留在仓库外。

---

# 15. Validation 文档必须直接回答

1. reference requested center 和 actual physical center 分别是什么；
2. selected centers 是哪些物理列；
3. 192-center geometry 是否全部通过；
4. beam codebook 是否共同旋转；
5. \(W,C,T\) 是否跨 center 一致；
6. rotation-class hash 是否一致；
7. actual-center hash 是否不同；
8. 一份 table 是否真的被所有 center adapters 共享；
9. 24-case semantics 是否通过；
10. T4 cache query 是否为 0；
11. 8-center build/load/storage 实测降低多少；
12. 192-center外推是多少，并明确是 analytic；
13. runtime sentinel 是否正向；
14. 当前 2.15% 中哪些属于 generic precomputation；
15. 哪些新证据是 cylindrical rotation 专属；
16. 是否可以在论文中写成 shared-center rotational reuse。

---

# 16. 结果分类

## 16.1 完整通过

必须满足：

```text
192/192 geometry pass
16/16 production model pass
all selected 21-key/pair static pass
negative controls rejected
24/24 semantic pass
T4 cache query = 0
8-center lifecycle build/storage reduction > 0
truth leakage = 0
```

状态：

```text
STAGE8_K2_CYLINDRICAL_MULTICENTER_CACHE_COMPLETE
MULTICENTER_ROTATION_REUSE_CERTIFIED
SHARED_DICTIONARY_PRODUCTION_INTEGRATION_PASS
```

Runtime sentinel 可分类：

```text
ONLINE_SENTINEL_POSITIVE
ONLINE_SENTINEL_INCONCLUSIVE
ONLINE_SENTINEL_NONPOSITIVE
```

它不单独否定 rotation reuse，只影响在线表述。

## 16.2 理论通过、production 失败

例如 geometry pass，但 W/T/G 不一致：

```text
GEOMETRIC_ROTATION_ONLY_PRODUCTION_REUSE_NOT_CERTIFIED
```

不得宣称完整圆柱阵 cache 创新已落地。

## 16.3 Lifecycle 非正

如果共享表语义正确但当前 adapter/serialization 导致 lifecycle 非正：

```text
MULTICENTER_REUSE_CORRECT_LIFECYCLE_NONPOSITIVE
```

如实记录，不扩张证据系统。

---

# 17. 论文表述边界

若完整通过，可写：

> For the factor-1 cylindrical-array receive model, co-rotated working subarrays, beam codebooks, Stage5 azimuth references, and registered candidate domains form a common rotation class. A single exact-key, shape-certified canonical beamspace-manifold dictionary is therefore shared across multiple physical working centers through lightweight center adapters, while the fixed DML backbone and continuous Tangent refinement remain unchanged.

中文：

> 对 factor-1 圆柱阵接收模型，当工作子阵、波束码本、Stage5 方位参考和注册候选域共同旋转时，不同物理工作中心构成同一旋转等价类。由此可使用一份 exact-key、shape-certified 的 canonical 波束域流形字典，通过轻量中心适配器服务多个工作中心，同时保持 fixed DML 主干与连续 Tangent refinement 不变。

必须把两个性能贡献分开：

```text
generic registered precomputation:
父阶段在线 reduction 约 2.15%

cylindrical rotational sharing:
本阶段 dictionary build/load/storage 从 per-center 降为 per-rotation-class
```

不得把 multi-center sharing 的主要贡献描述成新的单 trial 在线 2.15%。

---

# 18. Commit 顺序

建议：

## Commit 1

```text
docs(stage8-k2): define cylindrical multicenter cache validation
```

内容：

- 本提示词；
- 最小 architecture note；
- baseline/center selection freeze。

## Commit 2

```text
feat(stage8-k2): add multicenter rotation-class cache
```

内容：

- model factory；
- rotated Stage5；
- identities；
- shared provider；
- center adapter；
- static tests；
- compact semantic tests。

## Commit 3

```text
test(stage8-k2): validate multicenter cache lifecycle
```

内容：

- Gate A/B/C；
- evidence；
- lifecycle decision。

## Commit 4（仅 Gate D 运行后）

```text
perf(stage8-k2): run multicenter cache runtime sentinel
```

内容：

- compact runtime sentinel；
- final validation；
- manifest。

推送：

```bash
git push -u origin \
experiment/stage8-k2-cylindrical-multicenter-cache-v1
```

不得 force-push。

---

# 19. 最终回复格式

最终使用中文，按以下格式：

```text
BRANCH
HEAD
BASELINE_COMMIT
WORKTREE
PUSH

REFERENCE_REQUESTED_CENTER
REFERENCE_PHYSICAL_CENTER
REFERENCE_CENTER_COLUMN
CENTER_OFFSETS
SELECTED_PHYSICAL_CENTERS

GEOMETRY_192_STATUS
PRODUCTION_MODEL_16_STATUS
MAX_GEOMETRY_ERROR
MAX_W_ERROR
MAX_C_ERROR
MAX_T_ERROR
MAX_G_ERROR
RANK_MISMATCH
NEGATIVE_CONTROL_STATUS

ROTATION_CLASS_HASH_STATUS
ACTUAL_CENTER_IDENTITY_STATUS
SHARED_PROVIDER_COUNT
CENTER_ADAPTER_COUNT
T4_CACHE_QUERY_COUNT

SEMANTIC_CASES
SEMANTIC_PASS
DECISION_MISMATCH
TRAJECTORY_MISMATCH
MAX_ANGLE_ERROR
MAX_RSS_ERROR
MAX_LOGLIK_ERROR
TRUTH_LEAKAGE

INDEPENDENT_BUILD
SHARED_BUILD
BUILD_REDUCTION
INDEPENDENT_LOAD
SHARED_LOAD
LOAD_REDUCTION
INDEPENDENT_STORAGE
SHARED_STORAGE
STORAGE_REDUCTION
CENTER_192_EXTRAPOLATION

RUNTIME_SENTINEL_CASES
RUNTIME_SENTINEL_POINT
AB_POINT
BA_POINT
RUNTIME_SENTINEL_STATUS

FINAL_COMPLETION_STATUS
FINAL_ROTATION_REUSE_STATUS
PAPER_CLAIM_STATUS

COMMITS
PUSH_STATUS
```

---

# 20. 最终原则

整个阶段紧贴唯一新增创新点：

```text
one canonical registered-manifold dictionary
shared across multiple physical cylindrical-array working centers
through certified rotation-class identities and lightweight center adapters
```

不要重新打开：

- Tangent 算法；
- SNR 模型卡；
- 经典算法比较；
- continuous T4 cache；
- interpolation；
- FPGA；
- pair-level SVD cache；
- 大型 cache stack；
- 过度证据基础设施。

先完成圆柱阵旋转结构本身的 production 证据，再决定是否需要更大规模 runtime。
