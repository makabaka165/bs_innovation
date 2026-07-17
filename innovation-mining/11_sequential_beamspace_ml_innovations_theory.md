# 顺序数字波束形成下的局部未分辨目标簇波束域 ML：创新点、公式与理论推导

> 建议仓库位置：`innovation-mining/11_sequential_beamspace_ml_innovations_theory.md`  
> 适用项目：`makabaka165/bs_innovation`  
> 文档状态：候选新主线的理论设计文档，不代表相关代码和实验已经完成。  
> 前置审计：`innovation-mining/10_current_paper_innovation_audit.md`。  
> 已否决路线：`innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md`，不得通过继续调阈值恢复。

---

## 0. 先明确新的创新点

在删除 C05 规则堆叠、弱化 fixed topK3、停止恢复在线自适应 W/B，并将接收空间相位统一为单程模型之后，建议将论文主线收敛为两个核心创新点和一个统计支撑机制。

### 创新点 1：面向“先俯仰 DBF、后方位 DBF”处理链的分组条件波束域 DML

建立与全息凝视雷达实际顺序数字波束形成链一致的圆柱阵接收模型，先利用俯仰 DBF 输出估计可分辨的俯仰目标组，再在各俯仰组条件下执行方位单目标或多目标 DML，最后使用完整顺序波束域流形进行局部联合修正。

该创新点的目标不是简单地把二维搜索拆成两个互不相关的一维搜索，而是利用圆柱阵流形的**俯仰条件可分解结构**：

\[
\mathbf a(\phi,\theta)
=
\mathbf a_\phi(\phi,\theta)\otimes\mathbf a_z(\theta),
\]

其中方位流形仍依赖俯仰角，因此必须采用“俯仰分组—条件方位估计—联合修正”，不能直接宣称方位和俯仰严格解耦。

### 创新点 2：基于近目标切向信息和有效 Fisher 信息保真的最小局部波束集设计

推导近双目标顺序波束域流形的第二奇异值、归一化相关性和 Gram 条件数与局部切向信息矩阵之间的统一渐近关系，并以阵元域到顺序波束域的有效 Fisher 信息保真率为约束，从实际规则 DBF 波束中选择满足给定 CRB 膨胀上限的最小俯仰/方位局部波束集。

该创新点整体替换原来的

\[
\alpha L_{\rm proj}
+\beta C_{\rm corr}
+\gamma\log\kappa(W^HW)
\]

经验加权，不再使用 `alpha/beta/gamma`、固定 B7 或在线自适应 W/B。

### 支撑机制：局部目标数判定与“不可分辨”输出

算法至少完整支持

\[
K\in\{1,2\},
\]

并通过参数 bootstrap 标定的嵌套似然比检验控制单目标被错误分裂为双目标的概率。对于存在双目标迹象、但 Fisher 信息或 bootstrap 置信区域不足以支持两个独立角度的样本，输出 `K2_UNRESOLVED`，而不是强制给出两个高置信角度。

论文的完整理论和主实验聚焦双目标；多目标扩展采用分组形式

\[
K=\sum_{q=1}^{Q}K_q,
\]

并以有限的 \(K=3\) 实验验证结构可扩展性，不宣称已解决任意多目标问题。

---

## 1. 系统术语和研究边界

### 1.1 不再使用含糊的“前端—后端”表述

本项目中的实际硬件前端包括天线、T/R、射频接收、下变频、ADC 等，因此不应再把“常规测角给出中心和窗口”称为前端。

建议统一使用下面四层表述：

| 层级 | 推荐名称 | 主要内容 |
|---|---|---|
| 1 | 阵元数字接收链路 | 射频接收、ADC、数字下变频、脉压，输出阵元级复数据 |
| 2 | 常规顺序 DBF 与检测处理 | 俯仰 DBF、方位 DBF、MTD、CFAR、常规波束峰值或比幅测角 |
| 3 | 局部未分辨目标簇超分辨测角 | 对同一距离–多普勒单元和局部角分辨单元中的目标数与角度进行精估计 |
| 4 | 航迹与资源管理 | 数据关联、航迹滤波、跨 CPI 处理和波束调度 |

本文算法位于第 3 层，推荐名称为：

> **常规顺序数字波束形成之后的局部未分辨目标簇波束域超分辨测角模块。**

### 1.2 局部处理区域的来源

局部角域不能再写成由算法人工给定的固定 \(\pm1.5^\circ\) 或 \(\pm1.2^\circ\) 窗口。推荐两种定义。

#### 定义 A：由常规测角协方差给出的置信角域

常规测角输出

\[
\widehat{\boldsymbol\xi}_c
=
\begin{bmatrix}
\widehat\phi_c\\
\widehat\theta_c
\end{bmatrix},
\qquad
C_c=\operatorname{Cov}(\widehat{\boldsymbol\xi}_c),
\]

则局部区域定义为

\[
\Omega_{\alpha}
=
\left\{
\boldsymbol\xi:
(\boldsymbol\xi-\widehat{\boldsymbol\xi}_c)^T
C_c^{-1}
(\boldsymbol\xi-\widehat{\boldsymbol\xi}_c)
\le
\chi^2_{2,1-\alpha}
\right\}.
\]

#### 定义 B：由常规波束单元给出的物理角分辨区域

若当前检测落在俯仰波束 \(b_e\) 和方位波束 \(b_a\)，则定义

\[
\Omega_{b_e,b_a}
=
\left\{
(\phi,\theta):
(b_e,b_a)
=
\arg\max_{i,j}|z_{i,j}(\phi,\theta)|^2
\right\}.
\]

工程实现中可由相邻波束等响应交点、3 dB 边界或常规比幅测角有效区间近似该区域。算法参数应建立在这个物理区域上，而不是建立在人工固定角度窗口上。

### 1.3 论文应明确排除的内容

本文不宣称：

- 完成从射频硬件到航迹管理的完整雷达闭环；
- 完成全空域任意多目标盲搜索；
- 顺序 DBF 使圆柱阵方位和俯仰严格独立；
- 所有强相干、同角和零功率差模场景均可辨识；
- C05、fixed topK3、cache 或白化本身构成统计估计算法创新；
- 任意 \(K\) 多目标问题已被统一解决。

---

## 2. 接收单程圆柱阵模型

### 2.1 圆柱阵几何

设圆柱阵有 \(N_\phi\) 个环向阵元列和 \(N_z\) 个垂直阵元。第 \(m\) 个环向位置为

