# v0.19 顺序测角修订范围说明

> 版本：Step12.2，2026-07-17
> 活跃相位模型：`phase_factor=1`  
> 当前结论：接收流形、真实先俯仰后方位 DBF 和稳定白化/SVD-DML 数值后端验证通过；角度搜索、分组、FIM 和 K1/K2 均未实现。

## 1. 系统层级

| 层级 | 规范名称 | 本项目责任 |
|---|---|---|
| 1 | 阵元数字接收链路 | 射频、下变频、ADC、数字下变频、脉压，形成阵元复数据 |
| 2 | 常规顺序 DBF 与检测处理 | 形成俯仰/方位波束、距离–多普勒检测、常规粗角度与误差描述 |
| 3 | 局部未分辨目标簇超分辨测角 | 在局部角域内执行 K1/K2 判定和精细二维角估计 |
| 4 | 航迹与资源管理 | 数据关联、跟踪、跨 CPI 处理和波束调度 |

候选研究路线位于第 3 层。局部角域只能来自第 2 层的常规测角置信域或常规波束角分辨单元，不能继续描述为来源不明的人工固定窗口。第 1 层不负责产生局部双目标搜索域。

## 2. 接收相位模型

接收阵列流形固定为

\[
\mathbf a(az,el)=\exp\left(j\frac{2\pi}{\lambda}\mathbf p^T\mathbf u(az,el)\right),
\qquad \mathrm{phase\_factor}=1.
\]

目标距离对应的单站双程相位对远场窄带接收阵元近似为公共项，并吸收到目标复包络。新活跃函数 `build_receive_cyl_steering_vec` 不接受 `PhaseFactor` 参数，也没有 factor=2 分支。

factor=2 仅允许出现在：

1. 冻结的 v0.18/Step11 旧源码、metadata 和结果；
2. Step12.0 波束宽度测试内部的隔离历史对照公式。

它不得进入新公共函数、活跃配置或新性能结论。

## 3. 旧结果边界

所有圆柱阵 Step11 数值结果均为 factor=2 legacy evidence，包括 W/B、topK3、C05、cache 和 Step11.7 集成结果。它们继续保留用于历史审计，但不得：

- 作为 v0.19 的 success、RMSE、复杂度或运行时间证据；
- 用于选择 factor=1 的波束数、搜索步长或阈值；
- 被 Step12 runner 覆盖；
- 与 factor=1 新结果合并统计；
- 通过只改 metadata 的方式恢复为有效证据。

Phase 0 冻结的 Step11 结果聚合 SHA-256 必须在每个后续阶段结束时复核。

## 4. K1/K2 主范围

主论文范围固定为 $K\in\{1,2\}$：

| 状态 | 含义 | 当前阶段状态 |
|---|---|---|
| `K1` | 局部单目标模型足以解释观测 | 尚未实现判定 |
| `K2_RESOLVED` | 双目标模型通过校准且两个目标达到预注册分辨条件 | 尚未实现判定 |
| `K2_UNRESOLVED` | 双目标证据存在，但角分离/信息条件不足以可靠给出两个独立角度 | 尚未实现判定 |
| `INVALID/OUT_OF_SCOPE` | 输入、白化、秩、搜索域或模型假设不满足 | 尚未实现状态机 |

K1/K2 bootstrap 只允许在阶段 8 实现。它必须用独立 K1 holdout 校准 false resolved，并在独立 K2 集上分别报告 resolved、unresolved 和 false unresolved。bootstrap 和 unresolved 输出本身均不是独立创新。

$K=3$ 不属于主范围，只能在全主链通过后进入可选阶段 10A；不得把有限 K3 探索写成支持任意多目标。

## 5. 当前证据

| 主张 | 证据 | 状态 |
|---|---|---|
| 新流形逐元素等于 factor=1 解析公式 | 9 个角中心，最大绝对误差 0 | supported |
| 解析导数相对于 radian 正确 | 9 中心有限差分，最大相对误差 az `1.020e-9`、el `1.476e-9` | supported |
| factor=1 主瓣比 factor=2 历史对照更宽 | 方位宽度比 `2.000075`、俯仰宽度比 `2.000147` | supported for deterministic model check |
| legacy/canonical 阵元映射严格可逆 | 随机复向量和多维张量 roundtrip/permutation/坐标误差均为 0 | supported |
| 真实顺序 DBF 与等效 `Wseq^H` 一致 | 随机/单目标/双目标误差均 `<2e-15` | supported |
| 条件因子化流形与完整 factor=1 流形一致 | 9 个角中心最大误差 `9.353e-15` | supported |
| 方位权依赖俯仰条件 | 公式最大误差 `6.707e-15`，非零条件变化量 `>1.49` | supported |
| 白噪声输出协方差趋近 `Wseq^H Wseq` | 20,000 样本相对误差 `0.02195` | supported for registered white-noise test |
| PSD 白化使用有效子空间坐标 | rank-deficient `Cb` 返回 `4x5` whitener，误差 `8.306e-16` | supported |
| 稳定 SVD 评分与良态参考一致 | 对 `pinv` 最大相对误差 `1.681e-15`，对 QR 为 `7.202e-16` | supported |
| 流形整体尺度不改变投影评分 | `1e-8/1/1e8` 相对展宽 `5.937e-16` | supported |
| 重复列及 `B<K` 返回秩亏状态 | 重复列秩 1；`B=2<K=3` 返回 `RANK_DEFICIENT` | supported |
| 集中方差使用 ML 分母 `rC*L` | rank-deficient 白化坐标 `rC=3`，公式误差 0 | supported |
| 分组/条件 DML 有效 | 无 | not supported |
| FIM 波束设计有效 | 无 | not supported |
| K1/K2 bootstrap 已校准 | 无 | not supported |

## 6. 明确禁止的表述

- 不得把接收 factor=1 验证写成顺序 DBF 或超分辨算法已经完成；
- 不得引用 v0.18 factor=2 数值作为 v0.19 新结果；
- 不得把 DML、SVD/QR、AP、投影 FIM、归一化 FIM、FIM 约束最少选择、bootstrap 或 unresolved 单独声明为创新；
- 不得声称局部搜索域由硬件链路自动给出；
- 不得声称支持任意多目标、一般有色噪声、完整实时闭环或 FPGA 部署；
- 不得在 design/validation 后继续用 holdout 调参。

## 7. 后续阶段门

阶段 3 的稳定白化和 DML 数值后端已经通过注册门。下一阶段只能验证俯仰组 DML 与 `rank(Ge)`、`rank(Ce)` 和局部唯一性，不得直接进入条件方位联合修正或 FIM。阶段 4、6、7、8 分别是可辨识性、局部理论、exact-subset FIM 和 K1/K2 校准的强制否决门，不能跳过。
