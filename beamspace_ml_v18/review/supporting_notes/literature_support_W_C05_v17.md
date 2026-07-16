# v17 W 选择准则与 C05 自适应搜索准则文献支撑检索报告

检索日期：2026-07-03  
检索方式：按用户要求优先使用 Google Scholar；Chrome 人机验证通过后进行了多轮关键词检索、同义扩展检索和 cited-by 追踪。辅助用 IEEE/ACM/ScienceDirect/Springer/arXiv/出版社页核验 DOI、年份与出处。

## 1. 总体结论

1. **较强直接支撑**
   - 最大归一化相关 \(C_{\mathrm{corr}}\)：与 sparse DOA / dictionary coherence 中的 mutual coherence 形式高度一致。文献中常用
     \(\max_{i\ne j}|a_i^Ha_j|/(\|a_i\|\|a_j\|)\) 描述字典列相关、网格冗余和源可分性。你的式子是把该思想作用到 \(g_W(\theta)=W^Ha(\theta)\) 后的局部 beamspace manifold。
   - coarse-to-fine / multiresolution grid refinement：DOA、声源定位、稀疏 bearing estimation 中已有先粗网格再局部细化、用多分辨率网格减少搜索量的明确文献支撑。
   - beamspace 降维和 beamspace transform 对 DOA 估计性能/偏差/误差的影响：已有 beamspace ML、beamspace MUSIC/ESPRIT、UCA beamspace transform error analysis、optimal dimension reduction 等文献支撑。

2. **思想较强相似，但不是完全同式复现**
   - 投影损失 \(\mathcal L_{\mathrm{proj}}\)：未找到完全相同的
     \(1-\|P_WA_{\mathrm{local}}\|_F^2/\|A_{\mathrm{local}}\|_F^2\) beamspace DOA 公式；但 array interpolation、manifold matching、beamspace transform error、optimal dimension reduction 和 SVD 能量保留均用 Frobenius norm / manifold approximation / transformation error 来评价流形保真度。
   - 条件数风险：beamspace、compressive array 和 sparse DOA 文献会讨论 Gram/effective dictionary/beamspace observation matrix 的条件数、ill-conditioning 或相关性；但你这里的 \(\log_{10}\kappa(W^HW)\) 和 \(\operatorname{cond}(G^HG)\) 是工程化诊断量。
   - 综合 W score：未发现同时把 projection loss、beamspace manifold coherence 和 \(\log_{10}\kappa\) 三项以同一线性加权公式组合的直接文献。更稳妥表述为“受 manifold preservation、coherence/dictionary redundancy 和 numerical conditioning 三类已有思想启发的工程化综合评分”。

3. **主要属于本文工程化设计，需要第6章实验支撑**
   - C05 的 gap_scale、阈值、topK 数值、window scale、熵温度 \(\tau\)、权重 \(0.65/0.30/0.05\) 和 \(0.35/0.25/0.25/0.15\)：未找到文献给出这些数值。应明确写为“根据当前仿真集合、候选网格和安全指标标定”，并用第6章 full-grid match、topK miss、boundary hit、候选数比例、敏感性/消融证明。
   - boundary_margin：没有找到 DOA 文献中同式公式。可由 coarse-to-fine region contraction、hierarchical search、trust-region/local-search safety 间接支撑，定位为防止局部细化窗口截断真实峰值的工程判据。
   - softmax entropy：DOA 中未找到同式；统计模型选择和机器学习不确定度文献可支撑“把候选评分归一化为相对权重后，用熵衡量候选分布是否集中”的一般思想，不能写成 DOA 领域已有固定公式。

## 2. 按论文位置的引用建议

### A. 第4章 W 选择准则，图4-1之后、图4-2之前

建议引用组合：

- 投影损失 / 局部流形保真度：Anderson 1993；Hyberg et al. 2004；Belloni & Koivunen 2006；Belloni et al. 2007；Hassanien et al. 2006；Golub & Van Loan 2013（已有）；Hansen 1987（已有 SVD/正则背景）。
- 流形相关性 / 双目标可分性：Malioutov et al. 2005；Gurbuz et al. 2012；Donoho & Elad 2003；Tropp 2004；Kilic et al. 2022。
- 条件数 / 数值稳定性：Kautz & Zoltowski 1996；Anderson 1993；Ibrahim et al. 2017；Kilic et al. 2022；Golub & Van Loan 2013（已有）。
- 综合评分：Khabbazibasmenj et al. 2014；Hassanien & Vorobyov 2011；Ibrahim et al. 2017；Kilic et al. 2022。用于支撑 beamspace / compressive measurement design 可以按多目标或任务性能约束设计，但不能声称已有相同 score。

