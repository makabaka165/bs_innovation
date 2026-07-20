# 新主线实验体系、推荐代码结构与后续展开路径（prior-art 审查修订版）

> 建议保存路径：`innovation-mining/12_experiment_system_code_structure_roadmap.md`  
> 默认仓库：`makabaka165/bs_innovation`  
> 文档日期：2026-07-17  
> 必须先读：
>
> - `innovation-mining/06_formula_prior_art.md`
> - `innovation-mining/06_algorithm_prior_art.md`
> - `innovation-mining/06_closest_work_matrix.md`
> - `innovation-mining/10_current_paper_innovation_audit.md`
> - `innovation-mining/11_sequential_beamspace_ml_innovations_theory.md`
> - `innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md`
>
> 目的：把修订后的主张拆成可执行、可复现、可否决的代码阶段与实验体系。所有新代码、结果和论文论述必须主动区分“已有数学基础”“系统特化”和“经实验才可能成立的候选贡献”。
>
> 当前门（2026-07-20）：`PASS_STAGE8_1A4_CODE_ONLY`。Stage8.1A4 已修复未返回 start 的正式运行分支，并把 tracked calibration、registered artifact root、no-overwrite writer 和 calibration SHA snapshot 设为 formal public runner 不可绕过的合同；Stage8.1B 的正式离线 calibration 与 K1 validation、Stage8.2 independent holdout 均未执行，也没有任何 Stage8 性能数字。

---

## 0. 总体原则与开发顺序

### 0.1 开发顺序

```text
旧证据冻结与 prior-art 边界锁定
        ↓
接收单程模型和稳定 DML 内核
        ↓
真实先俯仰、后方位顺序 DBF 数据流
        ↓
俯仰分组可辨识性与 Q 已知估计
        ↓
条件方位 DML 与完整顺序流形联合修正
        ↓
固定白化顺序流形的近双目标渐近验证
        ↓
相关噪声子集下的 FIM 保真规则波束设计
        ↓
有限样本 threshold-risk 独立验收
        ↓
K1/K2 bootstrap 与 resolved/unresolved 状态
        ↓
K1/K2 全链锁定
        ↓
可选 K=3、cache 与硬件映射
```

### 0.2 不可违反的开发规则

1. 不覆盖 Step11 旧源码、旧结果和失败路线；新路线统一进入 Step12。
2. 新主线只使用接收单程空间相位 factor=1；factor=2 的旧证据必须失效标记。
3. SVD/QR DML、白化、AP、PR-DML、FIM、bootstrap 都是基础或 baseline，不单独包装成创新。
4. 不恢复 C05、不继续调 `gap/topK/window/condition` 阈值，不恢复在线自适应 W/B。
5. 每个阶段先写通过/否决标准，再实现；失败不得通过增加规则掩盖。
6. 所有候选搜索期间物理观测矩阵和白化坐标固定。
7. 俯仰分组必须检查 `rank(Ge)`、`rank(Ce)` 和局部唯一性。
8. FIM 波束选择必须对每个相关波束子集重构协方差和白化器，不假设逐束 FIM 可加。
9. FIM 通过只代表局部信息通过；还必须经过低 SNR、近源、弱目标、相干和错误峰 holdout。
10. 复杂度必须覆盖顺序 DBF、分组、条件方位、联合修正、模型阶数、bootstrap 校准和离线设计。
11. 任何外部 baseline 若无法准确复现，必须说明缺口，不得使用名称相似的自定义简化版冒充。
12. 配置在 validation 后锁定，holdout 禁止调参。

### 0.3 候选贡献与工程机制的代码隔离

| 层级 | 代码/实验定位 |
|---|---|
| 正确性基础 | 接收单程流形、一般白化、SVD/QR DML、顺序 DBF 等价性 |
| 候选核心算法 | 可辨俯仰组 → 条件方位 DML → 完整顺序流形修正 |
| 候选理论 | 固定白化顺序流形的近双目标显式渐近式 |
| 系统特化设计 | 相关规则顺序波束子集的 FIM 保真与结构化成本 |
| 风险控制 | K1/K2 bootstrap、resolved/unresolved、模型失配状态 |
| 软件优化 | cache、导数缓存、向量化、profiling、硬件映射 |

# 1. 推荐的新代码根结构

以下结构建议放在现有提取包中，不删除旧代码。

```text
beamspace_ml_v18/
  source/
    stepwise_signal_model/
      core/
        config/
          sim_cfg.m
          sim_cfg_sequential_v2.m
        array/
          arr_cyl.m
          reshape_cyl_vector_to_matrix.m
          reshape_cyl_matrix_to_vector.m
        manifold/
          build_receive_cyl_steering_vec.m
          build_receive_cyl_steering_with_derivatives.m
          build_cyl_factorized_manifold.m
        beamforming/
          form_elevation_dbf_cube.m
          form_azimuth_dbf_cube.m
          build_local_sequential_beam_set.m
          build_sequential_beam_matrix.m
        statistics/
          build_psd_whitener.m
          beamspace_dml_score_svd.m
          concentrated_dml_rss.m
          effective_deterministic_fim.m
          parametric_bootstrap_model_order.m
        utils/
          stable_numeric_rank.m
          canonicalize_target_order.m
          match_target_sets.m

      steps/
        step_12_0_receive_model_correction/
        step_12_1_sequential_dbf_model/
        step_12_2_stable_dml_backend/
        step_12_3_grouped_conditional_dml/
        step_12_4_tangent_information_theory/
        step_12_5_fim_beam_budget/
        step_12_6_model_order_bootstrap/
        step_12_7_integrated_k12_validation/
        step_12_8_optional_k3_extension/
        step_12_9_cache_and_runtime/
```

若不希望修改现有 `core/`，也可先在每个 Step12 的 `common/` 中实现；通过验证后再提升到 `core/`。但函数名、输入输出和测试合同应保持一致。

---

# 2. 数据维度与统一约定

## 2.1 角度和相位单位

- 对外配置和图表：角度使用 degree；
- 所有解析导数和 Fisher 信息内部计算：角度使用 radian；
- 函数名或变量名必须显式包含 `_deg` 或 `_rad`；
- 禁止在同一公式实现中隐式混用 `sind/cosd` 与弧度导数。

公共接口建议：

```matlab
[a, da_daz_rad, da_del_rad, meta] = ...
    build_receive_cyl_steering_with_derivatives( ...
        x, y, z, az_deg, el_deg, lambda);
```

输出导数含义必须是：

```text
da_daz_rad = ∂a / ∂az_rad
da_del_rad = ∂a / ∂el_rad
```

## 2.2 圆柱阵数据矩阵

统一采用：

```text
Y_elem: [N_el, N_az, N_snapshot]
```

若包含距离维：

```text
Y_elem_cube: [N_el, N_az, N_range, N_snapshot]
```

现有扁平阵元顺序必须由显式映射函数完成：

