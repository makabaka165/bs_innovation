# 当前论文创新主张、证据与不足审计

> 用途：交给外部 Pro 模型重新判断论文创新空间。  
> 审计对象：`beamspace_ml_v18` 的 v0.18 论文、Step11 主线 MATLAB 代码、技术审计和已保存实验结果。  
> 审计日期：2026-07-16。  
> 本文档只梳理现状与问题，不提出、暗示或筛选新的创新方案。

## 0. 先给结论

当前论文把一条主贡献和三个支撑机制组合为“低复杂度 controlled pair2d beamspace ML 后端”：

1. 真实圆柱阵流形下的 controlled pair2d DML；
2. `greedy_combined_B7` 波束矩阵选择；
3. fixed topK3 coarse-to-fine 与 C05 自适应搜索预算；
4. shared-center canonical beamspace manifold cache。

代码验证后的总体判断是：**这条链目前不足以作为一个逻辑闭合、普适且严格推导的算法创新来成立。** 各部分的性质并不相同：

| 部分 | 当前更准确的性质 | 创新性风险 |
|---|---|---|
| 真实圆柱阵流形、DML、白化 | 正确建模与经典估计器实现 | 这些本身主要是正确性基础，不是新算法 |
| controlled pair2d | 场景先验约束下的候选集合设计 | 参数化本身未必降维，复杂度收益主要来自离散分离列表、排序和局部窗口 |
| `greedy_combined_B7` | 经验加权的离线波束子集选择 | 无风险/CRB/似然推导，无全局或近似保证，且存在更强的直接邻近工作 |
| fixed topK3 | 标准粗到细搜索启发式 | 能减少候选数，但没有保峰概率或最优性保证，不改变估计准则 |
| C05 | 多阈值、多分支的经验预算策略 | 规则堆叠严重；病态压力集无性能增益且计算量反增；不宜作为核心创新 |
| manifold cache | 基于旋转等价和 exact-grid 的 memoization | 软件优化有效，但不改变估计器，不是独立算法创新 |
| 已删除的自适应 W/B | 已被正式实验否决的失败路线 | 不应通过继续调阈值恢复为创新声明 |

当前最需要外部模型重新判断的不是“如何替 C05 再加一条规则”，而是：**论文究竟还剩下哪个独立、必要、可推导、可比较的科学问题。** 本文档不回答该问题，只提供判断材料。

## 1. 审计依据和证据等级

### 1.1 本地依据

主要依据如下：

- 论文：`beamspace_ml_v18/paper/full_manuscript_v0.18_引用文献支撑修订稿.md`
- 贡献摘要：`beamspace_ml_v18/review/supporting_notes/contribution_summary.md`
- 论文边界：`beamspace_ml_v18/review/supporting_notes/paper_scope.md`
- 主张表：`beamspace_ml_v18/review/technical_audit/claim_table.md`
- 参数表：`beamspace_ml_v18/review/technical_audit/parameter_table.md`
- baseline 表：`beamspace_ml_v18/review/technical_audit/baselines.md`
- 第二轮技术审查：`beamspace_ml_v18/review/technical_audit/audit_outputs/second_round_technical_review.md`
- 公式/代码/数据映射：`beamspace_ml_v18/review/technical_audit/audit_outputs/mapping_claim_formula_code_data.md`
- W/C05 文献支撑报告：`beamspace_ml_v18/review/supporting_notes/literature_support_W_C05_v17.md`
- 失败路线：`innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md`
- Step11.1、11.2、11.3、11.5、11.6、11.7 的 MATLAB 源码及 CSV/Markdown 结果。

### 1.2 证据等级

| 等级 | 含义 |
|---|---|
| A | 公式、代码、数据相互一致，且有直接对照或压力证据 |
| B | 实现和局部实验成立，但场景、样本或 baseline 有明显限制 |
| C | 主要由经验参数、调参验证或代表性案例支持 |
| D | 仅有概念说明、人工 guard probe 或尚未审计的比较 |
| F | 已有明确负结果，不应继续作为正面主张 |

这里的等级评价的是**当前证据强度**，不是对未来可研究价值的评价。

## 2. 当前算法到底做了什么

### 2.1 信号与波束域模型

当前论文假设窄带、远场、已知且校准的圆柱阵几何。阵元域模型为

\[
Y=A_{\mathrm{cyl}}(\Theta)S+N,
\]

波束域观测和流形为

\[
Z=W^HY,\qquad G(\Theta)=W^HA_{\mathrm{cyl}}(\Theta).
\]

实验采用双程相位因子 `spatialPhaseFactor=2`。全阵为 `192 x 32 = 6144` 个阵元，当前工作子阵为 `65 x 32 = 2080` 个阵元；载频 10 GHz、波长 0.03 m、圆柱半径 0.4 m。

### 2.2 白化的真实含义

代码 `apply_beamspace_whitening.m` 在 `whitening_mode='white'` 时使用

\[
C_b=W^HW,
\]

对其特征值截断后计算 \(C_b^{-1/2}\)，并同时变换 \(Z\) 与 \(G\)。这只在阵元域噪声满足

\[
R_n=\sigma^2 I
\]

时，对非正交波束引入的波束域有色噪声进行正确补偿。它**不是**对任意杂波、互耦、非均匀阵元噪声或实测有色协方差的通用白化。固定截断值为 `1e-10`，没有随矩阵尺度、SNR 或估计误差自适应。

### 2.3 实际 DML 评分

理论写法为

\[
J(\Theta)=\operatorname{tr}\!\left(P_{G(\Theta)}ZZ^H\right),
\qquad
P_G=G(G^HG)^{-1}G^H.
\]

代码 `beamspace_dml_score.m` 实际使用

\[
\widetilde P_G
=G\left(G^HG+10^{-10}I\right)^{-1}G^H.
\]

因此实现中的 \(\widetilde P_G\) 在正则项非零时不再是严格正交投影矩阵。正则化是必要的数值保护，但论文推导与实现之间应明确区分“精确 DML 投影”和“固定岭正则的近似实现”。

双目标快速评分还直接使用 2 x 2 Gram 行列式分母

\[
d=s_{11}s_{22}-|s_{12}|^2,
\]

代码未设置相对秩阈值或与尺度相关的分母下限。近共线双目标流形下，这一实现存在放大数值误差的风险。

### 2.4 controlled pair2d 的真实候选集合

论文将两个目标写成中心、分离和方向变量，但代码中的复杂度压缩主要来自以下约束：

- 固定目标数 `K=2`；
- 方位对使用有序上三角候选，排除重复/同点组合；
- 俯仰不是两个自由连续变量，而是中心加少数离散分离值；
- 早期实现默认 `el_sep_index_list=[0,1,2]`；
- coarse 俯仰分离列表为 `[0, 0.36, 0.72]` deg；
- fine 俯仰分离列表为 `[0, 0.24, 0.36, 0.48, 0.60, 0.72]` deg；
- 方向变量只取 `+1/-1`；
- 搜索依赖前端粗中心和有限局部窗口。

若中心方位、中心俯仰、方位分离和俯仰分离都自由变化，则这仍然包含四个连续自由度；从 full4D 换成中心/差分坐标本身只是重参数化。**当前候选数下降的主要来源是候选集合受限，而不是坐标变换自动产生的数学降维。**

### 2.5 支撑机制的依赖关系

```text
真实圆柱阵几何 + 固定 K=2 + 前端局部窗口
                  |
            固定波束矩阵 W
                  |
      W^H W 白化（阵元白噪声假设）
                  |
     regularized beamspace DML score
                  |
       controlled pair2d 候选集合
                  |
        fixed topK3 coarse-to-fine
             /                 \
     C05 预算包装（可选）    cache（可选）
```

