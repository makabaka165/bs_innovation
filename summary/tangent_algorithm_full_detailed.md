# Tangent-Profile Safe 算法全流程详解

> 文档对象：当前仓库中的 `TANGENT_PROFILE_SAFE`，即已知目标数 `K=2` 的 Stage8 近邻双目标二维角度估计器。  
> 核对版本：仓库 `HEAD = c5a76f19824bdbc2d34dd80f107bdf0050874da3`。  
> 实际工作区：`E:\bs_innovation`。用户给出的 `E:\bs\_innovation` 与当前目录不一致，本文按实际工作区整理。  
> 本文只解释现有算法、代码与已提交证据，不改变算法，不新增在线门限，也不把离线真值诊断用于估计。  
> 原文件 `summary.md` 保持不变；本文是更细的独立说明。

阅读路线：第 0–7 章建立系统模型、符号、白化和 DML；第 8–12 章给出 Core-Lite 与 Tangent 的完整推导和伪代码；第 13–15 章映射到实际代码、场景与评价指标；第 16–20 章整理验证、传统基线与缓存；第 21–24 章集中说明结论边界和已发现问题。

---

## 0. 先给出最简洁但准确的定位

Tangent-Profile Safe 解决的问题是：

> 在同一个 CPI、同一个距离-多普勒单元内，已知存在两个角度非常接近的目标时，利用固定圆柱阵、固定顺序 DBF 和精确白化后的数据，估计两个目标各自的二维角度 `[方位, 俯仰]`。

它不是目标数估计器，也不是检测器、航迹器或跨 CPI 融合器。当前返回对象明确记录：

```text
single CPI                         = true
same range-Doppler cell            = true
cross-CPI data used                = false
tracking input used                = false
K estimated inside this module     = false
truth used in fit                  = false
```

算法的核心思想可以压缩成一句话：

> 先用单目标模型找到目标簇的等效中心，再把这个公共单目标模态投影掉，从残差在局部流形切平面中的能量方向估计双目标分离轴，最后只沿该轴搜索一个分离尺度，并用完整双目标流形的集中 DML 与固定网格 K2 基线做安全选择。

这里有三个不能混淆的层次：

1. **Taylor/Jacobian 只负责给出分离轴**，不是最终的近似似然。
2. **最终 `rho` 搜索使用完整圆柱阵流形和精确集中 DML**，不是线性化流形。
3. **Safe 只保证当前观测的集中 likelihood 不低于固定 K2 候选**，不保证每个 trial 的真值 RMSE 都不会变差。

---

## 1. 从输入到输出的完整执行链

当前一次调用的主路径是：

```text
输入：Y_element ∈ C^(2080×L)，已知 K=2
  │
  ├─ 1. 根据噪声配置取得固定 W_I、C_I、T_I
  │
  ├─ 2. Z = T_I W_I^H Y_element ∈ C^(15×L)
  │
  ├─ 3. 公共 K1 Core-Lite
  │      └─ 得到最佳单目标等效中心 c_hat
  │
  ├─ 4. 固定注册网格 K2 Core-Lite
  │      └─ 得到安全基线 Theta_fixed 与 ell_fixed
  │
  ├─ 5. 在 c_hat 计算完整流形 g 和每弧度 Jacobian J_g
  │
  ├─ 6. P_perp = I - gg^H/(g^H g)
  │      R = P_perp Z
  │      B = P_perp J_g
  │
  ├─ 7. T   = Re(B^H B)
  │      S_R = R R^H/L
  │      C_t = Re(B^H S_R B)
  │
  ├─ 8. 解 C_t u = mu T u，取最大广义特征值对应方向
  │      └─ 得到无向分离轴 u_hat，||u_hat||_2 = 1
  │
  ├─ 9. 计算对称端点都留在局部域内时的 rho_max
  │
  ├─10. 在 [0.001°, rho_max] 上粗扫 33 点
  │      └─ 最佳粗点相邻区间内 fminbnd 连续精化
  │
  ├─11. 每个 rho 都构造
  │      xi_1 = c_hat - rho u_hat/2
  │      xi_2 = c_hat + rho u_hat/2
  │      并用完整 G=[g(xi_1),g(xi_2)] 计算集中 DML
  │
  └─12. Safe selector
         ├─ Tangent 有效且 ell_tangent >= ell_fixed：输出 Tangent
         └─ 其他情况：输出固定网格 K2
```

输出角度矩阵为：

$$
\widehat\Theta=
\begin{bmatrix}
\widehat\phi_1 & \widehat\theta_1\\
\widehat\phi_2 & \widehat\theta_2
\end{bmatrix}
\in\mathbb R^{2\times2},
$$

其中第一列是方位角，第二列是俯仰角，单位均为度。代码为消除目标标签置换的不确定性，按“先俯仰、再方位”排序端点；这只是输出规范，不代表目标 1、目标 2 有物理身份。

---

## 2. 符号、尺寸、单位和运算约定

### 2.1 下标和规模

| 符号 | 当前值或范围 | 含义 |
|---|---:|---|
| $M$ | 2080 | 活动阵元数，$32\times65$ |
| $N_{\rm az}$ | 192 | 完整圆柱阵周向列数 |
| $N_{\rm el}$ | 32 | 垂直层数 |
| $M_{\rm az}$ | 65 | 当前活动方位列数 |
| $B_0$ | 25 | 父顺序波束池通道数，$5\times5$ |
| $r_C$ | 15 | 主配置白化后的有效观测维数 |
| $K$ | 2 | 当前模块已知的目标数 |
| $L$ | 1、4、8 | 快拍数 |
| $Q$ | 21 | 注册局部物理角网格点数，$7\times3$ |
| $m$ | $0,\ldots,191$ | 完整圆柱阵周向列索引 |
| $n$ | $0,\ldots,31$ | 垂直层索引 |
| $\ell$ | $1,\ldots,L$ | 快拍索引 |

### 2.2 角度和几何量

| 符号 | 尺寸 | 单位 | 含义 |
|---|---:|---|---|
| $\phi$ | 标量 | 度或弧度，依上下文 | 方位角 azimuth |
| $\theta$ | 标量 | 度或弧度，依上下文 | 俯仰角 elevation |
| $\boldsymbol\xi=[\phi,\theta]^T$ | $2\times1$ | 外部为度 | 一个目标的二维角坐标 |
| $\mathbf c$ | $2\times1$ | 度 | 两端点的几何中心；K1 输出只是其等效估计 |
| $\mathbf d$ | $2\times1$ | 度或弧度 | 分离向量 $\boldsymbol\xi_2-\boldsymbol\xi_1$ |
| $\rho=\|\mathbf d\|_2$ | 标量 | 度 | 当前实现使用的欧氏角平面分离尺度 |
| $\mathbf u=\mathbf d/\rho$ | $2\times1$ | 无量纲 | 分离轴方向，$\|\mathbf u\|_2=1$ |
| $\alpha_u$ | 标量 | 度 | 分离轴相对方位坐标轴的角度 |

外部候选、搜索边界、输出和 `rho` 都以度表示；流形的一阶导数对弧度求导。由于方位和俯仰坐标都乘同一个换算因子 $\pi/180$，把一个二维方向整体从“每弧度坐标”换到“每度坐标”不会改变方向比例。但凡计算

$$
\mathbf d^T T\mathbf d
$$

这类带物理尺度的二次型，$\mathbf d$ 必须与 Jacobian 的坐标单位一致，即先从度转换成弧度。

### 2.3 数据、流形和协方差

| 符号 | 尺寸 | 含义 |
|---|---:|---|
| $Y_e$ 或 `Y_element` | $2080\times L$ | 活动阵元域观测 |
| $A(\Theta)$ | $2080\times K$ | 阵元域多目标流形矩阵 |
| $S$ | $K\times L$ | 确定性未知复源幅度矩阵 |
| $N_e$ | $2080\times L$ | 阵元域复高斯噪声 |
| $R_e$ 或 $R_n$ | $2080\times2080$ | 单快拍阵元噪声协方差 |
| $W_0$ | $2080\times25$ | 父顺序 DBF 波束矩阵 |
| $W_I$ | $2080\times15$ | 主配置选中的固定波束矩阵 |
| $C_I$ | $15\times15$ | 波束输出噪声协方差 |
| $T_I$ | $15\times15$ | 当前满秩白化矩阵 |
| $Z$ | $15\times L$ | 白化顺序 Beamspace 数据 |
| $g(\boldsymbol\xi)$ | $15\times1$ | 白化单目标流形 |
| $G(\Theta)$ | $15\times K$ | 白化多目标流形 |
| $J_g$ | $15\times2$ | $[\partial g/\partial\phi,\partial g/\partial\theta]$，每弧度 |
| $P_g^\perp$ | $15\times15$ | 正交于中心流形 $g$ 的投影矩阵 |
| $R$ | $15\times L$ | 投影后的 K1 残差 |
| $B$ | $15\times2$ | 投影后的局部切向基 $P_g^\perp J_g$ |
| $S_R$ | $15\times15$ | 残差样本协方差 $RR^H/L$ |
| $T$ | $2\times2$ | 切向几何度量 $\operatorname{Re}(B^HB)$ |
| $C_t$ | $2\times2$ | 残差在切向基中的能量矩阵 |

### 2.4 运算符

| 记号 | 含义 |
|---|---|
| $(\cdot)^T$ | 普通转置 |
| $(\cdot)^H$ | 共轭转置；MATLAB 中为 `'` |
| $(\cdot)^\dagger$ | Moore-Penrose 伪逆 |
| $\operatorname{Re}(\cdot)$ | 取实部 |
| $\operatorname{tr}(\cdot)$ | 矩阵迹 |
| $\|\cdot\|_2$ | 向量二范数 |
| $\|\cdot\|_F$ | Frobenius 范数 |
| $\mathcal{CN}(0,R)$ | 圆对称复高斯分布 |
| $I_r$ | $r\times r$ 单位矩阵 |

---

## 3. 物理阵列模型

### 3.1 冻结圆柱阵参数

| 参数 | 当前设置 | 物理含义 |
|---|---:|---|
| 载频 $f_c$ | 10 GHz | 工作载频 |
| 光速 $c_0$ | $3\times10^8$ m/s | 配置常数 |
| 波长 $\lambda=c_0/f_c$ | 0.03 m | 空间相位波长 |
| 完整周向列数 | 192 | 圆周等角间隔布阵 |
| 垂直层数 | 32 | 每个周向列有 32 个阵元 |
| 完整阵元数 | 6144 | $192\times32$，但当前只读取活动子阵 |
| 圆柱半径 $R_c$ | 0.4 m | 周向阵元半径 |
| 垂直间距 $d_z$ | 0.017 m | 相邻垂直层距离 |
| 活动扇区半宽 | $60^\circ$ | 围绕当前扇区中心选活动列 |
| 活动周向列数 | 65 | 由 $2\lfloor60/(360/192)\rfloor+1$ 得到 |
| 活动阵元数 | 2080 | $65\times32$ |
| 接收空间相位因子 | 1 | 单程接收阵列相位，不是双程因子 2 |

第 $m$ 个周向列的绝对圆周角和第 $n$ 层高度为

$$
\psi_m=\frac{2\pi m}{N_{\rm az}},
\qquad
z_n=n d_z.
$$

阵元坐标为