```matlab
Ymat = reshape_cyl_vector_to_matrix(yvec, array_meta);
yvec2 = reshape_cyl_matrix_to_vector(Ymat, array_meta);
```

单元测试必须验证：

```matlab
norm(yvec2 - yvec) / norm(yvec) < 1e-14
```

不得直接使用未经审计的 `reshape` 假设阵元顺序。

## 2.3 顺序 DBF 数据维度

俯仰 DBF 后：

```text
Z_el: [B_el, N_az, N_range, N_snapshot]
```

方位 DBF 后：

```text
Z_seq: [B_el, B_az, N_range, N_snapshot]
```

取某个距离–多普勒或合成观测单元后：

```text
Z_local: [B_el * B_az, L_eff]
```

其中 `L_eff` 必须有物理来源，例如：

- 多脉冲/多快拍；
- 多 CPI；
- 多频点；
- 在俯仰阶段，环向列可作为共享俯仰流形的多测量向量。

禁止把不同候选角度、Monte Carlo 次数或真值信息当作快拍。

---

# 3. 核心函数合同

## 3.1 单程接收导向矢量

### 文件

```text
core/manifold/build_receive_cyl_steering_vec.m
```

### 推荐签名

```matlab
function a = build_receive_cyl_steering_vec( ...
    x, y, z, az_deg, el_deg, lambda)
```

### 公式

```matlab
ux = cosd(el_deg) * cosd(az_deg);
uy = cosd(el_deg) * sind(az_deg);
uz = sind(el_deg);
phase_m = x(:)*ux + y(:)*uy + z(:)*uz;
a = exp(1j * 2*pi/lambda * phase_m);
```

### 禁止项

- 不提供 `PhaseFactor=2` 的默认路径；
- 不把目标距离双程相位乘入空间导向矢量；
- 不在同一函数中兼容发射虚拟阵列，若未来需要应另建函数。

## 3.2 导向矢量及解析导数

### 文件

```text
core/manifold/build_receive_cyl_steering_with_derivatives.m
```

### 推荐签名

```matlab
function [a, da_daz_rad, da_del_rad, meta] = ...
    build_receive_cyl_steering_with_derivatives( ...
        x, y, z, az_deg, el_deg, lambda)
```

### 测试

中心差分：

```matlab
h = 1e-7; % rad
a_p = steering(az_rad+h, el_rad);
a_m = steering(az_rad-h, el_rad);
fd_az = (a_p-a_m)/(2*h);
```

通过条件：

```text
relative derivative error <= 1e-6
```

在多个中心和边界角度上验证。

## 3.3 PSD 白化器

### 文件

```text
core/statistics/build_psd_whitener.m
```

### 推荐签名

```matlab
function [T, info] = build_psd_whitener(C, opts)
```

### 必须执行

1. Hermitian 对称化；
2. `eig` 或 SVD；
3. 相对数值秩阈值；
4. 只对有效子空间取逆平方根；
5. 返回有效秩、特征值和白化误差。

### 输出

```text
info.rank
info.eigenvalues
info.relative_threshold
info.whitening_error
info.is_full_rank
```

### 测试

```matlab
Cw = T * C * T';
```

在有效子空间上应接近单位阵。

## 3.4 SVD DML 评分

### 文件

```text
core/statistics/beamspace_dml_score_svd.m
```

### 推荐签名

```matlab
function [score, rss, debug] = ...
    beamspace_dml_score_svd(Z, G, opts)
```

### 必须返回

```text
score
rss
debug.effective_rank
debug.singular_values
debug.rank_threshold
debug.projection_energy
debug.total_energy
debug.status
```

### 不得出现

```matlab
inv(G'*G)
(G'*G + 1e-10*eye(K)) \ ...
den = s11*s22 - abs(s12)^2
```

主路径不得使用固定岭或 2×2 行列式快速公式。快速公式只能在通过稳定性等价测试后作为可选优化路径。

## 3.5 俯仰 DBF

### 文件

```text
core/beamforming/form_elevation_dbf_cube.m
```

### 推荐签名

```matlab
function [Zel, V, info] = ...
    form_elevation_dbf_cube(Yelem, el_beam_deg, cfg)
```

### 关键要求

- 对每个环向列，只沿垂直维做俯仰 DBF；
- 不允许直接对全部二维阵元形成一个完整二维波束；
- `V` 形状固定为 `[N_el, B_el]`；
- 输出 `Zel` 形状固定为 `[B_el, N_az, ...]`。

## 3.6 方位 DBF

### 文件

```text
core/beamforming/form_azimuth_dbf_cube.m
```

### 推荐签名

```matlab
function [Zseq, Uset, info] = ...
    form_azimuth_dbf_cube(Zel, az_beam_deg, el_condition_deg, cfg)
```

### 关键要求

- 每个俯仰通道或俯仰组使用条件方位导向矢量；
- 方位导向矢量必须包含 `cos(el_condition_deg)`；
- 输出形状为 `[B_el, B_az, ...]`；
- 记录每个俯仰通道实际使用的方位权值。

## 3.7 顺序波束矩阵和流形

### 文件

```text
core/beamforming/build_sequential_beam_matrix.m
core/manifold/build_sequential_beamspace_manifold.m
```

### 推荐合同

```matlab
[Wseq, beam_meta] = build_sequential_beam_matrix(V, Uset, array_meta);

[Gseq, deriv, meta] = build_sequential_beamspace_manifold( ...
    Wseq, Cn, target_angles_deg, array_meta, opts);
```

必须验证：

```text
direct sequential output
==
Wseq' * element_vector
```

相对误差应小于 `1e-12`（double、无量化条件）。

---

# 4. Step12 分阶段结构

# Step12.0：接收模型和术语纠正

## 目标

只修正基础模型，不实现新算法。

## 修改内容

1. 活跃配置的 `spatialPhaseFactor` 改为 1；
2. 新建单程接收导向函数；
3. 统一论文中的“前端/后端”术语；
4. 将局部范围改写为常规角分辨单元或常规测角置信域；
5. 标记所有 phase factor 2 的旧结果为 legacy；
6. 生成新波束宽度和单目标方向图。

## 输出

```text
step_12_0_receive_model_correction/
  README.md
  run_step12_0_receive_model_correction.m
  common/
  tests/
  results/
    phase_model_keypoints.csv
    old_vs_new_beamwidth.csv
    receive_model_validation.md
```

## 通过条件

- 所有新接收流形均使用 factor 1；
- 解析导数通过有限差分；
- 旧 Step11 结果未被覆盖；
- 文档明确双程距离相位被吸收到复包络。

---

# Step12.1：顺序 DBF 数据流

## 目标

证明“先俯仰、后方位”的代码与数学模型一致。

## 实现

1. 阵元向量到 `[N_el,N_az]` 的显式重排；
2. 每个方位列独立俯仰 DBF；
3. 在俯仰通道上做方位 DBF；
4. 构造等效 Kronecker 顺序波束；
5. 对单目标和双目标验证 direct/sequential/equivalent matrix 一致性。

