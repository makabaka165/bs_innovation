# Stage8 Core-V2.2 单 CPI Known-K 最终冻结执行报告

```text
STAGE8_CORE_V2_2_FINAL_FREEZE_FAIL
STAGE8_CORE_V2_2_EXPERIMENT_INVALID
```

```text
SINGLE_CPI
SINGLE_RANGE_DOPPLER_CELL
KNOWN_K_CONDITIONAL_ESTIMATION
NO_TRACKING_INPUT
NO_CROSS_CPI_INPUT
NO_MODEL_ORDER_CLAIM
NO_FORMAL_STAGE8_1_PASS
NO_STAGE8_2_AUTHORIZATION
```

## Git 与执行现场

```text
Branch: experiment/stage8-core-v2
Starting HEAD: c0f77ee4bcd94cc621f459c6e365c63c2bc4c669
Prompt commit: b227da844cdc99fce40a2e94a5523fe54519cf50
Production code commit: 5f042b75ba6733ffdd531229f81cec7660418ca1
Evidence commit: THIS_DOCUMENTS_COMMIT
Push status: PUSH_REQUIRED_AFTER_EVIDENCE_COMMIT
Git clean at formal launch: true
origin/main unchanged: 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

正式执行使用一个 MATLAB R2022b 进程和 `-singleCompThread`。启动前
MATLAB、mwpython、coordinator 和 active lock 均为 0。

## 场景

- 单个 CPI；
- 单个已选距离–多普勒处理单元；
- 不使用航迹或跨 CPI 输入；
- 局部角域已给定；
- `K∈{1,2}` 是研究场景固定量或外部输入，本模块不估计 K。

## Gate F0

```text
F0_BOUNDARY_AND_ENVIRONMENT_PASS
```

- 分支、起点祖先和 `origin/main` 锚点正确；
- 正式启动时工作树 clean；
- 文档 15/16/23/24/26/27 未改；
- Step12.0–Step12.6 冻结源码未改；
- calibration/results/figures 未改；
- MATLAB external count = 0，lock count = 0，coordinator count = 0。

F0 审计保存在外部 runtime：
`E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_v1\f0_audit.mat`。

## Gate F1

```text
F1_FAIL_STOPPED
```

最终算法合同同时要求：

1. `CORE_LITE` 与 `CORE_PLUS` 的 K1 必须使用同一个 conventional singleton continuous 路径；
2. K1 禁止 grouped start；
3. 两种 mode 又必须分别逐 trial 位级匹配历史 H1/H2 K1 selected scientific fields。

历史证据中有一个 K1 trial 的 H1/H2 科学字段并不相同：

| Trial | Historical route | Initial angles | Final angles | RSS | Loglik |
|---|---|---|---|---:|---:|
| `R1_K1_N2_L1_SP6_INSIDE_OFF_GRID` | H1 / conventional | `[8 10]` | `[8.0920699030566574 10.099598405307129]` | 10.3920358675423 | -26.6657912334996 |
| `R1_K1_N2_L1_SP6_INSIDE_OFF_GRID` | H2 / grouped | `[8 10.199999999999999]` | `[8.0920698118747758 10.099598404408049]` | 10.392035863928 | -26.6657912282827 |

两行具有相同 `element_trial_hash`：
`3b0e869d44de9d497349a24f6adf56e8d2d6f3d447da8f0f429753bd96ad2d78`，
且均为 valid continuous upgrade；差异来自协议在最终路径中已禁止的 grouped K1 起点。

因此，同一个确定性最终 K1 路径不可能同时位级匹配这两个不同的历史目标。
协议第 5、10 节要求任何科学字段不一致时停止，且不得修改旧 CSV、恢复 grouped
K1、调参或继续独立验证。F1 在重建新 144-trial 数据之前硬停止。

F1 审计保存在外部 runtime：
`E:\bs_innovation_runtime\stage8_core_v2_2_single_cpi_known_k_final_v1\f1_audit.mat`。

## Independent registry

固定 registry 已由代码构造并通过结构测试：

```text
registered K1: 72
registered K2: 72
registered result rows: 288
```

由于 F1 未通过，正式执行量为：

```text
executed K1: 0/72
executed K2: 0/72
written result rows: 0/288
checkpoint count: 0
```

未计算独立验证 RMSE、win/tie/loss、q quartile、bootstrap CI 或正式复杂度。

## CORE_LITE / CORE_PLUS

```text
CORE_LITE_FINAL_STATUS: NOT_EVALUATED_F1_FAIL_STOPPED
CORE_PLUS_FINAL_STATUS: NOT_EVALUATED_F1_FAIL_STOPPED
```

生产接口和开发期合同测试已完成，但不得把开发期 smoke test 当作 144-trial
独立证据，也不得由此作最终性能判定。

## 最终状态

```text
Final state: STAGE8_CORE_V2_2_EXPERIMENT_INVALID
Model-order: DEFERRED
Formal 6000-trial: DEFERRED_NOT_FAILED / NOT_EXECUTED
Stage8.2: NOT_AUTHORIZED / NOT_EXECUTED
MATLAB / lock / coordinator after stop: 0 / 0 / 0
```

该状态表示 V2.2 冻结协议的历史回归合同内部不相容，不表示既有
`STAGE8_CORE_V2_1_OPERATIONAL_GROUPED_OPTIONAL` 科学结果失败。依照最终冻结条款，
不创建 Core-V3，不恢复自动 K、q threshold、resolved/unresolved、第三版 K2
solver、K=3、6000-trial 或 Stage8.2。
