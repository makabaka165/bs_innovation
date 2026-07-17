# 新主线实验体系、推荐代码结构与后续展开路径

> 建议仓库位置：`innovation-mining/12_experiment_system_code_structure_roadmap.md`  
> 必须先读：`innovation-mining/11_sequential_beamspace_ml_innovations_theory.md`  
> 目的：把理论主张拆成可执行、可否决、可复现实验和清晰代码模块。  
> 原则：不在旧 C05、fixed topK3 或经验 W-score 上继续叠加规则。

---

## 0. 总体开发策略

新的开发顺序应为：

```text
接收单程模型和稳定 DML 内核
        ↓
真实顺序 DBF 数据流
        ↓
俯仰分组 DML
        ↓
条件方位 DML
        ↓
完整顺序流形联合修正
        ↓
切向理论数值验证
        ↓
Fisher 信息最小波束集
        ↓
K1/K2 bootstrap 与不可分辨输出
        ↓
K=3 有限扩展
        ↓
完整实验、论文重写与 cache 优化
```

每个阶段必须有独立入口、单元测试、结果目录、通过/否决标准。上一阶段没有通过时，不得继续通过增加阈值或保护分支掩盖问题。

---

## 1. 仓库中的建议位置

### 1.1 文档

```text
innovation-mining/
  10_current_paper_innovation_audit.md
  11_sequential_beamspace_ml_innovations_theory.md
  12_experiment_system_code_structure_roadmap.md
  13_next_step_execution_prompts.md
  FAILED_likelihood_discriminative_adaptive_wb.md
```

### 1.2 新算法代码

为了保留 Step11 证据链并避免混淆，建议新建：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_sequential_grouped_beamspace_ml/
    README.md
    common/
    stage0_receive_model_and_svd_dml/
    stage1_sequential_dbf_equivalence/
    stage2_elevation_group_dml/
    stage3_conditional_azimuth_dml/
    stage4_joint_local_refinement/
    stage5_tangent_information_validation/
    stage6_fim_beam_budget/
    stage7_model_order_bootstrap/
    stage8_k3_extension/
    stage9_final_evidence_summary/
```

旧 Step11.1/11.2/11.3/11.5/11.6/11.7 保留为历史 baseline 和审计材料。除接收单程相位一致性修复、通用底层函数修复和结果失效标记外，不直接重写旧结果目录。

### 1.3 EI 小论文试验场

```text
EI_paper/code/
```

用于先完成固定方位、仅俯仰维的低风险验证：

- 接收单程模型；
- SVD-DML；
- 俯仰切向信息；
- 一维 Fisher 信息波束预算；
- K1/K2 bootstrap。

EI 通过后，再迁移到完整顺序 DBF 主线。

---

## 2. 阶段 0：全仓库接收单程相位与术语修正

## 2.1 代码修改

必须全仓库检索：

```text
spatialPhaseFactor
phaseFactor
PhaseFactor
双程相位
双程传播
eta_rt
4*pi/lambda
```

核心修改：

```matlab
% core/config/sim_cfg.m
cfg.beam.spatialPhaseFactor = 1;
```

统一注释：

```matlab
% 接收阵列单程空间相位。
% 目标距离双程公共相位吸收到未知目标复包络中，
% 不在接收空间导向矢量中额外乘 2。
```

### 必须检查的已知文件

```text
beamspace_ml_v18/source/stepwise_signal_model/core/config/sim_cfg.m
beamspace_ml_v18/source/stepwise_signal_model/core/beamforming/bf_azimuth.m
beamspace_ml_v18/source/stepwise_signal_model/core/beamforming/bf_elevation.m
beamspace_ml_v18/source/stepwise_signal_model/core/beamforming/bf_joint_2d.m
beamspace_ml_v18/source/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/build_cyl_steering_vec.m
beamspace_ml_v18/source/stepwise_signal_model/steps/step_11_2_beamspace_w_design/common/select_w_greedy_from_pool.m
EI_paper/code/run_cyl_beamspace_ml_demo.m
```

### 旧结果处理

所有在 phase factor 2 下得到的结果必须标记为失效，不允许仅修改正文公式后继续引用旧 CSV/PNG/MAT。

建议在旧结果根目录增加：

```text
INVALIDATED_BY_RECEIVE_PHASE_FACTOR_CHANGE.md
```

内容至少说明：

- 原结果使用 phase factor 2；
- 新主线使用接收单程 factor 1；
- 波束宽度、网格、分离阈值、W、cache、CRB、RMSE 和成功率均需重新生成；
- 文件保留仅用于历史审计。

## 2.2 文档术语修改

将下列表述统一替换：

| 旧表述 | 新表述 |
|---|---|
| 前端给出粗中心 | 常规顺序 DBF 与检测处理定位当前距离–多普勒–角度单元 |
| 后端 beamspace ML | 局部未分辨目标簇波束域超分辨测角模块 |
| 前端窗口 | 常规测角置信角域或当前常规波束角分辨单元 |
| 实现全息凝视雷达工作模式 | 面向全息凝视雷达顺序 DBF 链路中的局部精测角环节 |

## 2.3 阶段通过标准

- 全仓库不再存在被主线调用的 phase factor 2；
- 接收导向矢量、回波模型、DBF 权和论文公式一致；
- EI 与 v18 主线采用相同单程约定；
- 所有旧 phase factor 2 结果均有失效说明；
- 新代码测试不读取旧正面结果作为新证据。

---

## 3. 阶段 1：稳定数学内核

建议在

```text
step_12_sequential_grouped_beamspace_ml/common/
```

实现以下函数。

## 3.1 接收导向矢量

```matlab
function a = build_cyl_receive_steering(x, y, z, az_deg, el_deg, lambda)
```

要求：

- 只实现单程接收空间相位；
- 输入角度为 degree，内部明确转换；
- 输出固定为 `M x 1`；
- 不再提供 `PhaseFactor` 选项，防止新主线误用；
- 旧兼容函数保留，但新 Step12 禁止调用旧 phase-factor 接口。

## 3.2 解析导数

```matlab
function [a, daz, del] = build_cyl_receive_steering_with_derivatives( ...
    x, y, z, az_deg, el_deg, lambda)