建议写法：

> 现有 beamspace 和阵列插值研究表明，降维变换会改变阵列流形并影响 DOA 估计偏差、分辨率和数值稳定性；因此本文将 W 的选择写成局部流形保持、投影后流形低相关和 Gram 条件数之间的折中，而不是单一波束覆盖问题。

### B. 第4章 图4-2 分析段

图4-2A 的波束覆盖和候选波束选择：可引 Hassanien et al. 2006、Khabbazibasmenj et al. 2014、Hassanien & Vorobyov 2011。  
图4-2B 的投影损失/相关性/条件数曲线：可引 Anderson 1993、Hyberg et al. 2004、Belloni & Koivunen 2006、Malioutov et al. 2005、Kautz & Zoltowski 1996。  
图4-2C 的 \(|W^HW|\) 冗余诊断：可引 Donoho & Elad 2003、Tropp 2004、Kilic et al. 2022；用“Gram 相关/字典相干/冗余”语言，不要说这些文献画了同样的图。

### C. 第5章 5.2 粗到细搜索 / topK

建议主引：

- Ziskind & Wax 1988、Stoica & Sharman 1990：支撑 ML DOA 多维搜索计算代价高，需要降低搜索复杂度。
- Gurbuz et al. 2012：支撑 bearing/DOA 的 sparse grid 与 multiresolution refinement。
- Han et al. 2015：明确描述先粗网格估计，再在谱峰附近用细网格。
- Zotkin & Duraiswami 2004：层次化 coarse-to-fine 能量图搜索，虽是声源定位/steered response power，但与局部峰值细化思想相近。
- 近年 XL-MIMO / near-field 文献可作为辅助，因其明确写 coarse grid ML 后 fine refinement；但建议放背景，不作为核心经典文献。

topK 多候选：检索到若干近年工程文献明确使用 top-K peaks refinement，但顶刊直接支撑较弱。建议写为“为降低单峰粗搜索误判风险，本文保留多个粗候选；其必要性由第6章 topK miss / full-grid match 指标验证”，不要写成已有标准 topK=3。

### D. 第5章 5.3 C05 不确定度准则

- score gap / likelihood gap：Burnham & Anderson 2004、Wagenmakers & Farrell 2004 支撑 relative likelihood / Akaike weights / model-selection uncertainty。DOA 直接同式未找到；可作为“候选评分相对差异反映相对支持度”的间接统计支撑。
- softmax entropy：Hendrycks & Gimpel 2017、Lakshminarayanan et al. 2017、Kendall & Gal 2017 支撑 softmax/posterior predictive probabilities 与 entropy/uncertainty 的一般用法。只能作为候选评分不确定度的间接支撑。
- boundary margin：Zotkin & Duraiswami 2004 支撑层次化搜索在能量图中逐步缩小/细化区域；Nocedal & Wright / trust-region 思想可作为优化背景，但没有同式 DOA 公式。建议定位为工程保护判据。
- condition risk：Kautz & Zoltowski 1996、Ibrahim et al. 2017、Kilic et al. 2022、Donoho & Elad 2003 / Tropp 2004 支撑条件数、Gram/dictionary coherence 与稳定性/可分性相关。

### E. 第5章 图5-2 分析段

图5-2 更像本文实验可视化，而不是已有公式复现。可引用 Wagenmakers & Farrell 2004、Burnham & Anderson 2004、Hendrycks & Gimpel 2017 说明 gap/相对权重/熵可以作为候选不确定度刻画；再强调图5-2 的分支边界、候选比例和触发区域是本文 C05 配置在当前样本上的可视化，需要由第6.5节统计验证支撑。

## 3. 逐篇文献映射

