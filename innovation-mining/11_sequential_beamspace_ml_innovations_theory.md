# 顺序数字波束形成下的局部未分辨目标簇波束域 ML：经验证收束后的创新点、完整公式与算法边界

> 建议保存路径：`innovation-mining/11_sequential_beamspace_ml_innovations_theory.md`  
> 默认仓库：`makabaka165/bs_innovation`  
> 文档修订日期：2026-07-29（UTC）  
> 当前探索分支：`experiment/stage8-core-v2`  
> 当前证据提交：`fe5dd07fd67e1d3f701dabbc3a61b5dd10d09968`  
> 稳定主线：`main@247fad2208e77b04f7062e22b0fd3fd8a81bfc1f`，科学父提交为 `64cd2d6eae0813f8fd9266ec9ffe6bab4f616267`。  
> 当前总体状态：`STAGE8_CORE_V2_1_SAFE_KNOWN_K_CLOSURE_PASS`。已知 \(K\) 的安全估计核心在注册的 24-trial 诊断集上完成闭环；自动目标数判定、bootstrap threshold、resolved/unresolved、完整 6000-trial validation 与 Stage8.2 均保持 `DEFERRED_NOT_FAILED / NOT_EXECUTED`。  
> 本文取代 2026-07-17 版本的候选路线组织，但不删除旧理论、失败路线和执行证据；旧版本应归档为 superseded 文档。

> 必须联合阅读的当前证据：
>
> - `innovation-mining/06_formula_prior_art.md`
> - `innovation-mining/06_algorithm_prior_art.md`
> - `innovation-mining/06_closest_work_matrix.md`
> - `innovation-mining/15_stage6_tangent_theory_validation_audit.md`
> - `innovation-mining/16_stage7_exact_subset_fim_audit.md`
> - `innovation-mining/23_stage8_compact_algorithm_diagnostic.md`
> - `innovation-mining/24_stage8_r1_continuous_refinement_decisive_experiment.md`
> - `innovation-mining/26_stage8_core_v2_known_k_pruning_experiment.md`
> - `innovation-mining/27_stage8_core_v2_1_safe_hybrid_closure.md`
> - `innovation-mining/archive/failed/FAILED_likelihood_discriminative_adaptive_wb.md`
>
> 新颖性永久边界：接收圆柱阵流形、DML、SVD/QR 投影、白化、坐标上升、投影 Jacobian Fisher 信息、压缩前后归一化 FIM、FIM 约束最少选择、中心–差分参数化、bootstrap、source enumeration 和 unresolved 均有明确 prior art。本文允许保留的贡献，只能是：
>
> 1. 固定、精确白化的实际顺序接收波束二维流形上的近双目标显式局部推论；
> 2. 在实际顺序 DBF 接口上，已知 \(K\) 的固定网格粗初始化、完整顺序流形连续 DML 与确定性安全回退所组成的精简算法；
> 3. 分组/条件初始化作为 K2 的可选 rescue start 所表现出的场景化收益；
> 4. 相关规则顺序波束库下相对阵元域 FIM 保真与结构化成本的系统特化分析。
>
> 本文不再把自动 \(K\) 判定、自适应 W/B、bootstrap threshold、六状态机、K=3 或 Stage8.2 作为当前算法主线。

---

## 0. 经验证收束后的创新层级与 prior-art 边界

### 0.1 核心理论贡献：固定白化顺序二维流形的近双目标统一局部渐近式

在固定物理顺序波束矩阵 \(W_{\rm seq,0}\) 和固定精确白化坐标 \(T_0\) 下，定义

\[
g(\boldsymbol\xi)
=
T_0W_{\rm seq,0}^{H}a(\boldsymbol\xi),
\qquad
\boldsymbol\xi=
\begin{bmatrix}\phi\\\theta\end{bmatrix}.
\]

对近邻双目标

\[
\boldsymbol\xi_{1,2}
=
\mathbf c\mp\frac{\mathbf d}{2},
\]

定义

\[
T_{\rm seq}(\mathbf c)
=
\operatorname{Re}
\left\{
J_g^H(\mathbf c)
\Pi_{g(\mathbf c)}^\perp
J_g(\mathbf c)
\right\}.
\]

在

\[
q(\mathbf c,\mathbf d)
=
\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d>0
\]

时，有

\[
\boxed{
\sigma_2^2(G_2)
=
\frac12\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d
+
o(\|\mathbf d\|^2)
}
\]

\[
\boxed{
1-|\rho|^2
=
\frac{\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d}
{\|g(\mathbf c)\|_2^2}
+
o(\|\mathbf d\|^2)
}
\]

以及

\[
\boxed{
\kappa(\bar G_2^H\bar G_2)
\sim
\frac{4\|g(\mathbf c)\|_2^2}
{\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d}
}.
\]

阶段 6 已对 4 个物理主配置、9 个中心、4 个方向和 9 级分离尺度形成的 1296 个 secant case 进行验证，144 个注册非退化尾区全部通过。该贡献定位为：

```text
THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY
```

它是经典投影 FIM 几何在实际固定白化顺序二维流形上的显式场景化推论，不是新的 Fisher 信息矩阵，也不替代有限样本性能分析。

