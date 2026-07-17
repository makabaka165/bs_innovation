# 圆柱阵顺序数字波束形成后局部未分辨目标簇测角：接收单程模型修订稿

> **版本：v0.19 Step12.0 scope revision，2026-07-17**  
> **活跃空间相位：`phase_factor=1`**  
> **证据状态：v0.18/Step11 的圆柱阵数值结果由 `phase_factor=2` 产生，已失效并冻结为 legacy，不构成本稿结论。**  
> **完成状态：本稿仅完成接收模型、解析导数、方向图和波束宽度验证；真实顺序 DBF、分组/条件 DML、联合修正、FIM 波束设计、K1/K2 bootstrap 与新性能实验均未完成。**

## 版本说明与术语账本

v0.19 是从物理模型重新起步的修订源稿，不继承 v0.18 的波束宽度、W/B 选择、搜索网格、成功率、RMSE、候选数或运行时间结论。旧正文和结果继续保存在 v0.18 与 Step11 目录中用于审计，但不得作为本稿的新证据。后续章节只有在相应阶段测试通过后才能由“计划”改写为“方法”或“结果”。

| 规范术语 | 本稿含义 | 不再使用的含混表述 |
|---|---|---|
| 阵元数字接收链路 | 射频接收、下变频、ADC、数字下变频和脉压，输出阵元复数据 | 用一个词同时指硬件、检测和测角 |
| 常规顺序 DBF 与检测处理 | 俯仰/方位数字波束形成、MTD、CFAR 和常规测角 | 人工提供局部窗口的未定义模块 |
| 局部未分辨目标簇超分辨测角 | 对同一距离–多普勒单元和局部角分辨单元进行 K1/K2 与精细二维角估计 | 无系统位置定义的精估计模块 |
| 常规测角置信域 | 由常规测角估计及其误差统计形成的局部角域 | 固定且来源不明的人工窗口 |
| 常规波束角分辨单元 | 由检测波束及相邻波束边界形成的局部角域 | 被误写成硬件直接输出的窗口 |
| 接收阵列单程空间相位 | `phase_factor=1` 的接收流形 | 将目标距离双程公共相位再次乘入空间流形 |
| legacy evidence | v0.18/Step11 的 factor=2 源码配置和结果 | 可直接迁移到 v0.19 的性能证据 |

# 中文摘要

圆柱阵同时具有环向孔径和垂直孔径，适合三维测角，但局部近邻目标的接收流形同时依赖方位、俯仰和阵元几何。本文修订稿面向常规顺序数字波束形成与检测之后的局部未分辨目标簇，重新定义接收阵列空间相位和后续研究边界。对于只建模接收阵列的远场窄带系统，目标距离引起的单站双程相位对接收阵元近似为公共项，应吸收到目标复包络；接收空间导向矢量因而固定采用 `phase_factor=1`。

当前阶段实现了不接受相位因子参数的单程圆柱阵导向函数及其相对于弧度方位角、俯仰角的解析导数。基于 10 GHz、192×32 圆柱阵及 65×32 工作子阵的确定性验证表明，导向函数与逐元素公式的最大误差为 0；9 个方位/俯仰中心上的方位和俯仰导数最大相对误差分别为 $1.020\times10^{-9}$ 和 $1.476\times10^{-9}$。在均匀加权单目标切面中，factor=1 的方位和俯仰 3 dB 波束宽度分别为 $2.0275^\circ$ 和 $2.8378^\circ$，约为隔离 factor=2 历史对照的 2 倍。

这些结果只验证接收模型实现和相位缩放关系，不验证局部目标簇超分辨性能。v0.18/Step11 的圆柱阵数值结果均按 factor=2 生成，不能用于本稿的新结论。真实先俯仰后方位数据流、俯仰组可辨识性、条件方位 DML、完整流形联合修正、相关波束 exact-subset FIM 设计和 K1/K2 校准仍需在后续独立阶段实现和否决式验证。

**关键词：** 圆柱阵；接收阵列；单程空间相位；顺序数字波束形成；局部未分辨目标；方向估计