$$
\mathbf r_{m,n}=
\begin{bmatrix}
R_c\cos\psi_m\\
R_c\sin\psi_m\\
z_n
\end{bmatrix}.
$$

当前扇区中心为 $8^\circ$。代码先找离中心最近的物理列，再在圆周上取左右各 32 列，因此得到 65 列活动子阵。扇区中心是外部扫描/调度状态，不是估计器读取的目标真值。

### 3.2 方向矢量和导向矢量

方位角 $\phi$、俯仰角 $\theta$ 对应的单位传播方向为

$$
\mathbf q(\phi,\theta)=
\begin{bmatrix}
\cos\theta\cos\phi\\
\cos\theta\sin\phi\\
\sin\theta
\end{bmatrix}.
$$

空间波数为

$$
k_0=\frac{2\pi}{\lambda}.
$$

第 $(m,n)$ 个阵元的接收导向量分量为

$$
a_{m,n}(\phi,\theta)
=\exp\!\left(j k_0\mathbf r_{m,n}^T\mathbf q(\phi,\theta)\right).
$$

把所有活动阵元按代码规定的顺序堆叠后，得到

$$
\mathbf a(\phi,\theta)\in\mathbb C^{2080\times1}.
$$

这里的相位因子固定为 1，表示接收阵列的单程空间相位。雷达距离传播中的双程公共相位被吸收到未知复包络 $S$ 中，因此不能再把上式擅自改成 $2k_0$。

### 3.3 流形对角度的解析导数

代码计算的是对弧度的导数。令活动阵元坐标向量为 $x,y,z$，则相位对方位和俯仰的导数分别为

$$
\frac{\partial\varphi}{\partial\phi}
=k_0\cos\theta\left(-x\sin\phi+y\cos\phi\right),
$$

$$
\frac{\partial\varphi}{\partial\theta}
=k_0\left[-\sin\theta(x\cos\phi+y\sin\phi)+z\cos\theta\right].
$$

因为 $a=\exp(j\varphi)$，所以

$$
\frac{\partial a}{\partial\phi}
=j\frac{\partial\varphi}{\partial\phi}\odot a,
\qquad
\frac{\partial a}{\partial\theta}
=j\frac{\partial\varphi}{\partial\theta}\odot a,
$$

其中 $\odot$ 表示逐元素乘法。随后这些阵元域导数经历与数据完全相同的阵元重排、DBF 和白化，形成 $J_g$。

### 3.4 阵元顺序为什么必须单独说明

仓库中存在两种顺序：

```text
legacy steering order:
    方位列索引快，垂直层索引慢

canonical sequential-DBF order:
    垂直层索引快，方位列索引慢
```

`build_full_sequential_local_manifold.m` 不是默认假设二者相同，而是通过 `reshape_cyl_vector_to_matrix` 后再 `matrix(:)` 显式转换。若跳过该转换，即使每个阵元位置和公式都正确，$W_I^H a$ 仍会把错误的阵元与权值相乘。

---

## 4. 双目标观测、源相关性与噪声

### 4.1 条件/确定性双目标模型

令

$$
\Theta=\{\boldsymbol\xi_1,\boldsymbol\xi_2\},
\qquad
A(\Theta)=
\begin{bmatrix}
\mathbf a(\boldsymbol\xi_1)&\mathbf a(\boldsymbol\xi_2)
\end{bmatrix}.
$$

阵元域观测为

$$
\boxed{Y_e=A(\Theta)S+N_e}.
$$

其中

$$
S=
\begin{bmatrix}
s_1(1)&\cdots&s_1(L)\\
s_2(1)&\cdots&s_2(L)
\end{bmatrix}
\in\mathbb C^{2\times L}.
$$

这里 $S$ 在似然中被当作确定性未知干扰参数，而不是先验随机变量。因此当前 ML 是 Conditional/Deterministic ML，简称 CML/DML。实验生成器可以用相关系数构造 $S$，但估计器并不把该相关系数作为已知输入。

### 4.2 功率差和相关性在实验中表示什么

`secondary_power_db = -6` 表示第二个源的平均功率相对第一个源低 6 dB，而不是幅度低 6 倍。对应的功率比为

$$
\eta_P=10^{-6/10}\approx0.2512,
$$

幅度比为

$$
\eta_A=10^{-6/20}\approx0.5012.
$$

当 $L>1$ 时，源生成器按指定相关幅度构造两行源序列；Profile P3、P4 使用相关幅度 0.9。这个相关性描述快拍方向上的源波形相似程度。

当 $L=1$ 时，只有一个复样本，无法用样本维度形成两个独立的源时间模式。注册表因此把源条件强制记为完全相干。它不是说物理世界中两个源必然相干，而是说单快拍数据在该维度上没有可供区分的独立变化。

实际确定性源构造还可以写得更具体。为避免与角分离尺度 $\rho$ 混淆，下面把复相关系数记为 $\varrho_s$。令

$$
\gamma_P=10^{P_{2,{\rm dB}}/10},
\qquad
p_1=\frac{1}{1+\gamma_P},
\qquad
p_2=\frac{\gamma_P}{1+\gamma_P},
$$

$$
q_1=\frac1{\sqrt L}[1,\ldots,1],
$$

$$
q_2=\frac1{\sqrt L}
\left[e^{j2\pi\ell/L}\right]_{\ell=0}^{L-1},
$$

并由独立 source seed 生成 $\psi_s\sim U[0,2\pi)$，令

$$
\varrho_s=r_s e^{j\psi_s}.
$$

当 $L>1$ 时，代码构造

$$
s_1=\sqrt{Lp_1}\,q_1,
$$

$$
s_2=\sqrt{Lp_2}
\left(\varrho_s^*q_1+
\sqrt{1-|\varrho_s|^2}\,q_2\right).
$$

它保证未做 SNR 总缩放前

$$
\|S\|_F^2=L,
$$

第二行与第一行的功率比等于 $\gamma_P$，归一化相关系数等于 $\varrho_s$。当 $L=1$ 时只允许 $r_s=1$，并直接构造满足相同功率比的两个复标量。随后 72-trial 或 white-SNR 生成器再对整个 $S$ 乘一个共同尺度，不改变功率比和相关系数。

### 4.3 两种阵元噪声模型

白噪声配置为

$$
R_e=I_{2080}.
$$

相关噪声先分别构造垂直和方位 Toeplitz 协方差：

$$
R_{\rm el}=\operatorname{toeplitz}\left(0.45^{0:31}\right),
$$

$$
R_{\rm az}=\operatorname{toeplitz}\left(0.70^{0:64}\right),
$$

再按 canonical 阵元顺序形成

$$
R_e=R_{\rm az}\otimes R_{\rm el}.
$$

噪声按 separable matrix-normal 因子生成；两种噪声条件在同一物理数据接口上比较。相关噪声不是在白化后人工加入，而是在阵元域生成，再经过实际 $W_I$ 和 $T_I$。

具体地，若

$$
R_{\rm el}=L_{\rm el}L_{\rm el}^H,
\qquad
R_{\rm az}=L_{\rm az}L_{\rm az}^H,
$$

每个快拍先生成

$$
E_\ell\in\mathbb C^{32\times65},
\qquad
[E_\ell]_{ij}\overset{i.i.d.}{\sim}\mathcal{CN}(0,1),
$$

再形成

$$
N_\ell=L_{\rm el}E_\ell L_{\rm az}^H,
$$

最后按 canonical 顺序向量化为 2080 维噪声列。两套正式实验调用的噪声方差尺度均为 `sigma2 = 1`；不同 SNR 通过缩放信号而不是改变噪声协方差获得。

---

## 5. 顺序 DBF、主通道选择和白化

### 5.1 “顺序”不是时间扫描

顺序 DBF 的构造层次为：

```text
先做垂直/俯仰权值 v_b
再对该俯仰通道使用条件方位权值 u_(c|b)
```

对应一个最终阵元权向量

$$
w_{b,c}=u_{c|b}\otimes v_b.
$$

所有列组成 $W_0$ 后，对同一批阵元快拍同时做矩阵乘法。因此“顺序”描述可分解权值结构，不表示先后扫描不同时间的数据。

### 5.2 父 5×5 波束池

父池的俯仰波束为

$$
[9.2,9.6,10.0,10.4,10.8]^\circ,
$$

方位波束为

$$
[6.8,7.4,8.0,8.6,9.2]^\circ.
$$

因此

$$
W_0\in\mathbb C^{2080\times25}.
$$

构造权值时，方位与俯仰维都使用 Taylor taper，冻结参数均为 `nbar = 4`、旁瓣电平 `SLL = -30 dB`。这些 taper 会改变 $g$ 和 $J_g$ 的实际局部几何，因此不是只影响画图的显示参数。

通道编号采用俯仰索引快、方位索引慢的规则：

$$
i=b+(c-1)B_{\rm el},
$$

其中 $b=1,\ldots,5$ 是俯仰通道，$c=1,\ldots,5$ 是方位波束。

### 5.3 当前主配置 `PRIMARY_RECT_E14_A31`

`E14` 的二进制掩码选择俯仰索引 `2:4`，`A31` 选择全部五个方位索引，所以实际使用：

```text
俯仰波束：9.6°, 10.0°, 10.4°       共 3 个
方位波束：6.8°, 7.4°, 8.0°, 8.6°, 9.2°  共 5 个
总通道数：3 × 5 = 15
```

由此

$$
W_I\in\mathbb C^{2080\times15}.
$$

注意：Stage5 初始化波束中的方位集合是 `[7.4,8.0,8.6]°`；主观测矩阵却使用全部五个父方位波束。初始化束、观测束和 Tangent 搜索网格是三个不同对象。

### 5.4 波束噪声协方差

原始波束输出为

$$
Z_{\rm raw}=W_I^H Y_e\in\mathbb C^{15\times L}.
$$

其单快拍噪声协方差为

$$
\boxed{C_I=W_I^H R_e W_I}.
$$

即使 $R_e=I$，通常也有 $C_I\ne I$，因为不同波束复用相同阵元且权值不严格正交。若阵元噪声相关，这种通道相关性更不能忽略。

### 5.5 PSD 白化

设保留的特征分解为

$$
C_I=U_r\Lambda_r U_r^H,
$$

则可构造

$$
T_I=\Lambda_r^{-1/2}U_r^H,
$$

使

$$
C_w=T_I C_I T_I^H\approx I_{r_C}.
$$

代码使用稳定秩阈值决定保留维数，而不是无条件逆矩阵。当前两个噪声 profile 在主配置下的白化秩都为 15，所以 $T_I$ 为 $15\times15$。

最终白化数据为

$$
\boxed{Z=T_IW_I^H Y_e\in\mathbb C^{15\times L}}.
$$

白化单目标流形为

$$
\boxed{g(\boldsymbol\xi)=T_IW_I^H\mathbf a(\boldsymbol\xi)}.
$$

从这里开始，Tangent、Core-Lite、Core-Plus 和 Beamspace Full4D CML 都应在同一 $Z$、同一 $g$ 和同一噪声度量下比较。

---

## 6. 两套 SNR 定义必须分开

### 6.1 早期 72-trial 实验的 SNR

早期 decisive experiment 先形成未缩放阵元信号

$$
X_{e,0}=A(\Theta)S_0,
$$

然后令目标总信号能量为

