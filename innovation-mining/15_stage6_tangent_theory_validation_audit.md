# 阶段 6 固定白化近双目标切向理论验证审计

## 1. 审计结论与冻结边界

- 阶段结论：`PASS`。
- 理论状态：`THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY`。
- 统计范围：`DETERMINISTIC_GEOMETRIC_VALIDATION`；本阶段不存在也不报告统计置信区间。
- 基准提交：`0430f25272690a3ddf378dcf0bab465ca93edb68`（`feat: complete stage 5 grouped conditional DML`）。
- 分支：`main`；MATLAB：R2022b / PCWIN64 / double；活动模型：`phase_factor=1`。
- 阶段 6 控制哈希：`7344172be8a6cba67eb96c4453bcfaf8fdafea7784137d2faf8186ddc675dd53`。
- 阶段 6 实验计划哈希：`d76ec3ca634608f351af919d63f6fe2a8acabe5ee4fffc532f84e8db32a28ad5`。
- 四个物理主配置均为 `NONDEGENERATE_TANGENT`，状态为 `NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND`。单通道诊断仅为 `EXACT_MEASUREMENT_COLLAPSE`，不构成物理高阶分辨理论证据。
- 六阶 exact-null 候选式仅在预注册 synthetic analytic fixture 上通过；由于主物理配置无 exact tangent null，物理六阶扩展保持未验证。
- 本轮未实现阶段 7 的 exact-subset FIM 波束设计，也未修改阶段 4、阶段 5 或 Step11 冻结结果。

## 2. 固定 measurement contract

阶段 6 的唯一物理主流形为

\[
g(\phi,\theta)=T_{\rm seq}W_{\rm seq}^{H}a_{\rm receive}(\phi,\theta),\qquad
C_{\rm seq}=W_{\rm seq}^{H}R_{n,{\rm elem}}W_{\rm seq}.
\]

在每个注册测量配置内，`Wseq`、`Cseq`、有效子空间白化器 `Tseq`、白化秩、波束索引、噪声协方差和全部测量哈希均固定且与候选角无关；`Tseq*Cseq*Tseq'` 在有效白化子空间内等于单位阵至数值容差。接收阵列采用 2,080 阵元 canonical order 和 `factor=1` 流形。候选角只改变 `a_receive`，不得重新构造波束或白化器。

| 配置 | 顺序输出数 / 白化秩 | 噪声 | `fixed_measurement_hash` | 角色 |
|---|---:|---|---|---|
| `SEQ_3X3_WHITE` | 9 / 9 | identity | `3b47fe6660e21a9f7ca62a64f85c82c105c4b2b2b1bcff68b37e40624d5c250d` | 物理主配置 |
| `SEQ_3X3_CORRELATED` | 9 / 9 | Stage-5 Toeplitz correlated | `533ff5cdf79e2aafce8bd6f3744beededa1dfdcf624e75d097c501cebd4c2bb7` | 物理主配置 |
| `SEQ_2X3_WHITE` | 6 / 6 | identity | `0f256519d481919c09cc4cdb043ef0e6ab0502517df3077afaeece1dfd536391` | 物理主配置 |
| `SEQ_3X2_WHITE` | 6 / 6 | identity | `6e2f52a28dd4f8d65789ef177354eb0ea6feac705fb2a3c47f5564e38946ca3c` | 物理主配置 |
| `SINGLE_CHANNEL_DIAGNOSTIC` | 1 / 1 | identity | `cde07fbe2d9f897b1e020818ae1e13cc6591e4dc2830b6ee89f58c84db410325` | 完全测量塌缩诊断，不作正面证据 |

测量合同的逐对象 `Wseq_hash`、`Cseq_hash`、`Tseq_hash` 和 `array_geometry_hash` 保存在 `results/measurement_hash_registry.csv`。注册主配置使用 9 个中心、4 个固定单位方向和 `0.4*2.^(-(0:8))` degree 分离梯，形成 1,296 个物理 secant case；计划不因结果被替换或删点。

## 3. 正式假设、维度与单位