```

输出：

```text
a   : M x 1
 daz : M x 1，单位为“每度”
 del : M x 1，单位为“每度”
```

必须用中心差分验证：

\[
\frac{\|d_{\rm analytic}-d_{\rm FD}\|_2}
{\max(\|d_{\rm FD}\|_2,\epsilon)}
<10^{-6}
\]

默认差分步长建议从 \(10^{-5}\) degree 开始，并做步长敏感性检查。

## 3.3 一般白化

```matlab
function [Zw, Gw, info] = whiten_beamspace_general(Z, G, Cb, opts)
```

要求：

- `Cb` 由调用者显式传入；
- 阵元白噪声时调用者传入 `W' * W`；
- 一般噪声时传入 `W' * Rn * W`；
- 使用 Hermitian eig/SVD；
- 特征值阈值采用相对尺度：

```matlab
floor_val = opts.rel_floor * max(eigvals);
```

- 输出有效秩、最小保留特征值、白化后协方差误差；
- 不使用固定绝对 `1e-10` 作为唯一保护。

## 3.4 SVD-DML

```matlab
function [score, rss, info] = dml_score_svd(Zw, Gw, opts)
```

要求：

- 使用 economy SVD 或 pivoted QR；
- 默认数值秩阈值：

```matlab
rank_tol = max(size(Gw)) * eps(class(Gw)) * max(singular_values);
```

- `score = norm(Ur' * Zw, 'fro')^2`；
- `rss = norm(Zw, 'fro')^2 - score`；
- 数值上强制 `rss >= 0` 只能用于浮点舍入保护，不得掩盖明显负值；
- 输出有效秩、奇异值、rank deficient 标志。

## 3.5 必做单元测试

```text
test_receive_steering_phase_factor_one.m
test_receive_steering_derivatives.m
test_whitening_identity_covariance.m
test_dml_svd_vs_pinv_reference.m
test_dml_unitary_invariance.m
test_dml_rank_deficient_pair.m
```

阶段通过标准：

- 导数误差通过；
- 白化协方差相对误差 `< 1e-10`（双精度、良态测试）；
- SVD-DML 与高精度 pseudoinverse 参考在良态样本上相对误差 `< 1e-10`；
- 近共线样本不出现 NaN/Inf；
- 对酉变换后的 beamspace，score/RSS 一致。

---

## 4. 阶段 2：真实顺序 DBF 数据流

当前 `bf_elevation.m` 和 `bf_azimuth.m` 都直接读取阵元数据，`bf_joint_2d.m` 直接形成若干二维波束，尚未形成严格的“先俯仰、再方位”级联数据流。

## 4.1 建议接口

### 俯仰 DBF

```matlab
function out = form_elevation_dbf(pcCube, geom, cfg)
```