### 0.2 核心算法贡献：已知 K 的顺序波束域安全连续 DML

当前算法不再内部估计 \(K\)。输入明确提供

\[
K\in\{1,2\}.
\]

最小算法由以下步骤组成：

```text
固定 measurement 与白化
→ 固定网格 concentrated DML 粗估计
→ 在完整顺序二维流形上进行连续 refinement
→ 连续候选有效且集中似然不低于固定网格时升级
→ 否则返回固定网格结果
```

对 \(K=1\)，连续 refinement 在注册诊断集上得到：

```text
16/16 valid
off-grid median joint RMSE:
0.141421356° → 0.011388568°
```

即中位误差约改善 12.4 倍。因此，固定网格应降级为初始化和保底，连续完整顺序流形 DML 是当前最明确的算法性正面结果。

### 0.3 可选算法增强：分组/条件 K2 初始化与中心–分离连续 refinement

分组/条件链已经实现：

```text
俯仰 MMV DML
→ 俯仰组数据恢复
→ 条件方位 DML
→ 完整顺序流形 K2 refinement
```

但它不再是默认必选主链。原始 continuous K2 结果为：

```text
direct continuous K2:  2/8 valid
grouped continuous K2: 4/8 valid
```

在固定网格安全回退后：

```text
H1 direct hybrid:  K2 8/8 valid, median RMSE 0.141681308°
H2 grouped hybrid: K2 8/8 valid, median RMSE 0.140071055°
H2 vs H1: 4 wins / 4 ties / 0 losses
```

grouped 模式在 easy K2 子集的中位 RMSE 为 `0.093647917°`，但在 moderate 子集没有形成稳定改善，且计算成本更高。因此最终定位是：

```text
STAGE8_CORE_V2_1_OPERATIONAL_GROUPED_OPTIONAL
```

即 grouped/conditional initialization 只作为 K2 的可选 rescue start 或高精度模式，不作为最小算法的必需组件。

### 0.4 系统设计结果：相对阵元域 FIM 保真与结构化成本

旧经验 W-score 已被替换为：

\[
\eta(I)
=
\inf_{\zeta\in\Xi_{\rm id}}
\lambda_{\min}^{+}
\left[
F_{\rm elem}^{\dagger/2}(\zeta)
F_I(\zeta)
F_{\rm elem}^{\dagger/2}(\zeta)
\right],
\]

并求解

\[
\min_{I_e,I_a} C(I_e,I_a)
\]

满足

\[
\eta(I_e,I_a)\ge \eta_0.
\]

其中 \(C\) 包含俯仰 DBF、方位 DBF、输出通道、权重存储和数据搬运成本。

Stage7 已完整枚举 961 个矩形子集并完成 1184 个 FIM 场景与 52,200 个有限样本 method-trials。结果表明：

```text
eta0=0.80 的 exact 解：
RECT_E14_A31 = 中心 3 个俯仰波束 × 全部 5 个方位波束

但该解与最强固定基线 FIXED_RECT_3X5 完全相同。
```

因此该部分的最终定位是：

```text
PASS_SYSTEM_ANALYSIS_ONLY
```

它证明了更科学的设计指标和系统配置，但没有证明新的波束选择算法优于固定矩形基线。

### 0.5 已否决或长期 deferred 的路线

| 路线 | 最终状态 | 当前处理 |
|---|---|---|
| 在线自适应 W/B | 正式实验无 Pareto 收益，运行时间显著增加 | `FAILED`，不恢复 |
| 固定网格 unknown-K + bootstrap threshold | compact K1 false split `30/60=0.50` | 不再作为当前主线 |
| 连续 K1/K2 model-order recovery | 连续 K2 solver 只部分返回 | `MODEL_ORDER_DEFERRED` |
| resolved/unresolved 六状态闭环 | 依赖尚未成立的 unknown-K 层 | 长期 deferred |
| 完整 6000-trial formal validation | 对已知失败闭环无信息增益 | `DEFERRED_NOT_FAILED` |
| K=3 扩展 | 未实现，非当前核心 | future work |
| Stage8.2 | 未授权、未执行 | 不进入 |
| 第三版连续 K2 solver | 协议明确停止继续迭代 | 不设计 |

### 0.6 原子主张的最终定位

| 原子内容 | 当前定位 | 论文中允许的表述 |
|---|---|---|
| 接收单程圆柱阵流形、条件 Kronecker 表示 | 正确建模基础 | 顺序 DBF 与后续推导的物理基础 |
| 稳定白化集中 DML、SVD/QR 投影 | 经典数值实现 | 稳定内核，不单列创新 |
| 固定网格 coarse DML | 基线和安全回退 | 初始化、保底、可复现 baseline |
| 完整顺序流形 continuous K1 refinement | 已验证的算法核心 | off-grid K1 精度显著改善 |
| K2 中心–分离 continuous refinement | 部分有效 | 可选精度增强，不声称普遍收敛 |
| 分组条件 DML | 可选 K2 rescue initialization | 场景化工程增强，非必选核心 |
| \(T_{\rm seq}\) 局部二次型 | 经典 FIM 几何的系统特化 | 用于场景化推导 |
| \(\sigma_2\)–相关性–条件数统一渐近式 | 候选核心理论贡献 | 固定白化顺序流形上的显式局部推论 |
| 相对阵元域 FIM 保真波束设计 | 系统设计分析 | 不称新的波束选择算法 |
| automatic K / bootstrap / unresolved | 当前闭环失败或未完成 | future work，不进入当前贡献 |

