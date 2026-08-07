# Stage8 K2 Tangent–Canonical Cache 融合架构

Branch:
`experiment/stage8-k2-tangent-canonical-cache-v1`

Parent branch:
`experiment/stage8-k2-tangent`

Parent commit:
`3e7153ae11f8a49633a2edd2d2f710673e5d1bad`

Architecture source:
`experiment/stage8-k2-tangent-canonical-cache`
`8a398f4a86345520f29925f1ca7b41b700f22cb9`

Document status:
`LEVEL_A_IMPLEMENTATION_AUTHORIZED`

Execution authority:
`AUTHORIZED_BY_CURRENT_PROMPT`

Prompt status:
`LEVEL_A_V1_ACTIVE`

Code status:
`IN_PROGRESS`

Level B authority:
`NOT_AUTHORIZED`

## 1. 架构结论

本分支不重新设计 Tangent，也不重新打开已经完成的 white-SNR 和经典算法比较。它只定义一个新的后端计算架构：

> 将 factor-1 canonical beamspace manifold cache 作为 Tangent 的候选流形提供器，接入一维分离尺度 `rho` profile 的候选评分阶段；Tangent 的 K1 中心、投影残差方向、广义特征问题、DML 准则、连续优化和 safe fallback 均保持不变。

推荐的第一接入点是：

```text
tools/stage8_k2_tangent_profile/matlab/
  stage8_k2_tp_profile_scale.m
    -> evaluate_rho_local(...)
      -> 当前 build_full_sequential_local_manifold(...)
      -> 未来统一 pair-manifold provider
```

因此，canonical cache 的项目定位是：

```text
Tangent 决定搜索中心、方向和尺度
canonical cache 加速给定候选角度下的流形构造
DML 仍负责候选评分
safe selector 仍负责最终升级或回退
```

它不是新的 Tangent 方向估计器，不是新的 DML 准则，也不是新的模型阶数判决器。

## 2. 冻结基线与不可改变项

本架构继承父分支的以下冻结内容：

1. active receive manifold 使用 `spatialPhaseFactor=1`；
2. 当前固定测量由 `Wseq/W_I`、`Tseq/T_I`、阵元顺序和 `fixed_measurement_hash` 定义；
3. `TANGENT_PROFILE_SAFE` 仍为默认 K2 方法；
4. Core-Lite fixed-grid K2 仍为安全基线；
5. Tangent 与 fixed-grid 的选择只比较当前数据下的 concentrated log-likelihood；
6. 不允许 truth 进入中心估计、方向估计、cache 查询、候选评分或最终选择；
7. 不修改已完成的 Tangent、white-SNR 或 classical-baseline 证据；
8. 不复用 Step11.6 的旧 factor-2 数值缓存。

本分支已由当前执行提示词授权实现 Level-A exact cache/direct hybrid
provider。该授权不包括 Level-B 插值、Tangent 算法重标定、完整 white-SNR
Monte Carlo 或经典算法重跑。

## 3. 当前 Tangent 计算链

当前 Tangent 可以分为六个阶段。

| 阶段 | 当前作用 | cache 角色 |
|---|---|---|
| T0 | 阵元数据经固定 sequential DBF 和 whitening 得到 `Zseq_white` | 不介入 |
| T1 | Core-Lite K1 得到中心；Core-Lite K2 得到 fixed-grid 安全基线 | 第一版不介入 |
| T2 | 在 K1 中心构造单目标流形和解析一阶导数 | 第一版保持 direct |
| T3 | 构造投影残差、Fisher 型 metric 和 2-D 广义特征方向 | 不介入 |
| T4 | 沿方向对 `rho` 做 scan、bracket 和连续 profile；每个候选构造 K2 流形并计算 DML | **主要接入点** |
| T5 | Tangent 候选与 fixed-grid K2 比较并选择 upgrade/fallback | 不介入 |

第一版融合严格限定在 T4 的“候选流形构造”子阶段。

### 3.1 当前代码审计确认

本次以父提交 `3e7153ae11f8a49633a2edd2d2f710673e5d1bad` 审计确认：

1. profile 接入点是 `stage8_k2_tp_profile_scale` 内的
   `evaluate_rho_local`；
2. 当前 direct manifold 函数是
   `build_full_sequential_local_manifold`；
3. factor-1 steering 使用
   `exp(+j * 2*pi/lambda * r' * u(az,el))`；