核心估计器并不依赖 C05 或 cache 才能定义。C05 只改变候选预算，cache 只改变流形获得方式；两者均可移除而不改变 DML 模型。

## 3. 逐项创新审计总表

| 当前主张 | 代码真正实现的内容 | 正面证据 | 关键不足 | 证据等级 | 当前合理定位 |
|---|---|---|---|---|---|
| 真实圆柱阵 controlled pair2d beamspace ML | 真实流形投影 + 固定 K=2 + 局部、有序、离散俯仰分离候选搜索 | 记录场景中与 local full4D 最高联合成功率相同，复杂度代理比约 3.96 | DML 和真实流形是经典基础；参数化本身未证明降维；结果依赖强先验与离散列表；强相干最坏成功率 0 | B/C | 场景约束下的模型/候选集合设计，算法创新性未建立 |
| 非正交波束白化 | 用 \(W^HW\) 做特征值截断白化 | 能处理阵元白噪声经非正交 W 后的相关性 | 不处理一般 \(R_n\)；固定 `1e-10`；未估计实测噪声 | B | 正确性机制，不宜单列创新 |
| `greedy_combined_B7` | 用投影损失、最大相关性和 \(\log\kappa(W^HW)\) 的加权和逐束贪心 | 当前波束池和场景中 B7 表现较好 | 权重经验；量纲/尺度不统一；无全局保证；未直接优化 DML 风险；硬件池未闭环 | C | 离线工程启发式 |
| fixed topK3 coarse-to-fine | 粗网格保留 3 个峰，再在固定窗口细化 | 代表集上 131461 降至 19161.9，50/50 与 full fine 一致 | `topK=3`、步长、窗口全靠经验；无漏峰概率或全局保证；不改进估计器 | B/C | 搜索加速启发式 |
| C05 | 根据 `cond_risk`、边界标志和 `gap_13` 选择 topK/window；其他特征多用于展示或置信标签 | 零偏/450 样本复验候选数约为 fixed 的 0.714，安全指标通过 | Stage1 失败后继续加规则；多个特征未参与实际分支；120 个病态样本中无成功率增益且候选数反增；真实 ILL 分支未触发 | C，病态集为 F | 有限验证集上的调参策略，不宜作核心创新 |
| canonical cache | 预存固定 W、固定排列、exact-grid 下的 \(G\) | 数值等价、约 2.08 MB、MATLAB 后端运行时间下降 | memoization；不改变估计；无插值；配置变化需重建；未证明硬件实时收益 | A（软件等价）/C（算法创新） | 软件工程优化 |
| final backend 包装 | 串接 C05、cache、接口与回退 | direct/cached 输出一致 | 集成不等于新算法；没有前端到跟踪器闭环 | B | 软件集成证据 |

## 4. 详细不足

### 4.1 主贡献：controlled pair2d beamspace ML

#### 可以确认的内容

- 使用真实圆柱阵坐标而不是把波束索引当作均匀线阵。
- common-el、controlled pair2d、local full4D 使用同一类 DML 评分，差别主要在候选集合。
- 在当前记录的局部比较子集上，pair2d 和 local full4D 的最高联合成功率均为 1，full4D/pair2d 候选复杂度代理约为 3.9589。
- common-el 在相同摘要中的成功率为 0.5625，说明允许俯仰分离对该子集有价值。

#### 理论不足

1. **“参数化降维”没有被严格证明。** 中心/差分表示若保留全部自由变量，与四角度表示是坐标变换；复杂度下降来自离散分离列表和先验约束。
2. **没有给出约束候选集合的覆盖条件。** 未证明真实双目标在何种前端误差、角分离和 off-grid 偏差下必然被列表覆盖。
3. **没有辨识性/分辨阈值分析。** 对两个投影后导向向量何时可区分、Gram 行列式何时稳定、相干源何时不可辨，没有定理或 CRB/阈值边界。
4. **固定 K=2。** 方法不判断 K=0/1/2/3+，在单目标输入时可能产生假分裂，在三个以上目标时模型失配。
5. **正则化评分与论文投影公式不完全一致。** 固定岭参数没有尺度推导。

#### 实验不足

- “等于 full4D”只在记录的局部子集成立，不能推广为一般等价。
- Step11.1 强相干压力结果包含：总体强相干通过率约 0.9514，但**最坏联合成功率为 0，最大 false-high-like 风险为 1**。
- 未完成与 beam-index smoothing MUSIC 的公平性审计；窗口、SNR、快拍、容差和计算预算是否匹配仍未知。
- 没有与近年直接 beamspace ML、低仰角 BML、近源近似 ML、gridless ML 方法进行同一数据/同一预算比较。
- 没有系统给出 CRB、阈值区性能、置信区间或 bootstrap 区间。
- 离散网格上的成功不等于任意 off-grid 角度下有效。

#### 场景不足

方法只适用于前端已给出正确局部中心、真实目标未出窗、双目标结构与离散分离列表相容的情况。它尚不能覆盖全空域盲搜、任意多目标、一般有色噪声、互耦/标定误差、宽带、近场或明显机动造成的模型变化。

### 4.2 `greedy_combined_B7` 波束选择

代码实际最小化

\[
S(W)=\alpha L_{\mathrm{proj}}(W)
+\beta\rho_{\max}(W)
+\gamma\log_{10}\kappa(W^HW),
\]

其中默认

\[
\alpha=1,\qquad \beta=1,\qquad \gamma=0.05.
\]

#### 关键问题

1. 三项的数值范围、物理单位和统计意义不同，直接相加没有归一化或决策论解释。
2. 权重不是由 DML 误差、CRB、检测概率、硬件资源或风险上界推导，而是经验设置。
3. 文本把投影损失描述为能量损失，代码却使用其平方根：

   \[
   L_{\mathrm{code}}
   =\sqrt{\frac{\|A\|_F^2-E_{\mathrm{proj}}}{\|A\|_F^2}}.
   \]

4. 代码计算候选 pair 的 `cond(G^HG)`，但 `combined` score 实际只使用 `cond(W^HW)`；最接近 DML 病态性的诊断量没有进入选择目标。
5. 贪心逐列加入没有全局最优性或近似比保证，结果依赖初始波束池、候选 patch 和 pair set。
6. “波束越多不一定越好”只是在当前非正交波束池和数值实现中的经验现象，不是普遍规律。
7. 推荐 B7 的验证场景少，主结果缺少置信区间；波束池是否能由实际射频/数字通道并行形成也未闭环。
8. 2026 年刘旗等的工作已经从阵元域/波束域 CRB 等价条件出发设计波束形成器，并用 ML、仿真和实测验证；它是当前 W 主张必须面对的直接且更强基线。

因此，当前证据只能支持“在指定波束池和实验集上选择了一个可用的固定 B7 配置”，不能支持“提出了严格的最优 W 选择算法”。

### 4.3 fixed topK3 coarse-to-fine

#### 正面结果

- full fine 候选数：131461；
- fixed topK3 平均候选数：19161.9；
- 复杂度代理降低约 6.8605 倍；
- 代表性 50 次试验中 full fine 与 topK3 均为 50/50 成功，full-grid match=1、topK miss=0、boundary hit=0。

#### 不足

- `topK=3` 没有由似然曲率、波束宽度、CRB、Lipschitz 常数或漏峰概率推导。
- coarse/fine 步长、局部窗口和分离列表均固定；它们共同决定结果，无法把收益单独归因给 topK。
- 50/50 只能证明该测试集一致，不能给出场景外安全保证。
- 粗网格一旦漏掉真实峰，后续细化无法恢复；当前没有全局回退代价的统计评估。
- 它不改变 DML 目标函数，也不改善病态估计，只减少评分次数。

