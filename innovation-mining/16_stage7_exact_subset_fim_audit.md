# 阶段 7 / Step12.5 exact rectangular-subset FIM 审计

> 日期：2026-07-18
> 仓库：`makabaka165/bs_innovation`
> 基线：`ea1c0320b7ba9639d6d955a1a45037cdc6cfdb31`
> 分支：`main`
> MATLAB：R2022b
> 活跃相位：`phase_factor=1`
> 冻结计划 hash：`e630a084e68108a1604527afe7a81db7150b045454b3f54b05e6cfd389259a3b`
> Stage 7 source-tree hash：`2b3f71fcb63d2393cf0f49ab4e3583628c564a9d8d72525b74a05e83bbe30482`
> 阶段 6 evidence bundle hash：`0c1f444603398e03865043af4e4c6e4a414dd15a3cc90e0539b19c56e990c839`

## A. 阶段结论

最终状态为 **`PASS_SYSTEM_ANALYSIS_ONLY`**。

开始前的 remote、main、HEAD/origin、R2022b、phase factor 和上游冻结 hash
预检均通过。全过程未创建或切换分支，未提交、推送或创建 PR。

Stage 7 的数学实现、冻结计划、961 个矩形子集枚举、1184 个 FIM 场景、
oracle-K 有限样本风险验证和技术门均完成。唯一通过三重 FIM 门的
`EXACT_ETA_080` 与最强固定基线 `FIXED_RECT_3X5` 是同一物理子集，三个
有限样本 Pareto operating point 均未通过。因此：

- 保留 exact 相关协方差/FIM 重构及成本分析作为系统设计证据；
- 不保留新的波束选择算法贡献；
- 不恢复旧 W-score、C05、topK 或 gap 自适应；
- `stage8_technical_permission=false`，本轮停在阶段 7。

## B. 阅读范围与 prior-art 边界

已核对 innovation-mining 06/10/11/12/13/15、失败路线记录、阶段 5/6 冻结
证据、Step12.0-12.2 的 factor=1 流形/导数/白化/SVD-DML 接口，并复核：

- Chepuri 和 Leus，arXiv:1310.5251；
- Pakrooh 等，arXiv:1504.01081 与 arXiv:1505.07431；
- 刘旗等 2026，DOI `10.12000/JR25173` 的完整 16 页出版社 PDF。

FIM/CRB、未知确定性幅度消元、归一化 FIM、最少测量选择、greedy/exchange、
beamspace CRB retention、PSD 白化和广义特征值保真均有 prior art。刘旗等的
白噪声 semi-unitary ULA 角字典子集不能精确复现本项目的相关输出重白化和
两级矩形物理成本，状态为 `EXACT_REPRODUCTION_UNAVAILABLE`。未发现完全
相同组合不构成新颖性证明。

本文中的 `exact` 只表示冻结 5x5 父池、961 个矩形子集和注册场景族内的
完整枚举，不表示任意波束池或一般连续问题的全局最优。

## C. 文件清单

实现隔离在：

```text
beamspace_ml_v18/source/stepwise_signal_model/steps/
  step_12_5_exact_subset_fim_beam_design/
```

其中包含 runner、`common/`、`tests/`、`results/` 和 `figures/`。26 个必需
结果文件全部存在，另保存 `stage7_finite_sample_plan.csv` 和
`online_dbf_runtime.csv`；8 幅注册 PNG
全部可解码并已目检。关键结果入口为：

- `results/stage7_plan_registry.csv`
- `results/fim_subset_enumeration.csv`
- `results/fim_operating_points.csv`
- `results/fim_greedy_exact_gap.csv`
- `results/finite_sample_{normal,threshold,mismatch,stress}_holdout.csv`
- `results/fim_vs_finite_sample_risk.csv`
- `results/stage7_keypoints.csv`
- `results/stage7_fim_beam_design_report.md`

阶段 6 代码、README、results、figures、provenance contract 和 evidence
manifest 未修改；Stage 5 与 Step11 冻结证据也未覆盖。

## D. 公式到代码映射

