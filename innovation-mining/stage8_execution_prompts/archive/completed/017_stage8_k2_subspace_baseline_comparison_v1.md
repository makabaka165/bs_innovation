# Stage8-K2-SB1：Tangent 与 FBSS-MUSIC、Root-MUSIC、ESPRIT 及既有 CML 的同条件比较（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、Git 和 GitHub 推送的执行 AI。
>
> 本协议只增加经典/外部基线比较，不修改 `TANGENT_PROFILE_SAFE`、Step12.7、
> Core-Lite/Core-Plus、既有 Full4D CML/MUSIC 工具或 `31_*–34_*` 证据。
>
> 本协议遵循当前长期分支规则：
>
> ```text
> experiment/stage8-k2-tangent
> → work/stage8-k2-subspace-baselines-v1
> → 实现、验证和运行
> → 若实验完整有效，则在本授权下以 git merge --ff-only
>   快进回 experiment/stage8-k2-tangent
> ```
>
> 本协议是用户对本次 work 分支创建、实验执行和成功后 fast-forward 集成的
> 独立明确授权。
>
> 协议：
>
> ```text
> STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_AND_FF_INTEGRATION_V1
> ```

---

## 0. 当前分支定位

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

长期 Tangent 分支：

```text
experiment/stage8-k2-tangent
```

预期当前 HEAD：

```text
8e591779095e94333ed804351be1d35340d974ea
docs(stage8-k2): establish Tangent long-term branch and archive prompts
```

不可变分支：

```text
origin/main
=
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
=
4cc94707a55eb6435e37e0c0ccfac6796eae4b8d
```

Tangent 分支角色：

```text
PRIMARY_TANGENT_AND_CLASSICAL_BASELINES
```

默认 K2：

```text
TANGENT_PROFILE_SAFE
```

当前已有经典比较：

```text
FULL4D_BEAMSPACE_CML_MULTISTART
FULL4D_ELEMENT_CML_MULTISTART
BEAMSPACE_MUSIC_K2
ELEMENT_MUSIC_K2
```

已有结论保持不变：

```text
Tangent algorithm:
FROZEN

Further permitted work:
CLASSICAL_OR_EXTERNAL_BASELINE_COMPARISON_ONLY
```

---

## 1. 为什么不能直接套用标准二维 ESPRIT / Root-MUSIC

### 1.1 当前实际阵列

配置：

```text
full cylinder:
Naz = 192
Nel = 32
R = 0.4 m
dz = 0.017 m
fc = 10 GHz
```

但当前 Stage8 数据使用的是围绕当前扇区中心选出的连续工作子阵：

```text
active azimuth columns = 65
vertical layers = 32
active element count = 2080
```

阵元位置：

\[
\varphi_q
=
\frac{2\pi q}{192},
\]

\[
z_n
=
n d_z.
\]

接收导向量：

\[
a_{n,q}(\phi,\theta)
=
\exp
\left\{
j k_0
\left[
R\cos\theta\cos(\phi-\varphi_q)
+
z_n\sin\theta
\right]
\right\}.
\]

### 1.2 精确可分结构

定义：

\[
v_n(\theta)
=
e^{j n\mu_z(\theta)},
\]

\[
\mu_z(\theta)
=
k_0d_z\sin\theta,
\]

以及：

\[
b_q(\phi,\theta)
=
\exp
\left\{
j k_0R\cos\theta\cos(\phi-\varphi_q)
\right\}.
\]

则工作子阵流形矩阵精确满足：

\[
\boxed{
A(\phi,\theta)
=
v(\theta)b(\phi,\theta)^T
}
\]

向量化后：

\[
a(\phi,\theta)
=
b(\phi,\theta)\otimes v(\theta).
\]

因此，当前圆柱阵只在垂直 \(z\) 方向具有标准 ULA/Vandermonde 移位不变性：

\[
\boxed{
J_{z,2}v(\theta)
=
e^{j\mu_z(\theta)}
J_{z,1}v(\theta)
}
\]

而活动方位扇区不是 ULA，且不包含完整 192 列圆环。

### 1.3 当前顺序 Beamspace 不保留标准 ESPRIT/Root-MUSIC 结构

