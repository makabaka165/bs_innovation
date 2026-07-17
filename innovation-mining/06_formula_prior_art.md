# 新公式与理论推导的 prior-art 审查

> 审查对象：`11_sequential_beamspace_ml_innovations_theory.md` 与 `12_experiment_system_code_structure_roadmap.md`  
> 检索日期：2026-07-17  
> 检索性质：面向公式、变换和更新规则的定向检索，不是泛领域综述，也不是全球穷尽式专利检索  
> 结论标签仅使用：**已有完全相同方法**、**数学形式相似**、**算法机制相似**、**只有问题场景不同**、**暂未发现直接工作**

## 1. 结论先行

没有检索到一篇文献同时包含“圆柱阵顺序俯仰/方位 DBF、俯仰分组、条件方位 DML、完整顺序流形联合修正、近双目标切向渐近式、相对阵元域 FIM 最小波束集、bootstrap 阶数判定和 `K2_UNRESOLVED`”这一完整组合。

但这不等于各公式本身新颖。相反，当前理论中的大部分数学骨架已有明确前例：

1. 白化后的集中 DML 投影准则、未知确定性幅度消元后的投影 FIM，属于经典 ML/CRB 结果。
2. \(\operatorname{Re}\{J^H\Pi_g^\perp J\}\) 与经典有效 Fisher 信息只差幅度、快拍和噪声尺度，不能作为一个全新的信息矩阵定义来主张。
3. \(F_{\rm elem}^{-1/2}F_{\rm beam}F_{\rm elem}^{-1/2}\) 这一“压缩前后归一化 Fisher 信息矩阵”已由 Pakrooh 等直接研究。
4. “选最少测量项，并要求整个参数域上的 FIM 最小特征值达到阈值”已由 Chepuri 与 Leus 明确写成基数最小化问题。
5. 刘旗等 2026 年工作已经针对低仰角 beamspace ML 推导阵元域/波束域 CRB、分析等价条件并据此设计 beamformer。当前工作不能再把“用 CRB/FIM 保真指导 beamspace 设计”作为无前例的新思想。
6. 目前最可能保留独立理论价值的是：在固定白化顺序接收波束流形上，把第二奇异值、归一化相关性和 Gram 条件数显式统一到同一个二维分离方向二次型，并进一步把该局部量接到实际俯仰/方位规则波束子集选择中。对这一**完整显式渐近式和场景组合**，本轮暂未定位到完全同式论文；其基础几何和 FIM 形式已有明显先例。

## 2. 逐项公式判定