更准确的分类是“工程搜索启发式”，而不是新的最大似然估计方法。

### 4.4 C05 自适应搜索预算

#### 当前全部经验常数

| 参数/规则 | 数值 | 来源性质 |
|---|---:|---|
| `topK_max` | 7 | 人工上限 |
| softmax 温度 `tau` | 0.02 | 经验标定 |
| `gap_scale` | 0.003 | 经验标定 |
| EASY gap | 0.0020 | calibration split 选择 |
| ambiguous gap | 0.0008 | calibration split 选择 |
| EASY topK | 1 | 经验分支 |
| ambiguous/boundary topK | 5/5 | 经验分支 |
| EASY window scale | 0.60 | 经验分支 |
| boundary window scale | 1.15 | 经验分支 |
| boundary margin threshold | 1.5 个 coarse step | 人工定义 |
| condition normalization | `log10(cond)/8` | 人工归一化 |
| ILL threshold | 0.85 | 人工阈值 |
| `U_search` 权重 | 0.65/0.30/0.05 | 人工加权 |
| `U_confidence` 权重 | 0.35/0.25/0.25/0.15 | 人工加权 |
| confidence thresholds | 0.55、0.75 | 人工阈值 |

#### 规则堆叠和冗余

- Stage1 因 `H_norm` 近 1、gap 标度不合适，几乎全部样本进入 HARD；平均候选数从 fixed 的 19126.26 增至 38749.86，正式失败。
- Stage2 没有从统一目标重新推导，而是把单一不确定度拆成 `U_search` 和 `U_confidence`，再增加 EASY/NORMAL/SCORE_AMBIGUOUS/BOUNDARY/ILL_CONDITIONED 分支。
- `U_search` 被计算、记录和画图，但 v2 policy 的分支判断**不使用它**。
- `gap_17` 被计算但不用于 v2 policy。
- `H_norm` 主要影响置信标签，不决定 topK/window 主分支。
- 实际预算分支主要依赖 `cond_risk`、二值 `boundary_risk` 和 `gap_13`；公式展示的复杂程度高于真正决策逻辑。
- `cond_risk=log10(cond)/8` 且阈值 0.85 意味着自然触发需约

  \[
  \kappa(G^HG)\ge 10^{6.8}\approx 6.31\times10^6,
  \]

  但真实压力测试最大条件数只有 63.6169，因此该分支在当前尺度下几乎不可达。
- ILL_CONDITIONED 的“验证”来自人工构造 `cond_risk=0.9` 的 guard probe，不是自然搜索样本。

#### 正面集与病态集相互冲突

正面验证结果：

- 零偏 validation 中 fixed/adaptive 成功率均为 1；
- 平均候选数 18558 -> 13242.6，比例 0.713579；
- Metkl=30、3 个 seed group、共 450 个样本中，full-grid match=1、topK miss=0、boundary hit=0；
- 最大候选比例约 0.71508。

病态压力结果：

| 指标 | fixed topK3 | C05 adaptive |
|---|---:|---:|
| 120 样本总体成功率 | 0.333333 | 0.333333 |
| RMSE | 0.247123 deg | 0.247123 deg |
| 平均候选数 | 17509.58 | 19020.42 |
| adaptive/fixed 候选比 | - | 1.086286 |
| ILL 自然触发次数 | - | 0 |

子组中，close same-elevation coherent、weak secondary 和 lower-SNR close pair 的 fixed/adaptive 成功率均为 0；C05 没有修复估计失败，反而增加候选数。C05 的同模型 score gap 只能描述当前模型内部的相对峰差，不能在模型失配时证明峰是正确的。

#### 审计结论

C05 不是新的 ML 目标函数，也不是模型阶数选择器；它只是搜索预算包装器。其当前形式具有典型的“一个规则失效后再加特征、阈值和保护分支”的堆叠特征。正面集能证明特定分布上的候选节省，病态集则否定了它对困难条件的估计改进和普适复杂度优势。**不应继续把 C05 当作核心算法创新。**

### 4.5 shared-center canonical manifold cache

#### 成立的内容

- 在固定 `greedy_combined_B7`、固定 65 x 32 canonical 阵元排列、shared-center 最近列规则和 exact-grid lookup 下预存 \(G=W^Ha\)。
- 记录的最大相对 G 误差约 `3.23e-14`；estimate、score、policy 一致；cache miss 为 0。
- 缓存约 2.08 MB；MATLAB 重复调用中存在运行时间收益。

#### 不足

- 本质是利用圆柱阵旋转等价进行 memoization，不改变统计模型、候选集合或估计准则。
- `supports_interpolation=false`；任意 off-grid 查询不受支持。
- W、阵元顺序、相位因子、波长、中心列或网格变化时需重建。
- 报告的 runtime 未证明缓存构建成本在动态配置下已摊销。
- MATLAB 计时不能代替 FPGA/SoC 的 BRAM、带宽、定点误差、时序和端到端延迟验证。

它可以作为软件实现贡献或工程优化，但不应与估计算法并列为独立算法创新。

## 5. 参数与规则来源审计

| 类别 | 参数 | 当前值 | 是否有严格来源 | 主要风险 |
|---|---|---:|---|---|
| 物理 | 载频/波长 | 10 GHz / 0.03 m | 系统设定 | 只支持该窄带配置的实验 |
| 物理 | 圆柱阵 | 192 x 32，R=0.4 m | 系统设定 | 几何泛化未验证 |
| 物理 | 工作子阵 | 65 x 32=2080 | 工程设定 | 子阵选择本身未优化/审计 |
| 物理 | 双程相位因子 | 2 | 雷达传播模型 | 与单程通信阵列公式不能混用 |
| 统计 | 目标数 | K=2 | 场景假设 | 无自动模型阶数判断 |
| 统计 | 快拍数 | L=64 | 实验设定 | 小快拍/变化 L 未系统验证 |
| 数值 | 白化特征值 floor | `1e-10` | 固定经验值 | 尺度相关性和偏差未分析 |
| 数值 | DML ridge | `1e-10` | 固定经验值 | 破坏严格投影；近奇异行为未界定 |
| W 选择 | alpha/beta/gamma | 1/1/0.05 | 经验 | 指标尺度与 DML 风险脱节 |
| W 选择 | B | 7 | 当前 sweep 推荐 | 只对当前池/场景成立 |
| 局部窗口 | az/el 半宽 | 1.5/1.2 deg | 工程设定 | 出窗时后端无法恢复 |
| coarse grid | az/el 步长 | 0.16/0.24 deg | sweep/经验 | 无误差上界 |
| fine grid | az/el 步长 | 0.08/0.12 deg | sweep/经验 | off-grid 偏差未分析 |
| 分离列表 | coarse el sep | 0/0.36/0.72 deg | 人工候选集 | 覆盖性无证明 |
| 分离列表 | fine el sep | 0/0.24/0.36/0.48/0.60/0.72 deg | 人工候选集 | 场景绑定明显 |
| 搜索 | fixed topK | 3 | 代表集选择 | 无保峰概率 |
| C05 | 全部阈值与权重 | 见 4.4 | calibration/人工 | 规则多、过拟合、自然分支不可达 |
| 评价 | az 容差 | 常见 0.15 deg | 评价设定 | 需与网格步长和工程需求分离 |
| 评价 | el-sep 容差 | 常见 0.25 deg | 评价设定 | 容差可能掩盖细微退化 |

除物理系统参数外，绝大多数算法参数都来自 sweep、代表集或人工规则。目前没有一个统一约束或风险目标同时解释 W、B、topK、窗口、分离列表和 C05 阈值。

