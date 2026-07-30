# Stage8-K2-TP1：投影残差 Fisher 度量切向方向与一维全流形 Profile-Likelihood 实验（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b 与 Git 的执行 AI。
>
> 本协议从已经完成最终冻结的 `experiment/stage8-core-v2` 精确分叉，建立一个全新的 K2 理论驱动探索分支。原 `experiment/stage8-core-v2`、`main`、Step12.7、最终 `29_*` 证据和现有 Core-Lite/Core-Plus 均保持只读。
>
> 本路线不是 Core-V3，不恢复 automatic K，不修改已有生产接口；它只评价一个新的 K2 候选：
>
> ```text
> K1 continuous fit 给中心
> → 投影残差 + Fisher 度量给二维分离方向
> → 一维 full-manifold profile likelihood 给分离尺度
> → 与 fixed-grid K2 做安全似然选择
> ```
>
> 协议：
>
> ```text
> STAGE8_K2_TANGENT_PROFILE_DECISIVE_EXPERIMENT_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_TANGENT_PROFILE_DECISIVE_EXPERIMENT_V1
> ```

---

## 0. 当前基线分支的准确定位

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

稳定主线：

```text
branch:
main

tip:
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

已冻结的 known-K 探索基线：

```text
branch:
experiment/stage8-core-v2

tip:
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

commit title:
docs(stage8): close final known-k innovation scope
```

`9bcb4f7` 是 docs-only 收束提交。该分支当前已形成：

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_PASS_CORE_PLUS_OPTIONAL

F0/F1A/F1B:
PASS

live in-memory production regression:
24/24 PASS

independent validation:
K1 72/72
K2 72/72
288/288 rows
144/144 checkpoints
```

当前冻结算法：

```text
Core-Lite:
K=1:
  fixed-grid K1
  → conventional continuous full-sequential refinement
  → validity/loglik safe selection

K=2:
  fixed-grid known-K K2

Core-Plus:
K=1:
  与 Core-Lite 相同

K=2:
  fixed-grid K2
  + grouped/conditional starts
  + center-difference continuous refinement
  + safe likelihood fallback
```

最终 K2 证据：

```text
Core-Plus vs Core-Lite:
26 wins / 33 ties / 13 losses

continuous upgrades / fallbacks:
39 / 33

overall median RMSE:
两者均约 0.141681 deg

Core-Plus p90:
0.361642 deg

Core-Plus mean score/SVD:
约 1445 / 2927
```

因此现有 Core-Plus 是：

```text
OPTIONAL K2 RESCUE
```

不是稳定优于 Core-Lite 的默认方法。

---

## 1. 新分支创建与隔离

### 1.1 Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags

git status --porcelain=v1 --untracked-files=all
git rev-parse origin/main
git rev-parse origin/experiment/stage8-core-v2
```

要求：

```text
工作树 clean

origin/main
==
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/experiment/stage8-core-v2
==
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7
```

若原实验分支已由用户明确推进为 `9bcb4f7` 的 docs-only 后代：

- 停止；
- 报告实际 SHA；
- 不自行选择新起点。

### 1.2 新分支名称

新路线唯一分支：

```text
experiment/stage8-k2-tangent-profile-v1
```

先确认远端和本地均不存在同名分支：

```powershell
git show-ref --verify --quiet `
  refs/heads/experiment/stage8-k2-tangent-profile-v1

git show-ref --verify --quiet `
  refs/remotes/origin/experiment/stage8-k2-tangent-profile-v1
```

若任一存在，硬停止，不覆盖、不 force-push。

### 1.3 从精确提交分叉

执行：

```powershell
git switch --detach `
  9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

git switch -c experiment/stage8-k2-tangent-profile-v1
```

确认：

```powershell
git rev-parse HEAD
git merge-base --is-ancestor `
  9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7 `
  HEAD
```

初始 HEAD 必须精确为 `9bcb4f7`。

### 1.4 永久隔离规则

本协议中禁止：