1. `a_receive` 在所验局部邻域至少三阶可微；中心流形 `g0` 非零。
2. 中心–差分参数化为 `xi_minus=c-r*v/2`、`xi_plus=c+r*v/2`，其中 `v` 是二维实单位向量，`r>0`。
3. 非退化三式只适用于 `q_dir=v'*T*v>0` 且尚未进入注册数值底噪的局部尾区；near-null 仍属于 `q_dir>0`，不得改按 exact-null 处理。
4. exact-null 六阶候选式要求 `P_g_perp*g1=0` 且 `v3_eff` 非零；本阶段只在 synthetic fixture 满足并验证这一条件。
5. 所有解析导数、方向向量、分离 `r`、Taylor 展开、`T` 和 `q` 使用 radian；外部配置、中心和端点使用 degree，并在 CSV 中同时保存 radian/degree 分离。
6. `Wseq` 为 `2080 x B`，`Cseq` 为 `B x B`，`Tseq` 为 `rank(Cseq) x B`，`g` 为 `rank(Cseq) x 1`，`Jg` 与 `G2` 均为 `rank(Cseq) x 2`，`T` 为 `2 x 2`。
7. 结论仅关于固定、精确白化、确定性的局部流形几何；不外推至有限样本、随机源幅、未知模型阶数、相干源或 SNR threshold。

定义

\[
P_g^\perp=I-\frac{g_0g_0^H}{g_0^Hg_0},\qquad
T=\operatorname{Re}\{J_g^HP_g^\perp J_g\},\qquad
q_r=r^2v^TTv.
\]

数值实现将 `T` 显式对称化为 `0.5*(T+T.')`，且只允许由 `eps`、矩阵维度和 `norm(T,2)` 决定的机器精度负特征值容差。

## 4. 最终通过的公式

以下三式在 144 个预注册非退化尾区上全部通过，每个尾区固定保留 3 个点：

\[
\sigma_2^2([g_-,g_+])\sim\frac{1}{2}q_r,
\]

\[
1-|\rho|^2\sim\frac{q_r}{\lVert g_0\rVert^2},\qquad
\rho=\frac{g_-^Hg_+}{\lVert g_-\rVert\lVert g_+\rVert},
\]

\[
\kappa(\bar G^H\bar G)\sim\frac{4\lVert g_0\rVert^2}{q_r},\qquad
\bar G=\left[\frac{g_-}{\lVert g_-\rVert},\frac{g_+}{\lVert g_+\rVert}\right].
\]

三条 ratio 的最大尾区绝对误差分别为 `4.01018878082304e-6`、`1.04212196372355e-5` 和 `6.11803083117035e-6`。同时验证精确恒等式

\[
\kappa(\bar G^H\bar G)=\frac{1+|\rho|}{1-|\rho|},
\]

在未数值饱和行上的最大相对误差为 `1.39768507616424e-12`。高条件数饱和行不删除，按预注册的 `64*cond*eps` 界标记。

一、二、三阶方向导数的最大相对误差分别为 `5.88974509523221e-9`、`3.21222107858931e-5` 和 `6.58337759161130e-4`。左酉换基、固定复尺度和 angle-dependent phase gauge 三类不变性最大误差为 `9.43356504023996e-13`。

## 5. 降级或未获物理支持的公式

exact-null 条件下的候选量为

\[
\alpha=\frac{g_0^Hg_1}{g_0^Hg_0},\qquad
v_{3,{\rm eff}}=P_g^\perp\left(\frac{g_3}{24}-\frac{\alpha g_2}{8}\right),
\]

以及

\[
\sigma_2^2\sim\frac{1}{2}r^6\lVert v_{3,{\rm eff}}\rVert^2.
\]

该六阶式在 `g(x,y)=[1;x;y^3]`、中心 `(0,0)`、方向 `v=[0;1]` 的 synthetic fixture 中得到精确阶数 6，最大 ratio 误差 `2.22044604925031e-16`，因此 synthetic 验证状态为通过。但四个主物理配置的最小切向特征值均严格高于注册 null 容差，未出现 exact tangent null；故六阶式不得表述为已在当前物理顺序流形验证。`SINGLE_CHANNEL_DIAGNOSTIC` 的全零切向度量只是 `EXACT_MEASUREMENT_COLLAPSE`，不能用于支持该公式。

