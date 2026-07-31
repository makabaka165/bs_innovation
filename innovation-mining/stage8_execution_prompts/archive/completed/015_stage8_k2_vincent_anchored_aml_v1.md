# Stage8-K2-VA1：Vincent/Bonacci 启发的锚点–分离投影近似 CML（圆柱阵顺序 Beamspace V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b 和 Git 的执行 AI。
>
> 本协议从已经完成经典基线比较的分支精确分叉，建立一条独立的 Vincent-inspired K2 探索路线。原 `experiment/stage8-k2-classical-baselines-v1`、原 Tangent 分支、Core-V2 和 `main` 全部保持只读。
>
> 本路线不是继续加强 Full4D multistart，也不是简单增加一个 \((\alpha,\rho)\) 二维暴力搜索。它实现：
>
> ```text
> K1 给出局部参考点 c0
> → 现有投影残差方法给出无向 Tangent 轴 u
> → 沿该轴搜索第一个目标的锚点位置 t
> → 对每个 t，用 Vincent/Bonacci 式投影矩阵二次展开闭式求 ρ_AML(t)
> → 用完整顺序白化流形的精确 concentrated likelihood 评价该 pair
> → 一维搜索 t
> → 与 fixed-grid K2 做安全似然回退
> ```
>
> 协议：
>
> ```text
> STAGE8_K2_VINCENT_ANCHORED_PROJECTOR_AML_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_VINCENT_ANCHORED_PROJECTOR_AML_V1
> ```

---

## 0. 当前基线与为什么开新分支

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

当前基线分支：

```text
experiment/stage8-k2-classical-baselines-v1
```

精确基线提交：

```text
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b
docs(stage8-k2): record classical baseline comparison
```

只读上游：

```text
origin/experiment/stage8-k2-tangent-profile-v1
=
721c30aa96f1687c757004613c23e9fb6a814afd

origin/experiment/stage8-core-v2
=
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/main
=
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

已知结论：

```text
Tangent-Profile：
- joint endpoint RMSE 明显优于内部基线；
- 相对当前 Full4D Beamspace CML multistart 也更稳；
- 但固定 K1 中心导致的偏差仍是一个结构性可能；
- raw rho 恢复不稳定；
- Full4D 自由搜索在有限样本下出现较大方差/错误极值。

经典基线：
- Full4D Beamspace CML 是完整四角参数空间的数值近似；
- 标准未平滑 MUSIC 没有形成两个峰；
- Full4D Element CML 没有在 P2/P4 中给出明确恢复；
- 当前证据不支持继续堆 Full4D starts/sweeps。
```

本路线只回答：

> 保留 Tangent 的数据驱动分离轴，同时不再把 K1 结果固定为双目标几何中点，是否能用 Vincent/Bonacci 式“锚点位置 + 条件闭式分离量”得到更好的 K2 endpoint 估计？

---

## 1. 新分支创建与隔离

### 1.1 Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git status --porcelain=v1 --untracked-files=all

git rev-parse origin/experiment/stage8-k2-classical-baselines-v1
git rev-parse origin/experiment/stage8-k2-tangent-profile-v1
git rev-parse origin/experiment/stage8-core-v2
git rev-parse origin/main
```

要求：

```text
工作树 clean

origin/experiment/stage8-k2-classical-baselines-v1
==
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

origin/experiment/stage8-k2-tangent-profile-v1
==
721c30aa96f1687c757004613c23e9fb6a814afd

origin/experiment/stage8-core-v2
==
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/main
==
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

若当前 classical-baselines 分支是 `bdb2a51` 的用户授权 docs-only 后代，停止并报告实际 SHA，不自行选择新起点。

### 1.2 新分支

新分支名：

```text
experiment/stage8-k2-vincent-anchored-aml-v1
```

确认本地和远端均不存在同名 ref。

执行：

```powershell
git switch --detach bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b
git switch -c experiment/stage8-k2-vincent-anchored-aml-v1
```

初始 HEAD 必须精确为 `bdb2a51`。

### 1.3 永久隔离

禁止：

```text
push main
push experiment/stage8-core-v2
push experiment/stage8-k2-tangent-profile-v1
push experiment/stage8-k2-classical-baselines-v1
merge 回上述分支
force push
```

所有新增提交只推送：

```text
experiment/stage8-k2-vincent-anchored-aml-v1
```

---

## 2. 主要文献与可保留的新颖性边界

### 2.1 Vincent–Besson–Chaumette 2014

François Vincent, Olivier Besson, Eric Chaumette,

“Approximate maximum likelihood estimation of two closely spaced sources,”

*Signal Processing*, Vol. 97, 2014, pp. 83–90.

DOI：

```text
10.1016/j.sigpro.2013.10.017
```

其核心：

```text
A(f1, Δf) = [a(f1), a(f1 + Δf)]

