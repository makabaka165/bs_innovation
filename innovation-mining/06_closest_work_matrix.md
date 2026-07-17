# 最近工作矩阵与可复现检索记录

> 对应文档：`06_formula_prior_art.md`、`06_algorithm_prior_art.md`  
> 检索日期：2026-07-17  
> 数据库：Crossref、arXiv、OpenAlex、Semantic Scholar；另对 arXiv 全文和出版者文章页做定向核验  
> 范围：针对数学形式、关键变换、更新规则、搜索/剪枝流程、失败机制和算法组合的有界 prior-art 检索

## 1. 标签与证据等级

每个创新主张只使用以下五种结论：

| 标签 | 含义 |
|---|---|
| **已有完全相同方法** | 核心公式或更新机制已有可核验的同形结果；改变符号、阵列名或实现语言不构成差异。 |
| **数学形式相似** | 目标函数、约束、归一化、局部展开或矩阵结构高度相似，但参考矩阵、参数域或成本定义不同。 |
| **算法机制相似** | 搜索、交替更新、稀疏选择、bootstrap 或拒判机制相同，但组合和接口不同。 |
| **只有问题场景不同** | 已有工作的方法链基本一致，主要区别是阵列、低仰角/近双目标、规则波束库等应用对象。 |
| **暂未发现直接工作** | 本轮有界检索未定位到完整同法；不等于证明不存在。 |

证据等级：

| 代码 | 证据 |
|---|---|
| `FT` | 已读取公开全文或 arXiv 源文件并核验关键公式/算法。 |
| `ABS` | 已读取出版者或 arXiv 摘要。 |
| `META` | 仅核验题名、年份、出处和 DOI 等元数据。 |
| `LOCAL` | 仓库已有检索报告的候选与映射，当前轮用 DOI/索引交叉核验。 |

## 2. 创新主张最终矩阵

| Claim | 主张 | 最近工作 | 结论标签 | 置信度与理由 |
|---|---|---|---|---|
| C01 | 圆柱阵条件可分流形和顺序权的 Kronecker 表示 | UCA/cylindrical array 2D DOA；manifold separation | **已有完全相同方法** | 高。属于阵列几何和向量化恒等式。 |
| C02 | 白化集中 DML 投影评分 | Stoica–Sharman 1990；Zoltowski–Lee 1991 | **已有完全相同方法** | 高。经典 DML/BML 数学骨架。 |
| C03 | 俯仰分组→条件方位 DML→完整顺序流形联合修正 | UCA 2D ML 1995；Kim 2012；AP-DML | **暂未发现直接工作** | 中。各阶段已有，未找到完整相同顺序组合；Kim 全文未在本轮开放获取。 |
| C04 | 逐目标、逐维坐标最大化及单调性 | Ziskind–Wax 1988 alternating projection | **已有完全相同方法** | 高。标准 block coordinate ascent。 |
| C05 | 中心–差分和和差酉变换 | 近双源 ML、统计角分辨极限 | **数学形式相似** | 高。标准对称局部化；后续场景化推论才可能有差异。 |
| C06 | \(T=\operatorname{Re}\{J^H\Pi_g^\perp J\}\) | deterministic CRB；array-manifold differential geometry | **已有完全相同方法** | 高。与消去未知幅度后的单目标有效 FIM 成比例。 |
| C07 | \(\sigma_2^2=\tfrac12d^TTd+o(\lVert d\rVert^2)\) | 近源 CRB、流形微分几何、统计 resolution limit | **数学形式相似** | 中。本轮未找到顺序白化二维 beamspace 下完全同式；基础展开和几何量已有。 |
| C08 | 第二奇异值、相关性、Gram 条件数的统一渐近式 | mutual coherence、两列 Gram 谱、局部流形度量 | **数学形式相似** | 中高。三者关系可由两列矩阵代数直接得到，场景化显式式可能可保留。 |
| C09 | 精确白化下只依赖波束子空间、可逆换基不变 | 白化线性压缩与半酉投影 | **已有完全相同方法** | 高。标准线性代数不变性。 |
| C10 | 压缩前后归一化 FIM | Pakrooh et al. 2015 | **已有完全相同方法** | 高，`FT`。其 \(J^{-1/2}\widehat J J^{-H/2}\) 与当前核心归一化相同。 |
| C11 | 全场景最坏广义特征值信息保真 | Chepuri–Leus 2014；E-optimal design | **数学形式相似** | 高，`FT`。全参数域最小特征值约束已有；当前采用相对阵元域参考。 |
| C12 | 最小规则俯仰/方位波束集并满足 CRB/FIM 保真 | Chepuri–Leus 2014；刘旗等 2026 | **数学形式相似** | 高。最小选择加 FIM 约束已有，规则顺序波束乘积成本是差异。 |
| C13 | 用 CRB/FIM 保真设计 beamspace ML | 刘旗等 2026；Pakrooh 2015 | **只有问题场景不同** | 高，`ABS/FT`。已有“阵元/波束 CRB—保真设计—ML”链；当前改为二维近目标和最少实际波束。 |
| C14 | 大池 FIM-greedy add/drop/pair-swap | sensor selection、optimal design、local exchange | **算法机制相似** | 高。无次模证明时只是启发式局部搜索。 |
| C15 | parametric-bootstrap K1/K2 DML LRT | bootstrap source enumeration；非正则 LRT | **算法机制相似** | 中高。领域内已有 bootstrap 阶数判定；本轮未找到完全同一 nested DML LRT。 |
| C16 | `K2_UNRESOLVED` 区分存在性与可分辨性 | GLRT/Rao statistical resolution-limit 文献 | **算法机制相似** | 高。概念已有；状态定义和风险接口可作为工程差异。 |
| C17 | 全部 C03、C07–C16 的完整算法组合 | 下表多篇工作的交集 | **暂未发现直接工作** | 中。受限流和部分付费全文影响；不能作为正式新颖性证明。 |