| ID | 编号 11 中的主张 | 判定 | 最近 prior art | 审查意见 |
|---|---|---|---|---|
| F01 | 圆柱阵接收流形 \(a(\phi,\theta)=a_\phi(\phi,\theta)\otimes a_z(\theta)\) | **已有完全相同方法** | 圆柱/圆阵二维 DOA、UCA manifold separation、1995 年 UCA 二维 ML | 这是阵列几何和向量化约定的直接结果；“方位项仍依赖俯仰”是正确边界，但不是新公式。 |
| F02 | 白化 beamspace 集中 DML：\(J=\lVert Q_G^H\widetilde Z\rVert_F^2\) | **已有完全相同方法** | Stoica–Sharman 1990；Zoltowski–Lee 1991 | 最小二乘消去确定性幅度后得到正交投影能量，是标准 DML。SVD/QR 只是稳定实现。 |
| F03 | 顺序波束等效权 \(w_{b,c}=u_{c\mid b}\otimes v_b\) | **已有完全相同方法** | Kronecker/可分阵列与级联线性波束形成 | 是 \(\operatorname{vec}\) 恒等式和级联线性变换，不应列为理论创新。 |
| F04 | 中心–差分参数化 \(\xi_{1,2}=c\mp d/2\) | **数学形式相似** | 近双源 ML、统计分辨极限与双点源分析 | 这是标准对称重参数化；价值只能来自后续针对顺序流形得到的新结论。 |
| F05 | 切向矩阵 \(T_{\rm seq}=\operatorname{Re}\{J_g^H\Pi_g^\perp J_g\}\) | **已有完全相同方法** | 经典 deterministic CRB；阵列流形微分几何 | 对未知公共复幅度的单目标模型，它正比于消去幅度后的有效 FIM。新名称不产生新数学对象。 |
| F06 | \(\sigma_2^2(G_2)=\tfrac12 d^TT_{\rm seq}d+o(\lVert d\rVert^2)\) | **数学形式相似** | 阵列流形局部几何、近源 CRB、统计角分辨极限 | 和差酉变换加一阶 Taylor 可直接推出。本轮未找到在“白化顺序 beamspace 二维流形”下完全同式的论文，但底层局部几何不是空白。 |
| F07 | \(1-\lvert\rho\rvert^2\) 与 \(d^TTd\) 的渐近关系 | **数学形式相似** | 归一化 steering-vector 距离、mutual coherence、流形度量 | 这是归一化复向量的局部投影度量；不能把 correlation 与 FIM 的联系宣称为首次发现。 |
| F08 | \(\kappa(G_2^HG_2)\approx4\lVert g\rVert^2/(d^TTd)\) | **数学形式相似** | 两列 Gram 矩阵特征值、近源条件性分析 | 对近等范数两列，\(\kappa=(1+\lvert\rho\rvert)/(1-\lvert\rho\rvert)\)，再代入 F07 即得。可能的新意只在顺序流形的显式场景化。 |
| F09 | 精确白化下，同一波束子空间的可逆换基不改变 DML | **已有完全相同方法** | 白化、半酉基和投影统计量不变性 | 是线性代数不变性。可用于否决 `cond(W^HW)` 作为统计目标，但不宜写成新估计理论。 |
| F10 | nuisance 幅度消元后的有效 FIM：\([F]_{ij}=2\sigma^{-2}\operatorname{Re}\operatorname{tr}(D_i^H\Pi_G^\perp D_j)\) | **已有完全相同方法** | Stoica–Nehorai 1989/1990；Van Trees | 这是 deterministic signal model 的经典 CRB/FIM 公式。 |
| F11 | 归一化保真矩阵 \(F_{\rm elem}^{\dagger/2}F_{\rm seq}F_{\rm elem}^{\dagger/2}\) | **已有完全相同方法** | Pakrooh et al. 2015, arXiv:1504.01081 | 其论文明确研究 \(J^{-1/2}\widehat J J^{-H/2}\)；当前的伪逆和可辨识子空间限制是病态场景扩展，不改变核心归一化。 |
| F12 | 最坏方向保真率 \(\inf_\zeta\lambda_{\min}^+(\cdot)\) | **数学形式相似** | E-optimal design；Chepuri–Leus 的全参数域最小特征值约束 | “所有场景、所有方向上 FIM 不低于阈值”已有明确 LMI/最优设计前例；相对 \(F_{\rm elem}\) 的度量和双目标场景集是差异。 |
| F13 | 最小波束预算：最小化 \(\lvert I_e\rvert\lvert I_a\rvert\)，约束 \(\eta\ge\eta_0\) | **数学形式相似** | Chepuri–Leus 2014；刘旗等 2026 | 最少选择项加 FIM/CRB 约束并非新骨架；实际顺序波束库、乘积通道成本与近双目标 holdout 是场景化贡献。 |
| F14 | parametric-bootstrap 嵌套 LRT 判定 \(K=1/2\) | **算法机制相似** | bootstrap source enumeration；非正则 LRT 文献 | 阶数检验中 bootstrap 是已有解决路径。当前差异是把 DML、近重合角和独立 K1 holdout 接起来。 |
| F15 | 检出 K2 但信息不足时输出 `K2_UNRESOLVED` | **算法机制相似** | 统计角分辨极限、GLRT/Rao resolution tests、拒判机制 | “存在两个源”与“两个参数可分辨”在已有分辨极限研究中已明确区分；本轮未发现完全相同状态机名称。 |
| F16 | F01–F15 在顺序圆柱阵接收 DBF 上的完整组合 | **暂未发现直接工作** | Kim 2012；刘旗等 2026；Pakrooh 2015/2016；Chepuri–Leus | 这是本轮唯一可暂时保留的整体判断；“未发现”受数据库限流和部分全文不可访问约束，不是新颖性的证明。 |

## 3. 三个最关键的等价关系

### 3.1 `T_seq` 本质上是单目标有效 FIM 的几何部分

对单目标白化模型

\[
z=g(\xi)s+n,
\qquad n\sim\mathcal{CN}(0,\sigma^2I),
\]