对 close-source signal-subspace projector 关于 Δf 做二阶 Taylor 展开；

对每个 f1 得到条件闭式：
Δf_AML(f1) = -α1(f1)/(2 α2(f1))

将该 Δf_AML(f1) 代回精确或近似 CML，
只对 f1 做一维搜索。
```

其重要结构不是“固定中点”，而是：

```text
第一个位置 f1 保持可移动；
第二个位置由 f1 + Δf 给出；
几何中心随 f1、Δf 一起移动。
```

### 2.2 Bonacci–Vincent–Gigleux 2017

David Bonacci, François Vincent, Benjamin Gigleux,

“Robust DoA estimation in case of multipath environment for a sense and avoid airborne radar,”

*IET Radar, Sonar & Navigation*, 2017.

DOI：

```text
10.1049/iet-rsn.2016.0446
```

该工作将 ULA 空间频率参数化推广到 NULA 的：

\[
\sin\theta_1,\qquad
\Delta\sin\theta
=
\sin\theta_1-\sin\theta_2,
\]

并得到：

\[
\Delta\sin\theta_{\rm ACML}(\sin\theta_1)
\approx
-\frac{\alpha_1}{2\alpha_2}.
\]

然后只搜索第一个角度位置。

### 2.3 相关扩展

Vincent 等人的后续研究还把 close-source approximate ML 思路用于：

```text
unconditional ML；
close time-delay / multipath separation；
第三阶 likelihood 近似。
```

这些工作说明 Taylor-AML 思路可以从 ULA 频率问题推广到其他平滑参数流形，但不意味着其闭式公式可以直接复制到圆柱阵。

### 2.4 当前允许的表述

本路线只允许称为：

> 在固定精确白化的二维圆柱阵顺序 beamspace 中，利用现有投影残差估计的局部分离轴，把二维阵列流形限制为一条数据驱动的平滑曲线；随后用一般光滑曲线的信号子空间投影二次展开，对每个锚点位置闭式 profile 分离尺度，并以完整顺序流形 CML 完成一维锚点搜索。

禁止称为：

```text
首次提出 close-source AML
首次提出 anchor–separation 参数化
首次把二维 ML 降为一维
首次把 Taylor AML 推广到非均匀阵列
首次使用 projector expansion
```

若 prior art 检索发现完全相同的：

```text
固定白化二维圆柱阵 beamspace
+
数据驱动 Tangent 轴
+
锚点搜索
+
一般 projector differential 的闭式 rho
+
精确 full-manifold likelihood
```

则降级为：

```text
SYSTEM-SPECIFIC IMPLEMENTATION
```

---

## 3. 当前圆柱阵和顺序 Beamspace 模型

### 3.1 接收单程圆柱阵流形

第 \(m\) 个阵元位置：

\[
\mathbf r_m
=
[x_m,y_m,z_m]^T.
\]

方位和俯仰使用弧度：

\[
\phi,\theta.
\]

接收单程相位：

\[
\chi_m(\phi,\theta)
=
k_0
\left[
x_m\cos\theta\cos\phi
+
y_m\cos\theta\sin\phi
+
z_m\sin\theta
\right],
\]

\[
k_0=\frac{2\pi}{\lambda}.
\]

阵元导向量：

\[
a_m(\phi,\theta)
=
e^{j\chi_m(\phi,\theta)}.
\]

固定顺序 measurement 和精确白化后：

\[
\boxed{
g(\phi,\theta)
=
T_IW_I^Ha(\phi,\theta)
}
\]

其中 \(W_I,T_I\) 在一次估计内固定，且不随候选角改变。

### 3.2 白化观测和 CML

\[
Z
=
T_IW_I^HY_{\rm element}.
\]

样本能量矩阵：

\[
R_Z
=
ZZ^H.
\]

对于任意两个角：

\[
G(\xi_1,\xi_2)
=
[g(\xi_1),g(\xi_2)].
\]

投影矩阵：

\[
P_G
=
G(G^HG)^{-1}G^H.
\]

concentrated DML score：

\[
\boxed{
J(\xi_1,\xi_2)
=
\operatorname{Re}
\operatorname{tr}
(P_GR_Z)
}
\]

等价 residual：

\[
RSS
=
\|Z\|_F^2-J.
\]

最终候选评分必须继续调用已有：

```text
build_full_sequential_local_manifold
concentrated_dml_rss
```

而不是用近似 score 直接输出。

---

## 4. Vincent 式锚点–分离参数化

### 4.1 参考点和 Tangent 轴

同一份 K2 数据上：

1. 用冻结 Core-Lite K1 得到参考点：
   \[
   \widehat c_0.
   \]
2. 用现有投影 residual/Fisher metric 方法得到无向轴：
   \[
   \widehat u
   =
   [u_\phi,u_\theta]^T,
   \qquad
   \|\widehat u\|_2=1.
   \]

固定其规范符号：

```text
u_el > 0