# Abstract

Cylindrical arrays provide both circumferential and vertical apertures for three-dimensional direction finding, but their receive manifolds jointly depend on azimuth, elevation and element geometry. This revision defines the receive-array model and the scope of a future local super-resolution estimator operating after conventional sequential digital beamforming and detection. In a far-field narrowband receive-array model, the monostatic round-trip range phase is approximately common to all receive elements and is absorbed into the complex source envelope. The receive spatial manifold therefore uses `phase_factor=1`.

We implemented a six-input receive-only cylindrical steering function and analytic derivatives with respect to azimuth and elevation in radians. Deterministic validation for a 10 GHz, 192-by-32 cylindrical array with a 65-by-32 work subarray produced zero elementwise formula error. Across nine azimuth/elevation centers, the maximum relative derivative errors were $1.020\times10^{-9}$ for azimuth and $1.476\times10^{-9}$ for elevation. Under uniform weighting, the factor-1 azimuth and elevation 3 dB beamwidths were $2.0275^\circ$ and $2.8378^\circ$, approximately twice those of an isolated factor-2 legacy comparison.

These results validate only the receive model and its phase scaling. They do not establish local multi-target resolution performance. All cylindrical-array numerical evidence in v0.18/Step11 was generated with factor 2 and is excluded from the conclusions of this revision. The sequential data path, elevation-group identifiability, conditional-azimuth DML, full-manifold correction, exact-subset Fisher-information design under correlated beam noise, and K1/K2 calibration remain to be implemented and tested.

**Keywords:** cylindrical array; receive manifold; one-way spatial phase; sequential digital beamforming; locally unresolved targets; direction finding

# 第1章 系统层级、研究问题与证据状态

## 1.1 系统层级

本文采用四层系统划分，以避免把硬件接收、常规处理和局部超分辨混为同一接口。

| 层级 | 名称 | 输入与输出 |
|---|---|---|
| 1 | 阵元数字接收链路 | 从射频接收到脉压，输出阵元复数据 |
| 2 | 常规顺序 DBF 与检测处理 | 输出距离–多普勒检测、常规波束索引、粗角度及误差描述 |
| 3 | 局部未分辨目标簇超分辨测角 | 在局部角域中判定 K1/K2 状态并估计精细二维角度 |
| 4 | 航迹与资源管理 | 数据关联、跟踪、跨 CPI 处理和波束调度 |

候选算法位于第 3 层。其输入应来自第 2 层可审计的检测与测角量，而不是人工构造且没有物理来源的固定窗口。第 1 层只描述射频、ADC 和阵元数字数据形成，不负责给出双目标搜索域。

## 1.2 局部角域的物理来源

局部角域允许有两种来源。第一种是常规测角置信域。若常规角估计为 $\widehat{\boldsymbol\xi}_c$、估计协方差为 $C_c$，则可定义

\[
\Omega_\alpha=\left\{\boldsymbol\xi:
(\boldsymbol\xi-\widehat{\boldsymbol\xi}_c)^T C_c^{-1}
(\boldsymbol\xi-\widehat{\boldsymbol\xi}_c)
\le \chi^2_{2,1-\alpha}\right\}.
\]

第二种是常规波束角分辨单元。它可由检测波束的相邻交点、3 dB 边界或经独立数据估计的常规测角误差区域近似。两种定义都必须把覆盖率、边界命中和出域情形作为显式测试对象。

## 1.3 研究问题

当多个近邻目标落入同一距离–多普勒单元和常规角分辨单元时，单目标波束峰值或比幅测角可能表现为合并响应。候选研究问题是：在保留实际顺序 DBF 复数输出、相关噪声和完整圆柱阵接收流形的条件下，能否以受控计算预算完成 K1/K2 判定与局部二维精估计，并对不可分辨状态作出校准输出。

该问题不覆盖全空域盲搜、任意多目标、宽带近场、未知互耦、未经校准的阵列误差或完整跟踪闭环。主范围固定为 $K\in\{1,2\}$；$K=3$ 只允许在主链全部通过后作为可选有限扩展。