## 输出

```text
step_12_1_sequential_dbf_model/
  run_step12_1_sequential_dbf_validation.m
  common/
  tests/
    test_array_order_roundtrip.m
    test_sequential_vs_kron_weight.m
    test_noise_covariance_after_dbf.m
  results/
    sequential_equivalence_keypoints.csv
    sequential_noise_covariance.csv
    sequential_model_report.md
```

## 通过条件

- 无噪声输出相对误差 `<1e-12`；
- 白噪声 Monte Carlo 协方差与理论 `Wseq'Wseq` 相符；
- 条件方位导向包含俯仰角依赖；
- 不再调用旧的“直接二维五波束”逻辑作为新主路径。

---

# Step12.2：稳定 DML 基础后端

## 目标

在不涉及新创新算法前，替换固定岭和 Gram 行列式评分。

## 实现

```text
build_psd_whitener.m
stable_numeric_rank.m
beamspace_dml_score_svd.m
concentrated_dml_rss.m
```

## 测试集

1. 满秩随机 G；
2. 两列逐渐趋近；
3. 精确重复列；
4. 不同整体尺度；
5. B<K；
6. 非正交 W；
7. 一般 PSD 噪声协方差。

## 对照

- `pinv` 高精度参考；
- 旧 ridge 评分；
- 旧 2×2 快速评分。

## 通过条件

- 良态条件下 SVD 与 pinv 相对误差 `<1e-10`；
- 近秩亏时不产生 `Inf/NaN`；
- 重复列返回有效秩下降；
- 改变 G 的整体尺度不改变投影评分；
- 输出 RSS 可用于后续模型阶数。

---

# Step12.3：核心创新点 1——分组条件 DML 与可辨识性验证

## 目标

在 Q 和各组 Kq 已知的 oracle 条件下，验证以下链条是否成立：

```text
俯仰 DBF MMV 数据
    → 俯仰组流形与秩诊断
    → 俯仰组 DML
    → 组系数/环向数据恢复
    → 条件方位单目标或多目标 DML
    → 完整顺序流形局部联合修正
```

模型阶数自动判定留到 Step12.6；本阶段必须先把估计器本身和可辨识条件验证清楚。

## 子阶段 A：俯仰组数据与流形

建议函数：

```matlab
function [Zemmv, mapping, info] = stack_elevation_mmv_data(elOut, opts)
function [Ge, dGe, info] = build_elevation_group_manifold(...)
function diag = diagnose_elevation_group_identifiability(Ge, Ce_or_Z, opts)
```

统一数据维度：

```text
Zel    : [B_e, Nphi, L]
Zemmv  : [B_e, Nphi*L]
Ge     : [B_e, Q]
Ce     : [Q, Nphi*L]
```

必须检查：

```text
rank(Ge) == Q
rank(Ce) == Q（真值实验）
rank(Ce_hat) / singular values（估计实验）
B_e >= Q，建议 B_e > Q
局部 manifold-subspace 映射无别名
白化有效秩固定
```

当 `rank(Ce)<Q` 时，不允许继续强制估计 Q 个俯仰组，应返回：

```text
GROUP_UNIDENTIFIABLE
```

或在统计模型支持下合并为较少组：

```text
GROUP_MERGED
```

### L=1 专项测试

必须构造：

- 不同方位响应使 `rank(Ce)=Q` 的可辨样本；
- 同方位/相位组合导致 `rank(Ce)<Q` 的反例；
- 弱次目标；
- 环向工作孔径缩小；
- 环向列相关噪声。

报告中只能称环向列为 MMV 系数观测，不能称其为独立时间快拍。

## 子阶段 B：Q 已知俯仰 DML

建议函数：

```matlab
function [est, debug] = estimate_elevation_groups_dml( ...
    Zemmv, group_count_Q, search_domain, model, opts)
```

实现顺序：

1. Q=1 一维参考搜索；
2. Q=2 小局部二维 full reference；
3. AP-DML/PR-DML wrapper baseline；
4. 不使用固定 `el_sep` 列表、topK 或 C05。

输出至少包括：

```text
eta_hat_deg
score
rss
rank_Ge
singular_values_Ge
rank_Ce_hat
singular_values_Ce_hat
num_score_eval
num_svd
status
```

## 子阶段 C：组系数和环向数据恢复

```matlab
function [Xphi, Ce_hat, debug] = recover_group_azimuth_data( ...
    Zemmv, Ge_hat, mapping, opts)
```

必须输出：

- 组数据相对 Frobenius 误差；
- 子空间 chordal distance；
- 组间串扰矩阵；
- 秩诊断；
- 对同俯仰 Q=1/K=2 场景验证恢复数据为两个方位目标叠加。

## 子阶段 D：条件方位 DML

```matlab
function [Gphi, dGphi, info] = build_conditional_azimuth_manifold(...)
function [est, debug] = estimate_conditional_azimuth_dml( ...
    Xphi, eta_deg, target_count_Kq, az_domain, model, opts)
```

要求：

- 方位流形必须包含 `cos(eta)`；
- Kq=1 使用一维 DML；
- Kq=2 使用小局部 full reference、AP 或 PR-DML；
- 使用 SVD DML；
- 输出 score/RSS/rank/num_eval；
- 不能把同俯仰双目标错误拆成 Q=2。

## 子阶段 E：完整顺序流形联合修正

```matlab
function [Gseq, dGseq, info] = build_full_sequential_local_manifold(...)
function [est, history, debug] = refine_joint_sequential_dml( ...
    Zseq, init_targets_deg, local_domains, model, opts)
```

该更新属于已有 block coordinate ascent/AP 机制。必须：

- 固定物理 Zseq、Wseq 和 whitener；
- 按目标和维度执行局部精确或高精度一维最大化；
- 每步记录 score/RSS/angle update；
- 检查单调性；
- 使用多初值时完整记录 R 和成本；
- 区分函数值收敛、角度收敛和正确解收敛；
- 未收敛返回 `SEARCH_NOT_CONVERGED`，不得按场景扩窗。

## 直接 baselines

- local full DML；
- AP-DML；
- PR-DML；
- 不分组直接二维坐标上升；
- 仅分组条件估计、不联合修正；
- 旧 controlled pair2d；
- common-el；
- 常规顺序 DBF 测角。

必须采用相同物理角域、相同初始化信息和相同 score-call/wall-time 预算。若 Kim 2012 的方法无法准确复现，单独记录全文/实现缺口。

## 场景

- K1/Q1；
- K2/Q2，不同俯仰；
- K2/Q1，同俯仰不同方位；
- 两维均近；
- 不同功率比、相对相位、相关系数；
- L=1 与 L>1；
- 初值偏差；
- 局部角单元边界；
- 环向孔径变化；
- 模型失配。

## 输出