```text
push main
push experiment/stage8-core-v2
merge experiment/stage8-core-v2
rebase experiment/stage8-core-v2
force push
修改 origin/main
修改原 experiment 分支 ref
```

每次推送后必须确认：

```powershell
git rev-parse origin/main
git rev-parse origin/experiment/stage8-core-v2
```

二者必须分别保持：

```text
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7
```

---

## 2. 本路线的唯一科学问题

当前只研究：

> 在单 CPI、单距离–多普勒单元、已知 \(K=2\) 的局部角域中，能否利用已经验证的顺序流形投影 Jacobian 几何，从 K1 投影残差中直接估计双目标分离方向，并将原四维 K2 连续搜索约化为一维分离尺度 profile-likelihood 搜索，在不降低安全返回率的前提下改善 K2 精度或显著降低 Core-Plus 计算量？

本路线不研究：

```text
K=1
automatic K
目标检测
航迹
跨 CPI
bootstrap
resolved/unresolved
波束重新选择
K=3
Stage8.2
```

场景固定为：

```text
single CPI
single selected range-Doppler cell
one frozen local angular cell
known K=2
fixed sequential measurement
fixed whitening
```

---

## 3. 理论推导

### 3.1 白化顺序双目标模型

令固定白化顺序流形为：

\[
g(\boldsymbol\xi),
\qquad
\boldsymbol\xi=
\begin{bmatrix}
\phi\\
\theta
\end{bmatrix}.
\]

两个近邻目标写成：

\[
\boldsymbol\xi_1
=
\mathbf c-\frac{\mathbf d}{2},
\qquad
\boldsymbol\xi_2
=
\mathbf c+\frac{\mathbf d}{2}.
\]

白化观测矩阵：

\[
Z
=
g(\boldsymbol\xi_1)\mathbf s_1^T
+
g(\boldsymbol\xi_2)\mathbf s_2^T
+
N.
\]

定义和模与差模波形：

\[
\mathbf a
=
\mathbf s_1+\mathbf s_2,
\qquad
\mathbf b
=
\mathbf s_2-\mathbf s_1.
\]

在 \(\mathbf c\) 附近展开：

\[
g\left(\mathbf c\pm\frac{\mathbf d}{2}\right)
=
g(\mathbf c)
\pm
\frac12J_g(\mathbf c)\mathbf d
+
\frac18H_g(\mathbf c)[\mathbf d,\mathbf d]
+
O(\|\mathbf d\|^3).
\]

代入得到：

\[
\boxed{
Z
=
g(\mathbf c)\mathbf a^T
+
\frac12J_g(\mathbf c)\mathbf d\,\mathbf b^T
+
\frac18H_g(\mathbf c)[\mathbf d,\mathbf d]\mathbf a^T
+
O(\|\mathbf d\|^3)
+
N
}
\]

其中：

```text
第一项：
等效单目标中心分量

第二项：
一阶双目标分离分量

第三项：
二阶流形曲率分量
```

### 3.2 用 K1 fit 消除中心分量

使用现有 Core-Lite K1 路径，在同一 K2 数据上拟合最佳单目标中心：

\[
\widehat{\mathbf c}.
\]

记：

\[
g
=
g(\widehat{\mathbf c}),
\]

\[
\Pi_g^\perp
=
I-\frac{gg^H}{g^Hg},
\]

\[
B
=
\Pi_g^\perp
J_g(\widehat{\mathbf c}).
\]

投影残差：

\[
R
=
\Pi_g^\perp Z.
\]

一阶近似：

\[
\boxed{
R
\approx
\frac12B\mathbf d\,\mathbf b^T
+
N_\perp
}
\]

因此 residual 的主空间方向应沿 \(B\mathbf d\)。

### 3.3 Fisher 度量和切向残差矩阵

定义：

\[
T
=
\operatorname{Re}
\{B^HB\}.
\]

这与当前已经验证的：

\[
T_{\rm seq}
=
\operatorname{Re}
\{J_g^H\Pi_g^\perp J_g\}
\]