## 1.4 当前完成状态

当前只完成接收模型纠正和确定性数值验证。以下内容尚未形成可引用结果：

- 真实先俯仰、后方位的级联数据流；
- 俯仰组估计及 `rank(Ge)`/`rank(Ce)` 可辨识性；
- 条件方位 DML、完整流形联合修正和等预算 baseline；
- 固定白化流形的局部渐近式与零方向；
- 相关顺序波束的 exact-subset FIM 选择；
- K1/K2 bootstrap、false resolved 和 unresolved 校准；
- 新 factor=1 条件下的端到端性能、复杂度与硬件映射。

# 第2章 接收单程圆柱阵模型

## 2.1 圆柱阵几何

圆柱阵第 $m$ 个环向位置、第 $n$ 个垂直阵元的位置向量为

\[
\mathbf r_{m,n}=
\begin{bmatrix}
R\cos\psi_m & R\sin\psi_m & z_n
\end{bmatrix}^{T}.
\]

方位角 $\phi$ 和俯仰角 $\theta$ 的方向单位矢量定义为

\[
\mathbf u(\phi,\theta)=
\begin{bmatrix}
\cos\theta\cos\phi &
\cos\theta\sin\phi &
\sin\theta
\end{bmatrix}^{T},
\qquad k_0=\frac{2\pi}{\lambda}.
\]

外部配置和结果表中的角度使用 degree；解析导数、局部渐近式和 Fisher 信息内部统一使用 radian。

## 2.2 接收阵列空间相位

只考虑接收阵列时，单阵元导向项为

\[
\boxed{
a_{m,n}(\phi,\theta)
=\exp\left(jk_0\mathbf r_{m,n}^{T}\mathbf u(\phi,\theta)\right)
},
\qquad \eta_{\mathrm{phase}}=1.
\]

目标距离 $R_k$ 对应的单站双程传播相位为

\[
\exp\left(-j\frac{4\pi R_k}{\lambda}\right).
\]

在远场窄带接收模型中，该项对所有接收阵元近似相同，因此吸收到目标复包络 $s_{k,l}$ 中。本文不显式研究发射阵列流形，不能把该公共距离相位再次乘入接收空间导向矢量。

## 2.3 阵元域模型

令 $M=N_\phi N_z$，第 $l$ 个快拍满足

\[
\mathbf y_l=A(\Theta)\mathbf s_l+\mathbf n_l,
\qquad
A(\Theta)=[\mathbf a(\phi_1,\theta_1),\ldots,\mathbf a(\phi_K,\theta_K)].
\]

堆叠 $L$ 个快拍后有

\[
Y=A(\Theta)S+N.
\]

阵元白噪声只作为基础对照，$\mathbf n_l\sim\mathcal{CN}(0,\sigma^2I)$。一般相关噪声应写为 $\mathbf n_l\sim\mathcal{CN}(0,R_n)$，并在选取物理波束子集后重新构造对应协方差和白化器。

## 2.4 相对于弧度角的解析导数

令

\[
\frac{\partial\mathbf u}{\partial\phi}=
\begin{bmatrix}
-\cos\theta\sin\phi & \cos\theta\cos\phi & 0
\end{bmatrix}^{T},
\]

\[
\frac{\partial\mathbf u}{\partial\theta}=
\begin{bmatrix}
-\sin\theta\cos\phi & -\sin\theta\sin\phi & \cos\theta
\end{bmatrix}^{T}.
\]

则

\[
\frac{\partial a_{m,n}}{\partial\phi}
=jk_0\mathbf r_{m,n}^{T}\frac{\partial\mathbf u}{\partial\phi}a_{m,n},
\qquad
\frac{\partial a_{m,n}}{\partial\theta}
=jk_0\mathbf r_{m,n}^{T}\frac{\partial\mathbf u}{\partial\theta}a_{m,n}.
\]