输入维度：

```text
pcCube : [Nphi * Nz, Nrange, Npulse]
```

输出：

```text
out.data       : [Be, Nphi, Nrange, Npulse]
out.weights    : [Nz, Be] 或每个环向列共享的垂直权
out.beam_el    : [1, Be]
out.noise_gram : [Be, Be]
out.meta       : 阵元顺序、角度单位、phase convention
```

实现时先将阵元维恢复为

```text
[Nz, Nphi, Nrange, Npulse]
```

再沿 `Nz` 维做俯仰 DBF。

### 方位 DBF

```matlab
function out = form_azimuth_dbf_from_elevation(elOut, geom, cfg)
```

输入：

```text
elOut.data : [Be, Nphi, Nrange, Npulse]
```

输出：

```text
out.data       : [Be, Ba, Nrange, Npulse]
out.weights    : 方位权；允许按俯仰波束 b 变化
out.beam_az    : [Be, Ba] 或 [1, Ba]
out.noise_gram : 完整顺序波束通道 Gram
```

## 4.2 等效二维权验证

对每个顺序通道 \((b,c)\)，构造

\[
\mathbf w_{b,c}=\mathbf u_{c|b}\otimes\mathbf v_b.
\]

验证：

```matlab
z_seq = v_b' * Y * conj(u_c);
z_joint = w_bc' * vec(Y);
```

满足

\[
\frac{|z_{\rm seq}-z_{\rm joint}|}
{\max(|z_{\rm joint}|,\epsilon)}<10^{-12}.
\]

## 4.3 顺序流形函数

```matlab
function [g, dg_az, dg_el, meta] = build_sequential_receive_manifold( ...
    elWeights, azWeights, x, y, z, az_deg, el_deg, lambda)
```

输出顺序波束通道堆叠后的单目标流形及导数。

## 4.4 必做测试

```text
test_sequential_dbf_vs_joint_kronecker.m
test_sequential_manifold_vs_direct_weights.m
test_sequential_noise_covariance.m
test_sequential_derivatives.m
```

通过标准：

- 顺序 DBF 与等效 Kronecker 权数值一致；
- 顺序流形与直接 `Wseq' * a` 一致；
- 噪声协方差与理论 Gram 一致；
- 方位导向中保留 `cos(el)` 耦合，不能错误替换为仅依赖方位的 ULA 模型。

---

## 5. 阶段 3：俯仰分组 DML

## 5.1 建议函数

```matlab
function model = build_elevation_group_model(elDbfData, cfg)
function result = estimate_elevation_groups_dml(model, Q, searchCfg)
function result = select_elevation_group_order(model, orderCfg)
```

## 5.2 数据组织

对指定距离–多普勒检测单元，提取

```text
Ze_raw : [Be, Nphi, L]
```

拼接为

```text
Ze : [Be, Nphi * L]
```

白化后执行 \(Q=1,2,3\) 的 DML。

## 5.3 搜索方式

第一版允许使用：

- 高精度一维全网格作为真值参考；
- Q=2 时使用 AP/坐标搜索；
- PR-DML 作为外部 baseline；
- 不使用 C05、topK 或固定离散分离列表。

## 5.4 输出

```text
Q_hat
eta_hat_deg
score
rss
rank_effective
C_hat
bootstrap_order_info
```

## 5.5 主要实验

- Q=1 单目标；
- Q=2 两个俯仰可分目标；
- K=2 但相同俯仰，期望 Q=1；
- 不同方位、相同俯仰；
- 低 SNR；
- 功率比 0 至 -20 dB；
- 不同快拍数；
- 相干/强相干波形。

通过标准：

- 单目标 Q1 false split 受控；
- 同俯仰双目标不应被俯仰阶段错误强制分成 Q=2；
- 俯仰可分场景相对 full elevation DML 无显著性能损失；
- 所有结果使用独立 holdout，而不是在同一场景上反复调网格。

---

## 6. 阶段 4：条件方位 DML 与联合修正

## 6.1 建议函数

```matlab
function Xq = demix_elevation_group_coefficients(Ze, Ge, opts)
function result = estimate_conditional_azimuth_dml(Xq, eta_q, Kq, cfg)
function result = refine_joint_sequential_dml(Zseq, init, K, cfg)
```

## 6.2 条件方位场景

必须覆盖：

- `Q=2, K1=K2=1`；
- `Q=1, K1=2`；
- 两目标两维都近；
- 一个弱目标；
- 方位接近但俯仰可分；
- 俯仰接近但方位可分。