```text
results/elevation_group_trial.csv
results/elevation_group_identifiability.csv
results/group_recovery_error.csv
results/conditional_azimuth_trial.csv
results/joint_refinement_history.csv
results/method_budget_comparison.csv
results/grouped_conditional_dml_keypoints.csv
results/grouped_conditional_dml_report.md
```

## 通过/否决条件

通过至少要求：

- 正确 Q/Kq 的模型匹配正常集接近 local full DML；
- `rank(Ce)<Q` 反例被正确拒绝；
- 同俯仰 K2 由组内方位模型处理；
- 联合修正单调性违规为 0；
- 错误峰率和多初值成本透明；
- 同预算下形成性能、复杂度或鲁棒性 Pareto 收益。

若收益完全来自真值泄漏候选域，或大量多初值使成本不低于 local full DML，则降级为工程初始化策略。

# Step12.4：核心创新点 2——固定白化顺序流形的近双目标渐近式

> **执行状态（2026-07-17）：已完成并通过。** 目录为
> `steps/step_12_4_near_pair_tangent_asymptotics/`。理论状态为
> `THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY`；4 个主物理配置无
> exact tangent null，synthetic analytic fixture 支持六阶候选。本状态不授权
> 或执行 Step12.5。

> **阶段 6.1B 最终证据冻结（2026-07-18）：`STAGE6_REPRODUCIBLE_EVIDENCE_FROZEN`。** 两次独立干净 runner、Git-object 历史对照、自复现和 final-freeze validator 全部通过；21 个确定性 artifacts 的 evidence bundle hash 为 `0c1f444603398e03865043af4e4c6e4a414dd15a3cc90e0539b19c56e990c839`。阶段 6 source scope 零修改；在该冻结时点阶段 7/FIM 尚未开始，当前阶段 7 结论见下文 Step12.5。

## 目标

验证编号 11 中的显式局部推论，而不是重新证明经典 FIM。物理 Wseq、选择索引、噪声协方差和白化有效秩在每个验证配置中固定。

## 已实现函数

```matlab
function [model, debug] = build_stage6_fixed_measurement_model(config, cfg, opts)
function [g, Jg, info] = build_fixed_whitened_sequential_derivatives(center_deg, model, opts)
function out = build_fixed_whitened_directional_derivatives(center_deg, direction_unit_rad, model, opts)
function [metric, debug] = compute_projected_jacobian_metric(g, Jg, opts)
function row = evaluate_secant_tangent_case(center_deg, direction_unit_rad, separation_rad, model, opts)
function out = compute_tangent_null_sixth_order(g0, g1, g2, g3, g_minus, g_plus, separation_rad)
```

## 固定条件

每个 case 必须保存：

```text
Wseq_hash
noise_cov_hash
whitener_hash
whitening_rank
beam_indices
center_deg
```

候选角变化不能重建测量数据或白化器。

## 验证量

非退化方向 `q=d'*T*d>0`：

```text
sigma2_ratio = sigma2(G2)^2 / (0.5*q)
coherence_ratio = (1-abs(rho)^2) / (q/norm(g)^2)
normalized_gram_ratio = cond(Gbar'*Gbar) / (4*norm(g)^2/q)
```

其中 `Gbar` 的两列分别归一化。另报告：

```text
raw_gram_condition
column_norm_ratio
Taylor residual
T eigenvalues
q
```

## 零方向/近零方向专项

- 扫描 T 的最小特征向量；
- 对 `q` 小于相对阈值的方向单独分类；
- 不计算或不展示虚假的二次 ratio；
- 使用 log-log 拟合 `sigma2^2` 对 r 的高阶斜率；
- 检查二阶/三阶导数；
- 若零方向由波束选择造成，记录为一阶不可观方向；
- 不通过 denominator floor 或经验常数修复。

## 场景网格

- 至少 9 个局部中心；
- 纯方位、纯俯仰、正/负斜方向；
- 多个规则顺序波束集；
- 不同列范数变化；
- factor=1；
- r 逐次减半，避开浮点噪声区。

## prior-art 对照

报告中必须显式引用和比较：

- deterministic CRB/projected Jacobian；
- array-manifold differential geometry；
- near-source CRB/statistical resolution limit；
- 两列 Gram 与 mutual coherence；
- `06_formula_prior_art.md` 的 F05–F08。

## 实际输出

```text
results/stage6_configuration_registry.csv
results/measurement_hash_registry.csv
results/first_derivative_validation.csv
results/higher_directional_derivative_validation.csv
results/projected_metric_properties.csv
results/tangent_eigenvalues.csv
results/secant_tangent_nondegenerate.csv
results/secant_tangent_tail_summary.csv
results/secant_tangent_exact_null.csv
results/secant_tangent_near_null.csv
results/synthetic_null_validation.csv
results/two_column_exact_identity.csv
results/geometry_invariance_validation.csv
results/column_norm_asymmetry.csv
results/stage6_keypoints.csv
results/stage6_prior_art_mapping.md
results/stage6_theory_validation.md
figures/sigma2_ratio_vs_separation.png
figures/coherence_ratio_vs_separation.png
figures/normalized_gram_ratio_vs_separation.png
figures/taylor_residual_vs_separation.png
figures/tangent_eigenvalue_map.png
figures/null_direction_order_fit.png
figures/column_norm_ratio_vs_separation.png
```

## 已通过结果

- 1296 个主 secant case，144/144 个注册尾区通过；
- 一/二/三阶导数最大相对误差为 `5.8897e-9 / 3.2122e-5 / 6.5834e-4`；
- 三条 ratio 最大尾区误差为 `4.0102e-6 / 1.0421e-5 / 6.1180e-6`；
- 未饱和两列精确恒等式误差 `1.3977e-12`；
- 三类几何不变性最大误差 `9.4336e-13`；
- synthetic exact-null 拟合阶数 6，ratio 误差 `2.2204e-16`；
- Code Analyzer / scope / schema / hash violation 均为 0；
- 阶段 5 的 14 个结果文件和 Step11 的 351 个冻结文件哈希未改变。

## 否决条件

- 解析导数不通过有限差分；
- 非退化方向 ratio 不在明确小量区趋于 1；
- 常数因子只能靠经验拟合修正；
- 结论依赖随候选变化的白化器；
- 正式全文检索找到完全同式且当前没有额外顺序流形推论；
- 零方向被删除或掩盖。

# Step12.5：系统特化设计——相关顺序波束的 FIM 保真最小局部波束集

> **最终状态（2026-07-18）：`PASS_SYSTEM_ANALYSIS_ONLY`。** 已在冻结的 5x5 factor=1 顺序父池上完整枚举 961 个矩形子集，并对每个子集重构相关协方差、有效白化器、流形导数和 deterministic effective FIM。`eta0=0.80` 的 exact 解 `RECT_E14_A31` 通过 design/validation/FIM-holdout，但它与最强固定 `FIXED_RECT_3X5` 完全相同；`eta0=0.90/0.95` 高于父池设计上限 `0.823236874`，按注册规则不可行。有限样本 Pareto 门为 0/3，故只保留系统设计分析，不进入 Step12.6。

