# 面向圆柱阵的波束域最大似然测角与流形感知波束选择

## 摘要

针对圆柱阵近邻目标难以由常规波束扫描分辨、阵元域最大似然搜索计算量较大的问题，本文提出一种波束域最大似然测角与流形感知波束选择方法。该方法基于工作子阵的真实阵元坐标建立圆柱阵流形，将阵元域观测投影并白化到低维波束域，在目标方位已知且相同的局部双目标场景中采用集中似然完成俯仰角联合估计。为避免仅按波束覆盖范围选取变换矩阵，进一步构造由局部流形投影损失、候选流形最大相关性和格拉姆矩阵条件数共同组成的评分准则；本文对13波束小候选池精确枚举固定规模子集，大候选池可采用贪心近似。仿真结果表明，在常规波束扫描形成合并主峰时，所提方法仍能分辨同一主瓣内的两个目标；增加波束数可改善流形保持，但过多相关波束会降低数值稳定性，综合评分在中等波束数附近取得较优折中。本文结论限于固定方位、已知双目标数、单快拍和理想阵列模型下的仿真场景。

**关键词：** 圆柱阵；波束域；最大似然估计；DOA估计；波束选择

## 1 引言

圆柱阵兼具环向覆盖和垂直孔径，适用于雷达、电子侦察和通信感知中的二维测角。然而，当两个目标位于同一主瓣内时，常规波束扫描容易形成单个合并峰，分辨率受波束宽度和信噪比限制。阵元域最大似然估计能够直接利用阵列流形，但其搜索与投影计算随阵元数、目标数和角度网格迅速增长[1-4]。

波束域处理通过低维投影降低参数估计的输入维数，已用于最大似然、Root-MUSIC和ESPRIT等方法[5-8]。对于任意阵列和圆阵，投影后的流形保持误差、候选向量相关性及数值条件会直接影响估计性能[9-12]。现有方法通常关注波束域估计或变换设计中的单一指标，尚缺少面向圆柱阵局部最大似然搜索、同时兼顾流形保持、候选可分性和白化稳定性的紧凑选择准则。

本文围绕固定方位下的局部近邻双目标测角开展研究，主要贡献如下：

1. 基于圆柱阵真实阵元坐标建立工作子阵流形，在白化波束域中构造双目标集中似然估计，以较少波束保留同主瓣目标的可分辨信息。
2. 提出流形感知波束选择评分，将局部投影损失、最大候选相关性和条件数惩罚统一为可计算准则；对本文的小候选池精确枚举波束子集，并保留面向大候选池的贪心扩展接口。
3. 通过目标间隔、信噪比和波束数实验验证估计性能与评分行为，给出流形保持和数值稳定性之间的适用边界。

## 2 圆柱阵波束域最大似然模型

### 2.1 工作子阵与阵元域观测

设圆柱阵包含 \(N_{\psi}\) 个方位列和 \(N_z\) 个俯仰层，半径为 \(R_c\)，层间距为 \(d_z\)。第 \((n,m)\) 个阵元坐标为

$$
\psi_n=\psi_{\mathrm{ref}}+(n-1)\frac{2\pi}{N_{\psi}},\qquad
z_m=z_{\mathrm{ref}}+(m-1)d_z,\qquad
\mathbf r_{n,m}=
\begin{bmatrix}
R_c\cos\psi_n & R_c\sin\psi_n & z_m
\end{bmatrix}^{T}.
\tag{1}
$$

围绕方位中心 \(\phi_0\) 选取连续 \(Q\) 列和全部 \(N_z\) 层作为工作子阵，阵元数为 \(M=QN_z\)。图1给出了圆柱阵及工作阵元。

![图1 圆柱阵及工作阵元选择](figures/fig_cyl_array_working_elements_combined.png)

目标方向为 \(\boldsymbol\eta=(\phi,\theta)\)，其单位方向向量和工作子阵导向矢量分别为

