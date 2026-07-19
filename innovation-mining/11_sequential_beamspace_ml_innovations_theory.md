# 顺序数字波束形成下的局部未分辨目标簇波束域 ML：修订后的创新点、完整公式与理论推导

> 建议保存路径：`innovation-mining/11_sequential_beamspace_ml_innovations_theory.md`  
> 默认仓库：`makabaka165/bs_innovation`  
> 文档日期：2026-07-17  
> 文档状态：阶段 6 已冻结确定性流形证据；阶段 7 已完成 961 子集系统分析，Stage7.1 于 2026-07-19 完成两次独立 closure。Stage7.1 deterministic evidence bundle hash 为 `af40f8a7e8a0edfc7077594ebf08257cd0c7385d10902bc8dd624c83434bc322`。阶段 7 仍为 `PASS_SYSTEM_ANALYSIS_ONLY`，不代表投稿新颖性、未知模型阶数或有限样本分辨闭环已经成立。
> 本文替代旧的“controlled pair2d + greedy_combined_B7 + fixed topK3 + C05”创新组织方式，但不删除旧源码和旧证据。
>
> 必须联合阅读：
>
> - `innovation-mining/06_formula_prior_art.md`
> - `innovation-mining/06_algorithm_prior_art.md`
> - `innovation-mining/06_closest_work_matrix.md`
> - `innovation-mining/10_current_paper_innovation_audit.md`
> - `innovation-mining/12_experiment_system_code_structure_roadmap.md`
> - `innovation-mining/13_next_step_execution_prompts.md`
> - `innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md`
>
> 新颖性声明边界：本文中的 DML、SVD/QR 投影、交替投影/坐标上升、投影 Jacobian Fisher 信息、压缩前后归一化 FIM、FIM 约束最少选择、bootstrap 阶数估计和统计不可分辨概念均有明确 prior art。候选贡献只允许落在**实际顺序接收 DBF 接口上的完整算法组织、顺序白化二维流形的显式近双目标渐近推论，以及相关规则波束库与结构化成本下的系统特化和经独立实验验证的收益**。

---

## 0. 修订后的创新层级与 prior-art 边界

### 0.1 核心创新点 1：实际顺序接收 DBF 接口下的分组条件 DML

面向全息凝视雷达实际“先俯仰维数字波束形成、再方位维数字波束形成”的接收数据接口，构造以下完整处理链：

1. 利用俯仰 DBF 复输出估计**可辨俯仰目标组**，而不是直接假设每个目标都有独立可辨俯仰角；
2. 对每个俯仰组，在已估计俯仰条件下执行方位单目标或有限多目标 DML；
3. 使用固定的完整顺序波束域流形进行局部联合修正，补偿圆柱阵方位项仍依赖俯仰角所造成的分阶段误差；
4. 对同俯仰、多俯仰和两维均近邻目标采用统一的分组表示
   \[
   K=\sum_{q=1}^{Q}K_q.
   \]

**prior-art 边界：** DML、先一维后另一维、条件估计、AP/坐标上升分别已有前例；本轮暂未发现“以可辨俯仰组为中间变量、显式处理组内多方位目标、再用实际完整顺序流形修正”的同一完整组合。该点只有在相同角域和相同计算预算下优于 AP-DML、PR-DML 或直接局部 DML 时，才能从工程组合提升为算法贡献。

### 0.2 核心创新点 2：固定白化顺序二维流形的近双目标统一局部渐近式

在固定物理顺序波束矩阵和固定白化坐标下，针对两个近邻目标推导：

\[
\sigma_2^2(G_2)
=\frac12\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d
+o(\|\mathbf d\|^2),
\]

\[
1-|\rho|^2
=\frac{\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d}
{\|g(\mathbf c)\|_2^2}
+o(\|\mathbf d\|^2),
\]

以及对列归一化双目标流形

\[
\kappa(\bar G_2^H\bar G_2)
\sim
\frac{4\|g(\mathbf c)\|_2^2}
{\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d}.
\]

其中

\[
T_{\rm seq}(\mathbf c)
=\operatorname{Re}\{J_g^H\Pi_g^\perp J_g\}
\]

是经典未知复幅度消元后有效 Fisher 信息的几何部分，而不是一个全新的信息矩阵。候选理论贡献是：**在精确白化的顺序俯仰/方位接收波束二维流形上，把第二奇异值、归一化相关性和 Gram 条件数显式统一到同一二维分离方向二次型，并给出零方向、高阶退化和适用条件。**

### 0.3 算法设计贡献：相关顺序波束输出下的最小规则波束集

在 Pakrooh 等的压缩前后归一化 FIM、Chepuri–Leus 的 FIM 约束最少测量选择以及刘旗等 2026 年 CRB 保真 beamspace ML 工作基础上，针对本项目的实际规则波束库求解：

- 相邻顺序波束输出存在相关噪声；
- 每个候选子集的协方差逆和白化器随子集变化；
- 候选集具有俯仰波束与方位波束的结构化组合；
- 成本同时包含俯仰 DBF、方位 DBF、输出通道、存储和数据搬运；
- 设计场景为局部近双目标、功率失衡和相干压力场景；
- 高 SNR FIM 保真必须通过独立有限样本 threshold-risk holdout 才能被接受。

该部分不声称首次提出归一化 FIM、FIM 保真或最少选择问题；可保留的差异是**相关噪声、实际顺序规则波束、结构化成本和近双目标风险验证的联合特化**。

> **阶段 7 最终证据（2026-07-18）：`PASS_SYSTEM_ANALYSIS_ONLY`。** 冻结的 factor=1、5x5 父池包含 961 个非空矩形子集。完整父池相对阵元域的最坏设计保真上限仅为 `0.823236874`，因此 `eta0=0.90/0.95` 按注册规则不可行。`eta0=0.80` 的 exact 解为 `RECT_E14_A31`，即中心 3 个俯仰波束与全部 5 个方位波束；其 design/validation/FIM-holdout 保真率为 `0.812182048 / 0.854926015 / 0.816394840`。该物理子集与最强固定基线 `FIXED_RECT_3X5` 完全相同，有限样本 Pareto 门为 `0/3`，故本部分已降级为系统设计分析，不再列为核心算法贡献，也不授权进入阶段 8。

> **Stage7.1 closure（2026-07-19）：`PASS_STAGE7_1_CLOSURE_AUDIT`。** 科学和算法核心与历史提交 `85615e0` 一致；唯一历史变化是 legacy `peak_memory_estimate` 随 provenance context schema 增加而变化 69,742 bytes。它不是 FIM、DML、finite-sample 或真实进程峰值变化。独立确定性合同验证 `workspace=34,611,200` bytes、materialized/factorized weights `499,200/17,136` bytes 和 unique/charged score calls `9,152,562/11,734,516`。这里的 3/5 明确表示 **3 个俯仰中间通道，每通道 5 个条件方位输出**；`EXACT_ETA_080` 与 `FIXED_RECT_3X5` 是同一 `RECT_E14_A31` 物理子集。Stage8 未执行，未来若另行授权，只用于完成阶段 5 遗留的 K1/K2 模型阶数与 resolved/unresolved 统计闭环。

### 0.4 统计支撑机制：K1/K2 校准与 `K2_UNRESOLVED`

使用独立 K1 calibration/holdout 标定的 parametric-bootstrap DML 阶数检验控制 false split，并把“存在双目标证据”和“两个角度可可靠分离”分开：

- `K1`；
- `K2_RESOLVED`；
- `K2_UNRESOLVED`；
- `GROUP_UNIDENTIFIABLE`；
- `OUT_OF_LOCAL_CELL`；
- `SEARCH_NOT_CONVERGED`；
- `MODEL_MISMATCH`；
- `NUMERIC_RANK_DEFICIENT`。

bootstrap 和 unresolved 概念本身不是新统计理论；其作用是形成可校准、可拒判、不会在病态样本上强制输出两个高置信角度的工程接口。

### 0.5 原子主张的最终定位

| 原子内容 | 定位 | 论文中允许的表述 |
|---|---|---|
| 接收单程圆柱阵流形、条件 Kronecker 表示 | 已有完全相同数学基础 | 正确建模与顺序 DBF 推导基础 |
| 白化集中 DML、SVD/QR 投影 | 已有完全相同方法 | 稳定实现，不单列创新 |
| 逐目标/逐维坐标最大化及单调性 | 已有完全相同机制 | AP/坐标上升求解器与收敛性质 |
| 可辨俯仰组 → 条件方位 DML → 完整顺序流形修正 | 完整组合暂未发现直接工作 | 候选核心算法贡献，必须公平比较 |
| \(T=\operatorname{Re}\{J^H\Pi^\perp J\}\) | 经典有效 FIM 几何部分 | 用于场景化推导，不称新矩阵 |
| \(\sigma_2\)–相关性–条件数统一渐近式 | 数学形式相似，顺序流形同式暂未发现 | 候选核心理论贡献，定位为场景化显式推论 |
| 归一化 FIM 与最坏特征值 | 已有同形/强相似 | 作为系统设计指标，不称首次提出 |
| 最小 FIM 保真波束集 | 数学骨架已有；阶段 7 未超过最强固定矩形 | 仅保留相关顺序规则波束的系统设计分析 |
| parametric bootstrap、unresolved | 算法机制相似 | 风险控制和工程状态接口 |

### 0.6 明确禁止的创新表述

不得写成：

- 首次提出 beamspace DML；
- 首次提出投影 Jacobian 切向信息矩阵；
- 首次发现白化 beamspace 只依赖波束子空间；
- 首次用 Fisher 信息或 CRB 设计 beamspace；
- 首次提出最少测量数加 FIM 最小特征值约束；
- 首次提出坐标上升、AP、bootstrap 或 unresolved；
- 中心–差分参数化本身降低连续自由度；
- 完整算法组合“未检索到”即可证明非显而易见性或优越性。

## 1. 系统层级与问题定义

### 1.1 不再使用含混的“前端—后端”表述

在本文中统一采用以下系统层级：

| 层级 | 推荐名称 | 内容 |
|---|---|---|
| 1 | 阵元数字接收链路 | 射频接收、下变频、ADC、数字下变频、脉压，输出阵元复数据 |
| 2 | 常规顺序 DBF 与检测处理 | 俯仰 DBF、方位 DBF、MTD、CFAR、常规波束峰值或比幅测角 |
| 3 | 局部未分辨目标簇超分辨测角 | 在同一距离–多普勒单元和局部角分辨单元内，估计目标数及精细二维角度 |
| 4 | 航迹与资源管理 | 数据关联、跟踪、跨 CPI 处理和波束调度 |

本文算法位于第 3 层，推荐名称为：

> **常规顺序 DBF 之后的局部未分辨目标簇波束域超分辨测角模块。**

### 1.2 建议写入论文的问题描述

> 雷达首先沿俯仰维和方位维依次进行数字波束形成，并在距离–多普勒域完成常规检测和角度单元定位。当多个近邻目标落入同一常规角分辨单元，使常规波束峰值、三波束比幅或单目标测角结果表现为合并主峰时，本文利用该角分辨单元及相邻俯仰/方位波束的复数输出，进一步估计局部目标数及各目标的精细方位角和俯仰角。