> **Stage7.1 closure（2026-07-19）：已封存。** A4 code commit 为 `854e649`，Stage7 重生成证据 commit 为 `364c5b3`，Stage7.1 source/stable identity 为 `bdcea5bf...7185a` / `f3e84ecd...00b4c`。两次独立 closure 的 13-artifact deterministic bundle 均为 `af40f8a7e8a0edfc7077594ebf08257cd0c7385d10902bc8dd624c83434bc322`。科学核心与 `85615e0` 一致；69,742-byte legacy workspace estimate 差异仅为 provenance schema diagnostic，独立 deterministic memory contract 通过。3/5 表示 3 个俯仰中间通道各产生 5 个条件方位输出；exact 与 fixed 3/5 为同一物理子集。Stage8 未执行，且只能在后续单独授权下服务阶段 5 的 K1/K2 统计闭环。

## 目标

在已有归一化 FIM 和最少选择框架上，实现适用于相关顺序规则波束输出的 exact-subset 设计，并用有限样本 holdout 验收。不得假设逐束 FIM 可加。

## 核心接口

```matlab
function pool = build_sequential_beam_candidate_pool(...)
function subset = select_physical_beam_subset(pool, I_e, I_a)
function [CI, info] = build_subset_noise_covariance(C0, selection_matrix, opts)
function [Gw, dGw, info] = whiten_subset_manifold(GI, dGI, CI, opts)
function [F, info] = effective_deterministic_fim(Gw, dGw, S, sigma2, opts)
function [eta, info] = relative_fim_retention(Felem, Fsubset, opts)
function cost = sequential_dbf_cost(I_e, I_a, platform_profile, opts)
function result = enumerate_exact_subset_design(...)
function result = greedy_exchange_exact_subset_design(...)
```

## 必须实现的相关噪声逻辑

完整候选池：

```text
z0 = W0' * y
C0 = W0' * Rn * W0
```

子集：

```text
zI = SI * z0
CI = SI * C0 * SI'
GI = SI * W0' * A
TI = pinv_sqrt(CI)
GwI = TI * GI
```

每次 `I` 变化必须重新计算 `CI`、有效秩、白化器、Gw、导数和 FIM。

禁止：

```text
F(I) = sum_m Fm
```

除非先独立证明当前白化坐标和物理成本下满足可加条件。

## 设计目标

在阵元域可辨识子空间上计算

```text
eta(I) = min_scenario lambda_min_plus(
    Felem^(dagger/2) * FI * Felem^(dagger/2))
```

优化：

```text
min cost(I_e,I_a)
s.t. eta(I_e,I_a) >= eta0
```

成本至少分项报告：

```text
C_el  ~ B_e * Nphi * Nz
C_az  ~ B_e * B_a * Nphi
C_out ~ B_e * B_a
C_mem / data movement
measured MATLAB runtime
```

没有平台系数时，不将这些项用人工权重压成一个“综合评分”；报告 Pareto 前沿或使用明确的主成本和次级约束。

## 场景划分

```text
design
validation
normal_holdout
threshold_holdout
mismatch_holdout
```

变量：中心、二维分离方向、SNR、L、功率比、相关性、局部单元位置、噪声协方差、幅相/位置/失效通道。

## 求解器

小池：完全枚举。  
大池：exact-subset FIM greedy add → drop → pair-swap。  
每次候选重评估使用 exact `CI`。  
连续 SVD 子空间只作上界。  
Chepuri–Leus 型 SDP/稀疏松弛只作独立观测参考，除非重新推导可行性。

## 必须基线

1. 固定连续 3/5/7/... 规则波束；
2. 旧 `greedy_combined_B7`；
3. 刘旗等 2026 CRB 保真方法或可复现等价实现；
4. Chepuri–Leus 独立观测参考；
5. exact-FIM greedy add；
6. greedy + exchange；
7. 小池穷举；
8. 连续 SVD 上界。

## 二阶段验收

### 第一阶段：信息约束

- eta；
- predicted CRB inflation；
- FIM rank；
- 子集白化 rank；
- 设计成本。

### 第二阶段：独立有限样本风险

- threshold SNR；
- wrong local peak；
- oracle-K success 与 Wilson 95% 区间；
- 相对固定矩形和完整父池的配对成功/误差区间；
- unconditional penalized error；
- weak-secondary/coherent subgroup；
- covariance/gain-phase/position/channel-failure mismatch；
- runtime/memory/bandwidth。

Step12.5 固定 Q/K/Kq 为 oracle，不执行 K1/K2 模型阶数、bootstrap 或 resolved/unresolved 指标；这些对象只属于 Step12.6。

不把第二阶段指标重新线性加权进设计目标；任一预注册风险不通过即否决或降级。

## 输出

```text
results/stage7_plan_registry.csv
results/stage7_candidate_pool.csv
results/stage7_subset_family.csv
results/fim_subset_enumeration.csv
results/fim_subset_pareto.csv
results/fim_operating_points.csv
results/fim_greedy_exact_gap.csv
results/finite_sample_{normal,threshold,mismatch,stress}_holdout.csv
results/fim_vs_finite_sample_risk.csv
results/stage7_keypoints.csv
results/stage7_fim_beam_design_report.md
```

## 否决标准

- 需要逐束可加假设才能得到正结果；
- eta 在 holdout 不稳定；
- 相同 eta 下有限样本风险严重分化而方法不能识别；
- 相对于固定相邻波束无成本/性能收益；
- 相关噪声 exact 设计成本过高且无可实现简化；
- 只能重复已有 CRB 保真 BML，无本系统特化收益。

最终结果触发“相对于固定相邻波束无成本/性能收益”降级条件。实现和证据保留用于系统设计复核，但不恢复旧 W-score，也不把 greedy 或完整父池冒充 exact 优势。

# Step12.6：K1/K2 bootstrap、分辨状态与独立风险控制

> **当前门状态：`PASS_STAGE8_1A4_CODE_ONLY`。** Stage8.1A4 的 non-bypassable formal-evidence 合同已通过 miniature 验证，不改变 Step12.5 的 0/3 Pareto 结论，也不自动授权 Stage8.1B 或 Stage8.2。

## 四层冻结路线