### 0.7 明确禁止的创新表述

不得写成：

- 首次提出 beamspace DML；
- 首次提出连续 DML、AP、坐标上升或 SVD 投影；
- 首次提出投影 Jacobian Fisher 信息矩阵；
- 中心–分离参数化自动降低 K2 连续自由度；
- grouped initialization 已被证明普遍优于 direct initialization；
- safe fallback 解决了 unknown-K；
- fixed-grid fallback 的 8/8 valid 等同于 continuous K2 8/8 收敛；
- FIM exact-subset 设计优于最强固定 3×5 基线；
- bootstrap threshold 已控制连续 off-grid K1 false split；
- 当前算法已完成 Stage8.1 validation 或 Stage8.2；
- 当前结果已支持任意目标数或 K=3。

---

## 1. 系统层级与问题定义

### 1.1 系统位置

统一采用以下系统层级：

| 层级 | 推荐名称 | 内容 |
|---|---|---|
| 1 | 阵元数字接收链路 | 射频接收、下变频、ADC、数字下变频和脉压 |
| 2 | 常规顺序 DBF 与检测 | 俯仰 DBF、方位 DBF、MTD、CFAR、常规粗测角 |
| 3 | 局部波束域精细测角 | 在已定位局部角单元内执行 known-K DML 精细估计 |
| 4 | 航迹与资源管理 | 数据关联、跟踪、跨 CPI 处理和波束调度 |

本文算法位于第 3 层：

> **常规顺序 DBF 之后、给定局部角单元和已知目标数 \(K\) 的波束域精细二维测角模块。**

### 1.2 当前输入与输出

输入：

```text
局部 element-domain 或顺序波束域复观测
固定 measurement model
固定噪声协方差与白化器
局部角域 Ω
已知 K ∈ {1,2}
运行模式 CORE_LITE 或 CORE_PLUS
```

输出：

```text
K 个连续二维角度估计
fit validity
selected source:
  CONTINUOUS_UPGRADE
  FIXED_GRID_FALLBACK
RSS / concentrated log-likelihood
solver status
```

当前不输出：

```text
自动 K
K2_RESOLVED / K2_UNRESOLVED
false-split confidence
model-mismatch state
```

### 1.3 局部角域假设

当前算法把局部角域视为常规检测和粗测角给定的输入，不再在本算法中实现自适应局部域。候选域在一次估计内必须固定，不能根据候选角、truth 或中间分数改变 measurement、白化器或域边界。

---

## 2. 接收单程圆柱阵模型

### 2.1 几何与方向单位矢量

圆柱阵第 \(m\) 个环向位置、第 \(n\) 个垂直阵元的位置为

\[
\mathbf r_{m,n}
=
\begin{bmatrix}
R\cos\psi_m\\
R\sin\psi_m\\
z_n
\end{bmatrix}.
\]

方向单位矢量为

\[
\mathbf u(\phi,\theta)
=
\begin{bmatrix}
\cos\theta\cos\phi\\
\cos\theta\sin\phi\\
\sin\theta
\end{bmatrix},
\qquad
k_0=\frac{2\pi}{\lambda}.
\]

### 2.2 接收阵列单程空间相位

接收导向项固定为

\[
\boxed{
a_{m,n}(\phi,\theta)
=
\exp\left(
jk_0\mathbf r_{m,n}^{T}\mathbf u(\phi,\theta)
\right)
}
\]

即

\[
\boxed{\eta_{\rm phase}=1}.
\]

目标距离产生的双程公共传播相位吸收到目标复包络中，不再重复乘入接收空间导向矢量。

### 2.3 阵元域模型

第 \(l\) 个观测快拍：

\[
\mathbf y_l
=
A(\Theta)\mathbf s_l+\mathbf n_l,
\]

\[
A(\Theta)
=
[
\mathbf a(\phi_1,\theta_1),\ldots,
\mathbf a(\phi_K,\theta_K)
].
\]

堆叠 \(L\) 个快拍：

\[
Y=A(\Theta)S+N,
\qquad
\mathbf n_l\sim\mathcal{CN}(\mathbf0,R_n).
\]

---

## 3. 圆柱阵的条件可分解结构

展开内积：

\[
\mathbf r_{m,n}^{T}\mathbf u(\phi,\theta)
=
R\cos\theta\cos(\phi-\psi_m)
+
z_n\sin\theta.
\]

因此

\[
a_{m,n}(\phi,\theta)
=
a_{\phi,m}(\phi,\theta)
a_{z,n}(\theta),
\]

并在统一阵元顺序下写成

\[
\boxed{
\mathbf a(\phi,\theta)
=
\mathbf a_\phi(\phi,\theta)
\otimes
\mathbf a_z(\theta)
}.
\]

由于

\[
\mathbf a_\phi=\mathbf a_\phi(\phi,\theta),
\]

圆柱阵并不是严格的 \(a_\phi(\phi)\otimes a_z(\theta)\) 完全解耦模型。