若 abs(u_el) <= 1e-12：
u_az >= 0
```

### 4.2 沿轴定义一维圆柱阵流形曲线

以角度“度”为曲线参数：

\[
\boxed{
\xi(t)
=
\widehat c_0+t\widehat u
}
\]

\[
\boxed{
h(t)
=
g(\xi(t))
}
\]

两个目标写为：

\[
\boxed{
\xi_1
=
\xi(t),
\qquad
\xi_2
=
\xi(t+\rho),
\qquad
\rho>0
}
\]

这里：

```text
t：
第一个 endpoint 相对 K1 参考点的锚点位置；

rho：
沿固定 Tangent 轴的两个 endpoint 间隔。
```

与中心偏移参数的关系：

\[
\alpha
=
t+\frac{\rho}{2},
\]

\[
\xi_{1,2}
=
\widehat c_0
+
\alpha\widehat u
\mp
\frac{\rho}{2}\widehat u.
\]

因此当前 Tangent 是：

\[
\alpha=0
\quad\Longleftrightarrow\quad
t=-\rho/2
\]

这一受限特例。

新路线不会把 \(\widehat c_0\) 当成固定几何中点；它只把 \(\widehat c_0\) 当作一维线坐标的原点。

---

## 5. 圆柱阵沿 Tangent 轴的一至三阶解析导数

### 5.1 相位中间量

对每个阵元定义：

\[
A_m
=
x_m\cos\phi+y_m\sin\phi,
\]

\[
B_m
=
-x_m\sin\phi+y_m\cos\phi.
\]

一阶偏导：

\[
\chi_\phi
=
k_0\cos\theta B_m,
\]

\[
\chi_\theta
=
k_0
(-\sin\theta A_m+z_m\cos\theta).
\]

二阶偏导：

\[
\chi_{\phi\phi}
=
-k_0\cos\theta A_m,
\]

\[
\chi_{\phi\theta}
=
-k_0\sin\theta B_m,
\]

\[
\chi_{\theta\theta}
=
-k_0(\cos\theta A_m+z_m\sin\theta).
\]

三阶偏导：

\[
\chi_{\phi\phi\phi}
=
-k_0\cos\theta B_m,
\]

\[
\chi_{\phi\phi\theta}
=
k_0\sin\theta A_m,
\]

\[
\chi_{\phi\theta\theta}
=
-k_0\cos\theta B_m,
\]

\[
\chi_{\theta\theta\theta}
=
k_0(\sin\theta A_m-z_m\cos\theta).
\]

### 5.2 沿轴的方向相位导数

令：

\[
u_\phi=\widehat u(1),
\qquad
u_\theta=\widehat u(2).
\]

弧度曲线方向导数：

\[
p_1
=
u_\phi\chi_\phi
+
u_\theta\chi_\theta,
\]

\[
p_2
=
u_\phi^2\chi_{\phi\phi}
+
2u_\phi u_\theta\chi_{\phi\theta}
+
u_\theta^2\chi_{\theta\theta},
\]

\[
p_3
=
u_\phi^3\chi_{\phi\phi\phi}
+
3u_\phi^2u_\theta\chi_{\phi\phi\theta}
+
3u_\phi u_\theta^2\chi_{\phi\theta\theta}
+
u_\theta^3\chi_{\theta\theta\theta}.
\]

### 5.3 阵元导向量方向导数

设：

\[
\kappa=\frac{\pi}{180},
\]

因为数值搜索变量 \(t,\rho\) 使用“度”。

则关于 \(t_{\rm deg}\)：

\[
a_0=a,
\]

\[
\boxed{
a_1
=
\kappa
(jp_1)a
}
\]

\[
\boxed{
a_2
=
\kappa^2
(jp_2-p_1^2)a
}
\]

\[
\boxed{
a_3
=
\kappa^3
(jp_3-3p_1p_2-jp_1^3)a
}
\]

其中：

\[
a_r
=
\frac{d^ra(\xi(t))}{dt^r}.
\]

### 5.4 顺序 Beamspace 导数

固定线性 measurement 允许导数与变换交换：

\[
\boxed{
h_r
=
T_IW_I^Ha_r,
\qquad
r=0,1,2,3.
}
\]

代码必须按现有 element ordering 调用：

```text
reshape_cyl_vector_to_matrix
matrix(:)
```

完成 canonicalization，保持与 `build_full_sequential_local_manifold` 完全一致。

---

## 6. 一般光滑流形的无奇异投影展开

### 6.1 为什么不能直接在 \(\rho=0\) 对两列矩阵求逆

定义：

\[
A(t,\rho)
=
[h(t),h(t+\rho)].
\]

当：

\[
\rho\rightarrow0,
\]

两列重合，\(A^HA\) 奇异。

但对任意 \(\rho\ne0\)，以下列变换可逆：

\[
A(t,\rho)
\begin{bmatrix}
1 & -1/\rho\\
0 & 1/\rho
\end{bmatrix}
=
\left[
h(t),
\frac{h(t+\rho)-h(t)}{\rho}
\right].
\]

因此两者投影矩阵完全相同。

定义无奇异基：

\[
B(\rho)
=
\left[
h_0,
v(\rho)
\right],
\]

\[
v(\rho)
=
\frac{h(t+\rho)-h(t)}{\rho}.
\]

Taylor 展开：

\[
v(\rho)
=
h_1
+
\frac{\rho}{2}h_2
+
\frac{\rho^2}{6}h_3
+
O(\rho^3).
\]

于是：

\[
B_0=[h_0,h_1],
\]

\[
B_1=
\left[
0,\frac12h_2
\right],
\]

\[
B_2=
\left[
0,\frac13h_3
\right],
\]

其中 \(B_1=B'(0)\)，\(B_2=B''(0)\)。

### 6.2 常数预条件

对 \(B_0\) 执行 economy SVD：

\[
B_0
=
U\Sigma V^H.
\]

使用现有相对 rank 合同。

若：

```text
rank(B0) < 2
```

则 anchor 无效。

定义常数右变换：

\[
S
=
V\Sigma^{-1}.
\]

然后：

\[
C_j=B_jS,
\qquad
j=0,1,2.
\]

此时：

\[
C_0=U,
\qquad
C_0^HC_0=I,
\]

且右乘常数可逆矩阵不改变投影子空间。

### 6.3 Gram 逆的导数

定义：

\[
H_0=C_0^HC_0,
\]

\[
H_1=C_1^HC_0+C_0^HC_1,
\]

\[
H_2=C_2^HC_0+2C_1^HC_1+C_0^HC_2.
\]

定义：

\[
K(\rho)
=
(C(\rho)^HC(\rho))^{-1}.
\]

则：

\[
K_0=H_0^{-1},
\]

\[
\boxed{
K_1
=
-K_0H_1K_0
}
\]

\[
\boxed{
K_2
=
2K_0H_1K_0H_1K_0
-
K_0H_2K_0
}
\]

其中 \(K_1=K'(0)\)，\(K_2=K''(0)\)。

### 6.4 投影矩阵二次展开

\[
P(\rho)
=
C(\rho)
K(\rho)
C(\rho)^H.
\]

展开：

\[
\boxed{
P(\rho)
=
P_0+\rho P_1+\rho^2P_2+O(\rho^3)
}
\]

其中：

\[
P_0=C_0K_0C_0^H,
\]

\[
\boxed{
P_1
=
C_1K_0C_0^H
+
C_0K_1C_0^H
+
C_0K_0C_1^H
}
\]

以及：

\[
\boxed{
\begin{aligned}
P_2=\frac12[
& C_2K_0C_0^H
+2C_1K_1C_0^H
+2C_1K_0C_1^H\\
&+C_0K_2C_0^H
+2C_0K_1C_1^H
+C_0K_0C_2^H
].
\end{aligned}
}
\]

数值实现后分别执行：

\[
P_j
\leftarrow
\frac12(P_j+P_j^H).
\]

该公式是 Vincent/Bonacci 的：

```text
M2 / M3 / M4 projector expansion
```

在任意光滑一维复流形上的坐标无关版本。

它不要求 ULA 的：

```text
c(Delta) 与 anchor 无关
```

这一平移不变性，因此适用于当前圆柱阵固定白化顺序 beamspace 曲线。

---

## 7. 对每个锚点闭式求分离量

### 7.1 近似 projected-energy score

定义：

\[
q_j(t)
=
\operatorname{Re}
\operatorname{tr}
(P_j(t)R_Z),
\qquad
j=0,1,2.
\]

则：

\[
J(t,\rho)
\approx
q_0(t)
+
q_1(t)\rho
+
q_2(t)\rho^2.
\]

由于 CML 最小化 residual 等价于最大化 projected energy，条件驻点为：

\[
\boxed{
\rho_{\rm AML}(t)
=
-\frac{q_1(t)}{2q_2(t)}
}
\]

这正是 Bonacci：

\[
\Delta\sin\theta_{\rm ACML}
\approx
-\frac{\alpha_1}{2\alpha_2}
\]

在当前一般曲线上的对应式。

### 7.2 数值有效合同

只有同时满足以下条件时，anchor 才产生 raw AML 候选：

```text
rank(B0) = 2