消去未知复幅度 \(s\) 后，角参数的有效 FIM 为

\[
F_\xi
=
\frac{2|s|^2}{\sigma^2}
\operatorname{Re}
\left\{
J_g^H\Pi_g^\perp J_g
\right\}.
\]

因此

\[
F_\xi=\frac{2|s|^2}{\sigma^2}T_{\rm seq}.
\]

结论：`T_seq` 可以作为顺序 beamspace 的局部几何量使用，但论文应写成“将经典有效 FIM 的投影 Jacobian 结构用于近双目标顺序流形分析”，不能写成“提出新的切向信息矩阵”。

### 3.2 归一化 FIM 不是新形式

Pakrooh 等对压缩前 FIM \(J\) 和压缩后 FIM \(\widehat J\) 定义

\[
W=J^{-1/2}\widehat J J^{-H/2},
\]

并分析该矩阵及 CRB 膨胀的分布。编号 11 的

\[
F_{\rm elem}^{\dagger/2}
F_{\rm seq}
F_{\rm elem}^{\dagger/2}
\]

与此在可辨识子空间上是同一归一化。当前工作的可保留差异是：

- 压缩矩阵不是随机高斯，而是实际规则顺序 DBF 通道子集；
- 使用最坏广义特征值，而不是随机压缩下的分布；
- 场景参数包含近双目标分离、功率比、相干性和常规测角偏差；
- 成本是俯仰/方位波束笛卡尔积产生的输出通道数。

这些差异支持“面向本系统的确定性鲁棒设计”，不支持“首次提出 FIM 归一化保真率”。

### 3.3 最小预算加最小特征值约束已有直接数学前例

Chepuri 与 Leus 的核心问题可写为

\[
\min_{w\in\{0,1\}^M}\|w\|_0
\]

满足

\[
\sum_{m=1}^{M}w_mF_m(\theta)
-\lambda_{\rm eig}I
\succeq0,
\qquad\forall\theta\in\mathcal U.
\]

编号 11 的相对保真约束在共同可辨识子空间上等价于

\[
F_{\rm seq}(I_e,I_a;\zeta)
\succeq
\eta_0F_{\rm elem}(\zeta),
\qquad\forall\zeta\in\Xi_{\rm id}.
\]

两者的共同骨架都是：最小选择成本、整个参数域约束、最坏特征方向、FIM/CRB 性能保证。区别是参考矩阵、候选项结构和应用场景。因此 F13 应判为“数学形式相似”，而不是全新优化问题。

还必须保留一个不能省略的技术差异：Chepuri–Leus 的基本推导假设候选观测独立，使选中集合的 FIM 可写成固定单项贡献之和。相邻 DBF 波束的噪声通常相关；对索引集合 \(I\)，当前 FIM 含有

\[
D_I^H C_I^{-1}D_I,
\]

而 \(C_I^{-1}\) 会随子集改变。因此不能未经证明把每束 FIM 当作固定可加项，也不能原样套用其 LMI/SDP。可行路线包括：在完整候选池上先构造固定白化坐标并明确“选坐标”是否仍对应实际输出成本，或直接在相关观测模型下处理子集相关的 Schur complement/矩阵逆。这个差异影响求解器，不恢复“最小选择 + FIM 约束”目标骨架的新颖性。

## 4. 近双目标渐近式的 prior-art 边界

### 4.1 关键变换已有基础

使用

\[
g_\pm=g(c\pm d/2),
\qquad
h_1=(g_-+g_+)/\sqrt2,
\qquad
h_2=(g_+-g_-)/\sqrt2
\]

是对称 Taylor 展开和两列矩阵的酉和差变换。近双源 ML、点源统计分辨极限以及阵列流形微分几何都使用相同的局部化思想。其本身不能作为新变换。

### 4.2 本轮未找到的精确对象

本轮没有定位到一篇可核验文献同时写出以下三式，并把它们应用到“精确白化后的顺序俯仰/方位接收 DBF 二维流形”：

\[
\sigma_2^2(G_2)
=\frac12d^TT_{\rm seq}d+o(\|d\|^2),
\]

\[
1-|\rho|^2
=\frac{d^TT_{\rm seq}d}{\|g(c)\|^2}
+o(\|d\|^2),
\]