\[
\psi_m=\frac{2\pi m}{N_\phi},
\qquad m=0,\ldots,N_\phi-1,
\]

第 \(n\) 个垂直坐标为 \(z_n\)。阵元位置为

\[
\mathbf r_{m,n}
=
\begin{bmatrix}
R\cos\psi_m\\
R\sin\psi_m\\
z_n
\end{bmatrix}.
\]

方位角和俯仰角分别记为 \(\phi\) 和 \(\theta\)，到达方向单位矢量为

\[
\mathbf u(\phi,\theta)
=
\begin{bmatrix}
\cos\theta\cos\phi\\
\cos\theta\sin\phi\\
\sin\theta
\end{bmatrix}.
\]

### 2.2 接收单程空间相位

本文只建模接收阵列的空间相位，波数为

\[
k=\frac{2\pi}{\lambda}.
\]

单阵元接收导向项为

\[
\boxed{
a_{m,n}(\phi,\theta)
=
\exp\left(
\mathrm j k\mathbf r_{m,n}^T\mathbf u(\phi,\theta)
\right).
}
\]

目标距离造成的双程公共相位可以吸收到未知复幅度 \(s_{k,l}\) 中，因此接收空间导向矢量中不再乘以额外的双程因子 2。

展开内积：

\[
\mathbf r_{m,n}^T\mathbf u(\phi,\theta)
=
R\cos\theta\cos(\phi-\psi_m)
+z_n\sin\theta.
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
\exp\left[
\mathrm jkR\cos\theta\cos(\phi-\psi_m)
\right],
\]

\[
a_{z,n}(\theta)
=
\exp\left(
\mathrm jkz_n\sin\theta
\right).
\]

令

\[
\mathbf a_\phi(\phi,\theta)
=
[a_{\phi,0},\ldots,a_{\phi,N_\phi-1}]^T,
\]

\[
\mathbf a_z(\theta)
=
[a_{z,0},\ldots,a_{z,N_z-1}]^T.
\]

若阵元数据矩阵按“垂直阵元 × 环向列”存放并按列向量化，则

\[
\boxed{
\mathbf a(\phi,\theta)
=
\mathbf a_\phi(\phi,\theta)
\otimes
\mathbf a_z(\theta).
}
\]

该式是**俯仰条件可分解**，不是严格的方位–俯仰独立可分解，因为 \(\mathbf a_\phi\) 仍含 \(\cos\theta\)。

### 2.3 多目标阵元数据模型

第 \(l\) 个快拍的阵元数据矩阵记为

\[
Y_l\in\mathbb C^{N_z\times N_\phi}.
\]

对 \(K\) 个目标：

\[
\boxed{
Y_l
=
\sum_{k=1}^{K}
s_{k,l}
\mathbf a_z(\theta_k)
\mathbf a_\phi^T(\phi_k,\theta_k)
+N_l.
}
\]

也可写为

\[
Y_l
=
A_z(\boldsymbol\theta)
\operatorname{diag}(\mathbf s_l)
A_\phi^T(\boldsymbol\phi,\boldsymbol\theta)
+N_l,
\]

其中

\[
A_z(\boldsymbol\theta)
=
[\mathbf a_z(\theta_1),\ldots,\mathbf a_z(\theta_K)].
\]

该矩阵形式直接对应“先沿垂直维形成俯仰波束，再沿环向维形成方位波束”的顺序处理。

---

## 3. 创新点 1：分组条件顺序波束域 DML

## 3.1 第一阶段：俯仰 DBF

设俯仰 DBF 权矩阵为

\[
V=[\mathbf v_1,\ldots,\mathbf v_{B_e}]
\in\mathbb C^{N_z\times B_e}.
\]

俯仰波束输出为

\[
Z_{e,l}=V^HY_l
\in\mathbb C^{B_e\times N_\phi}.
\]

若阵元噪声为空间白噪声，俯仰波束噪声协方差为

\[
C_e=V^HV.
\]

采用

\[
T_e=C_e^{-1/2}
\]

进行白化：

\[
\widetilde Z_{e,l}=T_eV^HY_l.
\]

将全部快拍和方位列拼接：

\[
\widetilde Z_e
=
[
\widetilde Z_{e,1},\ldots,\widetilde Z_{e,L}
]
\in\mathbb C^{B_e\times N_\phi L}.
\]

若存在 \(Q\) 个可由俯仰维区分的目标组，其代表俯仰角为

\[
\boldsymbol\eta=[\eta_1,\ldots,\eta_Q]^T,
\]

定义俯仰波束域流形

\[
G_e(\boldsymbol\eta)
=
T_eV^H
[
\mathbf a_z(\eta_1),\ldots,\mathbf a_z(\eta_Q)
].
\]

则俯仰阶段模型为

\[
\boxed{
\widetilde Z_e
=
G_e(\boldsymbol\eta)C_e^{(s)}
+\widetilde N_e.
}
\]

系数矩阵 \(C_e^{(s)}\) 吸收了方位流形、目标复幅度和快拍变化。这个模型不要求先知道方位角。

### 3.1.1 俯仰 DML 推导

在已白化噪声下，给定 \(\boldsymbol\eta\) 和系数矩阵 \(C\)，负对数似然与

\[
\|\widetilde Z_e-G_eC\|_F^2
\]

等价。固定 \(\boldsymbol\eta\) 时：

\[
\widehat C(\boldsymbol\eta)
=G_e^\dagger(\boldsymbol\eta)\widetilde Z_e.
\]

集中残差为

\[
RSS_e(\boldsymbol\eta)
=
\|\Pi_{G_e}^{\perp}\widetilde Z_e\|_F^2,
\]

其中

\[
\Pi_{G_e}^{\perp}=I-P_{G_e}.
\]

因此

\[
\widehat{\boldsymbol\eta}
=
\arg\min_{\boldsymbol\eta\in\Omega_e}
RSS_e(\boldsymbol\eta),
\]

等价于

\[
\boxed{
\widehat{\boldsymbol\eta}
=
\arg\max_{\boldsymbol\eta\in\Omega_e}
J_e(\boldsymbol\eta),
\qquad
J_e=\|Q_e^H\widetilde Z_e\|_F^2,
}
\]

其中 \(Q_e\) 是 \(G_e\) 有效列空间的正交基。

### 3.1.2 俯仰目标组的定义

若多个目标具有相同或非常接近的俯仰角，则俯仰阶段只能识别一个组。定义

\[
\mathcal G_q
=
\{k:\theta_k\text{ 属于第 }q\text{ 个可辨俯仰组}\},
\]