未发现公式常数错误，编号 11 无需保留“错误原式/修正式”记录。非退化三式没有降级。

## 6. Prior-art 标签与检索边界

| 项目 | 标签 | 本阶段允许的表述边界 |
|---|---|---|
| 中心–差分参数化 | `Mathematical form similar` | 标准近源对称参数化，不是新方法 |
| 和差 Hadamard/酉变换 | `Existing identical linear-algebra mechanism` | 标准两列酉换基，不是新理论 |
| 投影 Jacobian / 有效 FIM | `Existing identical method` | 消去未知复幅后的经典确定性有效 FIM 几何 |
| 第二奇异值二次渐近式 | `Mathematical form similar` | 只保留固定顺序 DBF 流形上的场景化显式推论 |
| 归一化相关性二次亏损 | `Mathematical form similar` | 与投影切向度量共享二次型的场景化推论 |
| 归一化 Gram 条件数渐近式 | `Mathematical form similar` | 两列 Gram 谱为经典结果；这里只作顺序流形特化 |
| exact-null 三阶有效向量/六阶式 | `No direct identical equation located` | 仅 synthetic fixture 支持，物理流形未验证 |
| 三式在固定白化圆柱阵顺序流形上的统一使用 | `No direct identical complete treatment located` | 不等价于新颖性证明，只能称场景化推论 |

定向检查了 array-manifold differential geometry、statistical angular resolution limit、近双源 approximate ML、FIM/array-manifold geometry 和 beamspace MUSIC resolution threshold 等工作。OpenAlex/Crossref 检索未定位到同时含三式及 exact-null 扩展、且使用当前固定白化顺序圆柱阵流形的直接同式完整工作；Semantic Scholar 五次查询均返回 HTTP 429。该检索是有限的公式定向补检，不包含穷尽专利、付费数据库全文或完整 cited-by 审查，因此不能作为新颖性证明。可复现查询与 DOI 见 `results/stage6_prior_art_mapping.md`。

## 7. 适用与不适用范围

适用范围仅为已注册中心、方向、分离梯和固定测量合同上的确定性局部渐近/几何验证。以下不在本阶段结论内：有限样本可分辨率、概率性 resolution、低 SNR threshold、强相干源、K1/K2 判定、bootstrap 校准、未知源幅/模型阶数风险、off-grid/mismatch 性能、所有方向的普遍可辨性、FIM 波束选择、阶段 7 exact-subset 设计、专利新颖性和硬件实时性能。

物理主配置的 `lambda_min` 范围为 `[2.16519182170008e6, 2.87754587726923e6] per_radian_squared`，`lambda_min/lambda_max` 范围为 `[0.390563758297081, 0.555478502260491]`；注册 `near-null` 行数为 0。因此本阶段没有可报告的物理 near-null 数值区间，不能虚构或后验重选波束制造 near-null/null 证据。

## 8. 验证、冻结证据与复杂度

统一命令：

```matlab
run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/run_step12_4_tangent_asymptotics_validation.m')
```

最终 runner 状态为 `PASS`：14 项要求测试、3,491 行测试证据、Code Analyzer 0 消息、scope violation 0、CSV schema/hash/output 扫描全通过；阶段 5 冻结文件 14 个、hash mismatch 0；Step11 官方冻结清单 351 个文件、hash mismatch 0。注册复杂度为 6,813 次 receive-manifold evaluation、1,296 次 secant SVD、90 次度量特征分解、225 个导数 case，运行时间 `7.7739525 s`，固定模型内存 `38,074,687 bytes`。

## 9. 全部结果与图件 SHA-256 清单

以下路径均相对于仓库根目录；哈希算法为 SHA-256。最终文件系统中共有 15 个 CSV、2 个 Markdown 结果报告和 7 个 PNG，共 24 个文件、`3,154,709 bytes`。