一致。

残差样本协方差：

\[
S_R
=
\frac1L RR^H.
\]

定义切向残差矩阵：

\[
C_t
=
\operatorname{Re}
\{B^HS_RB\}.
\]

对任意实二维方向 \(\mathbf u\)，定义：

\[
\mathcal J(\mathbf u)
=
\frac{
\mathbf u^TC_t\mathbf u
}{
\mathbf u^TT\mathbf u
}.
\]

在无噪声一阶模型下：

\[
R
=
\frac12B\mathbf d\,\mathbf b^T.
\]

于是：

\[
\mathcal J(\mathbf u)
=
\frac{p_-}{4}
\frac{
|(B\mathbf u)^H(B\mathbf d)|^2
}{
\|B\mathbf u\|_2^2
},
\]

其中：

\[
p_-
=
\frac1L
\|\mathbf s_2-\mathbf s_1\|_2^2.
\]

由 Cauchy–Schwarz：

\[
|(B\mathbf u)^H(B\mathbf d)|^2
\le
\|B\mathbf u\|_2^2
\|B\mathbf d\|_2^2.
\]

若 \(B\) 满列秩，等号只在：

\[
\mathbf u\parallel\mathbf d
\]

时成立。

因此分离方向由最大广义特征向量给出：

\[
\boxed{
C_t\widehat{\mathbf u}
=
\lambda_{\max}
T\widehat{\mathbf u}
}
\]

### 3.4 白噪声只产生广义特征值平移

白化后：

\[
\mathbb E[N_\perp N_\perp^H/L]
=
\sigma^2\Pi_g^\perp.
\]

因为 \(B=\Pi_g^\perp J_g\)：

\[
\operatorname{Re}
\{B^H(\sigma^2\Pi_g^\perp)B\}
=
\sigma^2T.
\]

因此：

\[
C_t
=
C_{\rm signal}
+
\sigma^2T.
\]

广义特征问题变为：

\[
(C_{\rm signal}+\sigma^2T)\mathbf u
=
\lambda T\mathbf u.
\]

噪声只使广义特征值整体平移，不改变期望中的广义特征向量。

本算法不估计或减去噪声底，也不增加 eigen-gap threshold。

### 3.5 数值稳定形式

对：

\[
T=V\Lambda V^T
\]

执行现有相对数值秩判定。

只有：

```text
rank(T) = 2
```

时才构造：

\[
Q
=
V\Lambda^{-1/2}.
\]

白化后的实对称矩阵：

\[
M
=
Q^TC_tQ.
\]

取最大特征向量 \(\mathbf w_{\max}\)，然后：

\[
\widehat{\mathbf u}
=
Q\mathbf w_{\max}.
\]

归一化：

\[
\|\widehat{\mathbf u}\|_2=1.
\]

符号约定：

```text
u_el > 0

若 abs(u_el) <= 1e-12：
u_az >= 0
```

若 \(T\) 数值秩不足 2，则 tangent candidate 无效并安全回退，不增加其他方向 start。

### 3.6 一维分离尺度搜索

定义：

\[
\mathbf d(\rho)
=
\rho\widehat{\mathbf u},
\qquad
\rho>0.
\]

候选 endpoints：

\[
\boldsymbol\xi_1(\rho)
=
\widehat{\mathbf c}
-
\frac{\rho}{2}\widehat{\mathbf u},
\]

\[
\boldsymbol\xi_2(\rho)
=
\widehat{\mathbf c}
+
\frac{\rho}{2}\widehat{\mathbf u}.
\]

根据冻结 local-domain bounds 计算唯一的 \(\rho_{\max}\)，保证两个 endpoint 均在域内。

固定：

```text
rho_min_deg = 1e-3
scan_node_count = 33
```

在：

\[
[\rho_{\min},\rho_{\max}]
\]

上先计算 33 个等距节点的完整 K2 concentrated likelihood。

在最佳节点及其相邻节点构成的 bracket 内使用：