| 数学对象 | 实现 |
|---|---|
| 5x5 factor=1 顺序父池 | `common/build_stage7_candidate_pool.m` |
| 961 个 `I_e x I_a` 矩形族 | `common/enumerate_stage7_rectangular_subsets.m` |
| `C_I=W_I^H R_n W_I` 与有效白化 | `common/build_exact_subset_model.m` |
| 阵元/子集流形与弧度导数 | `common/build_stage7_element_manifold.m`、`common/apply_stage7_element_whitener.m` |
| deterministic source matrix | `common/construct_deterministic_source_matrix.m` |
| 幅度消元 effective FIM | `common/effective_deterministic_fim.m` |
| 显式实参数 Schur reference | `tests/private/effective_deterministic_fim_schur_reference.m` |
| 相对阵元域 eta | `common/relative_fim_retention.m` |
| 顺序结构化成本 | `common/stage7_subset_cost.m` |
| exact enumeration | `common/enumerate_exact_subset_design.m` |
| exact add/drop/pair-swap | `common/greedy_exchange_exact_subset_design.m` |
| oracle-K SVD-DML | `common/run_stage7_oracle_dml.m` |
| 有限样本 Pareto 门 | `common/apply_stage7_finite_sample_pareto_gate.m` |

FIM 投影实现按 `[r,L]` 残差矩阵计算，没有在主路径显式物化
`I_L kron Pi_G_perp`。每次子集变化均重新计算协方差秩、白化器、流形、
导数和 FIM；没有使用逐束固定 FIM 可加假设。

## E. 维度、单位、父池和子集族

- 阵元工作子阵：`32 x 65 = 2080` 个阵元；
- fallback 俯仰波束：`[9.2,9.6,10.0,10.4,10.8] deg`；
- fallback 方位波束：`[6.8,7.4,8.0,8.6,9.2] deg`；
- `W0 [2080,25]`，中心 3x3 已逐列匹配阶段 6；
- 外部角度与结果使用 degree，解析导数和 FIM 参数使用 radian；
- 物理域固定为 az `[7.4,8.6] deg`、el `[9.6,10.4] deg`；
- 非空矩形子集数 `(2^5-1)^2=961`，已评估 `961/961`；
- FIM 场景：640 design、288 validation、256 holdout，共 1184；
- 有限样本：6 normal、18 threshold、4 mismatch、1 stress，共 29；
- 每个有限样本场景 `Nmc=200`，9 个注册方法，共 52,200 个 method-trial。

Q/K/Kq 在有限样本层均为 oracle。未运行模型阶数逻辑、bootstrap、K=3、
cache、硬件或输出 SNR 单独归一化。

## F. 测试与实际命令

