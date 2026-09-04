# Tangent-Profile Safe 算法：完整流程、理论推导、场景设定、传统方法对比与结果闭环

> 本文基于 `makabaka165/bs_innovation` 当前稳定主线整理。  
> 当前 `main`：`c5a76f19824bdbc2d34dd80f107bdf0050874da3`。  
> 当前接受的 Stage8-K2 最终源提交：`c88050b286404336ceb2019f099ec6d5cbfabbd2`。  
> 默认 K2 估计器：`TANGENT_PROFILE_SAFE`。  
>
> 本文中的数学公式采用 GitHub、Typora、Obsidian、VS Code Markdown Preview 等常用环境可识别的 LaTeX Markdown 语法：
>
> - 行内公式：`$...$`
> - 独立公式：`$$...$$`

---

# 一、现在可以怎样定位整个项目

结合当前 GitHub `main`，Stage8-K2 已经不是“仍在探索中的实验分支”，而是完成了科学算法、统一 white-SNR 验证、全经典基线比较、固定骨架缓存和圆柱阵多中心缓存收束的稳定主线。

当前 `main` 位于合并提交：

```text
c5a76f19824bdbc2d34dd80f107bdf0050874da3
```

接受的最终 K2 源提交为：

```text
c88050b286404336ceb2019f099ec6d5cbfabbd2
```

默认 K2 估计器是：

```text
TANGENT_PROFILE_SAFE
```

没有活动 Stage8 执行提示词，后续阶段被限定为论文公式、图表、适用范围和限制整理。

需要把两部分区分开：

```text
科学算法：
Tangent-Profile Safe

工程加速：
固定注册骨架 cache
+ 圆柱阵多中心旋转复用
```

后面的 cache 没有修改 Tangent 的方向估计、连续 $\rho$ profile、DML 评分和最终选择器。

---

# 二、先用两张图理解整个流程

## 2.1 它在雷达系统中的位置

```text
圆柱阵阵元接收数据
        │
        ▼
脉压、距离–多普勒处理
        │
        ▼
检测到一个距离–多普勒单元
        │
        ├── 上游给出局部角域
        └── 上游或场景条件给出 K = 2
        │
        ▼
同时形成固定的二维顺序接收波束
        │
        ▼
精确计算波束噪声协方差并白化
        │
        ▼
Tangent-Profile Safe
        │
        ▼
输出两个二维角度
[(方位1,俯仰1),(方位2,俯仰2)]
```

这里研究的不是跨 CPI 航迹，也不是在完整雷达数据中自动判断目标数量。代码结果对象明确记录：

```text
single CPI = true
same range-Doppler cell = true
cross-CPI data used = false
tracking input used = false
K estimated inside module = false
```

---

## 2.2 Tangent 内部详细流程

```text
                         同一个 Y_element
                                │
                                ▼
                 固定 W_I、C_I、T_I 白化
                                │
                                ▼
                       Z = T_I W_I^H Y
                                │
             ┌──────────────────┴──────────────────┐
             │                                     │
             ▼                                     ▼
       K1 Core-Lite                          固定网格 K2
       估计参考中心 ĉ                       安全基线 Θgrid
             │                                     │
             ▼                                     │
   计算中心流形 g(ĉ) 和 Jacobian Jg               │
             │                                     │
             ▼                                     │
  投影掉 K1 公共模态：P⊥、R、B                     │
             │                                     │
             ▼                                     │
 构造 2×2 矩阵 T 和 Ct                             │
             │                                     │
             ▼                                     │
 解广义特征值问题，得到二维分离轴 û                │
             │                                     │
             ▼                                     │
     沿 û 只搜索一个分离尺度 ρ                     │
             │                                     │
             ▼                                     │
 每个 ρ 使用完整圆柱阵流形计算 K2 likelihood       │
             │                                     │
             └──────────────┬──────────────────────┘
                            ▼
                    Safe likelihood selector
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
Tangent 有效且 likelihood 更高         否则
          │                                   │
          ▼                                   ▼
 输出 Tangent 连续角度                  输出固定网格 K2
```

可以把它直观地理解成：

> 先把两个近目标看成一个目标簇，估计目标簇的大致中心；再观察“一个目标解释不掉的残差”主要朝二维角平面的哪个方向展开；最后只沿这个方向搜索两个目标到底分开多远。

---

# 三、当前研究的具体场景是什么

## 3.1 阵列和观测接口

当前模型使用圆柱阵活动子阵：

```text
垂直层数：32
活动方位列数：65
活动阵元数：32 × 65 = 2080
```

之后通过固定顺序二维数字波束形成，得到 15 维白化顺序 Beamspace。

“顺序波束”描述的是波束权值的构造层次：

```text
俯仰 DBF
→ 条件方位 DBF
```

它们最后统一写成一个固定矩阵 $W_I$，对同一个 CPI 数据同时作用，并不是时间上先扫描俯仰、再扫描方位。

---

## 3.2 两个目标为什么会落在同一个单元中

两个目标具有：

```text
相同或近似相同的距离
相同或近似相同的多普勒
```

因此普通距离–多普勒处理不能把它们分成两个单元。

但它们的角度不同：

$$
\boldsymbol{\xi}_1=
\begin{bmatrix}
\phi_1\\
\theta_1
\end{bmatrix},
\qquad
\boldsymbol{\xi}_2=
\begin{bmatrix}
\phi_2\\
\theta_2
\end{bmatrix}.
$$