| # | 文献 | DOI / 链接 | 支撑内容 | 强度 | 建议位置 | 可写入论文的中文句子 |
|---|---|---|---|---|---|---|
| 1 | S. Anderson, “On optimal dimension reduction for sensor array signal processing,” Signal Processing, 1993. | DOI: https://doi.org/10.1016/0165-1684(93)90150-9 | sensor array 降维/beamspace 变换的任务相关设计；支撑 W 不是任意降维。 | 思想较强相似 | 4.2 开头、图4-2B | “传感器阵列中的降维变换通常需要围绕估计任务设计，而非仅追求维度压缩。” |
| 2 | P. Hyberg, M. Jansson, B. Ottersten, “Array interpolation and bias reduction,” IEEE TSP, 2004. | DOI: https://doi.org/10.1109/TSP.2004.834402 | array manifold matching、Frobenius norm 近似误差、插值误差与 DOA bias。 | 思想较强相似 | 投影损失公式后 | “阵列插值研究通常用流形匹配误差刻画变换后流形与目标流形之间的偏差，该思想与本文的局部投影损失一致。” |
| 3 | A. Hassanien, S. A. Elkader, A. B. Gershman, K. M. Wong, “Convex optimization based beam-space preprocessing with improved robustness against out-of-sector sources,” IEEE TSP, 2006. | DOI: https://doi.org/10.1109/TSP.2006.870564 | beam-space preprocessing 会改变 array manifold；要求 in-sector preservation / out-of-sector robustness。 | 思想较强相似 | 4.2、图4-2A | “已有 beam-space preprocessing 工作强调在关注区域内保持阵列流形响应，同时抑制非关注区域干扰。” |
| 4 | F. Belloni, V. Koivunen, “Beamspace transform for UCA: error analysis and bias reduction,” IEEE TSP, 2006. | DOI: https://doi.org/10.1109/TSP.2006.877664 | UCA beamspace transform 的误差和 bias 分析。 | 直接背景支撑 | 4.2、图4-2B；已有参考文献[18] | “对 UCA 的 beamspace 变换误差分析表明，变换误差会影响后续 DOA 估计偏差。” |
| 5 | F. Belloni, A. Richter, V. Koivunen, “DoA estimation via manifold separation for arbitrary array structures,” IEEE TSP, 2007. | DOI: https://doi.org/10.1109/TSP.2007.896115 | 任意阵列流形建模与 manifold separation；支撑真实阵列流形应被保留。 | 间接背景支撑 | 2.3、4.2；已有参考文献[19] | “任意阵列 DOA 估计依赖对真实阵列流形的有效建模和分离。” |
| 6 | G. M. Kautz, M. D. Zoltowski, “Beamspace DOA estimation featuring multirate eigenvector processing,” IEEE TSP, 1996. | DOI: https://doi.org/10.1109/78.510623 | beamspace DOA 中讨论条件数和 beamspace 设计；支撑 conditioning 作为诊断。 | 思想较强相似 | 条件数公式后、图4-2B | “beamspace DOA 设计中已有工作关注变换后矩阵的条件数，因为其影响后续特征结构估计稳定性。” |
| 7 | D. Malioutov, M. Cetin, A. S. Willsky, “A sparse signal reconstruction perspective for source localization with sensor arrays,” IEEE TSP, 2005. | DOI: https://doi.org/10.1109/TSP.2005.850882 | 阵列流形样本构成过完备字典；SVD 数据降维；稀疏 DOA 的字典列相关/网格冗余背景。 | 直接背景支撑 | 相关性公式、5.2 网格 | “稀疏源定位将阵列流形采样视为过完备字典，因此字典列相关性会影响角度候选可分性。” |
| 8 | D. L. Donoho, M. Elad, “Optimally sparse representation in general dictionaries via l1 minimization,” PNAS, 2003. | DOI: https://doi.org/10.1073/pnas.0437847100 | mutual coherence 的标准定义和稀疏表示条件。 | 直接公式相似 | \(C_{\mathrm{corr}}\) 公式后 | “最大归一化内积是字典 mutual coherence 的标准形式，可用于刻画列向量冗余。” |
| 9 | J. A. Tropp, “Greed is good: Algorithmic results for sparse approximation,” IEEE TIT, 2004. | DOI: https://doi.org/10.1109/TIT.2004.834793 | mutual coherence 与贪心/稀疏恢复稳定性。 | 直接公式相似 | \(C_{\mathrm{corr}}\)、贪心 W 选择 | “以最大列相关度约束候选集合冗余，是稀疏近似和贪心选择分析中的常见做法。” |
| 10 | A. C. Gurbuz, V. Cevher, J. H. McClellan, “Bearing estimation via spatial sparsity using compressive sensing,” IEEE TAES, 2012. | DOI: https://doi.org/10.1109/TAES.2012.6178067 | bearing/DOA sparse grid；支持 multiresolution grid refinement。 | 思想较强相似 | 5.2 粗到细 | “为降低细网格代价，可先在粗网格上定位候选区域，再进行多分辨率细化。” |
| 11 | B. Kilic, A. Gungor, M. Kalfa, O. Arikan, “Adaptive Measurement Matrix Design in Direction of Arrival Estimation,” IEEE TSP, 2022. | DOI: https://doi.org/10.1109/TSP.2022.3209880 | DOA 中测量矩阵/有效字典设计，使用 RIP、mutual coherence 等评价；与 W/measurement design 相近。 | 思想较强相似 | 4.2 综合 W、相关性 | “DOA 的 measurement matrix 设计中，RIP 和 mutual coherence 被用作评价有效字典质量的指标。” |
| 12 | M. Ibrahim et al., “Design and analysis of compressive antenna arrays for direction of arrival estimation,” Signal Processing, 2017. | DOI: https://doi.org/10.1016/j.sigpro.2017.03.013 | 用模拟合并/压缩阵列减少通道，同时按 CRB/检测风险设计；支撑 W 设计可多指标化。 | 思想较强相似 | 4.3 综合评分 | “压缩阵列设计通常在硬件复杂度、估计性能和检测风险之间折中。” |
| 13 | A. Khabbazibasmenj, A. Hassanien, S. A. Vorobyov, M. W. Morency, “Efficient transmit beamspace design for search-free based DOA estimation in MIMO radar,” IEEE TSP, 2014. | DOI: https://doi.org/10.1109/TSP.2014.2299513；arXiv: https://arxiv.org/abs/1305.4979 | transmit beamspace matrix design for DOA；按目标 beampattern、功率约束、结构约束设计。 | 思想较强相似 | 4.3 综合 W | “beamspace 矩阵可按 DOA 后端需求和工程约束进行设计，而不是固定采用规则波束。” |
| 14 | A. Hassanien, S. A. Vorobyov, “Transmit energy focusing for DOA estimation in MIMO radar with colocated antennas,” IEEE TSP, 2011. | DOI: https://doi.org/10.1109/TSP.2011.2125960 | MIMO radar transmit beamspace energy focusing，支撑面向角区间/目标区域的 beamspace 设计。 | 思想较强相似 | 4.2/4.3 | “对关注角区间进行能量聚焦是 MIMO radar beamspace 设计中的常见思想。” |
| 15 | I. Ziskind, M. Wax, “Maximum likelihood localization of multiple sources by alternating projection,” IEEE TASSP, 1988. | DOI: https://doi.org/10.1109/29.7543 | 多源 ML DOA 计算代价高；用 alternating projection 降低多维搜索。 | 直接背景支撑 | 5.2 开头；已有参考文献[13] | “多源 ML DOA 的直接联合搜索代价较高，因此已有工作通过交替投影等方式降低搜索复杂度。” |
| 16 | P. Stoica, K. C. Sharman, “Maximum likelihood methods for direction-of-arrival estimation,” IEEE TASSP, 1990. | DOI: https://doi.org/10.1109/29.57542 | ML DOA 准则与搜索复杂度背景。 | 直接背景支撑 | 3章/5.2；已有参考文献[15] | “本文的搜索加速只改变候选组织方式，不改变 DML/ML 评分准则。” |
| 17 | D. N. Zotkin, R. Duraiswami, “Accelerated speech source localization via a hierarchical search of steered response power,” IEEE TSAP, 2004. | DOI: https://doi.org/10.1109/TSA.2004.832990 | 层次化搜索、coarse-to-fine energy map refinement；非雷达但同属阵列源定位。 | 思想较强相似 | 5.2、boundary margin | “层次化源定位搜索通过先粗后细地收缩候选区域减少搜索代价。” |
| 18 | G. Han, L. Wan, L. Shu, N. Feng, “Two novel DOA estimation approaches for real-time assistant calibration systems in future vehicle industrial,” IEEE Systems Journal, 2015. | DOI: https://doi.org/10.1109/JSYST.2015.2413691 | Scholar 摘要明确：先粗网格估计，再在谱峰周围细网格。 | 思想较强相似 | 5.2 | “已有实时 DOA 应用采用粗网格初估和谱峰附近细网格细化来兼顾复杂度与精度。” |
| 19 | K. P. Burnham, D. R. Anderson, “Multimodel inference: understanding AIC and BIC in model selection,” Sociological Methods & Research, 2004. | DOI: https://doi.org/10.1177/0049124104268644 | relative support、Akaike weights、model-selection uncertainty。 | 间接背景支撑 | 5.3 score gap | “相对似然和模型权重常用于表示候选模型之间的相对支持度。” |
| 20 | E.-J. Wagenmakers, S. Farrell, “AIC model selection using Akaike weights,” Psychonomic Bulletin & Review, 2004. | DOI: https://doi.org/10.3758/BF03206482 | 用指数归一化权重表达候选模型相对支持度，与 softmax over scores 类似。 | 间接背景支撑 | 5.3 softmax 权重 | “将相对评分指数归一化为权重，是统计模型选择中表达候选相对支持度的常见做法。” |
| 21 | D. Hendrycks, K. Gimpel, “A baseline for detecting misclassified and out-of-distribution examples in neural networks,” ICLR, 2017. | arXiv: https://arxiv.org/abs/1610.02136 | softmax probabilities 用于不确定性/OOD 判断；非 DOA。 | 间接背景支撑 | 5.3 entropy | “softmax 概率分布的集中程度常被用作预测置信度或不确定度的近似指标。” |
| 22 | B. Lakshminarayanan, A. Pritzel, C. Blundell, “Simple and scalable predictive uncertainty estimation using deep ensembles,” NeurIPS, 2017. | arXiv: https://arxiv.org/abs/1612.01474 | predictive distribution / uncertainty estimation；非 DOA。 | 间接背景支撑 | 5.3 entropy | “预测分布的分散程度可用于衡量模型输出不确定性。” |
| 23 | A. Kendall, Y. Gal, “What uncertainties do we need in Bayesian deep learning for computer vision?” NeurIPS, 2017. | arXiv: https://arxiv.org/abs/1703.04977 | aleatoric/epistemic uncertainty 和 predictive uncertainty；非 DOA。 | 间接背景支撑 | 5.3 entropy/confidence | “本文仅借用预测不确定度度量思想，不声称 C05 熵公式来自 DOA 标准方法。” |