两个导数均相对于 radian。实现接口中的输入仍为 degree，函数内部只在构造解析导数时转换为 radian。

## 2.5 条件可分解结构及边界

阵元内积可展开为

\[
\mathbf r_{m,n}^{T}\mathbf u(\phi,\theta)
=R\cos\theta\cos(\phi-\psi_m)+z_n\sin\theta.
\]

因此接收导向项可写成环向因子与垂直因子的乘积，但环向因子仍依赖俯仰角。该结构只说明后续条件处理的物理依据，不证明顺序 DBF 已实现，也不证明分组 DML 可辨识。

# 第3章 候选顺序测角路线与阶段边界

## 3.1 候选数据流

计划中的数据流为：阵元张量形成、俯仰 DBF、按俯仰组执行条件方位 DBF、局部 K1/K2 判定、完整接收流形联合修正。每个模块都必须有独立输入输出合同和否决门。当前仓库中的旧 `bf_elevation`、`bf_azimuth` 与直接二维波束函数没有形成上述级联，因此不能作为该路线已经实现的证据。

## 3.2 后续阶段的强制门

| 阶段 | 必须回答的问题 | 当前状态 |
|---|---|---|
| Step12.1 | 逐级输出是否与等效权严格一致，且保留正确噪声协方差 | 未开始 |
| 稳定 DML | SVD/QR 投影是否与参考最小二乘一致，病态候选是否可诊断 | 未开始 |
| 俯仰组 | `rank(Ge)`、`rank(Ce)` 和局部唯一性是否满足 | 未开始 |
| 条件方位与联合修正 | 是否优于等预算 baseline，坐标更新是否单调且收敛可控 | 未开始 |
| 局部渐近理论 | 固定白化条件、常数和零方向是否由公式及数值验证共同支持 | 未开始 |
| exact-subset FIM | 每个物理子集重构协方差后是否满足保真与 holdout 风险门 | 未开始 |
| K1/K2 | 独立 K1 holdout 是否控制 false resolved，K2 是否区分 resolved/unresolved | 未开始 |

任何一项失败都必须保留失败记录，不允许靠增加场景专用阈值、超大 topK 或人工分支掩盖。

# 第4章 Prior-art 边界与候选贡献合同

## 4.1 已有方法

集中 deterministic ML、beamspace ML、SVD/QR 正交投影、alternating projection、投影 Jacobian FIM、归一化 FIM、FIM 约束最少选择、bootstrap source enumeration 和 unresolved 判定均有直接或高度相似的既有工作[1–12]。这些对象不能单独声明为新算法。

Kim 等研究了三维 beamspace 中的双目标低角跟踪[5]；Pakrooh 等研究了压缩前后的归一化 Fisher 信息和 threshold effects[7,8]；Chepuri 与 Leus 已将最少选择与全参数域 FIM 约束结合[6]；刘旗等给出了低仰角 beamspace CRB 等价条件、波束形成器设计和 ML 验证[9]。这些工作是后续公平比较必须覆盖的直接边界。

## 4.2 仅保留的候选贡献

在没有后续证据前，只保留三项候选而非既成贡献：

1. 实际先俯仰后条件方位的数据接口、可辨识俯仰组、组内多方位 DML 和完整流形联合修正的系统组合；
2. 固定白化顺序二维流形上的显式近双目标局部渐近特化，包括零方向边界；
3. 相关物理顺序波束、exact-subset 重白化和乘积通道成本下的 FIM 最少选择特化。

“尚未发现完全相同工作”不构成新颖性证明。上述候选必须在阶段 9 与最近工作、等预算 baseline 和失败边界共同重写后才能形成论文贡献表述。

# 第5章 Step12.0 接收模型验证

## 5.1 实现与测试设置

活跃配置采用 10 GHz 载频、0.03 m 波长、192 个环向位置和 32 个垂直阵元，圆柱半径为 0.4 m，垂直间距为 17 mm。工作子阵包含 65 个环向位置和全部 32 个垂直阵元，共 2080 个阵元。单目标方向图中心为 $(az,el)=(8^\circ,10^\circ)$，使用均匀幅度权以隔离空间相位因子的影响。