该结构支持：

```text
俯仰分组
→ 条件方位初始化
→ 完整二维顺序流形修正
```

但当前 grouped 路线只作为 K2 可选初始化，最终估计始终在完整顺序流形上完成或回退到固定网格完整流形结果。

---

## 4. 顺序 DBF 的矩阵信号模型

### 4.1 阵元数据矩阵

将快拍重排为

\[
Y_l\in\mathbb C^{N_z\times N_\phi},
\]

则

\[
Y_l
=
\sum_{k=1}^{K}
s_{k,l}
\mathbf a_z(\theta_k)
\mathbf a_\phi^T(\phi_k,\theta_k)
+
N_l.
\]

### 4.2 先俯仰 DBF

令

\[
V=[v_1,\ldots,v_{B_e}]
\in\mathbb C^{N_z\times B_e},
\]

则

\[
Z_{e,l}=V^HY_l.
\]

俯仰输出保留环向列，不得直接把它等价成若干独立时间快拍。

### 4.3 条件方位 DBF 与完整顺序 measurement

对每个俯仰通道使用方位波束 \(u_{c|b}\)，定义

\[
w_{b,c}=u_{c|b}\otimes v_b.
\]

将所有输出堆叠为

\[
W_{\rm seq}
=
[w_{1,1},\ldots,w_{B_e,B_a}].
\]

波束域噪声协方差为

\[
C_b=W_{\rm seq}^HR_nW_{\rm seq}.
\]

固定有效子空间白化器为

\[
T_b=C_b^{\dagger/2}.
\]

白化数据与流形：

\[
\widetilde Z=T_bW_{\rm seq}^HY,
\]

\[
g_{\rm seq}(\phi,\theta)
=
T_bW_{\rm seq}^Ha(\phi,\theta).
\]

候选搜索期间 \(W_{\rm seq}\)、\(C_b\)、\(T_b\) 和有效秩固定。

---

## 5. 经验证的核心算法：Known-K Safe Hybrid DML

### 5.1 稳定 concentrated DML

对候选角集合 \(\Theta_K\)，构造

\[
G_K(\Theta_K)
=
[
g_{\rm seq}(\boldsymbol\xi_1),\ldots,
g_{\rm seq}(\boldsymbol\xi_K)
].
\]

令 economy SVD 为

\[
G_K=U\Sigma V^H.
\]

按相对秩阈值保留 \(U_r\)，评分为

\[
\boxed{
J_K(\Theta_K)
=
\|U_r^H\widetilde Z\|_F^2
}
\]

残差为

\[
\boxed{
RSS_K(\Theta_K)
=
\|\widetilde Z\|_F^2-J_K(\Theta_K)
}.
\]

集中噪声方差和对数似然：

\[
\widehat\sigma_K^2
=
\frac{RSS_K}{r_CL},
\]

\[
\ell_K^\star
=
-r_CL
\left[
\log(\pi\widehat\sigma_K^2)+1
\right].
\]

### 5.2 固定网格候选 B0

固定网格 concentrated DML 是：

```text
粗初始化
可复现 baseline
安全回退
```

它不再被视为连续真值的最终模型，但在当前注册 known-K K2 诊断集中 8/8 返回有效结果。

### 5.3 K1 Core-Lite

K1 默认路径：

```text
B0 fixed-grid K1
+
conventional singleton start
+
continuous full-sequential refinement
+
safe selection
```

选择不使用 truth。若 continuous fit 有效，且

\[
\ell_{\rm cont}\ge\ell_{\rm grid},
\]

则输出 continuous；否则输出 grid。

在当前 16 个 K1 trial 上，continuous candidate 16/16 有效，off-grid 中位联合 RMSE 从 `0.141421356°` 降到 `0.011388568°`。

因此，K1 不需要 grouped start 作为默认候选。

### 5.4 K2 Core-Lite

K2 最小默认路径：

```text
fixed-grid known-K K2 fit
```

原因：

- 当前 B0 在 8/8 注册 K2 trial 中有效；
- direct continuous 仅 2/8 有效；
- grouped continuous 仅 4/8 有效；
- 继续设计第三版 solver 会重新进入复杂求解循环。

Core-Lite 追求稳定与简洁，不强制连续 K2。

### 5.5 K2 Core-Plus

可选高精度路径：

```text
B0 fixed-grid K2
+
grouped/conditional K2 start
+
center-difference continuous refinement
+
safe selection
```

当 continuous candidate 有效且集中似然不低于 B0 时升级，否则回退 B0。

Core-Plus 对应当前

```text
H2_GROUPED_SAFE_HYBRID_KNOWN_K
```

在注册集上：

```text
K2 8/8 valid
continuous upgrade 4/8
fixed-grid fallback 4/8
K2 median RMSE 0.140071055°
easy K2 median RMSE 0.093647917°
moderate K2 median RMSE 0.156242749°
```

### 5.6 安全选择公式

对同一个已知 \(K\)，令 \(\widehat\Theta_g\) 为有效固定网格 fit，\(\widehat\Theta_c\) 为 continuous candidate。定义

