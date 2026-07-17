# 新算法组合、更新规则与失败机制的 prior-art 审查

> 审查对象：编号 11 的候选算法与编号 12 的实施路线  
> 检索日期：2026-07-17  
> 目标：判断算法组合是否已经出现，并逐项审查更新规则、搜索/剪枝、波束选择、模型阶数与失败处理

## 1. 总判定

本轮**暂未发现直接工作**完整复现以下端到端流程：

```text
实际顺序接收 DBF
  -> 俯仰组数/组中心 DML
  -> 每个俯仰组内条件方位 DML
  -> 完整顺序波束域逐目标、逐维联合修正
  -> 相对阵元域 FIM 约束下的最小规则波束集
  -> bootstrap K1/K2 判定
  -> K2_RESOLVED / K2_UNRESOLVED
```

但是，流程中的 DML、beamspace ML、二维/三维双目标估计、AP/坐标更新、FIM/CRB 波束设计、最小测量选择、bootstrap source enumeration 和统计分辨检验都有直接前例。最稳妥的创新定位不是“发明了新的 ML、FIM 或坐标优化”，而是：

> 将已有估计和设计机制约束到全息凝视雷达实际“先俯仰、后方位”的顺序接收 DBF 接口，显式处理同俯仰组内多目标，并以完整顺序流形修正分阶段误差；同时把已有 FIM 保真/最小选择思想落实到实际规则波束库和近双目标可辨识场景集。

这是一项**系统结构和任务约束下的算法组合候选**。只有在与 AP-DML、PR-DML、局部 full DML、刘旗等 2026 CRB 波束设计及通用 FIM 传感器选择公平比较后，才能判断它是否不仅是已知模块串联。

## 2. 原子算法主张判定

| ID | 算法主张 | 判定 | 最近工作/机制 | 结论边界 |
|---|---|---|---|---|
| A01 | 先用俯仰 DBF 数据估计可分辨俯仰组，再估计组内方位 | **算法机制相似** | 两阶段/解耦二维 DOA、可分阵列处理、二维 UCA ML | 先一维再另一维的思想已有；“以可辨俯仰组而非逐目标为中间对象”是当前差异。 |
| A02 | 俯仰模型把方位流形、幅度和快拍变化吸收入系数矩阵 | **数学形式相似** | 可分多维阵列模型、矩阵/张量因子模型、集中 DML | 把另一维作为 nuisance 系数是标准降维思想；需证明该系数模型在实际顺序 DBF 下没有丢失组内结构。 |
| A03 | 对每个俯仰组执行单目标或多目标条件方位 DML | **算法机制相似** | 条件/分阶段二维 DOA、AP-DML、PR-DML | 同俯仰组内多源方位搜索是有意义的场景化，但求解机制不是新机制。 |
| A04 | 用完整顺序流形做逐目标、逐坐标最大化修正 | **已有完全相同方法** | Ziskind–Wax 1988 alternating projection；block coordinate ascent | 更新规则和“每步精确最大化则目标不减”是标准坐标上升性质。 |
| A05 | 用分组条件估计初始化 A04 | **算法机制相似** | coarse-to-fine、分阶段初始化、AP 多初值 | 初始化来源可以是工程贡献，但不能把坐标更新重新命名为新优化器。 |
| A06 | 小候选波束池穷举 | **已有完全相同方法** | 组合选择/最优实验设计 | 只能声称得到当前有限池内全局最优，不是一般全局最优。 |
| A07 | 大候选池按最坏 FIM 增益 add，再 drop/pair-swap | **算法机制相似** | greedy sensor selection、local exchange、optimal design | 没有次模性证明就没有固定近似比；Chepuri–Leus 的 SDP/稀疏松弛应加入基线。 |
| A08 | 以连续 SVD 子空间作为上界 | **算法机制相似** | 最优降维、PCA/SVD 子空间设计 | 连续子空间忽略规则波束库和乘积成本，只能作为松弛上界。 |
| A09 | parametric-bootstrap 嵌套 LRT 选择 K1/K2 | **算法机制相似** | bootstrap source enumeration；非正则模型阶数检验 | 领域内已有 bootstrap 阶数判定，当前差异是 DML LRT 和独立 K1 holdout 的具体校准。 |
| A10 | Fisher/置信区间不足时输出 `K2_UNRESOLVED` | **算法机制相似** | statistical resolution limit、GLRT/Rao resolution tests、reject option | “检出两个源”与“可可靠分离”不是新概念；结构化状态机和风险控制仍可构成工程贡献。 |
| A11 | K=3 采用 \(K=\sum_qK_q\) 的有限分组扩展 | **算法机制相似** | 多维源分组、自动配对、分阶段多源估计 | 只能写有限扩展；没有一般 K 的复杂度或一致性保证。 |
| A12 | A01–A11 与实际顺序圆柱阵 DBF 的完整组合 | **暂未发现直接工作** | Kim 2012、刘旗等 2026、经典 BML/AP/PR-DML 的交集 | 这是候选主创新，但“未发现”不证明组合具有非显而易见性或性能收益。 |