算法要利用圆柱阵的空间相位差，在同一个距离–多普勒单元中估计这两个二维角度。

---

## 3.3 四种目标 profile

代码定义：

$$
\boldsymbol{\xi}_{1,2}
=
\mathbf c
\mp
\frac{\rho}{2}
\begin{bmatrix}
\cos\alpha\\
\sin\alpha
\end{bmatrix}.
$$

这里：

- $\mathbf c$：两个目标的几何中心；
- $\rho$：二维角平面中的总分离；
- $\alpha$：分离轴相对于方位轴的方向。

代码正是按这个式子生成两个真值 endpoint。

四种 profile 的冻结参数如下。

| Profile | 中心 $(\phi,\theta)$ | 总分离 | 方向 | 次目标功率 | 多快拍相关性 |
|---|---:|---:|---:|---:|---:|
| P1 | $(8.00,10.00)^\circ$ | $0.30^\circ$ | $45^\circ$ | 0 dB | 0 |
| P2 | $(8.20,10.00)^\circ$ | $0.20^\circ$ | $0^\circ$ | −6 dB | 0 |
| P3 | $(7.90,10.10)^\circ$ | $0.15^\circ$ | $90^\circ$ | 0 dB | 0.9 |
| P4 | $(8.10,9.95)^\circ$ | $0.10^\circ$ | $135^\circ$ | −6 dB | 0.9 |

对应两个目标大致为：

| Profile | 目标 1 | 目标 2 | 直观含义 |
|---|---|---|---|
| P1 | $(7.8939,9.8939)^\circ$ | $(8.1061,10.1061)^\circ$ | 方位、俯仰同时分开，等功率 |
| P2 | $(8.10,10.00)^\circ$ | $(8.30,10.00)^\circ$ | 只在方位分开，次目标弱 6 dB |
| P3 | $(7.90,10.025)^\circ$ | $(7.90,10.175)^\circ$ | 只在俯仰分开，强相关 |
| P4 | $(8.1354,9.9146)^\circ$ | $(8.0646,9.9854)^\circ$ | 极小分离、弱次目标、强相关 |

P1 是较有利场景；P4 是最典型的组合压力场景。

当 $L>1$ 时，源矩阵按照指定功率比和相关系数构造；当 $L=1$ 时，一个快拍无法提供独立源时间结构，代码强制两个源完全相干。

---

# 四、阵元域和波束域信号模型

## 4.1 圆柱阵流形

圆柱阵第 $m,n$ 个阵元位置写成：

$$
\mathbf r_{m,n}
=
\begin{bmatrix}
R\cos\psi_m\\
R\sin\psi_m\\
z_n
\end{bmatrix}.
$$

目标方向单位矢量：

$$
\mathbf u(\phi,\theta)
=
\begin{bmatrix}
\cos\theta\cos\phi\\
\cos\theta\sin\phi\\
\sin\theta
\end{bmatrix}.
$$

接收导向量：

$$
\boxed{
a_{m,n}(\phi,\theta)
=
\exp
\left[
j k_0\mathbf r_{m,n}^{T}
\mathbf u(\phi,\theta)
\right]
}
$$

其中：

$$
k_0=\frac{2\pi}{\lambda}.
$$

把全部活动阵元堆叠起来：

$$
\mathbf a(\phi,\theta)
=
[a_1,\ldots,a_{2080}]^T.
$$

---

## 4.2 双目标阵元域模型

对于 $L$ 个快拍：

$$
\boxed{
Y_e
=
A(\Theta)S+N_e
}
$$

其中：

$$
A(\Theta)
=
[
\mathbf a(\boldsymbol\xi_1),
\mathbf a(\boldsymbol\xi_2)
],
$$

$$
S=
\begin{bmatrix}
s_1(1)&\cdots&s_1(L)\\
s_2(1)&\cdots&s_2(L)
\end{bmatrix}.
$$

噪声满足：

$$
N_e\sim\mathcal{CN}(0,R_e).
$$

这里的源幅度是确定性未知量，这就是 Conditional/Deterministic ML 模型。

---

## 4.3 顺序 Beamspace

固定接收波束矩阵为：

$$
W_I\in\mathbb C^{2080\times15}.
$$

原始波束输出：

$$
Y_b=W_I^HY_e.
$$

波束噪声协方差：

$$
\boxed{
C_b=W_I^HR_eW_I
}
$$

一般：

$$
C_b\neq I,
$$

因为：

- 不同波束复用相同阵元；
- 波束权值不是严格正交；
- 阵元噪声还可能相关。

因此构造 whitener：

$$
T_IC_bT_I^H\approx I.
$$

白化后观测：

$$
\boxed{
Z=T_IW_I^HY_e
}
$$

白化后单目标流形：

$$
\boxed{
g(\boldsymbol\xi)
=
T_IW_I^H\mathbf a(\boldsymbol\xi)
}
$$

这一步以后，Tangent、Core、Full4D Beamspace CML 使用的都是同一个 $Z$ 和同一个 $g(\boldsymbol\xi)$。

---

# 五、当前 white-SNR 是怎样定义的

新 Monte Carlo 控制的不是阵元输入 SNR，而是：