```text
fminbnd
```

固定：

```text
TolX = 1e-4 deg
MaxFunEvals = 80
```

统一比较：

```text
最佳 scan node
bracket 两端
fminbnd candidate
```

选择 concentrated log-likelihood 最大者。

最终评分必须使用：

```text
完整顺序白化流形
真实 K2 rank contract
真实 concentrated DML
```

Taylor 展开只用于确定分离方向，不替代最终流形。

### 3.7 安全回退

基准候选：

```text
Core-Lite fixed-grid known-K K2
```

若 tangent-profile candidate：

```text
有效
且 loglik_tangent >= loglik_fixed
```

则输出：

```text
TANGENT_PROFILE_UPGRADE
```

否则：

```text
FIXED_GRID_FALLBACK
```

该选择不得读取：

```text
truth
RMSE
profile ID
SNR
L
noise type
q
Gamma_K2
direction error
```

### 3.8 局部可辨识强度

已有几何量：

\[
q
=
\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d.
\]

它只描述阵列、顺序 measurement、白化、中心和分离方向的几何可分性。

定义：

\[
p_-
=
\frac1L
\|\mathbf s_2-\mathbf s_1\|_2^2.
\]

局部一阶信息强度具有乘积结构：

\[
\boxed{
\Gamma_{\rm K2}
=
\frac{Lp_-}{2\sigma^2}
\mathbf d^TT_{\rm seq}(\mathbf c)\mathbf d
}
\]

在注册白化模型中可用 \(\sigma^2=1\) 形成 truth-only 分析量：

\[
\Gamma_{\rm K2,proxy}
=
\frac12
\|\mathbf s_2-\mathbf s_1\|_2^2
q.
\]

该量只用于解释：

```text
方向误差
尺度误差
candidate validity
upgrade/fallback
RMSE
```

不得用于在线 threshold 或删除 trial。

### 3.9 理论失效边界

若：

\[
\mathbf s_1\approx\mathbf s_2,
\]

则：

\[
p_-\approx0.
\]

一阶项：

\[
\frac12B\mathbf d\,\mathbf b^T
\]

接近消失，只剩：

\[
\frac18
\Pi_g^\perp
H_g[\mathbf d,\mathbf d]\mathbf a^T.
\]

其振幅为：

\[
O(\|\mathbf d\|^2),
\]

相应信息通常为：

\[
O(\|\mathbf d\|^4).
\]

这属于内在非正则性，不允许通过继续增加中心偏移、第二方向、二阶 solver 或更多 start 来补救。

另一个边界是 K1 单目标拟合中心不一定等于不等功率双目标的几何中点。本 V1 不增加中心修正参数。

---

## 4. 相关论文与新颖性边界

必须在设计文档中引用并讨论：

### 4.1 两近邻源近似 ML

François Vincent, Olivier Besson, Eric Chaumette,

“Approximate maximum likelihood estimation of two closely spaced sources,”

*Signal Processing*, Vol. 97, 2014, pp. 83–90.

DOI:

```text
10.1016/j.sigpro.2013.10.017
```

已有内容：

```text
近邻双源
Taylor 展开
近似 conditional ML
低维/一维计算
单快拍和相关源场景
```

### 4.2 非均匀阵列的一维近似 CML

Bonacci et al.,

“Robust DoA estimation in case of multipath environment for a sense and avoid airborne radar,”

*IET Radar, Sonar & Navigation*, 2017.

DOI:

```text
10.1049/iet-rsn.2016.0446
```

已有内容：

```text
将两个近邻源的 Taylor 近似 CML
从 ULA 推广到非均匀线阵
把二维最小化化简为一维搜索
```

### 4.3 Partial Relaxation

Minh Trinh-Hoang, Mats Viberg, Marius Pesavento,

“Partial Relaxation Approach: An Eigenvalue-Based DOA Estimator Framework,”

arXiv:

```text
1711.01982
```

已有内容：

```text
通过结构放松将多源高维 DML/WSF/协方差拟合
降成谱搜索或低维搜索
```