新导向函数只有 `(x,y,z,az_deg,el_deg,lambda)` 六个输入，不接受 `PhaseFactor`。解析导数在 3 个方位中心 $[-40^\circ,8^\circ,55^\circ]$ 和 3 个俯仰中心 $[-5^\circ,20^\circ,50^\circ]$ 的笛卡尔组合上验证，共 9 个中心。中心有限差分步长为 $10^{-6}$ rad，验收阈值为相对误差不超过 $10^{-6}$。

factor=2 只在测试文件的局部历史对照公式中出现。它不调用新公共函数，不进入活跃配置，也不构成可复用模型。

## 5.2 公式与导数结果

| 指标 | 结果 | 验收 |
|---|---:|---:|
| 逐元素公式案例数 | 9 | 通过 |
| 最大逐元素绝对误差 | 0 | 通过 |
| 方位导数最大相对误差 | $1.0198\times10^{-9}$ | 通过 |
| 俯仰导数最大相对误差 | $1.4759\times10^{-9}$ | 通过 |

解析导数误差比预设 $10^{-6}$ 门限低约三个数量级。该结果支持公式与实现的一致性，不构成估计精度或统计有效性证据。

## 5.3 单目标方向图和 3 dB 波束宽度

![factor=1 与隔离 factor=2 历史对照的单目标方向图](../source/stepwise_signal_model/steps/step_12_0_receive_model_correction/results/single_target_receive_pattern.png)

| 模型角色 | 切面 | 3 dB 宽度 | 峰值偏移 |
|---|---|---:|---:|
| active factor=1 | 方位 | $2.027503^\circ$ | $0^\circ$ |
| active factor=1 | 俯仰 | $2.837839^\circ$ | $0^\circ$ |
| legacy factor=2 comparison | 方位 | $1.013714^\circ$ | $0^\circ$ |
| legacy factor=2 comparison | 俯仰 | $1.418815^\circ$ | $0^\circ$ |

factor1/factor2 的方位和俯仰宽度比分别为 2.000075 和 2.000147。结果与相位梯度减半后主瓣约加宽一倍的局部预期一致。该对比只用于说明为什么 v0.18 的波束宽度、网格和后续统计量必须重算。

## 5.4 可复现文件