```text
WHITENED_SEQUENTIAL_BEAMSPACE_EXPECTED_TOTAL_SNR
```

定义：

$$
C_w=T_IC_bT_I^H,
$$

$$
X_w=T_IW_I^HX_e.
$$

于是：

$$
\boxed{
\gamma_w
=
\frac{\|X_w\|_F^2}
{L\operatorname{tr}(C_w)}
}
$$

为了把某个 trial 设为目标 white-SNR $\gamma_w^\star$，先构造无噪声未缩放信号：

$$
X_{e,0}=A(\Theta)S_0,
$$

然后计算：

$$
X_{w,0}=T_IW_I^HX_{e,0}.
$$

缩放系数：

$$
\boxed{
\alpha
=
\sqrt{
\frac{
\gamma_w^\star L\operatorname{tr}(C_w)
}{
\|X_{w,0}\|_F^2
}
}
}
$$

最后：

$$
X_e=\alpha X_{e,0},
$$

$$
\boxed{
Y_e=X_e+N_e.
}
$$

代码正是先缩放无噪声信号、生成固定协方差噪声，再执行：

```matlab
Y_element = signal + noise;
```

所以本质仍是最普通的：

```text
观测 = 无噪声信号 + 噪声
```

只是把 SNR 精确控制在 Tangent 实际工作的白化波束域。

---

# 六、集中 DML 是所有 ML 路线的共同基础

对于候选双目标角度：

$$
\Theta=
\{\boldsymbol\xi_1,\boldsymbol\xi_2\},
$$

构造：

$$
G(\Theta)
=
[
g(\boldsymbol\xi_1),
g(\boldsymbol\xi_2)
].
$$

模型：

$$
Z=G(\Theta)S+N_w.
$$

给定角度时，未知幅度的最小二乘估计是：

$$
\widehat S=G^\dagger Z.
$$

定义投影：

$$
P_G=GG^\dagger,
\qquad
P_G^\perp=I-P_G.
$$

剩余不能被候选流形解释的能量：

$$
\boxed{
RSS(\Theta)
=
\|P_G^\perp Z\|_F^2
}
$$

所以最大似然角度估计等价于：

$$
\boxed{
\widehat\Theta
=
\arg\min_\Theta RSS(\Theta)
}
$$

直观理解：

> 假设两个目标在某一对角度上，计算这两个方向能够解释多少观测；解释不掉的残差越小，这对角度越合理。

实际代码用 SVD 而不是直接求 $(G^HG)^{-1}$，这样在两个目标非常接近、$G$ 病态时更稳定。

---

# 七、Tangent 的核心理论推导

## 7.1 用中心和分离向量表示两个目标

设：

$$
\boldsymbol\xi_1
=
\mathbf c-\frac{\mathbf d}{2},
$$

$$
\boldsymbol\xi_2
=
\mathbf c+\frac{\mathbf d}{2}.
$$

其中：

$$
\mathbf c=
\frac{\boldsymbol\xi_1+\boldsymbol\xi_2}{2}
$$

是中心，

$$
\mathbf d=
\boldsymbol\xi_2-\boldsymbol\xi_1
$$

是二维分离向量。

完整 K2 原本有四个未知量：

$$
\phi_1,\theta_1,\phi_2,\theta_2.
$$

等价地是：

$$
c_\phi,c_\theta,d_\phi,d_\theta.
$$

---

## 7.2 对近目标流形作一阶展开

两个目标很近时：

$$
g\left(
\mathbf c-\frac{\mathbf d}{2}
\right)
\approx
g(\mathbf c)
-
\frac12J_g(\mathbf c)\mathbf d,
$$

$$
g\left(
\mathbf c+\frac{\mathbf d}{2}
\right)
\approx
g(\mathbf c)
+
\frac12J_g(\mathbf c)\mathbf d.
$$

其中：

$$
J_g(\mathbf c)
=
\begin{bmatrix}
\frac{\partial g}{\partial\phi}&
\frac{\partial g}{\partial\theta}
\end{bmatrix}_{\mathbf c}.
$$

代入双目标模型：

$$
\begin{aligned}
Z
&\approx
\left(
g_c-\frac12J_g\mathbf d
\right)s_1^T
+
\left(
g_c+\frac12J_g\mathbf d
\right)s_2^T
+
N_w\\
&=
g_c(s_1+s_2)^T
+
\frac12J_g\mathbf d(s_2-s_1)^T
+
N_w.
\end{aligned}
$$

这里出现了两个非常重要的部分。

### 公共模态

$$
\boxed{
g_c(s_1+s_2)^T
}
$$

它看起来像“一个目标”，代表整个目标簇的大部分共同能量。

### 分离差模

$$
\boxed{
\frac12J_g\mathbf d(s_2-s_1)^T
}
$$

它才包含“两目标不是同一个角度”的信息。

---

## 7.3 K1 拟合中心

Tangent 首先调用 K1 Core-Lite：

$$
\widehat{\mathbf c}
=
\arg\min_{\mathbf c}
RSS_{K=1}(\mathbf c).
$$

当前代码先调用：

```text
estimate_stage8_known_k_local_cell(..., K=1)
```

随后另外调用同一公共接口获得固定网格 K2 安全基线：

```text
estimate_stage8_known_k_local_cell(..., K=2)
```

需要注意：