### 4.4 波束域双目标

J. Kim, H. J. Yang, N. Kwak,

“Low-angle tracking of two objects in a three-dimensional beamspace domain,”

*IET Radar, Sonar & Navigation*, 2012.

DOI:

```text
10.1049/iet-rsn.2010.0163
```

已有内容：

```text
三维 beamspace 中的两个目标
附加目标/干扰使低维 beamspace 性能退化
```

### 4.5 当前允许的新颖性表述

在未完成专门 prior-art 检索前，只允许称为：

> 在固定精确白化的实际二维顺序波束流形上，利用 K1 投影残差构造 Fisher 度量广义特征方向，并沿该方向执行一维完整流形 profile-likelihood 的 K2 候选方法。

禁止称为：

```text
首次提出 Taylor 近似 ML
首次将 K2 搜索降为一维
首次使用导数流形
首次使用广义特征值 DOA
首次提出 close-source ML
```

设计文档必须建立一个简短 prior-art matrix，至少比较：

```text
Vincent 2014
Bonacci 2017
Partial Relaxation
当前 K2-Tangent-Profile
```

维度：

```text
阵列/流形类型
是否 beamspace
是否固定白化
方向估计方式
尺度搜索方式
最终是否使用完整流形 likelihood
是否需要多个 starts
```

若找到完全相同的组合，则将本路线定位为：

```text
SYSTEM-SPECIFIC IMPLEMENTATION / ENGINEERING SPECIALIZATION
```

不宣称新算法。

---

## 5. 代码与文档路径

只允许新增：

```text
tools/stage8_k2_tangent_profile/
```

建议：

```text
tools/stage8_k2_tangent_profile/
├── README.md
├── matlab/
│   ├── stage8_k2_tp_constants.m
│   ├── stage8_k2_tp_build_context.m
│   ├── stage8_k2_tp_build_registry.m
│   ├── stage8_k2_tp_projected_direction.m
│   ├── stage8_k2_tp_profile_scale.m
│   ├── stage8_k2_tp_evaluate_trial.m
│   ├── stage8_k2_tp_run_experiment.m
│   ├── stage8_k2_tp_summarize.m
│   └── stage8_k2_tp_stable_hash.m
└── tests/
    ├── test_tangent_direction_noiseless.m
    ├── test_tangent_direction_noise_shift.m
    ├── test_tangent_rank_deficiency.m
    └── test_one_trial_full_manifold_smoke.m
```

只允许新增文档：

```text
innovation-mining/
30_stage8_k2_tangent_profile_theory_and_design.md

innovation-mining/
31_stage8_k2_tangent_profile_decisive_experiment.md

innovation-mining/
31_stage8_k2_tangent_profile_trials.csv

innovation-mining/
31_stage8_k2_tangent_profile_summary.csv

innovation-mining/
31_stage8_k2_tangent_profile_geometry_analysis.csv

innovation-mining/
31_stage8_k2_tangent_profile_complexity.csv

innovation-mining/stage8_execution_prompts/active/
013_stage8_k2_tangent_profile_decisive_v1.md
```

允许在新分支更新：

```text
innovation-mining/stage8_execution_prompts/active/README.md
```

不得修改：

```text
beamspace_ml_v18/source/.../step_12_7_known_k_local_cell_refinement/**
innovation-mining/29_*
innovation-mining/11_*
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
tools/stage8_core_v2_known_k/**
tools/stage8_r1_continuous_decisive/**
origin/experiment/stage8-core-v2
origin/main
```

当前冻结 Core-Lite/Core-Plus 和 Step12.7 只能作为只读 baseline 调用。

---

## 6. 最小必要测试

本路线只设置两个科学入口检查，不建立新的 F0/F1、进程审计、runtime 协调器或多层 Gate。

### T0：解析边界

检查：