## 6. 当前适用场景

### 6.1 有代码与局部证据支持的范围

| 维度 | 当前范围 |
|---|---|
| 阵列 | 已知、校准的圆柱阵；全阵 192 x 32，工作子阵 65 x 32 |
| 信号 | 10 GHz 窄带、远场、双程相位模型 |
| 任务 | 前端检测后的局部未分辨双目标精估计 |
| 目标数 | 固定 K=2 |
| 前端输入 | 粗方位/俯仰中心、局部窗口、有效中心列和可用前端状态 |
| 局部误差 | 已保存的前端偏差验证主要到 az/el 各 ±0.20 deg |
| 搜索 | 方位半宽 1.5 deg、俯仰半宽 1.2 deg，固定 coarse/fine 网格和 el-sep 列表 |
| W | 固定 `greedy_combined_B7` |
| 噪声 | 阵元域白噪声，经非正交 W 后用 \(W^HW\) 白化 |
| 快拍 | 主配置 L=64 |
| cache | fixed W、fixed ordering、shared-center canonical、exact grid |

“有证据支持”不代表上述范围内所有样本都成功。强相干、弱次目标和极近目标在该范围内仍有明确失败子组。

### 6.2 未支持或证据不足的范围

- K 未知，或 K=0/1/3+；
- 任意分离、非局部、多簇或全空域多目标；
- 粗中心严重偏差、目标在窗口边界或落出窗口；
- 任意 off-grid 角度和连续参数优化；
- 一般阵元噪声协方差、杂波、间歇干扰、非均匀噪声；
- 阵元互耦、幅相误差、失效通道、位置误差和阵列形变；
- 宽带、近场、分布式目标、扩展目标和明显时间变化；
- 快拍数、SNR、相干系数和幅度比超出当前有限 sweep；
- 任意阵列结构或不同圆柱尺寸的无重标定迁移；
- 完整检测-聚类-粗测角-精估计-跟踪闭环；
- FPGA/SoC 下板、定点实现、实时吞吐与硬件资源闭环。

### 6.3 与“全息凝视雷达工作模式”的关系

全息凝视雷达综述把该体制描述为同时覆盖广域/全空域、全时空探测和同时多功能的数字阵列雷达。当前代码中的“前端给出局部中心，再在有限方位/俯仰窗口内精估计”可以作为这种系统中的一个后端处理环节，但尚未证明：

- “固定一个维度、扫描另一个维度”是所有全息凝视雷达统一且必需的标准工作模式；
- 当前局部算法已经实现了全息凝视雷达的完整扫描、驻留、波束调度或多功能资源管理；
- 当前仿真中的固定中心/局部窗口来自真实雷达前端而非人工输入。

因此，论文可以把全息凝视雷达作为工程背景，但不能仅凭局部固定维搜索就宣称完成该雷达体制的工作模式实现。

## 7. 实验证据：能支持什么、不能支持什么

| 实验 | 已记录结果 | 能支持 | 不能支持 |
|---|---|---|---|
| pair2d vs common-el/full4D | pair2d/full4D 最高成功率相同；full4D/pair2d 候选比约 3.96 | 当前局部子集的候选约束有效 | 普遍等价、任意场景覆盖、理论降维 |
| 强相干压力 | 总体率较高，但 worst success=0、false-high-like max=1 | 暴露边界 | 已解决强相干双目标 |
| W/B sweep | 当前池推荐 B7；高 B 不单调 | 当前配置选择 | B7 全局最优、波束越多普遍越差 |
| fixed topK3 | 131461 -> 19161.9；代表集一致 | 当前集的搜索加速 | 漏峰概率保证、off-grid 安全 |
| C05 正面复验 | 450 样本安全指标通过，候选比约 0.715 | 该分布上的预算节省 | 病态场景改进、普适安全 |
| C05 病态 120 集 | success 0.3333=0.3333，候选比 1.0863 | 明确负面边界 | C05 对困难条件有收益 |
| cache | 数值/策略等价，约 2.08 MB，MATLAB 加速 | 指定配置的软件等价性 | 通用算法创新、FPGA 实时性 |
| final backend | direct/cached estimate/policy/score 一致 | 接口集成 | 完整雷达闭环 |

### 7.1 仍缺失的关键实验

这里列的是证据缺口，不是新创新方案：

- 与直接 beamspace ML 近邻工作的同数据、同先验、同计算预算比较；
- beam-index smoothing MUSIC baseline 的公平性复核；
- 阵元域 ML 或 CRB 作为信息损失基准；
- seed 级方差、置信区间、失败率区间和显著性检验；
- SNR、快拍、分离、相干、幅比、前端偏差的完整交叉覆盖表；
- off-grid 和连续角度偏差；
- 一般有色噪声、互耦、幅相、阵元位置和通道失效；
- cache build amortization、配置切换和硬件资源；
- 从真实前端输入到最终估计的端到端数据。

## 8. 已否决路线：似然判别自适应 W/B

该路线曾试图用局部假设可判别性、稳健似然间隔和信息秩分支在线选择 W/B。正式验证后已删除，不能作为当前论文的潜在正面结果。

| 指标 | 自适应 W/B 相对固定 B7 | 95% CI/结论 |
|---|---:|---|
| 总体成功率差 | -0.001786 | [-0.008929, 0.005357]，无改善 |
| 平均 B 差 | -0.228571 | 节省未达到预注册 0.5 |
| MATLAB 运行时间比 | 2.935 | 明显更慢 |
| 困难场景成功率差 | 0 | 无收益 |
| 困难场景惩罚误差差 | +0.006737 deg | 显著变差 |

增益/相位误差、失效通道和阵元位置误差下，该路线会在错误似然峰上过早停止于 B5。失败原因包括固定 B7 已接近当前波束池可用信息上限、在线贪心代价过高、似然间隔无法识别模型失配，以及软件原型先形成完整波束池而无法节约前端资源。

此负结果说明：**把经验 W 规则替换成更多在线判别阈值，并不会自动形成算法创新或工程收益。**

## 9. 文献关系与当前主张的重叠

### 9.1 技术谱系

下列箭头表示主题和方法谱系，不保证每一条都是已逐页核实的直接引用边：

```text
低仰角 ML 接收机（1980/1982）
        -> beamspace ML 低仰角跟踪（Zoltowski & Lee, 1991）
        -> beamspace 搜索/跟踪处理器（Davis & Fante, 2001）
        -> 三维 beamspace 双目标跟踪（Kim et al., 2012）
        -> 目标高度/和差波束/自适应 RML 等场景化 BML（2022-2024）
        -> CRB 保真波束形成 + ML + 实测（Liu et al., 2026）

经典多源 DML/ML（Ziskind & Wax; Stoica 等）
        -> AP、近似 ML、重要性采样、自然计算、ADMM
        -> off-grid/gridless ML 与结构化协方差方法（2022-2026）

任务相关降维（Anderson, 1993）
        -> beamspace preprocessing / manifold preservation
        -> transmit/compressive/measurement-matrix design
        -> 以 CRB 等价条件约束的 BML 波束设计（Liu et al., 2026）
```

### 9.2 对当前各主张最关键的论文