$$
\widehat{\mathbf c}_{K1}
$$

是“最优单目标等效中心”，不一定严格等于两个目标的几何中点。

当：

```text
一个目标强、一个目标弱
源近同相
源高度相关
```

时，K1 中心可能偏向强目标。

---

## 7.4 投影掉公共模态

定义：

$$
g_c=g(\widehat{\mathbf c}),
$$

$$
\boxed{
P_c^\perp
=
I-\frac{g_cg_c^H}{g_c^Hg_c}
}
$$

将白化数据投影到 K1 流形的正交补：

$$
\boxed{
R=P_c^\perp Z
}
$$

并将流形 Jacobian 也投影：

$$
\boxed{
B=P_c^\perp J_g(\widehat{\mathbf c})
}
$$

则一阶近似下：

$$
\boxed{
R
\approx
\frac12B\mathbf d(s_2-s_1)^T
+
P_c^\perp N_w
}
$$

直观理解：

> 先把“一个目标就能解释的部分”擦掉，剩下的残差中，结构化信号主要来自两个目标的分离。

---

## 7.5 为什么需要 Fisher 型度量

方位角变化 $0.01^\circ$ 和俯仰角变化 $0.01^\circ$ 对波束数据的影响通常不一样。

如果直接对残差做普通二维 PCA，会把“阵列本身对某个方向更敏感”误认为“目标真的朝那个方向分开”。

因此定义：

$$
\boxed{
T=\operatorname{Re}(B^HB)
}
$$

这是一个 $2\times2$ 局部灵敏度矩阵：

- $T_{11}$：对方位变化的敏感度；
- $T_{22}$：对俯仰变化的敏感度；
- $T_{12}$：方位、俯仰变化的耦合。

残差协方差：

$$
S_R=\frac{RR^H}{L}.
$$

残差在切平面中的能量：

$$
\boxed{
C_t
=
\operatorname{Re}(B^HS_RB)
}
$$

这也是 $2\times2$。

---

## 7.6 广义特征值为什么给出分离方向

在理想一阶模型下，令：

$$
\Delta s=s_2-s_1,
$$

$$
\beta=\frac{\|\Delta s\|^2}{4L}.
$$

则近似有：

$$
\mathbb E[C_t]
\approx
T+
\beta T\mathbf d\mathbf d^TT.
$$

第一项是白噪声背景；第二项是沿真实分离向量 $\mathbf d$ 的秩一增强。

因此求：

$$
\boxed{
\widehat{\mathbf u}
=
\arg\max_{\mathbf u\neq0}
\frac{
\mathbf u^TC_t\mathbf u
}{
\mathbf u^TT\mathbf u
}
}
$$

等价于：

$$
\boxed{
C_t\widehat{\mathbf u}
=
\lambda_{\max}T\widehat{\mathbf u}.
}
$$

分母 $\mathbf u^TT\mathbf u$ 把阵列在不同方向上的天然灵敏度除掉，留下更接近真实目标分离方向的信息。

代码没有直接调用一般广义 `eig(Ct,T)`，而是：

1. 对 $T$ 做特征分解；
2. 检查 $T$ 是否满秩；
3. 构造 $T^{-1/2}$；
4. 在归一化坐标中求最大特征向量；
5. 映射回原方位–俯仰坐标；
6. 单位化并固定符号。

这与上述广义特征值问题等价。

---

## 7.7 为什么方向是无向轴

若：

$$
\widehat{\mathbf u}
\rightarrow
-\widehat{\mathbf u},
$$

则：

$$
\widehat{\mathbf c}
-\frac{\rho}{2}(-\widehat{\mathbf u})
=
\widehat{\mathbf c}
+\frac{\rho}{2}\widehat{\mathbf u},
$$

只是交换两个目标标签。

因此：

$$
\mathbf u\equiv-\mathbf u.
$$

方向误差必须定义为：

$$
\boxed{
e_{\rm axis}
=
\arccos
\left(
|\widehat{\mathbf u}^T\mathbf u_{\rm true}|
\right)
}
$$

代码后续诊断正是按无向轴修正；修正后的中位/P90 轴误差为：

```text
6.57° / 27.97°
```

---

## 7.8 把四维搜索降成一维

得到轴：

$$
\widehat{\mathbf u}
=
\begin{bmatrix}
\widehat u_\phi\\
\widehat u_\theta
\end{bmatrix}
$$

后，令：

$$
\boxed{
\boldsymbol\xi_1(\rho)
=
\widehat{\mathbf c}
-
\frac{\rho}{2}\widehat{\mathbf u}
}
$$

$$
\boxed{
\boldsymbol\xi_2(\rho)
=
\widehat{\mathbf c}
+
\frac{\rho}{2}\widehat{\mathbf u}
}
$$

只搜索一个未知量：

$$
\rho.
$$

于是：

```text
原来：
φ1、θ1、φ2、θ2，四维搜索

现在：
中心由 K1 给出
方向由残差给出
只搜索分离尺度 ρ，一维搜索
```

方位和俯仰并不是先后独立搜索，而是按：

$$
d_\phi=\rho\widehat u_\phi,
\qquad
d_\theta=\rho\widehat u_\theta
$$

同时变化。

---

## 7.9 最终不是 Taylor 近似评分

一阶展开只用于获得方向。

对于每个 $\rho$，代码重新构造：