| 路径 | bytes | SHA-256 |
|---|---:|---|
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/figures/coherence_ratio_vs_separation.png` | 50,937 | `288aa84e07af9ad2060dbbcf0ed48533c035f74bc8fc758343822a535a94e36a` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/figures/column_norm_ratio_vs_separation.png` | 44,989 | `dc330612b5c3a0bb0aa524d2cad2582525f83b3f14273567665b0c3a8f3ac4ad` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/figures/normalized_gram_ratio_vs_separation.png` | 45,304 | `371ff644f58d25b8335ed6208ad79165fc22f5abe80564b1eda05bbf6077ab19` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/figures/null_direction_order_fit.png` | 60,884 | `13ee29fefcb26a161f445b1916b995a040de8e3f98f064f2e8b4d82a6ccaf6ef` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/figures/sigma2_ratio_vs_separation.png` | 51,588 | `0844b78096ef1c51f5ec3cbe13250b6d39b80bdac2d977e4eacb3c809c478365` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/figures/tangent_eigenvalue_map.png` | 49,868 | `2e83624ad6e34e1e73f1cd4d79d600683cc6a564ff8aec179b6ecc06cd83b6cf` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/figures/taylor_residual_vs_separation.png` | 67,970 | `a486c5863b67803bec3a8c677109c8c52e5d1ff36ec3536824e89bf9b03e7cc7` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/column_norm_asymmetry.csv` | 593,751 | `4e464b87e8bb27c519936c567ff1a1f7cc9140449a491c7f1913851abb4f4166` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/first_derivative_validation.csv` | 19,018 | `a0bb3d3a745bac8c07fe8552908d70d26800fbb9f1ca3c8c2a3bce8af189819b` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/geometry_invariance_validation.csv` | 6,471 | `3b58dd86a01c25b4d3a9c2bc53ad9984b801e2960c1718af7919ce6d94fe39ed` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/higher_directional_derivative_validation.csv` | 87,239 | `69b66477da3ed141296a91fc687fc39d201a183bfab22f856a23f66bc6407ff5` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/measurement_hash_registry.csv` | 3,071 | `8046a8c02636d55c9ff6fb08772ff99a213ad2abb072c8370d99bb11e88c1db9` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/projected_metric_properties.csv` | 19,664 | `57a5d0d66a9df9bb3f63e31aa4c5f79a3d7e3dc0cb25e14ef892ddb92c1fa6a7` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/secant_tangent_exact_null.csv` | 3,554 | `4ea3eecf984fc14899cca1d1b28004ab6fccfee28cac788e2e4f8773f57c86da` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/secant_tangent_near_null.csv` | 236 | `fdf2f513b60a926c9aa275af279695a23269fd517d53e9d89b107f4590881954` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/secant_tangent_nondegenerate.csv` | 1,377,494 | `e15587e58d3e16f72610c959948bd90b3fd2bac75bb4f36a8b0284f3f20f8fd4` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/secant_tangent_tail_summary.csv` | 77,361 | `3d3bf1303a64207393b3fce40953e66d7a32f9d4bf03121cddf500849e5ce03f` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/stage6_configuration_registry.csv` | 2,317 | `44aa35eb375dbd1d6043911e6914b252113df945584119e60c0cf8061b15bdf0` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/stage6_keypoints.csv` | 14,013 | `7011efb10b6150afb4e130995c334fd8180be482cfde6d360647a36cfb92e09e` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/stage6_prior_art_mapping.md` | 3,474 | `00e1233ebbe35142aed8aee132023f0a2d069e91be6bbfced352554990739380` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/stage6_theory_validation.md` | 4,066 | `3b863631e870d9ea4c1b8cdbf881384ef2071e935f0c0016e72c40b5725a4cf8` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/synthetic_null_validation.csv` | 4,085 | `a07029d83ec80e87df8ffd931d0fdbaa1dce6eaea0a82823c61bc6923b7859bc` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/tangent_eigenvalues.csv` | 19,156 | `31a96fe19bfdceb949795efb51dceafa1a4b88485bbd2477d7985d38be1bc243` |
| `beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/results/two_column_exact_identity.csv` | 548,199 | `b84ef5bae04c4b0c1461005df1a40bdec0bc59d66a5f209d6426de8cc1a7d670` |

## 10. 下一阶段判定

固定 measurement contract、非退化三式、prior-art 边界和 null 诚实分类均通过，因此技术上允许后续单独授权进入阶段 7。本审计不构成阶段 7 授权；阶段 6 到此停止。