## 3. 与最近算法链的逐层比较

### 3.1 经典 DML 与 beamspace ML

Stoica–Sharman 的集中 DML和 Zoltowski–Lee、Davis–Fante 的 beamspace ML 已覆盖：

- 给定候选角度后消去未知幅度；
- 使用投影残差或解释能量作为 ML 评分；
- 在降维 beamspace 中保留正确噪声协方差；
- 以搜索/跟踪先验限制局部角域。

因此编号 11 的白化、SVD 投影评分和局部处理窗口是正确实现条件或任务假设，不是新估计器。

### 3.2 二维/三维和双目标近邻

以下工作直接压缩了当前流程可声称的空间：

- 1995 年 UCA 工作已经比较二维 DOA 的 MUSIC 和 ML。
- Kim 等 2012 已研究“三维 beamspace 中的低角双目标跟踪”。它不等同于当前俯仰分组流程，但在阵列维度、beamspace 和双目标对象上是强近邻。
- Vincent、Besson 与 Chaumette 2014 直接研究两个近源的近似 ML。
- Chen 等 2022/2024 已将 beamspace ML 用于低仰角/高度估计，并使用和差波束。
- 刘旗等 2026 已形成“阵元/波束 CRB 对比—近似保真 beamformer—ML 估计”的完整链。

当前论文必须逐篇说明不可替代差异：顺序接收 DBF、俯仰组内多目标、二维联合修正、从既有规则波束中做最小通道选择，而不是只写“别人是一维/低仰角，本文是二维”。

### 3.3 AP/PR-DML 与联合修正

编号 11 的更新

\[
\phi_k^{t+1}=\arg\max_{\phi_k}J(\ldots,\phi_k,\ldots),
\qquad
\theta_k^{t+1}=\arg\max_{\theta_k}J(\ldots,\theta_k,\ldots)
\]

属于 block coordinate ascent。Ziskind–Wax 的 alternating projection 已用逐源优化降低多源 ML 搜索维度；PR-DML 又提供了成熟的多源降维求解框架。

所以：

- “每步不降低 DML score”是标准性质，判为**已有完全相同方法**；
- 新内容只能是分组条件初始化、顺序流形的坐标组织和在该系统上的复杂度/失败率；
- 必须报告函数值收敛、角度收敛和正确解收敛三者的区别；
- 若需要大量多初值才能接近 local full DML，复杂度优势会被抵消。

## 4. 搜索、剪枝与优化流程审查

| 流程 | 已有解决方式 | 当前方案的位置 | 必须增加的对照 |
|---|---|---|---|
| 多源 DML 高维搜索 | AP、PR-DML、importance sampling、gridless ML、局部/全局优化 | 俯仰分组后条件方位，再局部坐标修正 | 相同评分次数/运行时间预算下的 AP、PR-DML、local full DML |
| 小波束池组合选择 | 完全枚举 | 池内枚举 | 报告候选池大小与“池内最优”，不能写一般最优 |
| 大波束池稀疏选择 | \(\ell_0\) 建模、\(\ell_1\)/SDP 松弛、次梯度、randomized rounding、greedy/exchange | 最坏 FIM 增益 add/drop/pair-swap | Chepuri–Leus 型松弛、固定邻域、随机/贪心、连续上界；相关 DBF 噪声下不可直接假设 FIM 逐束可加 |
| 固定网格偏差 | gridless ML、SBL refinement、局部连续优化 | 首版仍是高精度局部网格 | Pote–Rao、beamspace off-grid SBL、连续局部 ML |
| 模型阶数 | AIC/MDL、两步测试、bootstrap source enumeration、GLRT/Rao resolution tests | parametric-bootstrap nested LRT | AIC/MDL、bootstrap source-enumeration、已知 K oracle |
| 不可辨识样本 | resolution limit、置信区间、拒判/不确定输出 | `K2_UNRESOLVED` | 覆盖率、错误 resolved 率、unresolved 率和无条件风险 |

### 4.1 当前复杂度式不能代表完整算法

编号 11 给出的

\[
O\{TK(N_\phi^{\rm loc}+N_\theta^{\rm loc})\}
\]

只描述第三阶段局部坐标修正。完整代价还包括：