$$
G_\rho
=
\left[
g\left(
\widehat{\mathbf c}-\frac{\rho\widehat{\mathbf u}}2
\right),
g\left(
\widehat{\mathbf c}+\frac{\rho\widehat{\mathbf u}}2
\right)
\right]
$$

并使用完整真实圆柱阵流形计算：

$$
\boxed{
RSS_{\rm TP}(\rho)
=
\|P_{G_\rho}^{\perp}Z\|_F^2.
}
$$

代码固定：

```text
rho_min = 0.001°
33 个粗扫描节点
fminbnd TolX = 1e-4°
MaxFunEvals = 80
```

先扫描 33 个节点，再在最佳节点邻域执行 `fminbnd`。

---

## 7.10 Safe fallback

Tangent 同时保留固定网格 K2 结果：

$$
\widehat\Theta_{\rm grid}.
$$

如果：

```text
方向有效
rho profile 有效
两个 endpoint 在局部域内
K2 流形满秩
Tangent loglik >= fixed-grid loglik
```

则：

$$
\widehat\Theta
=
\widehat\Theta_{\rm Tangent}.
$$

否则：

$$
\boxed{
\widehat\Theta
=
\widehat\Theta_{\rm grid}.
}
$$

代码正是比较：

```matlab
profile.loglik_concentrated >= fixed.loglik_concentrated
```

它保证的是：

```text
最终结果有效
最终 likelihood 不差于固定网格
```

不是：

```text
每个 trial 的真实 RMSE 一定更低
```

因为在线算法不知道真值。

---

# 八、传统方法如何实现

## 8.1 Core-Lite

Core-Lite 是内部安全基线。

K2 时主要是：

```text
在固定二维角度网格中枚举候选目标对
→ 计算每对候选的 DML RSS
→ 选择 likelihood 最大的候选
```

优点：

- 稳定；
- 确定性；
- 不容易产生离域连续解。

缺点：

- 角度只能落在网格上；
- 存在网格量化误差；
- 很近的目标容易共享或邻接网格点。

---

## 8.2 Core-Plus

Core-Plus 在固定网格初始化后，允许更多连续坐标优化。

本质上类似：

$$
c_\phi
\rightarrow c_\theta
\rightarrow d_\phi
\rightarrow d_\theta
$$

逐坐标更新同一个 likelihood。

它比 Core-Lite 自由，但自由度增加后：

- 局部极值更多；
- 弱目标容易被强目标吸引；
- 有时高 likelihood 不对应更低角度误差。

因此最终它保留为内部参考，而不是默认 K2。

---

## 8.3 Full4D Beamspace CML

这是与 Tangent 最公平的传统 ML 基线。

它使用完全相同的：

```text
15 维白化顺序 Beamspace
相同 Z
相同圆柱阵流形 g(φ,θ)
相同 white-SNR trial
```

但不固定中心和分离方向，直接优化：

$$
\phi_1,\theta_1,\phi_2,\theta_2.
$$

或者等价地优化：

$$
c_\phi,c_\theta,d_\phi,d_\theta.
$$

目标仍然是：

$$
\boxed{
\min RSS(\phi_1,\theta_1,\phi_2,\theta_2).
}
$$

理论上，Full4D 的可行集合包含 Tangent 的一维可行集合：

$$
\mathcal T_{\rm Tangent}
\subset
\mathcal T_{\rm Full4D}.
$$

所以真正求到全局最优时：

$$
\ell_{\rm Full4D}^{\rm global}
\ge
\ell_{\rm Tangent}.
$$

但实际代码只能使用有限个起点和有限迭代，不保证求到全局最优；而且有限样本下，更多自由度会增加估计方差和 outlier 风险。

---

## 8.4 Full4D Element CML

它与 Beamspace Full4D 的公式相同，但直接使用全部 2080 个活动阵元：

$$
Y_{e,w}=R_e^{-1/2}Y_e,
$$

$$
A_w(\Theta)
=
R_e^{-1/2}
[
a(\boldsymbol\xi_1),
a(\boldsymbol\xi_2)
].
$$

优化：

$$
\boxed{
RSS_e(\Theta)
=
\|P_{A_w(\Theta)}^\perp Y_{e,w}\|_F^2.
}
$$

它拥有比 15 维 Beamspace 更多的信息，但计算量和内存明显更高，因此作为更多信息量参考，而不是相同硬件接口。

---

## 8.5 MUSIC

MUSIC 首先计算样本协方差：

$$
\widehat R
=
\frac1LZZ^H.
$$

进行特征分解：

$$
\widehat R
=
E_s\Lambda_sE_s^H
+
E_n\Lambda_nE_n^H.
$$

已知 $K=2$ 时，取两个最大特征向量作为信号子空间，其余作为噪声子空间。

对候选方向：

$$
\boxed{
P_{\rm MUSIC}(\phi,\theta)
=
\frac1{
g^H(\phi,\theta)E_nE_n^Hg(\phi,\theta)
}
}
$$

真实目标方向的 steering vector 理论上应与噪声子空间正交，所以谱中出现峰值。

为了输出两个目标，必须找到两个独立局部峰。

### 当前场景为什么困难

当两个目标很近、相关性高、快拍少时：