| 当前部分 | 最接近或最有约束力的已有工作 | 对当前创新性的影响 |
|---|---|---|
| beamspace DML | Zoltowski & Lee 1991；Davis & Fante 2001；Stoica & Sharman 1990 | 目标函数、集中似然和波束域 ML 均已有经典基础 |
| 局部双目标/三维 BML | Kim et al. 2012；Vincent et al. 2014；Chen et al. 2022/2024 | “双目标、低仰角、三维/高度、近间隔”不是空白场景，当前差异必须精确到约束与阵列几何 |
| W 选择 | Anderson 1993；Hassanien et al. 2006；Kilic et al. 2022；Ibrahim et al. 2017；Liu et al. 2026 | 已有任务相关降维、流形保真、measurement design 和 CRB 设计；经验三项加权难以形成强新颖性 |
| 多源复杂度 | Ziskind & Wax 1988；Wang et al. 2008；Vincent et al. 2014；Yang & Chen 2021 | 多维 ML 加速已有大量方法；fixed topK3 需按启发式而非新 ML 算法定位 |
| off-grid/gridless | Liu & Zhao 2022；Pote & Rao 2023；Gerstoft & Park 2025；Zhou et al. 2026 | 当前离散列表和 exact-grid cache 的边界已经有直接替代研究方向，但本文尚未比较 |
| 有色噪声/失配 | Pesavento & Gershman 2001；Djeddou et al. 2005；Lolaee & Akhaee 2018；Akdemir & Candan 2021 | 当前 \(W^HW\) 白化只覆盖阵元白噪声，不能表述为一般稳健 BML |
| C05 | Burnham & Anderson；Wagenmakers & Farrell；Hendrycks & Gimpel；Lakshminarayanan et al.；Kendall & Gal | 这些仅支撑相对权重/不确定度的一般概念，不是 DOA 搜索预算算法的直接先验，也不能证明当前阈值 |
| 全息凝视工程 | Guo et al. 2023 综述；Guo et al. 2023 系统实现；Oswald & Baker 2021 | 提供系统背景，但不能替代当前算法的端到端雷达模式和硬件验证 |

### 9.3 当前 baseline 体系的缺口

当前主要 baseline 是 common-el、local full4D、旧 beam-index smoothing MUSIC、不同 W 选择、full fine/fixed topK3 和 direct/cache。它们能完成内部消融，但不足以证明外部新颖性：

- common-el 和 local full4D 都是作者自己定义的候选集合，不是完整的现代外部算法基线；
- beam-index smoothing MUSIC 尚未完成公平性审计；
- 没有纳入 2012 三维双目标 beamspace 跟踪、2022/2024 低仰角 BML、2026 CRB 保真 BML 等直接工作；
- 没有纳入近源近似 ML、AP、gridless ML 或一般噪声 ML；
- 没有在同一精度下比较候选评分数、矩阵运算量、内存、端到端时间和硬件资源。

## 10. 相关文献总表

说明：以下是当前论文 41 条参考文献、W/C05 支撑报告中的补充文献，以及本轮 beamspace ML 定向检索所得相关文献的去重合集。并非所有论文都与当前方法同等接近；“直接”“邻近”“间接”标签用于防止过度引用。

### 10.1 原始/经典 beamspace、低仰角与直接 BML

