# 阶段 7 / Step12.5 exact rectangular-subset FIM 审计

> 日期：2026-07-19
> 仓库：`makabaka165/bs_innovation`
> 基线：`ea1c0320b7ba9639d6d955a1a45037cdc6cfdb31`
> 分支：`main`
> MATLAB：R2022b
> 活跃相位：`phase_factor=1`
> 冻结计划 hash：`1c6f99f158a118e5dc79efaa02076009cf103f87c9861d1dd52da27fb8608f23`
> Stage 7 source-tree hash：`16ee445f7045de64fc3add07f401b802b0da1df9a3b1c26661a34238cc90191d`
> 阶段 6 evidence bundle hash：`0c1f444603398e03865043af4e4c6e4a414dd15a3cc90e0539b19c56e990c839`
> Stage7.1 evidence bundle hash：`af40f8a7e8a0edfc7077594ebf08257cd0c7385d10902bc8dd624c83434bc322`

## A. 阶段结论

最终状态为 **`PASS_SYSTEM_ANALYSIS_ONLY`**。

开始前的 remote、main、HEAD/origin、R2022b、phase factor 和上游冻结 hash
预检均通过。本次创建了三个获授权的本地提交边界；未创建或切换分支，未推送
或创建 PR，也未执行 Stage8。

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

其中包含 runner、`common/`、`tests/`、`results/` 和 `figures/`。当前
Stage7 bundle 含 31 个结果文件与 8 幅注册 PNG，全部非空；排序外部
SHA-256 manifest 的文件 hash 为
`cc287ffee9852d2e39f58f1ec057d3466f3281a7a84db69932dad01013f91659`。
关键结果入口为：

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

本轮复用了在干净 A3 基准上已经完成的 MATLAB R2022b Stage7 长跑，没有再次
执行 1429 秒流程。该长跑正常退出，wall runtime 为 `1428.9983 s`，完成
961/961 子集、1184 个 FIM 场景、FIM gate 1/3、finite Pareto 0/3，并打印
`PASS_SYSTEM_ANALYSIS_ONLY`；Analyzer/scope/data-processing 为 `0/0/0`。
导入前在干净 A4 commit 上重建 locked plan 并逐字匹配当前 plan hash。

修订后的历史比较和独立短进程复核以退出码 0 完成：

- 计划 hash 与 source-tree hash 逐字匹配；
- Stage 6 `21/21`、Stage 5 `14/14`、Step11 `351/351`；
- 注册技术套件 `477/477`，包含 source common-scale 三项不变性；
- Code Analyzer 0；
- scope 与 no-model-order 扫描通过；
- data-processing violation 0；
- scientific/total historical comparison failures `0/0`；
- schema-dependent diagnostic variation count `1`；
- deterministic memory contract overall pass；
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
| actual unique physical-subset score calls | 9,152,562 |
| label-charged finite-sample DML score calls | 11,734,516 |
| duplicate method-label charge | 2,581,954 |
| finite-sample SVD calls | 11,734,516 |
| exact enumeration runtime sum | 246.6689 s |
| complete runner wall runtime | 1428.9983 s |
| legacy schema-dependent workspace estimate, historical/current | 110,347,346 / 110,417,088 bytes |
| legacy estimate delta / relative delta | 69,742 bytes / 0.00063202245 |
| deterministic workspace contract | 34,611,200 bytes |
| materialized / factorized sequential weights | 499,200 / 17,136 bytes |
| generated result volume at bundle close | 1,401,807 bytes |

`EXACT_ETA_080` 的 3/5 顺序语义是 3 个俯仰中间通道、每通道 5 个条件
方位输出，共 15 个 complex-double 通道，即 240 bytes；materialized 等效
权重为 499,200 bytes，factorized 俯仰/方位权重为 1,536/15,600 bytes，估计
数据搬运为 33,520 bytes，每样本 MAC 相对常规中心 1x1 增量为 5070。其单
子集离线 1184 场景评估时间为 0.2736 s。

冻结后且未参与选择的 256-sample batch 微基准测得 exact 3x5 与 full 5x5
的在线两级 DBF 时间分别约为 6.069 和 10.015 microseconds/sample。
该微基准只作实现诊断，不改变以 MAC 为主目标的冻结选择结果。

legacy `peak_memory_estimate` 由 `whos('context')`、finite trials 和
enumeration 的 schema 大小组成；当前 plan 增加 source/dependency manifests
和 provenance metadata 后产生 69,742-byte 差异。该字段不是内存泄漏证据，
也不是真实进程峰值。正式 deterministic memory contract 与该诊断分离。

## I. 风险、失败边界与降级项

1. FIM retention 是局部一阶信息，不等于有限样本成功；风险 CSV 原样保留。
2. 父池 design eta 上限低于 0.90，不能通过调低 eta0 掩盖。
3. Exact 0.80 与最强固定 3x5 相同，故没有算法 Pareto 收益。
4. Coherent-weak stress 对 full/exact/fixed 同时失败，未删除或改门。
5. 刘旗 2026、PR-DML、Kim 2012 和旧 factor=2 B7 均没有伪造同条件复现。
6. Physical exact tangent null 仍未验证；阶段 6 六阶式仍只由 synthetic fixture 支持。
7. legacy workspace estimate 依赖 provenance schema，不能解释为真实进程峰值。
8. `exact` 不外推到 ragged 子集、任意通道组合、更大父池或连续波束空间。