\[
\kappa(G_2^HG_2)
\sim
\frac{4\|g(c)\|^2}{d^TT_{\rm seq}d}.
\]

因此可以把“对当前顺序流形给出三者的统一显式渐近式”保留为候选理论贡献，但应降格为**基于经典投影 FIM/流形几何的场景化推论**，直到完成：

1. 对近源 CRB、阵列流形微分几何和统计分辨极限论文的全文逐式比对；
2. 符号推导和常数因子检查；
3. \(d\) 落在 \(T_{\rm seq}\) 零方向时的高阶项分析；
4. 不等范数、角度相关白化、幅度不等和强相干时的适用条件说明。

## 5. 已有失败机制对理论主张的约束

### 5.1 FIM/CRB 保真不等于有限样本可靠

Pakrooh、Scharf 与 Pezeshki 2016 研究了压缩数据下的 threshold effect：在低 SNR、少快拍或强近源情况下，ML/子空间方法会因 signal/noise subspace swap 突然偏离 CRB；其双近源 DOA 例子显示压缩会提高 threshold SNR。

因此 F13 不能只用高 SNR FIM 保真作为通过标准。至少还要加入：

- subspace-swap 或错误局部峰概率；
- 低 SNR/少快拍的 threshold SNR；
- `resolved` 条件下和无条件的两套误差；
- 相同 \(\eta\) 但不同有限样本失败率的反例。

### 5.2 FIM 奇异与模型阶数检验非正则

在 \(K=1\) 原假设下，新增源的角度在幅度为零时不可识别；当两源重合时，分离参数也处于奇异点。普通 Wilks 卡方近似没有自动成立的条件。Self–Liang 类非正则 LRT 理论支持“不能直接用普通卡方”，但并不自动证明任何一个 bootstrap 实现有效。

需要分别验证：

- K1 独立 holdout 的 false split 上置信界；
- 极近 K2、弱次目标和强相干条件下 bootstrap 分布的稳定性；
- 仿真模型失配时 parametric bootstrap 的校准偏差；
- `K2_UNRESOLVED` 与 `K1` 的混淆率，而不只报告 resolved 子集 RMSE。

## 6. 公式层面的建议贡献写法

可以保留：

> 针对固定、精确白化的顺序接收 DBF 流形，推导近双目标第二奇异值、归一化流形相关性和 Gram 条件数关于二维分离方向的共同局部二次型，并将该显式关系用于实际规则波束子集的场景化评估。

需要改写：

> 在已有压缩前后归一化 FIM 和 FIM 约束传感器选择框架基础上，构造相对于阵元域的最坏信息保真约束，并针对俯仰/方位顺序规则波束库及其乘积通道成本求取最小局部波束集。

不应保留：

- “首次提出投影 Jacobian 切向信息矩阵”；
- “首次发现白化 beamspace 只依赖子空间”；
- “首次用 Fisher 信息或 CRB 设计 beamspace”；
- “首次提出最小测量数加 FIM 最小特征值约束”；
- “中心–差分参数化本身降低了自由度”；
- “bootstrap 或 unresolved 输出本身构成新的统计理论”。

## 7. 关键文献