q0/q1/q2 finite

q2 < -64*eps(max(1,abs(q0)))

rho_AML finite

rho_AML >= rho_min_deg

rho_AML <= rho_max(t)

rho_AML <= rho_close_contract_max_deg
```

固定：

```text
rho_min_deg = 1e-3
rho_close_contract_max_deg = 0.35
```

理由：

```text
当前路线只处理 close-pair；
注册 truth 最大分离为 0.30 deg；
0.35 deg 仅提供固定边界余量；
不得根据结果修改。
```

禁止：

```text
把 rho_AML clamp 到下界或上界后继续；
在 q2>=0 时强行用边界；
设置 truth-dependent rho 区间。
```

不满足时，该 anchor 为：

```text
CONDITIONAL_RHO_INVALID
```

### 7.3 几何可行上界

直线：

\[
\xi(t)
=
c_0+t u
\]

与矩形 local domain 的交集给出：

\[
t\in[t_{\min},t_{\max}].
\]

对于 anchor \(t\)：

\[
\rho_{\max}(t)
=
t_{\max}-t.
\]

最终使用：

\[
\rho_{\rm feasible,max}
=
\min[
\rho_{\max}(t),
0.35^\circ
].
\]

---

## 8. 一维锚点搜索和精确完整流形评分

### 8.1 精确候选评分

对每个有效 \(t\)：

1. 计算：
   \[
   \rho_{\rm AML}(t).
   \]
2. 构造：
   \[
   \xi_1=\xi(t),
   \qquad
   \xi_2=\xi(t+\rho_{\rm AML}(t)).
   \]
3. 使用：
   ```text
   build_full_sequential_local_manifold
   concentrated_dml_rss
   ```
   计算完整、非 Taylor 的 K2 likelihood。
4. 只有：
   ```text
   rank_Gseq = 2
   RSS/loglik finite
   ```
   才是有效候选。

Taylor 展开只用于条件求 \(\rho\)，最终评分必须是完整流形 CML。

### 8.2 锚点扫描

固定：

```text
anchor_scan_node_count = 65
anchor_fminbnd_TolX_deg = 1e-4
anchor_fminbnd_MaxFunEvals = 80
```

在：

\[
[t_{\min},t_{\max}-\rho_{\min}]
\]

上扫描 65 个等距 anchor。

选择精确 likelihood 最大的有效节点。

若该节点左右存在有效邻居，则以邻居形成 bracket，运行：

```text
fminbnd
```

目标函数：

```text
对给定 t：
→ 解析方向导数
→ projector expansion
→ rho_AML(t)
→ exact full-manifold loglik
```

若 bracket 中出现无效 anchor，则返回大惩罚值；不扩展到第二维。

最终候选集：

```text
best coarse anchor
bracket endpoints
fminbnd anchor
```

按精确 full-manifold loglik 选择最大值。

### 8.3 最终参数

\[
\widehat t
=
\arg\max_t
J_{\rm exact}
(t,\rho_{\rm AML}(t)).
\]

\[
\widehat\rho
=
\rho_{\rm AML}(\widehat t).
\]

\[
\widehat\xi_1
=
c_0+\widehat t\,u,
\]

\[
\widehat\xi_2
=
c_0+(\widehat t+\widehat\rho)u.
\]

等效中心偏移：

\[
\boxed{
\widehat\alpha
=
\widehat t+\frac{\widehat\rho}{2}
}
\]

这使算法能够沿 Tangent 轴修正不等功率导致的 K1 中心偏移。

---

## 9. 安全输出

固定基线：

```text
CORE_LITE fixed-grid known-K K2
```

若 Anchored-AML raw candidate：

```text
valid
且
loglik_anchored >= loglik_fixed
```

则输出：

```text
VINCENT_ANCHORED_AML_UPGRADE
```

否则：

```text
FIXED_GRID_FALLBACK
```

不得在拟合/选择中读取：

```text
truth
RMSE
profile ID
SNR
L
noise type
secondary power
correlation
P1/P2/P3/P4
```

本 V1 不把当前 Tangent candidate 加入同一 safe candidate pool，以避免形成新的多路径规则堆叠。

---

## 10. 与当前 Tangent 的关系

当前 Tangent：

```text
固定 c0 为 pair center
只搜索 rho
```

新 Anchored-AML：

```text
固定 Tangent axis u
搜索 anchor t
rho 由 projector expansion 条件闭式给出
```

参数关系：

```text
当前 Tangent：
t = -rho/2
alpha = 0