\[
\boxed{
\widehat\Theta_{\rm safe}
=
\begin{cases}
\widehat\Theta_c,
&
\text{continuous valid 且 }
\ell^\star(\widehat\Theta_c)
\ge
\ell^\star(\widehat\Theta_g),\\[1ex]
\widehat\Theta_g,
&
\text{其他情况}.
\end{cases}
}
\]

该规则只读取：

```text
trial identity
fit validity
concentrated log-likelihood
```

不读取：

```text
truth
RMSE
SNR
noise profile
difficulty label
```

因此它是同一 known-K 模型内的数值安全策略，不是模型阶数自适应。

### 5.7 当前证据汇总

| 方法 | K1 valid | K2 valid | K1 off-grid median RMSE | K2 median RMSE | 定位 |
|---|---:|---:|---:|---:|---|
| B0 fixed-grid | 16/16 | 8/8 | 0.141421356° | 0.148962029° | baseline / fallback |
| B1 direct continuous | 16/16 | 2/8 | 0.011388568° | 0.149437254°（仅 valid rows） | K1 核心、K2 baseline |
| B2 grouped continuous | 16/16 | 4/8 | 0.011388568° | 0.093647917°（仅 valid rows） | optional K2 candidate |
| H1 direct safe hybrid | 16/16 | 8/8 | 0.011388568° | 0.141681308° | operational |
| H2 grouped safe hybrid | 16/16 | 8/8 | 0.011388568° | 0.140071055° | operational, grouped optional |

注意：H1/H2 closure 重用了既有 24 trials 和 72 个 B0/B1/B2 rows，没有增加新的独立统计样本。它证明的是架构闭环和安全选择，不是新的泛化性能认证。

---

## 6. 完整顺序流形连续修正

### 6.1 单目标顺序响应

\[
g_{b,c}(\phi,\theta)
=
\left[
u_{c|b}^Ha_\phi(\phi,\theta)
\right]
\left[
v_b^Ha_z(\theta)
\right].
\]

堆叠全部 \((b,c)\) 后得到固定白化顺序流形 \(g_{\rm seq}\)。

### 6.2 K1 连续 refinement

以 coarse-grid 角度为初值，对方位和俯仰依次执行有界一维改进。每次更新只在 DML 分数不下降时接受。

若

\[
J^{(t+1)}\ge J^{(t)}
\]

且 \(J\) 有界，则分数序列收敛。该性质不保证全局最优，只保证数值单调。

### 6.3 K2 中心–分离参数化

对可选 K2 continuous candidate，使用

\[
\boldsymbol\xi_1
=
\mathbf c-\frac{\mathbf d}{2},
\qquad
\boldsymbol\xi_2
=
\mathbf c+\frac{\mathbf d}{2}.
\]

内部变量为

```text
c_az, c_el, d_az, d_el
```

参数化只消除目标标签交换冗余，不降低 K2 的四个连续自由度。

当前 solver 已消除逐坐标更新时的 target-row 重排问题，但仍只在部分 K2 trial 上满足可用合同，因此它保持 optional。

### 6.4 停止条件和不再继续的边界

连续更新使用统一停止条件：

\[
\frac{J^{(t+1)}-J^{(t)}}
{\max(|J^{(t)}|,\epsilon)}
\le\varepsilon_J
\]

并满足角度更新阈值。

当前不再：

- 为不同难度设置不同规则；
- 增加第三版 K2 solver；
- 增加 rescue starts；
- 通过放宽 rank 或收敛门强行提高 valid count；
- 把 max-sweeps 中间结果包装成普遍可用解。

---

## 7. 核心理论：固定白化顺序流形的近双目标统一渐近式

### 7.1 正式假设

1. \(W_{\rm seq,0}\) 固定；
2. \(T_0\) 和白化有效秩固定；
3. \(g\) 在中心附近至少三次连续可微；
4. \(g(\mathbf c)\neq0\)；
5. \(\mathbf d\) 是实二维角增量；
6. 主结果只用于 \(q(\mathbf c,\mathbf d)>0\)。

### 7.2 Jacobian 与投影几何

\[
J_g(\mathbf c)
=
\left[
\frac{\partial g}{\partial\phi},
\frac{\partial g}{\partial\theta}
\right]_{\mathbf c},
\]

\[
\Pi_g^\perp
=
I-\frac{gg^H}{g^Hg},
\]

\[
T_{\rm seq}
=
\operatorname{Re}
\{J_g^H\Pi_g^\perp J_g\}.
\]

对于未知复幅度单目标模型，

\[
F_\xi
=
\frac{2|s|^2}{\sigma^2}T_{\rm seq}.
\]

### 7.3 圆柱阵单程流形导数

以弧度为求导单位：

\[
\frac{\partial a_{\phi,m}}{\partial\phi}
=
-jk_0R\cos\theta\sin(\phi-\psi_m)a_{\phi,m},
\]

\[
\frac{\partial a_{\phi,m}}{\partial\theta}
=
-jk_0R\sin\theta\cos(\phi-\psi_m)a_{\phi,m},
\]

\[
\frac{\partial a_{z,n}}{\partial\theta}
=
jk_0z_n\cos\theta\,a_{z,n}.
\]

固定白化顺序流形导数为

\[
\frac{\partial g}{\partial\xi}
=
T_0W_{\rm seq,0}^H
\frac{\partial a}{\partial\xi}.
\]