## 4. 两个核心公式的最接近文献判断

### 4.1 投影损失

你的公式：

\[
\mathcal L_{\mathrm{proj}}(W)=1-\frac{\|P_W\mathcal A_{\mathrm{local}}\|_F^2}{\|\mathcal A_{\mathrm{local}}\|_F^2}.
\]

检索结论：

- 未找到 beamspace DOA 文献中完全同式、同符号、同上下文的公式。
- 形式最接近的是 Frobenius-norm array manifold matching / interpolation error / transform error 文献，如 Hyberg et al. 2004、Belloni & Koivunen 2006、Hassanien et al. 2006。
- 数学思想也接近 PCA/SVD 子空间能量保留：若 \(P_W\) 是投影，则 \(\|P_WA\|_F^2/\|A\|_F^2\) 是被子空间解释的能量比例，\(1-\cdot\) 是投影外能量比例。

建议论文表述：

> 本文的投影损失不是直接照搬已有 beamspace DOA 固定公式，而是将阵列插值和 beamspace transform 文献中常用的流形近似误差思想写成局部流形样本在所选 beamspace 子空间中的能量保留率。

### 4.2 最大归一化相关

你的公式：

\[
C_{\mathrm{corr}}(W)=
\max_{\theta_1,\theta_2}
\frac{|g_W^H(\theta_1)g_W(\theta_2)|}
{\|g_W(\theta_1)\|_2\|g_W(\theta_2)\|_2}.
\]