## 3. 最近工作 × 核心主张

矩阵代码：`D`=直接覆盖核心对象，`M`=数学/机制强相似，`S`=场景强近邻，`B`=背景，`-`=未见实质覆盖。

| Work | 分组条件顺序 DML | 近双目标切向/分辨 | 归一化 FIM | 最小波束/FIM 设计 | 阶数/unresolved | 证据 |
|---|---:|---:|---:|---:|---:|---|
| Stoica–Sharman 1990, DML | M | B | - | - | - | `META/LOCAL` |
| Ziskind–Wax 1988, alternating projection | M | - | - | - | - | `META/LOCAL` |
| Zoltowski–Lee 1991, beamspace ML | M | B | - | B | - | `META/LOCAL` |
| Davis–Fante 2001, ML beamspace processor | M | - | - | B | - | `META/LOCAL` |
| UCA 2D MUSIC/ML 1995 | M | - | - | - | - | `META` |
| Kim et al. 2012, two objects in 3D beamspace | S | M | - | - | - | `META` |
| Vincent et al. 2014, approximate ML for two close sources | M | M | - | - | - | `META` |
| Array-manifold differential geometry 2004 | - | M | - | - | - | `META` |
| Statistical Angular Resolution Limit 2007 | - | D | - | - | M | `META` |
| Chepuri–Leus 2014, sparse sensor selection | - | - | B | D | - | `FT` |
| Pakrooh et al. 2015, Fisher information after compression | - | B | D | M | - | `FT` |
| Pakrooh et al. 2016, threshold effects after compression | - | M | M | B | M | `FT` |
| Anderson 1993, optimal dimension reduction | - | - | B | M | - | `META/LOCAL` |
| Kilic et al. 2022, adaptive measurement matrix design | - | - | B | M | - | `META/LOCAL` |
| 刘旗等 2026, high-accuracy beamspace DOA | M | - | M | D | - | `ABS` |
| Bootstrap source enumeration 2013 | - | - | - | - | D | `META` |
| Self–Liang 1987, nonstandard LRT | - | - | - | - | M | `META` |
| GLRT angular resolution 2018 | - | D | - | - | D | `META` |

## 4. 最需要正面比较的六篇工作

### W1. Kim et al. 2012