$$
E_{\rm target}=10^{\gamma_{\rm label}/10}\operatorname{numel}(X_{e,0}).
$$

源矩阵按

$$
S=S_0\sqrt{\frac{E_{\rm target}}{\|X_{e,0}\|_F^2}}
$$

缩放，噪声标度为 1。由于 `numel(X)=ML`，该标签实质控制阵元域期望平均能量 SNR：

$$
\gamma_e
=\frac{\|X_e\|_F^2}{ML}
=10^{\gamma_{\rm label}/10}
$$

两种注册 $R_e$ 的对角线都为 1，因此

$$
\mathbb E\|N_e\|_F^2
=L\operatorname{tr}(R_e)=ML.
$$

所以早期标签在白噪声和 Toeplitz 相关噪声下都等于阵元域期望总能量 SNR；相关噪声改变空间方向分布，但不改变其总期望噪声能量。

### 6.2 1680-trial Monte Carlo 的 white-SNR

后续主 Monte Carlo 使用 Tangent 实际工作的白化 Beamspace 作为控制域。令

```text
control_domain = WHITENED_SEQUENTIAL_BEAMSPACE_EXPECTED_TOTAL_SNR
```

其数学定义如下。令

$$
X_w=T_IW_I^H X_e,
\qquad
C_w=T_I C_I T_I^H,
$$

定义期望 white-SNR

$$
\boxed{
\gamma_w=
\frac{\|X_w\|_F^2}
{L\operatorname{tr}(C_w)}
}.
$$

给定目标 $\gamma_w^\star=10^{\gamma_{\rm dB}/10}$，用未缩放信号 $X_{w,0}$ 计算

$$
\boxed{
\alpha=
\sqrt{
\frac{\gamma_w^\star L\operatorname{tr}(C_w)}
{\|X_{w,0}\|_F^2}
}
},
$$

再令 $S=\alpha S_0$、$X_e=A S$，最后生成

$$
Y_e=X_e+N_e.
$$

该缩放用的是期望噪声能量，不是某一次噪声实现的随机能量；因此每个 trial 的 realized SNR 会围绕目标值波动。

### 6.3 不能做的比较

早期 72 trial 和后续 1680 trial 都出现 `-6/0/+6 dB` 标签，但两者不是相同输入条件：

```text
72 trial：阵元域总能量标度
1680 trial：白化顺序 Beamspace 期望总 SNR
```

所以不能把两张表中同名 SNR 行直接当作重复实验或一一复现。

---

## 7. 集中 DML：所有 ML 路线共同的评分核心

### 7.1 给定角度时消去未知源幅度

对白化模型

$$
Z=G(\Theta)S+N_w,
\qquad
N_w(:,\ell)\sim\mathcal{CN}(0,\sigma^2I_{r_C}),
$$

给定 $\Theta$ 和 $\sigma^2$ 时，对数似然除去常数后为

$$
\ell(\Theta,S,\sigma^2)
=-r_CL\log(\pi\sigma^2)
-\frac{1}{\sigma^2}\|Z-GS\|_F^2.
$$

对 $S$ 做最小二乘：

$$
\widehat S(\Theta)=G^\dagger Z.
$$

定义列空间投影

$$
P_G=GG^\dagger,
\qquad
P_G^\perp=I-P_G,
$$

则集中残差为

$$
\boxed{
RSS(\Theta)=\|P_G^\perp Z\|_F^2
}.
$$

因为 $\|Z\|_F^2$ 对候选角度不变，最大化解释能量 $\|P_GZ\|_F^2$、最小化 RSS 和最大化固定噪声方差下的 likelihood 是等价的。

### 7.2 同时集中掉噪声方差

复高斯最大似然方差估计为

$$
\boxed{
\widehat\sigma^2=\frac{RSS}{r_CL}
}.
$$

代回得到集中对数似然

$$
\boxed{
\ell_c(\Theta)
=-r_CL\left[\log(\pi\widehat\sigma^2)+1\right]
}.
$$

当前 $r_C=15$，所以复观测数是 $15L$。代码使用 ML 分母 $r_CL$，不是无偏估计中的自由度修正分母。

对固定与 Tangent 这两个 K2 候选，$Z$、$r_C$ 和 $L$ 完全相同。当 RSS 为正时，集中 loglik 对 RSS 严格单调递减，因此

$$
\ell_{\rm tangent}\ge\ell_{\rm fixed}
\quad\Longleftrightarrow\quad
RSS_{\rm tangent}\le RSS_{\rm fixed}.
$$

Safe selector 用 loglik 表述，但在当前同阶 K2 比较中也可直观理解为“不接受残差更大的 Tangent 候选”。

### 7.3 为什么用 SVD

两个目标趋于同一角度时，$G$ 的两列几乎共线，$G^HG$ 的条件数会迅速恶化。代码因此用 SVD 建立有效列空间和伪逆，不直接计算

$$
(G^HG)^{-1}G^H.
$$

候选 K2 只有在稳定数值秩至少为 2 时才可评分为有效。这个秩判定是数值可辨识性保护，不等于宣称两个真实目标在统计意义上已经被可靠分辨。

### 7.4 likelihood 与真值误差的关系边界

集中 likelihood 是数据拟合准则，不读取真值。真值 RMSE 只在离线评估阶段计算。因此出现以下情况并不矛盾：

```text
Tangent likelihood >= fixed-grid likelihood
但该 trial 的 Tangent 真值 RMSE > fixed-grid 真值 RMSE
```

Safe selector 的“安全”是拟合目标上的安全，不是真值损失上的逐样本支配。

---

## 8. Tangent 之前的 Core-Lite 基线到底做了什么

Tangent 一次调用会运行两个不同用途的 Core-Lite 子问题：

```text
公共 K1 Core-Lite：
    输出 Tangent 使用的 c_hat
    K1 固定候选和 K1 连续候选之间做 likelihood 安全选择

固定 K2 Core-Lite：
    输出最终 Safe selector 的 K2 基线
    只在注册网格上精化，不做连续四维精化
```

尤其要注意：固定 K2 内部还会重新计算一个**注册网格 K1 helper** 来构造 nested start。这个 helper 不等于 Tangent 使用的公共 K1 连续安全输出。

### 8.1 注册局部域

Stage5 冻结中心为

$$
\mathbf c_0=(8.0,10.0)^\circ.
$$

方位偏移为

$$
-0.6^\circ:0.2^\circ:+0.6^\circ,
$$

俯仰偏移为

$$
-0.2^\circ:0.2^\circ:+0.2^\circ.
$$

所以实际注册轴为

$$
\Phi_{\rm grid}
=\{7.4,7.6,7.8,8.0,8.2,8.4,8.6\}^\circ,
$$

$$
\Theta_{\rm grid}
=\{9.8,10.0,10.2\}^\circ.
$$

物理候选点总数为

$$
Q=7\times3=21.
$$

局部连续边界为

$$
\mathcal D=[7.4,8.6]^\circ\times[9.8,10.2]^\circ.
$$

不要把观测波束 `[9.6,10.0,10.4]°` 写成搜索俯仰域。波束中心可以位于搜索域外侧，用来提供对域内角度变化的响应信息。

### 8.2 固定网格坐标上升的共同规则

对任一注册起点，固定精化按以下顺序进行：

```text
for iteration = 1:6
    for target = 1:K
        尝试该目标的全部 7 个注册方位值
        保持其余坐标不变，接受分数严格更高的候选

        尝试该目标的全部 3 个注册俯仰值
        保持其余坐标不变，接受分数严格更高的候选
    end
end
```

即更新次序固定为

```text
target → azimuth → elevation
```

每次候选都重新构造完整白化流形并检查 K 列数值秩。角度始终留在 21 点注册集合上。最大 6 轮；相对分数变化阈值为 $10^{-9}$，角度更新阈值设为 $0^\circ$，所以“收敛”意味着本轮没有注册角度变化且分数稳定。

候选端点每次按“先俯仰、后方位”规范排序，避免交换目标标签造成无意义的状态差异。

### 8.3 K1 固定候选

K1 注册两个起点：

| 起点 ID | 来源 | 直观含义 |
|---|---|---|
| `K1_GROUPED_Q1_KQ1` | grouped Q1/Kq1 | 上游分组 DML 给出的注册单目标候选 |
| `K1_CONVENTIONAL_SINGLETON_PEAK` | conventional singleton peak | 常规单峰初始化 |

每个起点都执行最多 6 轮固定网格坐标上升，最后从所有有效起点中选择集中对数似然最大者。

### 8.4 K1 连续候选

连续 K1 只从 conventional singleton 起点开始，不从两个固定起点分别展开。其坐标更新为：

```text
最大 sweep 数                  8
每个坐标局部半径              0.20°
每坐标粗扫点数                9
局部精化                      fminbnd
fminbnd TolX                   1e-4°
fminbnd MaxFunEvals            80
相对 score 收敛阈值           1e-9
角度更新收敛阈值              1e-3°
更新顺序                      target → azimuth → elevation
```

每个坐标先在以当前位置为中心、被局部域裁剪的区间内扫 9 点，再以最佳点左右相邻节点为 bracket 做 `fminbnd`。只有不降低 score 的更新才接受。

若到 8 sweep 未满足正式收敛，但同时满足

$$
\text{relative score change}\le10^{-7},
$$

$$
\text{max angle update}\le2\times10^{-3}\ ^\circ,
$$

且没有单调性违规，代码允许把它标为可用。

公共 K1 最后在“固定候选”和“连续候选”之间再次做 likelihood 安全选择。输出

$$
\widehat{\mathbf c}=\widehat{\boldsymbol\xi}_{K1}
$$

被 Tangent 当作参考中心。

### 8.5 为什么 K1 输出不一定是几何中点

几何中点为

$$
\mathbf c_{\rm true}
=\frac{\boldsymbol\xi_1+\boldsymbol\xi_2}{2}.
$$

但 K1 求解的是

$$
\widehat{\mathbf c}
=\arg\min_{\mathbf c\in\mathcal D}
RSS_{K=1}(\mathbf c).
$$

如果两个源功率不同、相位不同、相关、流形弯曲或噪声较强，最佳单目标等效方向会向强目标或更能解释数据的一侧偏移。因此严谨的名称应是：

> K1 最佳单目标等效中心。

它不是由算法约束为真实几何中点，也没有在 Tangent 内做额外 center correction。

### 8.6 K2 固定基线的三个起点

K2 注册三个起点：

| 起点 ID | 来源 |
|---|---|
| `K2_GROUPED_Q1_KQ2` | grouped Q1 直接给出的 Kq2 双目标候选 |
| `K2_GROUPED_Q2_KQ1_PLUS_KQ1` | grouped Q2 的两个 Kq1 组合 |
| `K2_K1_EMBEDDED_NESTED_START` | 固定 K1 helper 加一个注册 anchor |

前两个起点来自冻结初始化上下文。第三个 nested 起点需要额外说明。

### 8.7 Nested K2 anchor 的构造

设固定 K1 helper 的角度和流形为

$$
\boldsymbol\xi_{K1},\qquad g_c=g(\boldsymbol\xi_{K1}).
$$

先计算投影 Jacobian 度量

$$
P_c^\perp=I-\frac{g_cg_c^H}{g_c^Hg_c},
$$