- \(Q\) 组俯仰 DML 的模型阶数搜索；
- 每组 \(K_q\) 源的条件方位 DML；
- 多初值和 bootstrap 重拟合；
- 每个波束子集、每个设计场景的 FIM 与广义特征值；
- 大池 add/drop/pair-swap 的候选重评估。

若第一阶段对 \(Q\) 个俯仰角做直接网格，代价仍可含 \(N_\theta^Q\)；组内直接方位 DML 可含 \(N_\phi^{K_q}\)。最终文稿必须给出总调用次数和矩阵维度，而不是用第三阶段的线性候选数代替总复杂度。

## 5. 相同失败机制及已有解决方案

### 5.1 错误局部峰

**已有机制：** 多源 ML/AP 会收敛到局部最优，目标函数单调不等于角度正确。  
**已有应对：** 多初值、粗全局搜索、PR-DML、importance sampling、全局/半全局基线。  
**对当前方案的要求：** 报告错误峰概率、best-of-R 成本和与 local full DML 的 score gap；不得只展示单调曲线。

### 5.2 近源、低 SNR和少快拍的 threshold effect

**已有机制：** Pakrooh 等 2016 证明/模拟压缩数据下 signal/noise subspace swap 会使 ML MSE 突然偏离 CRB；其案例正是两个近 DOA 源。  
**已有应对：** 显式估计 swap/threshold 概率、增加测量维数、降低压缩、使用先验或全局风险指标。  
**对当前方案的要求：** FIM 保真只能覆盖局部高 SNR 信息，不能替代 threshold-risk 实验。波束集选择至少要在 holdout 上同时约束 CRB 保真和错误峰/错误分裂概率。

### 5.3 两源存在但不可分辨

**已有机制：** 统计角分辨极限文献通过假设检验、GLRT 或 Rao test 定义两点源可分辨边界。  
**已有应对：** 把 source detection 和 source resolution 分开，按显著性/功效或置信域给出分辨结论。  
**对当前方案的要求：** `K2_UNRESOLVED` 是合理工程状态，但应与已有 resolution-limit 定义对齐，并报告 false resolved，而不只报告 K2 detection。

### 5.4 非正则模型阶数检验

**已有机制：** K1 下第二源角度不可识别、幅度位于边界；普通 Wilks 卡方失效。  
**已有应对：** parametric bootstrap、专用极限分布、信息准则和独立校准集。  
**对当前方案的要求：** bootstrap 不是自动正确；必须在 K1 holdout 控制 false split，并对模型失配和病态 K2 单独报告。

### 5.5 压缩后 FIM 相同但有限样本风险不同

**已有机制：** 两种压缩可以有相似局部 CRB，却有不同旁瓣、全局歧义和 subspace-swap 风险。  
**已有应对：** KL/ambiguity、threshold probability、out-of-sector robustness、Monte Carlo 全局风险。  
**对当前方案的要求：** 不能只按 \(\eta\) 选波束；至少把全局/局部歧义和失败概率作为验证指标，而非继续加一个无推导的线性权重。

### 5.6 强相干和幅度失衡

**已有机制：** steering 列接近、源信号相干或弱次目标会使 FIM/样本协方差病态。  
**已有应对：** deterministic ML、空间平滑、结构化先验、明确拒判。  
**对当前方案的要求：** `K2_UNRESOLVED` 可以覆盖失败，但不能把大量失败样本从主指标中删除；需同时报告无条件惩罚误差。

## 6. 最接近工作的算法差异

| 工作 | 已经包含 | 没有核验到的当前特征 | 对当前新颖性的影响 |
|---|---|---|---|
| Zoltowski–Lee 1991 | beamspace ML、低角雷达 | 俯仰组内条件方位、最小规则波束集、bootstrap 状态机 | BML 本身不能主张。 |
| Davis–Fante 2001 | ML beamspace 搜索/跟踪处理器 | 当前三阶段顺序圆柱阵流程 | 局部搜索/跟踪接口不是新概念。 |
| UCA 2D ML 1995 | 圆阵二维 DOA 的 ML | 顺序 DBF 和分组条件处理 | 二维圆阵 ML 不是新概念。 |
| Kim et al. 2012 | 低角、双目标、三维 beamspace | 本轮未核验到俯仰组→组内方位→联合修正 | 当前最强的算法对象近邻之一。 |
| Vincent et al. 2014 | 两个近源、近似 ML | 实际顺序 DBF 与 FIM 波束选择 | “近双源 ML”不能主张。 |
| Ziskind–Wax 1988 | 多源 ML alternating projection | 当前分组初始化 | A04 属已有机制。 |
| PR-DML 2017 | 多源 DML 降维谱搜索 | 顺序分组接口 | 必须作为求解基线。 |
| Chepuri–Leus 2014 | 最少选择、FIM/CRB 约束、全参数域、SDP/次梯度 | 顺序波束乘积成本和双近源 DML | A07/F13 的数学骨架已有。 |
| Pakrooh et al. 2015 | 压缩前后归一化 FIM、CRB 损失、DOA 案例 | 确定性规则波束子集 | FIM 归一化不能主张。 |
| Pakrooh et al. 2016 | 近双源 ML、压缩、subspace swap、threshold SNR | 当前状态机和顺序 DBF | 揭示仅用 FIM 的盲区。 |
| 刘旗等 2026 | 阵元/波束 CRB 等价条件、beamformer 设计、ML、低仰角 | 二维近目标、最少规则波束子集 | FIM/CRB-preserving BML 是强直接近邻。 |
| Bootstrap source enumeration 2013 | 阵列源数估计和 bootstrap | 当前 nested DML LRT + unresolved | bootstrap 不是独立新点。 |