### 7.4 第二奇异值、相关性与条件数

对

\[
G_2
=
[
g(\mathbf c-\mathbf d/2),
g(\mathbf c+\mathbf d/2)
],
\]

经对称 Taylor 展开和和差酉变换得到：

\[
\sigma_2^2(G_2)
=
\frac12\mathbf d^TT_{\rm seq}\mathbf d
+
o(\|\mathbf d\|^2).
\]

归一化相关性满足：

\[
1-|\rho|^2
=
\frac{\mathbf d^TT_{\rm seq}\mathbf d}
{\|g(\mathbf c)\|_2^2}
+
o(\|\mathbf d\|^2).
\]

列归一化 Gram 条件数满足：

\[
\kappa(\bar G_2^H\bar G_2)
\sim
\frac{4\|g(\mathbf c)\|_2^2}
{\mathbf d^TT_{\rm seq}\mathbf d}.
\]

### 7.5 零方向与高阶退化

若

\[
\mathbf d^TT_{\rm seq}\mathbf d=0,
\]

则二次主导项消失。六阶候选式只在 synthetic analytic fixture 上得到验证，四个物理主配置没有发现 exact tangent null。因此：

```text
物理非退化二次渐近式：保留
synthetic 六阶式：仅作边界说明
物理六阶普遍结论：禁止
```

### 7.6 几何理论与有限样本必须分开

局部几何不能单独预测：

- 弱次目标检出；
- 强相关源有限样本退化；
- 错误局部峰；
- unknown-K false split；
- continuous solver 返回率。

因此理论贡献与 safe known-K 算法证据必须分别陈述。

---

## 8. 白化后的子空间不变性与旧 W-score 的替代

给定非正交波束矩阵 \(W\)：

\[
U_W
=
W(W^HW)^{\dagger/2}.
\]

在有效秩子空间上：

\[
U_W^HU_W=I.
\]

若

\[
W_2=W_1R
\]

且 \(R\) 可逆，则两者张成同一子空间，白化基只差酉变换：

\[
U_{W_2}=U_{W_1}Q,
\qquad
g_{W_2}=Q^Hg_{W_1}.
\]

因此，精确白化下 DML 投影分数主要由 \(\operatorname{span}(W)\) 决定，而不是该子空间采用的非正交基。

结论：

```text
cond(W^H W)
不再与投影损失、流形相关性线性加权成统计 W-score。
```

它只可作为：

- 浮点/定点数值稳定性约束；
- 白化器量化诊断；
- 白化前硬件误差约束。

---

## 9. 相关规则顺序波束库的系统设计分析

### 9.1 子集观测与重白化

对完整候选波束池 \(W_0\) 和子集选择矩阵 \(S_I\)：

\[
z_I=S_IW_0^Hy,
\]

\[
C_I
=
S_IW_0^HR_nW_0S_I^H,
\]

\[
T_I=C_I^{\dagger/2}.
\]

每个子集必须重建自己的 \(C_I\)、白化器、流形和 FIM。

### 9.2 相对阵元域信息保真

\[
\eta(I)
=
\inf_{\zeta\in\Xi_{\rm id}}
\lambda_{\min}^{+}
\left[
F_{\rm elem}^{\dagger/2}
F_I
F_{\rm elem}^{\dagger/2}
\right].
\]

### 9.3 结构化成本

\[
C_{\rm el}
\propto |I_e|N_\phi N_z,
\]

\[
C_{\rm az}
\propto |I_e||I_a|N_\phi,
\]

\[
C_{\rm out}
\propto |I_e||I_a|.
\]

总成本包括：

\[
C=C_{\rm el}+C_{\rm az}+C_{\rm out}+C_{\rm mem}.
\]

### 9.4 已验证结果与最终定位

Stage7 得到：

```text
RECT_E14_A31 = 3×5
eta design / validation / holdout:
0.812182048 / 0.854926015 / 0.816394840
```

但它与最强固定 `FIXED_RECT_3X5` 是同一物理子集，有限样本指标逐项一致。

因此：

```text
科学评分替换完成
系统配置得到解释
新波束选择算法贡献不成立
```

本部分只保留为系统分析和 measurement freeze 依据。

---

## 10. 局部目标数判定与 unresolved：当前正式 deferred

### 10.1 理论公式仍然正确

对候选 \(K\)：

\[
RSS_K
=
\min_{\Theta_K,S}
\|\widetilde Z-G_K(\Theta_K)S\|_F^2,
\]

\[
\Lambda_{K,K+1}
=
2r_CL
\log\frac{RSS_K}{RSS_{K+1}}.
\]

普通 Wilks 卡方条件不成立，parametric bootstrap 在理论上是合理候选机制。

### 10.2 当前闭环失败原因

当前 300-cell calibration 主要对应 fixed-grid K1 模型，而独立诊断中的 K1 truth 连续 off-grid。固定网格 K2 可用两个相邻原子近似一个 off-grid 单目标，导致 K1 false split：

```text
30/60 = 0.50
```

因此旧 threshold 并未控制当前连续真值分布。

### 10.3 最终工程决定

当前版本明确：