$$
B_c=P_c^\perp J_g(\boldsymbol\xi_{K1}),
$$

$$
T_c=\operatorname{Re}(B_c^HB_c).
$$

然后遍历 21 个注册候选 $\boldsymbol\xi_q$。对每个候选：

1. 构造 $G_q=[g_c,g(\boldsymbol\xi_q)]$。
2. 要求 $G_q$ 数值满秩 2。
3. 将角差转换成弧度

$$
\Delta_q=\operatorname{deg2rad}
(\boldsymbol\xi_q-\boldsymbol\xi_{K1}).
$$

4. 计算投影 Fisher-like 距离

$$
D_q=\Delta_q^T T_c\Delta_q.
$$

5. 在满秩候选中选择 $D_q$ 最大者；数值并列时取字典序第一个。

这相当于选择一个在当前 K1 局部切向几何下与中心最容易区分的注册 anchor，而不是简单选欧氏角距离最远点。

随后还必须验证 nested 合同：

$$
RSS_{K2,\rm init}
\le RSS_{K1}+\tau_{\rm numeric},
$$

第一列 $G_q(:,1)$ 必须与 K1 已保存的 $g_c$ 在机器精度内一致，并且 $G_q$ 不能秩亏。只有同时通过才把 nested start 标为可用。

### 8.8 固定 K2 的最终选择

三个可用起点分别执行最多 6 轮注册网格坐标上升。最终选择有效起点中集中 likelihood 最大者，形成

$$
\widehat\Theta_{\rm fixed},
\qquad
\ell_{\rm fixed}.
$$

这个候选的关键边界是：

```text
它不是 21 点无序对的全枚举；
它依赖三个注册起点和局部坐标上升；
它不做连续四维 K2 精化；
它是 Tangent Safe 的实际 fallback 基线。
```

---

## 9. Tangent 的局部理论推导

### 9.1 中心-分离参数化

把两个目标写成

$$
\boldsymbol\xi_1=\mathbf c-\frac{\mathbf d}{2},
\qquad
\boldsymbol\xi_2=\mathbf c+\frac{\mathbf d}{2}.
$$

其中

$$
\mathbf c=\frac{\boldsymbol\xi_1+\boldsymbol\xi_2}{2},
\qquad
\mathbf d=\boldsymbol\xi_2-\boldsymbol\xi_1.
$$

再写成

$$
\mathbf d=\rho\mathbf u,
\qquad
\rho\ge0,
\qquad
\|\mathbf u\|_2=1.
$$

完整 K2 有四个角度自由度：

$$
(\phi_1,\theta_1,\phi_2,\theta_2),
$$

等价于

$$
(c_\phi,c_\theta,\rho,u_\phi/u_\theta).
$$

Tangent 用 K1 固定前两个中心自由度，用投影残差解析估计一个方向自由度，最后只数值搜索一个尺度 $\rho$。

### 9.2 完整到二阶的局部 Taylor 展开

令

$$
g_c=g(\mathbf c),
\qquad
J_g=J_g(\mathbf c).
$$

定义 Hessian 沿 $\mathbf d$ 的二次收缩

$$
H_g[\mathbf d,\mathbf d]
=\sum_{p=1}^{2}\sum_{q=1}^{2}
d_p d_q
\frac{\partial^2g}
{\partial\xi_p\partial\xi_q}
\bigg|_{\mathbf c}.
$$

则

$$
g\!\left(\mathbf c\pm\frac{\mathbf d}{2}\right)
=g_c
\pm\frac12J_g\mathbf d
\frac18H_g[\mathbf d,\mathbf d]
+O(\|\mathbf d\|^3).
$$

代入双目标模型，得到

$$
\boxed{
\begin{aligned}
Z\approx{}&
g_c(s_1+s_2)^T\\
&+\frac12J_g\mathbf d(s_2-s_1)^T\\
&+\frac18H_g[\mathbf d,\mathbf d](s_1+s_2)^T\\
&+O(\|\mathbf d\|^3)+N_w.
\end{aligned}
}
$$

为便于理解，定义

$$
p=s_1+s_2,
\qquad
q=s_2-s_1.
$$

则三项分别是：

| 项 | 数学形式 | 直观意义 |
|---|---|---|
| 公共模态 | $g_cp^T$ | 两个近目标共同看起来像一个目标的主要能量 |
| 一阶分离差模 | $\frac12J_g\mathbf d q^T$ | 两目标沿哪个角方向分开的主要一阶信息 |
| 二阶曲率模态 | $\frac18H_g[\mathbf d,\mathbf d]p^T$ | 流形不是平面造成的弯曲修正 |

只写一阶式容易产生两个误解：一是误以为中心一定无偏；二是误以为即使 $q$ 很弱也能稳定看到分离。二阶式清楚表明，曲率项、中心偏差和更高阶项会在很小分离或特殊源关系下变得相对重要。

### 9.3 为什么强相关、弱次目标和少快拍会困难

一阶分离信息的快拍系数是

$$
q=s_2-s_1.
$$

若两源幅相十分相似，$\|q\|$ 会变小；强相关源更容易出现这种情况。若第二目标弱 6 dB，一阶差模也可能被强目标公共模态、曲率和噪声掩盖。$L$ 小时，$S_R$ 的样本波动更大；$L=1$ 时更不存在可用于分离源时间子空间的多快拍秩信息。

但“相关系数高”不与“$q$ 必然为零”等价：功率不等、相位差和具体实现仍会改变 $q$。因此相关性是困难因素，不是单一的确定失败条件。

### 9.4 投影掉公共复幅度模态

在实际代码中用 K1 等效中心 $\widehat{\mathbf c}$ 代替 $\mathbf c$。令

$$
g=g(\widehat{\mathbf c}),
$$

中心单目标列空间的正交补投影为

$$
\boxed{
P_g^\perp
=I_{r_C}-\frac{gg^H}{g^Hg}
}.
$$

它满足

$$
P_g^\perp g=0,
\qquad
(P_g^\perp)^H=P_g^\perp,
\qquad
(P_g^\perp)^2=P_g^\perp.
$$

构造

$$
\boxed{R=P_g^\perp Z},
$$

$$
\boxed{B=P_g^\perp J_g(\widehat{\mathbf c})}.
$$

若 $\widehat{\mathbf c}=\mathbf c$ 且一阶近似充分，则

$$
R\approx\frac12B\mathbf d q^T+P_g^\perp N_w.
$$

更完整地，实际残差还包含：

```text
K1 等效中心与几何中心的偏差项
二阶曲率投影项
三阶及更高阶项
白化误差和有限样本噪声
```

所以 $R$ 是“单目标模型解释不掉的部分”，不是纯净的第二目标信号。

### 9.5 投影 Jacobian 度量 $T$

定义

$$
\boxed{T=\operatorname{Re}(B^HB)}.
$$

对任一实二维小位移 $\delta$，有

$$
\delta^T T\delta
=\|B\delta\|_2^2.
$$

它表示：消除中心公共复幅度方向后，角平面上位移 $\delta$ 会在白化观测空间中产生多大的一阶变化。

因此 $T$ 可以严谨地称为：

> 投影 Jacobian 的局部 Fisher-like 灵敏度度量，或消除公共复幅度干扰后的有效 FIM 几何部分。

例如对单目标白化模型

$$
z_\ell=g(\xi)p_\ell+n_\ell,
\qquad
n_\ell\sim\mathcal{CN}(0,\sigma^2I),
$$

把每个快拍的未知复幅度 $p_\ell$ 当作 nuisance 参数并做 Schur complement 后，二维角度的有效信息具有

$$
\mathcal I_{\xi,\rm eff}
=\frac{2}{\sigma^2}
\sum_{\ell=1}^{L}|p_\ell|^2
\operatorname{Re}
\left(J_g^HP_g^\perp J_g\right)
=\frac{2\|p\|_2^2}{\sigma^2}T
$$

这一形式。这说明 $T$ 确实是去掉公共复幅度后的几何核心；同时也显示完整 FIM 还带有源能量与噪声尺度。

它**不是**完整 Fisher 信息矩阵。完整 FIM 还应包含源幅度、噪声方差、快拍结构以及对 nuisance 参数做 Schur complement 后的尺度因子。本文后续提到“Fisher 距离”时都只指当前代码中的这一个局部几何量。

### 9.6 残差协方差和切向能量矩阵

残差样本协方差为

$$
\boxed{S_R=\frac1L RR^H}.
$$

再投影回二维切向坐标：

$$
\boxed{C_t=\operatorname{Re}(B^H S_RB)}.
$$

在理想一阶模型下，令

$$
\beta=\frac{\|q\|_2^2}{4L},
$$

则信号部分近似为

$$
S_R^{(s)}\approx
\beta B\mathbf d\mathbf d^TB^H,
$$

进而

$$
H_B=B^HB=T+jK_B,
$$

其中 $K_B=\operatorname{Im}(B^HB)$ 是实反对称矩阵。一般情况下应保留它，因而

$$
\boxed{
C_t^{(s)}\approx
\beta\operatorname{Re}
\left(H_B\mathbf d\mathbf d^TH_B\right)
}.
$$

只有当 $\operatorname{Im}(B^HB)=0$ 或可忽略时，它才简化为

$$
C_t^{(s)}\approx
\beta T\mathbf d\mathbf d^TT.
$$

即使保留虚部，对任意实方向 $u$ 仍有

$$
u^TC_t^{(s)}u
=\beta\left|\mathbf d^TH_Bu\right|^2,
$$

以及

$$
u^TTu=u^TH_Bu.
$$

当 $B$ 列满秩、理想一阶模型成立时，对 $H_B$ 内积使用 Cauchy-Schwarz 不等式可知，该广义 Rayleigh 商在 $u\propto\mathbf d$ 时取到上界。因此主广义方向仍与真实分离向量对齐；上面的 `T d d^T T` 只是其“Gram 矩阵为实数”时的直观特例，而不是普遍恒等式。

### 9.7 为什么不显式扣除噪声底

理想白化噪声经过 $P_g^\perp$ 后，其协方差与 $P_g^\perp$ 成比例。于是噪声对 $C_t$ 的期望贡献为

$$
C_t^{(n)}\propto
\operatorname{Re}(B^H P_g^\perp B)
=T.
$$

在广义特征值问题中，给 $C_t$ 加上 $\sigma^2T$ 只会把所有广义特征值整体平移，不改变广义特征向量。这是“不扣除各向同性噪声底”仍有理论合理性的原因。

但有限快拍噪声不可能严格各向同性，白化也有数值误差。因此代码不扣噪声底并不意味着噪声不会影响方向；它只是没有增加一个需要估计的噪声底修正步骤。

### 9.8 广义 Rayleigh 商

方向由以下优化给出：

$$
\boxed{
\widehat{\mathbf u}
=\arg\max_{\mathbf u\ne0}
\frac{\mathbf u^T C_t\mathbf u}
{\mathbf u^T T\mathbf u}
}.
$$

分子衡量该角方向在实际残差中看到的切向能量，分母消除阵列/波束对不同角方向先天灵敏度的差异。若不除以 $\mathbf u^TT\mathbf u$，结果会偏向阵列天然响应更强的坐标方向，而不一定是真实分离方向。

一阶最优条件为

$$
\boxed{C_t\mathbf u=\mu T\mathbf u}.
$$