检索结论：

- 该形式与 mutual coherence / dictionary coherence 的标准定义基本相同，只是将字典列换成了 beamspace steering vectors \(g_W(\theta)\)。
- DOA 领域中，Malioutov et al. 2005 将阵列流形采样写成过完备字典；Kilic et al. 2022 明确在 DOA measurement matrix 设计中使用 mutual coherence 评价 effective dictionary。
- 因此可判定为“直接公式相似”，但建议写成“将 mutual coherence 思想应用于本文局部 beamspace manifold”，不要声称已有文献使用了你完全相同的局部双目标 \(\mathcal P_{\mathrm{local}}\) 定义。

## 5. C05 参数和导师追问的回答方式

不建议给以下具体数值找文献来源：coarse/fine el-sep list、az/el step、half-width、topK=1/5/7、gap_scale、gap thresholds、boundary_margin < 1.5、cond_threshold=0.85、uncertainty weights。它们应表述为：

1. 准则设计思想来自文献：coarse-to-fine/multiresolution search、relative likelihood、entropy uncertainty、dictionary coherence/conditioning。
2. 具体数值来自本文任务：当前局部窗口、beamspace ML 后端、grid step、双目标场景集、MATLAB 实验复杂度与安全指标。
3. 参数是否合理由第6章验证：full-grid match、topK miss、boundary hit、candidate ratio、分支分布和代表性案例。
4. 若导师追问“为什么这样设”，可回答：