当前 Beamspace 数据：

\[
Z
=
T_IW_I^HY_{\rm element}.
\]

其中：

```text
W_I：
注册的顺序 DBF measurement

T_I：
精确 beamspace noise whitener
```

它们不是为保持 ULA shift invariance 或 Vandermonde polynomial 设计的。

因此本轮禁止把标准：

```text
2-D ESPRIT
2-D Root-MUSIC
UCA-RB-MUSIC
UCA-ESPRIT
```

直接应用到 15 维顺序 Beamspace 并称为同条件经典算法。

Mathews–Zoltowski 的 UCA-RB-MUSIC/UCA-ESPRIT 依赖：

```text
完整 UCA
phase-mode excitation / beamspace transformation
完整圆周旋转结构
```

当前只有 65/192 的活动扇区；若改用完整 192 列圆环，就改变了观测孔径和输入数据，
不再是同条件比较。

### 1.4 本轮采用的严格可行路线

本轮只利用精确存在的垂直 ULA 结构：

```text
阵元矩阵
→ 垂直 covariance
→ vertical forward/backward spatial smoothing
→ MUSIC / Root-MUSIC / ESPRIT 估计两个俯仰
→ 固定所估俯仰
→ 用完整阵元域 known-K CML 搜索两个方位
```

因此这些方法是：

```text
经典子空间方法
+
精确完整流形条件 CML
```

而不是纯闭式二维 ESPRIT。

---

## 2. 主要文献

设计文档必须引用并讨论：

### MUSIC

R. O. Schmidt,

“Multiple Emitter Location and Signal Parameter Estimation,”

IEEE Transactions on Antennas and Propagation, 1986.

### ESPRIT

R. Roy and T. Kailath,

“ESPRIT—Estimation of Signal Parameters Via Rotational Invariance Techniques,”

IEEE Transactions on Acoustics, Speech, and Signal Processing, 1989.

DOI：

```text
10.1109/29.32276
```

### Spatial smoothing

T.-J. Shan, M. Wax, and T. Kailath,

“On Spatial Smoothing for Direction-of-Arrival Estimation of Coherent Signals,”

IEEE Transactions on Acoustics, Speech, and Signal Processing, 1985.

DOI：

```text
10.1109/TASSP.1985.1164649
```

### Forward/backward spatial smoothing

S. U. Pillai and B. H. Kwon,

“Forward/Backward Spatial Smoothing Techniques for Coherent Signal Identification,”

IEEE Transactions on Acoustics, Speech, and Signal Processing, 1989.

DOI：

```text
10.1109/29.17496
```

### Root-MUSIC

A. J. Barabell,

“Improving the Resolution Performance of Eigenstructure-Based
Direction-Finding Algorithms,”

Proceedings of ICASSP, 1983.

### UCA applicability boundary

C. P. Mathews and M. D. Zoltowski,

“Eigenstructure Techniques for 2-D Angle Estimation with Uniform Circular Arrays,”

IEEE Transactions on Signal Processing, 1994.

DOI：

```text
10.1109/78.317861
```

### Conditional ML

P. Stoica and K. C. Sharman,

“Maximum Likelihood Methods for Direction-of-Arrival Estimation,”

IEEE Transactions on Acoustics, Speech, and Signal Processing, 1990.

DOI：

```text
10.1109/29.57542
```

---

## 3. 分支创建

### 3.1 Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags

git switch experiment/stage8-k2-tangent
git reset --hard origin/experiment/stage8-k2-tangent

git rev-parse HEAD
git rev-parse origin/experiment/stage8-k2-tangent
git rev-parse origin/main
git rev-parse origin/research/stage8-k2-vincent-anchored
git status --porcelain=v1 --untracked-files=all
```

要求：

```text
HEAD == origin/experiment/stage8-k2-tangent
HEAD == 8e591779095e94333ed804351be1d35340d974ea
origin/main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
origin/research/stage8-k2-vincent-anchored
== 4cc94707a55eb6435e37e0c0ccfac6796eae4b8d
working tree clean
```

若 Tangent 分支是 `8e591779` 的用户授权 docs-only 后代：

```text
停止并报告实际 SHA；
不得自行换起点。
```

### 3.2 Work 分支

新建：

```text
work/stage8-k2-subspace-baselines-v1
```

确认本地和远端均不存在同名分支。

执行：

```powershell
git switch -c work/stage8-k2-subspace-baselines-v1 `
  8e591779095e94333ed804351be1d35340d974ea
```