取最大广义特征值 $\mu_{\max}$ 对应的特征向量。

### 9.9 代码怎样稳定求解 2×2 广义问题

代码没有直接调用一个不加检查的 `eig(Ct,T)`，而是：

1. 对称化 $T$ 和 $C_t$。
2. 分解

$$
T=V\Lambda V^T.
$$

3. 将机器舍入范围内的小负特征值截为 0；若存在超过舍入容差的负值，则报错。
4. 用稳定秩阈值要求 $\operatorname{rank}(T)=2$。
5. 构造

$$
Q=V\Lambda^{-1/2}.
$$

6. 在单位度量中分解

$$
M=Q^T C_tQ.
$$

7. 取 $M$ 最大特征值对应 $w_{\max}$，回代

$$
\widetilde u=Qw_{\max},
$$

再做欧氏归一化

$$
\widehat u=\frac{\widetilde u}{\|\widetilde u\|_2}.
$$

如果 $T$ 秩不足 2，说明当前白化观测和中心处投影 Jacobian 不能在二维角坐标中提供两个独立局部方向，Tangent 方向无效并回退。

当前实现**没有广义特征值间隙门限**。也就是说，只要 $T$ 满秩且数值有限，即使两个广义特征值很接近，也会返回一个方向。特征间隙很小时方向可能对噪声非常敏感，这是现有实现的限制之一。

### 9.10 为什么方向是“轴”而不是“箭头”

端点集合

$$
\left\{
\widehat c-\frac\rho2\widehat u,
\widehat c+\frac\rho2\widehat u
\right\}
$$

在 $\widehat u\rightarrow-\widehat u$ 时不变。因此物理上

$$
\widehat u\equiv-\widehat u.
$$

代码只为结果可重复而固定符号：优先让俯仰分量非负；若俯仰分量在 $10^{-12}$ 容差内为 0，则让方位分量非负。

正式轴误差应为

$$
\boxed{
e_{\rm axis}
=\arccos\left(\left|widehat u^Tu_{\rm true}\right|\right)
\in[0,90^\circ]
}.
$$

不取绝对值的有向误差会把等价的 $u$ 与 $-u$ 误报为接近 $180^\circ$。

---

## 10. 沿分离轴进行完整流形 `rho` profile

### 10.1 对称端点

给定 K1 中心和轴方向，对任意候选尺度

$$
\rho\ge0,
$$

构造

$$
\boldsymbol\xi_1(\rho)
=\widehat{\mathbf c}-\frac\rho2\widehat{\mathbf u},
$$

$$
\boldsymbol\xi_2(\rho)
=\widehat{\mathbf c}+\frac\rho2\widehat{\mathbf u}.
$$

这里的对称性是 Tangent 降维的核心约束。若 K1 中心偏离真实几何中心，真实端点可能不在这条对称线上；`rho` 优化无法补偿垂直于轴的中心误差。

### 10.2 可行上界 `rho_max`

局部域边界写成

$$
[\phi_{\min},\phi_{\max}]
\times
[\theta_{\min},\theta_{\max}].
$$

对坐标 $j\in\{\phi,\theta\}$，中心到两侧边界的最小距离为

$$
m_j=\min
(\widehat c_j-l_j,\,h_j-\widehat c_j).
$$

若 $|\widehat u_j|>0$，为保证两个对称端点都在域内，需要

$$
\rho\le\frac{2m_j}{|\widehat u_j|}.
$$

所以

$$
\boxed{
\rho_{\max}
=\min_{j:|\widehat u_j|>0}
\frac{2m_j}{|\widehat u_j|}
}.
$$

若某方向分量为 0，该坐标不限制 `rho`。若 $\rho_{\max}<0.001^\circ$，profile 没有注册可行尺度并回退。

### 10.3 粗扫和连续精化

冻结参数为：

```text
rho_min                 0.001°
coarse scan node count  33
fminbnd TolX            1e-4°
fminbnd MaxFunEvals     80
```

步骤为：

1. 用 `linspace(rho_min,rho_max,33)` 生成均匀粗节点。
2. 在每个节点上计算完整 K2 集中 likelihood。
3. 从有效粗节点中取最大者。
4. 用该节点左右相邻节点形成 `fminbnd` bracket。
5. 以负集中 likelihood 为一维最小化目标。
6. 最后同时重新比较最佳粗点、bracket 两端和 `fminbnd` 候选，选有效 likelihood 最大者。

同一次 profile 内，对完全相同的浮点 `rho` 会复用已经计算的评价；这只是调用内去重，不等于跨 trial 的连续流形缓存。

### 10.4 每个 `rho` 都使用完整物理流形

对每个端点重新计算

$$
G(\rho)=
\begin{bmatrix}
g(\boldsymbol\xi_1(\rho))&
g(\boldsymbol\xi_2(\rho))
\end{bmatrix}.
$$

然后：

```text
检查 G 数值秩是否为 2
用 SVD 集中掉两个源的复幅度
计算 RSS、sigma2_hat 和 concentrated loglik
```

因此 Taylor 近似只限制搜索曲线的方向；最终 score 始终来自完整圆柱阵、完整 DBF、完整白化后的非线性流形。

### 10.5 为什么 `rho_min` 不取 0

当 $\rho=0$ 时两端点完全相同，$G$ 两列相同，K2 流形秩为 1，不能满足请求秩 2。代码用 $0.001^\circ$ 作为最小注册尺度，避开严格重复列。

但命中该下界通常表示“当前数据沿该轴没有支持更大可辨分离”，不能把 $0.001^\circ$ 当作成功恢复了一个真实微小间隔。

---

## 11. Safe selector 的所有主要分支

安全选择器首先要求固定 K2 基线有效。如果固定 K2 本身无效，当前函数返回无效状态，而不是让没有参照物的 Tangent 单独接管。

固定 K2 有效后，它立即成为默认输出。之后只有以下完整条件成立才升级：

$$
\text{profile.valid}=\text{true},
$$

$$
\ell_{\rm tangent}\ge\ell_{\rm fixed}.
$$

常见回退路径包括：

| 回退原因 | 含义 |
|---|---|
| `K1_CENTER_INVALID` | 公共 K1 没有有效有限角度 |
| `K1_CENTER_MANIFOLD_INVALID` | 中心流形能量非正或非有限 |
| `TANGENT_METRIC_RANK_DEFICIENT` | $T$ 的稳定秩不是 2 |
| `TANGENT_DIRECTION_NUMERIC_INVALID` | 广义方向数值无效 |
| `TANGENT_PROFILE_NO_FEASIBLE_SCALE` | 域内不存在 $\rho\ge0.001^\circ$ |
| `TANGENT_PROFILE_NO_VALID_SCAN_NODE` | 33 个粗节点都没有有效 K2 score |
| `TANGENT_PROFILE_FINAL_CANDIDATE_INVALID` | 最终候选集合没有有效项 |
| `TANGENT_LOGLIK_BELOW_FIXED_GRID` | Tangent 有效但 likelihood 更低 |

升级时记录

```text
selected_source   = TANGENT_PROFILE_UPGRADE
selected_start_id = FISHER_TANGENT_PROFILE_1D
```

回退时输出固定 K2 已经保存的角度、RSS、likelihood 和有效秩。

Safe 的数学保证只有：

$$
\ell_{\rm selected}
=\max(\ell_{\rm fixed},\ell_{\rm tangent})
$$

（在 Tangent 有效时；否则就是固定值）。它不提供置信概率、假警率、CRLB 达成保证或在线“已分辨/未分辨”判决。

---

## 12. 可直接照着实现的伪代码

```text
function TangentProfileSafe(Y_element, model, domain, K=2)

    assert K == 2

    # A. 两个公开安全子拟合
    k1 = CoreLite(Y_element, K=1)
    fixed = CoreLite(Y_element, K=2)

    if fixed invalid:
        return invalid

    selected = fixed

    if k1 invalid:
        return selected

    # B. 固定观测白化
    Z = T_I * W_I^H * Y_element
    c = k1.angle

    # C. 中心流形和局部切空间
    [g, dg_daz, dg_del] = FullSequentialManifoldAndJacobian(c)
    if g^H g <= 0 or non-finite:
        return selected

    Pperp = I - g*g^H/(g^H*g)
    J = [dg_daz, dg_del]        # derivative per radian
    B = Pperp * J
    R = Pperp * Z

    T  = sym(real(B^H*B))
    SR = R*R^H/L
    Ct = sym(real(B^H*SR*B))

    # D. Fisher-normalized residual direction
    [valid, u] = StableLargestGeneralizedEigenvector(Ct, T)
    if not valid:
        return selected

    normalize Euclidean norm of u
    canonicalize sign of u

    # E. Symmetric feasible one-dimensional profile
    rho_max = largest symmetric scale keeping c ± rho*u/2 in domain
    if rho_max < 0.001 degree:
        return selected

    rho_nodes = linspace(0.001 degree, rho_max, 33)
    evaluate exact full-manifold concentrated DML at all rho_nodes
    bracket the best valid node by its neighbors
    run fminbnd on negative concentrated loglik
    compare best node, bracket endpoints, and fminbnd candidate

    tangent = best valid exact-manifold candidate

    # F. Observation-only safe selection
    if tangent valid and tangent.loglik >= fixed.loglik:
        selected = tangent

    return selected
end
```

---

## 13. 理论步骤与当前 MATLAB 代码的逐项映射

### 13.1 Tangent 主链

| 理论/执行步骤 | 代码位置 | 实际行为 |
|---|---|---|
| Tangent 安全入口 | `tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_fit_safe.m` | 先运行公开 K1 和固定 K2，再做方向、profile 和 selector |
| 冻结常数与四个 Profile | `stage8_k2_tp_constants.m` | `rho_min`、33 点、`fminbnd` 参数、快拍/SNR/噪声集合 |
| 72-trial 注册表 | `stage8_k2_tp_build_registry.m` | 生成 72 个唯一 trial、源 seed 和噪声 seed；`L=1` 强制相干合同 |
| 方向广义特征求解 | `stage8_k2_tp_projected_direction.m` | 对称化、检查 $T$ 半正定与满秩、白化 $T$、取最大特征向量、固定符号 |
| 一维尺度 profile | `stage8_k2_tp_profile_scale.m` | 求 `rho_max`、33 点粗扫、邻点 bracket、`fminbnd`、完整流形 DML |
| 无向轴误差 | `stage8_k2_tp_axis_error_deg.m` | `acosd(abs(dot(u_hat,u_true)))` |
| Trial 生成和离线评价 | `stage8_k2_tp_evaluate_trial.m` | 生成共同阵元数据，三种方法共享；真值只用于结果行 |

### 13.2 Known-K Core 子链