## 6.3 联合修正停止条件

使用两个同时满足的条件：

```text
relative_score_gain <= tol_score
max_angle_update_deg <= tol_angle
```

并设置最大迭代数。推荐初始值：

```text
tol_score = 1e-8
tol_angle = 1e-4 deg
max_iter  = 30
```

这些数值只作为数值收敛阈值，必须做敏感性检查，不作为统计决策阈值。

## 6.4 通过标准

- 每轮 DML score 单调不减；
- 结果不依赖目标标签排序；
- 至少三组不同初值统计局部极值风险；
- 与 local full DML 比较最终 score、RSS、RMSE；
- 若未收敛，明确输出 `SEARCH_NOT_CONVERGED`，不得自动增加经验分支。

---

## 7. 阶段 5：切向信息定理的数值验证

## 7.1 建议函数

```matlab
function T = compute_tangent_information(g, dg_az, dg_el)
function out = evaluate_near_pair_asymptotics(manifoldFun, centers, directions, sepList)
```

## 7.2 验证量

对不同中心 \(c\)、单位分离方向 \(v\) 和尺度 \(\delta\)：

\[
\mathbf d=\delta\mathbf v.
\]

计算：

\[
r_\sigma
=
\frac{2\sigma_2^2(G_2)}{
\mathbf d^TT\mathbf d},
\]

\[
r_\rho
=
\frac{
(1-|\rho|^2)\|g(c)\|_2^2
}{
\mathbf d^TT\mathbf d
},
\]

\[
r_\kappa
=
\frac{
\kappa(G_2^HG_2)
\mathbf d^TT\mathbf d
}{
4\|g(c)\|_2^2
}.
\]

理论要求：

\[
r_\sigma,r_\rho,r_\kappa\to1
\quad\text{as}\quad\delta\to0.
\]

## 7.3 场景网格

至少覆盖：

- 多个方位中心；
- 多个俯仰中心；
- 纯方位分离；
- 纯俯仰分离；
- 斜向二维分离；
- 不同局部波束集；
- phase factor 1；
- 加窗和不加窗。

## 7.4 否决标准

若比值不随 \(\delta\) 缩小而趋近 1，必须检查：

- 导数单位；
- 阵元向量化顺序；
- 顺序波束 Kronecker 顺序；
- 白化矩阵是否固定；
- 相位和共轭约定；
- 二阶项是否在测试分离范围内不可忽略。

不能通过重新选择少量“好看”的中心点宣称定理成立。

---

## 8. 阶段 6：Fisher 信息最小波束预算

## 8.1 建议函数

```matlab
function F = compute_effective_dml_fim(G, dG, S, sigma2)
function eta = compute_information_retention(Felem, Fbeam, opts)
function result = select_minimum_local_beam_set(pool, scenarioSet, eta0, costCfg)
```

## 8.2 场景设计集与 holdout

设计集 `fim_design`：

- 常规角分辨单元内部的中心位置；
- 多个二维分离方向；
- 多个分离尺度；
- 多个功率比；
- 多个相关系数；
- 多个 SNR 和快拍数。

锁定波束集后，在独立 `fim_holdout` 上验证。不得用 holdout 继续调整 \(\eta_0\) 或波束集合。

## 8.3 候选波束集

优先使用当前检测波束周围的实际规则波束：

```text
俯仰：中心束 ± n_e 个相邻束
方位：中心束 ± n_a 个相邻束
```

第一版只比较连续对称邻域，降低组合复杂度并贴近工程。第二版再加入非连续子集搜索。

## 8.4 输出

```text
selected_el_indices
selected_az_indices
Be
Ba
beam_channel_cost
eta_design_worst
eta_holdout_worst
worst_scenario_id
FIM_eigenvalue_ratios
CRB_inflation_predicted
```

## 8.5 Baseline

- 旧 `greedy_combined_B7`；
- 规则固定 3/5/7/... 波束；
- 投影损失法；
- 低相关法；
- SVD 连续子空间上界；
- 刘旗等 2026 CRB 保真思想的可实现对照。

## 8.6 通过标准

新方法至少满足：

- holdout 最坏信息保真率达到预注册 \(\eta_0\)；
- 预测 CRB 膨胀与 Monte Carlo RMSE 趋势一致；
- 在相同通道数下不劣于旧 B7；或在相同性能下减少通道数；
- 不依赖在线贪心，不重复失败的自适应 W/B 路线。

---