本次不得在工具和实验完成前直接提交到长期 Tangent 分支。

---

## 4. 冻结科学边界

不得修改：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**

beamspace_ml_v18/**

innovation-mining/31_*
innovation-mining/32_*
innovation-mining/33_*
innovation-mining/34_*

research/stage8-k2-vincent-anchored
main
```

特别禁止：

```text
修改 Tangent 算法
修改 P1–P4
修改已有 source/noise seeds
修改 Full4D CML 预算
修改已有标准 MUSIC 实现
重新解释 Vincent 结果
```

只允许新增：

```text
tools/stage8_k2_subspace_baselines/**
innovation-mining/39_*
innovation-mining/40_*
prompt 017
文档索引和 prompt 状态
```

---

## 5. 同条件 Trial 合同

完整复用 `31_* / 34_*` 的原 72 个 K2 trials：

```text
noise:
WHITE
STAGE5_TOEPLITZ_CORRELATED

L:
1 / 4 / 8

SNR:
-6 / 0 / +6 dB

profiles:
P1 / P2 / P3 / P4
```

不得创建新 seed。

每个 trial：

1. 使用现有 generator 重建同一个 `Y_element`；
2. 验证：
   ```text
   element_trial_hash
   ==
   31_* / 34_* 对应 hash
   ```
3. 任一 hash 不同：
   ```text
   EXPERIMENT_INVALID
   ```

已有 Tangent、Full4D CML 和标准 MUSIC 结果：

```text
直接读取 31_* / 34_*
不重新拟合
```

---

## 6. 噪声结构与垂直 covariance

当前注册阵元噪声：

\[
R_{n,\rm elem}
=
R_{\rm az}\otimes R_{\rm el}.
\]

白噪声：

\[
R_{\rm az}=I,\qquad R_{\rm el}=I.
\]

相关噪声：

\[
[R_{\rm az}]_{ij}
=
\rho_{\rm az}^{|i-j|},
\]

\[
[R_{\rm el}]_{ij}
=
\rho_{\rm el}^{|i-j|}.
\]

将每个 snapshot 的阵元向量按 canonical ordering 重排为：

\[
X_\ell\in\mathbb C^{N_{\rm el}\times N_{\rm az}}.
\]

取：

\[
W_{\rm az}R_{\rm az}W_{\rm az}^H=I.
\]

MATLAB 中使用：

```matlab
L_az = chol(R_az, 'lower');
W_az = L_az \ eye(N_az);
X_az_white = X * W_az.';
```

注意必须使用非共轭转置 `.'`，因为：

\[
\operatorname{vec}(XW_{\rm az}^T)
=
(W_{\rm az}\otimes I)
\operatorname{vec}(X).
\]

于是 azimuth-whitened 噪声 covariance 为：

\[
I_{\rm az}\otimes R_{\rm el}.
\]

构造垂直 covariance：

\[
\boxed{
\widehat R_v
=
\frac{1}{LN_{\rm az}}
\sum_{\ell=1}^{L}
X_{\ell,\rm azw}
X_{\ell,\rm azw}^H
}
\]

其结构为：

\[
\widehat R_v
\approx
V C V^H
+
R_{\rm el}.
\]

---

## 7. 垂直 Forward/Backward Spatial Smoothing

### 7.1 固定子阵长度

阵元层数：

```text
N_el = 32
K = 2
```

固定：

\[
\boxed{
M_s=N_{\rm el}-K+1=31
}
\]

因此重叠子阵数：

\[
\boxed{
P=N_{\rm el}-M_s+1=2
}
\]

这是在满足 `P >= K` 的条件下最大化垂直子阵孔径的确定性选择。

不得根据结果调整 \(M_s\)。

### 7.2 Forward smoothing

定义选择矩阵：

\[
J_p
=
[0\ I_{M_s}\ 0],
\qquad p=0,1.
\]

垂直 steering：

\[
v_s(\theta)
=
[1,e^{j\mu_z},\ldots,e^{j(M_s-1)\mu_z}]^T.
\]

满足：

\[
J_pv(\theta)
=
e^{jp\mu_z(\theta)}
v_s(\theta).
\]

Forward-smoothed covariance：

\[
\boxed{
R_F
=
\frac1P
\sum_{p=0}^{P-1}
J_p\widehat R_vJ_p^H
}
\]

### 7.3 Forward/backward averaging

令：

\[
\Pi_{M_s}
\]

为反序 exchange matrix。

\[
\boxed{
R_{FB}
=
\frac12
\left(
R_F
+
\Pi_{M_s}R_F^*\Pi_{M_s}
\right)
}
\]

垂直噪声子阵 covariance：

\[
R_{n,s}
=
J_0R_{\rm el}J_0^H.
\]

由于当前 \(R_{\rm el}\) 是实对称 Toeplitz，\(R_{n,s}\) 与垂直
forward/backward 结构兼容。

---

## 8. 方法 B1：Generalized FBSS-MUSIC + 条件方位 CML

方法 ID：

```text
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
```

### 8.1 适用范围

适用：

```text
profiles P1 / P3 / P4
两种 noise
L = 1 / 4 / 8
全部 SNR
```

总数：

```text
54 trials
```

P2 的两个目标具有相同俯仰，只在方位上分离；垂直子阵只有一个唯一空间频率，
因此标记：

```text
NOT_APPLICABLE_EQUAL_ELEVATION_MULTIPLICITY
```

不得把 P2 N/A 计成失败或 Tangent 胜利。

### 8.2 Generalized whitening

对：

\[
R_{n,s}
=
L_sL_s^H
\]

取：

\[
C_s=L_s^{-1}.
\]

\[
\overline R
=
C_sR_{FB}C_s^H.
\]

\[
\overline v(\theta)
=
C_sv_s(\theta).
\]

取 \(\overline R\) 的两个主特征向量作为 signal subspace，
剩余向量为 \(E_n\)。

MUSIC spectrum：

\[
\boxed{
P_{\rm GFBSS-MUSIC}(\theta)
=
\frac{
1
}{
\|E_n^H\overline v(\theta)\|_2^2
}
}
\]

固定俯仰网格：

```text
9.8° : 0.001° : 10.2°
```

选择两个不同的一维局部峰。

少于两个峰：

```text
GFBSS_MUSIC_FEWER_THAN_TWO_ELEVATION_PEAKS
```

---

## 9. 方法 B2：FBSS Root-MUSIC + 条件方位 CML

方法 ID：

```text
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
```

### 9.1 适用范围

仅适用于：

```text
noise = WHITE
profiles P1 / P3 / P4
全部 L / SNR
```

总数：

```text
27 trials
```

相关噪声不实现 generalized Root-MUSIC，因为垂直噪声 whitening 会破坏标准
Vandermonde polynomial；标记：

```text
NOT_APPLICABLE_COLORED_NOISE_STANDARD_ROOT_MUSIC
```

P2：

```text
NOT_APPLICABLE_EQUAL_ELEVATION_MULTIPLICITY
```

### 9.2 Root polynomial

对白噪声 \(R_{FB}\) 做 EVD，取 noise projector：

\[
Q_n=E_nE_n^H.
\]

定义：

\[
v(z)
=
[1,z,\ldots,z^{M_s-1}]^T.
\]

Root-MUSIC polynomial：

\[
D(z)
=
v^T(z^{-1})Q_nv(z).
\]

系数：

\[
\boxed{
c_\ell
=
\sum_{m-n=\ell}
[Q_n]_{mn}
}
\]

\[
\ell=-(M_s-1),\ldots,M_s-1.
\]

形成普通多项式：

\[
\widetilde D(z)
=
z^{M_s-1}
\sum_\ell c_\ell z^\ell.
\]

从单位圆内选择：

```text
最接近单位圆
映射到注册俯仰域
互不为同一 reciprocal-conjugate pair
```

的两个根。

\[
\widehat\mu_k
=
\arg z_k.
\]

\[
\boxed{
\widehat\theta_k
=
\arcsin
\left(
\frac{\widehat\mu_k}{k_0d_z}
\right)
}
\]

具体正负号必须由合成 fixture 对当前 `exp(+j k z sin(theta))` 约定验证；
不得仅凭外部代码习惯猜测。

---

## 10. 方法 B3：FBSS LS-ESPRIT + 条件方位 CML

方法 ID：

```text
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

### 10.1 适用范围

与 Root-MUSIC 相同：

```text
WHITE
P1 / P3 / P4
全部 L / SNR
27 trials
```

相关噪声和 P2 分别标记结构性 N/A。

### 10.2 ESPRIT

取 \(R_{FB}\) 的两个主特征向量：

\[
U_s\in\mathbb C^{M_s\times2}.
\]

定义：

\[
S_1
=
[ I_{M_s-1}\ 0 ]U_s,
\]

\[
S_2
=
[ 0\ I_{M_s-1} ]U_s.
\]

LS-ESPRIT：

\[
\boxed{
\Psi
=
S_1^\dagger S_2
}
\]

其特征值：

\[
\lambda_k
\approx
e^{j\mu_z(\theta_k)}.
\]

因此：

\[
\widehat\mu_k
=
\arg\lambda_k,
\]

\[
\boxed{
\widehat\theta_k
=
\arcsin
\left(
\frac{\widehat\mu_k}{k_0d_z}
\right)
}
\]

若：

```text
S1 rank < 2
eigenvalues nonfinite
两个 elevation 数值重合
估计超出 local elevation domain
```

则方法 invalid。

本 V1 不增加 TLS、unitary ESPRIT 或多套 ESPRIT 变体。

---

## 11. 共同后端：完整阵元域条件方位 CML

三种新子空间方法都只直接估计：

```text
theta_1
theta_2
```

方位角由同一个完整阵元域条件 CML 后端估计。

### 11.1 精确阵元白化

使用已有：

```text
stage8_k2_cb_whiten_element_data
build_stage8_element_manifold
concentrated_dml_rss
```

得到：

\[
Y_w
=
R_{n,\rm elem}^{-1/2}Y_{\rm element}.
\]

给定 \(\widehat\theta_1,\widehat\theta_2\)，对任意方位对：

\[
(\phi_1,\phi_2)
\]

构造：

\[
A_w
=
R_{n,\rm elem}^{-1/2}
[
a(\phi_1,\widehat\theta_1),
a(\phi_2,\widehat\theta_2)
].
\]

条件 CML：

\[
\boxed{
(\widehat\phi_1,\widehat\phi_2)
=
\arg\min_{\phi_1,\phi_2}
\left\|
\Pi_{A_w(\phi_1,\phi_2)}^\perp
Y_w
\right\|_F^2
}
\]

### 11.2 方位搜索

固定粗网格：

```text
7.4° : 0.02° : 8.6°
```

允许：

```text
phi_1 = phi_2
```

因为 P3 是纯俯仰分离。

枚举全部 ordered pairs：

```text
61 × 61 = 3721
```

按 exact concentrated loglik 选前：

```text
top_start_count = 4
```

每个 start 做：

```text
phi_1 / phi_2 坐标更新
max sweeps = 8
scan nodes per coordinate = 9
fminbnd TolX = 1e-4 deg
MaxFunEvals = 80
```

最终选择有效 starts 中 exact loglik 最大者。

不得使用：

```text
truth
profile ID
Tangent angle
Full4D result
Core result
```

作为 start。

---

## 12. 方法和数据表

冻结参考方法：

```text
TANGENT_PROFILE_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART
FULL4D_ELEMENT_CML_MULTISTART
BEAMSPACE_MUSIC_K2
ELEMENT_MUSIC_K2
```

新方法：

```text
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

结果表对每个 72 trial 都保留一行/方法；不适用方法写：

```text
applicable = false
fit_valid = false
明确 applicability_status
```

不得删除 N/A 行。

---

## 13. 公平性说明

### 相同部分

所有方法使用：

```text
同一个 Y_element
同一个 source/noise seed
同一个 single-CPI / same range-Doppler cell
同一个 known K=2
同一个 local angular domain
同一个阵列和噪声模型
```

### 不同 observation domain

```text
Tangent / Beamspace CML:
固定 15 维顺序 Beamspace

新 FBSS / Root-MUSIC / ESPRIT：
完整活动阵元域
```

这是结构性必要差异，因为标准 ESPRIT/Root-MUSIC 需要 element-domain 垂直
shift invariance，当前任意顺序 Beamspace 不保留该结构。

报告必须把新方法定位为：

```text
MORE-INFORMATIVE ELEMENT-DOMAIN CLASSICAL REFERENCES
```

不得声称它们与 Tangent 具有完全相同的压缩维数和硬件接口。

---

## 14. 评价指标

在算法输出完成后做最优目标 permutation matching。

报告：

```text
applicable count
valid count
joint endpoint RMSE median/p90
azimuth RMSE median/p90
elevation RMSE median/p90
center error median/p90
axis error median/p90
rho error median/p90
separation-vector error median/p90
runtime median/p90
score/eig/SVD counts
```

配对比较仅在：

```text
两方法都 applicable
且
两方法都 valid
```

的共同子集上计算：

```text
wins / ties / losses
```

tie：

```text
abs(delta_joint_RMSE) <= 1e-6 deg
```

同时独立报告：

```text
applicable-but-invalid count
two-elevation-peak/root/eigenvalue success rate
conditional az CML valid rate
```

不得新增 resolved/unresolved threshold 或 bootstrap。

---

## 15. 最小测试

只设置以下理论/实现测试。

### T1：圆柱阵 Kronecker 分解

随机选择 8 个注册域内角度，验证：

\[
a(\phi,\theta)
=
b(\phi,\theta)\otimes v(\theta)
\]

相对误差：

```text
<= 1e-12
```

### T2：垂直 shift invariance

验证：

\[
J_{z,2}a
=
e^{j k_0d_z\sin\theta}
J_{z,1}a
\]

相对误差：

```text
<= 1e-12
```

### T3：噪声 Kronecker 与 azimuth whitening

对白噪声和相关噪声验证：

\[
R_n
=
R_{\rm az}\otimes R_{\rm el}
\]

以及：

\[
(W_{\rm az}\otimes I)
R_n
(W_{\rm az}\otimes I)^H
=
I\otimes R_{\rm el}.
\]

### T4：两相干源 FBSS fixture

构造两个不同俯仰、完全相干源，验证：

```text
原 covariance signal rank = 1 或退化
FBSS covariance 可恢复 2 维 signal subspace
```

### T5：GFBSS-MUSIC fixture

白噪声与相关噪声各一个合成 fixture，验证两个 elevation 峰有限且接近真值。

### T6：Root-MUSIC fixture

白噪声合成 fixture，验证根选择和当前正相位约定。

### T7：ESPRIT fixture

白噪声合成 fixture，验证：

\[
\lambda=e^{+j k_0d_z\sin\theta}.
\]

### T8：条件方位 CML fixture

固定两个正确俯仰，验证完整阵元域 conditional CML 能恢复两个方位。

### T9：Applicability

验证：

```text
P2 → equal-elevation N/A
colored Root-MUSIC → N/A
colored ESPRIT → N/A
```

### T10：72-trial hash reconstruction

要求：

```text
72/72 element hashes match
```

测试完成后直接正式运行，不增加 F0/F1/Gate 框架。

---

## 16. 新代码路径

只允许新增：

```text
tools/stage8_k2_subspace_baselines/
```

建议：

```text
tools/stage8_k2_subspace_baselines/
├── README.md
├── matlab/
│   ├── stage8_k2_sb_constants.m
│   ├── stage8_k2_sb_add_paths.m
│   ├── stage8_k2_sb_build_context.m
│   ├── stage8_k2_sb_reshape_element_snapshots.m
│   ├── stage8_k2_sb_noise_factors.m
│   ├── stage8_k2_sb_vertical_covariance.m
│   ├── stage8_k2_sb_fbss_covariance.m
│   ├── stage8_k2_sb_gfbss_music.m
│   ├── stage8_k2_sb_root_music.m
│   ├── stage8_k2_sb_ls_esprit.m
│   ├── stage8_k2_sb_conditional_az_cml.m
│   ├── stage8_k2_sb_evaluate_trial.m
│   ├── stage8_k2_sb_result_row.m
│   ├── stage8_k2_sb_summarize.m
│   └── stage8_k2_sb_run.m
└── tests/
    ├── test_cylinder_kronecker_factorization.m
    ├── test_vertical_shift_invariance.m
    ├── test_noise_kronecker_az_whitening.m
    ├── test_fbss_coherent_rank_restoration.m
    ├── test_gfbss_music_fixture.m
    ├── test_root_music_fixture.m
    ├── test_esprit_fixture.m
    ├── test_conditional_az_cml_fixture.m
    ├── test_applicability_contract.m
    └── test_trial_reconstruction_hash.m
```

---

## 17. 文档与输出

新增：

```text
innovation-mining/
39_stage8_k2_subspace_baseline_theory_and_protocol.md

40_stage8_k2_subspace_baseline_comparison.md

40_stage8_k2_subspace_baseline_trials.csv

40_stage8_k2_subspace_baseline_summary.csv

40_stage8_k2_subspace_baseline_profile_summary.csv

40_stage8_k2_subspace_baseline_applicability.csv

40_stage8_k2_subspace_baseline_complexity.csv

40_stage8_k2_subspace_baseline_elevation_diagnostics.csv
```

Prompt：

```text
innovation-mining/stage8_execution_prompts/active/
017_stage8_k2_subspace_baseline_comparison_v1.md
```

编号 `015/016` 已由 Vincent research 分支使用，因此 Tangent 分支下一编号直接使用 `017`。

---

## 18. 执行方式

使用：

```text
MATLAB R2022b
-singleCompThread
1 MATLAB process
```

禁止：

```text
parpool
parfor
coordinator
scheduled task
bootstrap
复杂 checkpoint
```

Runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_subspace_baselines_v1
```

先运行：

```text
10 项理论/实现测试
4 个 smoke trials：
P1/P3/P4 white + P3 correlated
```

smoke 只验证：

```text
finite
applicability
no truth leakage
conditional CML 可运行
```

不设性能门。

随后一次运行正式 72-trial 比较。

中断则删除本轮未提交 runtime 并从头执行，不建立恢复框架。

---

## 19. 结果解释

本轮没有“新算法保留门”。

只允许：

```text
STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_COMPLETE

STAGE8_K2_SUBSPACE_BASELINE_EXPERIMENT_INVALID
```

`COMPLETE` 只要求：

```text
72/72 hash
方法适用性合同正确
无 truth leakage
全部 applicable rows 有明确 valid/invalid 状态
输出表完整
冻结算法无修改
```

性能无论好坏都提交为经典基线证据。

报告必须回答：

1. 标准 MUSIC 为什么只有单峰；
2. 垂直 spatial smoothing 是否恢复 coherent-source elevation rank；
3. Root-MUSIC / ESPRIT 在其结构适用子集上的有效率；
4. 条件方位 CML 是否成为主要误差来源；
5. Tangent 相对更高信息量 element-domain 经典方法的误差和成本位置；
6. P1/P3/P4 与 L/SNR/noise 的差异；
7. P2 为什么不属于垂直子空间方法的可辨识集合；
8. 为什么 full-UCA phase-mode 方法未被伪装成同条件比较。

---

## 20. 提交顺序

### 20.1 Prompt/design commit

新增：

```text
39 theory/protocol
017 prompt
active README
```

active README：

```text
STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_ACTIVE
WORK_BRANCH_ONLY
TANGENT_FROZEN
NO_PRODUCTION_CHANGE
```

提交：

```text
docs(stage8-k2): define subspace baseline comparison
```

推送：

```powershell
git push -u origin work/stage8-k2-subspace-baselines-v1
```

### 20.2 Tool commit

只提交：

```text
tools/stage8_k2_subspace_baselines/
```

提交：

```text
feat(stage8-k2): add structured subspace baselines
```

推送 work 分支。

### 20.3 Result commit

提交：

```text
40_*
```

将 `017` 移到：

```text
archive/completed/
```

更新：

```text
archive/PROMPT_ARCHIVE_MANIFEST.csv
00_DOCUMENT_STATUS_INDEX.md
active/README.md
```

active README：

```text
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_COMPLETED

DEFAULT_K2:
TANGENT_PROFILE_SAFE

TANGENT ALGORITHM:
FROZEN

NEW SUBSPACE METHODS:
CLASSICAL REFERENCES ONLY

FURTHER WORK:
REQUIRES_SEPARATE AUTHORIZATION
```

提交：

```text
docs(stage8-k2): record subspace baseline comparison
```

推送 work 分支。

---

## 21. Work 分支结果审计

确认：

```text
HEAD == origin/work/stage8-k2-subspace-baselines-v1
Git tracked clean
```

从起点到结果 HEAD，只允许：

```text
tools/stage8_k2_subspace_baselines/**
39_*
40_*
017 prompt 的新增和归档
00 index
prompt README / manifest
```

以下必须无 diff：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
beamspace_ml_v18/**
31_*–34_*
main
research branch
```

若结论为：

```text
EXPERIMENT_INVALID
```

则：

```text
停止；
不得快进 Tangent；
保留 work 分支供审计。
```

---

## 22. Fast-forward 集成到长期 Tangent 分支

只有：

```text
STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_COMPLETE
```

且 scope audit 全部通过时执行。

记录 work result HEAD：

```powershell
$workHead = (git rev-parse HEAD).Trim()
```

切回 Tangent：

```powershell
git switch experiment/stage8-k2-tangent
git reset --hard origin/experiment/stage8-k2-tangent
```

确认仍为：

```text
8e591779095e94333ed804351be1d35340d974ea
```

执行：

```powershell
git merge --ff-only $workHead
git push origin experiment/stage8-k2-tangent
```

要求：

```text
origin/experiment/stage8-k2-tangent == $workHead
```

禁止：

```text
merge commit
squash
rebase
force push
删除 work 分支
```

work 分支保留，等待用户人工审查是否删除。

---

## 23. 最终审计

必须确认：

```text
main unchanged:
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

research unchanged:
4cc94707a55eb6435e37e0c0ccfac6796eae4b8d

Tangent contains:
31_*–34_*
39_*–40_*
Tangent tools
classical baseline tools
subspace baseline tools

Tangent does not contain:
Vincent tools
35_*–37_*
```

最终检出：

```text
experiment/stage8-k2-tangent
```

MATLAB / mwpython / coordinator / lock：

```text
0 / 0 / 0 / 0
```

---

## 24. 最终报告格式

```text
STAGE8_K2_SUBSPACE_BASELINE_COMPARISON_COMPLETE / INVALID

Starting Tangent HEAD:
Work branch:
Prompt commit:
Tool commit:
Result commit:
Fast-forward integration:
Final Tangent HEAD:
Work branch retained:

Main unchanged:
Research unchanged:
Tangent scientific code changed:
false
Existing evidence changed:
false

Trial integrity:
- 72/72 hashes
- truth leakage
- method rows
- applicability rows

Array structure:
- Kronecker factorization residual
- vertical shift residual
- colored noise factorization residual

GFBSS-MUSIC:
- applicable / valid
- two-elevation peak rate
- conditional az CML rate
- metrics
- P1/P3/P4
- L/SNR/noise

Root-MUSIC:
- applicable / valid
- root selection rate
- conditional az CML rate
- metrics

ESPRIT:
- applicable / valid
- eigenvalue rate
- conditional az CML rate
- metrics

Frozen references:
- Tangent
- Full4D CML
- standard MUSIC

Pairwise common-subset comparisons:

Interpretation:
- coherent-source restoration
- element vs beamspace information
- structural N/A cases
- cost

Default K2:
TANGENT_PROFILE_SAFE

Production integration:
false

Further algorithm modification:
not authorized
```

完成后停止，不启动新的算法比较。