\[
K_q=|\mathcal G_q|,
\qquad
K=\sum_{q=1}^{Q}K_q.
\]

这自然覆盖：

- \(Q=2,K_1=K_2=1\)：两个目标俯仰可分；
- \(Q=1,K_1=2\)：同俯仰或俯仰不可分，但方位可能可分；
- \(Q=1,K_1>2\)：同一俯仰组内的有限多目标方位问题。

它替换原来离散 \(\Delta el\) 列表，不再假定真实分离只能落在人工给定的若干值上。

## 3.2 第二阶段：条件方位 DML

俯仰阶段得到

\[
\widehat G_e=G_e(\widehat{\boldsymbol\eta}).
\]

对应的系数估计为

\[
\widehat C_e^{(s)}
=
\widehat G_e^\dagger\widetilde Z_e.
\]

取第 \(q\) 行并重排为

\[
X_{\phi,q}
\in\mathbb C^{N_\phi\times L}.
\]

理想模型为

\[
X_{\phi,q}
=
A_{\phi,q}(\boldsymbol\phi_q\mid\widehat\eta_q)S_q+E_q,
\]

其中

\[
A_{\phi,q}
=
[
\mathbf a_\phi(\phi_{q,1},\widehat\eta_q),
\ldots,
\mathbf a_\phi(\phi_{q,K_q},\widehat\eta_q)
].
\]

设方位 DBF 权矩阵为

\[
U_q=[\mathbf u_{q,1},\ldots,\mathbf u_{q,B_a}]
\in\mathbb C^{N_\phi\times B_a}.
\]

白化矩阵为

\[
T_{a,q}=(U_q^HU_q)^{-1/2}.
\]

条件方位波束域数据和流形为

\[
\widetilde Z_{a,q}=T_{a,q}U_q^HX_{\phi,q},
\]

\[
G_{a,q}(\boldsymbol\phi_q\mid\widehat\eta_q)
=
T_{a,q}U_q^H
A_{\phi,q}(\boldsymbol\phi_q\mid\widehat\eta_q).
\]

方位 DML 为

\[
\boxed{
\widehat{\boldsymbol\phi}_q
=
\arg\max_{\boldsymbol\phi_q\in\Omega_{a,q}}
\left\|
Q_{a,q}^H
(\boldsymbol\phi_q\mid\widehat\eta_q)
\widetilde Z_{a,q}
\right\|_F^2.
}
\]

当 \(K_q=1\) 时是一维单目标估计；当 \(K_q=2\) 时是同俯仰组内的局部双源方位 DML。多源情况下可使用 AP 或 PR-DML 作为求解器/基线，而不把已有的多源降维搜索思想重新包装为创新。

## 3.3 第三阶段：完整顺序波束域局部联合修正

俯仰权 \(\mathbf v_b\) 和方位权 \(\mathbf u_{c|b}\) 构成顺序波束通道。对单目标：

\[
\boxed{
g_{b,c}(\phi,\theta)
=
\left[\mathbf v_b^H\mathbf a_z(\theta)\right]
\left[\mathbf u_{c|b}^H\mathbf a_\phi(\phi,\theta)\right].
}
\]

其等效阵元权向量为

\[
\mathbf w_{b,c}
=
\mathbf u_{c|b}\otimes\mathbf v_b,
\]

并满足

\[
g_{b,c}(\phi,\theta)
=
\mathbf w_{b,c}^H\mathbf a(\phi,\theta).
\]

将所有局部顺序波束通道堆叠为

\[
\mathbf g_{\rm seq}(\phi,\theta).
\]

对 \(K\) 个目标：

\[
G_{\rm seq}(\Theta)
=
[
\mathbf g_{\rm seq}(\phi_1,\theta_1),
\ldots,
\mathbf g_{\rm seq}(\phi_K,\theta_K)
].
\]

若等效波束矩阵为 \(W_{\rm seq}\)，一般噪声协方差为 \(R_n\)，则波束域噪声协方差为

\[
C_{\rm seq}=W_{\rm seq}^HR_nW_{\rm seq}.
\]

白化后：

\[
\widetilde Z_{\rm seq}=C_{\rm seq}^{-1/2}W_{\rm seq}^HY,
\]

\[
\widetilde G_{\rm seq}=C_{\rm seq}^{-1/2}W_{\rm seq}^HA(\Theta).
\]

联合 DML 评分为

\[
\boxed{
J_{\rm seq}(\Theta)
=
\|Q_{\rm seq}^H(\Theta)\widetilde Z_{\rm seq}\|_F^2.
}
\]

以分组条件估计作为初始化，使用逐目标、逐维坐标最大化：

\[
\phi_k^{(t+1)}
=
\arg\max_{\phi_k\in\Omega_{\phi,k}}
J_{\rm seq}
(\phi_1^{(t+1)},\ldots,\phi_k,\ldots;
\boldsymbol\theta^{(t)}),
\]

\[
\theta_k^{(t+1)}
=
\arg\max_{\theta_k\in\Omega_{\theta,k}}
J_{\rm seq}
(\boldsymbol\phi^{(t+1)};
\theta_1^{(t+1)},\ldots,\theta_k,\ldots).
\]

### 命题 1：坐标最大化的单调性

若每个一维子问题均返回当前坐标上的最大值，则

\[
J_{\rm seq}(\Theta^{(t+1)})
\ge
J_{\rm seq}(\Theta^{(t)}).
\]

又因为投影解释能量满足

\[
0\le J_{\rm seq}(\Theta)
\le
\|\widetilde Z_{\rm seq}\|_F^2,
\]

故评分序列单调有界并收敛。

该命题只保证目标函数值收敛，不保证一定达到全局最优。论文中必须保留多初值、AP/PR-DML、局部 full DML 对照来检查局部极值风险。

## 3.4 复杂度变化

对 \(K\) 个二维目标，直接网格搜索规模近似为

\[
O(N_\phi^K N_\theta^K).
\]

双目标时为

\[
O(N_\phi^2N_\theta^2).
\]

分组条件算法的主要代价为：

1. \(Q\) 个俯仰组估计；
2. 每个组的 \(K_q\) 目标方位估计；
3. \(T\) 轮局部逐目标坐标修正。

若各一维局部搜索分别有 \(N_\phi^{\rm loc}\) 和 \(N_\theta^{\rm loc}\) 个候选，则联合修正近似为

\[
O\left[
TK(N_\phi^{\rm loc}+N_\theta^{\rm loc})
\right].
\]