| 理论/执行步骤 | 代码位置 | 实际行为 |
|---|---|---|
| Known-K 公共入口 | `.../step_12_7_known_k_local_cell_refinement/common/estimate_stage8_known_k_local_cell.m` | 组装白化数据、初始化上下文并分派 Core-Lite/Core-Plus |
| Core-Lite 安全组合 | `fit_stage8_core_lite.m` | K1 固定与连续安全选择；K2 固定网格 only |
| K1 连续精化 | `refine_stage8_k1_continuous.m` | 半径 0.20°、9 点加 `fminbnd`、最多 8 sweep |
| 固定 K1/K2 多起点拟合 | `.../step_12_6_k12_bootstrap_resolution/common/fit_local_model_k.m` | 建起点、注册网格坐标上升、重新认证、选择最大 likelihood |
| K1 起点 | `build_k1_initializations.m` | 两个固定注册起点 |
| K2 起点 | `build_k2_initializations.m` | 两个 grouped 起点加一个 Fisher-like nested anchor |
| 固定坐标上升 | `.../step_12_3_grouped_conditional_dml/common/refine_joint_sequential_dml.m` | 7 方位点、3 俯仰点、目标后坐标顺序、最多 6 轮 |
| Core-Plus | `fit_stage8_core_plus.m` | 固定 K2 与两个 grouped 连续中心-差分候选做安全选择 |

上表中的 `...` 都位于：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
```

### 13.3 物理模型、DBF 和 DML

| 对象 | 代码位置 | 关键事实 |
|---|---|---|
| 系统配置 | `beamspace_ml_v18/source/stepwise_signal_model/core/config/sim_cfg.m` | 10 GHz、192×32、0.4 m、17 mm、±60°、phase factor 1 |
| 圆柱阵活动子阵 | `core/array/arr_cyl.m` | 按扇区中心取 65 列，生成三维阵元坐标 |
| 父 5×5 波束池 | `.../step_12_5_exact_subset_fim_beam_design/common/build_stage7_candidate_pool.m` | 波束中心、$W_0$、通道顺序 |
| 主测量配置 | `.../step_12_6_k12_bootstrap_resolution/common/build_stage8_measurement_model.m` | 解析 `PRIMARY_RECT_E14_A31`，形成 $W_I,C_I,T_I$ |
| 数据白化 | `build_stage8_full_data_from_element.m` | `Zseq_raw=W_I'*Y`，`Zseq_white=T_I*Zseq_raw` |
| 完整白化流形与导数 | `.../step_12_3_grouped_conditional_dml/common/build_full_sequential_local_manifold.m` | 解析每弧度导数、阵元顺序转换、DBF、白化、秩检查 |
| 稳定集中 DML | `.../step_12_2_stable_dml_backend/common/concentrated_dml_rss.m` | SVD score、$RSS/(r_CL)$、集中 loglik |
| 白化器 | `build_psd_whitener.m` | PSD 特征模式与稳定秩处理 |

### 13.4 White-SNR 和经典基线

| 内容 | 代码位置 |
|---|---|
| white-SNR trial 缩放 | `tools/stage8_k2_snr_validation/matlab/stage8_k2_snr_generate_white_control_trial.m` |
| 1680 Monte Carlo 常数 | `tools/stage8_k2_white_snr_monte_carlo/matlab/stage8_k2_mc_constants.m` |
| Full4D CML | `tools/stage8_k2_classical_baselines/matlab/stage8_k2_cb_full4d_cml.m` |
| Beamspace/Element MUSIC | `tools/stage8_k2_classical_baselines/matlab/stage8_k2_cb_music.m` 及 all-classical 包 |
| GFBSS-MUSIC | `tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_gfbss_music.m` |
| Root-MUSIC | `tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_root_music.m` |
| LS-ESPRIT | `tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_ls_esprit.m` |
| 结构适用性规则 | `tools/stage8_k2_white_snr_all_classical_baselines/matlab/stage8_k2_wacb_applicability.m` |

---

## 14. 当前实际场景的完整冻结设定

### 14.1 输入场景

当前估计任务固定为：

```text
一个 CPI
一个已经检测到的距离-多普勒单元
该单元内已知 K=2
两个目标都位于局部角域 [7.4,8.6]° × [9.8,10.2]°
只使用该 CPI 的阵元复快拍矩阵
不使用真值、航迹、跨 CPI 历史或在线 SNR 标签
```

波形配置中虽然还存在脉冲宽度、带宽、PRI、32 脉冲和 CFAR 参数，但当前 Stage8 证据直接从同一距离-多普勒单元的角域快拍接口开始；这些上游波形参数没有进入 Tangent 的方向公式或 profile 目标。

### 14.2 四个注册 Profile

令分离轴角 $\alpha$ 从方位正轴朝俯仰正轴计，方向为

$$
u_{\rm true}=
\begin{bmatrix}
\cos\alpha\\
\sin\alpha
\end{bmatrix}.
$$

真值端点由

$$
\Theta_{\rm true}=
\begin{bmatrix}
c-\rho u_{\rm true}/2\\
c+\rho u_{\rm true}/2
\end{bmatrix}
$$

生成。

| Profile | 中心 $(c_\phi,c_\theta)$ | 真分离 $\rho$ | 轴角 | 次目标功率 | $L>1$ 相关幅度 | 主要压力 |
|---|---:|---:|---:|---:|---:|---|
| P1 | $(8.00,10.00)^\circ$ | $0.30^\circ$ | $45^\circ$ | 0 dB | 0 | 二维斜向、等功率、较大间隔 |
| P2 | $(8.20,10.00)^\circ$ | $0.20^\circ$ | $0^\circ$ | -6 dB | 0 | 纯方位分离、弱次目标 |
| P3 | $(7.90,10.10)^\circ$ | $0.15^\circ$ | $90^\circ$ | 0 dB | 0.9 | 纯俯仰分离、强相关 |
| P4 | $(8.10,9.95)^\circ$ | $0.10^\circ$ | $135^\circ$ | -6 dB | 0.9 | 极小斜向分离、弱次目标、强相关 |

对应端点约为：

| Profile | 目标 1 `[az,el]` | 目标 2 `[az,el]` |
|---|---:|---:|
| P1 | $(7.893934,9.893934)^\circ$ | $(8.106066,10.106066)^\circ$ |
| P2 | $(8.10,10.00)^\circ$ | $(8.30,10.00)^\circ$ |
| P3 | $(7.90,10.025)^\circ$ | $(7.90,10.175)^\circ$ |
| P4 | $(8.135355,9.914645)^\circ$ | $(8.064645,9.985355)^\circ$ |

P4 生成时第二行端点的方位更小，但输出会按俯仰再方位规范排序。算法和误差评价都应允许目标标签交换。

### 14.3 快拍条件

注册快拍数为

$$
L\in\{1,4,8\}.
$$

它们不是三个不同阵列，而是同一阵列、同一局部单元可获得的复观测列数：

```text
L=1：只有单列数据，源在快拍维完全相干
L=4：可形成低样本协方差，仍有明显有限样本波动
L=8：样本协方差更稳定，但远小于阵元数 2080
```

Tangent 的 $S_R=RR^H/L$ 在 $L<15$ 时本身低秩并不构成错误；方向最终只需要其在二维 $B$ 子空间中的信息。相反，标准 MUSIC 要从样本协方差中稳定识别两个信号特征模态，对少快拍和相干源更加敏感。

### 14.4 72-trial decisive experiment

因子组合为

$$
2\ \text{噪声}
\times3\ \text{快拍数}
\times3\ \text{SNR 标签}
\times4\ \text{Profile}
=72.
$$

其中：

```text
噪声：WHITE、STAGE5_TOEPLITZ_CORRELATED
L：1、4、8
早期阵元能量 SNR 标签：-6、0、+6 dB
Profile：P1、P2、P3、P4
每个精确因子格：1 次实现
source seed base：3326074000
noise seed base：3326075000
```

三种方法 `CORE_LITE`、`CORE_PLUS`、`TANGENT_PROFILE_SAFE` 对每个 trial 共享完全相同的 `Y_element`，而不是各自重新生成噪声。

### 14.5 1680-trial white-SNR Monte Carlo

后续主验证为

$$
7\ \text{white-SNR}
\times2\ \text{噪声}
\times3\ L
\times4\ \text{Profile}
\times10\ \text{重复}
=1680.
$$

具体为：

```text
white-SNR：-6、0、+6、+10、+14、+18、+22 dB
噪声：WHITE、STAGE5_TOEPLITZ_CORRELATED
L：1、4、8
Profile：P1、P2、P3、P4
每个精确因子格：10 次独立重复
每个 SNR 总 trial：2×3×4×10 = 240
source seed base：430100000
noise seed base：430200000
```

White-SNR 是实验生成坐标，不作为 Tangent 的在线输入。估计器只读取观测、固定模型和局部域。

### 14.6 当前 `rho` 搜索在各场景中的几何含义

由于 `rho_max` 由 K1 中心和方向共同决定，它不是固定为 Profile 真值，也不是固定为局部域对角线。举例：

```text
若 u=[1,0]，只受方位边界限制；
若 u=[0,1]，只受俯仰边界限制；
若 u 两分量都非零，取两个坐标允许尺度的较小者；
若 K1 中心贴近某一边界，可行对称尺度会显著缩小。
```

因此中心偏差不仅改变端点位置，也通过 `rho_max` 改变一维搜索可行集。

---

## 15. 离线评价指标的精确定义

### 15.1 最优目标匹配

两个估计端点与两个真值端点之间存在 $2!$ 个匹配。离线评价选择总平方角误差较小的匹配；估计器内部不读取这个匹配结果。

令匹配后误差为

$$
e_k=\widehat{\boldsymbol\xi}_{\pi(k)}-\boldsymbol\xi_k.
$$

### 15.2 联合角度 RMSE

当前 trial 的联合二维角度 RMSE 定义为

$$
\boxed{
RMSE_{\rm joint}
=\sqrt{\frac12\sum_{k=1}^{2}\|e_k\|_2^2}
}.
$$

方位和俯仰 RMSE 分别为

$$
RMSE_{\rm az}
=\sqrt{\frac12\sum_{k=1}^2e_{k,\phi}^2},
$$

$$
RMSE_{\rm el}
=\sqrt{\frac12\sum_{k=1}^2e_{k,\theta}^2}.
$$

### 15.3 中心、轴和分离指标

估计中心误差：

$$
e_c=\left\|
\frac{\widehat\xi_1+\widehat\xi_2}{2}
-\frac{\xi_1+\xi_2}{2}
\right\|_2.
$$

无向轴误差：

$$
e_{\rm axis}=\acosd(|\widehat u^Tu|).
$$

Raw Tangent 的尺度误差：

$$
e_\rho=|\widehat\rho-\rho_{\rm true}|.
$$

最终安全输出的分离向量误差：

$$
e_d=
\left\|
(\widehat\xi_2-\widehat\xi_1)
-(\xi_2-\xi_1)
\right\|_2,
$$

其中仍需先处理端点匹配和方向符号。

联合角度 RMSE 较小不必然意味着 `rho` 恢复准确。例如两个估计都靠近真实中心时，每个端点的绝对误差可能尚可，但估计间隔可能严重收缩。

### 15.4 valid、upgrade、fallback 的区别

```text
raw tangent valid：
    方向和 profile 自己产生了有效连续 K2 候选

upgrade：
    raw tangent valid 且其 likelihood 不低于 fixed K2

fallback：
    最终输出来自 fixed K2

safe output valid：
    最终返回有效；可能来自 Tangent，也可能来自 fixed K2
```

因此 `safe valid = 100%` 不能解读为 raw Tangent 在所有 trial 都成功。

---

## 16. 早期 72-trial 结果及正确解释

### 16.1 总体结果