新 Anchored-AML：
t 自由
alpha = t + rho/2 自由
```

与 Full4D 的关系：

```text
Anchored-AML：
固定数据驱动轴，只允许两个 endpoint 沿轴移动；
数值搜索维数 1。

Full4D：
中心、方向、尺度全部自由；
数值搜索维数 4。
```

因此新方法是：

```text
当前 Tangent 与 Full4D 之间的低维 bias–variance 折中，
但其 rho 不是二维暴力搜索，而是 Vincent 式条件闭式 profile。
```

---

## 11. 新代码路径

只允许新增：

```text
tools/stage8_k2_vincent_anchored_aml/
```

建议结构：

```text
tools/stage8_k2_vincent_anchored_aml/
├── README.md
├── matlab/
│   ├── stage8_k2_va_constants.m
│   ├── stage8_k2_va_add_paths.m
│   ├── stage8_k2_va_build_context.m
│   ├── stage8_k2_va_build_registry.m
│   ├── stage8_k2_va_generate_trial.m
│   ├── stage8_k2_va_directional_derivatives.m
│   ├── stage8_k2_va_projector_expansion.m
│   ├── stage8_k2_va_conditional_rho.m
│   ├── stage8_k2_va_anchor_profile.m
│   ├── stage8_k2_va_fit_safe.m
│   ├── stage8_k2_va_evaluate_trial.m
│   ├── stage8_k2_va_metrics.m
│   ├── stage8_k2_va_summarize.m
│   ├── stage8_k2_va_run.m
│   └── stage8_k2_va_stable_hash.m
└── tests/
    ├── test_cylindrical_directional_derivatives.m
    ├── test_projector_expansion_order.m
    ├── test_conditional_rho_synthetic_curve.m
    ├── test_anchor_parameterization_contract.m
    └── test_one_trial_no_truth_smoke.m