总复杂度不能只用候选数描述，还应同时报告：

- 流形构造次数；
- SVD/QR 次数及矩阵维数；
- 复乘加数量；
- 内存和缓存访问；
- MATLAB 运行时间；
- 若面向硬件，报告输出波束通道数和数据带宽。

---

## 4. 稳定 DML 数值实现

当前固定岭实现

\[
G(G^HG+10^{-10}I)^{-1}G^H
\]

不再作为新主线实现。建议统一采用 QR/SVD 子空间投影。

对候选流形：

\[
G=U\Sigma V^H.
\]

定义尺度相关秩阈值

\[
\tau_{\rm rank}
=
\max(B,K)\epsilon_{\rm mach}\sigma_1(G),
\]

保留满足

\[
\sigma_i(G)>\tau_{\rm rank}
\]

的左奇异向量，构成 \(U_r\)。则

\[
\boxed{
J(\Theta)=\|U_r^H\widetilde Z\|_F^2,
}
\]

\[
\boxed{
RSS(\Theta)=\|\widetilde Z\|_F^2-J(\Theta).
}
\]

需要输出：

- `rank_effective`；
- `sigma_min_retained`；
- `sigma_ratio`；
- `score`；
- `rss`；
- `is_rank_deficient`。

若必须使用岭正则，则应重新解释为具有源幅度先验的 MAP/Tikhonov 估计，并给出 \(\lambda\) 的统计来源，不能继续称为精确 DML 正交投影。

---

## 5. 创新点 2：近双目标切向信息理论

以下推导是候选核心定理，必须通过符号核查和数值渐近实验后再进入正式论文。

## 5.1 中心–差分表示

令单目标白化顺序波束域流形为

\[
\mathbf g(\boldsymbol\xi),
\qquad
\boldsymbol\xi=
\begin{bmatrix}
\phi\\
\theta
\end{bmatrix}.
\]

两个近目标写为

\[
\boldsymbol\xi_1
=
\mathbf c-\frac{\mathbf d}{2},
\qquad
\boldsymbol\xi_2
=
\mathbf c+\frac{\mathbf d}{2},
\]

其中

\[
\mathbf c=
\begin{bmatrix}
\phi_c\\
\theta_c
\end{bmatrix},
\qquad
\mathbf d=
\begin{bmatrix}
\Delta\phi\\
\Delta\theta
\end{bmatrix}.
\]

这只是精确重参数化，不声称自动降低连续自由度。目标标签交换可通过字典序约束消除，例如

\[
\Delta\phi>0,
\quad\text{或}\quad
\Delta\phi=0,\;\Delta\theta\ge0.
\]

## 5.2 流形 Jacobian 和切向信息矩阵

定义

\[
J_g(\mathbf c)
=
\frac{\partial\mathbf g(\mathbf c)}
{\partial\mathbf c^T}
=
\left[
\frac{\partial\mathbf g}{\partial\phi},
\frac{\partial\mathbf g}{\partial\theta}
\right].
\]

去除公共复幅度方向后的正交投影为

\[
\Pi_{\mathbf g}^{\perp}
=
I-
\frac{\mathbf g\mathbf g^H}{\mathbf g^H\mathbf g}.
\]

定义切向信息矩阵

\[
\boxed{
T_{\rm seq}(\mathbf c)
=
\operatorname{Re}
\left
\{
J_g^H(\mathbf c)
\Pi_{\mathbf g(\mathbf c)}^{\perp}
J_g(\mathbf c)
\right\}.
}
\]

它描述在消去未知公共幅度以后，顺序 beamspace 对方位/俯仰微小变化的有效敏感性。

## 5.3 近双目标第二奇异值定理

双目标流形矩阵为

\[
G_2(\mathbf c,\mathbf d)
=
\left[
\mathbf g(\mathbf c-\mathbf d/2),
\mathbf g(\mathbf c+\mathbf d/2)
\right].
\]

一阶 Taylor 展开：

\[
\mathbf g_-
=
\mathbf g_0-rac12J_g\mathbf d+O(\|\mathbf d\|^2),
\]

\[
\mathbf g_+
=
\mathbf g_0+rac12J_g\mathbf d+O(\|\mathbf d\|^2).
\]

对两列执行酉的和差变换：

\[
\mathbf h_1
=
\frac{\mathbf g_-+\mathbf g_+}{\sqrt2}
=
\sqrt2\mathbf g_0+O(\|\mathbf d\|^2),
\]

\[
\mathbf h_2
=
\frac{\mathbf g_+-\mathbf g_-}{\sqrt2}
=
\frac1{\sqrt2}J_g\mathbf d+O(\|\mathbf d\|^3).
\]

将 \(\mathbf h_2\) 对 \(\mathbf g_0\) 正交化，其主导能量为

\[
\left\|
\Pi_{\mathbf g_0}^{\perp}\mathbf h_2
\right\|_2^2
=
\frac12
\mathbf d^T
T_{\rm seq}(\mathbf c)
\mathbf d
+o(\|\mathbf d\|^2).
\]

因此候选定理为

\[
\boxed{
\sigma_2^2
\left(G_2(\mathbf c,\mathbf d)\right)
=
\frac12
\mathbf d^T
T_{\rm seq}(\mathbf c)
\mathbf d
+o(\|\mathbf d\|^2).
}
\]

该式表明，两个目标趋近时，决定流形秩分离能力的不是人工的 `cond_risk`，而是沿真实分离方向 \(\mathbf d\) 的切向信息

\[
\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d.
\]

## 5.4 与流形相关性和 Gram 条件数的关系

令

\[
\rho(\mathbf c,\mathbf d)
=
\frac{
\mathbf g_-^H\mathbf g_+
}{
\|\mathbf g_-\|_2\|\mathbf g_+\|_2
}.
\]

在 \(\mathbf d\to0\) 时：

\[
\boxed{
1-|\rho|^2
=
\frac{
\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d
}{
\|\mathbf g(\mathbf c)\|_2^2
}
+o(\|\mathbf d\|^2).
}
\]

双目标 Gram 矩阵的条件数近似为

\[
\boxed{
\kappa(G_2^HG_2)
\approx
\frac{
4\|\mathbf g(\mathbf c)\|_2^2
}{
\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d
}.
}
\]

所以原来分别计算的最大相关性、候选 Gram 条件数和第二奇异值，在近目标场景中是同一局部几何量的不同表达。新算法不再把它们作为多个独立经验项线性相加。

## 5.5 圆柱阵接收流形导数