$$
\mathbf u(\phi,\theta)=
\begin{bmatrix}
\cos\theta\cos\phi & \cos\theta\sin\phi & \sin\theta
\end{bmatrix}^{T},
\qquad
\mathbf a_{\mathrm{cyl}}(\phi,\theta)=
\left[
e^{j\frac{2\pi}{\lambda}\mathbf p_1^T\mathbf u},
\ldots,
e^{j\frac{2\pi}{\lambda}\mathbf p_M^T\mathbf u}
\right]^T .
\tag{2}
$$

对 \(K\) 个目标和 \(L\) 个快拍，阵元域模型为

$$
Y=A_{\mathrm{cyl}}(\Theta)S+N,\qquad
A_{\mathrm{cyl}}(\Theta)=
\left[
\mathbf a_{\mathrm{cyl}}(\boldsymbol\eta_1),\ldots,
\mathbf a_{\mathrm{cyl}}(\boldsymbol\eta_K)
\right],
\tag{3}
$$

其中 \(Y\in\mathbb C^{M\times L}\)，\(S\in\mathbb C^{K\times L}\)，且阵元噪声满足 \(\mathbf n_l\sim\mathcal{CN}(\mathbf0,\sigma^2I_M)\)。

### 2.2 波束域投影与白化

由 \(B\ll M\) 个局部波束组成变换矩阵 \(W=[\mathbf w_1,\ldots,\mathbf w_B]\)，其中

$$
\mathbf w_b=
\frac{\mathbf a_{\mathrm{cyl}}(\phi_0,\theta_b)}
{\|\mathbf a_{\mathrm{cyl}}(\phi_0,\theta_b)\|_2},
\qquad
Z=W^HY=G(\Theta)S+W^HN,
\qquad
G(\Theta)=W^HA_{\mathrm{cyl}}(\Theta).
\tag{4}
$$

当 \(W\) 的列向量非正交时，波束域噪声协方差为 \(\sigma^2W^HW\)。采用

$$
T=(W^HW)^{-1/2},\qquad
\bar Z=TW^HY,\qquad
\bar G(\Theta)=TW^HA_{\mathrm{cyl}}(\Theta)
\tag{5}
$$

进行白化，使等效噪声协方差为 \(\sigma^2I_B\)。下文仍以 \(Z\) 和 \(G\) 表示白化后的观测与流形。

### 2.3 局部双目标集中似然估计

给定候选方向集合 \(\Theta\)，未知复包络的最小二乘估计为 \(\widehat S(\Theta)=G^\dagger(\Theta)Z\)。消去 \(S\) 后，集中似然评分及角度估计为

$$
J(\Theta)=
\operatorname{tr}\!\left[
G(\Theta)G^\dagger(\Theta)ZZ^H
\right],
\qquad
\widehat\Theta=
\arg\max_{\Theta\in\Omega_{\mathrm{win}}^{(K)}}J(\Theta).
\tag{6}
$$

本文取 \(K=2\)，并限定两个目标具有相同方位 \(\phi_1=\phi_2=\phi_0\)。在俯仰网格 \(\mathcal G_\theta=\{\theta_i^{(g)}\}_{i=1}^{N_g}\) 上构造

$$
\Omega_{\mathrm{pair},\theta}=
\left\{
\Theta_{ij}=
\big((\phi_0,\theta_i^{(g)}),(\phi_0,\theta_j^{(g)})\big):
i\neq j
\right\},
\tag{7}
$$

并以式(6)遍历候选对。该局部参数化不覆盖全空域盲搜、目标数判定或不同方位双目标。

## 3 流形感知波束选择

### 3.1 三项诊断量

波束矩阵 \(W\) 决定降维后的信息保持、候选可分性和白化稳定性。设 \(\mathcal A_{\mathrm{local}}\) 为局部角域采样得到的圆柱阵流形，\(P_W=W(W^HW)^\dagger W^H\)。局部流形投影损失定义为