- 两个 steering vector 高度相关；
- 样本协方差的第二个信号特征值很弱；
- 两个谱峰合并成一个宽峰；
- 低 SNR 下可能出现噪声伪峰。

因此 MUSIC 可能知道“这里有一个强目标簇”，却无法稳定给出两个峰。

---

## 8.6 GFBSS-MUSIC

圆柱阵整体不是 ULA，但垂直方向的 32 层阵元具有精确移位结构。

把阵元数据重排为：

$$
X_l\in\mathbb C^{32\times65}.
$$

利用全部方位列和快拍构造垂直协方差：

$$
\widehat R_v
=
\frac1{LN_{\rm az}}
\sum_{l=1}^{L}
X_{l,\rm azw}X_{l,\rm azw}^H.
$$

固定长度为 31 的两个重叠垂直子阵：

$$
R_F
=
\frac12
\left(
J_0\widehat R_vJ_0^H+
J_1\widehat R_vJ_1^H
\right).
$$

再做前后向平均：

$$
\boxed{
R_{FB}
=
\frac12
\left(
R_F+\Pi R_F^*\Pi
\right)
}
$$

目的是让相干源重新获得秩。

相关噪声下再对白化后的 $R_{FB}$ 做 MUSIC，得到两个俯仰；若成功，再固定这两个俯仰，用完整圆柱阵条件 CML 搜索两个方位。

### 当前场景为什么困难

P1、P3、P4 的俯仰差大约只有：

```text
P1：0.212°
P3：0.150°
P4：0.071°
```

两个垂直 steering vector 几乎共线。

空间平滑可以恢复“代数秩”，但不保证有限 SNR 下第二个特征值足够大。

P2 两个目标俯仰完全相同，因此垂直结构中只有一个空间频率，是结构性 N/A。

---

## 8.7 Root-MUSIC

Root-MUSIC 需要 ULA 的 Vandermonde 形式：

$$
v(z)
=
[1,z,z^2,\ldots,z^{M-1}]^T.
$$

噪声投影：

$$
Q_n=E_nE_n^H.
$$

构造多项式：

$$
\boxed{
D(z)
=
v^T(z^{-1})Q_nv(z).
}
$$

选择最靠近单位圆的两个有效根：

$$
z_k=e^{j\mu_k}.
$$

由：

$$
\mu_k=k_0d_z\sin\theta_k
$$

得到：

$$
\boxed{
\widehat\theta_k
=
\arcsin
\left(
\frac{\arg z_k}{k_0d_z}
\right).
}
$$

当前只把它应用于圆柱阵真实存在的垂直 ULA 维度，再用条件方位 CML 补齐方位。

失败通常表现为：

```text
找不到两个注册角域内的根
两个根映射为几乎相同的俯仰
根偏离单位圆
```

---

## 8.8 ESPRIT

ESPRIT 也使用垂直移位不变性。

设信号子空间为：

$$
U_s.
$$

取上下两个移位子阵：

$$
U_1=J_1U_s,
\qquad
U_2=J_2U_s.
$$

求：

$$
\boxed{
\Psi=U_1^\dagger U_2.
}
$$

其两个特征值理论上为：

$$
\lambda_k
=
e^{jk_0d_z\sin\theta_k}.
$$

所以：

$$
\boxed{
\widehat\theta_k
=
\arcsin
\left(
\frac{\arg\lambda_k}{k_0d_z}
\right).
}
$$

当第二信号子空间模态被噪声淹没时，$\Psi$ 的特征值相位会严重偏移，甚至映射到局部俯仰域之外。

---

# 九、为什么 Tangent 更适合当前场景

三类方法依赖的信息不同。

## MUSIC、Root-MUSIC、ESPRIT 依赖

```text
样本协方差中必须稳定出现两个信号模态
```

也就是：

$$
\lambda_2(\widehat R)
$$

必须明显高于噪声特征值。

## Tangent 依赖

```text
K1 单目标解释之后的残差
在完整流形切平面中仍包含方向性结构
```

它不要求先在样本协方差中形成两个清晰的全局信号特征向量。

因此，在：

```text
目标极近
相关性高
快拍少
次目标弱
```

时，Tangent 可能仍能从残差的一阶结构中提取方向，而子空间方法已经无法稳定形成第二模态。

---

# 十、理论和代码逐项对应

| 理论步骤 | 当前代码 |
|---|---|
| K1 参考中心 | `estimate_stage8_known_k_local_cell(...,K=1)` |
| 固定 K2 安全基线 | `estimate_stage8_known_k_local_cell(...,K=2)` |
| 白化数据 | `build_stage8_full_data_from_element` |
| 中心流形和导数 | `build_full_sequential_local_manifold` |
| $P_c^\perp$ | `eye - (g*g')/g_energy` |
| $B=P_c^\perp J_g$ | `B = Pg_perp * Jg` |
| $R=P_c^\perp Z$ | `R = Pg_perp * Zseq_white` |
| $T=\operatorname{Re}(B^HB)$ | `T = real(B' * B)` |
| $C_t$ | `Ct = real(B' * S_R * B)` |
| 广义特征方向 | `stage8_k2_tp_projected_direction` |
| 一维 $\rho$ profile | `stage8_k2_tp_profile_scale` |
| 完整流形 K2 评分 | `concentrated_dml_rss` |
| Safe selector | `profile.loglik >= fixed.loglik` |

---