```

只读调用：

```text
Step12.7 public/core functions
tools/stage8_k2_tangent_profile
tools/stage8_k2_classical_baselines
Stage7/Stage8 frozen manifold and noise functions
```

不得修改上述已有文件。

---

## 12. 最小理论测试

### 12.1 圆柱阵方向导数

在一个冻结物理 measurement model 上，选择 3 个内部角点和 3 个不同轴方向。

验证：

\[
h(t+\delta)
=
h_0
+
\delta h_1
+
\frac{\delta^2}{2}h_2
+
\frac{\delta^3}{6}h_3
+
O(\delta^4).
\]

使用：

```text
delta = 0.02 deg
delta/2
delta/4
```

要求 Taylor residual 随步长减半，误差比接近 16；只检查四阶收敛趋势，不用 truth 场景。

### 12.2 投影展开阶数

对实际圆柱阵 curve：

\[
P_{\rm exact}(\rho)
-
(P_0+\rho P_1+\rho^2P_2)
=
O(\rho^3).
\]

使用：

```text
rho = 0.02 / 0.01 / 0.005 deg
```

要求误差随步长减半约下降 8 倍。

同时检查：

```text
P0/P1/P2 Hermitian
P0 idempotent
rank(B0)=2
```

### 12.3 合成条件 rho

构造一个已知光滑复向量曲线，生成高 SNR/noiseless：

```text
Z = [h(t_true),h(t_true+rho_true)]S
```

要求：

```text
conditional rho finite
q2 < 0
rho error 明显小于 coarse line interval
exact candidate valid
```

该 fixture 不作为真实性能证据。

### 12.4 参数化合同

随机生成合法 \(t,\rho\)，验证：

\[
\alpha=t+\rho/2,
\]

以及：

\[
c_0+t u
=
c_0+\alpha u-\rho u/2,
\]

\[
c_0+(t+\rho)u
=
c_0+\alpha u+\rho u/2.
\]

### 12.5 Truth isolation smoke

使用一个仓库外 trial：

```text
P2, L=4, SNR=0, WHITE
```

检查：

```text
fit 不读取 truth
anchor/rho 来自 data only
exact full manifold used
safe fallback 有效
```

不设性能门。

测试通过后直接运行一次正式实验，不建立新的 F0/F1 或证据框架。

---

## 13. 独立 72-trial 验证

为避免针对原 72 行数据进行后验过拟合，使用与 P1–P4 相同的因子设计，但采用全新 seeds。

因素：

```text
noise ∈ {
  WHITE,
  STAGE5_TOEPLITZ_CORRELATED
}