阶段 1 的源代码、CSV、验证报告和方向图位于：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_0_receive_model_correction/
```

关键结果源为 `phase_model_keypoints.csv`、`old_vs_new_beamwidth.csv`、`derivative_validation.csv` 和 `receive_model_validation.md`。所有活跃结果 metadata 均为 `phase_factor=1`。

# 第6章 新证据计划与旧结果隔离

## 6.1 v0.18/Step11 结果边界

v0.18/Step11 的圆柱阵实验按 factor=2 生成。factor 从 2 改为 1 会改变空间相位梯度、波束宽度、候选网格、局部 Fisher 信息、W/B 选择和有限样本性能。因此旧图、旧表和旧 CSV 只能用于追溯原开发过程，不能在 v0.19 中作为性能、复杂度或创新性结论。

本稿不报告旧 success、RMSE、候选数、cache 或 runtime 数值。后续每个阶段必须写入新的 factor=1 metadata，并使用互斥的 design、validation 和 holdout 划分。

## 6.2 后续实验合同

| 证据层 | 最低要求 | 禁止替代物 |
|---|---|---|
| 顺序数据流 | direct/sequential/equivalent 无噪声等价和噪声协方差验证 | 旧直接二维波束演示 |
| 稳定评分 | SVD/QR、rank/status、病态和零矩阵测试 | 固定 `1e-10` 岭或 2×2 Gram 除法 |
| 可辨识性 | `rank(Ge)`、`rank(Ce)`、局部唯一性和失败状态 | 把环向列当独立时间快拍 |
| 算法性能 | 同输入、同通道、同计算预算 baseline | 不等预算或使用真值的比较 |
| 理论 | 固定白化解析式、有限差分和零方向验证 | 经验拟合常数 |
| FIM 设计 | 每个子集重构协方差、白化器和 FIM | 假设逐束 FIM 可加 |
| K1/K2 | 独立 K1 false-resolved 校准和 K2 resolved/unresolved 报告 | 在 holdout 调参 |

# 第7章 当前结论、限制与下一步

## 7.1 当前结论

本阶段建立并验证了 factor=1 的接收圆柱阵空间流形及其弧度解析导数。逐元素公式、9 中心有限差分、单目标峰值和 3 dB 波束宽度对比均通过预设门限。由此只能得出“接收模型实现正确且旧 factor=2 数值不可迁移”这一结论。

## 7.2 当前限制

当前没有真实顺序 DBF 输出，没有双目标 DML 性能，没有 FIM 波束选择，没有模型阶数判定，也没有 bootstrap 校准。方向图采用理想几何和均匀幅度权，没有覆盖互耦、增益相位误差、失效通道、一般有色噪声、宽带或近场条件。任何超分辨、复杂度或硬件收益表述都必须等待后续证据。

## 7.3 阶段门

下一步只能进入真实顺序 DBF 数据流验证。若逐级输出、等效矩阵或噪声协方差不能满足阶段 2 的严格等价门，则停止算法创新路线；不得提前进入分组 DML、FIM 或 K1/K2 实现。

# 参考文献

[1] Ziskind I, Wax M. Maximum likelihood localization of multiple sources by alternating projection. IEEE Transactions on Acoustics, Speech, and Signal Processing, 1988, 36(10): 1553–1560. DOI: 10.1109/29.7543.

[2] Stoica P, Nehorai A. MUSIC, maximum likelihood, and Cramer-Rao bound. IEEE Transactions on Acoustics, Speech, and Signal Processing, 1989, 37(5): 720–741. DOI: 10.1109/29.17564.

[3] Stoica P, Sharman K C. Maximum likelihood methods for direction-of-arrival estimation. IEEE Transactions on Acoustics, Speech, and Signal Processing, 1990, 38(7): 1132–1143. DOI: 10.1109/29.57542.

[4] Zoltowski M D, Lee T S. Maximum likelihood based sensor array signal processing in the beamspace domain for low angle radar tracking. IEEE Transactions on Signal Processing, 1991, 39(3): 656–671. DOI: 10.1109/78.80885.

[5] Kim, Yang and Kwak. Low-angle tracking of two objects in a three-dimensional beamspace domain. IET Radar, Sonar & Navigation, 2012. DOI: 10.1049/IET-RSN.2010.0163.

[6] Chepuri S P, Leus G. Sparsity-promoting sensor selection for non-linear measurement models. IEEE Transactions on Signal Processing, 2014. arXiv: 1310.5251.

[7] Pakrooh P, et al. Analysis of Fisher information and the Cramer-Rao bound for nonlinear parameter estimation after compressed sensing. IEEE Transactions on Signal Processing, 2015. DOI: 10.1109/TSP.2015.2464183.

[8] Pakrooh P, Scharf L L, Pezeshki A. Threshold effects in parameter estimation from compressed data. IEEE Transactions on Signal Processing, 2016. DOI: 10.1109/TSP.2016.2521617.

[9] 刘旗, 郭瑞, 王佳佳, 等. 低仰角目标高精度波束空间 DOA 估计方法. 雷达学报, 2026. DOI: 10.12000/JR25173.

[10] A source enumeration method based on subspace orthogonality and bootstrap technique. Signal Processing, 2013. DOI: 10.1016/j.sigpro.2012.11.007.

[11] Self S G, Liang K-Y. Asymptotic properties of maximum likelihood estimators and likelihood ratio tests under nonstandard conditions. Journal of the American Statistical Association, 1987. DOI: 10.1080/01621459.1987.10478472.

[12] Golub G H, Van Loan C F. Matrix Computations. 4th ed. Johns Hopkins University Press, 2013.