以弧度为单位：

\[
\frac{\partial\mathbf u}{\partial\phi}
=
\begin{bmatrix}
-\cos\theta\sin\phi\\
\cos\theta\cos\phi\\
0
\end{bmatrix},
\]

\[
\frac{\partial\mathbf u}{\partial\theta}
=
\begin{bmatrix}
-\sin\theta\cos\phi\\
-\sin\theta\sin\phi\\
\cos\theta
\end{bmatrix}.
\]

对第 \(m\) 个阵元：

\[
\frac{\partial a_m}{\partial\phi}
=
\mathrm jk
\left(
\mathbf r_m^T\frac{\partial\mathbf u}{\partial\phi}
\right)a_m,
\]

\[
\frac{\partial a_m}{\partial\theta}
=
\mathrm jk
\left(
\mathbf r_m^T\frac{\partial\mathbf u}{\partial\theta}
\right)a_m.
\]

若角度接口使用度，则代码必须额外乘

\[
\frac{\pi}{180}.
\]

对固定线性波束变换 \(B\)：

\[
\mathbf g=B\mathbf a,
\]

\[
\frac{\partial\mathbf g}{\partial\phi}
=B\frac{\partial\mathbf a}{\partial\phi},
\qquad
\frac{\partial\mathbf g}{\partial\theta}
=B\frac{\partial\mathbf a}{\partial\theta}.
\]

如果白化矩阵随候选角度不变，上式可直接用于切向信息和 FIM。若波束矩阵或噪声协方差随角度更新，则必须把其导数纳入模型，不能忽略。

---

## 6. 精确白化下的波束子空间不变性

这一部分用于说明为什么 `cond(W^HW)` 不应继续作为统计性能目标。

设阵元噪声协方差为 \(R_n\succ0\)，波束矩阵为

\[
W\in\mathbb C^{M\times B}.
\]

波束域噪声协方差为

\[
C_W=W^HR_nW.
\]

白化波束流形为

\[
\mathbf g_W(\xi)
=C_W^{-1/2}W^H\mathbf a(\xi).
\]

定义

\[
U_W
=R_n^{1/2}W(W^HR_nW)^{-1/2}.
\]

则

\[
U_W^HU_W=I,
\]

且

\[
\mathbf g_W(\xi)
=U_W^HR_n^{-1/2}\mathbf a(\xi).
\]

因此白化 beamspace 的本质，是把噪声白化后的阵列流形投影到

\[
\mathcal S_W
=\operatorname{span}(R_n^{1/2}W).
\]

若

\[
W_2=W_1R,
\]

其中 \(R\) 可逆，则 \(U_{W_1}\) 和 \(U_{W_2}\) 是同一子空间的两组半酉基，因此存在酉矩阵 \(Q\) 使

\[
U_{W_2}=U_{W_1}Q.
\]

于是

\[
\mathbf g_{W_2}=Q^H\mathbf g_{W_1},
\]

而 DML 投影评分在酉变换下不变。

### 命题 2：精确白化下的基不变性

在完全相同的波束子空间、精确噪声白化和无限精度线性运算条件下，DML 统计性能只依赖波束子空间，不依赖该子空间采用的具体非正交基。

因此：

- `cond(W^H W)` 可以作为数值/定点实现诊断；
- 它不应继续和流形信息、估计风险并列构成统计目标；
- 如果量化发生在白化前并使条件数影响信息，则必须把量化噪声模型显式放入 \(R_n\) 或 Fisher 信息，而不是继续添加经验惩罚项。

---

## 7. 有效 Fisher 信息和最小局部波束集

## 7.1 DML 的有效 Fisher 信息

白化观测模型：

\[
\widetilde Z
=G(\boldsymbol\xi)S+\widetilde N,
\qquad
\widetilde N\sim\mathcal{CN}(0,\sigma^2I).
\]

角参数向量可写为

\[
\boldsymbol\xi
=[\phi_1,\theta_1,\ldots,\phi_K,\theta_K]^T.
\]

对第 \(i\) 个角参数定义

\[
D_i
=
\frac{\partial G}{\partial\xi_i}S.
\]

将未知确定性复包络 \(S\) 作为 nuisance parameter 消去后，有效 Fisher 信息矩阵为

\[
\boxed{
[F(\boldsymbol\xi)]_{ij}
=
\frac{2}{\sigma^2}
\operatorname{Re}
\operatorname{tr}
\left(
D_i^H
\Pi_G^{\perp}
D_j
\right).
}
\]

该式应分别在阵元域和顺序 beamspace 计算：

\[
F_{\rm elem}(\zeta),
\qquad
F_{\rm seq}(\mathcal I_e,\mathcal I_a;\zeta),
\]

其中 \(\zeta\) 表示场景状态，包括中心角、分离、SNR、功率比、源相关性、快拍数和常规测角偏差。

## 7.2 最坏信息保真率

只在阵元域本身可辨识的场景集合 \(\Xi_{\rm id}\) 上定义信息保真率：

\[
\boxed{
\eta(\mathcal I_e,\mathcal I_a)
=
\inf_{\zeta\in\Xi_{\rm id}}
\lambda_{\min}^{+}
\left[
F_{\rm elem}^{\dagger/2}(\zeta)
F_{\rm seq}(\mathcal I_e,\mathcal I_a;\zeta)
F_{\rm elem}^{\dagger/2}(\zeta)
\right].
}
\]

符号 \(\lambda_{\min}^{+}\) 表示只在阵元域可辨识子空间上取最小广义特征值。

解释：

\[
\eta=1
\]

表示顺序 beamspace 在最坏方向上保留了全部阵元域 Fisher 信息；

\[
\eta=0.8
\]

表示最坏方向上的 CRB 最多膨胀约

\[
\rho_{\rm CRB}=\frac1{\eta}=1.25.
\]

## 7.3 最小波束预算

从常规检测波束附近的实际俯仰和方位 DBF 波束中选取索引集合

\[
\mathcal I_e,
\qquad
\mathcal I_a.
\]

默认资源成本定义为顺序输出通道数：

\[
C_{\rm beam}
=|\mathcal I_e||\mathcal I_a|.
\]

若真实硬件的代价模型不同，可以替换成本函数，但不能改变信息约束。

优化问题为

\[
\boxed{
(\mathcal I_e^\star,\mathcal I_a^\star)
=
\arg\min_{\mathcal I_e,\mathcal I_a}
|\mathcal I_e||\mathcal I_a|
}
\]

满足