局部角域不应再描述为“某个前端人工给出的固定 \(\pm1.5^\circ\) 窗口”，而应来自以下两类物理对象之一。

#### 方式 A：常规测角置信域

设常规测角结果为

\[
\widehat{\boldsymbol\xi}_{c}
=
\begin{bmatrix}
\widehat\phi_c\\
\widehat\theta_c
\end{bmatrix},
\]

估计协方差为 \(C_c\)，则定义

\[
\Omega_{\alpha}
=
\left\{
\boldsymbol\xi:
(\boldsymbol\xi-\widehat{\boldsymbol\xi}_{c})^T
C_c^{-1}
(\boldsymbol\xi-\widehat{\boldsymbol\xi}_{c})
\le
\chi^2_{2,1-\alpha}
\right\}.
\]

#### 方式 B：常规波束角分辨单元

设常规 DBF 波束输出为 \(z_{b_e,b_a}\)，定义某检测波束对应的角分辨单元

\[
\Omega_{b_e,b_a}
=
\left\{
(\phi,\theta):
(b_e,b_a)
=
\arg\max_{i,j}
|z_{i,j}(\phi,\theta)|^2
\right\}.
\]

实际实现可用相邻波束交点、3 dB 边界或常规测角误差统计近似该区域。

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

方位角为 \(\phi\)，俯仰角为 \(\theta\)，方向单位矢量定义为

\[
\mathbf u(\phi,\theta)
=
\begin{bmatrix}
\cos\theta\cos\phi\\
\cos\theta\sin\phi\\
\sin\theta
\end{bmatrix}.
\]

令

\[
k_0=\frac{2\pi}{\lambda}.
\]

### 2.2 只考虑接收阵列时的单程空间相位

接收导向项为

\[
\boxed{
a_{m,n}(\phi,\theta)
=
\exp
\left(
j k_0
\mathbf r_{m,n}^T
\mathbf u(\phi,\theta)
\right).
}
\]

即空间相位因子固定为

\[
\boxed{\eta_{\rm phase}=1.}
\]

目标距离对应的单站双程传播相位可写成

\[
\exp\left(-j\frac{4\pi R_k}{\lambda}\right),
\]

但在远场窄带接收阵列模型中，它对所有接收阵元近似为公共相位，可以吸收到目标复包络 \(s_{k,l}\) 中。只要本文不显式研究发射阵列流形，就不应再把双程因子乘入接收空间导向矢量。

### 2.3 阵元域模型

设 \(M=N_\phi N_z\)，第 \(l\) 个观测快拍的向量模型为

\[
\mathbf y_l
=
A(\Theta)\mathbf s_l+\mathbf n_l,
\]

其中

\[
A(\Theta)
=
[
\mathbf a(\phi_1,\theta_1),
\ldots,
\mathbf a(\phi_K,\theta_K)
].
\]

堆叠 \(L\) 个观测：

\[
Y=A(\Theta)S+N.
\]

阵元白噪声基线为

\[
\mathbf n_l\sim\mathcal{CN}(\mathbf 0,\sigma^2I_M).
\]

一般噪声扩展为

\[
\mathbf n_l\sim\mathcal{CN}(\mathbf 0,R_n).
\]

### 2.4 从双程因子 2 改为 1 对信息量的影响

若原导向矢量写为

\[
a(\xi;\eta)
=
\exp(j\eta k_0\mathbf r^T\mathbf u(\xi)),
\]

则

\[
\frac{\partial a}{\partial\xi}
\propto\eta.
\]

局部 Fisher 信息近似满足

\[
F(\eta)\propto\eta^2.
\]

因此，在其余条件不变时，

\[
F(1)\approx\frac14F(2),
\]

\[
\operatorname{CRB}(1)\approx4\operatorname{CRB}(2),
\]

角度标准差约增大 2 倍。实际数值受波束形成、加窗、噪声和 nuisance 参数影响，但旧的双程模型会系统性夸大接收角度信息。因此旧相位模型下的波束宽度、W/B 选择、搜索网格和全部结果均需重算。

---

## 3. 圆柱阵的条件可分解结构

展开阵元内积：