## 9. 阶段 7：K1/K2 bootstrap 与不可分辨输出

## 9.1 建议函数

```matlab
function fit = fit_local_model_order(Z, K, cfg)
function boot = calibrate_nested_lrt_bootstrap(fitK, K, Kplus1, cfg)
function state = classify_resolution_state(fit1, fit2, boot, fimInfo, cfg)
```

## 9.2 数据划分

```text
order_calibration_k1
order_holdout_k1
order_holdout_k2
order_stress
```

K1 calibration 只能用于 bootstrap 或预计算近似门限。最终 false split 必须在独立 K1 holdout 报告。

## 9.3 关键指标

- K1 false split rate；
- K2 detection rate；
- K2 resolved rate；
- K2 unresolved rate；
- conditional RMSE（仅 resolved 样本）；
- unconditional penalized error；
- bootstrap 门限稳定性；
- 运行时间。

## 9.4 通过标准

若预注册

\[
\alpha=0.01,
\]

则 K1 holdout 的 false split 上置信界应满足预设容差。不能只报告点估计。

对极近、弱次目标或强相干场景，允许 `K2_UNRESOLVED`，但不能错误标记为高置信 `K2_RESOLVED`。

---

## 10. 阶段 8：K=3 有限扩展

建议只实现和验证结构扩展，不扩大主论文理论承诺。

## 10.1 场景

| 场景 | 期望分组 |
|---|---|
| 三个不同俯仰 | Q=3, Kq=1 |
| 两个同俯仰、一个不同 | Q=2, K=[2,1] |
| 三个近似同俯仰 | Q=1, K1=3 |
| 一个弱目标 | 检查漏检和模型阶数 |
| 两个相干加一个独立 | 检查分组和不可分辨状态 |

## 10.2 输出边界

论文只写：

> 完成有限三目标扩展验证。

不得写：

> 方法已适用于任意多目标或任意目标数。

---

## 11. 完整实验体系

## 11.1 实验组 A：数学和代码一致性

- 单程相位；
- 导向矢量解析导数；
- 顺序 DBF–Kronecker 等价；
- 白化协方差；
- SVD-DML–pseudoinverse 参考一致；
- 酉基不变性；
- cache 重建后的一致性。

## 11.2 实验组 B：算法主性能

比较：

1. 常规顺序 DBF 峰值/比幅；
2. common-el；
3. 旧 controlled pair2d；
4. local full DML；
5. AP-DML；
6. PR-DML；
7. gridless/SBL refinement；
8. 新分组条件顺序 DML；
9. 新方法 + 联合修正。

公平性要求：

- 同一阵元数据；
- 同一接收单程流形；
- 同一噪声和快拍；
- 相同局部常规角分辨单元；
- 同一成功容差；
- 同时报告复杂度和性能。

## 11.3 实验组 C：变量矩阵

| 变量 | 推荐取值 |
|---|---|
| SNR | `[-15,-10,-5,0,5,10,15,20] dB` |
| 方位分离 | `0 ~ 1.5` 个本地方位 3 dB 波束宽度 |
| 俯仰分离 | `0 ~ 1.5` 个本地俯仰 3 dB 波束宽度 |
| 分离方向 | 纯方位、纯俯仰、四种斜向 |
| 功率比 | `[0,-3,-6,-10,-15,-20] dB` |
| 源相关系数 | `[0,0.5,0.9,0.99,1]`，并扫描相对相位 |
| 快拍数 | `[1,4,8,16,32,64]` |
| 常规中心偏差 | 由角分辨单元内部位置或协方差置信域给出 |
| Monte Carlo | 开发期小样本，正式期每单元至少数百次并报告 CI |

## 11.4 实验组 D：失配和压力

- 阵元增益误差；
- 阵元相位误差；
- 位置误差；
- 通道失效；
- 非均匀噪声；
- 相关噪声；
- 间歇干扰；
- 错误常规角分辨单元；
- 目标落在单元边界；
- 目标数超过模型上限。

## 11.5 统计指标

性能：

- 目标数正确率；
- joint success；
- per-target RMSE；
- separation RMSE；
- K1 false split；
- K2 missed split；
- unresolved rate；
- bootstrap/Monte Carlo 置信区间；
- worst-case subgroup performance。

复杂度：

- DML score 次数；
- SVD/QR 次数；
- 平均矩阵维数；
- 复乘加估算；
- 运行时间；
- 内存；
- 顺序波束输出通道数。

理论一致性：