1. **Stage8.0 / Step12.6A（已冻结）：** 建立独立代码目录；冻结 fixed measurement、共同局部域、K1 两起点、K2 三起点、`r_C*L` LRT、separation confidence、六状态输出和未来实验计划；只运行小型 fixture，无性能结果。
2. **Stage8.1A4 / Step12.6B-pre（当前）：** best start 只从有效 registered starts 选择；未返回 estimate 的 start 保留审计与计费但不参与选择；formal loader/wrapper/finalizer 不能关闭 tracked-evidence 检查，formal writer 不能覆盖，artifact root 固定在注册 Stage8 目录，calibration bytes 在 validation 前后以 SHA-256 snapshot 复核。仍只运行 fixture，不执行正式样本。
3. **Stage8.1B（尚未授权、尚未执行）：** 仅在后续单独授权后，从干净 A4 code commit 在仓库外 checkpoint root 完成 300 cells 和两个 `q_global`，创建 `docs(stage8.1): freeze k1 bootstrap thresholds`；随后从干净 threshold evidence commit 重建计划、exact 验证 provenance，执行 6000 个公共 K1 trial/12,000 config rows，并创建 `docs(stage8.1): validate k1 false-split control`。FULL_PARENT 只作 paired sensitivity，不能抵消 PRIMARY 失败。
4. **Stage8.2（尚未执行）：** 仅在 Stage8.1B artifact 锁定、K1 validation gate 通过且再次单独授权后，执行 K1/K2 independent holdout、full-parent paired sensitivity、mismatch holdout 和 Stage5 coherent-weak boundary；holdout 不重新校准阈值，并按预注册 Wilson 门给出 PASS/PARTIAL/FAIL。

四层的 seed、artifact 和 Git identity 独立。Stage8.1A 不生成正式 threshold table、calibration CSV、validation CSV、holdout CSV 或 PNG。

## 目标

移除固定 K=2 假设，控制单目标被错误分裂，并把“检测到 K2 证据”和“两个角度可可靠分辨”分开。该阶段是已有统计机制的工程集成。

## 建议函数

```matlab
function fit = fit_local_model_k(Zlocal, K, domains, model, opts)
function lr = nested_dml_likelihood_ratio(fitK1, fitK2, dims, opts)
function calib = calibrate_parametric_bootstrap_lrt(config_grid, Bboot, opts)
function p = lookup_locked_lrt_threshold(measurement_config_id, locked_artifact, expected_contract)
function ci = bootstrap_separation_confidence(fitK2, Bboot, opts)
function state = classify_local_cluster_state(fitK1, fitK2, lr, ci, diagnostics, opts)
```

## 校准方式

优先离线校准：

- 在锁定的 SNR/L/噪声配置网格上执行完整 K1/K2 bootstrap 重拟合；
- calibration 后冻结阈值表；
- online/holdout 只查表，不逐样本重新调阈值；
- 若必须逐样本 bootstrap，单独报告计算成本。

每个 bootstrap 样本必须完整重新拟合 K1 和 K2，不能只在真值或固定估计处评分。

## 主状态

```text
K1
K2_RESOLVED
K2_UNRESOLVED
OUT_OF_LOCAL_CELL
SEARCH_NOT_CONVERGED
NUMERIC_RANK_DEFICIENT
```

Stage4 group support 只作初始化诊断，不再作为统一拒判。`MODEL_MISMATCH`
在独立校准数据可见 GOF 前固定禁用，仿真 truth metadata 不得激活该状态。

不得增加 EASY/HARD/AMBIGUOUS 搜索预算状态。

## 数据划分

- K1 calibration；
- K1 validation；
- K1 independent holdout；
- K2 validation；
- K2 independent holdout；
- threshold holdout；
- mismatch holdout。

所有 seed、场景 ID 和参数网格显式隔离。

## 指标

```text
false_split_rate_K1
upper_CI_false_split_K1
missed_split_rate_K2
false_resolved_rate
resolved_rate
unresolved_rate
K1_vs_K2_UNRESOLVED_confusion
separation_CI_coverage
unconditional_penalized_error
conditional_RMSE_resolved
model_mismatch_wrong_confidence
runtime
```

必须同时报告无条件风险和 resolved 条件下指标，不能用 unresolved 排除困难样本后只展示漂亮 RMSE。

## Baselines

- AIC；
- MDL；
- 已有 bootstrap source-enumeration 方法；
- nested DML LRT parametric bootstrap；
- 已知 K oracle；
- 不允许 unresolved 的消融；
- GLRT/Rao statistical resolution-limit 参考。

## 通过标准

- K1 holdout false split 及其上置信界受预注册 alpha 控制；
- false resolved 受控；
- K2_UNRESOLVED 不与 K1 大量混淆；
- 模型失配不频繁输出错误 `K2_RESOLVED`；
- bootstrap threshold 在 holdout 不调整；
- 计算成本完整报告。

## 否决标准

- calibration 只在训练分布有效；
- 参数失配导致 false split/false resolved 严重失控；
- unresolved 成为隐藏失败样本的工具；
- 必须重新引入 score-gap 多阈值才能工作。

# Step12.7：K1/K2 集成验证

## 统一入口

```text
run_step12_7_integrated_k12_validation.m
```

## 主链

```text
element data
→ elevation DBF
→ elevation group model order
→ group recovery
→ conditional azimuth DML
→ joint refinement
→ K1/K2 bootstrap
→ resolved/unresolved state
→ metrics
```

## 必须锁定的配置

- phase factor = 1；
- 阵列几何；
- DBF 波束网格；
- 局部角单元定义；
- Fisher 信息目标 \(\eta_0\)；
- \(\alpha,\beta\)；
- SVD rank threshold 规则；
- 最大迭代数；
- 收敛容限；
- 成功评价容差。

锁定后不允许在 holdout 上重新调参。

---

# Step12.8：可选 K3 扩展

只在 K1/K2 主线通过后进行。

## 目标

验证结构可扩展，而不是声称任意多目标全局最优。

## 场景

```text
K3_three_elevation_groups
K3_two_same_el_one_different
K3_same_el_three_azimuths
K3_one_weak_target
K3_two_coherent_plus_one
```

## 对照

- PR-DML；
- AP-DML；
- local full search（仅在可承受的小网格上）；
- gridless/SBL。

## 输出

清楚区分：

- 算法能运行；
- 能正确估计；
- 能稳定选择 K；
- 是否具有理论保证。

---

# Step12.9：cache、运行时间和硬件映射

cache 最后做，不先做。

## 新 cache 内容

可缓存：

- \(g(\phi,\theta)\)；
- \(\partial g/\partial\phi\)；
- \(\partial g/\partial\theta\)；
- 局部 FIM 基础项；
- 固定局部波束集的白化矩阵。

## 必须失效的配置变化

```text
phase factor
lambda
array geometry
element ordering
DBF windows
beam centers
beam set
noise covariance model
grid/interpolation mode
```

cache 只作为软件/硬件优化，不作为统计创新。

---

# 5. 推荐的实验场景体系

## 5.1 数据划分

至少四个互斥集合：

| 集合 | 用途 | 是否允许调参 |
|---|---|---|
| design | FIM 波束集和实现调试 | 允许 |
| validation | 锁定 \(\eta_0,\alpha,\beta\) 和算法配置 | 只允许一次性锁定 |
| normal holdout | 正常分布独立评价 | 禁止 |
| stress holdout | 病态与模型失配评价 | 禁止 |

随机种子和场景 ID 必须固定并保存。

## 5.2 核心变量

### 角度结构