## 7. 必须加入的 baseline 和消融

### 7.1 主算法

1. local full DML：同一真实接收流形、同一局部物理角域。
2. AP-DML：相同初值预算与评分次数。
3. PR-DML：相同候选域和停止条件。
4. Kim 2012/现有 3D-BML 可实现版本或等价复现。
5. gridless ML / SBL refinement。
6. 仅分组条件估计，不做联合修正。
7. 不分组，直接二维坐标上升。

### 7.2 波束选择

1. 固定连续 3/5/7/... 规则波束。
2. 旧 `greedy_combined_B7`。
3. 刘旗等 2026 的 CRB 近似保真设计。
4. Chepuri–Leus 型 \(\ell_1\)/SDP 稀疏选择或可行近似。
5. 最坏 FIM greedy add。
6. greedy + drop/pair-swap。
7. 小池穷举最优。
8. 连续 SVD 子空间上界。

其中 Chepuri–Leus 型 \(\ell_1\)/SDP 只应作为“可加独立观测”参考。当前相邻波束输出存在相关噪声，子集协方差逆随所选集合改变；若未先证明等价的固定白化/可加表示，就不能把其 SDP 结果当作当前问题的可行解或下界。

### 7.3 模型阶数/分辨

1. AIC/MDL。
2. bootstrap source-enumeration 基线。
3. nested DML LRT 的 parametric bootstrap。
4. 已知 K oracle。
5. 只输出 K1/K2，不允许 unresolved 的消融。

## 8. 推荐的保守贡献表述

### 贡献 1

> 面向实际“先俯仰、后方位”的顺序接收 DBF 数据接口，构造以可辨俯仰组为中间变量的条件 DML 流程，并用完整顺序波束流形进行局部联合修正，以处理同俯仰组内的有限多目标方位估计。

标签：**暂未发现直接工作**（完整组合）；其中 DML、条件估计和坐标修正分别为已有数学/算法机制。

### 贡献 2

> 在已有压缩 FIM 和 FIM 约束稀疏选择框架上，针对实际俯仰/方位规则波束库，按相对阵元域的最坏信息保真和乘积输出通道成本选择最小局部波束集，并在近双目标、功率失衡和相干场景上独立验证。

标签：**数学形式相似**；刘旗等 2026 使“CRB/FIM-preserving beamspace ML”本身只能视为**只有问题场景不同**。

### 支撑机制

> 用独立 K1 holdout 校准的 parametric-bootstrap DML 阶数检验控制 false split，并结合分辨信息和置信域区分 `K2_RESOLVED` 与 `K2_UNRESOLVED`。

标签：**算法机制相似**。

## 9. 停止或降级条件

满足任一项时，应把对应“创新点”降级为工程实现或否决：

1. 相同计算预算下不优于 AP/PR-DML 或 local full DML。
2. 三阶段流程的收益完全来自更窄、含真值泄漏的候选域。
3. 联合修正必须使用大量多初值才能避免错误峰，导致成本不低于基线。
4. FIM 波束集与固定相邻波束相比没有通道数或有限样本性能收益。
5. 相同 \(\eta\) 下 threshold failure 很高，说明局部 FIM 约束不足。
6. bootstrap 无法在独立 K1 holdout 控制 false split。
7. `K2_UNRESOLVED` 被用来排除大量困难样本，使 conditional RMSE 看似改善而无条件风险恶化。
8. 最终贡献只能表述为“把已有 DML、FIM 选择和 bootstrap 串联”，且没有系统约束带来的新性能/复杂度证据。

## 10. 检索说明

文献、检索式、数据库响应、全文/摘要核验等级和主张 × 文献矩阵见 `06_closest_work_matrix.md`。本文件中的“暂未发现直接工作”是有界检索结论，不覆盖专利，也不替代投稿前的付费数据库全文复核。