| 编号 | 文献 | 对本审查的直接证据 |
|---|---|---|
| P01 | P. Stoica and A. Nehorai, “MUSIC, maximum likelihood, and Cramer-Rao bound,” 1989. [DOI](https://doi.org/10.1109/29.17564) | 经典 ML/CRB 与投影导数结构。 |
| P02 | P. Stoica and K. C. Sharman, “Maximum likelihood methods for direction-of-arrival estimation,” 1990. [DOI](https://doi.org/10.1109/29.57542) | 集中 DML 投影准则。 |
| P03 | M. D. Zoltowski and T.-S. Lee, “Maximum likelihood based sensor array signal processing in the beamspace domain for low angle radar tracking,” 1991. [DOI](https://doi.org/10.1109/78.80885) | 经典 beamspace ML。 |
| P04 | “MUSIC and maximum likelihood techniques on two-dimensional DOA estimation with uniform circular array,” 1995. [DOI](https://doi.org/10.1049/ip-rsn:19951756) | 圆阵二维 ML 直接背景。 |
| P05 | A. Vincent, O. Besson, and E. Chaumette, “Approximate maximum likelihood estimation of two closely spaced sources,” 2014. [DOI](https://doi.org/10.1016/j.sigpro.2013.10.017) | 近双源 ML 和局部参数化强近邻。 |
| P06 | “Differential Geometry of Array Manifold Surfaces,” 2004. [DOI](https://doi.org/10.1142/9781860946028_0003) | 阵列流形局部度量、切向和分辨能力背景。 |
| P07 | “Statistical Angular Resolution Limit for Point Sources,” 2007. [DOI](https://doi.org/10.1109/TSP.2007.898789) | 两点源统计分辨极限。 |
| P08 | S. P. Chepuri and G. Leus, “Sparsity-Promoting Sensor Selection for Non-linear Measurement Models,” 2014. [arXiv](https://arxiv.org/abs/1310.5251) | 最少传感器、全参数域 FIM 最小特征值约束、SDP/次梯度求解。 |
| P09 | P. Pakrooh et al., “Analysis of Fisher Information and the Cramer-Rao Bound for Nonlinear Parameter Estimation after Compressed Sensing,” 2015. [DOI](https://doi.org/10.1109/TSP.2015.2464183), [arXiv](https://arxiv.org/abs/1504.01081) | 与 F11 同骨架的归一化 FIM；压缩比与 CRB 损失。 |
| P10 | P. Pakrooh, L. L. Scharf, and A. Pezeshki, “Threshold Effects in Parameter Estimation from Compressed Data,” 2016. [DOI](https://doi.org/10.1109/TSP.2016.2521617), [arXiv](https://arxiv.org/abs/1505.07431) | 压缩、近双源 ML、subspace swap 和 threshold SNR。 |
| P11 | S. Anderson, “On optimal dimension reduction for sensor array signal processing,” 1993. [DOI](https://doi.org/10.1016/0165-1684(93)90150-9) | 任务相关阵列降维。 |
| P12 | B. Kilic et al., “Adaptive Measurement Matrix Design in Direction of Arrival Estimation,” 2022. [DOI](https://doi.org/10.1109/TSP.2022.3209880) | DOA 测量矩阵和有效字典设计。 |
| P13 | 刘旗、郭瑞、王佳佳等，“低仰角目标高精度波束空间 DOA 估计方法,” 2026. [DOI](https://doi.org/10.12000/JR25173) | 阵元/波束域 CRB、等价条件、beamformer 设计和 ML；当前 FIM 波束设计的强直接近邻。 |
| P14 | “A source enumeration method based on subspace orthogonality and bootstrap technique,” 2013. [DOI](https://doi.org/10.1016/j.sigpro.2012.11.007) | 阵列 source enumeration 中使用 bootstrap。 |
| P15 | S. G. Self and K.-Y. Liang, “Asymptotic properties of maximum likelihood estimators and likelihood ratio tests under nonstandard conditions,” 1987. [DOI](https://doi.org/10.1080/01621459.1987.10478472) | 边界/不可识别参数下普通 LRT 极限失效背景。 |
| P16 | “Angular Statistical Resolution Limit of Two Closely-Spaced Point Targets: A GLRT-Based Study,” 2018. [DOI](https://doi.org/10.1109/ACCESS.2018.2882889) | 以 GLRT 区分双目标检出与统计可分辨性。 |

## 8. 检索边界

- Crossref 返回的是题名/DOI 元数据和相关性排序；对若干 IEEE、IET、Elsevier 论文，本轮只能核验元数据或摘要，不能声称已逐式排除其全文中的所有相同公式。
- Chepuri–Leus、Pakrooh 2015 和 Pakrooh 2016 已通过公开 arXiv 全文核验关键公式和算法，不只依据摘要。
- 刘旗等 2026 已通过期刊文章页核验英文摘要、DOI、卷页和“阵元/波束 CRB 等价条件—beamformer 设计—ML”的方法链；Crossref 对该 DOI 返回 404，故采用出版者元数据。
- OpenAlex 在一次完整尝试和一次重试中均返回 429；Semantic Scholar 返回 429。该失败已在 `06_closest_work_matrix.md` 的 provenance 中记录，不能解释成数据库无相关论文。
- “暂未发现直接工作”只适用于本次有界检索，不能替代正式投稿前的 IEEE Xplore/Scopus/Web of Science/Google Scholar 全文与 cited-by 复核，也不覆盖专利。