L ∈ {1,4,8}

SNR ∈ {-6,0,+6} dB

profile ∈ {P1,P2,P3,P4}
```

Profiles 保持不变：

| Profile | Center [az,el] | Separation | Direction | Secondary power | Correlation for L>1 |
|---|---|---:|---:|---:|---:|
| P1 | [8.00,10.00] | 0.30° | 45° | 0 dB | 0 |
| P2 | [8.20,10.00] | 0.20° | 0° | -6 dB | 0 |
| P3 | [7.90,10.10] | 0.15° | 90° | 0 dB | 0.9 |
| P4 | [8.10,9.95] | 0.10° | 135° | -6 dB | 0.9 |

总数：

```text
72 K2 trials
```

新 seed：

```text
source seed base = 3726074000
noise seed base  = 3726075000
```

每 trial 唯一。

`L=1` 继续使用：

```text
L1_FULLY_COHERENT_BY_CONTRACT
```

场景：

```text
single CPI
single range-Doppler cell
known K=2
no tracking
no cross-CPI
```

---

## 14. 正式方法

同一 `Y_element` 上运行：

```text
M0 = CORE_LITE
M1 = TANGENT_PROFILE_SAFE
M2 = VINCENT_ANCHORED_PROJECTOR_AML_SAFE
M3 = FULL4D_BEAMSPACE_CML_MULTISTART
```

### M0

冻结 Step12.7 Core-Lite，作为 fixed-grid 安全基线。

### M1

冻结当前 Tangent-Profile 实现，不修改。

### M2

本协议的新方法。

### M3

只读复用 classical-baselines 分支已实现的 Full4D Beamspace CML 数值基线。

M3 只作诊断：

```text
不参与 M2 safe selection；
不作为 truth oracle；
不调新预算。
```

结果：

```text
72 × 4 = 288 method rows
72 Anchored diagnostics
```

---

## 15. Anchored diagnostics

逐 trial 保存：

```text
trial_id
element_trial_hash

K1_center_deg
tangent_axis_hat
axis_status

line_t_min_deg
line_t_max_deg

raw_anchor_valid_count
anchor_scan_node_count

selected_t_deg
selected_rho_deg
selected_alpha_deg

q0
q1
q2
curvature_valid_flag

B0_rank
B0_condition
projector_expansion_status

raw_candidate_valid
raw_candidate_angles
raw_candidate_loglik
raw_candidate_RSS

upgrade_flag
fallback_flag
fallback_reason

center_error_deg
axis_error_deg
rho_error_deg
rho_relative_error
separation_vector_error_deg
joint_RMSE_deg

score_call_count
SVD_call_count
runtime_sec

truth_used_in_fit_flag
```

truth-only 字段只在拟合完成后计算。

---

## 16. 汇总指标

每种方法报告：

```text
valid count
joint RMSE median/p90
center error median/p90
axis error median/p90
rho error median/p90
separation-vector error median/p90
score/SVD mean
runtime median/p90
```

分层：

```text
P1–P4
SNR
L
noise
```

重点比较：

```text
M2 vs M1 overall
M2 vs M1 P2
M2 vs M1 P4
M2 vs M3
```

配对：

```text
wins/ties/losses
tie tolerance = 1e-6 deg
```

只用于展示。

同时报告：

```text
selected alpha median/p90
P2 alpha 的符号和幅度
conditional rho invalid count
q2 nonconcave count
rho out-of-contract count
```

不得新增 bootstrap 或 resolved threshold。

---

## 17. 一次性决策

### RETAIN

同时满足：

```text
M2 safe valid = 72/72

overall median joint RMSE M2 <= M1

overall p90 joint RMSE M2 <= M1

M2 vs M1 wins >= losses

P2 median joint RMSE M2 < M1

P2 median center error M2 < M1

mean score calls M2 < mean score calls M3