$$
\mathcal L_{\mathrm{proj}}(W)=
1-
\frac{\|P_W\mathcal A_{\mathrm{local}}\|_F^2}
{\|\mathcal A_{\mathrm{local}}\|_F^2}.
\tag{8}
$$

该指标越小，所选波束子空间保留的局部流形能量越多。对白化后的投影导向向量
\(\widetilde{\mathbf g}_W(\boldsymbol\eta)=T W^H\mathbf a_{\mathrm{cyl}}(\boldsymbol\eta)\)，定义局部候选的最大相关性为

$$
C_{\mathrm{corr}}(W)=
\max_{(\boldsymbol\eta_1,\boldsymbol\eta_2)\in\mathcal P_{\mathrm{local}}}
\frac{
\left|\widetilde{\mathbf g}_W^H(\boldsymbol\eta_1)
\widetilde{\mathbf g}_W(\boldsymbol\eta_2)\right|
}{
\|\widetilde{\mathbf g}_W(\boldsymbol\eta_1)\|_2
\|\widetilde{\mathbf g}_W(\boldsymbol\eta_2)\|_2
}.
\tag{9}
$$

较小的 \(C_{\mathrm{corr}}\) 表示候选流形更易区分。波束矩阵的数值稳定性由

$$
C_{\mathrm{cond}}(W)=
\log_{10}\!\left[\max\!\left(\kappa(W^HW),1\right)\right]
\tag{10}
$$

衡量。该值增大表示波束相关性或尺度不均衡增强，白化与投影计算对扰动更敏感。

### 3.2 综合评分与波束子集搜索

从候选池 \(W_{\mathrm{pool}}=[\mathbf w_1,\ldots,\mathbf w_{B_0}]\) 中选取 \(B\) 个波束。记候选池全部 \(B\) 波束子集为 \(\mathcal S_B(W_{\mathrm{pool}})\)，并计算

$$
\operatorname{score}(W)=
\alpha\mathcal L_{\mathrm{proj}}(W)
+\beta C_{\mathrm{corr}}(W)
+\gamma C_{\mathrm{cond}}(W),
\qquad
W_B^\star=\arg\min_{W\in\mathcal S_B(W_{\mathrm{pool}})}
\operatorname{score}(W).
\tag{11}
$$

其中 \(\alpha,\beta,\gamma\) 为权重。本文的13波束候选池允许以 \(\binom{B_0}{B}\) 次离线评分精确枚举子集；候选池较大时，可按相同评分逐步加入使当前评分最小的波束，但本文不将该贪心近似的性能作为实验结论。该评分是面向当前局部最大似然后端的工程化折中准则，不构成对任意阵列或场景的全局最优保证。本文固定方位，\(\mathcal A_{\mathrm{local}}\) 取俯仰切片，并在统计相关性时排除间隔小于 \(\Delta_{\theta,\min}\) 的候选对。

图2概括了波束投影、白化、候选构造和集中似然搜索流程。

![图2 波束域最大似然估计流程](figures/fig_beamspace_ml_flowchart_notation.png)

对单个 \(K\) 目标候选，评分复杂度为

$$
\mathcal O(BK^2+K^3+BKL).
\tag{12}
$$

当 \(K=2\) 时，遍历 \(N_g(N_g-1)\) 个有序俯仰候选对的复杂度为
\(\mathcal O(N_g(N_g-1)BL)\)。该结果描述在线最大似然搜索，不包含离线波束池构造和波束选择开销。

## 4 仿真实验

### 4.1 设置与评价指标

仿真采用圆柱阵工作子阵。两个目标方位均为 \(\phi_0\)，俯仰角关于 \(\theta_0\) 对称。主要参数见表1。