4. legacy steering 经 `reshape_cyl_vector_to_matrix(...); matrix(:)` 转为
   当前 `Wseq` 的 canonical element order；
5. measurement physical center 来自当前工作子阵中心列：
   `model.array_meta.phiCol(model.array_meta.colCtr)`，而
   `model.array_meta.azCtr` 仅记录请求中心；
6. Level-A 只替换 T4 的 pair-manifold construction，不改变 K1 中心、
   Tangent 方向、rho 搜索或 DML 评分；
7. Core-Lite fixed-grid fallback 仍是 `TANGENT_PROFILE_SAFE` 的内部安全候选，
   不由 provider 替换或删除。

## 4. 统一数学模型

### 4.1 数据路径

对固定 measurement model `M`，当前数据路径为：

$$
Z_{\mathrm{raw}}
=
W_{M}^{H}Y_{\mathrm{element}},
$$

$$
Z_{\mathrm{white}}
=
T_{M}Z_{\mathrm{raw}}.
$$

其中：

- $W_M$ 对应 `model.Wseq` 或 `model.W_I`；
- $T_M$ 对应 `model.Tseq` 或 `model.T_I`；
- measurement identity 由 `model.fixed_measurement_hash` 固定。

### 4.2 单目标候选流形

对角度

$$
\theta=(az,el),
$$

定义白化 sequential beamspace manifold：

$$
\mathbf g_M(\theta)
=
T_M W_M^H\mathbf a_M(az,el).
$$

当前 direct 路径由 `build_full_sequential_local_manifold` 生成阵元导向矢量，再完成 $W_M^H$ 和 $T_M$ 投影。

### 4.3 双目标 Tangent 参数化

K1 中心记为：

$$
\widehat{\theta}_c
=
[\widehat{az}_c,\widehat{el}_c].
$$

Tangent 方向记为：

$$
\widehat{v}
=
[\widehat v_{az},\widehat v_{el}]^T,
\qquad
\|\widehat v\|_2=1.
$$

对任意正分离尺度 $\rho$，两个端点为：

$$
\theta_-(\rho)
=
\widehat{\theta}_c-
\frac{\rho}{2}\widehat v,
$$

$$
\theta_+(\rho)
=
\widehat{\theta}_c+
\frac{\rho}{2}\widehat v.
$$

对应 K2 流形为：

$$
G_M(\rho)
=
[\mathbf g_M(\theta_-(\rho)),\quad
 \mathbf g_M(\theta_+(\rho))].
$$

canonical cache 只替换上式中两列 $\mathbf g_M(\theta)$ 的生成方法。

## 5. 两种“中心”必须分离

融合时必须区分：

### 5.1 measurement center

记为：

$$
\phi_M.
$$

它是当前物理工作子阵、canonical order 和 DBF 码本的旋转参考中心。它属于 measurement model，不能由当前目标真值或 Tangent K1 结果定义。

### 5.2 Tangent K1 center

记为：

$$
\widehat{\theta}_c.
$$

它是当前观测数据给出的目标簇中心，用于生成 Tangent 双目标端点。

通常：

$$
\widehat{az}_c\ne\phi_M.
$$

因此，cache 的 canonical 方位坐标必须是：

$$
\delta
=
\operatorname{wrap}_{180}(az-\phi_M),
$$

不能直接用：

$$
az-\widehat{az}_c.
$$

后者只属于 Tangent 局部参数化。

## 6. factor-1 canonical 旋转等价

设 canonical 局部子阵中第 $m$ 个阵元位置为：

$$
\mathbf r_m^{(0)}.
$$

measurement center 为 $\phi_M$ 时，实际阵元位置为：

$$
\mathbf r_m^{(M)}
=
R_z(\phi_M)\mathbf r_m^{(0)}.
$$

方向单位向量为：

$$
\mathbf u(az,el)
=
[\cos el\cos az,\ \cos el\sin az,\ \sin el]^T.
$$

若：

$$
az=\phi_M+\delta,
$$

则：

$$
\mathbf u(\phi_M+\delta,el)
=
R_z(\phi_M)\mathbf u(\delta,el).
$$

于是：

$$
(\mathbf r_m^{(M)})^T
\mathbf u(\phi_M+\delta,el)
=
(\mathbf r_m^{(0)})^T
\mathbf u(\delta,el).
$$

对当前 factor-1 接收相位：

$$
a_m(az,el)
=
\exp\left(
 j\frac{2\pi}{\lambda}
 \mathbf r_m^T\mathbf u(az,el)
\right),
$$