\[
\mathbf r_{m,n}^T\mathbf u(\phi,\theta)
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

其中

\[
a_{\phi,m}(\phi,\theta)
=
\exp
\left(
jk_0R\cos\theta\cos(\phi-\psi_m)
\right),
\]

\[
a_{z,n}(\theta)
=
\exp
\left(
jk_0z_n\sin\theta
\right).
\]

将阵元顺序按“垂直维在内、环向维在外”统一后，

\[
\boxed{
\mathbf a(\phi,\theta)
=
\mathbf a_{\phi}(\phi,\theta)
\otimes
\mathbf a_z(\theta).
}
\]

需要强调：

\[
\mathbf a_{\phi}=\mathbf a_{\phi}(\phi,\theta),
\]

所以圆柱阵不是严格的

\[
a_\phi(\phi)\otimes a_z(\theta)
\]

完全解耦形式。正确的算法结构是：

\[
\boxed{
\text{先估计俯仰组}
\rightarrow
\text{在俯仰条件下估计方位}
\rightarrow
\text{用完整流形联合修正}.
}
\]

---

## 4. 顺序 DBF 的矩阵信号模型

### 4.1 阵元数据矩阵

将第 \(l\) 个快拍重排为

\[
Y_l\in\mathbb C^{N_z\times N_\phi}.
\]

则

\[
\boxed{
Y_l
=
\sum_{k=1}^{K}
s_{k,l}
\mathbf a_z(\theta_k)
\mathbf a_\phi^T(\phi_k,\theta_k)
+
N_l.
}
\]

等价地，

\[
Y_l
=
A_z(\boldsymbol\theta)
\operatorname{diag}(\mathbf s_l)
A_\phi^T(\boldsymbol\phi,\boldsymbol\theta)
+
N_l.
\]

其中

\[
A_z(\boldsymbol\theta)
=
[
a_z(\theta_1),\ldots,a_z(\theta_K)
].
\]

### 4.2 先俯仰 DBF

令俯仰波束矩阵

\[
V=
[
v_1,\ldots,v_{B_e}
]
\in\mathbb C^{N_z\times B_e}.
\]

每个环向列独立执行相同的俯仰 DBF：

\[
Z_{e,l}=V^HY_l
\in\mathbb C^{B_e\times N_\phi}.
\]

阵元白噪声下，俯仰波束噪声协方差为

\[
C_e=V^HV.
\]

定义尺度相关的稳定白化矩阵

\[
T_e=C_e^{\dagger/2},
\]

实际计算应通过特征分解或 SVD，并使用相对秩阈值，而不是固定绝对 `1e-10`。

白化输出为

\[
\widetilde Z_{e,l}=T_eV^HY_l.
\]

### 4.3 俯仰阶段的多测量向量模型

把所有环向列和快拍拼接：

\[
\widetilde Z_e
=
[
\widetilde Z_{e,1},
\ldots,
\widetilde Z_{e,L}
]
\in
\mathbb C^{B_e\times N_\phi L}.
\]

定义白化俯仰流形

\[
g_e(\theta)=T_eV^Ha_z(\theta).
\]

如果存在 \(Q\) 个可由俯仰维区分的目标组，组中心为

\[
\boldsymbol\eta
=
[\eta_1,\ldots,\eta_Q]^T,
\]

则

\[
\boxed{
\widetilde Z_e
=
G_e(\boldsymbol\eta)C_e^{(s)}
+
\widetilde N_e,
}
\]

其中

\[
G_e(\boldsymbol\eta)
=
[
g_e(\eta_1),\ldots,g_e(\eta_Q)
].
\]

系数矩阵 \(C_e^{(s)}\) 吸收：

- 每个目标的复幅度；
- 方位阵列相位；
- 同一俯仰组内多个方位目标的叠加。

因此，即使时间快拍 \(L=1\)，环向列仍提供 \(N_\phi\) 个共享俯仰流形的观测通道。

---

## 5. 核心创新点 1：分组条件顺序波束域 DML

本节的候选新意是**实际顺序 DBF 接口上的算法组织**，不是重新发明 DML、AP 或二维 DOA。算法必须先证明分组模型在当前数据结构下可辨识，再讨论估计与联合修正。

### 5.1 俯仰 MMV 模型与集中 DML

经过俯仰 DBF 和相应噪声白化后，将环向列与时间快拍拼接：

\[
\widetilde Z_e
\in\mathbb C^{B_e\times N_\phi L},
\]

建立

\[
\boxed{
\widetilde Z_e
=G_e(\boldsymbol\eta)C_e+\widetilde N_e,
}
\]

其中

\[
G_e(\boldsymbol\eta)
=
[\,g_e(\eta_1),\ldots,g_e(\eta_Q)\,]
\in\mathbb C^{B_e\times Q}
\]

表示不同可辨俯仰组的白化俯仰波束域流形，系数矩阵

\[
C_e\in\mathbb C^{Q\times N_\phi L}
\]

吸收每组的方位响应、目标复幅度以及快拍变化。

给定组数 \(Q\) 时，确定性集中 DML 为

\[
\widehat{\boldsymbol\eta}
=
\arg\max_{\boldsymbol\eta\in\Omega_e^Q}
J_e(\boldsymbol\eta),
\]

\[
J_e(\boldsymbol\eta)
=
\|U_{e,r}^H(\boldsymbol\eta)\widetilde Z_e\|_F^2,
\]

其中 \(U_{e,r}\) 是 \(G_e\) 的有效左奇异子空间。残差为

\[
RSS_e(\boldsymbol\eta)
=
\|\widetilde Z_e\|_F^2-J_e(\boldsymbol\eta).
\]

实现中必须使用 SVD/QR 正交投影，不构造固定岭形式的

\[
G(G^HG+10^{-10}I)^{-1}G^H.
\]

### 5.2 “俯仰组”而不是“每个目标的俯仰角”

定义第 \(q\) 个俯仰组

\[
\mathcal G_q
=
\{k:\theta_k\text{ 在当前俯仰 DBF 数据中不可与 }\eta_q\text{ 区分}\},
\]

总目标数满足

\[
K=\sum_{q=1}^{Q}K_q.
\]

双目标的主要结构为：

| 场景 | 俯仰阶段 | 条件方位阶段 |
|---|---|---|
| 两目标俯仰可分 | \(Q=2, K_1=K_2=1\) | 两个条件单目标方位估计 |
| 两目标同俯仰或俯仰不可分 | \(Q=1, K_1=2\) | 同一俯仰组内双目标方位 DML |
| 两维均很近 | 初始可能为 \(Q=1,K_1=2\) | 条件方位初值后由完整顺序流形联合修正；必要时输出 unresolved |

这一定义替代固定离散 `el_sep` 列表，但不能用新的人工间隔阈值重新制造规则分支。组数和组内目标数必须由可校准的模型比较或已知 K oracle 实验确定。

### 5.3 俯仰分组的可辨识条件

无噪声时

\[
\widetilde Z_e=G_eC_e.
\]

若

\[
\operatorname{rank}(G_e)=Q,
\qquad
\operatorname{rank}(C_e)=Q,
\]

则

\[
\operatorname{col}(\widetilde Z_e)=\operatorname{col}(G_e).
\]

因此，以下条件是俯仰组恢复至少必须检查的条件：

1. **波束域维数条件**
   \[
   B_e\ge Q.
   \]
   为保留残差空间和数值稳定性，工程上通常需要 \(B_e>Q\)。
2. **流形列满秩**
   \[
   \operatorname{rank}G_e(\boldsymbol\eta)=Q.
   \]
   极近俯仰组可能使其第二奇异值趋于零。
3. **系数矩阵行满秩**
   \[
   \operatorname{rank}C_e=Q.
   \]
   若不同组的环向响应和快拍系数线性相关，俯仰阶段看不到 Q 维信号子空间。
4. **局部参数映射唯一性**：在当前物理角单元内，不应存在另一组 \(\boldsymbol\eta'\neq\boldsymbol\eta\) 使
   \[
   \operatorname{span}G_e(\boldsymbol\eta')
   =
   \operatorname{span}G_e(\boldsymbol\eta).
   \]
5. **固定白化有效秩**：候选搜索期间俯仰波束矩阵、噪声协方差和保留的白化子空间固定，不能因候选角度变化而改变测量坐标。
6. **局部有效 FIM 非奇异**：消去系数矩阵后，关于 \(\boldsymbol\eta\) 的有效 Fisher 信息在目标方向上应为正。

若 \(\operatorname{rank}C_e<Q\)，则即使 \(G_e\) 满秩，也无法只靠俯仰阶段辨识 Q 个组。这是结构性不可辨识，不应通过增大 topK、缩放窗口或添加阈值解决。

#### 关于 \(L=1\) 的严格说明

当 \(L=1\) 时，\(N_\phi\) 个环向列可以形成 \(N_\phi\) 个 MMV 系数列，但它们不是 \(N_\phi\) 个独立时间快拍。它们能否提供 \(\operatorname{rank}C_e=Q\) 取决于：

- 不同俯仰组的条件方位响应是否线性独立；
- 有效环向孔径和工作子阵是否足够；
- 目标复幅度、相对相位和相干关系是否造成抵消；
- 噪声在不同环向列之间是否相关；
- 是否存在弱目标或通道失效。

因此只能写“环向列为俯仰 DML 提供额外 MMV 系数观测”，不能写“单快拍自动等价于 \(N_\phi\) 个独立快拍”。

#### 分组阶段允许的状态

- `GROUP_IDENTIFIABLE`：秩条件和局部唯一性通过；
- `GROUP_MERGED`：数据只支持更少的可辨俯仰组，后续在组内处理多方位目标；
- `GROUP_UNIDENTIFIABLE`：\(G_e\) 或 \(C_e\) 秩不足，不能可靠确定组结构；
- `NUMERIC_RANK_DEFICIENT`：数值秩不稳定；
- `MODEL_MISMATCH`：残差、白化或 holdout 诊断表明模型不匹配。

### 5.4 俯仰组估计与秩诊断

对每个候选 \(\boldsymbol\eta\)，必须同时输出：

\[
\sigma(G_e),
\quad
\operatorname{rank}_{\rm num}(G_e),
\quad
RSS_e,
\quad
J_e,
\]

并对估计后的系数矩阵输出

\[
\sigma(\widehat C_e),
\quad
\operatorname{rank}_{\rm num}(\widehat C_e).
\]

数值秩阈值使用相对尺度，例如

\[
\tau_{\rm rank}
=
\max(m,n)\epsilon_{\rm mach}\sigma_1,
\]

而不是固定绝对常数。

### 5.5 恢复各俯仰组的环向数据

给定

\[
\widehat G_e=G_e(\widehat{\boldsymbol\eta}),
\]

使用 SVD 伪逆求

\[
\widehat C_e=\widehat G_e^\dagger\widetilde Z_e.
\]

第 \(q\) 行按环向列和时间快拍重排为

\[
X_{\phi,q}\in\mathbb C^{N_\phi\times L}.
\]

理想条件下

\[
\boxed{
X_{\phi,q}
=
A_{\phi,q}(\boldsymbol\phi_q\mid\widehat\eta_q)S_q+E_q,
}
\]

其中

\[
A_{\phi,q}
=
[\,a_\phi(\phi_{q,1},\widehat\eta_q),\ldots,
   a_\phi(\phi_{q,K_q},\widehat\eta_q)\,].
\]

恢复误差必须通过子空间距离、相对 Frobenius 误差和组间串扰同时评价。只报告角度 RMSE 不足以验证该中间变量是否正确。

### 5.6 条件方位 DML

对第 \(q\) 个俯仰组，选择固定方位局部波束矩阵 \(U_q\)，并使用其对应噪声协方差

\[
C_{\phi,q}=U_q^HR_{\phi,q}U_q.
\]

白化后

\[
\widetilde Z_{\phi,q}
=C_{\phi,q}^{\dagger/2}U_q^HX_{\phi,q},
\]

\[
g_{\phi,q}(\phi\mid\eta_q)
=C_{\phi,q}^{\dagger/2}U_q^Ha_\phi(\phi,\eta_q).
\]

注意 \(a_\phi\) 仍依赖 \(\eta_q\) 中的 \(\cos\eta_q\)，不能使用与俯仰无关的方位流形。

对 \(K_q\) 个方位目标

\[
G_{\phi,q}
=[\,g_{\phi,q}(\phi_{q,1}\mid\eta_q),\ldots,
   g_{\phi,q}(\phi_{q,K_q}\mid\eta_q)\,],
\]

条件方位 DML 为

\[
\boxed{
\widehat{\boldsymbol\phi}_q
=
\arg\max_{\boldsymbol\phi_q}
\|U_{\phi,q,r}^H\widetilde Z_{\phi,q}\|_F^2.
}
\]

对于 \(K_q>1\)，可使用小局部参考搜索、AP-DML 或 PR-DML。AP/PR-DML 是已有求解机制，必须作为 baseline 或求解器引用，不能改名为新优化器。

### 5.7 核心创新点 1 的可验证主张

只有在完成以下比较后，才能声称该组合具有算法价值：

- 相同物理角域；
- 相同真值信息可见性；
- 相同 DML 评分和噪声模型；
- 相同 score-call、SVD 次数或 wall-time 预算；
- 对比 local full DML、AP-DML、PR-DML、无分组二维坐标上升和旧 controlled pair2d；
- 报告错误局部峰率、多初值成本、最终 score/RSS gap、无条件失败率。

如果收益完全来自更窄且含真值泄漏的候选域，或必须使用大量多初值才能接近 local full DML，则该点应降级为工程初始化策略。

## 6. 完整顺序波束域流形与局部联合修正

> **prior-art 定位：** 本节的逐目标/逐维最大化属于 Ziskind–Wax alternating projection 和一般 block coordinate ascent 的已有机制。“每次精确更新使 DML 分数不下降”是标准性质，不是新收敛理论。候选差异只允许放在分组条件初始化、实际顺序流形接口以及由此产生的有限样本性能/复杂度。目标函数单调不代表角度正确，也不保证全局最优。

### 6.1 单个顺序波束响应

对俯仰波束 \(v_b\) 和在该俯仰通道上使用的方位波束 \(u_{c|b}\)，令

\[
w_{b,c}
=
u_{c|b}\otimes v_b.
\]

向量化阵元数据：

\[
\operatorname{vec}(Y_l)
=
\sum_{k=1}^{K}
s_{k,l}
\left[
a_\phi(\phi_k,\theta_k)
\otimes
a_z(\theta_k)
\right]
+
n_l.
\]

顺序波束输出为

\[
z_{b,c,l}
=
w_{b,c}^H\operatorname{vec}(Y_l).
\]

单目标顺序流形分量为

\[
\boxed{
g_{b,c}(\phi,\theta)
=
\left[
u_{c|b}^Ha_\phi(\phi,\theta)
\right]
\left[
v_b^Ha_z(\theta)
\right].
}
\]

把局部所有 \((b,c)\) 输出堆叠，得到

\[
g_{\rm seq}(\phi,\theta).
\]

若顺序波束矩阵为

\[
W_{\rm seq}
=
[
w_{1,1},\ldots,w_{B_e,B_a}
],
\]

一般噪声协方差下的白化流形为

\[
\widetilde g_{\rm seq}(\phi,\theta)
=
C_b^{\dagger/2}
W_{\rm seq}^H
a(\phi,\theta),
\]

\[
C_b=W_{\rm seq}^HR_nW_{\rm seq}.
\]

### 6.2 多目标联合 DML

\[
G_{\rm seq}(\Theta)
=
[
\widetilde g_{\rm seq}(\phi_1,\theta_1),
\ldots,
\widetilde g_{\rm seq}(\phi_K,\theta_K)
].
\]

联合评分：

\[
\boxed{
J_{\rm seq}(\Theta)
=
\left\|
U_{{\rm seq},r}^H(\Theta)
\widetilde Z_{\rm seq}
\right\|_F^2.
}
\]

联合残差：

\[
RSS_{\rm seq}(\Theta)
=
\|\widetilde Z_{\rm seq}\|_F^2
-
J_{\rm seq}(\Theta).
\]

### 6.3 逐目标局部坐标最大化

以俯仰组和条件方位估计为初始化 \(\Theta^{(0)}\)，对每个目标依次更新：

\[
\phi_k^{(t+1)}
=
\arg\max_{\phi_k\in\Omega_{\phi,k}}
J_{\rm seq}
(
\phi_1^{(t+1)},\ldots,\phi_k,\ldots,\phi_K^{(t)};
\boldsymbol\theta^{(t)}
),
\]

\[
\theta_k^{(t+1)}
=
\arg\max_{\theta_k\in\Omega_{\theta,k}}
J_{\rm seq}
(
\boldsymbol\phi^{(t+1)};
\theta_1^{(t+1)},\ldots,\theta_k,\ldots,\theta_K^{(t)}
).
\]

每个一维子问题可用：

- 自适应一维网格；
- Brent/golden-section（仅当局部单峰可验证）；
- 多起点局部搜索；
- 一维 branch-and-bound；
- 细网格作为可审计基线。

### 6.4 单调性

如果每次坐标更新不降低当前目标函数，则

\[
J_{\rm seq}(\Theta^{(t+1)})
\ge
J_{\rm seq}(\Theta^{(t)}).
\]

又因为

\[
0
\le
J_{\rm seq}(\Theta)
\le
\|\widetilde Z_{\rm seq}\|_F^2,
\]

所以

\[
\{J_{\rm seq}(\Theta^{(t)})\}
\]

单调有界并收敛。

注意：这只能证明目标函数值收敛，不能自动证明收敛到全局最优或唯一参数点。论文必须保留该边界。

### 6.5 停止条件

不使用 C05 的 score gap 和多分支规则。建议采用统一停止条件：

\[
\frac{
J^{(t+1)}-J^{(t)}
}{
\max(|J^{(t)}|,\epsilon)
}
\le
\varepsilon_J,
\]

并同时满足

\[
\max_k
\left\|
\widehat{\boldsymbol\xi}_k^{(t+1)}
-
\widehat{\boldsymbol\xi}_k^{(t)}
\right\|_2
\le
\varepsilon_\xi.
\]

\(\varepsilon_J\) 是允许的相对似然改进，\(\varepsilon_\xi\) 是系统角度精度要求，不再为不同场景设置 EASY/NORMAL/AMBIGUOUS 分支。

---

## 7. 核心创新点 2：固定白化顺序流形的近双目标统一渐近式

### 7.1 prior-art 定位

中心–差分参数化、对称 Taylor 展开、和差酉变换、投影 Jacobian 度量、近源 CRB 和两列 Gram 谱均已有明确数学基础。因此本节不能声称创造了新的变换或新的 Fisher 信息矩阵。

允许保留的候选理论贡献是：

> 对固定、精确白化的实际顺序俯仰/方位接收波束二维流形，给出第二奇异值、归一化流形相关性和列归一化 Gram 条件数关于同一二维分离方向二次型的显式渐近式，并明确零方向、高阶退化、列范数不等和有限样本适用边界。

### 7.2 参数化和正式假设

令

\[
\boldsymbol\xi=
\begin{bmatrix}\phi\\\theta\end{bmatrix},
\qquad
\boldsymbol\xi_{1,2}
=
\mathbf c\mp\frac{\mathbf d}{2}.
\]

该表示是精确重参数化，不降低连续自由度。目标标签可通过字典序规范化。

定义固定白化顺序流形

\[
\boxed{
g(\boldsymbol\xi)=T_0W_{\rm seq,0}^Ha(\boldsymbol\xi),
}
\]

其中 \(W_{\rm seq,0}\) 和 \(T_0\) 在所分析局部邻域内固定。正式假设为：

1. \(W_{\rm seq,0}\) 是固定的物理测量矩阵；
2. 噪声协方差和白化有效秩固定，\(T_0\) 不随候选角度改变；
3. \(g\) 在 \(\mathbf c\) 邻域至少三次连续可微；
4. \(g(\mathbf c)\neq0\)；
5. 所考察方向 \(\mathbf d\) 为实二维参数增量；
6. 在主定理的非退化版本中
   \[
   q(\mathbf c,\mathbf d)
   :=\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d>0.
   \]

若物理波束、选择索引、白化器或有效秩随候选角度变化，则必须重新推导包含这些变化的导数，不能直接使用本节公式。

### 7.3 Jacobian 与经典投影 FIM 几何量

定义

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
=I-\frac{gg^H}{g^Hg},
\]

以及

\[
\boxed{
T_{\rm seq}(\mathbf c)
=
\operatorname{Re}\{J_g^H\Pi_g^\perp J_g\}.
}
\]

对单目标白化模型 \(z=g(\xi)s+n\)，消去未知复幅度后

\[
F_\xi
=
\frac{2|s|^2}{\sigma^2}T_{\rm seq},
\]

所以 \(T_{\rm seq}\) 是经典有效 FIM 的几何部分。

### 7.4 圆柱阵单程流形导数

以弧度为求导单位：

\[
a_{z,n}(\theta)=\exp(jk_0z_n\sin\theta),
\]

\[
\frac{\partial a_{z,n}}{\partial\theta}
=jk_0z_n\cos\theta\,a_{z,n}.
\]

\[
a_{\phi,m}(\phi,\theta)
=
\exp\{jk_0R\cos\theta\cos(\phi-\psi_m)\},
\]

\[
\frac{\partial a_{\phi,m}}{\partial\phi}
=-jk_0R\cos\theta\sin(\phi-\psi_m)a_{\phi,m},
\]

\[
\frac{\partial a_{\phi,m}}{\partial\theta}
=-jk_0R\sin\theta\cos(\phi-\psi_m)a_{\phi,m}.
\]

若

\[
a=a_\phi\otimes a_z,
\]

则

\[
\frac{\partial a}{\partial\phi}
=
\frac{\partial a_\phi}{\partial\phi}\otimes a_z,
\]

\[
\frac{\partial a}{\partial\theta}
=
\frac{\partial a_\phi}{\partial\theta}\otimes a_z
+a_\phi\otimes\frac{\partial a_z}{\partial\theta}.
\]

固定白化顺序流形导数为

\[
\frac{\partial g}{\partial\xi}
=T_0W_{\rm seq,0}^H\frac{\partial a}{\partial\xi}.
\]

### 7.5 第二奇异值定理

定义

\[
G_2(\mathbf c,\mathbf d)
=
[\,g(\mathbf c-\mathbf d/2),
   g(\mathbf c+\mathbf d/2)\,].
\]

对两列右乘和差酉矩阵，不改变奇异值。Taylor 展开给出

\[
h_1
=
\frac{g_-+g_+}{\sqrt2}
=
\sqrt2g(\mathbf c)+O(\|\mathbf d\|^2),
\]

\[
h_2
=
\frac{g_+-g_-}{\sqrt2}
=
\frac1{\sqrt2}J_g(\mathbf c)\mathbf d
+O(\|\mathbf d\|^3).
\]

将 \(h_2\) 对 \(h_1\) 正交化，其主导能量为

\[
\frac12
\|\Pi_{g(\mathbf c)}^\perp J_g(\mathbf c)\mathbf d\|_2^2.
\]

对实分离向量

\[
\|\Pi_g^\perp J_g\mathbf d\|_2^2
=
\mathbf d^TT_{\rm seq}\mathbf d.
\]

因此，在 \(q(\mathbf c,\mathbf d)>0\) 时

\[
\boxed{
\sigma_2^2(G_2)
=
\frac12\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d
+o(\|\mathbf d\|^2).
}
\]

### 7.6 与归一化相关性的关系

定义

\[
\rho
=
\frac{g_-^Hg_+}{\|g_-\|_2\|g_+\|_2}.
\]

对光滑、非零流形，有

\[
\boxed{
1-|\rho|^2
=
\frac{\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d}
{\|g(\mathbf c)\|_2^2}
+o(\|\mathbf d\|^2).
}
\]

该式使用归一化列，因此自动排除纯幅度缩放对角度几何的影响。

### 7.7 与列归一化 Gram 条件数的关系

令

\[
\bar g_\pm=\frac{g_\pm}{\|g_\pm\|_2},
\qquad
\bar G_2=[\bar g_-,\bar g_+].
\]

则精确有

\[
\kappa(\bar G_2^H\bar G_2)
=
\frac{1+|\rho|}{1-|\rho|}.
\]

当 \(|\rho|\to1\) 且 \(q>0\) 时

\[
\boxed{
\kappa(\bar G_2^H\bar G_2)
\sim
\frac{4\|g(\mathbf c)\|_2^2}
{\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d}.
}
\]

对未归一化 \(G_2\)，列范数比会额外影响条件数。若 \(\|g_-\|/\|g_+\|\to1\)，其主导发散阶与上式相同；否则必须单独报告列范数不对称，不能直接套用等范数公式。

### 7.8 零方向与高阶退化

若

\[
q(\mathbf c,\mathbf d)=0,
\]

则一阶正交切向信息在该方向消失，以上二次主导项不能用于分辨预测。定义沿单位方向的方向导数 $g_0,g_1,g_2,g_3$，并令

\[
\alpha=\frac{g_0^Hg_1}{g_0^Hg_0},
\qquad
v_{3,\rm eff}=\Pi_g^\perp\left(\frac{g_3}{24}-\frac{\alpha g_2}{8}\right).
\]

对称 Taylor 展开和和差酉变换给出一个待验证的高阶候选：若
$\Pi_g^\perp g_1=0$ 且 $v_{3,\rm eff}\neq0$，则

\[
\boxed{
\sigma_2^2(G_2)
\sim
\frac12\|\mathbf d\|^6\|v_{3,\rm eff}\|_2^2.
}
\]

阶段 6 使用解析流形 $g(x,y)=[1,x,y^3]^T$ 沿 $y$ 方向验证该常数：精确
$\sigma_2^2=r^6/32$，拟合阶数为 6，六阶 ratio 最大误差为
$2.220\times10^{-16}$。四个预注册完整顺序物理配置的 $T_{\rm seq}$ 均未
出现 exact tangent null，因此该六阶式目前只获得 synthetic analytic fixture
支持，不能写成已在物理圆柱阵流形上验证的普遍定理。单通道配置只属于
`EXACT_MEASUREMENT_COLLAPSE`。

在任何零方向分析中：

- 不得把分母设 floor 后继续报告同一渐近比；
- 必须显式检查 $\mathbf d$ 是否落在 $T_{\rm seq}$ 的零空间或近零特征方向；
- 领先阶由三阶有效向量或更高阶流形导数决定；
- 若 $v_{3,\rm eff}$ 也为机器零，则只能报告 `HIGHER_THAN_SIXTH_ORDER_OR_EXACT_COLLAPSE`；
- 若零方向对应物理对称性或波束选择造成的信息丢失，应输出不可辨识，而不是增加搜索预算。

若 $T_{\rm seq}\succ0$，则所有非零二维分离方向都具有一阶局部几何信息；若其半正定且有零特征值，则至少存在一个一阶不可观方向。

> **阶段 6 验证状态（2026-07-17）：** 4 个主测量配置、9 个中心、4 个固定方向和 9 级分离尺度形成 1296 个 secant case；144 个注册非退化尾区全部通过。$\sigma_2^2$、coherence deficit 和 normalized-Gram condition 的最大 tail ratio 误差分别为 $4.010\times10^{-6}$、$1.042\times10^{-5}$ 和 $6.118\times10^{-6}$。状态为 `THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY`；没有发现物理 exact tangent null。

### 7.9 几何定理与有限样本性能必须分开

上述关系只描述固定测量流形矩阵 \(G_2\) 的局部几何。目标幅度、功率比、源相干性、快拍数和噪声会通过 \(S\)、有效 FIM 和似然地形改变有限样本性能。

因此：

- 强相干不改变给定角度下的 \(G_2\) 几何公式，但可能使有效 FIM 或样本信息退化；
- 弱次目标可能让几何上可分的两列在有限样本中不可检出；
- 相同局部 FIM 的波束集可能具有不同旁瓣、错误局部峰和 threshold SNR；
- 不能用该定理替代 K1/K2 检验、错误峰概率和低 SNR holdout。

## 8. 白化后的子空间不变性与 W-score 的替代

> **prior-art 定位：** 精确白化后的可逆换基不变性是标准线性代数事实，不作为创新点。它在本文中的作用是证明旧 `cond(W^HW)` 不应与统计信息指标线性相加，并帮助定义后续波束集的正确设计对象。

### 8.1 阵元白噪声下

给定非正交波束矩阵 \(W\)，定义

\[
U_W
=
W(W^HW)^{\dagger/2}.
\]

则在有效秩子空间上

\[
U_W^HU_W=I.
\]

白化流形为

\[
g_W(\theta)
=
(W^HW)^{\dagger/2}W^Ha(\theta)
=
U_W^Ha(\theta).
\]

如果

\[
W_2=W_1R
\]

且 \(R\) 可逆，则 \(W_1\) 和 \(W_2\) 张成同一子空间。其正交化基只相差一个酉变换：

\[
U_{W_2}=U_{W_1}Q.
\]

因此

\[
g_{W_2}=Q^Hg_{W_1},
\]

DML 投影分数不变。

### 8.2 结论

\[
\boxed{
\text{在精确白化和无限数值精度下，统计信息主要由 }
\operatorname{span}(W)
\text{ 决定，而不是该子空间采用哪组非正交基。}
}
\]

所以

\[
\kappa(W^HW)
\]

不应再与投影损失、流形相关性并列为统计优化目标。它可以作为：

- 浮点/定点实现稳定性约束；
- 白化器位宽和量化误差诊断；
- 模拟波束形成或白化前量化的工程约束。

若量化发生在白化之前，则必须把量化噪声加入 \(R_n\) 或等效似然模型，而不是继续增加经验条件数权重。

---

## 9. 算法设计贡献：相关顺序波束输出下的最小规则波束集

### 9.1 prior-art 边界

以下数学骨架已有直接前例：

- 压缩前后归一化 FIM；
- 按允许 CRB 损失选择压缩维数；
- 最少选择项并对整个参数域施加 FIM 最小特征值约束；
- CRB/FIM 保真 beamspace 设计；
- 贪心、稀疏松弛和局部交换求解。

因此本节不把“FIM 保真”或“最小测量选择”称为首次提出。候选贡献只在于：**对实际先俯仰后方位的规则顺序波束库，在相邻波束噪声相关、子集白化器随选择变化、成本具有顺序 DBF 结构的条件下，构造相对阵元域最坏信息约束，并用独立有限样本风险验证筛选结果。**

### 9.2 完整候选波束池与子集观测

设完整候选顺序波束矩阵为

\[
W_0\in\mathbb C^{M\times B_0},
\qquad
z_0=W_0^Hy.
\]

阵元噪声协方差为 \(R_n\)，则完整候选输出噪声协方差

\[
C_0=W_0^HR_nW_0.
\]

对候选索引集合 \(I\)，令选择矩阵

\[
S_I\in\{0,1\}^{B_I\times B_0},
\]

则

\[
z_I=S_Iz_0,
\]

\[
G_I(\Theta)=S_IW_0^HA(\Theta),
\]

\[
\boxed{
C_I=S_IC_0S_I^H.
}
\]

每个子集必须使用自己的白化器

\[
T_I=C_I^{\dagger/2},
\]

\[
\widetilde Z_I=T_IZ_I,
\qquad
\widetilde G_I=T_IG_I.
\]

对白化有效秩发生变化的子集，必须记录秩变化和信息损失，不能通过固定 floor 假装所有子集具有相同维数。

### 9.3 为什么当前 FIM 不能按逐束固定贡献相加

在独立候选观测模型中，FIM 常可写成

\[
F_I=\sum_{m\in I}F_m.
\]

但相邻 DBF 波束通常相关。当前 FIM 含有

\[
D_I^HC_I^{-1}D_I,
\]

而

\[
C_I^{-1}
=(S_IC_0S_I^H)^{-1}
\]

随子集 \(I\) 改变。因此不能预先定义一个与其他波束无关的固定 \(F_m\)，也不能未经证明直接套用依赖 FIM 可加性的 LMI/SDP 结果。

两条可能路线必须明确区分：

1. **物理输出子集选择：** 对每个 \(I\) 重新构造 \(C_I\)、白化器、流形和 FIM；这是本文主路线。
2. **先对白化完整候选池再选坐标：** 选中的坐标通常是原物理波束的线性混合，未必对应实际输出通道成本；只有证明硬件/软件接口允许该变换时才能采用。

Chepuri–Leus 型松弛可作为独立观测参考，但在未证明等价前不能作为本问题的严格下界、可行解或最优性证书。

### 9.4 有效 deterministic FIM

白化多目标模型为

\[
\widetilde Z_I
=
\widetilde G_I(\Theta)S+\widetilde N_I,
\qquad
\widetilde N_I\sim\mathcal{CN}(0,\sigma^2I).
\]

令实角度参数

\[
\boldsymbol\vartheta
=[\phi_1,\theta_1,\ldots,\phi_K,\theta_K]^T.
\]

定义

\[
G_{I,i}=\frac{\partial\widetilde G_I}{\partial\vartheta_i},
\qquad
d_{I,i}=\operatorname{vec}(G_{I,i}S),
\]

\[
D_I=[d_{I,1},\ldots,d_{I,2K}].
\]

消去未知确定性复包络后

\[
\boxed{
F_{{\rm eff},I}
=
\frac{2}{\sigma^2}
\operatorname{Re}
\left\{
D_I^H(I_L\otimes\Pi_{\widetilde G_I}^\perp)D_I
\right\}.
}
\]

同样计算阵元域 \(F_{\rm elem}(\zeta)\) 和子集顺序波束域 \(F_I(\zeta)\)。场景变量 \(\zeta\) 至少包含：

- 局部中心；
- 方位/俯仰分离及方向；
- SNR 和快拍数；
- 功率比和相对相位；
- 源相关性或确定性 \(S\)；
- 常规角单元内位置；
- 噪声协方差；
- 必要的幅相、位置和通道失配。

### 9.5 相对阵元域信息保真率

在阵元域可辨识子空间上定义

\[
\boxed{
\eta(I)
=
\inf_{\zeta\in\Xi_{\rm id}}
\lambda_{\min}^{+}
\left[
F_{\rm elem}^{\dagger/2}(\zeta)
F_I(\zeta)
F_{\rm elem}^{\dagger/2}(\zeta)
\right].
}
\]

该归一化形式与已有压缩 FIM 工作同形。本文只能声称：参考矩阵是实际阵元域 FIM，候选压缩为确定性的顺序规则波束子集，评价采用最坏场景/最坏方向，并显式处理阵元域本身不可辨识的子空间。

若

\[
\eta(I)\ge\eta_0,
\]

则局部可辨识方向上的预测 CRB 膨胀上限为

\[
\rho_{\rm CRB}\le\frac1{\eta_0}.
\]

这只是一阶局部信息保证，不是有限样本成功率保证。

### 9.6 顺序 DBF 的结构化成本

只用 \(|I_e||I_a|\) 不能代表完整运算量。对每个距离–脉冲样本，可报告近似成本

\[
C_{\rm el}
=c_{\rm el}|I_e|N_\phi N_z,
\]

\[
C_{\rm az}
=c_{\rm az}|I_e||I_a|N_\phi,
\]

\[
C_{\rm out}
=c_{\rm out}|I_e||I_a|,
\]

以及存储/搬运成本 \(C_{\rm mem}\)。总成本写为

\[
\boxed{
C(I_e,I_a)
=C_{\rm el}+C_{\rm az}+C_{\rm out}+C_{\rm mem}.
}
\]

系数优先由实际 MATLAB profiling、目标平台运算计数或硬件接口带宽得到。若暂时无法获得，只能分别报告各项，不能把随意权重包装成统一最优目标。

### 9.7 设计问题

\[
\boxed{
\min_{I_e,I_a}C(I_e,I_a)
}
\]

满足

\[
\boxed{
\eta(I_e,I_a)\ge\eta_0,
}
\]

以及必要的固定约束：

- 候选来自实际规则 DBF 波束库；
- 子集白化有效秩满足最小要求；
- 局部角单元覆盖不含真值泄漏；
- 设计集与 holdout 完全隔离；
- 配置锁定后不在 holdout 调整 \(\eta_0\)、波束数或候选池。

### 9.8 求解策略

小候选池：

- 完全枚举，得到**当前有限池内**全局最优；
- 报告候选池大小和枚举次数，不能写一般全局最优。

大候选池：

1. 固定相邻规则波束集初始化；
2. 按“重新计算后的最坏 \(\eta\) 增益/成本”执行 add；
3. 执行 drop 和 pair-swap；
4. 每次候选变化均重新构造 \(C_I\)、白化流形和 FIM；
5. 对可枚举子问题报告最优差距；
6. 没有次模性证明时不声称固定近似比；
7. 连续 SVD 子空间只作松弛上界，因为它忽略物理规则波束和结构化成本。

### 9.9 FIM 通过后的有限样本二阶段验收

FIM 只用于第一阶段筛选。通过 \(\eta\) 约束的波束集还必须在独立 holdout 检查：

- threshold SNR；
- 错误局部峰率；
- K1 false split；
- K2 missed split；
- false resolved；
- 无条件惩罚误差；
- weak secondary 和强相干失败率；
- 相同 \(\eta\) 但有限样本风险不同的反例；
- 实际运行时间、内存和输出带宽。

阶段 7 只在 oracle-K、oracle-Q、oracle-Kq 条件下执行独立有限样本风险验证。K1/K2 模型阶数逻辑、bootstrap、false-split、missed-split、false-resolved 和 resolved/unresolved 指标均未执行，仍属于后续阶段而非本阶段结果。

不得再构造“FIM + ambiguity + success”的经验线性加权分数。采用分层判定：

1. 先满足 FIM 保真约束；
2. 再满足预注册有限样本风险约束；
3. 任一不通过则否决该子集或降级该贡献。

### 9.10 必须正面对比的波束选择基线

- 固定连续 3/5/7/... 规则波束；
- 旧 `greedy_combined_B7`；
- 刘旗等 2026 的 CRB 近似保真设计或可复现等价实现；
- Chepuri–Leus 型独立观测稀疏选择参考；
- exact-subset FIM greedy add；
- greedy + drop/pair-swap；
- 小池穷举最优；
- 连续 SVD 子空间上界。

若新方法相对于固定相邻波束没有通道、成本或有限样本性能收益，则该部分应降级为系统设计分析，而不是核心算法创新。

阶段 7 的实测结果触发了该降级条件：`EXACT_ETA_080` 与 `FIXED_RECT_3X5` 是同一 `RECT_E14_A31` 子集，MAC 均为 7215，所有 5800 个注册有限样本上的逐场景汇总指标一致。相对完整 5x5 父池的 MAC 降幅为 40%，但相对最强固定矩形的降幅为 0%，因此不得声称波束选择算法取得 Pareto 收益。

## 10. 局部目标数和不可分辨判定

> **prior-art 定位：** source enumeration、非正则 LRT、parametric bootstrap、统计角分辨极限和拒判机制均有前例。本节是风险控制与工程状态接口，不单独作为新统计理论。

## 10.1 候选目标数

主论文至少处理

\[
K\in\{1,2\},
\]

可选扩展到

\[
K_{\max}=3.
\]

俯仰组数为 \(Q\)，各组目标数为 \(K_q\)，满足

\[
K=\sum_{q=1}^{Q}K_q.
\]

### 10.2 集中似然残差

对候选目标数 \(K\)，令最优残差为

\[
RSS_K
=
\min_{\Theta_K,S}
\|
\widetilde Z-G_K(\Theta_K)S
\|_F^2.
\]

未知噪声方差的集中对数似然为

\[
\ell_K^\star
=
-BL
\log
\left(
\frac{RSS_K}{BL}
\right)
+C.
\]

相邻模型的似然比统计量为

\[
\boxed{
\Lambda_{K,K+1}
=
2BL
\log
\frac{RSS_K}{RSS_{K+1}}.
}
\]

### 10.3 为什么不能直接使用普通卡方阈值

在 \(K\) 目标原假设下新增第 \(K+1\) 个目标时：

- 新目标复幅度为零，处于参数边界；
- 新目标角度在原假设下不可辨识；
- 两个目标重合时模型退化；
- 目标标签存在置换对称性。

普通 Wilks 定理的正则条件不成立，因此不建议直接套固定 \(\chi^2\) 阈值。

### 10.4 参数 bootstrap

对 \(K\rightarrow K+1\) 判定：

1. 拟合 \(K\) 目标模型，得到
   \[
   \widehat\Theta_K,\widehat S_K,\widehat\sigma_K^2.
   \]
2. 在拟合的 \(K\) 目标模型下生成 \(B_{\rm boot}\) 组 bootstrap 数据。
3. 每组数据都完整运行 K 和 K+1 估计器。
4. 计算
   \[
   \Lambda_{K,K+1}^{(b)}.
   \]
5. 取经验 \(1-\alpha\) 分位数
   \[
   q_{1-\alpha}^{\rm boot}
   \]
   作为阈值。
6. 当
   \[
   \Lambda_{K,K+1}>
   q_{1-\alpha}^{\rm boot}
   \]
   时接受增加目标。

这里唯一的统计控制量是

\[
\alpha=
\text{允许的 false-split 概率}.
\]

### 10.5 可分辨与不可分辨

即使 K2 模型显著优于 K1，也不代表两个角度都能稳定估计。

定义目标差向量

\[
\Delta\boldsymbol\xi
=
\boldsymbol\xi_2-\boldsymbol\xi_1.
\]

通过参数 bootstrap 得到其联合置信区域 \(\mathcal C_\Delta^{1-\beta}\)。

推荐判定：

- `K2_RESOLVED`：K2 通过模型阶数检验，且 \(0\notin\mathcal C_\Delta^{1-\beta}\)，同时角度置信区满足系统精度要求；
- `K2_UNRESOLVED`：K2 有统计证据，但差向量置信区域仍包含零，或估计不确定度超过工程容限；
- `K1`：K2 未通过 false-split 控制的检验。

这避免算法在信息不足时强制输出两个看似精确的角度。

### 10.6 推荐状态输出

```text
K1
K2_RESOLVED
K2_UNRESOLVED
K3_RESOLVED          % 可选扩展
OUT_OF_LOCAL_CELL
SEARCH_NOT_CONVERGED
MODEL_MISMATCH
NUMERIC_RANK_DEFICIENT
```

状态标签只描述统计/数值证据，不通过额外规则修改 DML 估计结果。

---

## 11. 稳定 DML 数值实现

### 11.1 不再使用固定岭投影

旧实现

\[
G(G^HG+10^{-10}I)^{-1}G^H
\]

不是严格正交投影，并且固定绝对正则与矩阵尺度无关。

新实现统一采用 economy SVD 或 rank-revealing QR。

### 11.2 SVD 评分

\[
G=U\Sigma V^H.
\]

相对秩阈值：

\[
\tau_{\rm rank}
=
\max(B,K)
\epsilon_{\rm mach}
\sigma_1(G)
\cdot c_{\rm rank},
\]

其中 \(c_{\rm rank}\) 默认为 1，只在数值实验明确证明需要时调整。

有效秩

\[
r
=
\#\{\sigma_i>\tau_{\rm rank}\}.
\]

评分

\[
\boxed{
J(\Theta)
=
\|U_r^H\widetilde Z\|_F^2.
}
\]

残差

\[
\boxed{
RSS(\Theta)
=
\|\widetilde Z\|_F^2-J(\Theta).
}
\]

同时输出：

- `effective_rank`
- `singular_values`
- `sigma_min_effective`
- `relative_rank_threshold`
- `rss`
- `score`
- `projection_idempotence_error`（仅测试模式）

### 11.3 白化的稳定实现

对白化协方差

\[
C_b=W^HR_nW
\]

做特征分解

\[
C_b=Q\Lambda Q^H.
\]

使用相对阈值

\[
\tau_b
=
\max(B,1)
\epsilon_{\rm mach}
\lambda_{\max}
\cdot c_b.
\]

保留

\[
\lambda_i>\tau_b
\]

的有效子空间，构造

\[
C_b^{\dagger/2}
=
Q_r\Lambda_r^{-1/2}Q_r^H.
\]

如果有效秩小于所需目标数，应返回数值状态，而不是继续用固定 floor 强行求逆。

---

## 12. 完整复杂度与计算预算

不得再用

\[
O\{TK(N_\phi^{\rm loc}+N_\theta^{\rm loc})\}
\]

代表整个算法；该式最多描述联合修正中的某一部分。完整复杂度必须分为在线推理、离线校准和离线波束设计。

### 12.1 在线顺序 DBF 成本

对每个距离–脉冲样本，近似有

\[
C_{\rm elDBF}
=O(B_eN_\phi N_z),
\]

\[
C_{\rm azDBF}
=O(B_eB_aN_\phi),
\]

输出通道数为

\[
B_{\rm out}=B_eB_a.
\]

必须同时报告复乘加次数、内存流量和实际 wall time。

### 12.2 在线估计总成本

\[
\boxed{
C_{\rm online}
=
C_{\rm elDBF}
+C_{\rm azDBF}
+C_{\rm group\_fit}
+\sum_{q=1}^{Q}C_{{\rm az},q}
+C_{\rm joint}
+C_{\rm K1/K2}.
}
\]

其中：

- 若俯仰 Q=2 采用直接二维网格，\(C_{\rm group\_fit}\) 仍可含 \(O(N_\theta^2)\)；
- 若组内 \(K_q=2\) 采用直接方位双源搜索，\(C_{{\rm az},q}\) 仍可含 \(O(N_\phi^2)\)；
- AP/PR-DML 的代价必须按实际 score 调用、特征分解和迭代次数统计；
- 联合修正需要报告每次迭代的候选数、SVD 次数和多初值次数；
- K1/K2 在线判定至少包含 K1 和 K2 两次完整拟合。

### 12.3 bootstrap 校准成本

若对每个在线样本重新执行 \(B_{\rm boot}\) 次完整 K1/K2 拟合，成本约为

\[
C_{\rm bootstrap,online}
\approx
B_{\rm boot}(C_{K1}+C_{K2}),
\]

通常不适合实时处理。优先采用：

- 在锁定配置和 nuisance 参数网格上离线 parametric bootstrap；
- 独立 calibration 数据生成阈值表或保守上界；
- 在线只执行 K1/K2 拟合和阈值查表；
- 若必须逐样本 bootstrap，单独报告其延迟，不能隐藏在“模型阶数模块”中。

离线校准成本写为

\[
C_{\rm calibration}
=
N_{\rm cfg}B_{\rm boot}(C_{K1}+C_{K2}).
\]

### 12.4 FIM 波束设计成本

波束选择为离线设计：

\[
C_{\rm design}
=
N_{\rm subset}N_{\rm scenario}C_{\rm FIM},
\]

其中每个子集都需要重构相关噪声协方差、白化器、流形导数和广义特征值。大池 greedy/add/drop/pair-swap 的每次候选重评估必须计入。

### 12.5 公平比较单位

至少同时提供：

- DML score 调用次数；
- QR/SVD 次数及矩阵尺寸；
- AP/PR 迭代次数；
- 多初值次数；
- K1/K2 拟合次数；
- bootstrap 重拟合次数；
- 实际 wall time；
- 峰值内存；
- 顺序 DBF 输出通道数和数据量。

与 AP-DML、PR-DML 和 local full DML 的比较必须采用相同 score-call、wall-time 或明确的 Pareto 曲线预算，不能只比较候选数代理。

## 13. 双目标与多目标的论文边界

### 13.1 双目标能否作为硕士论文创新

可以，但创新不能写成“研究了两个目标”。双目标是最小非平凡未分辨目标簇：

- 单目标不存在分辨问题；
- 双目标开始出现流形共线、分辨阈值和模型阶数问题；
- 可形成完整的定理、算法、模型选择和压力实验闭环。

建议主理论和主实验集中在

\[
K\in\{1,2\}.
\]

### 13.2 有限多目标扩展

建议只做有限的

\[
K=3
\]

结构验证：

1. 三个不同俯仰组；
2. 两目标同俯仰、一个不同俯仰；
3. 三目标同俯仰但方位可分；
4. 一个弱目标；
5. 两个相干目标加一个独立目标。

推荐论文表述：

> 所提分组结构原则上可扩展到 \(K>2\)。本文围绕最小未分辨目标簇 \(K=2\) 给出完整理论和统计验证，并通过 \(K=3\) 场景验证有限多目标扩展能力，不宣称已解决任意目标数的全局最优估计。

---

## 14. 建议的正式贡献表述

### 贡献 1：分组条件顺序 DML 组合

> 面向实际“先俯仰、后方位”的顺序接收 DBF 数据接口，构造以可辨俯仰组为中间变量的条件 DML 流程；在各俯仰组内进行条件方位单目标或有限多目标估计，并使用固定的完整顺序波束流形进行局部联合修正，以处理同俯仰组内多目标和圆柱阵方位–俯仰耦合。

定位：完整组合暂未发现直接工作；DML、条件估计和坐标修正分别为已有机制。必须通过同预算 AP/PR/local-full-DML 比较证明组合收益。

### 贡献 2：顺序白化流形的近双目标显式局部推论

> 基于经典投影 Fisher 信息和阵列流形局部几何，针对固定、精确白化的顺序接收波束二维流形，推导近双目标第二奇异值、归一化相关性和列归一化 Gram 条件数关于二维分离方向的共同局部二次型，并给出零方向和高阶退化边界。

定位：场景化显式理论推论；不声称首次提出切向矩阵、Taylor/和差变换或相关性–FIM 联系。

### 贡献 3：相关规则顺序波束库的系统特化设计

> 在已有压缩 FIM 和 FIM 约束最少选择框架基础上，针对相邻波束噪声相关、子集白化随选择变化的俯仰/方位规则波束库，按相对阵元域的最坏信息保真和顺序 DBF 结构化成本选择最小局部波束集，并通过独立低 SNR、近目标、功率失衡和相干 holdout 验证有限样本风险。

定位：已有目标骨架上的相关噪声和工程接口特化。阶段 7 已完成并发现 exact 解不优于最强固定相邻矩形，因此该项正式降级为系统设计分析，不作为核心算法创新。

### 统计支撑机制

> 使用独立 K1 holdout 校准的 parametric-bootstrap DML 阶数判定控制 false split，并结合分离置信区域和信息退化诊断区分 `K2_RESOLVED`、`K2_UNRESOLVED` 和 `GROUP_UNIDENTIFIABLE`。

定位：已有统计机制的工程集成，不单列为基础理论创新。

## 15. 必须删除或降级的旧主张

| 旧内容 | 新定位 |
|---|---|
| 真实圆柱阵流形本身是创新 | 正确建模基础 |
| beamspace DML 本身是创新 | 经典估计准则 |
| 中心–分离坐标自动降维 | 删除；它本身只是重参数化 |
| 离散 el-sep 列表 | 旧方法的工程候选约束 |
| `greedy_combined_B7` | 历史经验 baseline |
| `cond(W^HW)` 统计惩罚 | 降为数值/硬件约束 |
| fixed topK3 | 搜索 baseline |
| C05 | 已否决的规则预算 baseline，不进入新主线 |
| fixed-grid cache | 软件优化，不是统计估计创新 |
| 完整全息凝视雷达工作模式实现 | 删除；本文只研究其局部精测角模块 |

---

# 16. 公式与算法相关参考文献

以下文献按与本文公式的关系分组。链接优先使用 DOI；预印本使用 arXiv。该列表是后续论文公式和 baseline 设计所需的核心集合，不代表全球穷尽式系统综述。

## 16.1 DML、集中似然、CRB 与多源优化

1. Ziskind, I.; Wax, M. “Maximum likelihood localization of multiple sources by alternating projection.” *IEEE Transactions on Acoustics, Speech, and Signal Processing*, 1988.  
   DOI: https://doi.org/10.1109/29.7543  
   用途：多源 DML、alternating projection、低维迭代 baseline。

2. Stoica, P.; Nehorai, A. “MUSIC, maximum likelihood, and Cramer-Rao bound.” *IEEE Transactions on Acoustics, Speech, and Signal Processing*, 1989.  
   DOI: https://doi.org/10.1109/29.17564  
   用途：ML、MUSIC 与 CRB 的理论关系。

3. Stoica, P.; Sharman, K. C. “Maximum likelihood methods for direction-of-arrival estimation.” *IEEE Transactions on Acoustics, Speech, and Signal Processing*, 1990.  
   DOI: https://doi.org/10.1109/29.57542  
   用途：DML/SML 集中似然和 nuisance 幅度消元。

4. Stoica, P.; Nehorai, A. “MUSIC, maximum likelihood, and Cramer-Rao bound: further results and comparisons.” 1990.  
   DOI: https://doi.org/10.1109/29.61541  
   用途：ML 性能与 CRB 补充理论。

5. Athley, F. “Threshold region performance of maximum likelihood direction of arrival estimators.” *IEEE Transactions on Signal Processing*, 2005.  
   DOI: https://doi.org/10.1109/TSP.2005.843717  
   用途：低 SNR 阈值区、异常估计概率。

6. Vincent, F.; Besson, O.; Chaumette, E. “Approximate maximum likelihood estimation of two closely spaced sources.” *Signal Processing*, 2014.  
   DOI: https://doi.org/10.1016/j.sigpro.2013.10.017  
   用途：近双源近似 ML，双目标直接 baseline。

7. Wang, H.; Kay, S.; Saha, E. “An importance sampling maximum likelihood direction of arrival estimator.” *IEEE Transactions on Signal Processing*, 2008.  
   DOI: https://doi.org/10.1109/TSP.2008.928504  
   用途：非穷举 ML 全局搜索 baseline。

8. Trinh-Hoang, M.; Viberg, M.; Pesavento, M. “Partial Relaxation Approach: An Eigenvalue-Based DOA Estimator Framework.” 2017/2018.  
   arXiv: https://arxiv.org/abs/1711.01982  
   用途：将多源 DML/WSF 等多维问题放松为谱搜索；条件方位多源估计的重要 baseline。

9. Yang, Z.; Chen, X. “Maximum Likelihood Direction-of-Arrival Estimation via Rank-Constrained ADMM.” 2021.  
   DOI: https://doi.org/10.1109/RADAR53847.2021.10028640  
   用途：ML 优化求解 baseline。

10. Pote, R.; Rao, B. D. “Maximum Likelihood-Based Gridless DoA Estimation Using Structured Covariance Matrix Recovery and SBL With Grid Refinement.” *IEEE Transactions on Signal Processing*, 2023.  
    DOI: https://doi.org/10.1109/TSP.2023.3254919  
    用途：连续/gridless 和网格细化 baseline。

11. Gerstoft, P.; Park, Y. “Atom-Constrained Maximum Likelihood Gridless DOA with Wirtinger Gradients.” ICASSP 2025.  
    DOI: https://doi.org/10.1109/ICASSP49660.2025.10889232  
    用途：连续参数 ML 与梯度优化。

12. Zhou, Y.; Cao, Z.; Zhang, X. “Gridless DOA estimation for arbitrary array geometries based on maximum likelihood.” *Signal Processing*, 2026.  
    DOI: https://doi.org/10.1016/j.sigpro.2025.110415  
    用途：任意阵列几何的 gridless ML，圆柱阵连续估计的重要近邻。

## 16.2 Beamspace ML 与近双目标场景

13. Zoltowski, M. D.; Lee, T.-S. “Maximum likelihood based sensor array signal processing in the beamspace domain for low angle radar tracking.” 1991.  
    DOI: https://doi.org/10.1109/78.80885  
    用途：beamspace ML 经典直接先验。

14. Davis, R. C.; Fante, R. L. “A maximum-likelihood beamspace processor for improved search and track.” 2001.  
    DOI: https://doi.org/10.1109/8.933484  
    用途：beamspace ML 搜索/跟踪处理器。

15. Kim, H.; Yang, J.; Kwak, N. “Low-angle tracking of two objects in a three-dimensional beamspace domain.” 2012.  
    DOI: https://doi.org/10.1049/IET-RSN.2010.0163  
    用途：三维 beamspace 双目标，最直接场景 baseline 之一。

16. 陈生等. “米波 MIMO 雷达波束空间精确最大似然算法.” 2022.  
    DOI: https://doi.org/10.12305/j.issn.1001-506X.2022.05.24  
    用途：中文 beamspace 精确 ML 直接先验。

17. Chen, S. et al. “A beamspace maximum likelihood algorithm for target height estimation for a bistatic MIMO radar.” *Digital Signal Processing*, 2022.  
    DOI: https://doi.org/10.1016/j.dsp.2021.103330  
    用途：场景化 BML 和高度估计。

18. Tang, X. et al. “Bistatic MIMO radar height estimation method based on adaptive beam-space RML data fusion.” *Digital Signal Processing*, 2024.  
    DOI: https://doi.org/10.1016/j.dsp.2023.104346  
    用途：自适应 beamspace RML 近邻。

19. Chen, S. et al. “Beamspace Maximum Likelihood Algorithm Based on Sum and Difference Beams for Elevation Estimation.” 2024.  
    DOI: https://doi.org/10.23919/JSEE.2024.000057  
    用途：和差波束 BML 和俯仰估计。

20. 刘旗等. “低仰角目标高精度波束空间 DOA 估计方法.” 2026.  
    DOI: https://doi.org/10.12000/JR25173  
    用途：阵元/波束域 CRB 等价条件和 BML 波束设计；创新点 2 必须逐式比较的强近邻。

## 16.3 任务相关波束域降维、流形保真与测量设计

21. Anderson, B. D. O. “On optimal dimension reduction for sensor array signal processing.” *Signal Processing*, 1993.  
    DOI: https://doi.org/10.1016/0165-1684(93)90150-9  
    用途：任务相关阵列降维。

22. Hyberg, P.; Jansson, M.; Ottersten, B. “Array interpolation and bias reduction.” 2004.  
    DOI: https://doi.org/10.1109/TSP.2004.834402  
    用途：Frobenius 流形误差和 DOA 偏差。

23. Hassanien, A. et al. “Convex optimization based beam-space preprocessing with improved robustness against out-of-sector sources.” 2006.  
    DOI: https://doi.org/10.1109/TSP.2006.870564  
    用途：关注扇区内流形保持和扇区外鲁棒性。

24. Belloni, F.; Koivunen, V. “Beamspace transform for UCA: error analysis and bias reduction.” 2006.  
    DOI: https://doi.org/10.1109/TSP.2006.877664  
    用途：圆阵 beamspace 变换误差与偏差。

25. Belloni, F.; Richter, A.; Koivunen, V. “DoA estimation via manifold separation for arbitrary array structures.” 2007.  
    DOI: https://doi.org/10.1109/TSP.2007.896115  
    用途：任意阵列流形建模。

26. Kautz, G. M.; Zoltowski, M. D. “Beamspace DOA estimation featuring multirate eigenvector processing.” 1996.  
    DOI: https://doi.org/10.1109/78.510623  
    用途：beamspace 维数、条件性和处理结构。

27. Ibrahim, M. et al. “Design and analysis of compressive antenna arrays for direction of arrival estimation.” *Signal Processing*, 2017.  
    DOI: https://doi.org/10.1016/j.sigpro.2017.03.013  
    用途：通道数、CRB 和硬件约束折中。

28. Kilic, V. et al. “Adaptive Measurement Matrix Design in Direction of Arrival Estimation.” *IEEE Transactions on Signal Processing*, 2022.  
    DOI: https://doi.org/10.1109/TSP.2022.3209880  
    用途：DOA measurement matrix、coherence/RIP 和信息设计。

29. Khabbazibasmenj, A. et al. “Efficient transmit beamspace design for search-free based DOA estimation in MIMO radar.” 2014.  
    DOI: https://doi.org/10.1109/TSP.2014.2299513  
    arXiv: https://arxiv.org/abs/1305.4979  
    用途：面向 DOA 后端的 beamspace matrix design。

30. Hassanien, A.; Vorobyov, S. A. “Transmit energy focusing for DOA estimation in MIMO radar with colocated antennas.” 2011.  
    DOI: https://doi.org/10.1109/TSP.2011.2125960  
    用途：角域任务相关波束能量设计。


### 16.3A 压缩 FIM、最少选择与 threshold effect（必须正面引用）

- **FIM-1** Chepuri, S. P.; Leus, G. “Sparsity-Promoting Sensor Selection for Non-linear Measurement Models.” 2014.  
  arXiv: https://arxiv.org/abs/1310.5251  
  用途：最少选择、全参数域 FIM 最小特征值约束、稀疏松弛和随机化；其 FIM 可加假设不能未经证明直接套用于相关 DBF 波束。

- **FIM-2** Pakrooh, P. et al. “Analysis of Fisher Information and the Cramer-Rao Bound for Nonlinear Parameter Estimation after Compressed Sensing.” *IEEE Transactions on Signal Processing*, 2015.  
  DOI: https://doi.org/10.1109/TSP.2015.2464183  
  arXiv: https://arxiv.org/abs/1504.01081  
  用途：压缩前后归一化 FIM、CRB 膨胀和压缩维数选择；直接约束本文归一化保真主张。

- **FIM-3** Pakrooh, P.; Scharf, L. L.; Pezeshki, A. “Threshold Effects in Parameter Estimation from Compressed Data.” *IEEE Transactions on Signal Processing*, 2016.  
  DOI: https://doi.org/10.1109/TSP.2016.2521617  
  arXiv: https://arxiv.org/abs/1505.07431  
  用途：近双源、压缩、subspace swap 和 threshold SNR；证明 FIM/CRB 保真不能替代有限样本风险验证。

- **FIM-4** “Differential Geometry of Array Manifold Surfaces.” 2004.  
  DOI: https://doi.org/10.1142/9781860946028_0003  
  用途：阵列流形局部切向、曲率和几何度量；约束近双目标理论的基础新颖性。

- **FIM-5** “Statistical Angular Resolution Limit for Point Sources.” 2007.  
  DOI: https://doi.org/10.1109/TSP.2007.898789  
  用途：近点源统计分辨极限以及“存在多个源”与“参数可分辨”的区别。

- **FIM-6** “Angular Statistical Resolution Limit of Two Closely-Spaced Point Targets: A GLRT-Based Study.” 2018.  
  DOI: https://doi.org/10.1109/ACCESS.2018.2882889  
  用途：GLRT 分辨状态与 `K2_UNRESOLVED` 的直接概念近邻。

- **FIM-7** “A source enumeration method based on subspace orthogonality and bootstrap technique.” 2013.  
  DOI: https://doi.org/10.1016/j.sigpro.2012.11.007  
  用途：阵列源数估计中的 bootstrap 直接前例。

## 16.4 近源相关性、字典相干与分辨阈值

31. Malioutov, D.; Cetin, M.; Willsky, A. “A sparse signal reconstruction perspective for source localization with sensor arrays.” 2005.  
    DOI: https://doi.org/10.1109/TSP.2005.850882  
    用途：DOA 流形字典和相关性。

32. Donoho, D.; Elad, M. “Optimally sparse representation in general dictionaries via \(\ell_1\) minimization.” 2003.  
    DOI: https://doi.org/10.1073/pnas.0437847100  
    用途：mutual coherence 理论；只能间接支撑流形相关性，不能证明旧 W-score。

33. Tropp, J. “Greed is good: Algorithmic results for sparse approximation.” 2004.  
    DOI: https://doi.org/10.1109/TIT.2004.834793  
    用途：coherence 与贪心理论；不能直接赋予旧三项评分近似保证。

34. Lee, H. B.; Wengrovitz, M. S. “Resolution threshold of beamspace MUSIC for two closely spaced emitters.” 1990.  
    DOI: https://doi.org/10.1109/29.60074  
    用途：beamspace 近双源分辨阈值背景。

35. Shan, T.-J.; Wax, M.; Kailath, T. “On spatial smoothing for direction-of-arrival estimation of coherent signals.” 1985.  
    DOI: https://doi.org/10.1109/TASSP.1985.1164649  
    用途：相干源平滑经典 baseline。

36. Pillai, S. U.; Kwon, B. H. “Forward/backward spatial smoothing techniques for coherent signal identification.” 1989.  
    DOI: https://doi.org/10.1109/29.17496  
    用途：相干源前后向平滑 baseline。

## 16.5 多分辨率和搜索加速

37. Gurbuz, A. C.; Cevher, V.; McClellan, J. “Bearing estimation via spatial sparsity using compressive sensing.” 2012.  
    DOI: https://doi.org/10.1109/TAES.2012.6178067  
    用途：多分辨率网格和局部细化。

38. Han, K. et al. “Two novel DOA estimation approaches for real-time assistant calibration systems in future vehicle industrial.” 2015.  
    DOI: https://doi.org/10.1109/JSYST.2015.2413691  
    用途：粗网格后局部精细网格。

39. Zotkin, D.; Duraiswami, R. “Accelerated speech source localization via a hierarchical search of steered response power.” 2004.  
    DOI: https://doi.org/10.1109/TSA.2004.832990  
    用途：层次化区域细分思想；非雷达 ML 直接公式。

## 16.6 非均匀噪声、相关噪声和模型失配

40. Pesavento, M.; Gershman, A. B. “Maximum-likelihood direction-of-arrival estimation in the presence of unknown nonuniform noise.” 2001.  
    DOI: https://doi.org/10.1109/78.928686  
    用途：一般非均匀噪声 ML。

41. Djeddou, M.; Belouchrani, A.; Aouada, D. “Maximum likelihood angle-frequency estimation in partially known correlated noise for low-elevation targets.” 2005.  
    DOI: https://doi.org/10.1109/TSP.2005.851194  
    用途：低仰角、相关噪声和联合参数估计。

42. Akdemir, E.; Candan, C. “Maximum-likelihood direction of arrival estimation under intermittent jamming.” *Digital Signal Processing*, 2021.  
    DOI: https://doi.org/10.1016/j.dsp.2021.103028  
    用途：干扰与模型失配下的 ML。

## 16.7 模型阶数与非正则似然检验

43. Wax, M.; Kailath, T. “Detection of signals by information theoretic criteria.” 1985.  
    DOI: https://doi.org/10.1109/TASSP.1985.1164557  
    用途：阵列信号数估计经典背景；不直接解决当前边界型 K1/K2 检验。

44. Davies, R. B. “Hypothesis testing when a nuisance parameter is present only under the alternative.” *Biometrika*, 1977.  
    DOI: https://doi.org/10.1093/biomet/64.2.247  
    用途：新增目标角度只在备择模型下存在的非正则性。

45. Self, S. G.; Liang, K.-Y. “Asymptotic properties of maximum likelihood estimators and likelihood ratio tests under nonstandard conditions.” *JASA*, 1987.  
    DOI: https://doi.org/10.1080/01621459.1987.10478472  
    用途：参数边界下的非标准似然比理论。

46. Davison, A. C.; Hinkley, D. V. *Bootstrap Methods and Their Application*. Cambridge University Press, 1997.  
    出版社：https://www.cambridge.org/core/books/bootstrap-methods-and-their-application/ED2FD043579F27952363566DC09CBD6A  
    用途：参数 bootstrap 和置信区间。

## 16.8 数值线性代数

47. Golub, G. H.; Van Loan, C. F. *Matrix Computations*, 4th ed., 2013.  
    出版社：https://www.press.jhu.edu/books/title/10678/matrix-computations  
    用途：SVD、QR、伪逆、数值秩和子空间计算。

48. Hansen, P. C. “The truncated SVD as a method for regularization.” 1987.  
    DOI: https://doi.org/10.1007/BF01937276  
    用途：截断 SVD 和正则化背景；不能为固定 `1e-10` 提供依据。

49. Van Trees, H. L. *Optimum Array Processing*. 2002.  
    DOI: https://doi.org/10.1002/0471221104  
    用途：阵列处理、似然和 Fisher 信息基础。

## 16.9 全息凝视雷达工程背景

50. 郭瑞等. “全息凝视雷达系统技术与发展应用综述.” 2023.  
    DOI: https://doi.org/10.12000/JR22153  
    用途：全息凝视雷达系统、数字阵列和工作模式背景。

51. Guo, R.; Zhang, Z.; Chen, J. “Design and Implementation of a Holographic Staring Radar for UAVs and Birds Surveillance.” 2023.  
    DOI: https://doi.org/10.1109/RADAR54928.2023.10371201  
    用途：实际系统设计和工程背景。

52. Oswald, G.; Baker, C. *Holographic Staring Radar*. 2021.  
    DOI: https://doi.org/10.1049/SBRA518E  
    用途：全息凝视雷达专著背景。

---

## 17. 后续理论与新颖性验证清单

在写入正式论文前，至少完成以下闭环。

### 17.1 模型和数值正确性

1. 单程接收导向矢量、解析导数和有限差分一致；
2. 真实先俯仰后方位级联 DBF 与等效顺序权数值一致；
3. 白化后噪声协方差与单位阵一致；
4. SVD-DML 与高精度参考在良态样本一致，近秩亏样本无 NaN/Inf；
5. 候选搜索期间物理测量和白化坐标固定。

### 17.2 分组条件 DML 可辨识性

6. 同时报告 \(\operatorname{rank}G_e\) 和 \(\operatorname{rank}C_e\)；
7. 构造 \(\operatorname{rank}C_e<Q\) 的反例并正确返回 `GROUP_UNIDENTIFIABLE`；
8. 验证 \(L=1\) 时环向列只作为 MMV 系数列，不误写为独立时间快拍；
9. 分组恢复中间量的子空间误差、串扰和角度结果均被验证；
10. 与 AP-DML、PR-DML、无分组坐标上升、local full DML 同预算比较。

### 17.3 近双目标显式渐近式

11. [已通过] 导数有限差分误差达到预设精度；
12. [已通过] 对纯方位、纯俯仰和斜方向验证三个渐近比趋于 1；
13. [已通过] 显式搜索 $T_{\rm seq}$ 近零方向，不删除失败样本；主物理配置无 exact null；
14. [部分边界闭合] synthetic null 的六阶收敛通过，物理 exact null 未出现；
15. [已通过] 验证列范数不等时未归一化 Gram 条件数的额外影响；
16. [有界完成] 已与近源 CRB、流形几何和统计分辨极限作定向映射；付费数据库全文/cited-by 与专利检索仍未完成。

### 17.4 相关波束 FIM 设计

17. 对每个候选子集重构 \(C_I\)、白化器和 FIM；
18. 不使用未经证明的逐束固定 FIM 可加性；
19. 与固定相邻波束、旧 B7、刘旗等 2026、Chepuri–Leus 参考、小池穷举和连续上界比较；
20. 同时报告 FIM 保真、threshold SNR、错误局部峰、false split、false resolved 和无条件风险；
21. 设计集、validation 和 holdout 完全隔离；
22. 若相同 \(\eta\) 的波束集有限样本风险不同，明确记录 FIM 指标的边界。

### 17.5 模型阶数和不可分辨状态

23. K1 独立 holdout 的 false split 上置信界受控；
24. K2 的 missed split、false resolved、unresolved 和无条件误差全部报告；
25. 检查模型失配下 parametric bootstrap 的校准偏差；
26. 不以 unresolved 排除大量困难样本后只报告条件 RMSE；
27. AIC/MDL、已有 bootstrap source enumeration 和已知 K oracle 作为基线。

### 17.6 新颖性停止条件

满足任一项时降级或否决对应主张：

- 分组条件链在同预算下不优于 AP/PR/local-full-DML；
- 收益完全来自更窄或含真值泄漏的候选域；
- 大量多初值使复杂度优势消失；
- 统一渐近式在规定非退化条件下不收敛或与已有全文完全同式；
- FIM 波束集相对固定相邻波束无成本或有限样本收益；
- bootstrap 无法控制 K1 false split；
- `K2_UNRESOLVED` 被用于隐藏主失败率；
- 最终只能证明已有模块串联，而没有顺序接口带来的独立性能、复杂度或可解释性收益。

本轮“暂未发现直接工作”是有界检索结论，不覆盖专利，也不替代正式投稿前对 Kim 2012、Vincent 2014、统计分辨极限文献及 cited-by 网络的全文核验。