mean SVD calls M2 < mean SVD calls M3
```

结论：

```text
STAGE8_K2_VINCENT_ANCHORED_AML_RETAIN
```

### NOT RETAINED

其他完整、有效结果：

```text
STAGE8_K2_VINCENT_ANCHORED_AML_NOT_RETAINED
```

### EXPERIMENT INVALID

仅用于：

```text
trial/hash mismatch
truth leakage
existing frozen code changed
registry/seed mismatch
scientific output nonfinite and fixed fallback unavailable
```

结论：

```text
STAGE8_K2_VINCENT_ANCHORED_AML_EXPERIMENT_INVALID
```

禁止根据结果调整：

```text
rho max
anchor nodes
derivative formulas
q2 condition
profiles
seeds
safe selection
```

---

## 18. 一次性停止边界

完成本 V1 后，禁止继续增加：

```text
第二 Tangent 轴
垂直轴偏移
二维 anchor 网格
四阶 projector expansion
第三阶 rho 多根选择
多个 anchor start families
Anchored + Tangent + Full4D 多路径融合
automatic K
bootstrap
更多 trials
V2
```

若 RETAIN：

```text
只作为候选结果保留；
不得自动修改 Step12.7 或原 Tangent 生产接口；
后续集成需要用户单独授权。
```

若 NOT RETAINED：

```text
保留负结果并停止。
```

---

## 19. 文档与输出

新增：

```text
innovation-mining/
35_stage8_k2_vincent_anchored_aml_theory_and_protocol.md

36_stage8_k2_vincent_anchored_aml_experiment.md

36_stage8_k2_vincent_anchored_aml_trials.csv

36_stage8_k2_vincent_anchored_aml_summary.csv

36_stage8_k2_vincent_anchored_aml_profile_summary.csv

36_stage8_k2_vincent_anchored_aml_diagnostics.csv

36_stage8_k2_vincent_anchored_aml_complexity.csv
```

新增 prompt：

```text
innovation-mining/stage8_execution_prompts/active/
015_stage8_k2_vincent_anchored_aml_v1.md
```

---

## 20. 执行方式

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
复杂 checkpoint/protocol
```

Runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_vincent_anchored_aml_v1
```

先运行理论单元测试和 1 个 smoke。

随后一次运行 72 trial。

若计算中断：

```text
不建立新恢复框架；
删除本轮未提交 runtime；
从头执行。
```

---

## 21. 提交顺序

### 21.1 设计提交

新增：

```text
35 theory/protocol
015 prompt
active README
```

提交：

```text
docs(stage8-k2): define Vincent anchored AML experiment
```

首次推送：

```powershell
git push -u origin experiment/stage8-k2-vincent-anchored-aml-v1
```

### 21.2 工具提交

只提交：

```text
tools/stage8_k2_vincent_anchored_aml/
```

提交：

```text
feat(stage8-k2): add Vincent-inspired anchored projector AML
```

### 21.3 结果提交

提交：

```text
36_stage8_k2_vincent_anchored_aml_*
```

将 015 归档至：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

active README：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_K2_VINCENT_ANCHORED_AML_V1_COMPLETED
```

提交：

```text
docs(stage8-k2): record Vincent anchored AML result
```

只推送新分支。

---

## 22. 最终审计

确认：

```text
new branch HEAD == origin new branch
Git clean

origin/experiment/stage8-k2-classical-baselines-v1
==
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

origin/experiment/stage8-k2-tangent-profile-v1
==
721c30aa96f1687c757004613c23e9fb6a814afd

origin/experiment/stage8-core-v2
==
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/main
==
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

检查已有：

```text
31/32/33/34 evidence
Step12.7
Tangent tools
classical-baseline tools
```

相对 `bdb2a51` 无修改。

---

## 23. 最终报告格式

```text
STAGE8_K2_VINCENT_ANCHORED_AML_COMPLETE

Branch:
Base:
Design commit:
Tool commit:
Result commit:
Push:
Git clean:

Original branches unchanged:
- classical baseline
- Tangent
- Core-V2
- main

Theory tests:
- cylindrical derivative Taylor order
- projector O(rho^3)
- synthetic conditional rho
- anchor parameterization
- no-truth smoke

Registry:
- 72/72 trials
- 288/288 method rows
- 72/72 diagnostics

Tangent:
- median/p90 joint RMSE
- P2/P4 metrics
- score/SVD/runtime

Vincent Anchored AML:
- raw valid
- upgrades/fallbacks
- conditional invalid reasons
- median/p90 joint/center/axis/rho/vector
- P1–P4
- selected alpha
- score/SVD/runtime

Full4D Beamspace CML:
- diagnostic comparison only

Paired:
- Anchored vs Tangent
- Anchored vs Full4D

Final conclusion:
Prior-art positioning:
Production integration authorized:
false
```

完成后停止。