```text
当前分支精确为 experiment/stage8-k2-tangent-profile-v1
9bcb4f7 是祖先
origin/experiment/stage8-core-v2 仍为 9bcb4f7
origin/main 仍为 247fad
工作树 clean
Step12.7 与 9bcb4f7 无 diff
29_* 与 9bcb4f7 无 diff
```

失败即停止。

### T1：理论单元测试

#### 无噪声方向恢复

人工构造满列秩复矩阵 \(B\)、实非零 \(\mathbf d\)、非零差模 \(\mathbf b\)：

\[
R
=
\frac12B\mathbf d\,\mathbf b^T.
\]

要求：

\[
\left|
\widehat{\mathbf u}^T
\frac{\mathbf d}{\|\mathbf d\|}
\right|
\ge
1-10^{-12}.
\]

#### 各向同性噪声平移

构造：

\[
C_t^{(2)}
=
C_t^{(1)}
+
\alpha T,
\qquad
\alpha>0.
\]

要求两个最大广义特征方向满足：

\[
|\widehat{\mathbf u}_1^T\widehat{\mathbf u}_2|
\ge
1-10^{-12}.
\]

#### 秩不足

构造：

```text
rank(T) < 2
```

必须返回：

```text
TANGENT_METRIC_RANK_DEFICIENT
```

并不得生成方向。

#### 一个完整流形 smoke

只使用一个仓库外合成 K2 trial，检查：

```text
不使用 truth 拟合
endpoint 在域内
profile 使用完整 K2 流形
输出 fixed-grid 或 tangent safe result
结果有限
```

这些测试通过后即运行正式 72-trial；不增加其他 Gate。

---

## 7. 独立 72-trial K2 registry

不得把现有 `29_*` 的 72 个 K2 trial 作为新方法的主结论数据。

新 registry 仍采用相同物理因子，以便与当前最终证据可比较，但使用完全新的 seeds。

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

Profiles：

| Profile | Center [az,el] | Separation | Direction | Secondary power | Correlation for L>1 |
|---|---|---:|---:|---:|---:|
| P1 | [8.00,10.00] | 0.30° | 45°  | 0 dB  | 0 |
| P2 | [8.20,10.00] | 0.20° | 0°   | -6 dB | 0 |
| P3 | [7.90,10.10] | 0.15° | 90°  | 0 dB  | 0.9 |
| P4 | [8.10, 9.95] | 0.10° | 135° | -6 dB | 0.9 |

总数：

```text
2 × 3 × 3 × 4 = 72 K2 trials
```

新 seed：

```text
source seed base = 3326074000
noise seed base  = 3326075000
```

每个 trial 使用唯一 source/noise seed。

对 `L=1`：

```text
correlation = 1
L1_FULLY_COHERENT_BY_CONTRACT
```

所有 endpoints 必须位于冻结 local domain 内。

场景 flags：

```text
single_cpi_flag = true
same_range_doppler_cell_flag = true
cross_cpi_data_used_flag = false
tracking_input_used_flag = false
K_estimated_inside_module_flag = false
```

---

## 8. 每个 trial 的三种方法

同一个 `Y_element` 上运行：

```text
M0 = CORE_LITE
M1 = CORE_PLUS
M2 = TANGENT_PROFILE_SAFE
```

### M0

直接调用冻结 Step12.7：

```text
estimate_stage8_known_k_local_cell(..., K=2, mode=CORE_LITE)
```

### M1

直接调用冻结 Step12.7：

```text
estimate_stage8_known_k_local_cell(..., K=2, mode=CORE_PLUS)
```

### M2

执行：

```text
Core-Lite K1 helper 得到中心
→ projected tangent direction
→ 1D full-manifold separation profile
→ fixed-grid K2 safe fallback
```

三种方法必须共享：

```text
同一个 Y_element
同一个 measurement
同一个 whitening
同一个 local domain
同一个 truth-only evaluation
```

总结果：

```text
72 × 3 = 216 method rows
```

另存 72 行 tangent diagnostics。

---

## 9. 结果字段

每个 method row 至少保存：