| 方法 | 有效输出 | 联合 RMSE median | 联合 RMSE P90 |
|---|---:|---:|---:|
| Core-Lite | 72/72 | $0.18381^\circ$ | $0.37919^\circ$ |
| Core-Plus | 72/72 | $0.14963^\circ$ | $0.37618^\circ$ |
| Tangent-Profile Safe | 72/72 | $0.07752^\circ$ | $0.25282^\circ$ |

Tangent 诊断：

```text
raw Tangent valid       70/72
upgrade                 59/72
fallback                13/72
对 Core-Lite            53 胜 / 13 平 / 6 负
对 Core-Plus            54 胜 /  7 平 / 11 负
报告 tie 容差           1e-6°
```

### 16.2 轴误差统计曾经有一个口径问题

原始 decisive report 使用有向误差，给出：

```text
oriented direction median/P90 = 7.7820° / 166.4330°
```

其中 13/72 个误差超过 90°，实质上主要是 $u$ 与 $-u$ 的等价符号。后续不重跑拟合，只更正诊断为无向轴误差：

```text
axis error median/P90 = 6.5719° / 27.9703°
```

更正没有改变任何估计角度、RSS、likelihood、RMSE、升级/回退或最终保留决定。

### 16.3 分离恢复不能过度表述

修正后的 72-trial 分离诊断为：

```text
rho error median/P90                 0.10684° / 0.22775°
relative rho error median/P90        0.93783 / 1.44758
selected separation median           0.21046°
selected-separation error median/P90 0.10761° / 0.30508°
separation-vector error median/P90   0.12421° / 0.34829°
raw rho lower-bound hits             23/72
```

所以证据支持的是：

> 在注册场景中，Tangent Safe 明显改善了联合角度 RMSE。

证据不支持：

> 在所有 trial 中稳定、无偏地恢复了真实双目标间隔。

尤其 `rho` 下界命中 23 次和相对 `rho` 误差中位数接近 1，说明“端点整体更接近真值”与“间隔尺度估得准确”是不同命题。

### 16.4 计算量和 MATLAB 墙钟时间

72-trial 报告中的中位运行时间大致为：

| 方法 | median runtime | 说明 |
|---|---:|---|
| Core-Lite | 0.168 s | 固定骨架很轻 |
| Core-Plus | 2.580 s | 连续四参数中心-差分精化 |
| Tangent Safe | 4.953 s | 一维 profile 每点仍重建完整流形并做 SVD |

Tangent 的注册 score/SVD 调用数低于 Core-Plus，但当前 MATLAB 原型墙钟时间更高。合理表述是：

> 理论驱动的低维候选，调用计数较低，但当前 MATLAB 实现尚不是运行时间更快的实现。

不能只凭“一维搜索”就宣称端到端速度一定高于四维基线。

---

## 17. 1680-trial white-SNR Monte Carlo 结果

### 17.1 Tangent 随 white-SNR 的总体变化

每个 SNR 行包含 240 个 trial：

| White-SNR | Tangent median RMSE | Tangent P90 | Fallback rate |
|---:|---:|---:|---:|
| -6 dB | $0.43848^\circ$ | $0.62665^\circ$ | 87.92% |
| 0 dB | $0.32109^\circ$ | $0.60966^\circ$ | 68.33% |
| +6 dB | $0.24274^\circ$ | $0.55283^\circ$ | 59.17% |
| +10 dB | $0.18382^\circ$ | $0.50000^\circ$ | 47.08% |
| +14 dB | $0.11633^\circ$ | $0.38290^\circ$ | 28.75% |
| +18 dB | $0.09210^\circ$ | $0.29342^\circ$ | 22.50% |
| +22 dB | $0.07962^\circ$ | $0.22361^\circ$ | 15.83% |

随着 white-SNR 增大，残差切向结构更容易超过固定网格候选，fallback 总体下降；但即使在 +22 dB 仍有 15.83% fallback，说明 Safe 基线不是只在极低 SNR 才参与。

### 17.2 工作区只是离线描述

提交证据把总体从 +10 dB 起的区间描述为经验工作区：

| Scope | 第一个稳定收益 SNR | 说明 |
|---|---:|---|
| ALL | +10 dB | 从首个观察点起总体单调 |
| P1 | +14 dB | 经验区间非严格单调 |
| P2 | +22 dB | 弱次目标纯方位场景最晚 |
| P3 | +10 dB | 强相关纯俯仰场景 |
| P4 | +14 dB | 极小、弱且相关 |

这不是在线门限。算法没有读取 white-SNR，也没有在 +10 dB 自动开关 Tangent。该“工作区”只用于总结已观察到的 Monte Carlo 结果，不能外推为未经验证场景的检测边界。

### 17.3 总体方法统计的另一视角

统一 1680 trial 汇总中：

| 方法 | valid | 总体 median RMSE | 总体 P90 |
|---|---:|---:|---:|
| Core-Lite | 1680/1680 | $0.27698^\circ$ | $0.54901^\circ$ |
| Core-Plus | 1680/1680 | $0.26680^\circ$ | $0.55678^\circ$ |
| Tangent Safe | 1680/1680 | $0.17979^\circ$ | $0.53952^\circ$ |
| Full4D Beamspace CML | 1680/1680 | $0.23159^\circ$ | $0.55083^\circ$ |

总体汇总跨越了 -6 到 +22 dB、两个噪声模型和四个难度差异很大的 Profile，因此只适合描述注册集合整体，不应替代分 SNR、分 Profile 的结果。

---

## 18. Core-Plus 和 Full4D 基线为何仍需保留

### 18.1 Core-Plus

Core-Plus 先得到与 Core-Lite 相同的固定 K2 候选，再从两个 grouped K2 起点做连续中心-差分精化。参数化为

$$
(c_{\rm az},c_{\rm el},d_{\rm az},d_{\rm el}),
$$

依次更新四个坐标。冻结合同包括：

```text
max sweeps              20
scan points/coordinate   9
center radius            0.20°
delta-az radius          0.40°
delta-el radius          0.20°
fminbnd TolX             1e-4°
fminbnd MaxFunEvals      80
minimum separation       0.001°
```

两个连续起点中选 likelihood 最大的有效者，再与固定 K2 做安全选择。它比 Tangent 的一维曲线自由度更高，但也更容易受到有限样本方差、局部极值和计算预算影响。

### 18.2 Full4D Beamspace CML

Full4D Beamspace CML 是与 Tangent 使用同一 $Z$、同一完整白化流形的传统 ML 比较。它先对 21 个注册点的不同点无序双目标对做完整枚举，共

$$
\binom{21}{2}=210
$$

个粗候选；按 likelihood 取前 6 个有效起点，再对四个中心-差分坐标连续精化，最多 12 sweep。每坐标扫 9 点并用相邻 bracket 做 `fminbnd`，`TolX=10^{-4}\ ^\circ`、`MaxFunEvals=80`，最小端点分离为 $0.001^\circ$。

理论上，若优化做到全局且预算无限，包含 Tangent 曲线的完整四维可行域不应给出更低的最大 likelihood。但当前结果比较的是**有限多起点、有限 sweep 的实际数值算法**。四维搜索可因局部极值或有限样本过拟合而在真值 RMSE 上弱于带结构约束的一维 Tangent。

这不是证明一维模型在所有情况下优于全局四维 ML，而是说明当前注册场景和预算下，结构化降维提供了有益的偏差-方差折中。

### 18.3 Full4D Element CML

Element CML 直接用阵元域及其噪声模型，硬件/数据接口和 Beamspace 方法不同，计算量也显著更高。统一比较中它只有预注册的一部分 trial 被执行，不能把其有效子集结果当成对全部 1680 场景的总体支配关系。

---

## 19. 经典子空间方法涉及的理论与当前实现

### 19.1 标准 MUSIC

对白化或阵元数据形成样本协方差

$$
\widehat R_z=\frac1LZZ^H,
$$

特征分解后取已知 $K=2$ 的信号子空间 $U_s$ 和噪声子空间 $U_n$。二维 MUSIC 谱为

$$
P_{\rm MUSIC}(\boldsymbol\xi)
=\frac{1}{g(\boldsymbol\xi)^H
U_nU_n^H g(\boldsymbol\xi)}.
$$

当前 Beamspace 和 Element MUSIC 都在二维域上使用 $0.005^\circ$ 步长谱网格，再寻找两个峰。方位共有 241 点，俯仰共有 81 点，总谱点评价数为

$$
241\times81=19521.
$$

`L=1` 时样本协方差的信号子空间秩不足以按标准方法支持两个信号特征向量，因此被预注册为 structural N/A，而不是算法运行失败。

近邻、相干、弱次目标和少快拍会使第二信号特征模态不稳定，两个谱峰可能合并或第二峰不可信。这是当前 MUSIC 大量 algorithmic invalid 的主要原因。

### 19.2 GFBSS-MUSIC

Generalized Forward-Backward Spatial Smoothing 利用圆柱活动子阵的 32 层垂直等距结构：

```text
垂直阵元数          32
平滑子阵长度        31
平滑子阵数          2
俯仰谱网格          9.8:0.001:10.2°
```

空间平滑试图恢复相干源协方差秩，forward-backward 平均再利用共轭对称结构。但这里只有两个高度重叠的 31 元子阵，平滑自由度有限；而且它首先只估计两个俯仰角。

得到两个有效且不同的俯仰后，代码再固定俯仰，用方位 CML 搜索/精化方位。方位粗轴为


```text
7.4:0.02:8.6°     共 61 点
```

两个已区分俯仰对应的有序方位粗组合为 $61^2=3721$ 个，选前 4 个有效起点；随后最多 8 sweep，每个方位坐标扫 9 点并用 `fminbnd` 精化。P2 两目标俯仰完全相同，对这类“先分两个俯仰”的结构化方法是预注册 structural N/A。

### 19.3 Root-MUSIC

Root-MUSIC 把垂直 ULA 的噪声子空间正交条件写成关于复变量 $z$ 的多项式，通过靠近单位圆的根恢复俯仰：

$$
z=e^{jk_0d_z\sin\theta}.
$$

它避免了俯仰谱密集扫描，但标准形式依赖白噪声和理想移位结构。当前只对白噪声、不同俯仰的 Profile 注册为 applicable；相关噪声和 P2 被标为 structural N/A。得到俯仰后同样接方位 CML。

### 19.4 LS-ESPRIT

ESPRIT 利用相邻垂直子阵信号子空间的旋转不变性：

$$
U_{s,2}\approx U_{s,1}\Psi.
$$

LS 解出 $\Psi$ 后，其特征值相位满足

$$
\angle\lambda_k(\Psi)
=k_0d_z\sin\theta_k,
$$

从而

$$
\widehat\theta_k
=\arcsin\left(
\frac{\angle\lambda_k}{k_0d_z}
\right).
$$

当前 LS-ESPRIT 同样只对白噪声且两个俯仰不同的场景注册适用，再接方位 CML。重复俯仰、子空间秩不足、特征值越出局部域等都会形成算法无效状态。

### 19.5 三种结果状态必须分开

| 状态 | 含义 | 是否计入有效 trial 的 RMSE |
|---|---|---|
| structural N/A | 方法结构先验不适用于该已注册场景，例如 MUSIC 的 $L=1$、Root-MUSIC 的相关噪声、P2 的等俯仰 | 否 |
| algorithmic invalid | 方法按规则适用并已运行，但没有产生两个满足合同的角度 | 否 |
| valid output | 产生两个有效角度 | 是 |