主 MATLAB 入口：

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_5_exact_subset_fim_beam_design/run_step12_5_exact_subset_fim_design.m')
```

鉴于 R2022b 多线程长跑的 native heap instability，正式完整运行由
`matlab -singleCompThread -batch` 启动；该执行模式不改变冻结计划、种子、
候选、求解器或判门。

主脚本完成全部计算、写出结果和 8 幅图后打印
`Step12.5 Stage 7 result: PASS_SYSTEM_ANALYSIS_ONLY`，wall runtime 为
`1641.6270 s`。MATLAB R2022b 随后在进程清理阶段返回
`0xc0000374 Heap corruption`。异常发生在最终报告和图形落盘之后，没有
未完成场景；但它作为运行环境风险保留，不能隐藏。

为区分证据计算与退出清理异常，另起短进程独立复核并以退出码 0 完成：

- 计划 hash 与 source-tree hash 逐字匹配；
- Stage 6 `21/21`、Stage 5 `14/14`、Step11 `351/351`；
- 注册技术套件 `477/477`，包含 source common-scale 三项不变性；
- Code Analyzer 0；
- scope 与 no-model-order 扫描通过；
- data-processing violation 0；
- `git diff --check` 通过。

关键数值误差包括：FIM projection/Schur 最大相对误差
`1.666e-15`，解析导数最大相对误差 `1.147e-9`，相关协方差直接公式误差
`1.072e-15`，相关协方差 Monte Carlo 误差 `2.694e-3`，source common-scale
不变性最大误差 `1.110e-15`。target permutation、center-difference、
output-basis、source-scale、nested-subset monotonicity 和
full-parent ceiling 测试均通过。

## G. 关键结果

### G.1 FIM operating points

完整父池最坏 design eta 上限为 `0.823236874`。

| eta0 | 结果 | 子集 | MAC | eta design / validation / holdout |
|---:|---|---|---:|---|
| 0.80 | FIM 三重门通过 | `RECT_E14_A31`，3x5 | 7215 | `0.812182048 / 0.854926015 / 0.816394840` |
| 0.90 | `DESIGN_OPERATING_POINT_INFEASIBLE` | 无 | 无 | 父池上限不足 |
| 0.95 | `DESIGN_OPERATING_POINT_INFEASIBLE` | 无 | 无 | 父池上限不足 |

没有降低 eta0，也没有用其他子集替代不可行 operating point。`eta0=0.80`
对应的注册 CRB 膨胀上限为 1.25。

### G.2 exact 与 greedy

Exact 解使用俯仰 ID `2;3;4` 和方位 ID `1;2;3;4;5`。Greedy 返回
`RECT_E28_A31`，即俯仰 ID `3;4;5` 与全部方位，MAC 同为 7215；其 design
eta 为 `0.818362441`，比 exact 解高 `0.006180393`，但不是固定 tie-break
下的同一子集。Greedy 只作为对照，不冒充 exact。

### G.3 oracle-K 有限样本

`EXACT_ETA_080` 与最强固定 `FIXED_RECT_3X5` 是同一物理子集，全部 5800
个 realization 的输出指标逐项一致：

| 指标 | exact / fixed 3x5 |
|---|---:|
| 冻结网格 aggregate success | `3803/5800 = 0.655689655` |
| 描述性 Wilson 95% 区间 | `[0.643362139,0.667811075]` |
| wrong-local-peak rate | `0.034827586` |
| unconditional penalized error | `0.281383897` |
| 配对成功差及 95% 区间 | `0 [0,0]` |
| 配对误差差及 95% 区间 | `0 [0,0]` |
| wrong-peak 增量及 95% 区间 | `0 [0,0]` |

该 exact 子集相对完整父池的 MAC 降幅为 40%，但相对最强固定矩形为 0%。
方案 A 的 20% 固定基线成本降幅条件不成立；方案 B 的严格性能改善条件也
不成立。因此有限样本 Pareto 为 `0/3`。

Threshold profile T0/T1 的 `SNR_80` 分别为 `7.285714 dB` 和
`3.656250 dB`；完整父池对应 `7.285714 dB` 和 `3.620690 dB`。M0-M3 下
exact 的成功率为 `1.000 / 0.995 / 0.995 / 1.000`，wrong-local-peak 均为
0。Stage-5 coherent-weak stress 下 exact、固定 3x5 和完整父池均为
`0/200`，Wilson 95% 区间为 `[0,0.018845326]`，无条件惩罚误差为
`0.632455532`。这是一条共同物理/算法边界，不要求 subset 单独解决。

本阶段不提供或计算 false-split、missed-split、false-resolved 或 unresolved
rate。

## H. 完整复杂度

| 项目 | 数值 |
|---|---:|
| FIM evaluations | 1,292,928 |
| covariance decompositions | 2,184 |
| whitener eigendecompositions | 2,184 |
| manifold evaluations | 6,985 |
| derivative evaluations | 2,368 |
| generalized-eigenvalue evaluations | 2,585,856 |
| greedy add/drop/swap candidate evaluations | 122 |
| finite-sample DML score calls | 11,734,516 |
| finite-sample SVD calls | 11,734,516 |
| exact enumeration runtime sum | 399.0746 s |
| complete runner wall runtime | 1641.6270 s |
| peak-memory estimate | 110,347,346 bytes |
| generated result volume at bundle close | 1,378,536 bytes |

`EXACT_ETA_080` 的输出为 15 个 complex-double 通道，即 240 bytes；权重内存
为 499,200 bytes，估计数据搬运为 33,520 bytes，每样本 MAC 相对常规中心
1x1 增量为 5070。其单子集离线 1184 场景评估时间为 0.3474 s。

冻结后且未参与选择的 256-sample batch 微基准测得 exact 3x5 与 full 5x5
的在线两级 DBF 时间分别约为 12.116 和 17.183 microseconds/sample。
该微基准只作实现诊断，不改变以 MAC 为主目标的冻结选择结果。

## I. 风险、失败边界与降级项

1. FIM retention 是局部一阶信息，不等于有限样本成功；风险 CSV 原样保留。
2. 父池 design eta 上限低于 0.90，不能通过调低 eta0 掩盖。
3. Exact 0.80 与最强固定 3x5 相同，故没有算法 Pareto 收益。
4. Coherent-weak stress 对 full/exact/fixed 同时失败，未删除或改门。
5. 刘旗 2026、PR-DML、Kim 2012 和旧 factor=2 B7 均没有伪造同条件复现。
6. Physical exact tangent null 仍未验证；阶段 6 六阶式仍只由 synthetic fixture 支持。
7. 主长跑存在落盘后的 R2022b heap-cleanup 异常；独立短进程验证均正常退出。
8. `exact` 不外推到 ragged 子集、任意通道组合、更大父池或连续波束空间。

## J. 下一阶段判定

阶段 8 **不获技术授权**。本轮已按要求停在阶段 7，没有执行 K1/K2
bootstrap、false-resolved 控制、resolved/unresolved calibration 或任何阶段 8
代码。若未来重新提出阶段 8，必须由用户另行授权，并先处理阶段 7 没有超过
固定矩形这一贡献边界；当前证据本身不能作为自动继续的许可。

## Stage7.1A2 code-only 补充审计

**A2 code-only 修订与短单测已通过；Stage7.1B 未执行，closure 未完成。**

Stage7 source-hashed README 已稳定化：不再保存运行或 rerun 状态，后续状态只
由 Stage7.1 results 和本文记录，且 Stage7.1B 不得再次修改。该 README 的
冻结 Git blob 为 `ad2e11de647e31a8c92de9fdc653e5d1f1040d18`。

edge diagnostic 仍是原六个 scenario ID、三个方法、`[0,5,10] dB`、
`Nmc=200` 和 seed 基数 `20260719`，但随机设计改为 18 个
scenario-by-SNR paired group：每组一个 seed、一个 `paired_group_id`，三个方法
共享公共阵元域 trial，再分别应用物理子集。计划只被冻结和测试，本轮没有执行
Monte Carlo。

角域合同保留 `historical_registered_domain_pass`，新增
`tolerant_registered_domain_pass`、`boundary_numeric_disagreement_flag` 和
`domain_tolerance_deg`。容差严格为
`parameter_dimension*eps(domain_scale_deg)`，不含经验角度常数。D0286 固定为
historical false、tolerant true、boundary disagreement true，后续 edge gate
使用 tolerant pass。

既有方法 Pareto 敏感性在任何计算前检查所有比较方法拥有相同 scenario 集合，
并检查各 scenario 的 `n_trials` 一致；full-parent conservative
shared-reference interval 标签保留。正式 complexity accounting 必须显式传入
frozen plan 的 `N_el/N_az/B_el/B_az`，内置默认值仅能在 unit-test mode 与
default opt-in 同时为 true 时使用。

Stage7.1 code identity 记录 source base commit
`5ed1b5686b0cdfb74a835c7d298b8e3181961e28`、Git `mode/blob/path` tree hash
`89c54fd78a60f3b9eb506446f638a757534ee02b1998f4c76c7867ead95055b8` 和
identity hash
`e78bb4b9eae45f2f4cb8d2ca252ad3065895bcdb5b957ee7327dc1d23f86303e`，供未来
获授权的 Stage7.1B 输出绑定。

A2 code-only 总入口共 523 条断言通过，Code Analyzer 与 scope violation 均为
0；Stage7 core 与 results/figures 修改数为 0（Stage7 仅稳定化 README），
Stage6 `21/21`、Stage5 `14/14`、Step11 `351/351` 冻结证据通过。本轮没有修改
FIM、DML、961 子集枚举、eta、Pareto 门或任何 Stage8 内容。Stage7.1 closure
仍未完成，本轮不授权或进入 Stage7.1B，也不改变阶段 8 的
`NOT_AUTHORIZED_BY_STAGE7_RESULT` 状态。