\[
\boxed{
\eta(\mathcal I_e,\mathcal I_a)
\ge
\eta_0
=
\frac1{\rho_{\rm CRB,max}}.
}
\]

这使波束数量由允许的理论性能损失决定，而不是由 B7、经验权重或同一验证集上的 sweep 决定。

## 7.4 求解策略

### 小候选池

对 EI 固定方位俯仰波束池或小型邻域，直接穷举所有组合，获得池内全局最优解。

### 大候选池

采用：

1. 规则相邻波束作为初始集合；
2. 按最坏 Fisher 信息增益加入波束；
3. 使用 add/drop 或 pair-swap 局部交换；
4. 与连续 SVD 子空间上界比较；
5. 报告最终集合相对上界和可枚举子问题最优值的差距。

除非能证明目标具有单调次模性，否则不能宣称普通贪心存在固定近似比。

---

## 8. 局部目标数和不可分辨判定

## 8.1 集中似然残差

对每个候选目标数 \(K\)：

\[
RSS_K
=
\min_{\Theta_K,S_K}
\|\widetilde Z-G_K(\Theta_K)S_K\|_F^2.
\]

未知噪声方差的集中对数似然为

\[
\ell_K^\star
=
-BL\log\left(
\frac{RSS_K}{BL}
\right)+C.
\]

相邻模型的统计量为

\[
\boxed{
\Lambda_{K,K+1}
=
2BL
\log
\frac{RSS_K}{RSS_{K+1}}.
}
\]

## 8.2 为什么不能直接使用普通卡方阈值

在 \(K\) 目标原假设下新增第 \(K+1\) 个目标时：

- 新目标幅度为零；
- 新目标角度在原假设下不可识别；
- 目标重合位于参数空间边界；
- 源交换造成标签对称。

因此普通 Wilks 定理的正则条件不成立，不能直接使用固定 \(\chi^2\) 阈值。

## 8.3 参数 bootstrap

对 \(K=1\) 与 \(K=2\) 判别：

1. 在实测样本上拟合 \(K=1\)，得到 \(\widehat\Theta_1,\widehat S_1,\widehat\sigma_1^2\)；
2. 在 \(K=1\) 拟合模型下生成 \(B_{\rm boot}\) 个 bootstrap 样本；
3. 对每个样本分别运行 K1 和 K2 搜索；
4. 计算 \(\Lambda_{1,2}^{(b)}\)；
5. 取经验 \(1-\alpha\) 分位数为门限 \(\gamma_{1,2}(\alpha)\)；
6. 当

\[
\Lambda_{1,2}>\gamma_{1,2}(\alpha)
\]

时，拒绝 K1。

这里

\[
\alpha
\]

具有明确含义：允许的单目标 false split 概率。

## 8.4 “存在双目标”不等于“两个角度可可靠分离”

令双目标分离向量为

\[
\mathbf d
=
\begin{bmatrix}
\phi_2-\phi_1\\
\theta_2-\theta_1
\end{bmatrix}.
\]

若角参数协方差近似为 \(F_2^\dagger\)，定义

\[
H_d=[-I_2\quad I_2],
\]

\[
C_d=H_dF_2^\dagger H_d^T.
\]

分离显著性为

\[
D_{\rm sep}^2
=
\widehat{\mathbf d}^T
C_d^\dagger
\widehat{\mathbf d}.
\]

可采用

\[
D_{\rm sep}^2
>
\chi^2_{2,1-\beta}
\]

作为渐近 resolved 条件，并用 bootstrap 置信区域进行最终校准。

推荐状态：

- `K1`：没有足够证据拒绝单目标；
- `K2_RESOLVED`：K2 证据成立，且两个角度的分离置信区域满足要求；
- `K2_UNRESOLVED`：K2 证据成立，但两个独立角度不可可靠报告；
- `OUT_OF_LOCAL_CELL`：最优解或置信区域触及/超出常规角分辨单元；
- `SEARCH_NOT_CONVERGED`：搜索未达到预设收敛或最优性要求；
- `MODEL_MISMATCH`：残差、噪声模型或阵列失配检验失败。

---

## 9. 双目标与多目标范围

### 9.1 双目标足以作为硕士论文主问题的条件

双目标是最小非平凡未分辨目标簇。只有在下面内容完整成立时，双目标主线才可形成有说服力的硕士论文创新：

1. 建立与实际顺序 DBF 一致的接收模型；
2. 提出分组条件 DML，而不是简单离散 pair2d；
3. 至少完成一个可验证的理论结果，如切向第二奇异值定理；
4. 完成 Fisher 信息波束预算；
5. 支持 K1/K2 判定和不可分辨输出；
6. 与直接 BML、AP/PR-DML、局部 full DML、gridless/SBL 和常规 DBF 公平比较；
7. 在独立 holdout、低 SNR、强相干、弱次目标和阵列失配下验证。

“只考虑两个目标”不是创新；上述模型、理论和算法组合才是创新主体。

### 9.2 推荐的多目标范围

论文完整理论和主实验：

\[
K\in\{1,2\}.
\]

有限扩展实验：

\[
K=3.
\]

建议三目标场景包括：

- 三个不同俯仰组；
- 两个同俯仰、一个不同俯仰；
- 三个近似同俯仰、方位可分；
- 一个弱目标；
- 两个强相干目标加一个独立目标。

推荐论文表述：

> 所提分组结构原则上可扩展至有限多目标。本文围绕最小未分辨目标簇 K=2 给出完整理论和统计验证，并通过 K=3 场景验证有限多目标扩展能力，不宣称已经解决任意目标数、任意相干结构和全空域多目标问题。

---

## 10. 需要删除、保留和重新定位的旧主张

| 旧内容 | 新定位 |
|---|---|
| 真实圆柱阵流形 | 正确建模基础，不单列创新 |
| 双程 `spatialPhaseFactor=2` | 改为接收单程 1，全部结果重跑 |
| controlled pair2d | 保留为旧 baseline；不再声称参数化自动降维 |
| common-el | 同俯仰简化 baseline |
| local full4D | 小窗口高精度参考，不是默认工程算法 |
| `greedy_combined_B7` | 由 Fisher 信息保真最小波束集替换 |
| fixed topK3 | 搜索工程 baseline |
| C05 | 从新主线删除，仅保留负面/历史 baseline |
| \(W^HW\) 白化 | 正确性机制 |
| fixed `1e-10` DML ridge | 改为 QR/SVD 有效秩投影 |
| canonical cache | 软件优化；按新相位和顺序流形重建 |
| 完整“后端”表述 | 改为常规顺序 DBF 后的局部未分辨目标簇超分辨模块 |