| 参数 | 取值 | 参数 | 取值 |
|---|---:|---|---:|
| 圆柱半径 \(R_c\) | \(0.4\,\mathrm m\) | 载频 | \(8\,\mathrm{GHz}\) |
| 方位阵元数/层数 | \(144/32\) | 层间距 | \(16\,\mathrm{mm}\) |
| 工作方位列数 \(Q\) | 49 | \((\phi_0,\theta_0)\) | \((8^\circ,10^\circ)\) |
| 3 dB俯仰波束宽度 | \(3.7681^\circ\) | 快拍数 \(L\) | 1 |
| 搜索网格数 \(N_g\) | 161 | 蒙特卡洛次数 \(D\) | 300 |

俯仰搜索范围为 \(\theta_0\pm0.8\mathrm{BW}_{3\mathrm{dB}}\)。采用俯仰均方根误差和分辨成功率评价性能；当两个估计均存在且配对误差不超过 \(0.1\mathrm{BW}_{3\mathrm{dB}}\) 时，判为分辨成功。

### 4.2 同主瓣近邻目标分辨

在 \(B=10\)、白化波束域输入SNR为 \(18\,\mathrm{dB}\) 时，将目标间隔由 \(0.1\mathrm{BW}_{3\mathrm{dB}}\) 增至 \(1.0\mathrm{BW}_{3\mathrm{dB}}\)。当间隔为 \(0.5\mathrm{BW}_{3\mathrm{dB}}\) 时，常规波束扫描产生单个合并峰，而集中似然在真实目标附近形成对称峰值，表明低维波束域仍保留了双目标子空间差异。

![图3 间隔为半波束宽度时的常规扫描与集中似然](code/results/fig_single_case_half_bw.png)

统计结果显示，随目标间隔增大，所提方法的RMSE整体下降且分辨成功率提高；常规波束扫描在同一主瓣内难以稳定输出两个目标。

![图4 不同目标间隔下的RMSE与分辨成功率](code/results/fig_rmse_resolution_vs_separation.png)

### 4.3 信噪比与波束数

将目标间隔固定为 \(0.8\mathrm{BW}_{3\mathrm{dB}}\)，SNR从 \(-10\) dB变化至 \(20\) dB，并比较 \(B\in\{2,4,6,8,10\}\)。当波束数较充足时，提高SNR可降低RMSE并提高分辨成功率；当 \(B\) 过小时，性能在较高SNR下仍受限，说明过度降维会丢失近邻目标的可分辨信息。

![图5 不同SNR和波束数下的估计性能](code/results/fig_snr_beam_comparison.png)

### 4.4 波束选择评分

在 \(\theta_0\) 附近构造13个候选俯仰波束，相邻中心间隔为 \(0.5\mathrm{BW}_{3\mathrm{dB}}\)。取 \(\alpha=0.48\)、\(\beta=0.48\)、\(\gamma=0.04\)，并对 \(B\in\{2,4,6,8,10\}\) 评估式(11)。随 \(B\) 增大，平均投影损失下降，但条件数惩罚上升；候选池优化后，最大相关性变化相对较小。

![图6 波束数与评分最优波束集合的诊断量](IEEE_ICSPS_6page/figures_en/fig_w_score_optimal_metrics_vs_B.png)

综合评分呈先下降后上升趋势，在 \(B=4\) 至 \(B=6\) 附近取得较低值。相应波束指向关于 \(\theta_0\) 近似对称，说明评分在保留局部流形与控制波束相关性之间形成了可解释折中。

![图7 评分最优波束集合的俯仰指向](IEEE_ICSPS_6page/figures_en/fig_w_score_optimal_beam_layout.png)

## 5 结论

本文提出了面向圆柱阵局部双目标场景的波束域最大似然测角与流形感知波束选择方法。该方法在白化低维波束域中执行集中似然搜索，并通过投影损失、候选相关性和条件数惩罚选择波束。仿真表明，所提方法能够在常规波束扫描形成合并峰时分辨同主瓣目标，且中等波束数可在流形保持和数值稳定性之间取得较好折中。现有结果仅针对固定同方位、已知 \(K=2\)、单快拍及理想阵列模型；不同方位、模型失配和实测数据仍需进一步验证。