# 十一、运行结果是什么

## 11.1 最初 72-trial 决定性实验

```text
Tangent valid：72/72
联合 RMSE median：0.07752°
联合 RMSE P90：0.25282°

对 Core-Lite：
53 胜 / 13 平 / 6 负

对 Core-Plus：
54 胜 / 7 平 / 11 负
```

---

## 11.2 1680-trial white-SNR Monte Carlo

| White-SNR | Tangent median RMSE | P90 | Fallback |
|---:|---:|---:|---:|
| −6 dB | 0.4385° | 0.6267° | 87.9% |
| 0 dB | 0.3211° | 0.6097° | 68.3% |
| +6 dB | 0.2427° | 0.5528° | 59.2% |
| +10 dB | 0.1838° | 0.5000° | 47.1% |
| +14 dB | 0.1163° | 0.3829° | 28.8% |
| +18 dB | 0.0921° | 0.2934° | 22.5% |
| +22 dB | 0.0796° | 0.2236° | 15.8% |

总体经验稳定相对收益从 `+10 dB` 开始；更稳妥的工程精化区大致是 `+14～+18 dB` 以上。

---

## 11.3 相对 Full4D Beamspace CML

| White-SNR | Tangent median | Full4D median | Tangent P90 | Full4D P90 |
|---:|---:|---:|---:|---:|
| +10 | 0.1838° | 0.2390° | 0.5000° | 0.5175° |
| +14 | 0.1163° | 0.2047° | 0.3829° | 0.4960° |
| +18 | 0.0921° | 0.1683° | 0.2934° | 0.3956° |
| +22 | 0.0796° | 0.1300° | 0.2236° | 0.3153° |

四个预注册工作区 SNR 点全部支持 Tangent 相对当前有限预算 Full4D Beamspace CML 的优势。

这是最强、最公平的对比，因为两者使用同一个 15 维白化 Beamspace。

---

## 11.4 相对阵元域 Full4D CML

在 160 个更多信息量阵元域参考 trial 中：

```text
Tangent：
median / P90 = 0.1065° / 0.3616°

Beamspace Full4D：
0.1657° / 0.3943°

Element Full4D：
0.1631° / 0.3764°
```

这说明 Tangent 的结果并不能简单归因于“经典方法少用了阵元信息”。

不过 Element Full4D 仍是有限预算数值实现，不是全局 ML 证明。

---

## 11.5 相对全部子空间方法

| 方法 | Applicable | Valid | 有效率 |
|---|---:|---:|---:|
| Tangent Safe | 1680 | 1680 | 100% |
| Beamspace MUSIC | 1120 | 0 | 0% |
| Element MUSIC | 1120 | 3 | 0.27% |
| GFBSS-MUSIC + az CML | 1260 | 5 | 0.40% |
| FBSS Root-MUSIC + az CML | 630 | 5 | 0.79% |
| FBSS LS-ESPRIT + az CML | 630 | 7 | 1.11% |

这些结果最主要说明：

> 子空间方法在当前场景中几乎不能稳定产生两个目标输出；Tangent 通过模型驱动的一维 profile 和 fallback 保持了完整输出覆盖率。

不能用 Root-MUSIC 仅有的 5 个成功样本或 ESPRIT 仅有的 7 个成功样本来做总体 RMSE 排名。

---

# 十二、理论预期和运行结果是否一致

总体上是高度一致的。

| 理论预期 | 代码运行结果 | 是否一致 |
|---|---|---|
| 低 SNR 下残差方向不稳定，应大量 fallback | fallback 从 −6 dB 的 87.9% 降至 +22 dB 的 15.8% | 一致 |
| SNR 上升后方向和一维 profile 应更有效 | median RMSE 从 0.4385° 降到 0.0796° | 一致 |
| 四维自由 ML 有更高方差和更多局部极值 | 当前有限 Full4D CML 在 +10～+22 dB 的 median/P90 均劣于 Tangent | 一致 |
| 子空间方法依赖清晰第二特征模态 | MUSIC 几乎全是单峰；Root/ESPRIT 有效率低于 1.2% | 一致 |
| P2 弱次目标且纯方位分离，应更难 | P2 首个稳定相对收益点达到 +22 dB | 一致 |
| 连续 $\rho$ profile 不会命中有限注册字典 | exact cache 在真实连续 T4 中 0 hit、346 miss | 一致 |
| 固定注册骨架可缓存，但只能获得有限端到端收益 | 固定骨架 cache 总体约 2.15% 加速 | 一致 |

Level-A exact cache 的真实连续 profile 命中率为 0，因此没有被错误保留为连续 T4 加速器；最终只保留固定注册骨架 cache。

多中心圆柱阵复用又取得约 86% 的多中心字典构建下降和约 82% 的存储下降，但它属于工程复用，不改变科学估计结果。

---

# 十三、唯一不能过度宣传的地方：分离尺度

虽然联合角度 RMSE 很好，但真实分离尺度 $\rho$ 恢复没有同样稳定。

原决定性实验中：

```text
rho 绝对误差 median / P90：
0.1068° / 0.2277°

rho 相对误差 median / P90：
0.938 / 1.448

rho 下界命中：
23/72
```

为什么 joint RMSE 仍然可以较小？

因为真实目标分离本来只有：

```text
0.10°～0.30°
```