| ID | 文献与链接 | 与当前工作的关系 |
|---|---|---|
| L01 | Capon, 1969, “High-resolution frequency-wavenumber spectrum analysis.” [DOI](https://doi.org/10.1109/PROC.1969.7278) | 经典高分辨谱估计背景，非 ML |
| L02 | Schmidt, 1986, “Multiple emitter location and signal parameter estimation.” [DOI](https://doi.org/10.1109/TAP.1986.1143830) | MUSIC 经典背景，非 ML |
| L03 | Roy & Kailath, 1989, “ESPRIT-estimation of signal parameters via rotational invariance techniques.” [DOI](https://doi.org/10.1109/29.32276) | ESPRIT 经典背景，非 ML |
| L04 | Krim & Viberg, 1996, “Two decades of array signal processing research: the parametric approach.” [DOI](https://doi.org/10.1109/79.526899) | 阵列参数估计综述 |
| L05 | Pesavento, Trinh-Hoang & Viberg, 2023, “Three more decades in array signal processing research.” [DOI](https://doi.org/10.1109/MSP.2023.3255558) | 现代阵列优化综述 |
| L06 | Godara, 1997, “Application of antenna arrays to mobile communications. II.” [DOI](https://doi.org/10.1109/5.622504) | beamforming/DOA 背景 |
| L07 | Haykin, Reilly & Taylor, 1980, “New realisation of maximum likelihood receiver for low-angle tracking radar.” [DOI](https://doi.org/10.1049/el:19800210) | 低仰角 ML 早期工作，直接场景谱系 |
| L08 | Haykin & Reilly, 1982, “Maximum-likelihood receiver for low-angle tracking radar. Part 1: The symmetric case.” [DOI](https://doi.org/10.1049/ip-f-1.1982.0039) | 低仰角 ML 经典工作 |
| L09 | Reilly & Haykin, 1982, “Maximum-likelihood receiver for low-angle tracking radar. Part 2: The nonsymmetric case.” [DOI](https://doi.org/10.1049/ip-f-1.1982.0050) | 非对称低仰角模型 |
| L10 | Xu & Buckley, 1988, “Maximum Likelihood and Least-Squares Broadband Source Localization in Beam-Space.” [DOI](https://doi.org/10.1109/ACSSC.1988.754612) | beamspace ML 早期直接工作；宽带 |
| L11 | Zoltowski & Lee, 1991, “Maximum likelihood based sensor array signal processing in the beamspace domain for low angle radar tracking.” [DOI](https://doi.org/10.1109/78.80885) | 当前目标函数与低仰角 BML 的核心经典先验 |
| L12 | Zoltowski, Kautz & Silverstein, 1993, “Beamspace Root-MUSIC.” [DOI](https://doi.org/10.1109/TSP.1993.193151) | beamspace 子空间方法背景，非 ML |
| L13 | Xu, Silverstein, Roy & Kailath, 1994, “Beamspace ESPRIT.” [DOI](https://doi.org/10.1109/78.275607) | beamspace 结构方法背景，非 ML |
| L14 | Kautz & Zoltowski, 1996, “Beamspace DOA estimation featuring multirate eigenvector processing.” [DOI](https://doi.org/10.1109/78.510623) | beamspace 维数、处理和条件性邻近工作 |
| L15 | Davis & Fante, 2001, “A maximum-likelihood beamspace processor for improved search and track.” [DOI](https://doi.org/10.1109/8.933484) | 直接 BML 搜索/跟踪处理器 |
| L16 | Kim, Yang & Kwak, 2012, “Low-angle tracking of two objects in a three-dimensional beamspace domain.” [DOI](https://doi.org/10.1049/IET-RSN.2010.0163) | 三维 beamspace 双目标，和当前场景高度接近 |
| L17 | 陈生等, 2022, “米波 MIMO 雷达波束空间精确最大似然算法.” [DOI](https://doi.org/10.12305/j.issn.1001-506X.2022.05.24) | 中文直接 BML 先验 |
| L18 | Chen et al., 2022, “A beamspace maximum likelihood algorithm for target height estimation for a bistatic MIMO radar.” [DOI](https://doi.org/10.1016/j.dsp.2021.103330) | 场景化 BML、高度估计 |
| L19 | Tang et al., 2024, “Bistatic MIMO radar height estimation method based on adaptive beam-space RML data fusion.” [DOI](https://doi.org/10.1016/j.dsp.2023.104346) | 自适应 beamspace RML 邻近工作 |
| L20 | Chen et al., 2024, “Beamspace Maximum Likelihood Algorithm Based on Sum and Difference Beams for Elevation Estimation.” [DOI](https://doi.org/10.23919/JSEE.2024.000057) | 和差波束 BML，直接低仰角/俯仰邻近工作 |
| L21 | Yang et al., 2025, “Coherent DOA Estimation of Multi-Beam Frequency Beam-Scanning LWAs Based on Maximum Likelihood Algorithm.” [DOI](https://doi.org/10.3390/s25123791) | 相干、多波束扫描、ML；阵列场景不同 |
| L22 | 刘旗等, 2026, “低仰角目标高精度波束空间DOA估计方法.” [DOI](https://doi.org/10.12000/JR25173), [期刊页](https://radars.ac.cn/cn/article/doi/10.12000/JR25173) | 推导阵元/波束域 CRB 等价充分条件、设计波束形成器并用 ML/实测验证；当前 W 主张的强直接基线 |

### 10.2 ML 复杂度、近源、gridless 与稳健性

| ID | 文献与链接 | 与当前工作的关系 |
|---|---|---|
| L23 | Zhu, Zhao & Shui, 2017, “Low-angle target tracking using frequency-agile refined maximum likelihood algorithm.” [DOI](https://doi.org/10.1049/iet-rsn.2016.0301) | 低仰角、频率捷变、refined ML |
| L24 | Xu et al., 2021, “A Beamspace Dimension Reduction Technique With Application to DOA Estimation in Low-angle Tracking.” [DOI](https://doi.org/10.1109/RADAR53847.2021.10028043) | 低仰角 beamspace 降维邻近工作 |
| L25 | Chen et al., 2022, “Beamspace Scene Classification Algorithm for Low-Angle Estimation in MIMO Radar.” [DOI](https://doi.org/10.3390/rs14081917) | 前端场景分类/模型选择邻近背景，不是当前 DML |
| L26 | Shao, Ding & Lu, 2006, “A Low Complexity Maximum Likelihood Algorithm for Targets DOA Tracking.” [DOI](https://doi.org/10.1109/ICOSP.2006.344522) | 低复杂度 ML 跟踪邻近工作 |
| L27 | Ziskind & Wax, 1988, “Maximum likelihood localization of multiple sources by alternating projection.” [DOI](https://doi.org/10.1109/29.7543) | 多源 ML 降复杂度经典基线 |
| L28 | Stoica & Nehorai, 1989, “MUSIC, maximum likelihood, and Cramer-Rao bound.” [DOI](https://doi.org/10.1109/29.17564) | ML/CRB 经典理论 |
| L29 | Stoica & Sharman, 1990, “Maximum likelihood methods for direction-of-arrival estimation.” [DOI](https://doi.org/10.1109/29.57542) | DML/SML 与集中似然核心理论 |
| L30 | Stoica & Nehorai, 1990, “MUSIC, maximum likelihood, and Cramer-Rao bound: further results and comparisons.” [DOI](https://doi.org/10.1109/29.61541) | ML 性能比较理论 |
| L31 | Athley, 2005, “Threshold region performance of maximum likelihood direction of arrival estimators.” [DOI](https://doi.org/10.1109/TSP.2005.843717) | 当前低 SNR/病态证据缺失的重要理论背景 |
| L32 | Vincent, Besson & Chaumette, 2014, “Approximate maximum likelihood estimation of two closely spaced sources.” [DOI](https://doi.org/10.1016/j.sigpro.2013.10.017) | 两个近源、近似 ML，和当前双目标高度相关 |
| L33 | Wang, Kay & Saha, 2008, “An Importance Sampling Maximum Likelihood Direction of Arrival Estimator.” [DOI](https://doi.org/10.1109/TSP.2008.928504) | ML 全局搜索复杂度替代思路 |
| L34 | Boccato et al., 2012, “Application of natural computing algorithms to maximum likelihood estimation of direction of arrival.” [DOI](https://doi.org/10.1016/j.sigpro.2011.12.004) | 非穷举 ML 优化邻近工作 |
| L35 | Krummenauer et al., 2010, “Improving the threshold performance of maximum likelihood estimation of direction of arrival.” [DOI](https://doi.org/10.1016/j.sigpro.2009.10.028) | 低 SNR 阈值区改进 |
| L36 | Pesavento & Gershman, 2001, “Maximum-likelihood direction-of-arrival estimation in the presence of unknown nonuniform noise.” [DOI](https://doi.org/10.1109/78.928686) | 一般非均匀噪声，超出当前 \(W^HW\) 白化 |
| L37 | Djeddou, Belouchrani & Aouada, 2005, “Maximum likelihood angle-frequency estimation in partially known correlated noise for low-elevation targets.” [DOI](https://doi.org/10.1109/TSP.2005.851194) | 低仰角、相关噪声、联合参数估计 |
| L38 | Akdemir & Candan, 2021, “Maximum-likelihood direction of arrival estimation under intermittent jamming.” [DOI](https://doi.org/10.1016/j.dsp.2021.103028) | 干扰失配下 ML |
| L39 | Barat, Karimi & Masnadi-Shirazi, 2021, “High-Order Maximum Likelihood Methods for Direction of Arrival Estimation.” [DOI](https://doi.org/10.1109/OJSP.2021.3093866) | ML 准则/高阶统计邻近工作 |
| L40 | Yang & Chen, 2021, “Maximum Likelihood Direction-of-Arrival Estimation via Rank-Constrained ADMM.” [DOI](https://doi.org/10.1109/RADAR53847.2021.10028640) | 优化层面的 ML 复杂度基线 |
| L41 | Lolaee & Akhaee, 2018, “Robust Stochastic Maximum Likelihood Algorithm for DOA Estimation of Acoustic Sources in the Spherical Harmonic Domain.” [DOI](https://doi.org/10.23919/EUSIPCO.2018.8553583) | 不同阵列域下的稳健 SML；邻近而非直接 baseline |
| L42 | Liu & Zhao, 2022, “Real-valued sparse Bayesian learning algorithm for off-grid DOA estimation in the beamspace.” [DOI](https://doi.org/10.1016/j.dsp.2021.103322) | beamspace off-grid 邻近工作，非 ML |
| L43 | Pote & Rao, 2023, “Maximum Likelihood-Based Gridless DoA Estimation Using Structured Covariance Matrix Recovery and SBL With Grid Refinement.” [DOI](https://doi.org/10.1109/TSP.2023.3254919) | ML-based gridless，直接约束当前固定网格边界 |
| L44 | Gerstoft & Park, 2025, “Atom-Constrained Maximum Likelihood Gridless DOA with Wirtinger Gradients.” [DOI](https://doi.org/10.1109/ICASSP49660.2025.10889232) | 连续参数/gridless ML |
| L45 | Zhou, Cao & Zhang, 2026, “Gridless DOA estimation for arbitrary array geometries based on maximum likelihood.” [DOI](https://doi.org/10.1016/j.sigpro.2025.110415) | 任意阵列几何的 gridless ML；当前圆柱阵离散网格的重要邻近工作 |

### 10.3 W、流形、阵列结构与粗到细搜索

| ID | 文献与链接 | 与当前工作的关系 |
|---|---|---|
| L46 | Mathews & Zoltowski, 1994, “Eigenstructure techniques for 2-D angle estimation with uniform circular arrays.” [DOI](https://doi.org/10.1109/78.317861) | 圆阵二维测角背景 |
| L47 | Belloni & Koivunen, 2006, “Beamspace transform for UCA: error analysis and bias reduction.” [DOI](https://doi.org/10.1109/TSP.2006.877664) | 变换误差/偏差分析，直接约束“保留真实流形”表述 |
| L48 | Belloni, Richter & Koivunen, 2007, “DoA estimation via manifold separation for arbitrary array structures.” [DOI](https://doi.org/10.1109/TSP.2007.896115) | 任意阵列流形建模 |
| L49 | Anderson, 1993, “On optimal dimension reduction for sensor array signal processing.” [DOI](https://doi.org/10.1016/0165-1684(93)90150-9) | 任务相关阵列降维经典工作 |
| L50 | Hassanien et al., 2006, “Convex optimization based beam-space preprocessing with improved robustness against out-of-sector sources.” [DOI](https://doi.org/10.1109/TSP.2006.870564) | 流形保持、扇区鲁棒和优化式 W 设计 |
| L51 | Hyberg, Jansson & Ottersten, 2004, “Array interpolation and bias reduction.” [DOI](https://doi.org/10.1109/TSP.2004.834402) | Frobenius 流形误差与估计偏差 |
| L52 | Kilic et al., 2022, “Adaptive Measurement Matrix Design in Direction of Arrival Estimation.” [DOI](https://doi.org/10.1109/TSP.2022.3209880) | DOA measurement matrix、RIP/coherence 设计 |
| L53 | Ibrahim et al., 2017, “Design and analysis of compressive antenna arrays for direction of arrival estimation.” [DOI](https://doi.org/10.1016/j.sigpro.2017.03.013) | 通道/硬件与 CRB/检测风险折中 |
| L54 | Khabbazibasmenj et al., 2014, “Efficient transmit beamspace design for search-free based DOA estimation in MIMO radar.” [DOI](https://doi.org/10.1109/TSP.2014.2299513), [arXiv](https://arxiv.org/abs/1305.4979) | 面向 DOA 后端的 beamspace matrix design |
| L55 | Hassanien & Vorobyov, 2011, “Transmit energy focusing for DOA estimation in MIMO radar with colocated antennas.” [DOI](https://doi.org/10.1109/TSP.2011.2125960) | 面向角区的 beamspace 能量设计 |
| L56 | Malioutov, Cetin & Willsky, 2005, “A sparse signal reconstruction perspective for source localization with sensor arrays.” [DOI](https://doi.org/10.1109/TSP.2005.850882) | 流形字典、相关性和网格背景 |
| L57 | Donoho & Elad, 2003, “Optimally sparse representation in general dictionaries via l1 minimization.” [DOI](https://doi.org/10.1073/pnas.0437847100) | mutual coherence 理论；只间接支撑 W 的相关性项 |
| L58 | Tropp, 2004, “Greed is good: Algorithmic results for sparse approximation.” [DOI](https://doi.org/10.1109/TIT.2004.834793) | coherence/贪心理论；不证明当前三项 score |
| L59 | Gurbuz, Cevher & McClellan, 2012, “Bearing estimation via spatial sparsity using compressive sensing.” [DOI](https://doi.org/10.1109/TAES.2012.6178067) | 稀疏网格与多分辨率搜索 |
| L60 | Han et al., 2015, “Two novel DOA estimation approaches for real-time assistant calibration systems in future vehicle industrial.” [DOI](https://doi.org/10.1109/JSYST.2015.2413691) | 粗网格后在谱峰附近细化，支撑一般 coarse-to-fine 思想 |
| L61 | Zotkin & Duraiswami, 2004, “Accelerated speech source localization via a hierarchical search of steered response power.” [DOI](https://doi.org/10.1109/TSA.2004.832990) | 层次化搜索邻近背景，非雷达 ML |
| L62 | Shan, Wax & Kailath, 1985, “On spatial smoothing for direction-of-arrival estimation of coherent signals.” [DOI](https://doi.org/10.1109/TASSP.1985.1164649) | 相干源 smoothing 经典背景 |
| L63 | Pillai & Kwon, 1989, “Forward/backward spatial smoothing techniques for coherent signal identification.” [DOI](https://doi.org/10.1109/29.17496) | 旧 MUSIC 路线背景 |
| L64 | Lee & Wengrovitz, 1990, “Resolution threshold of beamspace MUSIC for two closely spaced emitters.” [DOI](https://doi.org/10.1109/29.60074) | beamspace 近双源分辨阈值，非 ML |
| L65 | Wang et al., 2022, “基于 FFT 和波束空间 MUSIC 的快速超分辨算法.” [DOI](https://doi.org/10.12677/JISP.2022.111001) | 快速 beamspace MUSIC 背景 |

### 10.4 数值基础和全息凝视雷达工程背景

| ID | 文献与链接 | 与当前工作的关系 |
|---|---|---|
| L66 | Van Trees, 2002, *Optimum Array Processing*. [DOI](https://doi.org/10.1002/0471221104) | 阵列估计理论基础 |
| L67 | Golub & Van Loan, 2013, *Matrix Computations*, 4th ed. [出版社](https://www.press.jhu.edu/books/title/10678/matrix-computations) | 数值线性代数基础，不支撑算法新颖性 |
| L68 | Hansen, 1987, “The truncated SVD as a method for regularization.” [DOI](https://doi.org/10.1007/BF01937276) | 正则化背景；不解释固定 `1e-10` |
| L69 | Balanis, 2016, *Antenna Theory: Analysis and Design*, 4th ed. [出版社](https://www.wiley.com/en-us/Antenna+Theory%3A+Analysis+and+Design%2C+4th+Edition-p-9781118642061) | 阵列/天线基础 |
| L70 | 郭瑞等, 2023, “全息凝视雷达系统技术与发展应用综述.” [DOI](https://doi.org/10.12000/JR22153), [期刊页](https://radars.ac.cn/cn/article/doi/10.12000/JR22153) | 系统定义、工作特点、收发波束控制和参数估计背景 |
| L71 | Guo, Zhang & Chen, 2023, “Design and Implementation of a Holographic Staring Radar for UAVs and Birds Surveillance.” [DOI](https://doi.org/10.1109/RADAR54928.2023.10371201) | 实际全息凝视雷达系统背景 |
| L72 | Oswald & Baker, 2021, *Holographic Staring Radar*. [DOI](https://doi.org/10.1049/SBRA518E) | 全息凝视雷达专著背景 |

### 10.5 C05 的间接文献

| ID | 文献与链接 | 能支持什么 | 不能支持什么 |
|---|---|---|---|
| L73 | Burnham & Anderson, 2004, “Multimodel inference: understanding AIC and BIC in model selection.” [DOI](https://doi.org/10.1177/0049124104268644) | 候选模型相对支持的一般思想 | 不能推导 C05 gap、topK 或窗口阈值 |
| L74 | Wagenmakers & Farrell, 2004, “AIC model selection using Akaike weights.” [DOI](https://doi.org/10.3758/BF03206482) | 指数归一化相对权重 | C05 的 score 不是 AIC，不能直接等同 |
| L75 | Hendrycks & Gimpel, 2017, “A baseline for detecting misclassified and out-of-distribution examples in neural networks.” [arXiv](https://arxiv.org/abs/1610.02136) | softmax 置信/OOD 的一般背景 | 非 DOA、非似然搜索预算 |
| L76 | Lakshminarayanan, Pritzel & Blundell, 2017, “Simple and scalable predictive uncertainty estimation using deep ensembles.” [arXiv](https://arxiv.org/abs/1612.01474) | 预测不确定度的一般背景 | 不支撑单模型粗搜索熵的可靠性 |
| L77 | Kendall & Gal, 2017, “What uncertainties do we need in Bayesian deep learning for computer vision?” [arXiv](https://arxiv.org/abs/1703.04977) | aleatoric/epistemic 区分 | 当前 C05 未建立 Bayesian 不确定度模型 |

这些间接文献不应与直接 beamspace ML 论文放在同一证据强度上。它们最多解释 C05 指标的灵感来源，不能证明 C05 是 DOA 领域的新算法，也不能替代阈值推导与外部分布验证。

## 11. 检索与元数据核验记录

### 11.1 实际使用的来源

| 来源 | 日期 | 用途 | 备注 |
|---|---|---|---|
| Google Scholar | 2026-07-03（项目既有检索） | 关键词检索、同义扩展、关键论文 cited-by 追踪 | 记录在 `literature_support_W_C05_v17.md` |
| Crossref REST API | 2026-07-16 | DOI、题名、作者、年份、期刊/会议和被引计数核验 | 直接 DOI 查询为主；被引计数会变化且可能不完整 |
| OpenAlex REST API | 2026-07-16 | DOI 和主题查询交叉核验 | 本轮若干精确主题查询返回 0，未把该结果解释为“无相关论文” |
| DOI resolver | 2026-07-16 | DOI 可解析性检查 | `10.12000` 的一个请求出现临时连接错误 |
| 《雷达学报》期刊页 | 2026-07-16 | 核验 `JR22153`、`JR25173` 中文元数据与摘要 | Crossref 未收录这两条，采用出版社页元数据 |
| IEEE/ScienceDirect/IET/MDPI/arXiv 链接 | 既有检索及本轮 DOI 解析 | 出版物落地页和开放预印本 | 链接统一优先写为 DOI |

本轮没有使用内置浏览器插件；在线核验通过学术 REST API、DOI 解析和出版社 HTTP 页面完成。

### 11.2 已使用检索式

项目既有 Google Scholar 锚定检索式：

```text
beamspace DOA manifold preservation projection error Frobenius norm
array manifold approximation beamspace transformation Frobenius norm DOA
DOA estimation mutual coherence steering matrix dictionary coherence
condition number steering matrix DOA estimation Gram matrix
beamspace design DOA condition number Gram matrix
coarse-to-fine maximum likelihood DOA estimation top K refinement
multiresolution grid refinement DOA estimation
likelihood gap uncertainty estimation candidate selection model selection
softmax entropy likelihood scores uncertainty posterior entropy
coarse-to-fine search region contraction boundary refinement local search
```

本轮 Crossref/OpenAlex 补充检索式：

```text
"beamspace maximum likelihood" DOA
beamspace maximum likelihood radar angle estimation
beamspace maximum likelihood low angle tracking
maximum likelihood beamspace DOA
"beamspace" "maximum likelihood" direction arrival
beamspace maximum likelihood direction arrival
```

本轮还对第 10 节新增条目的 DOI 逐条调用 Crossref `/works/{doi}`。`JR22153` 和 `JR25173` 改用《雷达学报》文章页的 `citation_*`/`dc.*` 元数据核验。

### 11.3 引用与被引关系核验边界

既有 Scholar 检索保存了以下关键记录的 cited-by 入口标识：Hyberg 2004、Hassanien 2006、Anderson 1993、Malioutov 2005、Gurbuz 2012、Khabbazibasmenj 2014。本轮 Crossref 还返回了部分动态被引计数，例如 Zoltowski & Lee 1991 为 53、Davis & Fante 2001 为 25、Vincent et al. 2014 为 19、Pote & Rao 2023 为 53（均为 2026-07-16 查询时的 Crossref 字段）。

这些计数只能用于确认论文确有后续影响，不能替代逐篇全文引用图。Crossref 的 reference/cited-by 覆盖并不完整，中文期刊也存在缺失，因此第 9.1 节只写“技术谱系”，没有把所有主题关系冒充为已验证的直接引用边。

### 11.4 完整性声明

- 第 10 节是当前项目检索到且经相关性筛选的合集，不是全球数据库的穷尽式系统综述。
- Crossref 的宽泛 bibliographic query 返回大量无关条目；本表排除了只包含“maximum likelihood”但与阵列 DOA/beamspace 无关的结果。
- OpenAlex 的精确短语查询本轮返回异常空结果，因此没有用空结果否定论文存在性。
- DOI 和年份优先采用 Crossref；Crossref 缺失时采用出版社页面。
- 对没有 DOI 的书籍/预印本使用出版社或 arXiv 链接。

## 12. 交给 Pro 模型时必须保留的事实

1. 不要把“真实圆柱阵流形 + beamspace DML”默认视为创新；两者首先是正确建模和经典方法组合。
2. 不要把中心/分离坐标的重参数化自动视为降维；必须区分坐标自由度和实际受限候选数。
3. 当前复杂度收益依赖前端局部窗口、固定 K=2、排序、离散 el-sep 列表、固定网格和 fixed W。
4. W score 的 `1/1/0.05`、topK3、全部窗口/步长和 C05 参数都没有统一推导。
5. C05 的正面 450 样本与负面 120 病态样本必须同时考虑；不能只引用候选比 0.715。
6. C05 的 `U_search` 和 `gap_17` 对 v2 预算分支无实际作用；ILL_CONDITIONED 只通过人工 guard probe。
7. 自适应 W/B 路线已被预注册指标和 bootstrap 否决，不应靠继续调阈值复活。
8. cache 的等价性证据较强，但它是 fixed-grid 软件优化，不是新的统计估计器。
9. 当前没有 FPGA 下板、定点、时序、资源或真实前端闭环证据。
10. 2026 年 CRB 保真 BML、2012 年三维双目标 beamspace、2022/2024 低仰角 BML 和近年的 gridless ML 都是外部新颖性判断必须阅读的直接邻近工作。

## 13. 留给 Pro 模型的审查问题

以下只定义问题，不在本文档给出答案或候选创新点：

1. 在移除 C05、cache 和所有经验阈值后，controlled pair2d 本身还剩下什么可独立陈述、可证明的新命题？
2. 当前所谓“降维”究竟是自由度下降、候选集合裁剪，还是仅仅计算量下降？应使用什么严格定义区分三者？
3. 离散 el-sep 列表和局部窗口是工程先验、模型假设还是算法组成？不同归类会如何影响创新性和适用边界？
4. 与 Kim 2012、Chen 2022/2024、Liu 2026 相比，当前方法的不可替代差异是什么？该差异是否已被实验单独验证？
5. W 选择、candidate search 和 numerical regularization 是否在优化同一个统计目标？如果不是，当前论文是否只是多个局部启发式的串联？
6. 哪些当前主张应删除，哪些只能作为工程实现，哪些仍有资格进入算法章节？
7. 对硕士论文而言，软件、算法和硬件三部分分别已有何种可验收产物；当前缺失项能否在时间和设备条件内真实完成？
8. 应采用哪些直接 baseline、数据划分和否决标准，才能防止再次在同一仿真集上调出“正结果”？
9. 什么反例会否定未来候选方法？能否在设计前先写出失败判据，而不是实验后继续加规则？
10. 当前工程场景中哪些假设来自真实雷达接口，哪些只是 MATLAB 为降低搜索量而人工提供的先验？

## 14. 最终审计意见

当前版本最严重的问题不是某一个参数取值不够好，而是**论文把不同层次的内容包装成了一条算法贡献链**：经典 DML 与物理流形承担正确性，受限候选集合承担复杂度下降，经验 W/topK/C05 承担配置选择，cache 承担软件加速。它们之间没有一个统一目标、约束或误差保证。

其中：

- controlled pair2d 有场景建模价值，但“降维”和“算法新颖性”尚未成立；
- `greedy_combined_B7` 是经验离线配置，且被更严格的 CRB 波束设计文献直接约束；
- fixed topK3 是可用的工程搜索加速；
- C05 存在明显规则堆叠、冗余特征和分布外失败，不应继续作为主创新；
- cache 是证据较完整的软件优化；
- 在线自适应 W/B 已正式失败。

因此，外部模型应从“哪些科学问题仍未被解决”重新开始，而不是在当前 C05/W/topK 规则上继续添加指标。本文档到此停止，不给出新的创新方案。
