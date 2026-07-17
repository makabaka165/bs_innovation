# v0.19 顺序测角修订范围说明

> 版本：Step12.4 阶段 6 修订，2026-07-17
> 活跃相位模型：`phase_factor=1`
> 当前结论：接收流形、真实先俯仰后方位 DBF、稳定 SVD-DML，以及
> oracle-Q 注册局部网格下的俯仰组 DML、matrix-normal 行/列白化、
> 三层状态语义、物理环向组恢复、条件方位 DML 和固定完整顺序流形修正已通过技术与 Pareto 工程门；固定白化顺序流形的近双目标非退化三式与 synthetic exact-null 六阶候选已通过确定性验证。所有有噪声结果仍未统计校准。

## 1. 系统层级

| 层级 | 规范名称 | 本项目责任 |
|---|---|---|
| 1 | 阵元数字接收链路 | 射频、下变频、ADC、数字下变频、脉压，形成阵元复数据 |
| 2 | 常规顺序 DBF 与检测处理 | 形成俯仰/方位波束、距离–多普勒检测、常规粗角度与误差描述 |
| 3 | 局部未分辨目标簇超分辨测角 | 在局部角域内执行 K1/K2 判定和精细二维角估计 |
| 4 | 航迹与资源管理 | 数据关联、跟踪、跨 CPI 处理和波束调度 |

候选研究路线位于第 3 层。局部角域只能来自第 2 层的常规测角置信域
或常规波束角分辨单元，不能描述为来源不明的人工固定窗口。阶段 4
使用预注册局部 full-reference 网格和 oracle Q 隔离验证估计器；这不是
自动分组，也不是全空域盲搜。

## 2. 接收相位与旧结果边界

接收阵列流形固定为

\[
\mathbf a(az,el)=\exp\left(j\frac{2\pi}{\lambda}
\mathbf p^T\mathbf u(az,el)\right),
\qquad \mathrm{phase\_factor}=1.
\]

目标距离对应的单站双程公共相位吸收到目标复包络。新活跃接收函数
没有相位因子分支。全部圆柱阵 Step11 数值结果仍冻结为 factor=2 legacy
evidence，不得作为 v0.19 的成功率、RMSE、复杂度或运行时间证据，也不得
用于选择 factor=1 的网格、阈值或波束数。

## 3. 阶段 4 数据合同

对每个 snapshot，physical elevation-DBF 数据满足

\[
Z_{\rm left}=T_{\rm row}Z_{\rm raw},\qquad
Z_{\rm score}=Z_{\rm left}T_{\rm col}^{H}.
\]

其中

\[
T_{\rm row}(V^H R_zV)T_{\rm row}^H=I_{r_{\rm row}},
\qquad
T_{\rm col}R_{\phi,\rm sel}T_{\rm col}^H=I_{r_{\rm col}}.
\]

两侧白化器均复用 Step12.2 的有效子空间 PSD 白化规则。固定坐标为：

| 量 | 维度 | 用途 |
|---|---:|---|
| `Zel_raw` | `[B_phys,Nphi,L]` | 物理俯仰 DBF 输出 |
| `T_row` | `[r_row,B_phys]` | 波束行协方差白化 |
| `T_col` | `[r_col,Nphi]` | 选定环向列协方差白化 |
| `Z_score_mmv` | `[r_row,r_col*L]` | 仅用于 DML 评分 |
| `Z_recovery_mmv` | `[r_row,Nphi*L]` | 仅用于物理环向组恢复 |
| `Ge` | `[r_row,Q]` | 只含固定俯仰波束和行白化 |
| `Ce_score` | `[Q,r_col*L]` | 右白化评分系数 |
| `Ce_recovery` | `[Q,Nphi*L]` | 物理环向恢复系数 |

右白化只作用在 nuisance coefficient 列，不进入 `Ge`。候选搜索期间物理
波束、行列协方差、两个白化器和注册候选域均固定。外部角度使用 degree，
解析导数使用 radian；`phase_factor=1`。`L=1` 时的环向列是 MMV 系数观测，
不是独立时间快拍。

## 4. 三层状态语义

阶段 4 将输出严格拆为：