```text
K 由外部给定
不运行 LRT threshold
不输出 K2_RESOLVED / K2_UNRESOLVED
不运行 separation bootstrap
不执行 6000-trial
不执行 Stage8.2
```

unknown-K 可在未来以新的研究问题重新立项，但不得通过继续调旧 q_global、增加规则、扩大 trial 或放宽 solver 合同恢复。

---

## 11. 稳定 DML 数值实现

### 11.1 禁止固定岭投影

不使用

\[
G(G^HG+10^{-10}I)^{-1}G^H
\]

作为主 DML 投影。

### 11.2 相对数值秩

\[
\tau_{\rm rank}
=
\max(B,K)\epsilon_{\rm mach}\sigma_1(G)c_{\rm rank}.
\]

有效秩不足 \(K\) 时返回无效状态，不使用固定 floor 强行继续。

### 11.3 稳定白化

对

\[
C_b=Q\Lambda Q^H
\]

使用相对阈值保留有效特征子空间：

\[
T_b
=
\Lambda_r^{-1/2}Q_r^H
\]

或其等价稳定形式。

### 11.4 Safe Hybrid 的数值合同

B0 fallback 必须：

```text
finite
full rank
valid RSS / variance / log-likelihood
```

continuous candidate 必须：

```text
finite estimate
full rank
monotonicity violations = 0
valid concentrated likelihood
```

safe selection 不使用 truth。

---

## 12. 完整复杂度与计算预算

### 12.1 顺序 DBF 成本

\[
C_{\rm elDBF}
=
O(B_eN_\phi N_z),
\]

\[
C_{\rm azDBF}
=
O(B_eB_aN_\phi).
\]

### 12.2 Core-Lite

K1：

```text
固定网格 B0
+
一个 conventional continuous candidate
+
safe selection
```

K2：

```text
固定网格 B0
```

Core-Lite 不运行：

```text
grouped K2
direct continuous K2
bootstrap
K1/K2 双模型比较
```

### 12.3 Core-Plus

K2 增加：

```text
grouped initialization
+
center-difference continuous candidate
+
safe selection
```

当前 24-trial 成本审计中，B0 与 continuous row 均包含共享 initialization 成本，因此二者相加只是保守上界，不能解释为精确生产成本。

候选均值：

```text
B0:
120.875 score calls
275.125 SVD calls
0.142283 s

H2 continuous candidate:
1142 score calls
2302.833 SVD calls
0.930513 s
```

因此 Core-Plus 是明确的高成本可选模式。

### 12.4 不再计入当前算法的成本

以下不属于当前在线算法：

```text
bootstrap calibration
separation bootstrap
6000-trial validation
Stage8.2
K=3
自适应 W/B
```

---

## 13. 双目标与论文边界

### 13.1 当前论文处理范围

当前算法主实验只处理：

\[
K\in\{1,2\},
\]

且 \(K\) 已知。

### 13.2 双目标的意义

双目标是最小非平凡近邻场景，用于研究：

- 顺序白化流形局部共线；
- 第二奇异值和相关性；
- fixed-grid 与 continuous 估计；
- grouped rescue initialization；
- safe fallback。

### 13.3 不再承诺 K=3

K=3 只保留为 future work，不进入当前代码和论文主张。

---

## 14. 建议的正式贡献表述

### 贡献 1：固定白化顺序流形的近双目标显式局部推论

> 基于经典投影 Fisher 信息和阵列流形局部几何，针对固定、精确白化的实际顺序接收波束二维流形，推导近双目标第二奇异值、归一化流形相关性和列归一化 Gram 条件数关于同一二维分离方向二次型的显式局部渐近关系，并明确其非退化条件、零方向边界和有限样本适用范围。

定位：

```text
核心理论贡献
场景化显式推论
不称新 FIM
```

### 贡献 2：Known-K 顺序波束域安全连续 DML

> 面向常规顺序 DBF 后的局部角单元，在固定 measurement 和精确白化坐标下，以固定网格 concentrated DML 提供粗初始化与可靠保底，并在完整顺序二维流形上进行连续 refinement；连续候选只有在数值有效且集中似然不低于固定网格时才被采用，从而兼顾 off-grid 精度与返回可靠性。

定位：

```text
核心算法贡献
K1 证据最强
K2 使用固定网格安全回退
```

### 可选增强：Grouped K2 rescue initialization

> 利用俯仰 MMV 分组和条件方位 DML 生成 K2 初值，并在中心–分离参数化下执行完整顺序流形连续 refinement；当候选有效且似然更高时作为高精度升级，否则回退固定网格。

定位：

```text
optional engineering enhancement
不作为必需核心创新
```

### 系统结果：相关规则顺序波束的 FIM 保真分析

> 对相关噪声、子集重白化和两级顺序 DBF 结构化成本下的规则波束池，使用相对阵元域有效 FIM 保真进行 exact-subset 系统分析，确定 `RECT_E14_A31` 为可接受 3×5 配置。

定位：

```text
系统设计分析
不称新波束选择算法
```

---

## 15. 必须删除、降级或归档的旧主张