可得：

$$
a_m^{(M)}(\phi_M+\delta,el)
=
a_m^{(0)}(\delta,el).
$$

在以下条件全部满足时，可复用 canonical beamspace manifold：

1. actual 与 canonical 工作子阵使用相同 local element order；
2. $W_M$ 与该 canonical order 一致；
3. $T_M$ 与当前 noise profile 和 measurement model 一致；
4. wavelength、阵列几何、active phase factor 均与 cache identity 一致。

因此定义：

$$
\mathcal C_M(\delta,el)
=
T_MW_M^H\mathbf a^{(0)}(\delta,el).
$$

对任意候选角度：

$$
\mathbf g_M(az,el)
=
\mathcal C_M(
\operatorname{wrap}_{180}(az-\phi_M),el
).
$$

## 7. Tangent profile 中的融合公式

对每个 $\rho$：

$$
\delta_-(\rho)
=
\operatorname{wrap}_{180}
(az_-(\rho)-\phi_M),
$$

$$
\delta_+(\rho)
=
\operatorname{wrap}_{180}
(az_+(\rho)-\phi_M).
$$

若两个端点都可由 cache 返回，则：

$$
G_{\mathrm{cache}}(\rho)
=
\begin{bmatrix}
\mathcal C_M(\delta_-(\rho),el_-(\rho)) &
\mathcal C_M(\delta_+(\rho),el_+(\rho))
\end{bmatrix}.
$$

之后仍执行当前：

1. stable rank check；
2. `concentrated_dml_rss`；
3. scan-node 最大值选择；
4. bracket 构造；
5. `fminbnd`；
6. final candidate re-evaluation；
7. 与 fixed-grid K2 的 log-likelihood 比较。

cache 不改变这些步骤。

## 8. 结果保持性质

若 exact cache 满足：

$$
G_{\mathrm{cache}}(\rho)
=
G_{\mathrm{direct}}(\rho),
$$

则：

$$
P_{G,\mathrm{cache}}
=
P_{G,\mathrm{direct}},
$$

$$
RSS_{\mathrm{cache}}(\rho)
=
RSS_{\mathrm{direct}}(\rho),
$$

$$
\ell_{\mathrm{cache}}(\rho)
=
\ell_{\mathrm{direct}}(\rho).
$$

从而：

$$
\widehat\rho_{\mathrm{cache}}
=
\widehat\rho_{\mathrm{direct}},
$$

并保持最终 Tangent/fixed-grid 选择不变。

第一版接口要求同列顺序下直接数值一致，不依赖相位对齐后等价作为默认合同。

## 9. 必须采用的分层融合架构

当前 Tangent 的方向和 `fminbnd` 候选是连续的，旧 Step11.6 的 fixed exact-grid cache 不能保证高命中率。因此架构分成两个层级。

### 9.1 Level A：结果保持型 provider，必须先实现

```text
每个单目标 endpoint
  -> 验证 cache identity
  -> exact cache lookup
     -> hit: 返回 cached g
     -> miss: 调用 factor-1 direct G-only builder
  -> 两列拼成 G
  -> 当前 rank/DML 评分
```

Level A 的目的：

- 建立干净的 provider 接口；
- 证明 cache/direct 可交换；
- 记录真实 hit/miss；
- 不改变 Tangent 搜索结果；
- 为后续更有收益的加速策略提供安全基线。

允许一列 cache hit、另一列 direct fallback。两列只要属于同一 `fixed_measurement_hash`，即可拼成同一个 $G$。

### 9.2 Level B：cache-assisted scan screening，后续可选

若 Level A 的 exact hit rate 过低，可研究：

```text
33-point rho scan
  -> canonical cache interpolation / fast approximation
  -> 选择 top-M scan nodes 及邻域
  -> 对 shortlist 做 direct exact re-score
  -> 用 exact score 决定 bracket
  -> fminbnd 和最终候选继续 direct exact
```

Level B 的边界：

- approximate cache 只用于候选筛选；
- final likelihood 和最终输出必须 direct exact 认证；
- score gap 小、rank 风险高、插值状态异常时回退完整 direct scan；
- 是否采用插值、插值阶数和网格步长均未在本架构中冻结。

Level B 不属于第一版默认实现，必须在 Level A 完成后单独决策。

## 10. 为什么 T2 导数阶段第一版保持 direct

Tangent 方向阶段需要：