1. `estimate_status`：估计器是否返回注册候选；
2. `support_status`：当前注册模型的结构证据；
3. `statistical_calibration_status`：统一为 `NOT_CALIBRATED_STAGE4`。

`GROUP_REGISTERED_MODEL_CERTIFIED` 只用于 oracle-Q、注册候选库、无噪声或
精确结构证据下的确定性认证，不表示统计置信。有噪声正常场景只能返回
`GROUP_REGISTERED_MODEL_SUPPORTED_UNCALIBRATED`。有噪声数据中的
`rank(Z_score_mmv)`、`rank(Z_recovery_mmv)` 和 `rank(Ce_hat)` 只作诊断，
不得决定确定性认证。

精确 `rank(Ce)<Q` 反例返回：

```text
estimate_status = ESTIMATE_NOT_RUN_STRUCTURAL_RANK_FAILURE
support_status  = GROUP_MMV_RANK_UNCERTIFIED
```

其含义仅为当前注册 Q 组 MMV 分组/恢复链未获得结构认证，不构成所有非线性
参数化方法下的一般物理不可辨识证明。有限注册候选库的 exact alias 检查也
不是连续参数域全局唯一性证明。

## 5. 公共/测试边界

公共估计器和恢复函数不读取测试真值。公共恢复函数只求解
`Ce_hat_recovery`、恢复每组 `[Nphi,L]` 数据并报告数值秩/求解状态。相对
Frobenius 误差、子空间弦距、串扰和 mixing 误差只由
`tests/private/evaluate_group_recovery_against_truth.m` 计算，不进入候选评分、
搜索域构造或停止条件。

阶段 5 的条件路径只使用阶段 4 恢复的 `Xphi_hat{q}` 形成初始化；最终联合
评分回到原始 factor=1 阵元数据，并固定 `Wseq`、`Cseq`、`Tseq` 和物理角域。
公共角域构造器只接受常规中心与冻结工程偏移，不接受真值。目标 Hungarian/
最小代价匹配、`truth_in_domain_flag`、错误局部峰、local-full 对应关系和成功
判定均在测试评价层。只有上游 `estimate_returned_flag` 与
`structural_gate_pass_flag` 同时为真，条件和分组联合链才运行；否则返回
`UPSTREAM_GROUP_STAGE_UNCERTIFIED`，不扩窗、不降低秩门。

阶段 5 的固定全孔径维度为：`Xphi [65,L]`、`Uq [65,3]`、
`Zphi [3,L]`、`Tphi [3,3]`、`Wseq [2080,9]`、`Zseq [9,L]`、
`Tseq [9,9]`、`Gphi [3,Kq]` 和 `Gseq [9,K]`。所有固定对象和统一角域
均保存 hash；有噪声输出统一为 `NOT_CALIBRATED_STAGE5`。

## 6. 阶段 6 固定白化流形合同

阶段 6 的主理论对象固定为

\[
g(\phi,\theta)=T_{\rm seq}W_{\rm seq}^{H}a_{\rm receive}(\phi,\theta),
\]

其中 `Wseq`、`Cseq=Wseq'*Rn_elem*Wseq`、`Tseq` 和有效白化秩在一个测量
配置内均固定，不随中心、方向或分离尺度改变。4 个主配置的顺序通道数为
9、9、6 和 6；单通道配置只用于测量完全塌缩诊断。9 个中心、4 个固定
per-radian 方向和 9 个分离尺度形成 1296 个主 secant case。

对 $T=\operatorname{Re}\{J_g^H\Pi_g^\perp J_g\}$ 和
$q_{\mathbf v}=\mathbf v^{T}T\mathbf v>0$，阶段 6 验证
$\sigma_2^2\sim r^2q_{\mathbf v}/2$、
$1-|\rho|^2\sim r^2q_{\mathbf v}/\|g\|^2$ 和
$\kappa(\bar G^H\bar G)\sim4\|g\|^2/(r^2q_{\mathbf v})$。
144 个预注册尾区全部通过，最大 ratio 误差分别为 `4.0102e-6`、
`1.0421e-5` 和 `6.1180e-6`。三类不变性最大误差为 `9.4336e-13`。