- 常规角单元中心位置；
- 方位分离；
- 俯仰分离；
- 分离方向；
- 目标靠近波束单元边界；
- 同俯仰；
- 同方位；
- 两维均近邻。

### 信号条件

- SNR；
- 目标功率比；
- 目标相对相位；
- 快拍数；
- 相关系数；
- Doppler 相同/不同；
- 单 CPI/多 CPI。

### 模型失配

- 阵元增益误差；
- 阵元相位误差；
- 位置误差；
- 通道失效；
- 一般有色噪声；
- 波束权量化；
- 常规测角角单元偏差；
- 目标落出局部单元。

## 5.3 推荐归一化尺度

角分离同时报告：

```text
degree
fraction of 3 dB beamwidth
Fisher metric distance
```

Fisher 距离：

\[
d_F^2
=
\Delta\boldsymbol\xi^T
T_{\rm seq}(\mathbf c)
\Delta\boldsymbol\xi.
\]

这样可以判断不同中心和不同方向的“相同角度间隔”是否具有相同的信息难度。

---

# 6. Baseline 体系与公平比较

## 6.1 主算法必须基线

1. 常规顺序 DBF 峰值/比幅测角；
2. local full DML：同一接收流形、同一局部物理角域；
3. AP-DML：相同初始化和 score-call/wall-time 预算；
4. PR-DML：相同候选域和停止条件；
5. 不分组直接二维坐标上升；
6. 仅分组条件估计、不做联合修正；
7. old controlled pair2d；
8. common-el；
9. gridless ML/SBL refinement；
10. Kim 2012/三维 beamspace 双目标方法的准确复现或明确的实现缺口。

## 6.2 波束设计必须基线

1. 固定连续规则波束；
2. `greedy_combined_B7`；
3. 刘旗等 2026 CRB 保真设计；
4. Chepuri–Leus 独立观测稀疏选择参考；
5. exact-FIM greedy；
6. greedy + exchange；
7. 小池穷举；
8. 连续 SVD 上界。

Chepuri–Leus 结果只有在独立/可加假设成立时才可视为当前问题可行解或下界，否则只作机制参考。

## 6.3 模型阶数与分辨必须基线

- AIC/MDL；
- bootstrap source enumeration；
- nested DML LRT bootstrap；
- 已知 K oracle；
- GLRT/Rao statistical resolution reference；
- 无 unresolved 消融。

## 6.4 公平比较要求

- 相同数据和噪声 realization；
- 相同局部角域，禁止真值泄漏；
- 相同接收单程流形；
- 相同白化和候选物理输出；
- 相同 K 先验或明确区分 oracle/unknown-K；
- 相同 score-call、SVD 次数或 wall-time；
- 多初值成本完整计入；
- 失败状态计入无条件风险；
- 外部方法的简化复现必须标注与原文差异。

# 7. 评价指标与复杂度记账

## 7.1 估计性能

- permutation-invariant target-set RMSE；
- 方位/俯仰分量 RMSE；
- joint success；
- worst-subgroup success；
- score/RSS gap to local full DML；
- wrong-local-peak rate；
- boundary/out-of-cell rate；
- unconditional penalized error。

## 7.2 分组中间量

- `rank(Ge)`、`rank(Ce_hat)`；
- Ge/Ce singular values；
- group recovery relative error；
- subspace chordal distance；
- group crosstalk；
- `GROUP_UNIDENTIFIABLE` 正确率。

## 7.3 模型阶数与分辨

- K1 false split 及置信上界；
- K2 missed split；
- false resolved；
- resolved/unresolved rate；
- K1 与 K2_UNRESOLVED 混淆；
- separation CI coverage；
- mismatch wrong-confidence rate。

## 7.4 理论一致性

- derivative finite-difference error；
- T PSD error；
- nonzero-direction asymptotic ratios；
- null-direction high-order slope；
- column-norm asymmetry；
- FIM rank and eta；
- predicted vs empirical CRB/RMSE inflation。

## 7.5 完整复杂度

在线：

```text
C_elDBF
C_azDBF
C_group_fit
sum C_az_group
C_joint
C_K1K2
```

离线：

```text
C_bootstrap_calibration
C_FIM_design
C_cache_build
```

实际字段：

- DML score calls；
- QR/SVD calls and dimensions；
- AP/PR iterations；
- multi-start count；
- K1/K2 fits；
- bootstrap refits；
- wall time；
- peak memory；
- output channels；
- bytes moved/stored。

## 7.6 鲁棒性

- SNR、L、功率比、相关性；
- 幅相误差、阵元位置误差、失效通道；
- 一般/估计误差噪声协方差；
- local cell bias；
- threshold SNR；
- same-eta/different-risk counterexamples。

# 8. 统计报告要求

## 8.1 不只报告平均值

每个主指标至少报告：

- 样本数；
- mean；
- median；
- standard deviation；
- 95% bootstrap CI；
- worst subgroup；
- seed-level results。

## 8.2 成功率区间

成功/失败率使用 Wilson 或 Clopper–Pearson 区间，不能只写 `50/50 = 1` 后推断普适安全。

## 8.3 配对比较

同一个 Monte Carlo 样本上比较算法，使用配对统计：

- paired bootstrap；
- paired success difference；
- paired runtime ratio；
- seed-stratified bootstrap。

## 8.4 预注册否决标准

每一个新创新点开始实现前，先写：

```text
primary metric
minimum meaningful improvement
maximum allowed degradation
runtime budget
holdout definition
failure condition
```

失败后记录失败，不再新增规则。

---

# 9. 推荐的论文和文档结构

```text
paper_v19/
  00_scope_and_claims.md
  01_system_processing_chain.md
  02_receive_array_model.md
  03_sequential_dbf_model.md
  04_grouped_conditional_dml.md
  05_tangent_information_theory.md
  06_fim_preserving_beam_budget.md
  07_model_order_and_unresolved_state.md
  08_experiments.md
  09_limitations.md
  10_references.md
```

## 9.1 章节主线

### 第 1 章

- 全息凝视雷达顺序 DBF 工程背景；
- 常规角分辨单元内未分辨目标簇；
- 不再使用“前端给窗口的后端算法”。

### 第 2 章

- 接收单程圆柱阵模型；
- factor 1；
- 阵元矩阵模型；
- 条件 Kronecker 结构。

### 第 3 章

- 俯仰 DBF；
- 条件方位 DBF；
- 顺序波束等效矩阵；
- 白化。

### 第 4 章

- 分组条件 DML；
- 联合修正；
- 单调性；
- 复杂度。

### 第 5 章

- 近双目标割线–切线定理；
- 第二奇异值、相关性、Gram 条件数。

### 第 6 章

- 有效 Fisher 信息；
- 信息保真率；
- 最小局部波束预算。

### 第 7 章

- K1/K2 bootstrap；
- resolved/unresolved；
- K3 有限扩展。

### 第 8 章

- 实验；
- baselines；
- 正常/压力 holdout；
- 统计区间。