不能把 structural N/A 当成一次错误估计，也不能把 algorithmic invalid 删除后只报告少数成功样本而宣称总体精度高。

### 19.6 当前经典方法的适用和有效计数

| 方法 | 总 trial | applicable | valid | structural N/A | algorithmic invalid |
|---|---:|---:|---:|---:|---:|
| Beamspace MUSIC | 1680 | 1120 | 0 | 560 | 1120 |
| Element MUSIC | 1680 | 1120 | 3 | 560 | 1117 |
| GFBSS-MUSIC + az CML | 1680 | 1260 | 5 | 420 | 1255 |
| Root-MUSIC + az CML | 1680 | 630 | 5 | 1050 | 625 |
| LS-ESPRIT + az CML | 1680 | 630 | 7 | 1050 | 623 |

这些计数说明当前注册近邻场景下没有形成稳健的经典双目标输出区间。它们不能推广成“这些方法一般无效”；结论只针对当前阵列、少快拍、相干/弱源、近间隔和严格两峰有效性合同。

---

## 20. 缓存和工程加速与 Tangent 数学的关系

### 20.1 连续 T4 exact cache

`rho` 经 `fminbnd` 产生连续浮点端点，跨 trial 或跨评价精确命中注册字典的机会很小。实测 exact cache：

```text
hit  = 0
miss = 346
```

也就是 `0 hit / 346 miss`。

因此不能声称该连续 exact cache 已带来加速。调用内对相同 `rho` 的去重与跨调用流形缓存是两件不同的事。

### 20.2 固定注册骨架 cache

K1/K2 固定部分反复查询同一 21 个注册物理角点，适合缓存单列白化流形。验证结果：

```text
缓存注册点数                    21
结果等价                        72/72
相对 legacy 完整流形端到端降低  约 2.1527%
speedup                         约 1.0221×
```

收益较小是因为完整 Tangent 还包含 K1 连续候选、中心导数、连续 `rho` profile、DML SVD 和 MATLAB 调度开销。

### 20.3 多中心圆柱旋转复用

圆柱阵不同扇区中心的局部活动子阵具有旋转等价性。把实际中心映射到 canonical 局部方位坐标，可复用流形字典。证据显示：

```text
字典构建成本降低约 86%
存储降低约 82%
运行 sentinel 端到端收益约 1.7%
```

这种复用要求阵元 canonical 顺序、权值顺序和中心映射完全一致。它优化的是流形生成，不改变 $P_g^\perp$、$T$、$C_t$、广义方向、`rho` DML 或 Safe selector。

### 20.4 为什么理论低维不自动等于实现快

Tangent 的搜索参数只有一个 `rho`，但每个函数值仍包含：

```text
两个完整 2080 阵元 steering 的生成
阵元顺序转换
15 个波束投影
白化
K2 数值秩 SVD
集中 DML SVD
MATLAB 函数和审计调用
```

若不优化这些内核，一维优化器的参数维数优势可能被单次评价成本抵消。

---

## 21. 当前算法能够怎样解释，不能怎样解释

### 21.1 证据支持的表述

可以说：

> 在当前固定圆柱阵、15 维精确白化顺序 Beamspace、已知 K=2、同一距离-多普勒单元、注册局部角域和给定 Profile/SNR/快拍条件下，Tangent-Profile Safe 用 K1 投影残差估计分离轴，再沿该轴做完整流形一维集中 DML，并以固定 K2 likelihood fallback 保持全部 trial 有效输出。现有 72-trial 与 1680-trial 证据显示，它在注册集合上改善了联合角度 RMSE，收益在较高 white-SNR 时更稳定。

### 21.2 证据不支持的表述

不能说：

```text
自动估计了目标数 K
在所有 SNR 或所有场景都优于四维 ML
每个 trial 的真实 RMSE 都因 Safe selector 而不变差
稳定恢复了所有真实目标间隔
T 是完整 Fisher 信息矩阵
达到了 CRLB
当前 MATLAB 实现一定比 Core-Plus 或 Full4D 更快
+10 dB 是算法的在线启停门限
经典方法在一般问题中都无效
缓存改变或改进了 Tangent 的统计估计公式
```

---

## 22. 已发现的问题、不确定性和使用边界

### 22.1 路径写法不一致

用户给出的路径是 `E:\bs\_innovation\summary`，实际工作区和仓库是 `E:\bs_innovation`。本文按后者创建。若另有一个独立的 `E:\bs\_innovation` 目录，本次没有读取或写入它。

### 22.2 K1 中心偏差是结构性误差源

Tangent profile 固定在 K1 等效中心两侧对称。弱次目标、相关源和流形曲率都可能令 K1 中心偏向强目标。当前没有中心-`rho` 联合再优化，也没有用 Hessian 做中心修正。

### 22.3 一阶方向在差模弱时会退化

当 $s_1\approx s_2$ 时，一阶差模 $q=s_2-s_1$ 变弱；此时残差可能更多由曲率、中心偏差和噪声决定。Safe 可以回退到固定 K2，但没有在线置信度证明“返回的方向可靠”。

### 22.4 没有 eigengap 门限

代码检查 $T$ 满秩，却不检查 $C_tu=\mu Tu$ 的两个广义特征值是否充分分离。最大特征值近似重根时，方向可对很小扰动敏感。当前证据记录广义特征值，但没有把 eigengap 变成 selector 条件。

### 22.5 没有显式噪声底扣除

理想白化各向同性噪声只平移广义特征值，因此不扣底有合理理论依据；有限 $L$ 下样本噪声并不各向同性。现实现没有估计并扣除该随机底，也没有 shrinkage 协方差。

### 22.6 `rho` 下界命中较多

72-trial raw profile 中有 23 次命中 $0.001^\circ$ 下界。它提示分离尺度估计存在明显收缩或不可辨情况。论文或报告应同时给出联合角 RMSE、`rho` 误差、分离向量误差和下界命中率。

### 22.7 SNR 名称存在历史口径差异

早期 72 trial 的 `snr_db` 是阵元域能量缩放标签，后续 1680 trial 是 white-SNR。若只看列名或图标题而忽略生成器，很容易把两套结果错误合并。

### 22.8 Safe 是 likelihood-safe，不是 RMSE-safe

最终选择完全不使用真值，这是正确的数据隔离；代价是较高 likelihood 不保证较小真值误差。当前 72 trial 对 Core-Lite 仍有 6 次 RMSE 负例，对 Core-Plus 有 11 次。

### 22.9 `K=2` 和局部域由上游保证

如果真实 K 不是 2，或者任一目标在局部域外，当前模型会产生模型失配。算法没有自动扩域、自动估 K 或多模型选择。

### 22.10 角平面使用普通欧氏距离

当前局部域很小且位于约 $10^\circ$ 俯仰，使用 `[az,el]` 度坐标的欧氏 `rho` 是合理局部近似。但在大视场或高俯仰下，相同方位差对应的球面角距离不同；当前 `rho` 不是全局球面测地距离。

### 22.11 统计外推范围有限

验证只覆盖：

```text
四个固定几何/功率/相关 Profile
L = 1、4、8
两种指定噪声模型
white-SNR -6 到 +22 dB
一个 10 GHz、192×32、活动 65 列圆柱阵
一个 15 通道主 DBF 配置
```

阵列校准误差、互耦、宽带失配、非高斯噪声、多个距离-多普勒泄漏源、K>2、运动角变化和真实硬件量化不在当前闭环证据内。

此外，72-trial 实验的每个精确因子格只有一次实现，不能从单格估计方差或尾分位数；1680-trial 实验每个精确格有 10 次重复，单格 P90 仍只是描述性统计，不是稳定的尾部风险估计。

### 22.12 经典方法的有效样本极少

Element MUSIC、GFBSS、Root-MUSIC、ESPRIT 只在极少数 applicable trial 输出有效角度，因此其有效子集 RMSE 不能和 Tangent 的 1680/1680 覆盖率作无条件总体数值比较。首先应报告 applicability 和 valid rate，再讨论 common-valid 子集。

### 22.13 本次没有重新运行 MATLAB

本文依据当前源代码和已提交 CSV/Markdown 证据逐项核对，没有重新执行 72 或 1680 trial。正式全量复现依赖 MATLAB R2022b 和仓库外注册 runtime 目录；历史运行还建议使用 `-singleCompThread` 以降低运行时间可比性中的线程差异。

---

## 23. 关键证据文件

| 证据 | 用途 |
|---|---|
| `innovation-mining/31_stage8_k2_tangent_profile_summary.csv` | 72-trial 三方法总体与分组结果 |
| `innovation-mining/31_stage8_k2_tangent_profile_trials.csv` | 72-trial 方法输出明细 |
| `innovation-mining/32_stage8_k2_tangent_profile_diagnostic_correction.md` | 有向方向误差改为无向轴误差的正式更正 |
| `innovation-mining/32_stage8_k2_tangent_profile_corrected_geometry_analysis.csv` | 轴、`rho`、分离向量和下界命中统计 |
| `innovation-mining/44_stage8_k2_white_snr_monte_carlo_summary.csv` | 1680-trial white-SNR 结果 |
| `innovation-mining/44_stage8_k2_white_snr_monte_carlo_and_route_closure.md` | 工作区描述与完整性闭环 |
| `innovation-mining/48_stage8_k2_white_snr_all_method_applicability_summary.csv` | 十种方法 applicability/valid/invalid 统计 |
| `innovation-mining/48_stage8_k2_white_snr_all_classical_comparison.md` | 经典方法比较解释边界 |
| `innovation-mining/54_stage8_k2_tangent_fixed_backbone_cache_runtime_summary.csv` | 固定骨架 cache 端到端运行证据 |

---

## 24. 最终综合判断

Tangent-Profile Safe 的真正贡献不在于“发明了一个新的四维全局优化器”，而在于把当前近邻双目标问题中最有价值的局部结构显式利用起来：

1. K1 先吸收近目标的公共模态，给出数据驱动的等效中心。
2. 投影消去该中心的未知复幅度方向，使残差更集中地暴露分离信息。
3. 投影 Jacobian $B$ 把残差限制到实际圆柱阵、实际 15 通道白化 Beamspace 的二维局部切空间。
4. $T$ 对阵列方向灵敏度归一化，$C_t$ 提取残差切向能量，最大广义 Rayleigh 商给出无向分离轴。
5. 一阶理论只决定轴；完整非线性流形的一维 DML 决定尺度。
6. 固定 K2 likelihood fallback 保护当前观测上的拟合质量和输出覆盖率。

它的优势来自强结构约束带来的有限样本偏差-方差折中，而其风险也来自同一约束：K1 中心偏差、差模过弱、局部流形曲率和错误方向都可能使真实端点不在所搜索的对称直线上。现有证据表明该折中在注册场景中对联合角度 RMSE 有效，但分离尺度的稳定恢复仍明显弱于“所有端点都准确恢复”这一更强命题。

因此，对当前算法最准确的总体定位是：

> 一个面向固定圆柱阵白化 Beamspace、已知 K=2 的近邻双目标局部条件 ML 估计器：用投影切空间确定一维分离轴，用完整流形 profile likelihood 确定尺度，并用固定网格 K2 做 observation-only 安全回退。