即使两个估计结果在一定程度上向中心收缩，每个 endpoint 距离真值可能仍只有 $0.05^\circ$ 到 $0.15^\circ$，所以 joint RMSE 可以较低，但分离尺度的相对误差会很大。

因此论文允许写：

> Tangent 提升了近邻双目标联合角度估计的有限样本性能。

不应写：

> Tangent 在所有场景下稳定恢复了两个目标的真实角间隔。

---

# 十四、当前算法的最终准确表述

## 场景表述

> 面向圆柱阵全数字接收系统中，单 CPI、同一距离–多普勒单元内、已知 $K=2$、已给定局部二维角域的近邻双目标精细测角问题。

## 方法表述

> 在固定精确白化的 15 维顺序 Beamspace 中，首先利用 K1 DML 获得目标簇参考中心；随后投影消除单目标公共模态，利用投影流形 Jacobian 和残差协方差构造 Fisher 归一化广义特征值问题，估计双目标二维分离轴；最后沿该轴执行一维完整圆柱阵流形 profile likelihood 搜索，并以固定网格 K2 likelihood 作为安全回退。

## 效果表述

> 在涵盖白噪声与相关噪声、$L=1/4/8$、等功率与 −6 dB 弱次目标、非相关与 0.9 强相关源、$0.10^\circ$ 至 $0.30^\circ$ 二维角分离，以及 white-SNR −6 至 +22 dB 的 1680 次试验中，Tangent-Profile Safe 在全部 trial 上保持有效输出。总体上从 +10 dB 开始形成相对 Core-Lite 和 Core-Plus 的稳定收益，在 +14 dB 以上收益更明显；在 +10/+14/+18/+22 dB 下，其联合角度 RMSE 中位数和 P90 均优于当前有限预算 Full4D Beamspace CML。标准 Beamspace/Element MUSIC、GFBSS-MUSIC、Root-MUSIC 和 ESPRIT 未形成稳健双目标输出区间。

## 边界表述

> 当前结果不涉及 unknown-$K$、自动检测、跨 CPI 跟踪、阵列标定误差或全局最优 ML 证明；对真实分离尺度的恢复也弱于对联合 endpoint 角度的恢复。

---

# 十五、最终结论

理论、代码和结果目前形成了完整闭环：

```text
理论：
近双目标一阶切向结构成立

代码：
投影残差 → Fisher 方向 → 一维完整流形 profile

数值：
低 SNR fallback，高 SNR upgrade 增加

对比：
优于当前 Core 和有限预算 Full4D CML
经典子空间方法几乎无稳定双目标输出

工程：
固定骨架缓存和多中心复用不改变科学算法

结论：
Tangent-Profile Safe 在限定场景下有效
且已经可以收束
```

当前真正剩余的工作不是继续设计新算法，而是将上述内容整理为论文中的：

```text
问题建模
理论推导
算法流程图与伪代码
复杂度分析
实验设置
结果讨论
适用边界
```

另外，当前 `main` 中编号 11 文档的头部仍停留在较早的 Core-V2 状态，而 `00_DOCUMENT_STATUS_INDEX.md` 已经把 `31_*–48_*` 和 `50_*–56_*` 定义为当前权威证据；后续论文整理应以当前主线状态重写编号 11，而不是直接沿用其旧版结论。

---

# 十六、代码与证据索引

以下路径可用于进一步核对理论、实现和实验结果：

## Tangent 核心实现

```text
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_fit_safe.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_projected_direction.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_profile_scale.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_constants.m
```

## Known-K 公共接口

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_7_known_k_local_cell_refinement/common/
estimate_stage8_known_k_local_cell.m
```

## SNR 和场景生成

```text
tools/stage8_k2_snr_validation/matlab/
stage8_k2_snr_generate_white_control_trial.m

tools/stage8_k2_snr_validation/matlab/
stage8_k2_snr_build_source_fixture.m

tools/stage8_k2_snr_validation/matlab/
stage8_k2_snr_truth_from_spec.m

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_5_exact_subset_fim_beam_design/common/
construct_deterministic_source_matrix.m
```

## 主要科学证据

```text
innovation-mining/31_stage8_k2_tangent_profile_decisive_experiment.md
innovation-mining/32_stage8_k2_tangent_profile_diagnostic_correction.md
innovation-mining/34_stage8_k2_classical_baseline_comparison.md
innovation-mining/40_stage8_k2_subspace_baseline_comparison.md
innovation-mining/42_stage8_k2_snr_domain_validation.md
innovation-mining/44_stage8_k2_white_snr_monte_carlo_and_route_closure.md
innovation-mining/46_stage8_k2_white_snr_classical_baseline_comparison.md
innovation-mining/47_stage8_k2_white_snr_all_classical_baseline_theory_and_protocol.md
innovation-mining/48_stage8_k2_white_snr_all_classical_runtime_manifest.json
```

## 缓存与工程收束

```text
innovation-mining/51_stage8_k2_tangent_canonical_cache_v1_validation.md
innovation-mining/54_stage8_k2_tangent_fixed_backbone_cache_validation.md
innovation-mining/55_stage8_k2_cylindrical_multicenter_cache_validation.md
innovation-mining/56_stage8_k2_tangent_cache_branch_closeout.md
```

## 当前权威状态索引

```text
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/stage8_execution_prompts/README.md
```