## J. 下一阶段判定

阶段 8 **未执行且不由 closure 自动授权**。本轮没有执行 K1/K2 bootstrap、
false-resolved 控制、resolved/unresolved calibration 或任何阶段 8 代码。
若未来由用户另行授权，Stage8 只服务阶段 5 遗留的 K1/K2 统计闭环；它不得
改变阶段 7 没有超过固定矩形的贡献边界。

## K. Stage7.1 A4 + B 正式 closure

最终状态为 **`PASS_STAGE7_1_CLOSURE_AUDIT`**。A4 code-only commit 为
`854e649205913c9fa579a696b141b6c34fd20981`；Stage7 重生成 evidence
commit 为 `364c5b30f8cf85f9bc164de0b7fcb5bc8f167628`。A4 后不再修改
Stage7/Stage7.1 `.m` 或 README。

Stage7.1 source tree hash 为
`bdcea5bf6c863bd9648773ec1e01b1bade656eea0c0e0bec4059d9f4c917185a`，
stable code identity 为
`f3e84ecd77e63632d9e2eb0e70c0600fa0f370193ad27d6fa5717f0381700b4c`。
runtime HEAD 只进入 provenance/runtime metadata。A4 code-only 总入口 647
条断言通过，Code Analyzer/scope 为 `0/0`；Stage7/6/5/Step11 冻结检查和
`git diff --check` 通过。

### K.1 历史科学对照与内存分类

修订后的 comparator 从提交 `85615e0` 读取 11 个核心 CSV。321 条 comparison
rows 中 scientific failures 为 0、total failures 为 0、diagnostic variations
为 1；961 子集、`RECT_E14_A31`、Stage7 status 和有限样本成功计数均一致。

唯一变化是 legacy `peak_memory_estimate`：

| 项目 | 数值 |
|---|---:|
| historical | 110,347,346 bytes |
| current | 110,417,088 bytes |
| delta | 69,742 bytes |
| relative delta | 0.0006320224503 |
| status | `EXPECTED_PROVENANCE_SCHEMA_DEPENDENT_VARIATION` |

该值含 `whos('context')`、finite trials 和 enumeration schema bytes；当前
context 增加 source/dependency manifests 与 provenance metadata。它不作为
FIM/算法相等门、内存泄漏证据或真实进程峰值。

独立 deterministic memory contract 全部通过：

| 合同 | 数值 |
|---|---:|
| workspace | 34,611,200 bytes |
| candidate / admissible / evaluated | 25 / 961 / 961 |
| selected subset | `RECT_E14_A31` |
| `B_el/B_az/B_out` | 3 / 5 / 15 |
| materialized equivalent weights | 499,200 bytes |
| factorized elevation / azimuth / total | 1,536 / 15,600 / 17,136 bytes |
| actual unique score calls | 9,152,562 |
| charged score calls / duplicate charge | 11,734,516 / 2,581,954 |

### K.2 顺序、alias 与 minimum-cost 语义

3/5 明确表示 **3 个俯仰中间通道，每通道 5 个条件方位输出**，不是两个可交换
的独立波束计数。`EXACT_ETA_080` 与 `FIXED_RECT_3X5` 同为
`RECT_E14_A31`；`STAGE6_CENTER_3X3` 与 `FIXED_RECT_3X3` 也为同一
物理子集。eta0=0.80 的 minimum-cost family 含 6 个 MAC=7215 成员；注册
selection 保持 `RECT_E14_A31`，`RECT_E28_A31` 只作同成本 post-hoc
sensitivity。full-parent 区间保留 conservative shared-reference 标签。

### K.3 Paired edge diagnostics

edge plan 为 54 行、18 个 paired groups、每组 3 个固定方法。`Nmc=200`，
共生成 3600 个唯一公共阵元域 trial 和 10800 个方法行；每个公共 trial 的
truth、seed、realized SNR 和 identity hash 在三方法间一致。summary 为 54 行，
每行 200 trials。D0286 的 historical/tolerant/disagreement/edge pass 固定为
`false/true/true/true`，正式路径使用 tolerant gate。全部 edge 结果均为
post-hoc sensitivity，不参与 Stage7 selection。

### K.4 两次独立 closure

两个全新 MATLAB R2022b 进程均得到：

- closure `PASS_STAGE7_1_CLOSURE_AUDIT`；
- Stage7 `PASS_SYSTEM_ANALYSIS_ONLY`；
- Stage8 technical permission `false`；
- common/method counts `3600/10800`；
- 16 个 registry artifacts、13 个 deterministic artifacts；
- deterministic bundle hash
  `af40f8a7e8a0edfc7077594ebf08257cd0c7385d10902bc8dd624c83434bc322`。

13 个 deterministic artifacts 的 relative path、byte count、SHA-256 和 stable
identity 逐项一致。只变化了被排除的 runtime diagnostics 和自引用 manifest。
Run2 保留为正式结果。

Stage7 因此正式封存为系统设计分析，不升级为波束选择算法贡献。Stage8 未执行；
未来若由用户单独授权，只用于完成阶段 5 遗留的 K1/K2 false-split、
false-resolved 与 resolved/unresolved 统计闭环。