- CRB/RMSE 比；
- Fisher 信息保真预测误差；
- 切向渐近比值；
- 坐标优化单调性；
- full DML score gap。

---

## 12. 数据划分和预注册

建议固定四类数据：

```text
design
validation
holdout_normal
holdout_stress
```

规则：

1. `design` 只用于波束集和数值参数开发；
2. `validation` 用于一次性锁定版本；
3. 锁定后不再根据 holdout 调参；
4. `holdout_normal` 报告主要性能；
5. `holdout_stress` 报告边界和失败；
6. 若 holdout 失败，不加分支，先按预注册否决或重新立项。

每个阶段在代码前写：

```text
H0/H1
主指标
通过阈值
否决条件
允许的数值容差
随机种子规则
输出文件名
```

---

## 13. 推荐结果目录与文件

每个 stage 统一输出：

```text
results_<stage_name>/
  README.md
  config_snapshot.json
  git_or_file_manifest.txt
  trial.csv
  summary.csv
  keypoints.csv
  pass_fail.csv
  runtime.csv
  figures/
  logs/
```

`keypoints.csv` 只保存可由原始 `trial.csv` 重算的摘要，不允许绘图脚本硬编码正文数值。

推荐最终总表：

```text
step12_final_claim_evidence.csv
```

字段：

```text
claim_id
claim_text
formula_id
code_entry
raw_data
summary_data
figure
status
evidence_grade
failure_boundary
```

---

## 14. 推荐图表

### 理论图

- 圆柱阵顺序 DBF 数据流；
- 俯仰条件可分解流形；
- 俯仰组–条件方位–联合修正流程；
- 切向信息椭圆；
- `sigma2^2` 与理论二次型；
- Fisher 信息保真率随波束数变化。

### 性能图

- K1/K2 ROC 或 false split–detection tradeoff；
- 二维分离平面 joint success 热图；
- RMSE/CRB 随 SNR；
- 功率比和相干系数压力图；
- 新方法 vs full DML score/RMSE/运行时间；
- 不同波束预算的 Pareto 图；
- K=3 分组案例。

### 所有图必须

- 从 CSV/MAT 原始结果读取；
- 在图注中说明样本数、SNR、快拍、成功判据；
- 不用单个代表性案例替代统计证据；
- 同时展示失败区域。

---

## 15. 代码质量要求

- 新函数必须有输入输出维度说明；
- 角度单位写入变量名或文档；
- 阵元向量化顺序必须由 metadata 保存；
- 不允许隐式依赖 MATLAB 当前路径；
- 不允许脚本内部使用绝对盘符路径；
- 随机数种子由配置传入；
- 所有阈值区分为：物理参数、统计显著性、数值容差；
- 禁止将数值容差包装为算法创新；
- 禁止 truth leakage；
- 禁止根据真值选择搜索窗口、波束数或模型阶数；
- 失败必须输出结构化状态，不能静默回退。

---

## 16. 推荐推进里程碑

### M0：模型修正

- phase factor 1；
- 术语更新；
- 旧结果失效标记。

### M1：数学内核

- 接收流形和导数；
- 一般白化；
- SVD-DML；
- 单元测试通过。

### M2：顺序 DBF

- 俯仰→方位真实级联；
- 与等效二维权一致。

### M3：双目标主算法

- 俯仰分组；
- 条件方位；
- 联合修正；
- 与 full DML/AP/PR-DML 比较。

### M4：理论创新

- 切向渐近定理数值闭环；
- Fisher 信息最小波束集。

### M5：统计可靠性

- K1/K2 bootstrap；
- unresolved 输出；
- 独立 holdout。

### M6：扩展和论文

- K=3 有限扩展；
- cache；
- 最终证据表；
- 论文重写。

---

## 17. 最终停止/否决条件

以下任一情形出现时，相关创新点应降级或否决：

1. 顺序分组算法在相同计算预算下不优于 AP/PR-DML 或局部 full DML；
2. 联合修正经常收敛到错误局部峰，且多初值成本抵消复杂度收益；
3. 切向渐近式不能在预定小分离范围内得到稳定验证；
4. Fisher 信息波束集不能预测实际性能，或不优于规则相邻波束；
5. bootstrap K1 false split 无法在独立 holdout 控制；
6. 新方法只在设计集有提升，holdout 无提升；
7. phase factor 1 后原优势消失；
8. 需要重新引入大量经验分支才能维持结果。

失败应写入新的 `FAILED_*.md`，不能把失败阶段继续包装为正面创新。