---

## 11. 建议的正式贡献写法

### 贡献 1

> 针对全息凝视雷达先俯仰、后方位的顺序数字波束形成链路，建立接收单程相位下的圆柱阵顺序波束域模型，提出俯仰目标组估计、条件方位多目标估计和局部联合修正相结合的分组条件 beamspace DML 方法，将局部多目标二维联合全局搜索转化为与工程数据流一致的分阶段低维优化。

### 贡献 2

> 推导顺序波束域中近双目标流形第二奇异值、归一化相关性和 Gram 条件数与局部切向信息矩阵之间的渐近关系，并构造阵元域—顺序波束域有效 Fisher 信息保真准则，据此选择满足规定 CRB 膨胀上限的最小局部俯仰和方位波束集。

### 支撑贡献

> 基于集中似然残差和参数 bootstrap 构造局部目标数判定与不可分辨状态输出，使算法能够区分单目标、可分辨双目标和统计不可分辨目标簇，并通过有限三目标场景验证分组结构的扩展能力。

---

## 12. 参考文献与公式映射

> 下表只列与新算法公式、理论推导、直接 baseline 和工程背景有实质关系的文献。引用前仍需逐篇阅读全文，不能仅依据题名或摘要宣称完全同式。

### 12.1 DML、集中似然、CRB 和多源搜索

| 编号 | 文献 | 链接 | 本文用途 |
|---|---|---|---|
| R01 | P. Stoica and A. Nehorai, “MUSIC, maximum likelihood, and Cramer-Rao bound,” 1989. | https://doi.org/10.1109/29.17564 | ML/CRB 理论基础 |
| R02 | P. Stoica and K. C. Sharman, “Maximum likelihood methods for direction-of-arrival estimation,” 1990. | https://doi.org/10.1109/29.57542 | DML/SML 集中似然 |
| R03 | P. Stoica and A. Nehorai, “MUSIC, maximum likelihood, and Cramer-Rao bound: further results and comparisons,” 1990. | https://doi.org/10.1109/29.61541 | ML 与 CRB 进一步比较 |
| R04 | I. Ziskind and M. Wax, “Maximum likelihood localization of multiple sources by alternating projection,” 1988. | https://doi.org/10.1109/29.7543 | 多源 AP、逐目标优化 baseline |
| R05 | M. Trinh-Hoang, M. Viberg, and M. Pesavento, “Partial Relaxation Approach: An Eigenvalue-Based DOA Estimator Framework,” 2017. | https://arxiv.org/abs/1711.01982 | PR-DML、多源多维搜索降为谱搜索 baseline |
| R06 | A. L. Swindlehurst and P. Stoica 等相关 deterministic CRB 推导，建议结合 Van Trees 教材逐式核对。 | 见 R38 | nuisance amplitude 下的有效 FIM |
| R07 | S. M. Kay / H. L. Van Trees 阵列估计基础。 | https://doi.org/10.1002/0471221104 | Fisher 信息、CRB 和阵列处理基础 |
| R08 | S. Athley, “Threshold region performance of maximum likelihood direction of arrival estimators,” 2005. | https://doi.org/10.1109/TSP.2005.843717 | 低 SNR 阈值区实验设计 |
| R09 | A. Vincent, O. Besson, and E. Chaumette, “Approximate maximum likelihood estimation of two closely spaced sources,” 2014. | https://doi.org/10.1016/j.sigpro.2013.10.017 | 近双源 ML 直接 baseline |

### 12.2 Beamspace ML 和低仰角/双目标直接工作

| 编号 | 文献 | 链接 | 本文用途 |
|---|---|---|---|
| R10 | M. D. Zoltowski and T.-S. Lee, “Maximum likelihood based sensor array signal processing in the beamspace domain for low angle radar tracking,” 1991. | https://doi.org/10.1109/78.80885 | 经典 beamspace ML |
| R11 | R. C. Davis and R. L. Fante, “A maximum-likelihood beamspace processor for improved search and track,” 2001. | https://doi.org/10.1109/8.933484 | BML 搜索/跟踪处理器 |
| R12 | J. Kim, H. Yang, and K. Kwak, “Low-angle tracking of two objects in a three-dimensional beamspace domain,” 2012. | https://doi.org/10.1049/IET-RSN.2010.0163 | 三维 beamspace 双目标直接近邻 |
| R13 | S. Chen et al., “A beamspace maximum likelihood algorithm for target height estimation for a bistatic MIMO radar,” 2022. | https://doi.org/10.1016/j.dsp.2021.103330 | 场景化 BML 直接近邻 |
| R14 | S. Chen et al., “Beamspace Maximum Likelihood Algorithm Based on Sum and Difference Beams for Elevation Estimation,” 2024. | https://doi.org/10.23919/JSEE.2024.000057 | 和差波束 BML baseline |
| R15 | Y. Tang et al., “Bistatic MIMO radar height estimation method based on adaptive beam-space RML data fusion,” 2024. | https://doi.org/10.1016/j.dsp.2023.104346 | 自适应 beamspace RML 近邻 |
| R16 | 刘旗等，“低仰角目标高精度波束空间 DOA 估计方法,” 2026. | https://doi.org/10.12000/JR25173 | 阵元/波束域 CRB 等价和 W 设计的强直接基线 |

### 12.3 波束子空间、流形保真和测量矩阵设计