**题名：** “Low-angle tracking of two objects in a three-dimensional beamspace domain”  
**标识：** [10.1049/iet-rsn.2010.0163](https://doi.org/10.1049/iet-rsn.2010.0163)  
**为什么最近：** 双目标、低角、三维、beamspace 四个关键词与当前主问题直接重合。  
**当前可主张差异：** 实际顺序接收 DBF、俯仰可辨组、组内多方位、完整顺序流形修正和最小规则波束集。  
**证据限制：** 本轮 IET 页面返回 403，只核验 Crossref 元数据；投稿前必须阅读全文。

### W2. 刘旗等 2026

**题名：** “A High-accuracy Beamspace DOA Estimation Method for Low-elevation Angle Targets”  
**标识：** [10.12000/JR25173](https://doi.org/10.12000/JR25173)  
**已核验方法链：** 分别推导阵元域和波束域 CRB，分析两者相等条件，按近似条件设计 beamformer，再用 ML 精估计。  
**为什么最近：** 直接否定“CRB/FIM 保真 beamspace ML”作为无前例主张。  
**当前可主张差异：** 该文摘要聚焦低仰角/多径和高精度 elevation；当前聚焦局部二维近目标、实际顺序规则波束的最小集合和模型阶数。  
**判定：** 对一般方法链为**只有问题场景不同**；对“最小实际波束集合”仍为**数学形式相似**。

### W3. Pakrooh et al. 2015

**题名：** “Analysis of Fisher Information and the Cramer-Rao Bound for Nonlinear Parameter Estimation after Compressed Sensing”  
**标识：** [10.1109/TSP.2015.2464183](https://doi.org/10.1109/TSP.2015.2464183), [arXiv:1504.01081](https://arxiv.org/abs/1504.01081)  
**全文同形对象：**

\[
W=J^{-1/2}\widehat J J^{-H/2}.
\]

论文进一步给出随机压缩下该归一化 FIM 的矩阵 beta 分布、平均信息损失、CRB 膨胀和按允许 CRB 损失选择压缩比的例子。  
**判定：** 当前归一化 FIM 核心为**已有完全相同方法**；确定性实际波束选择是扩展。

### W4. Chepuri–Leus 2014

**题名：** “Sparsity-Promoting Sensor Selection for Non-linear Measurement Models”  
**标识：** [arXiv:1310.5251](https://arxiv.org/abs/1310.5251)  
**全文同构问题：**

\[
\min\|w\|_0,
\quad
\sum_mw_mF_m(\theta)\succeq\lambda I,
\quad\forall\theta\in\mathcal U.
\]

同时给出 \(\ell_1\)/SDP、稀疏增强、projected subgradient 和 randomized rounding。  
**判定：** “最少选择项 + 全参数域 FIM 最小特征值约束”为已有骨架；当前相对阵元域约束和顺序波束乘积成本属于**数学形式相似**的场景扩展。该文依赖独立观测带来的 FIM 可加性，而当前相邻 DBF 波束通常相关，所以其 SDP 不能未经重新推导直接套用。

### W5. Pakrooh et al. 2016

**题名：** “Threshold Effects in Parameter Estimation from Compressed Data”  
**标识：** [10.1109/TSP.2016.2521617](https://doi.org/10.1109/TSP.2016.2521617), [arXiv:1505.07431](https://arxiv.org/abs/1505.07431)  
**全文直接场景：** 压缩观测、两个近 DOA 源、ML、subspace swap、threshold SNR。论文指出压缩比每翻倍，示例中的 threshold SNR 约损失 3 dB。  
**影响：** 证明 FIM/CRB 保真不能单独保证有限样本可靠；应加入 threshold/swap 风险基线。

### W6. Ziskind–Wax 1988

**题名：** “Maximum likelihood localization of multiple sources by alternating projection”  
**标识：** [10.1109/29.7543](https://doi.org/10.1109/29.7543)  
**直接覆盖：** 逐源交替优化降低多源 ML 联合搜索维度。  
**影响：** 当前逐目标、逐维联合修正及其单调性属于**已有完全相同方法**层级；差异只能放在初始化与顺序流形接口。

## 5. Crossref 检索记录

统一端点：

```text
GET https://api.crossref.org/works
    ?query.bibliographic=<query>
    &rows=8
    &select=DOI,title,author,published,container-title,
            is-referenced-by-count,score,type
```

说明：`total-results` 是 Crossref 对宽松 bibliographic query 的匹配总数，不是“相关论文数”。每式只读取相关性前 8 条，再人工排除非 DOA/阵列结果。

| ID | Query | total-results | 前 8 条中的关键命中 |
|---|---|---:|---|
| X01 | `grouped conditional sequential beamspace deterministic maximum likelihood elevation azimuth DOA` | 19,298 | DML expected-likelihood；sum/difference BML；未见完整分组顺序法 |
| X02 | `two dimensional maximum likelihood DOA uniform cylindrical array elevation azimuth` | 232,517 | 1995 UCA 二维 MUSIC/ML |
| X03 | `beamspace maximum likelihood two targets three dimensional tracking` | 3,378,785 | Kim 2012；Zoltowski–Lee 1991 |
| X04 | `decoupled conditional two-stage elevation azimuth direction of arrival estimation` | 2,892,645 | 多种 two-stage/decoupled 2D DOA；未见当前完整 DML 链 |
| X05 | `differential geometry array manifold detection resolution metric` | 2,836,651 | 2004 array-manifold curve/surface differential geometry chapters |
| X06 | `second singular value steering matrix closely spaced sources direction arrival` | 30,480 | 1993 近源 CRB 近似；2013 近双源 approximate ML；未直接命中当前 \(\sigma_2\) 式 |
| X07 | `statistical angular resolution limit closely spaced point sources Fisher information` | 73,387 | 2007 statistical angular resolution；2013/2014/2018 hypothesis/GLRT 系列 |
| X08 | `approximate maximum likelihood two closely spaced sources` | 2,306,746 | Vincent et al. 2014；2015 approximate UML |
| X09 | `Fisher information beamspace design direction of arrival Cramer Rao` | 5,676,297 | 排名前 8 多为一般 CRB，精确命中较弱 |
| X10 | `minimum sensor selection Fisher information matrix constraint estimation` | 4,802,569 | 一般 FIM sensor placement；Crossref 排序未把 Chepuri 放入前 8 |
| X11 | `sensor selection Cramer Rao bound direction of arrival` | 1,501,080 | 一般 DOA CRB；说明宽查询噪声很高 |
| X12 | `optimal dimension reduction sensor array signal processing` | 3,372,466 | Anderson 1993 及 generalized 1995 |
| X13 | `adaptive measurement matrix design direction of arrival estimation` | 4,892,208 | Kilic et al. 2021/2022 |
| X14 | `parametric bootstrap source enumeration array processing` | 2,154,572 | 2013 bootstrap source enumeration；2024 Monte Carlo enumeration |
| X15 | `bootstrap likelihood ratio number of signals direction of arrival` | 965,253 | 未命中同一 DML LRT；出现一般 mixture bootstrap LRT |

另对 DOI `10.12000/JR25173` 调用 Crossref 单条接口，返回 404；随后使用《雷达学报》出版者页面核验，不把 Crossref 缺失解释为论文不存在。

## 6. arXiv 检索记录

统一端点：

```text
GET https://export.arxiv.org/api/query
    ?search_query=<query>
    &start=0
    &max_results=8
    &sortBy=relevance
    &sortOrder=descending
```

请求按 arXiv 的 1 次/3 秒限制串行执行。

| ID | search_query | totalResults | 结果 |
|---|---|---:|---|
| AR1 | `all:beamspace AND all:"direction of arrival"` | 9 | transmit beamspace design、2D sparse DOA、beamspace ESPRIT 等；无当前完整组合 |
| AR2 | `all:"closely spaced sources" AND all:"singular value"` | 1 | spatial smoothing large-array 分析；无当前显式定理 |
| AR3 | `all:"array manifold" AND all:"differential geometry"` | 0 | 空结果仅说明 arXiv 索引未命中，Crossref 命中了 2004 书章 |
| AR4 | `all:"Fisher information" AND all:"sensor selection"` | 7 | 多篇通用 FIM sensor selection |
| AR5 | `all:"Cramer-Rao" AND all:"beam selection"` | 1 | mmWave beam tracking，非当前 DOA 设计 |
| AR6 | `all:"parametric bootstrap" AND all:"direction of arrival"` | 0 | 不解释为不存在；Crossref 命中 bootstrap source enumeration |

精确题名检索：

- `Sparsity-Promoting Sensor Selection for Non-linear Measurement Models`：命中 [arXiv:1310.5251](https://arxiv.org/abs/1310.5251)，并核验全文。
- `Analysis of Fisher Information and the Cramer-Rao Bound for Nonlinear Parameter Estimation after Compressed Sensing`：命中 [arXiv:1504.01081](https://arxiv.org/abs/1504.01081)，并核验源文件。
- `Threshold Effects in Parameter Estimation from Compressed Data`：命中 [arXiv:1505.07431](https://arxiv.org/abs/1505.07431)，并核验源文件。

## 7. OpenAlex 与 Semantic Scholar 响应

### OpenAlex

端点模板：

```text
GET https://api.openalex.org/works
    ?search=<query>
    &per_page=5
    &select=id,doi,display_name,publication_year,cited_by_count
```

对算法链、近源奇异值/流形几何、FIM 波束选择和 bootstrap 四组共 21 个定向查询均返回 `429 Too Many Requests`。按 skill 规则等待后只重试一次，重试仍为 429，随后停止使用 OpenAlex。环境中没有 `OPENALEX_API_KEY`。

### Semantic Scholar

端点：

```text
GET https://api.semanticscholar.org/graph/v1/paper/search
    ?query=grouped conditional beamspace deterministic maximum likelihood
           DOA elevation azimuth
    &fields=paperId,title,year,abstract,citationCount,externalIds,
            authors,openAccessPdf
    &limit=10
```

返回 `429`。环境中没有 `S2_API_KEY`，故没有把该失败解释为空结果，也没有反复重试共享池。

## 8. 直接全文/出版者核验

| 来源 | 核验内容 | 结果 |
|---|---|---|
| arXiv:1310.5251 全文 | 目标、FIM 最小特征值 LMI、\(\ell_0\) 最少选择、全参数域、求解器 | 确认与当前最小波束/FIM 约束高度同构 |
| arXiv:1504.01081 源文件 | \(J^{-1/2}\widehat J J^{-H/2}\)、压缩后 CRB、DOA 例子 | 确认归一化 FIM 为已有同形对象 |
| arXiv:1505.07431 源文件 | 两近 DOA 源、压缩、ML、subspace swap、threshold SNR | 确认相同失败机制和 FIM 盲区 |
| 《雷达学报》JR25173 页面 | 英文摘要、卷页、DOI、CRB 等价条件、beamformer 设计、ML | 确认刘旗等 2026 为强直接近邻 |
| IEEE/IET/Elsevier DOI 页面 | DOI 可解析性 | 多个页面返回 202/403 或动态反爬，未进行未经授权绕过；相应条目保持 `META` |

## 9. 检索完整性与警告

1. 本轮是 targeted lookup，不是 exhaustive systematic review；每个 Crossref 主题只取相关性前 8 条。
2. API 调用在约 50 次的 skill 建议上限停止；后续只读取已定位条目的公开全文或出版者页面。
3. OpenAlex 和 Semantic Scholar 的 429 造成覆盖缺口。配置免费 key 后应补做 exact-title、cited-by 和 recommendation 检索。
4. Crossref 对数学公式不可检索，题名/摘要不含公式时会漏掉同式工作；因此 C07/C08 的“未找到完全同式”置信度低于 C10–C13。
5. Kim 2012、Vincent 2014、2007 statistical resolution limit 等付费全文尚未逐式检查。正式投稿前必须补齐。
6. 本轮没有检索专利。若“实际顺序 DBF 流程”接近工程系统实现，专利查新尤其必要。
7. 2026-07-17 之后的新论文不在范围内；arXiv 返回的未来/异常日期元数据没有用作主要证据。

## 10. 最终新颖性边界

可以暂时保留为未见直接同法的对象：

> 在实际圆柱阵顺序接收 DBF 接口上，以可辨俯仰组为中间变量执行条件方位 DML，再以完整顺序流形局部联合修正；同时针对近双目标场景，以相对阵元域最坏 FIM 保真约束从实际规则俯仰/方位波束中选择最小乘积通道集，并输出校准后的 unresolved 状态。

但该整体主张由大量已有模块构成。投稿时必须把新颖性压缩到以下三点，而不是扩张到基础公式：

1. **接口差异：** 实际“俯仰→方位”顺序接收 DBF 与俯仰组内多目标。
2. **显式推论：** 针对该白化顺序流形的近双目标 \(\sigma_2\)–correlation–condition-number 统一渐近式。
3. **约束特化：** 相对阵元域、最坏场景、实际规则波束和乘积输出通道成本的联合定义。

其余 DML、投影 FIM、归一化 FIM、FIM 约束最少选择、坐标最大化、bootstrap 和统计可分辨概念均应主动引用 prior art，并通过实验说明当前组合产生了不可由模块简单串联预期的收益。