$$
\mathbf g_c,
\quad
\frac{\partial\mathbf g}{\partial az},
\quad
\frac{\partial\mathbf g}{\partial el}.
$$

理论上导数也具有旋转等价性，但第一版不缓存导数，原因是：

1. 每个 trial 只在 K1 中心计算一次；
2. K1 中心通常不是 exact grid 点；
3. 当前导数坐标为 radian；
4. 缓存三组复向量会显著增加内存；
5. 导数误差会直接影响 $T$、$C_t$ 和方向 $\widehat v$；
6. 主要重复成本位于 T4 的多次 pair-manifold 构造。

所以第一版保持：

```text
K1-center g + analytic derivatives -> direct
rho-profile pair G              -> hybrid provider
```

## 11. Direct 路径需要 G-only 化

当前 `build_full_sequential_local_manifold` 即使调用者忽略导数，也会构造：

- element-domain steering；
- azimuth derivative；
- elevation derivative；
- 三组 beamspace projection。

T4 的每个 $\rho$ 只需要 $G$，不需要导数。因此新架构要求一个明确的 direct G-only 路径：

```text
build_full_sequential_single_target_g_only
或
build_full_sequential_local_manifold(..., ComputeDerivatives=false)
```

这有两个作用：

1. direct fallback 不再计算无用导数；
2. cache 与 direct runtime 对比不会把无关导数成本算入 cache 收益。

G-only 优化不改变数学模型。

## 12. cache 内容与身份

第一版推荐按 measurement model 缓存白化后的单目标向量：

$$
\mathcal C_M(\delta,el)
=
T_MW_M^H a^{(0)}(\delta,el).
$$

不缓存：

- 双目标排列；
- projector；
- DML score；
- observation-dependent 结果；
- Tangent direction；
- `rho` 最优值。

cache identity 至少包含：

```text
cache_version
fixed_measurement_hash
measurement_config_id
noise_profile_id
phase_factor = 1
array_geometry_hash
canonical_element_order
lambda
W_hash
T_hash
measurement_center_az_deg
delta_grid_hash
el_grid_hash
numeric_class
```

任一 identity 不匹配时，不允许 lookup，必须 direct fallback 或拒绝加载。

第一版使用 complex double 作为科学基线。single、定点或 FPGA 存储不属于当前架构实施范围。

## 13. 建议模块边界

后续代码建议独立放置于：

```text
tools/stage8_k2_tangent_canonical_cache/
├── README.md
├── matlab/
│   ├── stage8_k2_tcc_build_canonical_geometry.m
│   ├── stage8_k2_tcc_build_cache.m
│   ├── stage8_k2_tcc_build_cache_key.m
│   ├── stage8_k2_tcc_validate_cache_identity.m
│   ├── stage8_k2_tcc_lookup_exact.m
│   ├── stage8_k2_tcc_build_g_direct.m
│   ├── stage8_k2_tcc_get_single_target_g.m
│   ├── stage8_k2_tcc_get_pair_manifold.m
│   └── stage8_k2_tcc_profile_adapter.m
└── tests/
    ├── test_factor1_rotation_equivalence.m
    ├── test_exact_cache_matches_direct_g.m
    ├── test_pair_manifold_mixed_provider.m
    ├── test_profile_score_equivalence.m
    └── test_cache_identity_rejection.m
```

本文件只定义目录和职责，不创建这些文件。

## 14. 建议接口

### 14.1 cache 构建

```matlab
[cache, metadata] = stage8_k2_tcc_build_cache( ...
    model, canonical_geometry, grid_spec, options)
```

输入：

- 当前 factor-1 measurement model；
- canonical geometry；
- delta/el grid；
- numeric class 和构建选项。

输出：

- 单目标 whitened manifold cache；
- 完整 identity metadata。

### 14.2 单目标 provider

```matlab
[g, info] = stage8_k2_tcc_get_single_target_g( ...
    angle_deg, model, cache, options)
```

`info` 至少包含：

```text
source = CACHE_EXACT | DIRECT_FALLBACK
cache_hit
cache_miss_reason
delta_az_deg
el_deg
fixed_measurement_hash_match
phase_factor_match
element_order_match
runtime_sec
```

### 14.3 双目标 provider

```matlab
[G, info] = stage8_k2_tcc_get_pair_manifold( ...
    angles_deg, model, cache, options)
```

该接口逐列查询，并在最终 $G$ 上执行与当前一致的 stable-rank 诊断。

### 14.4 Tangent adapter