## 参考文献

[1] Krim H, Viberg M. Two decades of array signal processing research: the parametric approach[J]. IEEE Signal Processing Magazine, 1996, 13(4): 67-94. DOI: 10.1109/79.526899.

[2] Pesavento M, Trinh-Hoang M P, Viberg M. Three more decades in array signal processing research: an optimization and structure exploitation perspective[J]. IEEE Signal Processing Magazine, 2023, 40(4): 92-106. DOI: 10.1109/MSP.2023.3255558.

[3] Van Trees H L. Optimum Array Processing: Part IV of Detection, Estimation, and Modulation Theory[M]. New York: Wiley, 2002.

[4] Stoica P, Sharman K C. Maximum likelihood methods for direction-of-arrival estimation[J]. IEEE Transactions on Acoustics, Speech, and Signal Processing, 1990, 38(7): 1132-1143. DOI: 10.1109/29.57542.

[5] Zoltowski M D, Lee T S. Maximum likelihood based sensor array signal processing in the beamspace domain for low angle radar tracking[J]. IEEE Transactions on Signal Processing, 1991, 39(3): 656-671. DOI: 10.1109/78.80885.

[6] Zoltowski M D, Kautz G M, Silverstein S D. Beamspace Root-MUSIC[J]. IEEE Transactions on Signal Processing, 1993, 41(1): 344-364. DOI: 10.1109/TSP.1993.193151.

[7] Xu G, Silverstein S D, Roy R H, Kailath T. Beamspace ESPRIT[J]. IEEE Transactions on Signal Processing, 1994, 42(2): 349-356. DOI: 10.1109/78.275607.

[8] Lee H B, Wengrovitz M S. Resolution threshold of beamspace MUSIC for two closely spaced emitters[J]. IEEE Transactions on Acoustics, Speech, and Signal Processing, 1990, 38(9): 1545-1559. DOI: 10.1109/29.60074.

[9] Belloni F, Richter A, Koivunen V. DoA estimation via manifold separation for arbitrary array structures[J]. IEEE Transactions on Signal Processing, 2007, 55(10): 4800-4810. DOI: 10.1109/TSP.2007.896115.

[10] Hassanien A, Elkader S A, Gershman A B, Wong K M. Convex optimization based beam-space preprocessing with improved robustness against out-of-sector sources[J]. IEEE Transactions on Signal Processing, 2006, 54(5): 1587-1595. DOI: 10.1109/TSP.2006.870564.

[11] Khabbazibasmenj A, Hassanien A, Vorobyov S A, Morency M W. Efficient transmit beamspace design for search-free based DOA estimation in MIMO radar[J]. IEEE Transactions on Signal Processing, 2014, 62(6): 1490-1500. DOI: 10.1109/TSP.2014.2299513.

[12] Belloni F, Koivunen V. Beamspace transform for UCA: error analysis and bias reduction[J]. IEEE Transactions on Signal Processing, 2006, 54(8): 3078-3089. DOI: 10.1109/TSP.2006.877664.

[13] Malioutov D, Cetin M, Willsky A S. A sparse signal reconstruction perspective for source localization with sensor arrays[J]. IEEE Transactions on Signal Processing, 2005, 53(8): 3010-3022. DOI: 10.1109/TSP.2005.850882.

[14] Kilic B, Gungor A, Kalfa M, Arikan O. Adaptive measurement matrix design in direction of arrival estimation[J]. IEEE Transactions on Signal Processing, 2022, 70: 4745-4760. DOI: 10.1109/TSP.2022.3209880.

[15] Ibrahim M, Ramireddy V, Lavrenko A, Koenig J, Roemer F, Landmann M, Grossmann M, Del Galdo G. Design and analysis of compressive antenna arrays for direction of arrival estimation[J]. Signal Processing, 2017, 138: 35-47. DOI: 10.1016/j.sigpro.2017.03.013.