```text
trial_id
method_id
noise_profile_id
L
SNR
profile_id
element_trial_hash

fit_valid
selected_source
angles_hat_deg
RSS
loglik
joint_RMSE_deg
azimuth_RMSE_deg
elevation_RMSE_deg
separation_vector_error_deg

score_call_count
SVD_call_count
runtime_sec

truth_used_in_fit_flag
single_cpi_flag
same_range_doppler_cell_flag
cross_cpi_data_used_flag
tracking_input_used_flag
K_estimated_inside_module_flag
```

Tangent diagnostics 额外保存：

```text
K1_center_deg
K1_center_error_deg

metric_rank
metric_condition
metric_eigenvalues

direction_hat
direction_true
direction_error_deg

rho_hat_deg
rho_true_deg
rho_error_deg
rho_max_deg

raw_tangent_candidate_valid
raw_tangent_loglik
upgrade_flag
fallback_flag
fallback_reason

q
p_minus
Gamma_K2_proxy
```

truth 只允许用于运行完成后的误差和 \(\Gamma_{\rm K2}\) 分析。

---

## 10. 执行方式

使用：

```text
MATLAB R2022b
-singleCompThread
1 个 MATLAB process
```

禁止：

```text
parpool
parfor
多 worker
coordinator
scheduled task
bootstrap
复杂 checkpoint/protocol infrastructure
```

72-trial 规模应在单次会话中完成。

输出先写到仓库外：

```text
E:\bs_innovation_runtime\
stage8_k2_tangent_profile_v1
```

正式完成后一次性生成仓库内 `31_*` 文件。

若 MATLAB 会话中断：

```text
不恢复部分科学结果
清空未提交的本次 runtime
从头运行 72 trials
```

不得为这 72 个 trial 增加新的可恢复执行框架。

---

## 11. 汇总指标

### 11.1 安全有效率

三种方法：

```text
valid count / 72
```

M2 使用 fixed-grid fallback，原则上必须 72/72 valid；否则实验无效。

### 11.2 精度

报告：

```text
overall median RMSE
overall p90 RMSE
每个 P1–P4 median/p90
每个 L median
每个 SNR median
```

### 11.3 配对比较

M2 分别对 M0、M1：

```text
wins
ties
losses
```

tie：

```text
abs(RMSE_M2 - RMSE_baseline) <= 1e-6 deg
```

该容差只用于显示数值相同结果，不是算法门限。

### 11.4 方向和尺度

报告：

```text
raw tangent candidate valid count
median/p90 direction error
median/p90 rho error
median/p90 separation-vector error
```

### 11.5 计算量

报告：

```text
mean score calls
mean SVD calls
median runtime
p90 runtime
```

### 11.6 理论关联

按 `Gamma_K2_proxy` 四分位数报告：

```text
direction error
rho error
RMSE
raw candidate valid rate
fallback rate
```

只作描述，不产生阈值。

---

## 12. 唯一决策规则

### 12.1 RETAIN

同时满足：

```text
M2 valid = 72/72

median_RMSE_M2 <= median_RMSE_CORE_PLUS

p90_RMSE_M2 <= p90_RMSE_CORE_PLUS

M2_vs_CORE_PLUS wins >= losses

mean_score_calls_M2 < mean_score_calls_CORE_PLUS

mean_SVD_calls_M2 < mean_SVD_calls_CORE_PLUS
```

结论：

```text
STAGE8_K2_TANGENT_PROFILE_RETAIN
```

### 12.2 RETAIN_AS_EFFICIENT_OPTION

若不满足 RETAIN，但同时满足：

```text
M2 valid = 72/72

median_RMSE_M2 <= median_RMSE_CORE_LITE

p90_RMSE_M2 <= p90_RMSE_CORE_LITE

M2_vs_CORE_LITE wins >= losses

mean_score_calls_M2 < mean_score_calls_CORE_PLUS

mean_SVD_calls_M2 < mean_SVD_calls_CORE_PLUS
```

结论：