---

# 10. 结果目录与命名规范

每个阶段：

```text
results_<step_name>/
  config_snapshot.json
  environment.txt
  git_commit.txt
  trial_table.csv
  summary_table.csv
  keypoints.csv
  figures/
  report.md
```

每一行 trial 至少包含：

```text
scenario_id
split
seed
method
true_K
estimated_K
state
true_angles
estimated_angles
snr
power_ratio
correlation
snapshot_count
beam_set_id
B_el
B_az
score
rss
runtime
num_dml_eval
success
```

配置不得只存在 MATLAB workspace 中。

---

# 11. 推荐的推进顺序

## 里程碑 M0：冻结旧证据

- 校验旧 Step11 结果完整；
- 记录 SHA/配置；
- 不运行新算法。

## M1：factor 1 和术语

- 修改接收模型；
- 重新生成单目标波束宽度；
- 修改论文范围；
- 不做创新宣称。

## M2：顺序 DBF

- 实现真实数据流；
- 证明等效矩阵；
- 通过噪声协方差测试。

## M3：稳定 DML

- 替换固定 ridge；
- 通过秩亏测试；
- 生成 K1/K2 RSS。

## M4：核心创新点 1——分组条件顺序 DML

- 先在 Q/Kq 已知条件下验证估计器和可辨识性；
- 构造 rank(Ce)<Q 反例；
- 与 full local DML、AP-DML、PR-DML 同预算比较；
- 模型阶数留到 M7。

## M5：核心创新点 2——固定白化顺序流形渐近式

- 解析导数；
- 非退化方向统一渐近式；
- 零方向高阶退化；
- 若失败，停止把该式作为理论贡献。

## M6：系统特化设计——相关规则波束 exact-subset FIM

- 已完成 961/961 个矩形子集的相关协方差重构、FIM 保真与结构化成本评估；
- design/validation/FIM holdout 技术门通过，`eta0=0.80` 为唯一可行 operating point；
- oracle-K normal/threshold/mismatch/stress 共 29 个场景、每场景 200 次；
- exact 解等于最强固定 3x5 矩形，有限样本 Pareto 0/3；里程碑以 `PASS_SYSTEM_ANALYSIS_ONLY` 关闭。
- Stage7.1 已用 18 个 paired groups、3600 个公共阵元域 trial 和 10800 个方法行完成 post-hoc closure；结果不改变注册选择或贡献定位。
- legacy workspace estimate 单列为 schema-dependent diagnostic；确定性内存、子集与 score-call 合同独立通过。

## M7：K1/K2 bootstrap

- 尚未执行；若未来由用户单独授权，只用于完成阶段 5 的 K1/K2 false-split、false-resolved 与 unresolved 统计闭环，不得把 Stage7 系统分析升级为算法贡献。
- false split；
- unresolved；
- 模型失配。

## M8：集成论文结果

- 锁定参数；
- 大规模 holdout；
- 重写论文。

## M9：K3 和 cache

- 仅在主线通过后执行；
- 不影响 K1/K2 主结论。

---

# 12. 风险与应对

| 风险 | 必须采取的处理 |
|---|---|
| 分组系数矩阵不满秩 | 返回 `GROUP_UNIDENTIFIABLE`，构造反例，不加搜索规则 |
| AP/坐标上升错误局部峰 | 多初值成本和 score gap 透明，与 PR/full DML 同预算比较 |
| T 存在零方向 | 高阶分析和不可辨识输出，不设置 denominator floor |
| 波束噪声相关导致 FIM 非可加 | 每个子集重构协方差/白化/FIM |
| 高 SNR FIM 与有限样本风险脱节 | threshold/mismatch holdout 二阶段验收 |
| bootstrap 模型失配 | 独立 K1/K2/mismatch holdout，报告 false resolved |
| “完整组合未发现”被过度宣传 | 按 06 文档标签逐项引用 prior art，只保留系统组合差异 |

| 风险 | 表现 | 正确应对 |
|---|---|---|
| 顺序分组误差传播 | 俯仰估计错误导致方位失败 | 用完整流形联合修正；报告失败边界 |
| 同俯仰目标不可分组 | Q=1 | 在组内执行多目标方位 DML |
| 两维都极近 | FIM 接近奇异 | 返回 `UNRESOLVED` |
| 相干源 | 有效差模信息消失 | 多快拍/结构方法 baseline；不保证全部解决 |
| FIM 只适用于高 SNR | 阈值区预测失效 | 同时报告低 SNR holdout；不加经验权重 |
| PR-DML 已覆盖低维多源优化 | 新颖性重叠 | 新颖性限定为顺序圆柱阵分组模型和信息保真波束预算 |
| 刘旗 2026 已有 CRB BML | W 创新被压缩 | 做逐式差异：双目标、顺序 DBF、物理局部波束、最坏信息率、最小预算 |
| K3 工作量过大 | 模型阶数和配对复杂 | K3 只做有限结构验证 |
| cache 提前牵制设计 | 围绕旧网格优化 | cache 最后做 |
| 旧结果与 factor 1 混用 | 结论错误 | 所有新结果带 `phase_factor=1` 元数据 |

---

# 13. 最终验收条件

最终主线只有同时满足以下条件才能进入正式论文：

1. 贡献表述与 `06_*` prior-art 标签一致；
2. 分组模型可辨识条件和反例完整；
3. 近双目标公式在非退化方向通过，零方向边界清楚；
4. 相关噪声 exact-subset FIM 实现正确；
5. FIM 与有限样本风险均通过独立 holdout；
6. K1 false split、K2 false resolved 和无条件风险受控；
7. 与 AP/PR/local-full-DML 形成同预算 Pareto 收益；
8. 没有通过恢复 C05/topK/经验综合权重获得正结果；
9. 全部复杂度、失败状态和多初值成本被计入；
10. Kim 2012、刘旗等 2026、Pakrooh、Chepuri–Leus 和统计分辨文献被正面比较。

新路线只有在以下证据同时成立时，才适合作为硕士论文核心创新：

1. 顺序 DBF 模型与代码数值一致；
2. SVD DML 在近秩亏条件下稳定；
3. 分组条件 DML 在主要 K2 场景接近 local full DML，且计算量显著降低；
4. 联合修正目标函数单调不降；
5. 割线–切线渐近式得到数值验证；
6. Fisher 信息率能预测波束集的 CRB/RMSE 损失；
7. 最小波束集在独立 holdout 上不依赖重新调参；
8. K1 false split 受 bootstrap 显著性控制；
9. 病态场景能正确输出 `UNRESOLVED`，而非错误高置信；
10. 与直接 BML、PR-DML、gridless/SBL 和旧方法完成公平比较；
11. 所有主要结论具有置信区间和 worst subgroup；
12. 论文明确不宣称任意多目标、任意模型失配或完整雷达闭环。

若其中第 3、5、6 或 8 项失败，应重新评估创新点，而不是继续增加规则。