解析 fixture $g(x,y)=[1,x,y^3]^T$ 支持
$\sigma_2^2\sim r^6\|v_{3,\rm eff}\|^2/2$，拟合阶数为 6；但 4 个主物理
配置均无 exact tangent null，故六阶扩展没有物理实例证据。统计范围固定为
`DETERMINISTIC_GEOMETRIC_VALIDATION`，不得写成有限样本可分辨、低 SNR
threshold 已解决或强相干已解决。

## 7. 当前证据

| 主张 | 证据 | 状态 |
|---|---|---|
| factor=1 接收流形及弧度导数正确 | 9 中心，最大导数误差 az `1.020e-9`、el `1.476e-9` | supported |
| 真实顺序 DBF 与等效矩阵一致 | 随机/单目标/双目标误差均 `<2e-15` | supported |
| Step12.2 有效子空间白化与 SVD-DML 稳定 | `pinv` 对照最大误差 `1.681e-15` | supported |
| 阶段 4 行/列白化正确 | 单元测试最大误差 `1.059e-15 / 1.136e-15` | supported |
| separable 与小型显式 Kronecker 一致 | data/score/RSS `1.199e-16 / 0 / 0` | supported |
| oracle-Q 注册俯仰组 DML | 9 个物理场景和 1 个结构反例全部通过 | supported within registered scope |
| 有噪声场景未被确定性认证 | 2/2 主场景均为 `SUPPORTED_UNCALIBRATED` | supported |
| 精确系数秩反例语义正确 | `rank(Ge)=2`、`rank(Ce)=1`，返回 MMV-rank uncertified | supported |
| 相关行/列噪声精确建模 | `T_col` 已应用，行/列误差 `7.941e-13 / 3.052e-15` | supported for specified separable covariance |
| 同俯仰 Q1/K2 组内叠加恢复 | 相对误差 `3.891e-15` | supported |
| 组恢复噪声传播 | 20,000 样本完整协方差误差 `1.448e-2`，保留组间相关项 | supported |
| 条件方位流形与弧度导数 | 公式/导数误差 `3.606e-15 / 5.618e-10` | supported |
| 条件方位白化 | 30,000 样本协方差误差 `4.862e-3` | supported |
| 完整顺序数据、协方差和流形 | staged 误差 `3.697e-15`，协方差 MC 误差 `1.490e-2`，流形误差 0 | supported |
| 联合修正 | 单调违规 0，确定性主链/local-full score gap `8.106e-16` | supported |
| normal holdout | 主链 205/205，Wilson 95% `[0.9816,1]` | supported within registered domain |
| stress holdout | 主链 45/250，Wilson 95% `[0.1373,0.2324]` | recorded limitation |
| 主链相对两初值直接 AP | 成功率差区间 `[0,0]`，score calls 减少 `44.95%` | Pareto scheme 1 passed |
| 相干弱目标核心 stress | 主链/直接 AP/local-full 均 `0/200` | registered failure boundary |
| PR-DML 与 Kim 2012 | `EXACT_REPRODUCTION_UNAVAILABLE` | open baseline gap |
| 固定白化近双目标非退化三式 | 1296 case、144/144 注册尾区通过 | scenario-specific deterministic corollary |
| synthetic exact-null 六阶候选 | 拟合阶数 6，ratio 误差 `2.220e-16` | supported on analytic fixture only |
| 主物理 exact tangent null | 4 个主配置均未发现 | `NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND` |
| FIM、bootstrap、自动 Q、K=3 | 无 | not started |

阶段 5 另含方位/俯仰半网格、同时 off-grid、边界、部分出域、极近、弱目标、相干、相关噪声、缩孔径和 `L=1/L>1` 场景。成功判定使用固定最终网格门；出域样本不扩窗并计入无条件失败。AP 属经典方法，PR-DML/Kim 的准确复现缺口仍保留，没有用自定义简化版本替代。

## 8. 后续阶段门

阶段 6 已通过固定测量、导数、投影几何、非退化三式、精确恒等式、几何不变性、synthetic null 和 prior-art 边界门，但本轮必须停止。只有用户后续单独授权，才可进入阶段 7。exact-subset FIM、模型阶数 bootstrap、自动 Q、K=3、cache 与硬件映射均未实现。