```text
STAGE8_K2_TANGENT_PROFILE_RETAIN_AS_EFFICIENT_OPTION
```

### 12.3 NOT_RETAINED

其他科学结果：

```text
STAGE8_K2_TANGENT_PROFILE_NOT_RETAINED
```

### 12.4 EXPERIMENT_INVALID

仅在以下情况：

```text
trial 缺失/重复
element data 未共享
truth leakage
baseline Step12.7 被修改
seed/registry 不一致
非有限科学输出且 fixed-grid fallback 未返回
```

结论：

```text
STAGE8_K2_TANGENT_PROFILE_EXPERIMENT_INVALID
```

不得通过修改 scan nodes、TolX、方向公式、profiles 或 seeds 重新运行。

---

## 13. 一次性停止规则

完成本实验后，禁止在该分支继续增加：

```text
中心偏移参数
不对称两个分离尺度
第二个 tangent direction
grouped + tangent 多路径融合
Hessian 二阶 solver
更多 starts
automatic K
bootstrap
更多 trial
新 Gate
```

若结果为 NOT_RETAINED：

```text
保留负结果
停止该路线
不创建 V2
```

若结果为 RETAIN 或 RETAIN_AS_EFFICIENT_OPTION：

```text
只记录为候选结果
不得自动修改原 Core-Lite/Core-Plus
不得合并原 experiment 分支或 main
后续集成需要用户单独授权
```

---

## 14. 提交顺序

### 14.1 设计与 prompt commit

新增：

```text
innovation-mining/
30_stage8_k2_tangent_profile_theory_and_design.md

innovation-mining/stage8_execution_prompts/active/
013_stage8_k2_tangent_profile_decisive_v1.md
```

更新新分支上的 active README：

```text
STAGE8_K2_TANGENT_PROFILE_V1_AUTHORIZED
BASE_CORE_V2_BRANCH_READ_ONLY
```

提交：

```text
docs(stage8-k2): define tangent-profile experiment
```

然后首次推送新分支：

```powershell
git push -u origin experiment/stage8-k2-tangent-profile-v1
```

验证：

```text
origin/experiment/stage8-core-v2 == 9bcb4f7
origin/main == 247fad
```

### 14.2 工具 commit

只提交：

```text
tools/stage8_k2_tangent_profile/
```

提交：

```text
feat(stage8-k2): add Fisher-metric tangent-profile candidate
```

推送新分支。

### 14.3 结果 commit

只提交：

```text
innovation-mining/31_stage8_k2_tangent_profile_*
```

将 013 prompt 移至：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

active README 最终：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_K2_TANGENT_PROFILE_V1_COMPLETED
```

提交：

```text
docs(stage8-k2): record tangent-profile decisive result
```

只推送：

```powershell
git push origin experiment/stage8-k2-tangent-profile-v1
```

---

## 15. 最终审计

必须确认：

```text
新分支 HEAD == 远端新分支
工作树 clean

origin/experiment/stage8-core-v2
==
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/main
==
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

Step12.7 与 9bcb4f7 无 diff
29_* 与 9bcb4f7 无 diff
```

报告：

```text
Branch:
Base commit:
Design commit:
Tool commit:
Result commit:
Push:
Git clean:

Original Core-V2 branch unchanged:
Main unchanged:

Theory tests:
- noiseless direction
- isotropic noise shift
- rank deficiency
- full-manifold smoke

Registry:
72/72 K2
216/216 method rows
72/72 tangent diagnostics

Core-Lite:
- valid
- median/p90 RMSE
- score/SVD/runtime

Core-Plus:
- valid
- median/p90 RMSE
- score/SVD/runtime

Tangent-Profile:
- valid
- raw candidate valid
- upgrades/fallbacks
- median/p90 RMSE
- direction error
- rho error
- score/SVD/runtime
- Gamma quartiles

Paired:
- vs Core-Lite wins/ties/losses
- vs Core-Plus wins/ties/losses

Final conclusion:
Prior-art positioning:
```

完成后停止。