| 编号 | 文献 | 链接 | 本文用途 |
|---|---|---|---|
| R17 | S. Anderson, “On optimal dimension reduction for sensor array signal processing,” 1993. | https://doi.org/10.1016/0165-1684(93)90150-9 | 任务相关阵列降维 |
| R18 | A. Hassanien et al., “Convex optimization based beam-space preprocessing with improved robustness against out-of-sector sources,” 2006. | https://doi.org/10.1109/TSP.2006.870564 | 扇区流形保持和优化式 beamspace |
| R19 | P. Hyberg, M. Jansson, and B. Ottersten, “Array interpolation and bias reduction,” 2004. | https://doi.org/10.1109/TSP.2004.834402 | 流形匹配误差和估计偏差 |
| R20 | F. Belloni and V. Koivunen, “Beamspace transform for UCA: error analysis and bias reduction,” 2006. | https://doi.org/10.1109/TSP.2006.877664 | 圆阵 beamspace 变换误差 |
| R21 | F. Belloni, A. Richter, and V. Koivunen, “DoA estimation via manifold separation for arbitrary array structures,” 2007. | https://doi.org/10.1109/TSP.2007.896115 | 任意阵列真实流形建模 |
| R22 | G. M. Kautz and M. D. Zoltowski, “Beamspace DOA estimation featuring multirate eigenvector processing,” 1996. | https://doi.org/10.1109/78.510623 | Beamspace 维数和条件性背景 |
| R23 | B. Kilic et al., “Adaptive Measurement Matrix Design in Direction of Arrival Estimation,” 2022. | https://doi.org/10.1109/TSP.2022.3209880 | DOA 测量矩阵、coherence/RIP 设计 |
| R24 | M. Ibrahim et al., “Design and analysis of compressive antenna arrays for direction of arrival estimation,” 2017. | https://doi.org/10.1016/j.sigpro.2017.03.013 | 通道、CRB 和压缩阵列设计 |
| R25 | S. Khabbazibasmenj et al., “Efficient transmit beamspace design for search-free based DOA estimation in MIMO radar,” 2014. | https://doi.org/10.1109/TSP.2014.2299513 | 面向 DOA 后端的 beamspace 设计 |
| R26 | A. Hassanien and S. Vorobyov, “Transmit energy focusing for DOA estimation in MIMO radar with colocated antennas,” 2011. | https://doi.org/10.1109/TSP.2011.2125960 | 角区任务相关波束设计背景 |

### 12.4 Gridless、稳健噪声和最优性评估

| 编号 | 文献 | 链接 | 本文用途 |
|---|---|---|---|
| R27 | J. Pote and B. D. Rao, “Maximum Likelihood-Based Gridless DoA Estimation Using Structured Covariance Matrix Recovery and SBL With Grid Refinement,” 2023. | https://doi.org/10.1109/TSP.2023.3254919 | 固定网格/离散分离列表的重要 baseline |
| R28 | Z. Liu and H. Zhao, “Real-valued sparse Bayesian learning algorithm for off-grid DOA estimation in the beamspace,” 2022. | https://doi.org/10.1016/j.dsp.2021.103322 | beamspace off-grid baseline |
| R29 | P. Gerstoft and Y. Park, “Atom-Constrained Maximum Likelihood Gridless DOA with Wirtinger Gradients,” 2025. | https://doi.org/10.1109/ICASSP49660.2025.10889232 | 连续参数 ML 近邻 |
| R30 | Zhou, Cao, and Zhang, “Gridless DOA estimation for arbitrary array geometries based on maximum likelihood,” 2026. | https://doi.org/10.1016/j.sigpro.2025.110415 | 任意阵列 gridless ML 强近邻 |
| R31 | M. Pesavento and A. Gershman, “Maximum-likelihood direction-of-arrival estimation in the presence of unknown nonuniform noise,” 2001. | https://doi.org/10.1109/78.928686 | 一般非均匀噪声 ML |
| R32 | M. Djeddou et al., “Maximum likelihood angle-frequency estimation in partially known correlated noise for low-elevation targets,” 2005. | https://doi.org/10.1109/TSP.2005.851194 | 相关噪声和低仰角 ML |
| R33 | A. Akdemir and C. Candan, “Maximum-likelihood direction of arrival estimation under intermittent jamming,” 2021. | https://doi.org/10.1016/j.dsp.2021.103028 | 干扰/模型失配下 ML |
| R34 | T. Liu et al., “Maximum A Posteriori Direction-of-Arrival Estimation via Mixed-Integer Semidefinite Programming,” 2023. | https://arxiv.org/abs/2311.03501 | branch-and-bound 与最优性评估研究范式 |

### 12.5 模型阶数、非正则检验和数值线性代数

| 编号 | 文献 | 链接 | 本文用途 |
|---|---|---|---|
| R35 | M. Wax and T. Kailath, “Detection of signals by information theoretic criteria,” 1985. | https://doi.org/10.1109/TASSP.1985.1164557 | AIC/MDL 模型阶数 baseline |
| R36 | S. G. Self and K.-Y. Liang, “Asymptotic properties of maximum likelihood estimators and likelihood ratio tests under nonstandard conditions,” 1987. | https://doi.org/10.1080/01621459.1987.10478472 | 边界/不可识别参数下普通 Wilks 失效背景 |
| R37 | P. C. Hansen, “The truncated SVD as a method for regularization,” 1987. | https://doi.org/10.1007/BF01937276 | 截断 SVD 和数值秩背景 |
| R38 | G. H. Golub and C. F. Van Loan, *Matrix Computations*, 4th ed., 2013. | https://www.press.jhu.edu/books/title/10678/matrix-computations | QR/SVD、子空间扰动和数值线性代数 |
| R39 | H. L. Van Trees, *Optimum Array Processing*, 2002. | https://doi.org/10.1002/0471221104 | 阵列处理、FIM 和 CRB 总体理论 |

### 12.6 全息凝视雷达工程背景

| 编号 | 文献 | 链接 | 本文用途 |
|---|---|---|---|
| R40 | 郭瑞等，“全息凝视雷达系统技术与发展应用综述,” 2023. | https://doi.org/10.12000/JR22153 | 系统定义和工程背景 |
| R41 | R. Guo, J. Zhang, and X. Chen, “Design and Implementation of a Holographic Staring Radar for UAVs and Birds Surveillance,” 2023. | https://doi.org/10.1109/RADAR54928.2023.10371201 | 实际系统实现背景 |
| R42 | G. Oswald and C. Baker, *Holographic Staring Radar*, 2021. | https://doi.org/10.1049/SBRA518E | 全息凝视雷达专著背景 |

---

## 13. 理论进入论文前的验证要求

以下任一项未完成时，不得把对应命题写成已证明的论文贡献：

1. 使用有限差分验证接收导向矢量解析导数；
2. 验证单程相位公式、回波、DBF 权和 cache 全链一致；
3. 在不同中心角和分离方向下验证
   \[
   \frac{2\sigma_2^2(G_2)}{\mathbf d^TT_{\rm seq}\mathbf d}
   \to1;
   \]
4. 验证相关性和 Gram 条件数渐近式；
5. 验证阵元域和顺序 beamspace FIM 的数值梯度一致性；
6. 验证 Fisher 信息保真率能预测实际 CRB/RMSE 膨胀；
7. 验证坐标最大化评分单调不减；
8. 在多初值条件下统计局部极值概率；
9. 用独立 K1 holdout 验证 bootstrap false split 控制；
10. 将正常集和病态压力集同时报告，不得只展示正面子集。