> 参数不是从单篇文献直接取值，而是在已有粗到细搜索和候选不确定度思想的基础上，根据本文 controlled pair2d beamspace ML 的局部窗口、网格分辨率和安全指标标定。我们先选择能覆盖粗网格量化误差和主要双目标分离范围的 coarse/fine 网格，再用 full fine reference 检查 fixed topK 和 C05 是否出现 topK miss 或 boundary hit；gap、entropy、boundary 和 condition 的阈值则按候选数压缩与 full-grid 一致性之间的折中确定。因此文献支撑的是准则类别和设计逻辑，具体阈值由第6章实验验证。

## 6. 可直接放入第4章或第5章的保守表述

> 本文的 \(W\) 选择和 C05 自适应搜索策略并非直接复现已有固定公式，而是在 ML DOA、beamspace dimension reduction、array-manifold approximation、dictionary coherence、coarse-to-fine search 和 likelihood-based uncertainty analysis 等已有思想基础上，结合本文局部双目标 beamspace ML 后端设计的工程化判据。具体而言，投影保真度用于描述局部阵列流形在所选 beamspace 子空间中的能量保留程度，流形相关性借鉴 mutual coherence / dictionary coherence 思想刻画投影后候选目标的可分性，条件数用于诊断 beamspace steering 或 Gram 矩阵的数值稳定性。C05 中的 score gap、候选熵、边界裕度和条件数风险分别用于描述粗搜索似然地形的集中程度、多峰歧义、局部细化窗口安全性和投影估计稳定性。上述指标的组合形式、阈值和权重为面向本文场景的工程化标定，并通过第6章的候选数压缩、full-grid match、topK miss、boundary hit 和代表性案例验证其有效性与适用边界。

## 7. 检索记录摘要

Google Scholar 锚定查询包括：

- `beamspace DOA manifold preservation projection error Frobenius norm`
- `array manifold approximation beamspace transformation Frobenius norm DOA`
- `DOA estimation mutual coherence steering matrix dictionary coherence`
- `condition number steering matrix DOA estimation Gram matrix`
- `beamspace design DOA condition number Gram matrix`
- `coarse-to-fine maximum likelihood DOA estimation top K refinement`
- `multiresolution grid refinement DOA estimation`
- `likelihood gap uncertainty estimation candidate selection model selection`
- `softmax entropy likelihood scores uncertainty posterior entropy`
- `coarse-to-fine search region contraction boundary refinement local search`

Citation chasing 已追踪的 Google Scholar data-cid：

- Hyberg et al. 2004: `XdVXsU3pQm4J`
- Hassanien et al. 2006: `sdYju8vHfmEJ`
- Anderson 1993: `ezybabBtJnIJ`
- Malioutov et al. 2005: `-0g5FJoDDjcJ`
- Gurbuz et al. 2012: `KFyDeHrhPfUJ`
- Khabbazibasmenj et al. 2014: `yFSY2Q_YB_EJ`