| 旧内容 | 当前定位 |
|---|---|
| 真实圆柱阵流形本身是创新 | 正确建模基础 |
| beamspace DML 本身是创新 | 经典估计准则 |
| 中心–分离坐标自动降维 | 删除；只是重参数化 |
| grouped initialization 是必选核心 | 降级为 K2 optional rescue |
| fixed-grid 是最终连续模型 | 降级为 coarse baseline / fallback |
| `greedy_combined_B7` | 历史经验 baseline |
| `cond(W^HW)` 统计惩罚 | 数值/硬件约束 |
| 自适应 W/B | 已失败，不恢复 |
| fixed topK3 / C05 | 历史搜索启发式 |
| bootstrap K1/K2 自动判定是当前主线 | 长期 deferred |
| `K2_RESOLVED / K2_UNRESOLVED` 是当前输出 | 删除出当前接口 |
| K=3 是必要扩展 | future work |
| 6000-trial 是当前下一步 | 删除；不再执行 |
| Stage8.2 自动授权 | 禁止 |

---

# 16. 公式、代码、证据与相关参考

## 16.1 当前代码和证据映射

| 对象 | 路径/证据 |
|---|---|
| 接收单程、顺序 DBF、稳定 DML | `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_*` |
| 阶段 6 局部理论 | `innovation-mining/15_stage6_tangent_theory_validation_audit.md` |
| 阶段 7 FIM 系统分析 | `innovation-mining/16_stage7_exact_subset_fim_audit.md` |
| unknown-K compact failure | `innovation-mining/23_stage8_compact_algorithm_diagnostic.md` |
| continuous R1 诊断 | `innovation-mining/24_stage8_r1_continuous_refinement_decisive_experiment.md` |
| Core-V2 known-K K2 诊断 | `innovation-mining/26_stage8_core_v2_known_k_pruning_experiment.md` |
| safe hybrid closure | `innovation-mining/27_stage8_core_v2_1_safe_hybrid_closure.md` |
| Core-V2 工具 | `tools/stage8_core_v2_known_k/` |

## 16.2 DML 与多源优化

1. Ziskind, I.; Wax, M. “Maximum likelihood localization of multiple sources by alternating projection.” *IEEE TASSP*, 1988. DOI: `10.1109/29.7543`.
2. Stoica, P.; Sharman, K. C. “Maximum likelihood methods for direction-of-arrival estimation.” *IEEE TASSP*, 1990. DOI: `10.1109/29.57542`.
3. Stoica, P.; Nehorai, A. “MUSIC, maximum likelihood, and Cramer-Rao bound.” *IEEE TASSP*, 1989. DOI: `10.1109/29.17564`.
4. Vincent, F.; Besson, O.; Chaumette, E. “Approximate maximum likelihood estimation of two closely spaced sources.” *Signal Processing*, 2014. DOI: `10.1016/j.sigpro.2013.10.017`.
5. Trinh-Hoang, M.; Viberg, M.; Pesavento, M. “Partial Relaxation Approach: An Eigenvalue-Based DOA Estimator Framework.” arXiv: `1711.01982`.
6. Pote, R.; Rao, B. D. “Maximum Likelihood-Based Gridless DoA Estimation Using Structured Covariance Matrix Recovery and SBL With Grid Refinement.” *IEEE TSP*, 2023. DOI: `10.1109/TSP.2023.3254919`.

## 16.3 Beamspace ML 与近双目标

7. Zoltowski, M. D.; Lee, T.-S. “Maximum likelihood based sensor array signal processing in the beamspace domain for low angle radar tracking.” 1991. DOI: `10.1109/78.80885`.
8. Kim, H.; Yang, J.; Kwak, N. “Low-angle tracking of two objects in a three-dimensional beamspace domain.” 2012. DOI: `10.1049/IET-RSN.2010.0163`.
9. 刘旗等. “低仰角目标高精度波束空间 DOA 估计方法.” 2026. DOI: `10.12000/JR25173`.

## 16.4 FIM、压缩与测量选择

10. Chepuri, S. P.; Leus, G. “Sparsity-Promoting Sensor Selection for Non-linear Measurement Models.” arXiv: `1310.5251`.
11. Pakrooh, P. et al. “Analysis of Fisher Information and the Cramer-Rao Bound for Nonlinear Parameter Estimation after Compressed Sensing.” *IEEE TSP*, 2015. DOI: `10.1109/TSP.2015.2464183`.
12. Pakrooh, P.; Scharf, L. L.; Pezeshki, A. “Threshold Effects in Parameter Estimation from Compressed Data.” *IEEE TSP*, 2016. DOI: `10.1109/TSP.2016.2521617`.

## 16.5 最终开发边界

当前算法开发在以下状态停止：

```text
CORE_LITE:
K1 continuous safe hybrid
K2 fixed-grid known-K

CORE_PLUS:
K2 grouped continuous optional upgrade
fixed-grid fallback

MODEL_ORDER:
DEFERRED

FORMAL 6000-TRIAL:
DEFERRED_NOT_FAILED

STAGE8.2:
NOT_EXECUTED
```

下一项允许的工作仅应是：

```text
把 Core-Lite / Core-Plus 整理为单一生产接口
并用既有 24 trials 做逐行回归
```

不得自动重新启动 unknown-K、bootstrap、第三版 K2 solver、自适应 W/B 或新的大规模验证。