`stage8_k2_tp_profile_scale` 未来只调用 pair provider，不直接知道 cache 的内部存储结构。

这样可以通过配置切换：

```text
DIRECT_ONLY
EXACT_CACHE_OR_DIRECT
CACHE_SCREEN_DIRECT_CERTIFY   (future)
```

## 15. 运行生命周期

建议生命周期为：

```text
构建 context / resolve measurement model
  -> 按 fixed_measurement_hash 加载或构建 cache 一次
  -> 每个 trial 继续运行当前 K1/fixed-grid
  -> Tangent T2/T3 direct
  -> Tangent T4 调用 hybrid provider
  -> current DML / safe selection
  -> 汇总 hit、miss、runtime 和 equivalence
```

cache 是 measurement-level 对象，不应在每个 `rho`、每个 trial 内重复构建。

## 16. 第一版最小验证问题

架构后续只需要围绕创新点验证以下问题，不扩展为新的算法认证体系。

### V1：factor-1 旋转等价

在多个工作子阵中心、多个 relative azimuth 和 elevation 上比较：

$$
g_{\mathrm{actual}}
\quad\text{vs.}\quad
g_{\mathrm{canonical}}.
$$

### V2：single-target cache/direct 等价

比较 exact-grid 点上的：

- relative $G$ error；
- maximum absolute error；
- measurement identity；
- element order。

### V3：pair-manifold 和 DML 等价

比较：

- pair $G$；
- numerical rank；
- singular values；
- RSS；
- concentrated log-likelihood。

### V4：Tangent profile 等价

在 `DIRECT_ONLY` 与 `EXACT_CACHE_OR_DIRECT` 下比较：

- evaluated `rho` sequence；
- scan-node scores；
- selected bracket；
- final `rho_hat`；
- final angles；
- upgrade/fallback decision。

### V5：实际收益

记录：

- cache build/load time；
- cache memory；
- exact hit rate；
- direct fallback rate；
- manifold-only runtime；
- profile runtime；
- end-to-end Tangent runtime。

本架构不冻结数值阈值、trial 数或正式 pass/fail 条件。

## 17. 风险与明确边界

### 17.1 连续查询导致 exact hit 低

当前 `rho`、K1 center 和 Tangent direction 都是连续量。Level A 可能主要完成接口与正确性，而不是带来最终速度提升。

### 17.2 插值对近邻双目标敏感

Tangent 工作区域中两列 manifold 可能高度相关。插值误差可能放大 projector、rank 和 likelihood 的误差，因此插值不能直接承担最终候选认证。

### 17.3 measurement identity 变化

只要 $W$、$T$、noise profile、阵元顺序、波长或几何发生变化，旧 cache 必须失效。

### 17.4 旧 Step11.6 不能直接迁移

旧 cache 只可用于理论和历史审计参考。当前实现必须重新构建 factor-1、current-measurement-aware cache。

### 17.5 FPGA 不在当前范围

当前 cache 位于 CPU 后端。FPGA 仍只推进 sequential DBF。ROM/BRAM/URAM 映射属于未来系统部署问题，不属于本分支第一阶段。

## 18. 明确非目标

本架构不做：

- 修改 Tangent direction；
- 重新调整 Tangent constants；
- 修改 `rho` 参数化；
- 修改 concentrated DML；
- 修改 safe upgrade/fallback；
- 修改 Core-Lite、Core-Plus 或 classical baselines；
- 修改 automatic-K 或 bootstrap；
- 恢复 C05；
- 建立新的 online selector；
- 使用 truth；
- 直接实现插值；
- 直接实现 FPGA ROM；
- 重新运行 white-SNR 全比较。

## 19. 分支推进顺序

后续若获得单独授权，建议顺序为：

```text
A. 公式/identity 审计
B. direct G-only builder
C. factor-1 canonical cache builder
D. exact single/pair provider
E. 仅接入 Tangent profile manifold call site
F. direct-vs-hybrid 等价性和 runtime 小规模验证
G. 根据真实 hit rate 决定是否研究 Level B
```

不得从本架构文档直接推断已经授权实现、实验、提交结果或合并父分支。

## 20. 当前停止点

当前状态：

```text
BRANCH_CREATED
ARCHITECTURE_DEFINED
NO_PROMPT
NO_CODE
NO_RUNTIME
NO_TANGENT_MODIFICATION
NO_PARENT_BRANCH_CHANGE
```

下一步必须由用户明确决定：

```text
REVIEW_ARCHITECTURE
```
