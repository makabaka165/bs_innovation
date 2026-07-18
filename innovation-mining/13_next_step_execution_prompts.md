# 下一步分阶段执行提示词（prior-art 审查修订版）

> 建议保存路径：`innovation-mining/13_next_step_execution_prompts.md`  
> 默认仓库：`makabaka165/bs_innovation`  
> 文档日期：2026-07-17  
> 使用方式：每次只复制一个阶段的提示词给 AI；当前阶段通过审查后，再执行下一阶段。  
> 默认行为：允许读取 GitHub/联网检索，但**未经当前会话明确授权，不提交、不推送、不创建 PR，不改动其他仓库**。
>
> 强制依赖：
>
> - `innovation-mining/06_formula_prior_art.md`
> - `innovation-mining/06_algorithm_prior_art.md`
> - `innovation-mining/06_closest_work_matrix.md`
> - `innovation-mining/10_current_paper_innovation_audit.md`
> - `innovation-mining/11_sequential_beamspace_ml_innovations_theory.md`
> - `innovation-mining/12_experiment_system_code_structure_roadmap.md`
> - `innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md`
>
> 本文已经把 prior-art 审查要求写入每个关键阶段：俯仰分组秩条件、固定白化定理假设、零方向高阶退化、相关波束非可加 FIM、完整复杂度、threshold-risk、false-resolved 和等预算外部基线。

---

# 0. 所有阶段共同使用的总约束

把下面文本附在每一个阶段提示词前。

```text
默认 GitHub 仓库为 makabaka165/bs_innovation。只分析和修改该仓库。

开始工作前必须完整阅读：
1. innovation-mining/06_formula_prior_art.md
2. innovation-mining/06_algorithm_prior_art.md
3. innovation-mining/06_closest_work_matrix.md
4. innovation-mining/10_current_paper_innovation_audit.md
5. innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
6. innovation-mining/12_experiment_system_code_structure_roadmap.md
7. innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md
8. beamspace_ml_v18/review/technical_audit/code_manifest.md
9. beamspace_ml_v18/paper/full_manuscript_v0.18_引用文献支撑修订稿.md
10. beamspace_ml_v18/source/stepwise_signal_model/README.md

创新性永久约束：
- 不把接收圆柱阵流形、DML、SVD/QR 投影、白化、AP/坐标上升、投影 Jacobian FIM、归一化 FIM、FIM 约束最少选择、bootstrap 或 unresolved 单独声明为新方法。
- 候选贡献 1 是“实际顺序 DBF 接口 + 可辨俯仰组 + 组内多方位 DML + 完整顺序流形修正”的完整组合。
- 候选贡献 2 是经典投影 FIM/流形几何在固定白化顺序二维流形上的显式近双目标推论，包括零方向边界。
- FIM 波束设计定位为已有框架在相关噪声、实际规则顺序波束和结构化成本下的系统特化。
- “暂未发现直接工作”不是新颖性的证明；必须主动引用并公平比较 06 文档中的最近工作。

代码与实验永久约束：
- 不删除、不覆盖 Step11、C05、cache 和失败自适应 W/B 的旧源码、旧结果及审计。
- 新实现统一放入 step_12_*；公共函数通过独立测试后才可提升到 core/。
- 新活跃模型只使用接收单程空间相位 factor=1。
- 旧 factor=2 结果只作 legacy，不能混入新证据。
- 不恢复或调整 C05，不增加 EASY/HARD、score-gap、人工 condition threshold、额外 topK 或场景特殊分支。
- 不恢复 FAILED_likelihood_discriminative_adaptive_wb 中已否决的在线自适应 W/B。
- DML 主路径使用 QR/SVD 正交投影，不使用固定 1e-10 岭和 2×2 Gram 行列式除法。
- 候选搜索期间物理观测、波束索引、噪声协方差和白化坐标固定。
- 俯仰分组必须检查 rank(Ge)、rank(Ce) 和局部唯一性；L=1 的环向列不等同于独立时间快拍。
- FIM 波束选择对每个子集重新构造 CI、白化器和 FIM，不假设逐束 FIM 可加。
- FIM 通过后必须进行 threshold/mismatch 独立 holdout，不构造新的经验综合评分。
- 复杂度必须覆盖顺序 DBF、分组、条件方位、联合修正、多初值、K1/K2、bootstrap 校准和离线 FIM 设计。
- 角度对外用 degree，解析导数和 FIM 内部用 radian，变量名包含 _deg 或 _rad。
- design/validation/holdout 不交叉；holdout 禁止调参。
- 失败时记录失败，不增加规则掩盖。
- 未经用户在当前会话明确授权，不提交、不推送、不创建 PR。
- 当前阶段结束后停止，不自动进入下一阶段。

每次最终输出必须包含：
A. 本阶段结论；
B. 阅读过的关键文件和 prior-art 条目；
C. 新增/修改文件清单；
D. 公式到代码映射；
E. 数据维度、角度/相位/白化约定；
F. 实际执行测试和命令；
G. 结果文件、关键数值及置信区间；
H. score-call/SVD/多初值/runtime/内存等复杂度；
I. 未通过项、风险和停止条件；
J. 是否可以进入下一阶段。
```

# 阶段 0：仓库重新盘点和旧证据冻结

## 目标

只做盘点、映射和冻结，不修改算法。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

本阶段只执行仓库重新盘点和旧证据冻结，不修改算法，不重跑大规模实验。

任务：

1. 确认仓库默认分支、当前 commit、目录结构和 MATLAB 代码根目录。
2. 逐项定位：
   - sim_cfg.m
   - arr_cyl.m
   - bf_elevation.m
   - bf_azimuth.m
   - bf_joint_2d.m
   - build_cyl_steering_vec.m
   - apply_beamspace_whitening.m
   - beamspace_dml_score.m
   - controlled pair2d、full4D、fixed topK3、C05、cache、Step11.7 的入口和结果目录
   - EI_paper/code/run_cyl_beamspace_ml_demo.m
3. 全仓搜索以下字符串，并输出文件、行号和语义：
   - spatialPhaseFactor
   - PhaseFactor
   - phase_factor
   - 双程
   - 前端
   - 后端
   - topK
   - C05
   - 1e-10
   - cond(W
   - G' * G
4. 生成一个“旧证据冻结清单”，记录：
   - Step11 每个阶段的配置、入口、结果目录、关键 CSV；
   - phase factor=2 的所有旧结果；
   - FAILED_likelihood_discriminative_adaptive_wb 的状态；
   - 当前论文正文、代码和结果之间的已知不一致。
5. 不修改旧结果文件。对旧结果计算或复用已有 SHA-256 清单，确认没有覆盖。
6. 在 innovation-mining 下新增：
   innovation-mining/14_step12_preimplementation_inventory.md
7. 文档必须包含：
   - 当前代码调用图；
   - 当前数据维度；
   - 当前阵元顺序；
   - 哪些函数是真正二维联合波束，哪些是分开的演示；
   - 为什么当前 bf_elevation/bf_azimuth/bf_joint_2d 还不等于“先俯仰 DBF、再方位 DBF”的真实级联数据流；
   - 新 Step12 将复用和不会复用的文件。
8. 若仓库实际路径与 11/12 文档的建议路径不一致，在 inventory 中给出真实路径映射，不要凭空创建多个重复根目录。

验收：
- 不应出现算法源码改动；
- 不应出现旧 CSV/图片修改；
- inventory 必须足以让后续阶段无歧义地定位文件；
- 完成后停止。
```

---

# 阶段 1：修正相位模型、系统术语和论文范围

## 目标

把新活跃路线统一为接收单程相位 factor=1，并修正文档表述；不实现创新点算法。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.0：接收模型和术语纠正。不要实现分组 DML、FIM 波束设计或模型阶数。

先阅读：
- innovation-mining/14_step12_preimplementation_inventory.md
- innovation-mining/11_sequential_beamspace_ml_innovations_theory.md 的第 1–3 节
- innovation-mining/12_experiment_system_code_structure_roadmap.md 的 Step12.0

代码任务：

1. 新建：
   beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_0_receive_model_correction/
   目录包含 README.md、common/、tests/、results/、run_step12_0_receive_model_correction.m。

2. 新建单程接收导向函数：
   common/build_receive_cyl_steering_vec.m
   签名：
   function a = build_receive_cyl_steering_vec(x, y, z, az_deg, el_deg, lambda)

   唯一公式：
   ux = cosd(el_deg)*cosd(az_deg)
   uy = cosd(el_deg)*sind(az_deg)
   uz = sind(el_deg)
   phase = x(:)*ux + y(:)*uy + z(:)*uz
   a = exp(1j*2*pi/lambda*phase)

   不接受 PhaseFactor 参数，不包含 factor=2 分支。

3. 新建解析导数函数：
   common/build_receive_cyl_steering_with_derivatives.m
   签名：
   function [a, da_daz_rad, da_del_rad, meta] = ...
       build_receive_cyl_steering_with_derivatives(x,y,z,az_deg,el_deg,lambda)

   导数必须相对于弧度。按 11 文档公式实现。

4. 将 active 配置中的：
   cfg.beam.spatialPhaseFactor = 2
   修改为 1，并把注释改成：
   “接收阵列单程空间相位；目标距离双程公共相位吸收到复包络中。”

5. 全仓检查所有新活跃调用链：
   - 不能继续显式传 2；
   - 新 Step12 只能调用单程函数；
   - 旧 Step11 不删除，但标记 legacy；
   - 不自动覆盖旧 Step11 结果。

6. 在旧代码中若注释写“当前回波模型按双程相位，因此权值也用双程”，对 active 路径修改为单程接收模型。
   若直接修改会破坏旧复现，应保留旧函数，创建 Step12 新函数，并在 README 明确 legacy/new 的调用边界。

7. 运行并记录：
   - 单目标方向图；
   - factor 1 与 factor 2 的 3 dB 波束宽度对比；
   - 解析导数与中心有限差分对比；
   - 至少 9 个 az/el 中心；
   - 相对导数误差。

8. 结果文件：
   results/phase_model_keypoints.csv
   results/old_vs_new_beamwidth.csv
   results/derivative_validation.csv
   results/receive_model_validation.md

文档任务：

9. 不直接篡改旧 v18 结果说明。创建新的论文修订源稿：
   beamspace_ml_v18/paper/full_manuscript_v0.19_sequential_dbf_revision.md
   初始可从 v0.18 复制，但必须在标题或版本说明中标记：
   - phase factor=1；
   - v18 factor=2 结果失效，待重跑；
   - 新路线尚未完成实验。

10. 全文替换或重写模糊的“前端/后端”表述：
    - “前端”仅指射频/AD/阵元数字接收链路时才能使用；
    - 算法位置写成“常规顺序 DBF 与检测之后的局部未分辨目标簇超分辨测角”；
    - 局部搜索域来自常规角分辨单元或常规测角置信域；
    - 不再声称人工窗口来自硬件前端。

11. 新增：
    beamspace_ml_v18/review/supporting_notes/sequential_revision_scope.md
    明确系统层级、phase factor=1、旧结果边界、K1/K2 主范围。

测试和验收：

- 新导向函数与解析公式逐元素一致；
- 解析导数相对误差建议 <=1e-6；
- 所有新结果 metadata 写 phase_factor=1；
- 旧结果没有被覆盖；
- v0.19 文本不得引用旧 factor=2 数值作为新结论；
- 不实现任何新创新点；
- 完成后停止。
```

---

# 阶段 2：实现真实的“先俯仰、后方位”顺序 DBF

## 目标

建立新算法必须依赖的数据流；不实现 DML 创新。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.1：真实顺序 DBF 模型和代码。当前阶段只验证波束形成与数学等价，不做多目标 DML。

必须阅读：
- 11_sequential_beamspace_ml_innovations_theory.md 第 3、4、6.1 节
- 12_experiment_system_code_structure_roadmap.md 第 2、3、Step12.1
- Step12.0 的 README 和结果

先审计现有：
- bf_elevation.m
- bf_azimuth.m
- bf_joint_2d.m
说明它们为何不是所需的严格级联，再新建 Step12 实现。不要直接删除旧函数。

目录：
beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_1_sequential_dbf_model/

必须实现：

1. common/reshape_cyl_vector_to_matrix.m
   function [Ymat, info] = reshape_cyl_vector_to_matrix(yvec, array_meta)
   输出固定为 [N_el,N_az,...]。
   阵元顺序只能从 arr_cyl/array_meta 推导，不能猜测。

2. common/reshape_cyl_matrix_to_vector.m
   实现严格逆映射。

3. common/form_elevation_dbf_cube.m
   function [Zel, V, info] = form_elevation_dbf_cube(Yelem, el_beam_deg, cfg)
   输入：
   Yelem [N_el,N_az,N_range,N_snapshot] 或经统一包装后的等价形状。
   输出：
   Zel [B_el,N_az,N_range,N_snapshot]
   要求：
   - 对每个方位列只沿 N_el 维做俯仰 DBF；
   - V [N_el,B_el]；
   - 不得在此阶段对 N_az 维相干求和。

4. common/form_azimuth_dbf_cube.m
   function [Zseq, Uset, info] = form_azimuth_dbf_cube( ...
       Zel, az_beam_deg, el_condition_deg, cfg)
   输出：
   Zseq [B_el,B_az,N_range,N_snapshot]
   要求：
   - 对每个俯仰通道在 N_az 维做方位 DBF；
   - 方位导向包含 cos(el_condition_deg)；
   - 保存每个俯仰通道的实际 U。

5. common/build_sequential_beam_matrix.m
   构造等效 w_{b,c}=u_{c|b}⊗v_b。
   Wseq 列顺序必须与 Zseq(:) 顺序一致，并在 meta 中记录。

6. common/build_sequential_beamspace_manifold.m
   使用 factor=1 的完整圆柱阵流形计算 Wseq' * a(az,el)。
   不用 separable 近似替代完整结果。

测试：

A. test_array_order_roundtrip.m
   随机复向量 roundtrip 相对误差 <1e-14。

B. test_sequential_vs_kron_weight.m
   随机单目标、双目标和随机复数据：
   逐级 DBF 输出与 Wseq' * y 的相对误差 <1e-12。

C. test_factorized_vs_full_manifold.m
   a_phi⊗a_z 与完整几何流形在统一阵元顺序下误差 <1e-12。

D. test_conditional_azimuth_dependence.m
   固定 az，改变 el，确认方位流形按 cos(el) 改变；不能错误使用 a_phi(az) 独立模型。

E. test_noise_covariance_after_dbf.m
   阵元白噪声 Monte Carlo：
   样本协方差与 Wseq'Wseq 的相对误差随样本数收敛。

结果：
results/sequential_equivalence_keypoints.csv
results/array_order_validation.csv
results/noise_covariance_validation.csv
results/conditional_azimuth_validation.csv
results/sequential_model_report.md

文档：
- 在 v0.19 第 2/3 章写入矩阵模型和顺序 DBF 模型；
- 只写已经通过的等价关系；
- 不声称方位/俯仰完全解耦；
- 明确“俯仰条件下的可分解结构”。

验收：
所有等价性测试通过后才允许进入稳定 DML。完成后停止。



同时还有要补充的内容：
新增输入模型约束：

现有 core/echo/echo_elem.m 使用 tau=2*Rm/c 和
exp(-j*4*pi*Rm/lambda)，其逐阵元空间相位实质为 factor=2。
该函数及 echo_elem_cube.m 属于 legacy 双程回波生成路径，
不得直接作为 Step12.1 的 active 输入。

在 step_12_1_sequential_dbf_model/common/ 新建
generate_receive_only_element_snapshots.m。

首版采用窄带接收模型：

    Yelem = A_receive(Theta) * S + N

A_receive 的每一列必须直接调用
build_receive_cyl_steering_vec，禁止复制另一套公式。

新增测试：

1. test_receive_snapshot_matches_factor1_manifold.m
   - 无噪声单目标快拍投影到 factor=1 流形正交补后的
     相对残差 < 1e-12；
   - factor=2 流形不能得到同样的零残差。

2. test_step12_has_no_legacy_echo_dependency.m
   - Step12.1 active path 不得调用 echo_elem、echo_elem_cube；
   - 不得出现 4*pi/lambda 或 PhaseFactor=2。

阶段 2 的顺序等价测试必须至少覆盖：
- 随机复阵元数据；
- factor=1 单目标物理快拍；
- factor=1 双目标物理快拍；
- 阵元白噪声。

只有物理快拍、逐级 DBF 和 Wseq' * y 三者同时一致，
才允许阶段 2 通过。
```

---

# 阶段 3：替换固定岭和 Gram 行列式，建立稳定 DML

## 目标

建立所有后续创新共用的可信评分器。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.2：稳定白化和 SVD/QR DML。不要实现俯仰分组、FIM 波束选择或 bootstrap。

必须阅读：
- 11 文档第 8、9、11 节
- 12 文档 Step12.2
- 当前 apply_beamspace_whitening.m
- 当前 beamspace_dml_score.m
- 当前所有 2×2 fast score 代码

目录：
beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_2_stable_dml_backend/

实现：

1. common/stable_numeric_rank.m
   输入奇异值、矩阵维度和可选乘数；
   默认阈值：
   tau = max(m,n)*eps(class(sigma1))*sigma1
   返回 rank 和 threshold。

2. common/build_psd_whitener.m
   function [T, info] = build_psd_whitener(C, opts)
   - Hermitian 对称化；
   - eig/SVD；
   - 相对阈值；
   - 伪逆平方根；
   - 返回 rank/eigenvalues/threshold/whitening_error/status。

3. common/beamspace_dml_score_svd.m
   function [score, rss, debug] = beamspace_dml_score_svd(Z,G,opts)
   - economy SVD；
   - U_r；
   - score=norm(U_r'*Z,'fro')^2；
   - rss=norm(Z,'fro')^2-score；
   - 不构造 G(G'G)^-1G'；
   - 不加固定 ridge。

4. common/concentrated_dml_rss.m
   为后续 K1/K2 统一返回：
   score, rss, sigma2_hat, loglik_concentrated, rank。

5. 可选：
   common/beamspace_dml_score_qr.m
   作为 QR 对照，不作为必须项。

测试矩阵：

- 随机满秩 G；
- G 第二列逐渐接近第一列；
- 完全重复列；
- G 乘 1e-8、1、1e8；
- B<K；
- 非正交 W；
- rank-deficient Cb；
- 一般 PSD 噪声。

对照：
- pinv 投影；
- 旧 ridge；
- 旧 2×2 行列式。

必须生成：
results/stable_dml_trial.csv
results/stable_dml_keypoints.csv
results/rank_deficiency_cases.csv
results/old_vs_new_score_comparison.csv
results/stable_dml_report.md

验收：
- 良态下与 pinv 相对误差 <1e-10；
- 尺度改变不改变投影评分；
- 近秩亏不产生 NaN/Inf；
- 重复列有效秩下降；
- rss 非负，仅允许机器精度量级负值并截断为 0，同时记录；
- 主路径不含固定 1e-10；
- 完成后停止。


额外的附加约束：
对白化器采用有效子空间降维形式：

    C = Ur*Lambda_r*Ur'
    T = Lambda_r^(-1/2)*Ur'

因此 T 的维度为 rank(C) × B，并要求：

    T*C*T' ≈ I_rank(C)

不要使用奇异 B×B 白化坐标并把投影矩阵误报为单位协方差。

concentrated DML 使用有效白化维数 rC：

    sigma2_hat = RSS / (rC*L)

这是最大似然估计，不进行无偏自由度修正。

当 rank(Gw)<requested_K 时允许计算其列空间评分，
但必须返回 rank-deficient 状态，不能把该候选视为正常可辨识 K 目标模型。

RSS 只允许对机器精度量级的负值做 0 截断；
明显负值必须使测试失败。
```

---

# 阶段 4：核心创新点 1A——俯仰目标组 DML 与可辨识性

> **历史初始提示词，已由提交 `89d8c056` 的阶段 4 修订合同替代。**
> 下方文本仅保留用于审计，不再作为 active 执行要求；其中旧的统一失败状态和
> 未校准置信字段不得被后续阶段恢复。

## 目标

在 Q 已知的 oracle 条件下验证俯仰分组估计和组数据恢复。当前阶段不自动选择 Q，不进入 FIM。

## 历史初始提示词（不得直接执行）

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.3 子阶段 A–C：俯仰目标组 DML、可辨识性诊断和组环向数据恢复。当前假设俯仰组数 Q 已知，用于隔离模型和估计器正确性。

必读：
- innovation-mining/11_sequential_beamspace_ml_innovations_theory.md 第 5.1–5.5 节
- innovation-mining/12_experiment_system_code_structure_roadmap.md 的 Step12.3
- innovation-mining/06_formula_prior_art.md 的 F01/F02
- innovation-mining/06_algorithm_prior_art.md 的 A01/A02
- Step12.1 顺序 DBF 和 Step12.2 稳定 DML 结果

目录：
beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_3_grouped_conditional_dml/

实现：

1. common/stack_elevation_mmv_data.m
   function [Zemmv,mapping,info] = stack_elevation_mmv_data(elOut,opts)
   将 Zel [B_e,Nphi,L] 变为 Zemmv [B_e,Nphi*L]，保存列映射。

2. common/build_elevation_group_manifold.m
   function [Ge,dGe,info] = build_elevation_group_manifold(...)
   使用固定俯仰波束和固定白化器。

3. common/diagnose_elevation_group_identifiability.m
   function diag = diagnose_elevation_group_identifiability(Ge,Ce_or_Z,opts)
   必须输出：
   - singular values/rank of Ge；
   - singular values/rank of Ce（真值实验）或 Ce_hat；
   - B_e 与 Q；
   - whitening effective rank；
   - local manifold-subspace alias test；
   - status。

4. common/estimate_elevation_groups_dml.m
   function [est,debug] = estimate_elevation_groups_dml(...)
   - Q=1 一维；
   - Q=2 小局部 full reference；
   - SVD DML；
   - 可选 AP/PR-DML baseline；
   - 不用 el_sep 列表、topK、gap 或 C05。

5. common/recover_group_azimuth_data.m
   function [Xphi,Ce_hat,debug] = recover_group_azimuth_data(...)
   输出每组 [Nphi,L] 数据、子空间误差、Frobenius 误差和组间串扰。

必须构造的场景：
- K1/Q1；
- K2/Q2，不同俯仰；
- K2/Q1，同俯仰不同方位；
- 极近俯仰；
- L=1 与 L>1；
- rank(Ce)=Q 的可辨样本；
- rank(Ce)<Q 的结构性反例；
- 弱次目标、相干、环向孔径缩小、相关噪声。

L=1 约束：
- 文档必须说明 Nphi 列是 MMV 系数列，不是 Nphi 个独立时间快拍；
- 不允许因为 Nphi>Q 就自动宣称可辨识；
- rank(Ce)<Q 时返回 GROUP_UNIDENTIFIABLE；
- 数据只支持较少组时允许 GROUP_MERGED，但不能用人工间隔阈值决定。

Baselines：
- 垂直阵元域 DML；
- 俯仰波束峰值；
- local full elevation DML；
- AP/PR-DML（可准确复现时）。

输出：
results/elevation_group_trial.csv
results/elevation_group_identifiability.csv
results/group_recovery_error.csv
results/elevation_group_keypoints.csv
results/elevation_group_report.md

验收：
- 无噪声模型匹配且 rank 条件成立时真值残差接近 0；
- rank(Ce)<Q 反例不能被错误输出为 Q 个高置信组；
- Q1 同俯仰场景恢复数据等于组内多目标叠加；
- 所有 rank 阈值使用相对尺度；
- 不能通过添加规则修复失败；
- 完成后停止，不自动进入条件方位阶段。
```

# 阶段 5：核心创新点 1B/1C——条件方位 DML、联合修正与等预算基线

## 目标

完成 Q/Kq 已知条件下的分组条件估计链，并证明其收益不是候选域泄漏或未计入多初值成本造成的。

> **执行状态（2026-07-17）：阶段 5 已完成并停止。** 技术测试与 Pareto 方案 1 通过；455 个 holdout 配对中，主链与两初值直接 AP 的成功率差 95% 区间为 `[0,0]`，主链端到端 score calls 减少 44.95%。所有有噪声输出为 `NOT_CALIBRATED_STAGE5`；相干弱目标核心 stress 场景中主链、直接 AP 和 local full 均为 `0/200`。本状态记录不授权或执行阶段 6。

## 可直接复制的提示词

```text
默认 GitHub 仓库为：

makabaka165/bs_innovation

本轮只执行阶段 5 / Step12.3D-E：

- 条件方位单目标/双目标 DML；
- 完整固定顺序流形上的局部联合修正；
- 同物理角域、同先验、同预算 baseline；
- oracle 俯仰、估计俯仰和受扰俯仰误差传播验证。

本轮不执行：

- 自动 Q 选择；
- 自动 K 或 Kq 选择；
- Fisher 信息波束设计；
- 近双目标切向理论；
- bootstrap；
- K=3；
- cache；
- FPGA/硬件实现；
- C05、topK 或在线自适应 W/B。

当前阶段完成后必须停止，输出 A–J 报告，不得进入阶段 6。

未经用户在当前会话明确授权：

- 不提交；
- 不推送；
- 不创建 PR；
- 不新建或切换分支；
- 不修改其他仓库；
- 不覆盖 Step11 冻结结果。

============================================================
一、必须阅读
============================================================

完整阅读：

1. innovation-mining/06_formula_prior_art.md
2. innovation-mining/06_algorithm_prior_art.md
3. innovation-mining/06_closest_work_matrix.md
4. innovation-mining/10_current_paper_innovation_audit.md
5. innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
   重点：第 5.6 节、第 6 节、第 12 节
6. innovation-mining/12_experiment_system_code_structure_roadmap.md
   重点：Step12.3、复杂度、数据划分和否决标准
7. innovation-mining/13_next_step_execution_prompts.md
8. innovation-mining/14_step12_preimplementation_inventory.md
9. innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md
10. beamspace_ml_v18/paper/full_manuscript_v0.19_sequential_dbf_revision.md
11. beamspace_ml_v18/review/supporting_notes/sequential_revision_scope.md
12. Step12.0、Step12.1、Step12.2 的 README、公共接口和结果
13. Step12.3 阶段 4 修订后的全部：
    - README.md
    - common/
    - tests/
    - results/
    - run_step12_3_elevation_group_validation.m
14. 06_algorithm_prior_art.md 中：
    - A03 条件方位 DML；
    - A04 坐标最大化/AP；
    - A05 分组初始化；
    - 完整复杂度和相同失败机制。
15. Ziskind–Wax alternating projection 和已定位的 PR-DML 资料。

永久创新边界：

- 条件 DML、AP、坐标上升、单调性、SVD 投影均是已有方法。
- 候选贡献只允许定位为：
  “实际顺序 DBF 接口上的俯仰组初始化、同俯仰组内多方位处理，
   以及固定完整顺序流形修正的整体组织和工程效果。”
- 不得把联合修正重新命名为新的优化器。
- PR-DML 或 Kim 2012 若无法准确复现，只记录缺口，不得使用自定义简化版冒充。

============================================================
二、阶段 4 最终合同
============================================================

阶段 5 必须以提交：

89d8c056a3dc23fa7a54c2e332063aa27f0fbc99

中的阶段 4 合同为准。

不得重新使用旧字段：

- GROUP_UNIDENTIFIABLE
- high_confidence_group_flag

阶段 4 的上游状态包括：

estimate_status
support_status
statistical_calibration_status
registered_model_certified_flag
structural_gate_pass_flag
estimate_returned_flag

阶段 5 只允许在：

estimate_returned_flag == true
且
structural_gate_pass_flag == true

时进入条件方位估计。

若上游为：

GROUP_MMV_RANK_UNCERTIFIED
GROUP_MANIFOLD_RANK_UNCERTIFIED
GROUP_REGISTERED_ALIAS_UNCERTIFIED
GROUP_NO_FULL_RANK_CANDIDATE
GROUP_NUMERICAL_FAILURE

则阶段 5 不运行条件方位和联合修正，输出：

UPSTREAM_GROUP_STAGE_UNCERTIFIED

不得通过扩窗、改变 Q、降低 rank 门或增加特殊规则继续计算。

所有阶段 5 输出固定：

statistical_calibration_status = NOT_CALIBRATED_STAGE5

不得使用：

high confidence
posterior
probability
calibrated confidence
medium/low confidence

============================================================
三、阶段 5 开始时的两个预检修订
============================================================

1. 更新 innovation-mining/13_next_step_execution_prompts.md：

   - 将旧阶段 4 提示词标记为：
     “历史初始提示词，已由提交 89d8c056 的修订合同替代。”
   - 不再保留会误导后续执行的 GROUP_UNIDENTIFIABLE 和
     high_confidence_group_flag 作为 active 要求。

2. 修正阶段 4 测试表中 elevation_beam_peak baseline 的状态作用域：

   当前 baseline 不执行 registered-model structure diagnosis，
   不应把 fixture 的结构认证解释成 baseline 方法认证。

   新增字段：

   upstream_group_support_status
   method_status_scope

   对 elevation_beam_peak：

   method_status_scope = UPSTREAM_FIXTURE_ONLY
   method_certification_status = NOT_APPLICABLE_BASELINE
   registered_model_certified_flag = false

   fixture 的状态只保留在：

   upstream_group_support_status

   该修订只涉及测试/结果语义，不改变阶段 4 主估计器。

完成后重新运行阶段 4 runner，确认：

- 全部测试仍通过；
- Step11 哈希不变；
- 阶段 4 数值结果没有实质变化。

============================================================
四、阶段 5 的数据流
============================================================

阶段 5 必须区分两个不同的数据路径。

------------------------------------------------------------
4.1 条件方位初始化路径
------------------------------------------------------------

输入来自阶段 4 恢复的每个俯仰组：

Xphi_hat{q} [Nphi,L]

该路径用于：

- Kq=1 条件方位一维 DML；
- Kq=2 同俯仰双目标方位 DML；
- 生成完整联合修正的初始化。

它不是最终完整顺序 DML 的评分数据。

------------------------------------------------------------
4.2 完整顺序联合修正路径
------------------------------------------------------------

联合修正必须回到：

- 原始 factor=1 阵元数据；
- Step12.1 固定的物理顺序波束矩阵 Wseq；
- 原始固定顺序 DBF 观测 Zseq；
- 固定的完整顺序噪声协方差和白化器。

联合修正不得以：

- Xphi_hat；
- Ce_hat；
- 条件方位波束输出；

作为最终完整似然的观测。

原因：组恢复数据包含估计误差、组间耦合和噪声传播。
最终修正必须由原始完整顺序观测重新评分。

============================================================
五、组恢复噪声传播
============================================================

阶段 4 在行白化坐标中：

Z_recovery = Ge * Ce + N

使用：

H_e = Ge^\dagger

恢复：

Ce_hat = H_e * Z_recovery

在行噪声已经白化的条件下，组恢复噪声混合矩阵为：

R_group = H_e * H_e^H

不得直接计算 inv(Ge^H*Ge)；
必须使用 Step12.2 的稳定 SVD 求解或伪逆接口。

对第 q 个组：

alpha_q = real(R_group(q,q))

其物理环向列噪声协方差为：

C_x_q = alpha_q * Rphi_selected

不同组 q、r 的交叉噪声为：

R_group(q,r) * Rphi_selected

必须新增：

common/propagate_group_recovery_noise.m

建议签名：

function [noise_model,debug] = propagate_group_recovery_noise( ...
    Ge_hat, Rphi_selected, opts)

输出至少包含：

R_group
group_noise_scale
cross_group_noise_correlation
Rphi_selected
rank_Ge
phase_factor
num_svd
status

要求：

- 使用稳定 SVD；
- 不直接求 Gram 逆；
- 对 rank(Ge)<Q 返回显式失败；
- 不把各组恢复噪声假设成相互独立；
- 单独处理条件方位时可以使用 alpha_q，
  但必须保存完整 R_group 作为诊断。

============================================================
六、固定条件方位波束域
============================================================

每个组 q 的物理环向数据：

Xphi_q [Nphi,L]

对应条件俯仰角：

eta_condition_q

条件方位流形必须使用：

a_phi_m(phi | eta)
=
exp(j*k0*R*cos(eta)*cos(phi-psi_m))

不能使用与俯仰无关的 a_phi(phi)。

------------------------------------------------------------
6.1 方位物理波束矩阵
------------------------------------------------------------

新增：

common/build_fixed_conditional_azimuth_beam_bank.m

建议签名：

function [Uq,info] = build_fixed_conditional_azimuth_beam_bank( ...
    az_beam_deg, eta_condition_deg, array_meta, opts)

要求：

- Uq [Nphi,Ba]；
- eta_condition_deg 在一次条件方位搜索开始前固定；
- az_beam_deg 为预注册物理波束中心；
- 候选方位变化时不得重建 Uq；
- 单位范数权；
- 保存波束中心、条件俯仰、阵元顺序和 hash；
- phase_factor=1。

------------------------------------------------------------
6.2 条件方位观测和白化
------------------------------------------------------------

新增：

common/prepare_conditional_azimuth_data.m

建议签名：

function [data,model,debug] = prepare_conditional_azimuth_data( ...
    Xphi_q, Uq, Rphi_selected, alpha_q, opts)

计算：

Zphi_raw = Uq^H * Xphi_q

Cphi_beam_q =
alpha_q * Uq^H * Rphi_selected * Uq

Tphi_q Cphi_beam_q Tphi_q^H = I

Zphi_white = Tphi_q * Zphi_raw

输出：

data.Zphi_white
data.Zphi_raw
data.temporal_snapshot_count
data.eta_condition_deg
data.condition_source
data.upstream_group_support_status
data.statistical_calibration_status

model.Uq
model.Tphi_q
model.array_coordinates
model.lambda
model.eta_condition_deg
model.phase_factor
model.fixed_measurement_hash

要求：

- 使用 Step12.2 build_psd_whitener；
- alpha_q 只影响噪声尺度，不改变物理流形；
- Uq 和 Tphi_q 在候选搜索期间固定；
- 不得从候选方位或真值重新生成观测；
- 保存白化误差和有效秩。

------------------------------------------------------------
6.3 条件方位流形
------------------------------------------------------------

新增：

common/build_conditional_azimuth_manifold.m

建议签名：

function [Gphi,dGphi,info] = build_conditional_azimuth_manifold( ...
    az_candidate_deg, model, opts)

定义：

Aphi =
[a_phi(phi_1|eta_condition), ..., a_phi(phi_Kq|eta_condition)]

Gphi =
Tphi_q * Uq^H * Aphi

要求：

- Kq=1 或 Kq=2；
- 导数相对于 radian；
- 候选期间 Uq、Tphi_q、eta_condition 固定；
- 不接受 candidate-dependent whitener；
- 不接受 PhaseFactor；
- 输出 rank 和固定对象 hash。

============================================================
七、条件方位 DML
============================================================

新增：

common/estimate_conditional_azimuth_dml.m

建议签名：

function [est,debug] = estimate_conditional_azimuth_dml( ...
    data, target_count_Kq, search_domain, model, opts)

当前 Kq 由 oracle 给定：

Kq ∈ {1,2}

不做模型阶数选择。

Kq=1：

- 注册局部一维方位搜索；
- 使用 Step12.2 SVD-DML。

Kq=2：

- 在小型注册局部方位域内枚举全部无序角对；
- 不使用固定 az-separation 列表；
- 不使用 topK；
- 不使用 score gap；
- 不使用 C05；
- 不使用场景特殊阈值。

输出至少包括：

az_hat_deg
score
rss
rank_Gphi
num_score_eval
num_svd
runtime
conditional_estimate_status
upstream_group_support_status
eta_condition_deg
condition_source
statistical_calibration_status
fixed_measurement_hash

状态至少包括：

CONDITIONAL_AZIMUTH_RETURNED
UPSTREAM_GROUP_STAGE_UNCERTIFIED
AZIMUTH_MANIFOLD_RANK_UNCERTIFIED
NO_FULL_RANK_AZIMUTH_CANDIDATE
CONDITIONAL_AZIMUTH_NUMERICAL_FAILURE

不得输出统计 confidence。

============================================================
八、三条俯仰条件链
============================================================

每个核心场景必须分别运行三条链。

1. ORACLE_ELEVATION

eta_condition = eta_truth

用途：

- 隔离条件方位实现正确性；
- 不作为最终工程性能。

2. ESTIMATED_ELEVATION

eta_condition = 阶段 4 eta_hat

用途：

- 主工程链；
- 所有最终主结果必须以此链为主。

3. PERTURBED_ELEVATION

eta_condition =
eta_truth + delta_eta

至少测试：

delta_eta =
±0.1、±0.25、±0.5 个 factor=1 俯仰网格步长
或等价预注册物理偏差。

用途：

- 分析俯仰误差向方位估计传播；
- 不得按场景调节偏差列表。

必须输出：

oracle_to_estimated_degradation
estimated_to_perturbed_degradation
azimuth_bias_vs_elevation_error

如果方法只在 ORACLE_ELEVATION 下有效，
不得宣称完整分组条件链成立。

============================================================
九、完整固定顺序 DML 数据
============================================================

新增：

common/prepare_full_sequential_dml_data.m

建议签名：

function [data,model,debug] = prepare_full_sequential_dml_data( ...
    Yelem, Wseq, Rn_elem, opts)

计算：

Zseq = Wseq^H * Yelem

Cseq = Wseq^H * Rn_elem * Wseq

Tseq Cseq Tseq^H = I

Zseq_white = Tseq * Zseq

模型：

Gseq(Theta) =
Tseq * Wseq^H * A_receive(Theta)

要求：

- 使用 Step12.1 的真实 Wseq；
- 使用正确的阵元 permutation；
- Rn_elem 与 fixture 的 Rz/Rphi 模型一致；
- 对 separable covariance，按实际 vectorization 构造；
- Wseq、Cseq、Tseq 在整个联合搜索期间固定；
- 保存 hash；
- 候选变化不能重建 Wseq 或 whitener；
- 不使用阶段 4 恢复数据作为完整似然观测。

新增测试：

- Zseq 与逐级 DBF 输出一致；
- Cseq 与 Monte Carlo/显式公式一致；
- 白化误差通过；
- 固定 hash 在全部候选间不变。

============================================================
十、完整顺序局部流形
============================================================

新增：

common/build_full_sequential_local_manifold.m

建议签名：

function [Gseq,dGseq,info] = build_full_sequential_local_manifold( ...
    target_angles_deg, model, opts)

直接调用 factor=1 完整圆柱阵流形：

A_receive =
[a(az_1,el_1), ..., a(az_K,el_K)]

Gseq =
Tseq * Wseq^H * A_receive

不得使用：

a_phi⊗a_el 的独立近似替代完整候选评分。

可以用因子化形式做一致性测试，但最终评分必须由完整流形得到。

============================================================
十一、联合修正
============================================================

新增：

common/refine_joint_sequential_dml.m

建议签名：

function [est,history,debug] = refine_joint_sequential_dml( ...
    full_data, initial_angles_deg, local_domain, model, opts)

该更新属于经典 block-coordinate ascent/AP，
不得作为新优化器主张。

要求：

1. 目标 canonical order 固定：
   - 组按 elevation 排序；
   - 组内目标按 azimuth 排序；
   - 每次更新后重新 canonicalize。

2. 逐目标、逐维更新：
   - az_1、el_1、az_2、el_2；
   - 每个一维子问题使用固定注册候选轴；
   - 不按场景扩窗；
   - 不动态改变网格；
   - 不使用真值。

3. 每次候选评分使用同一个：
   - Zseq_white；
   - Wseq；
   - Tseq；
   - 物理角域。

4. 单调性：
   J_new >= J_old - tau_numeric

   tau_numeric 必须由机器精度和 score scale 决定，
   不能是场景经验常数。

5. 停止条件：
   - relative score change；
   - maximum angle update；
   - max_iter；
   三者使用全局固定配置。

6. 状态：
   JOINT_REFINEMENT_CONVERGED
   JOINT_REFINEMENT_MAX_ITER
   JOINT_REFINEMENT_NOT_RUN_UPSTREAM_UNCERTIFIED
   JOINT_REFINEMENT_NUMERICAL_FAILURE

7. 必须分别记录：
   - 函数值收敛；
   - 角度更新收敛；
   - 是否收敛到 local-full reference 对应解；
   - 错误局部峰；
   - 每次迭代 score/RSS；
   - 每维候选数；
   - SVD 次数；
   - runtime。

8. 多初值：
   - 主方法默认使用分组条件初始化；
   - 额外多初值只能作为预注册 diagnostic；
   - 所有 R 次运行全部计入成本；
   - 不允许看结果后增加 R。

============================================================
十二、初始化和 baseline
============================================================

必须实现或运行以下方法。

A. MAIN_GROUPED_CONDITIONAL_JOINT

阶段 4 分组
→ 条件方位
→ 完整顺序联合修正

B. GROUPED_CONDITIONAL_ONLY

阶段 4 分组
→ 条件方位
→ 不联合修正

C. DIRECT_AP_CONVENTIONAL_INIT

使用同一个联合修正器，
但初始化来自常规 DBF/固定波束中心，
不使用俯仰分组恢复。

它与主方法的差异只能是初始化和数据组织，
不能使用不同评分函数。

D. DIRECT_COORDINATE_ASCENT_FIXED_CENTER

使用固定常规中心作为初始化的直接二维坐标更新。
若与 AP 完全等价，应合并名称，不重复包装两个方法。

E. LOCAL_FULL_DML_REFERENCE

仅在可承受的小型局部物理角域中运行：

- 同一 Wseq；
- 同一白化观测；
- 同一 K；
- 同一物理角域；
- 全部候选；
- 只称 local full-grid reference，不称全局最优。

F. CONVENTIONAL_DBF

常规波束峰值或现有常规测角。

G. FACTOR1_COMMON_EL / FACTOR1_CONTROLLED_PAIR2D

若使用，必须：

- 在 factor=1 下重新实现或重跑；
- 使用相同数据、Wseq、白化和角域；
- 不得读取旧 Step11 factor=2 性能数字。

H. PR-DML

只有能够按已发表公式准确复现时才运行。
否则在结果中记录：

PR_DML_STATUS = EXACT_REPRODUCTION_UNAVAILABLE

不得用自定义简化版冒充。

I. Kim 2012

同样只有准确复现时运行，否则记录明确缺口。

============================================================
十三、baseline 状态作用域
============================================================

所有方法表必须区分：

upstream_group_support_status
method_estimate_status
method_status_scope
statistical_calibration_status

常规 DBF、beam peak 等 baseline：

method_status_scope = METHOD_ONLY
upstream_group_support_status 可单独保存
registered_model_certified_flag 不得直接继承到 baseline 方法

不得让 fixture 的结构认证看起来像 baseline 方法本身被认证。

============================================================
十四、搜索域与禁止真值泄漏
============================================================

必须新增统一角域构造接口：

common/build_common_registered_local_domain.m

局部物理角域只能来自：

1. 常规 DBF 检测波束和相邻波束边界；
2. 预注册的常规测角中心及固定偏差；
3. 预先冻结的工程角分辨单元。

不得来自：

- 真值中心；
- 为某个方法单独缩小的窗口；
- 看到结果后扩大的窗口；
- 包含真值保证的人工区间。

所有方法必须使用同一个物理角域。

每个结果行记录：

domain_id
domain_source
domain_bounds
domain_hash
truth_in_domain_flag
truth_on_search_grid_flag
grid_step_az_deg
grid_step_el_deg

若真值出域：

- 不允许扩窗；
- 记录 OUT_OF_REGISTERED_DOMAIN；
- 计入无条件失败率。

============================================================
十五、必须增加 off-grid 场景
============================================================

阶段 5 不得只使用 truth-on-grid 场景。

至少加入：

1. 方位真值位于网格半步；
2. 俯仰真值位于网格半步；
3. 方位和俯仰同时 off-grid；
4. 常规中心存在固定偏差；
5. 目标靠近角域边界；
6. 真值部分出域；
7. 极近俯仰场景加入白噪声；
8. 两维同时极近；
9. 同俯仰 K2；
10. Q2/K1+K1；
11. 弱次目标；
12. 相干源；
13. 相关 Rz/Rphi；
14. 缩小环向孔径；
15. L=1 和 L>1。

不得把 off-grid 结果通过临时增加网格点修复。

============================================================
十六、相干和弱目标场景
============================================================

必须区分：

1. 时间波形相干，但环向响应不同；
2. 同俯仰组内两个相干方位目标；
3. 组系数接近比例；
4. 第二目标功率逐级降低；
5. 相干 + 弱目标组合。

必须报告：

- 条件方位流形秩；
- 恢复组数据串扰；
- 错误局部峰率；
- joint score gap；
- 无条件错误；
- 不得用 unresolved/uncertified 删除困难样本。

本阶段 Q/Kq 为 oracle，
但算法失败仍必须计入主性能。

============================================================
十七、公平预算
============================================================

主方法的端到端预算必须包括：

C_total_main =
C_stage4_group_search
+ C_group_recovery
+ C_noise_propagation
+ C_conditional_azimuth
+ C_joint_refinement
+ C_multi_start

不得只报告阶段 5 新增部分。

每个方法必须记录：

- score calls；
- SVD calls；
- eig/whitener calls；
- 候选流形构造次数；
- 迭代次数；
- multi-start 次数；
- wall time；
- 最大主要数组内存；
- 预计算时间；
- 在线时间。

local full、AP、主方法使用：

- 相同物理数据；
- 相同 Wseq；
- 相同 K/Q/Kq 先验；
- 相同角域；
- 相同最终 DML score；
- 相同硬件/软件环境。

不得只给主方法更窄的搜索域。

============================================================
十八、数据划分
============================================================

必须分为：

1. DESIGN
   - 只用于实现、单元测试和固定全局优化容差。

2. VALIDATION
   - 用于一次性确认预注册配置。

3. NORMAL_HOLDOUT
   - 不参与任何参数、网格、迭代或多初值选择。

4. STRESS_HOLDOUT
   - 极近、弱目标、相干、边界、相关噪声和模型失配。

所有配置在进入 holdout 前锁定并保存 hash。

holdout 失败后不得修改：

- 搜索域；
- 网格；
- max_iter；
- multi-start；
- 停止条件；
- 目标匹配规则。

============================================================
十九、统计报告
============================================================

本阶段不进行模型阶数 bootstrap，
但对 Monte Carlo 性能必须报告统计区间。

核心有噪声场景每方法建议至少：

Nmc >= 200

并使用相同随机噪声 realization 做配对比较。

报告：

- 联合成功率；
- 方位 RMSE；
- 俯仰 RMSE；
- 二维配对 RMSE；
- conditional RMSE；
- 无条件惩罚误差；
- wrong-local-peak rate；
- convergence rate；
- score gap；
- runtime；
- score calls。

成功率使用 Wilson 区间；
方法差异使用配对 bootstrap 或成对重采样区间。

不得只报告成功样本上的 conditional RMSE。

============================================================
二十、目标配对
============================================================

新增：

common/match_target_sets.m

评价时使用 Hungarian 或最小总二维角度代价。

要求：

- 只用于评价；
- 不参与搜索；
- 不影响候选排序；
- 不使用真值修正算法输出；
- 保存 permutation 和总代价。

============================================================
二十一、测试
============================================================

至少新增：

1. test_group_noise_propagation.m
   - Monte Carlo 验证 R_group 和 alpha_q；
   - 样本误差随样本数下降。

2. test_conditional_azimuth_manifold.m
   - 与完整环向几何公式一致；
   - 明确 cos(eta)；
   - 导数误差 <=1e-6。

3. test_conditional_azimuth_fixed_measurement.m
   - 候选变化时 Uq/Tphi/hash 不变。

4. test_conditional_azimuth_noise_whitening.m
   - 白化后协方差接近单位阵。

5. test_conditional_azimuth_q1_k2.m
   - 同俯仰双目标方位搜索。

6. test_oracle_estimated_perturbed_elevation.m
   - 三条条件链全部运行。

7. test_full_sequential_data_equivalence.m
   - 原始逐级 DBF 与 Wseq^H*Y 一致；
   - Cseq 公式和白化通过。

8. test_full_sequential_manifold.m
   - 与 factor=1 完整流形一致。

9. test_joint_refinement_monotonicity.m
   - 单调性违规数为 0。

10. test_joint_refinement_canonical_order.m
    - 标签交换不改变最终集合。

11. test_no_truth_dependent_domain.m
    - active 搜索域构造器不接受 truth。

12. test_upstream_group_gate.m
    - 上游 uncertified 时阶段 5 不运行。

13. test_baseline_status_scope.m
    - baseline 不继承结构认证为方法认证。

14. test_stage5_scope_rules.m
    禁止：
    - C05；
    - topK；
    - score-gap 分支；
    - PhaseFactor=2；
    - 固定 1e-10 ridge；
    - high confidence；
    - candidate-dependent W/whitener；
    - truth-dependent domain。

============================================================
二十二、输出
============================================================

不要覆盖阶段 4 结果。

建议新增：

step_12_3_grouped_conditional_dml/results_stage5/

输出至少包括：

conditional_azimuth_trial.csv
conditional_azimuth_elevation_error_propagation.csv
group_noise_propagation.csv
joint_refinement_history.csv
joint_refinement_trial.csv
method_budget_comparison.csv
method_score_gap.csv
wrong_local_peak_summary.csv
offgrid_holdout.csv
normal_holdout_summary.csv
stress_holdout_summary.csv
baseline_reproduction_status.csv
stage5_keypoints.csv
stage5_report.md

每个方法结果行至少包含：

scenario
data_split
method
K
oracle_Q
oracle_Kq
condition_source
eta_condition_deg
upstream_group_support_status
conditional_estimate_status
joint_refinement_status
statistical_calibration_status
domain_id
domain_source
domain_hash
truth_in_domain_flag
truth_on_search_grid_flag
az_hat_deg
el_hat_deg
score
rss
normalized_score_gap_to_local_full
az_rmse
el_rmse
pair_rmse
success_flag
wrong_local_peak_flag
num_score_eval_stage4
num_score_eval_conditional
num_score_eval_joint
num_score_eval_total
num_svd_total
num_eig_total
num_multi_start
runtime_total
pass_flag
phase_factor

============================================================
二十三、技术验收门
============================================================

全部满足才允许 PASS。

A. 数学与接口正确性

- 条件方位流形与完整环向公式一致；
- cos(eta) 依赖得到验证；
- 组恢复噪声传播通过；
- 条件方位白化通过；
- 完整顺序观测、协方差和流形通过；
- 联合修正只使用原始完整顺序观测；
- 候选期间 W/U/whitener/hash 固定；
- phase_factor=1。

B. 确定性正确性

- grid-aligned、无噪声、模型匹配场景中：
  主方法与 local full reference 的角度集合一致，
  或误差不超过一个预注册最终网格步长；
- normalized score gap <=1e-10；
- 单调性违规为 0；
- 标签交换不改变最终目标集合；
- Q1/K2 同俯仰场景由条件方位正确处理。

C. 误差传播

- ORACLE_ELEVATION、ESTIMATED_ELEVATION、
  PERTURBED_ELEVATION 均有结果；
- 不得只展示 oracle 链；
- 若估计俯仰链明显失效，不能以 oracle 结果支持完整算法。

D. 公平性

- 所有方法使用同一物理角域；
- 不存在真值中心窗口；
- 主方法总成本包含阶段 4；
- multi-start 全部计入；
- old factor=2 结果未被使用；
- local full 只称局部 reference。

E. holdout/Pareto 门

主方法必须在独立 holdout 上满足下列之一：

方案 1：复杂度收益

- 相对最强同预算 AP/直接坐标 baseline，
  成功率差的 95% 下界 >= -0.02；
- 平均端到端 score calls 至少降低 20%。

或方案 2：性能收益

- 在端到端 score calls 不高于 baseline 的条件下，
  成功率差的 95% 下界 > 0，
  或无条件惩罚误差显著下降。

同时，相对 local full reference：

- 不要求性能超过 local full；
- 但应以明显更少的 score calls 接近其成功率和最终 score；
- 若成本不低于 local full，且性能无改善，则失败。

若两种方案均不满足：

- 不得继续包装为核心算法创新；
- 降级为工程初始化或失败路线。

F. 证据边界

- 不宣称自动 Q/K；
- 不宣称统计 confidence；
- 不宣称 PR/Kim 比较完成，除非准确复现；
- 不进入阶段 6。

============================================================
二十四、停止和否决条件
============================================================

出现任一项必须 FAIL 或 PARTIAL：

1. 条件方位必须使用真值俯仰才工作；
2. 估计俯仰链相对直接 AP 无实际收益；
3. 联合修正大量落入错误局部峰；
4. 必须按场景扩窗或增加多初值；
5. 主方法总成本不低于 local full；
6. 收益来自更窄、含真值的候选域；
7. 阶段 4 uncertified 样本仍被强制向下处理；
8. 组恢复噪声被假设为独立但未验证；
9. 候选期间重建 Wseq/Uq/whitener；
10. baseline 状态继续混淆 fixture 支持和方法认证；
11. off-grid 或边界失败后增加特殊规则；
12. 使用旧 factor=2 结果；
13. 为通过测试恢复 C05、topK、gap 或经验综合分数。

无论 PASS、PARTIAL 或 FAIL，本轮结束后停止。

============================================================
二十五、最终 A–J 报告
============================================================

A. 阶段结论
   - PASS / PARTIAL / FAIL
   - 候选贡献是保留、降级还是否决
   - 是否允许进入阶段 6

B. 阅读和 prior-art 边界

C. 文件清单
   - public/private/test-only
   - 新增与修改路径

D. 公式到代码映射
   - 组噪声传播
   - 条件方位数据
   - 完整顺序数据
   - 联合修正

E. 数据维度和固定对象
   - Xphi
   - Uq
   - Zphi
   - Tphi
   - Wseq
   - Zseq
   - Tseq
   - Gphi
   - Gseq

F. 测试和命令

G. 关键结果及置信区间
   - oracle/estimated/perturbed
   - off-grid
   - normal/stress holdout
   - wrong peak
   - score gap

H. 完整复杂度
   - 阶段 4 + 条件方位 + 联合修正
   - score/SVD/eig/multi-start/runtime/memory

I. 风险和未完成项
   - oracle Q/Kq
   - PR/Kim 缺口
   - 未模型阶数校准
   - 未 FIM/切向理论

J. 下一阶段判定
   - 只有全部技术和 Pareto 门通过，才可写：
     “技术上允许后续单独授权进入阶段 6。”
   - 本轮必须停止。
```

# 阶段 6：核心创新点 2——固定白化顺序流形的近双目标渐近验证

## 目标

验证显式近双目标推论、正式假设和零方向边界；不选择波束，不把经典投影 FIM 改名为新理论。

> **执行状态（2026-07-17）：阶段 6 已完成并停止。** 固定测量合同、导数、投影几何、精确恒等式、144 个非退化注册尾区、三类不变性和 synthetic exact-null 六阶候选全部通过；理论状态为 `THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY`。1296 个主 secant case 全部保留，三条 ratio 最大尾区误差为 `4.0102e-6 / 1.0421e-5 / 6.1180e-6`。四个主物理配置均无 exact tangent null，单通道仅为 `EXACT_MEASUREMENT_COLLAPSE`。本状态记录不授权或执行阶段 7。

> **阶段 6.1A2 finalizer 冻结状态（2026-07-18）：`STAGE6_REPRODUCTION_FINALIZERS_IMPLEMENTED_EVIDENCE_RERUN_PENDING`。** provenance 核心合同已经在 `ac92c37` 实现；A2 进一步冻结了 core/final artifact registry、15 表显式旧证据比较合同、Git-object 比较器、raw-file SHA-256 manifest、确定性 bundle、独立快照、自复现 verifier 和三文件 final-freeze writer。

> **阶段 6.1B 最终证据冻结状态（2026-07-18）：`STAGE6_REPRODUCIBLE_EVIDENCE_FROZEN`。** 从干净 `90f1e08e4622a620d7ebcb64dcc83d26d07ebf15` 独立运行两次，runner、历史 `17c2022` 对照、自复现和 FINAL_FREEZE validator 全部通过。Run1/Run2 core bundle 均为 `f85e03894cb4c5a9527dd0cc7d872302b494525a47f2d5ddcda28f734ae7e286`；最终确定性 bundle 为 `0c1f444603398e03865043af4e4c6e4a414dd15a3cc90e0539b19c56e990c839`，21 个 artifacts、45,940,802 bytes。阶段 6 `.m`、README、source/dependency scope 均零修改；物理 exact tangent null 仍未出现，synthetic 六阶候选仍不构成物理验证。本状态只允许后续单独授权进入阶段 7，不自动进入。

## 阶段 6.1A 固定白化切向证据复现合同

后续阶段 6.1B 的正式证据运行必须同时满足：

1. `baseline_commit=0430f25272690a3ddf378dcf0bab465ca93edb68` 是 runtime HEAD 的祖先，不要求两者相等；非祖先返回 `STAGE6_BASELINE_NOT_ANCESTOR`。
2. runner 写入任何证据前，`git status --porcelain=v1 --untracked-files=all` 必须为空；否则返回 `STAGE6_DIRTY_WORKTREE_AT_START`。
3. `runtime_head_commit` 只进入独立 `stage6_runtime_diagnostics.csv` 和人类审计，不进入任何稳定计划、measurement、provenance 或 deterministic-evidence hash。
4. `stage6_source_tree_hash` 只覆盖阶段 6 目录内 Git 跟踪的 `*.m` 与根 `README.md`；`results/`、`figures/` 和生成证据全部排除。
5. `stage6_dependency_tree_hash` 使用显式直接依赖清单，覆盖 Step12.0 接收流形/导数、Step12.1 顺序 DBF 与 canonical permutation、Step12.2 PSD 白化/数值秩、Step12.3 完整顺序流形及其数值秩 helper、`sim_cfg.m` 和 `arr_cyl.m`。
6. source/dependency tree 均按相对路径字典序，对 Git `mode + NUL + blob hash + NUL + relative path` 记录计算 SHA-256，不读取 checkout 文本作为跨平台身份。
7. `stage6_controls_hash`、`stage6_measurement_plan_hash`、`stage6_experiment_plan_hash` 按控制、物理测量和实验身份分别构造；`stage6_provenance_hash` 绑定 baseline、source/dependency trees、三类稳定计划、`phase_factor=1` 和 MATLAB R2022b 合同。
8. 稳定数值 CSV 不再保存 wall-clock、进程峰值内存或 runtime HEAD；这些信息只写入 `stage6_runtime_diagnostics.csv`，且不参与数值复现相等门。
9. runner 使用显式 required artifact registry，不再以“CSV 文件数量必须等于 15”作为 schema 合同。
10. 阶段 6.1A 只验证 provenance 代码与静态协议；不得运行完整阶段 6 runner、不得生成新 CSV/PNG、不得覆盖 `17c2022` 证据。

## 阶段 6.1B 正式证据重跑与最终冻结接口

阶段 6.1B 只能从干净的 A2 code-only 提交开始，并严格按以下顺序执行：

1. 从干净 A2 提交运行阶段 6 runner；
2. 使用 `capture_stage6_evidence_snapshot` 将第一轮快照保存到仓库外临时目录；
3. 恢复工作树到干净 A2 提交；
4. 第二次运行阶段 6 runner；
5. 将第二轮快照保存到另一个仓库外临时目录；
6. 使用 `compare_stage6_evidence_to_commit` 对比固定历史提交 `17c2022aea3be4d1c6b090aa771e7253c79c858e`；
7. 使用 `verify_stage6_self_reproduction` 比较两个独立快照；
8. 生成 `stage6_reproduction_comparison.csv`；
9. 生成 raw-file `stage6_evidence_manifest.csv` 和确定性 bundle hash；
10. 使用 `write_stage6_final_freeze_artifacts` 写入 comparison、manifest 和 self-check 三个 final-freeze 文件；
11. 使用 `validation_scope=FINAL_FREEZE` 执行 artifact validator；
12. 只更新阶段 6 source scope 之外的论文与审计文档；
13. 创建 evidence commit；
14. 从 evidence commit 的干净 checkout 再执行 smoke reproduction；
15. 不再修改阶段 6 source scope。

阶段 6.1B 永久禁止修改：

- `step_12_4_near_pair_tangent_asymptotics/README.md`；
- `step_12_4_near_pair_tangent_asymptotics/**/*.m`。

若 6.1B 需要修改上述文件，必须停止并退回新的 code-only 修订轮次，不能在正式证据运行中顺手修改。

## 可直接复制的提示词

```text
默认 GitHub 仓库为：

makabaka165/bs_innovation

本轮只执行阶段 6 / Step12.4：

固定白化完整顺序接收流形下，近双目标第二奇异值、
归一化相关性和列归一化 Gram 条件数的统一局部渐近关系验证，
并分析 exact tangent null、near-null 和高阶退化边界。

本轮不执行：

- Fisher 信息波束选择；
- 自动 Q/K/Kq 选择；
- bootstrap；
- K1/K2 模型阶数；
- K=3；
- cache；
- 硬件映射；
- 新的角度搜索算法；
- C05、topK、score-gap 或自适应搜索预算；
- 阶段 5 性能优化或重新调参。

当前阶段完成后必须停止，输出 A–J 报告，不得自动进入阶段 7。

未经用户在当前会话明确授权：

- 不提交；
- 不推送；
- 不创建 PR；
- 不新建或切换分支；
- 不修改其他仓库；
- 不覆盖 Step11、阶段 4 或阶段 5 的冻结结果。

============================================================
一、基准提交与阶段边界
============================================================

以以下提交为阶段 6 基准：

0430f25272690a3ddf378dcf0bab465ca93edb68

提交信息：

feat: complete stage 5 grouped conditional DML

开始工作前记录：

- git HEAD；
- 当前分支；
- 工作树状态；
- MATLAB 版本；
- 操作系统；
- 浮点精度；
- 当前 active phase factor。

阶段 6 的物理主流形必须为：

g(phi,theta)
=
Tseq * Wseq' * a_receive(phi,theta)

其中：

- a_receive 使用 factor=1；
- Wseq 是固定物理顺序波束矩阵；
- Cseq = Wseq' * Rn_elem * Wseq；
- Tseq 是 Cseq 的固定有效子空间白化器；
- Wseq、Cseq、Tseq、有效白化秩在一个测量配置内均不得随候选角变化。

阶段 6 的主理论对象不是：

- 阶段 4 的 Ge；
- 恢复组数据 Xphi；
- 条件方位 Gphi；
- 某个随候选角重新形成的波束矩阵；
- 未白化阵元流形。

Ge 和 Gphi 最多只能作为补充诊断，不能作为主理论结论的流形。

============================================================
二、必须阅读
============================================================

完整阅读并遵守：

1. innovation-mining/06_formula_prior_art.md
2. innovation-mining/06_algorithm_prior_art.md
3. innovation-mining/06_closest_work_matrix.md
4. innovation-mining/10_current_paper_innovation_audit.md
5. innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
   重点：第 7 节、第 8 节和 prior-art 边界
6. innovation-mining/12_experiment_system_code_structure_roadmap.md
   重点：Step12.4
7. innovation-mining/13_next_step_execution_prompts.md
8. innovation-mining/14_step12_preimplementation_inventory.md
9. innovation-mining/FAILED_likelihood_discriminative_adaptive_wb.md
10. beamspace_ml_v18/paper/full_manuscript_v0.19_sequential_dbf_revision.md
11. beamspace_ml_v18/review/supporting_notes/sequential_revision_scope.md
12. Step12.0：
    - build_receive_cyl_steering_vec.m
    - build_receive_cyl_steering_with_derivatives.m
13. Step12.1：
    - build_sequential_beam_matrix.m
    - form_elevation_dbf_cube.m
    - form_azimuth_dbf_cube.m
    - 阵元 permutation 函数
14. Step12.2：
    - stable_numeric_rank.m
    - build_psd_whitener.m
    - beamspace_dml_score_svd.m
15. Step12.3 阶段 5：
    - prepare_full_sequential_dml_data.m
    - build_full_sequential_local_manifold.m
    - build_common_registered_local_domain.m
    - build_stage5_locked_config.m
    - stage5_keypoints.csv
    - stage5_report.md
16. 06_formula_prior_art 中 F04–F08：
    - 中心–差分参数化；
    - 投影 Jacobian；
    - 第二奇异值；
    - 归一化相关性；
    - Gram 条件数。
17. 已定位的最近工作：
    - deterministic CRB / projected Jacobian；
    - array-manifold differential geometry；
    - near-source CRB；
    - statistical angular resolution limit；
    - approximate ML for two closely spaced sources；
    - 两列 Gram 和 mutual coherence。

若可使用 paper-lookup skill 或联网检索，只执行针对公式的定向补检：

- second singular value of two steering vectors Taylor expansion；
- projected Jacobian close sources singular value；
- normalized coherence local Fisher metric；
- Gram condition number closely spaced array manifold；
- tangent-null higher-order array manifold separation。

不得把宽泛领域搜索结果数量当作新颖性证明。

============================================================
三、prior-art 与创新性永久边界
============================================================

以下均不得单独声明为新方法或新理论：

- 中心–差分参数化；
- 对称 Taylor 展开；
- 和差 Hadamard/酉变换；
- 投影 Jacobian；
- 单目标有效 Fisher 信息；
- 阵列流形微分几何；
- 两列 Gram 特征值；
- mutual coherence；
- SVD；
- 精确白化；
- 可逆/酉换基不变性。

本阶段允许保留的候选理论贡献只能表述为：

“针对固定、精确白化的实际圆柱阵顺序接收波束二维流形，
显式统一给出近双目标第二奇异值、归一化相关性和列归一化
Gram 条件数关于同一个二维分离方向二次型的局部渐近关系，
并明确其 exact-null、near-null、列范数不对称和数值适用边界。”

即使所有公式通过，也应定位为：

经典投影 FIM / 流形几何在当前固定顺序 DBF 场景中的显式推论。

不得写：

- 首次提出投影 Jacobian；
- 首次发现 Fisher 信息和相关性的联系；
- 首次发现近目标 Gram 病态；
- 首次提出白化 beamspace 几何；
- 首次提出中心–差分坐标。

============================================================
四、新代码目录
============================================================

新建：

beamspace_ml_v18/source/stepwise_signal_model/steps/
step_12_4_near_pair_tangent_asymptotics/

目录结构：

step_12_4_near_pair_tangent_asymptotics/
  README.md
  common/
  common/private/
  tests/
  tests/private/
  results/
  figures/
  run_step12_4_tangent_asymptotics_validation.m

不得把新代码混入阶段 5 的 common/ 或 results_stage5/。

允许调用阶段 1–5 已通过的公共函数，但不得复制另一套：

- factor=1 导向矢量；
- PSD 白化器；
- 数值秩规则；
- 阵元 permutation；
- Wseq 构造。

============================================================
五、正式参数化与单位
============================================================

所有理论推导内部使用弧度。

定义：

xi =
[phi;
 theta]

中心：

c_rad =
[phi_c;
 theta_c]

单位方向：

v_rad in R^2

要求：

norm(v_rad,2) = 1

分离范数：

r_rad > 0

实际二维分离向量：

d_rad = r_rad * v_rad

两个目标：

xi_minus = c_rad - d_rad/2
xi_plus  = c_rad + d_rad/2

外部配置和 CSV 可同时保存 degree，但所有：

- Jacobian；
- T；
- q；
- 导数；
- Taylor 展开；
- 渐近式；

必须使用 radian。

不得在公式中把 degree 数值直接代入 per-radian 导数。

每条结果必须同时保存：

center_az_deg
center_el_deg
direction_az_component
direction_el_component
separation_norm_rad
separation_norm_deg
endpoint_minus_az_deg
endpoint_minus_el_deg
endpoint_plus_az_deg
endpoint_plus_el_deg

============================================================
六、锁定的阶段 6 配置
============================================================

新增：

tests/private/build_stage6_locked_plan.m

该函数必须在运行任何结果前返回完整注册计划，并计算：

stage6_controls_hash
stage6_measurement_plan_hash
stage6_experiment_plan_hash

hash 必须覆盖：

- beam centers；
- beam subset indices；
- noise covariance type；
- covariance parameters；
- centers；
- direction bank；
- separation ladder；
- derivative finite-difference steps；
- numeric-floor multiplier；
- rank multiplier；
- ratio acceptance thresholds；
- exact-null threshold rule；
- MATLAB precision；
- phase factor；
- current git commit；
- method/version IDs。

不得只 hash 波束中心而遗漏场景计划。

------------------------------------------------------------
6.1 注册测量配置
------------------------------------------------------------

至少预注册以下固定配置，不得看完结果后替换：

A. SEQ_3X3_WHITE

az beams:
[7.4, 8.0, 8.6] deg

el beams:
[9.6, 10.0, 10.4] deg

element covariance:
identity

B. SEQ_3X3_CORRELATED

使用与阶段 5 correlated fixture 相同的：

Rz = toeplitz(0.45.^(0:Nel-1))
Rphi = toeplitz(0.70.^(0:Nphi-1))

Rn_elem = kron(Rphi,Rz)

C. SEQ_2X3_WHITE

az beams:
[7.4, 8.6] deg

el beams:
[9.6, 10.0, 10.4] deg

D. SEQ_3X2_WHITE

az beams:
[7.4, 8.0, 8.6] deg

el beams:
[9.6, 10.4] deg

E. SINGLE_CHANNEL_DIAGNOSTIC

只用于检查完全退化的状态处理。
不得将该配置作为实际设计推荐或理论正面证据。

对于每个配置：

1. 使用 Step12.1 的真实顺序 DBF 函数构造 Wseq；
2. 计算 Cseq = Wseq' * Rn_elem * Wseq；
3. 使用 Step12.2 build_psd_whitener 构造 Tseq；
4. 保存 whitening rank；
5. 保存 beam indices；
6. 保存：
   - Wseq_hash
   - Cseq_hash
   - Tseq_hash
   - array_geometry_hash
   - fixed_measurement_hash
7. 一个配置内所有中心、方向和分离尺度必须复用同一固定对象。

不得在候选角变化时重新计算：

- Wseq；
- Cseq；
- Tseq；
- whitening rank。

------------------------------------------------------------
6.2 注册中心
------------------------------------------------------------

至少使用以下 9 个中心：

az center:
[7.6, 8.0, 8.4] deg

el center:
[9.8, 10.0, 10.2] deg

形成 3×3 笛卡尔积。

如果某中心的：

norm(g(c)) == 0
或
接近机器零，

必须返回：

CENTER_MANIFOLD_NUMERICALLY_ZERO

不得临时更换中心。

------------------------------------------------------------
6.3 注册固定方向
------------------------------------------------------------

固定方向至少包括：

V_AZ =
[1;0]

V_EL =
[0;1]

V_DIAG_POS =
[1;1]/sqrt(2)

V_DIAG_NEG =
[1;-1]/sqrt(2)

这些方向在 radian 坐标中归一化。

另允许根据每个 T 的特征向量生成：

V_T_MAX
V_T_MIN

它们只能用于诊断最强/最弱切向方向，
不得替换四个固定方向的主验收结果。

------------------------------------------------------------
6.4 注册分离尺度
------------------------------------------------------------

固定：

r_deg =
0.4 * 2.^(-(0:8))

即：

0.4
0.2
0.1
0.05
0.025
0.0125
0.00625
0.003125
0.0015625 degree

内部使用：

r_rad = deg2rad(r_deg)

不得根据 ratio 结果增加或删除中间尺度。

若最小尺度进入数值底噪，只能按预注册 numeric-floor 规则分类，
不能通过手工选择“最好看的三个点”验收。

============================================================
七、固定测量模型构造
============================================================

新增：

common/build_stage6_fixed_measurement_model.m

建议签名：

function [model,debug] = build_stage6_fixed_measurement_model( ...
    config, cfg, opts)

输出 model 至少包含：

model.config_id
model.Wseq
model.Cseq
model.Tseq
model.whitening_rank
model.array_meta
model.lambda
model.phase_factor
model.az_beam_deg
model.el_beam_deg
model.beam_indices
model.noise_covariance_id
model.Rn_elem
model.Wseq_hash
model.Cseq_hash
model.Tseq_hash
model.fixed_measurement_hash
model.stage6_controls_hash

要求：

- phase_factor=1；
- 使用 canonical element order；
- Tseq 采用有效子空间降维形式；
- Tseq*Cseq*Tseq' ≈ I_rank；
- 不接受候选角作为输入；
- 不接受 candidate-dependent beam/whitener options。

============================================================
八、一阶解析导数
============================================================

新增：

common/build_fixed_whitened_sequential_derivatives.m

建议签名：

function [g,Jg,info] = build_fixed_whitened_sequential_derivatives( ...
    center_deg, model, opts)

要求：

1. 必须调用阶段 1 权威函数：

build_receive_cyl_steering_with_derivatives

不得复制第三套一阶导数公式。

2. 将 legacy 阵元顺序显式转换到 canonical 顺序。

3. 计算：

g =
Tseq * Wseq' * a

Jg =
[
 Tseq * Wseq' * da_daz_rad,
 Tseq * Wseq' * da_del_rad
]

4. 输出：

derivative_unit = per_radian
fixed_measurement_hash
phase_factor
g_norm
Jg_norm
whitening_rank

5. 与阶段 5：

build_full_sequential_local_manifold

返回的单目标 g/J 进行一致性检查。

============================================================
九、二阶和三阶方向导数
============================================================

新增：

common/build_fixed_whitened_directional_derivatives.m

建议签名：

function out = build_fixed_whitened_directional_derivatives( ...
    center_deg, direction_unit_rad, model, opts)

至少返回：

out.g0
out.g1
out.g2
out.g3
out.direction_unit_rad
out.fixed_measurement_hash

定义：

g1 = D_v g
g2 = D_v^2 g
g3 = D_v^3 g

必须基于 factor=1 接收流形解析构造或由经过验证的解析几何函数构造。

对方向单位向量：

v =
[v_phi;
 v_theta]

定义方向单位矢量的导数：

u1 =
v_phi*u_phi + v_theta*u_theta

u2 =
v_phi^2*u_phiphi
+ 2*v_phi*v_theta*u_phitheta
+ v_theta^2*u_thetatheta

u3 =
v_phi^3*u_phiphiphi
+ 3*v_phi^2*v_theta*u_phiphitheta
+ 3*v_phi*v_theta^2*u_phithetatheta
+ v_theta^3*u_thetathetatheta

对第 m 个阵元：

f1_m = k0*r_m^T*u1
f2_m = k0*r_m^T*u2
f3_m = k0*r_m^T*u3

若：

a = exp(j*f)

则：

a1 =
j*f1 .* a

a2 =
(j*f2 - f1.^2) .* a

a3 =
(j*f3 - 3*f1.*f2 - j*f1.^3) .* a

然后投影：

gk =
Tseq * Wseq' * ak

k=1,2,3。

必须用独立中心差分或高阶差分验证，不能以同一解析表达式自证。

预注册差分步长：

first derivative:
h1 = 1e-6 rad

second derivative:
h2 = 2e-4 rad

third derivative:
h3 = 5e-4 rad

同时报告一个固定步长敏感性梯度，但不得看结果后更换主验收步长。

验收建议：

first derivative relative error <= 1e-6
second derivative relative error <= 1e-4
third derivative relative error <= 1e-3

若三阶导数无法稳定验证，exact-null 六阶扩展必须判为 PARTIAL，
但非退化二次渐近式仍可单独验收。

============================================================
十、投影 Jacobian 几何量
============================================================

新增：

common/compute_projected_jacobian_metric.m

建议签名：

function [metric,debug] = compute_projected_jacobian_metric( ...
    g, Jg, opts)

定义：

Pg_perp =
I - g*g'/(g'*g)

T =
real(Jg' * Pg_perp * Jg)

数值实现：

T =
0.5*(T+T.')

输出：

metric.Pg_perp
metric.T
metric.eigenvalues
metric.eigenvectors
metric.rank_T
metric.condition_T
metric.trace_T
metric.min_eigenvalue
metric.max_eigenvalue
metric.negative_eigenvalue_tolerance
metric.phase_factor

检查：

- Pg_perp Hermitian；
- Pg_perp idempotent；
- Pg_perp*g ≈ 0；
- T 为实对称；
- 负特征值只允许机器精度量级。

负特征值容差必须由：

eps
matrix dimension
norm(T,2)

决定。

不得通过固定绝对 floor 把真实负值裁为零。

============================================================
十一、非退化方向正式量
============================================================

对单位方向 v 定义：

q_dir =
v' * T * v

对 separation r：

q_r =
r^2 * q_dir

其中 r 使用 radian。

两列流形：

g_minus =
g(c-r*v/2)

g_plus =
g(c+r*v/2)

G2 =
[g_minus,g_plus]

------------------------------------------------------------
11.1 第二奇异值
------------------------------------------------------------

使用直接 SVD：

sigma =
svd(G2,'econ')

sigma2_sq =
sigma(2)^2

不得通过 det(G2'*G2) 或 2×2 行列式间接计算。

理论预测：

sigma2_pred =
0.5 * q_r

ratio：

sigma2_ratio =
sigma2_sq / sigma2_pred

------------------------------------------------------------
11.2 归一化相关性
------------------------------------------------------------

rho =
(g_minus' * g_plus) /
(norm(g_minus)*norm(g_plus))

若 abs(rho)>1：

- 只有超出 1 的量处于机器精度尺度时才允许裁到 1；
- 必须记录 coherence_roundoff_clipped_flag；
- 明显大于 1 时直接 FAIL。

理论预测：

coherence_deficit_pred =
q_r / norm(g_center)^2

实际：

coherence_deficit =
1 - abs(rho)^2

ratio：

coherence_ratio =
coherence_deficit / coherence_deficit_pred

------------------------------------------------------------
11.3 列归一化 Gram
------------------------------------------------------------

gbar_minus =
g_minus/norm(g_minus)

gbar_plus =
g_plus/norm(g_plus)

Gbar =
[gbar_minus,gbar_plus]

使用 SVD 或 Hermitian eig 计算：

cond_normalized_gram

同时验证精确恒等式：

cond_exact_rho =
(1+abs(rho))/(1-abs(rho))

只在分母可表示且未进入机器饱和时比较。

理论渐近预测：

cond_asymptotic =
4*norm(g_center)^2/q_r

ratio：

normalized_gram_ratio =
cond_normalized_gram/cond_asymptotic

------------------------------------------------------------
11.4 原始 Gram
------------------------------------------------------------

另报告：

raw_gram_condition
column_norm_minus
column_norm_plus
column_norm_ratio
column_norm_log_ratio

不得对未归一化 Gram 直接使用等范数公式。

============================================================
十二、统一 case 评价接口
============================================================

新增：

common/evaluate_secant_tangent_case.m

建议签名：

function row = evaluate_secant_tangent_case( ...
    center_deg, direction_unit_rad, separation_rad, model, opts)

每行至少包含：

config_id
center_az_deg
center_el_deg
direction_id
direction_az_component
direction_el_component
separation_norm_rad
separation_norm_deg
q_direction
q_at_separation
sigma1_sq
sigma2_sq
sigma2_prediction
sigma2_ratio
abs_rho
coherence_deficit
coherence_prediction
coherence_ratio
normalized_gram_condition
normalized_gram_exact_from_rho
normalized_gram_asymptotic
normalized_gram_ratio
raw_gram_condition
column_norm_minus
column_norm_plus
column_norm_ratio
taylor_sum_residual
taylor_difference_residual
numeric_floor
numeric_floor_reached_flag
coherence_roundoff_clipped_flag
Wseq_hash
Cseq_hash
Tseq_hash
fixed_measurement_hash
stage6_experiment_plan_hash
phase_factor
case_status

============================================================
十三、客观数值底噪和渐近尾区
============================================================

不得人工挑选 ratio 最接近 1 的点。

定义：

numeric_floor =
4096 * eps(class(g)) * norm(g_center)^2

一个 separation 点只有在：

sigma2_prediction > numeric_floor

且：

sigma2_sq > numeric_floor/4

时才作为 ratio 验收点。

其余点标记：

NUMERIC_FLOOR_REACHED

仍保存在 CSV 中，不得删除。

对每个：

config × center × fixed direction

按 separation 从小到大选择最小的 3 个有效点，
作为 registered asymptotic tail。

若不足 3 个有效点：

INSUFFICIENT_ASYMPTOTIC_TAIL

该 case 不得被算作通过。

主验收门：

max(abs(sigma2_ratio-1)) <= 0.02
max(abs(coherence_ratio-1)) <= 0.02
max(abs(normalized_gram_ratio-1)) <= 0.05

以上门只用于预注册 tail。

同时报告：

- ratio error 对 r 的 log-log slope；
- Taylor residual slope；
- 最小有效 r；
- 数值底噪开始位置。

不得通过经验重新拟合：

0.5
1
4

三个理论常数。

============================================================
十四、Taylor 和差残差
============================================================

定义方向导数：

g0,g1,g2,g3

对称和差列：

h1 =
(g_minus+g_plus)/sqrt(2)

h2 =
(g_plus-g_minus)/sqrt(2)

二阶/三阶预测：

h1_pred =
sqrt(2)*(g0 + r^2*g2/8)

h2_pred =
(r/sqrt(2))*(g1 + r^2*g3/24)

报告：

taylor_sum_residual =
norm(h1-h1_pred)/max(norm(h1),realmin)

taylor_difference_residual =
norm(h2-h2_pred)/max(norm(h2),realmin)

不得只验证最终 ratio 而不检查 Taylor 中间关系。

============================================================
十五、exact null、near-null 与非退化分类
============================================================

对 T 的特征值：

lambda_max
lambda_min

定义机器尺度 exact-null 阈值：

null_tol =
256 * max(size(T)) * eps(class(T)) * max(lambda_max,realmin)

分类：

A. EXACT_TANGENT_NULL

lambda_min <= null_tol

B. NEAR_TANGENT_NULL

lambda_min > null_tol
且
lambda_min/lambda_max < 1e-6

C. NONDEGENERATE_TANGENT

其余情况。

重要：

- near-null 仍然属于 q>0；
- near-null 在足够小 r 下仍应满足二次渐近式；
- 不得因为 q 较小便套用 exact-null 高阶公式；
- 不得通过人为阈值把 near-null 改成 exact null。

若所有实际完整顺序配置均无 exact null：

输出：

NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND

这不是失败。

不得为了得到 null 结果而在看完结果后重新选择波束。

============================================================
十六、exact-null 的三阶有效项
============================================================

这一部分是待验证扩展，不得在验证前写成已成立结论。

若：

q_dir = 0

则：

P_g_perp * g1 = 0

定义：

alpha =
(g0' * g1)/(g0' * g0)

定义候选三阶有效向量：

v3_eff =
P_g_perp * (g3/24 - alpha*g2/8)

在 v3_eff 非零时，待验证预测为：

sigma2_sq
~
0.5 * r^6 * norm(v3_eff)^2

定义：

null_sigma2_prediction =
0.5*r^6*norm(v3_eff)^2

null_sigma2_ratio =
sigma2_sq/null_sigma2_prediction

这一公式必须先在 synthetic analytic fixture 中验证，
再决定是否用于物理流形。

------------------------------------------------------------
16.1 必须新增 synthetic null 单元测试
------------------------------------------------------------

使用解析测试流形：

g(x,y) =
[1;
 x;
 y^3]

中心：

(0,0)

沿 y 方向：

v=[0;1]

此时：

T = diag(1,0)

并且精确有：

sigma2_sq = r^6/32

要求验证：

- exact tangent null 被正确识别；
- v3_eff 系数正确；
- null_sigma2_ratio 在有效尾区趋于 1；
- log(sigma2_sq) 对 log(r) 斜率在有效区间接近 6。

建议门：

abs(fitted_slope-6) <= 0.25
max(abs(null_sigma2_ratio-1)) <= 0.02

------------------------------------------------------------
16.2 物理 exact-null
------------------------------------------------------------

若某个预注册物理配置存在 exact null：

- 沿其最小特征向量执行同样分析；
- 计算 g1、g2、g3、alpha、v3_eff；
- 若 v3_eff 非零，验证六阶候选公式；
- 若 v3_eff 也为机器零，输出：
  HIGHER_THAN_SIXTH_ORDER_OR_EXACT_COLLAPSE
- 不得拟合任意经验常数。

若 only SINGLE_CHANNEL_DIAGNOSTIC 出现完全零流形维度：

- 只记录 EXACT_MEASUREMENT_COLLAPSE；
- 不把它包装成物理高阶分辨理论。

============================================================
十七、精确恒等式和不变性测试
============================================================

必须新增以下测试。

------------------------------------------------------------
17.1 两列 normalized-Gram 精确恒等式
------------------------------------------------------------

验证：

cond(Gbar'*Gbar)
=
(1+abs(rho))/(1-abs(rho))

在未数值饱和的场景中相对误差：

<=1e-10

这是精确恒等式，不是渐近验收。

------------------------------------------------------------
17.2 固定左酉换基不变性
------------------------------------------------------------

对固定随机酉矩阵 Q：

g_tilde = Q*g
J_tilde = Q*J

验证：

- T 不变；
- sigma2 不变；
- abs(rho) 不变；
- normalized Gram condition 不变。

相对误差：

<=1e-10

------------------------------------------------------------
17.3 固定复尺度不变性
------------------------------------------------------------

对非零复常数 beta：

g_tilde = beta*g

验证：

- sigma2_sq 与 q 同比例乘 abs(beta)^2；
- sigma2_ratio 不变；
- coherence ratio 不变；
- normalized Gram ratio 不变。

------------------------------------------------------------
17.4 angle-dependent phase gauge
------------------------------------------------------------

选择预注册线性 phase：

psi(phi,theta)
=
0.3*phi - 0.2*theta

其中 phi/theta 为 radian。

定义：

g_tilde =
exp(j*psi)*g

J_tilde =
exp(j*psi)*(J + j*g*grad(psi)')

验证：

- T 不变；
- 两端流形列只发生独立单位相位变化；
- sigma2 不变；
- abs(rho) 不变；
- normalized Gram condition 不变。

不得省略该测试，因为它能验证投影 Jacobian 确实去除了纯列相位方向。

============================================================
十八、场景与输出
============================================================

主正面证据只使用：

- whitening_rank >= 2；
- g(center) 非零；
- 固定完整顺序接收流形；
- 非退化固定方向；
- 预注册 measurement configs。

必须输出：

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

图片：

figures/sigma2_ratio_vs_separation.png
figures/coherence_ratio_vs_separation.png
figures/normalized_gram_ratio_vs_separation.png
figures/taylor_residual_vs_separation.png
figures/tangent_eigenvalue_map.png
figures/null_direction_order_fit.png
figures/column_norm_ratio_vs_separation.png

所有 CSV 至少包含：

phase_factor
fixed_measurement_hash
stage6_controls_hash
stage6_experiment_plan_hash
theory_status
prior_art_status
pass_flag

============================================================
十九、prior-art 增量报告
============================================================

新增：

results/stage6_prior_art_mapping.md

对每一项分别标记：

- 已有完全相同方法；
- 数学形式相似；
- 算法/证明机制相似；
- 只有问题场景不同；
- 暂未发现直接同式工作。

至少映射：

1. 中心–差分参数化；
2. 和差酉变换；
3. projected Jacobian metric；
4. sigma2 二次渐近式；
5. coherence deficit 二次渐近式；
6. normalized Gram condition 渐近式；
7. exact-null 三阶有效向量和六阶候选式；
8. 三式在固定白化顺序圆柱阵流形上的统一使用。

若检索到完全相同的三式和当前场景：

- 不删除数值工作；
- 但将理论贡献降级为复现/场景验证；
- 不得继续声称独立理论创新。

============================================================
二十、结果状态
============================================================

阶段 6 的总理论状态只允许：

THEORY_SUPPORTED_AS_SCENARIO_SPECIFIC_COROLLARY
THEORY_PARTIALLY_SUPPORTED
THEORY_REJECTED
NUMERICAL_VALIDATION_INCOMPLETE

子状态至少包括：

NONDEGENERATE_ASYMPTOTIC_SUPPORTED
NONDEGENERATE_ASYMPTOTIC_FAILED
INSUFFICIENT_ASYMPTOTIC_TAIL
NUMERIC_FLOOR_REACHED
EXACT_TANGENT_NULL
NEAR_TANGENT_NULL
NO_EXACT_PHYSICAL_TANGENT_NULL_FOUND
SYNTHETIC_NULL_SIXTH_ORDER_SUPPORTED
PHYSICAL_NULL_SIXTH_ORDER_SUPPORTED
HIGHER_THAN_SIXTH_ORDER_OR_EXACT_COLLAPSE
CENTER_MANIFOLD_NUMERICALLY_ZERO
MEASUREMENT_WHITENING_FAILED

本阶段是确定性理论/数值验证，不使用：

confidence
posterior
probability
statistical calibration

统一写：

statistical_scope =
DETERMINISTIC_GEOMETRIC_VALIDATION

============================================================
二十一、测试文件
============================================================

至少新增：

tests/test_stage6_fixed_measurement_registry.m
tests/test_stage6_measurement_hash_freeze.m
tests/test_stage6_first_derivatives.m
tests/test_stage6_higher_directional_derivatives.m
tests/test_projected_metric_properties.m
tests/test_two_column_exact_identity.m
tests/test_secant_tangent_nondegenerate.m
tests/test_synthetic_tangent_null.m
tests/test_physical_tangent_null.m
tests/test_geometry_invariances.m
tests/test_column_norm_asymmetry.m
tests/test_stage6_scope_rules.m
tests/verify_stage5_frozen_results.m
tests/verify_step11_frozen_results.m

scope test 必须禁止：

- PhaseFactor=2；
- fixed 1e-10 ridge；
- 2×2 Gram determinant score；
- denominator floor；
- 删除 null 样本；
- candidate-dependent Wseq；
- candidate-dependent whitener；
- 用阶段 4 Xphi 作为主理论流形；
- 用条件 Gphi 代替完整 Gseq；
- C05；
- topK；
- score-gap；
- 经验拟合 0.5、1、4 三个理论常数；
- 看到结果后改变 separation ladder；
- 只保存通过样本。

============================================================
二十二、阶段 5 非阻塞问题的处理边界
============================================================

本轮不重新运行或修改阶段 5 算法。

可以在文档中保留以下已知边界：

- 44.95% 是相对注册的两初值直接 AP；
- 当前主要复杂度证据是 score calls，不是完整 wall-clock；
- 相干弱目标仍为 0/200 失败边界；
- Q/Kq 为 oracle。

这些内容与阶段 6 几何定理无关。

不得因为阶段 5 stress 失败而修改阶段 6 流形、波束或方向计划。

============================================================
二十三、技术验收门
============================================================

全部满足才可 PASS。

A. 固定测量合同

- 所有 active 配置 phase_factor=1；
- Wseq/Cseq/Tseq 在每个配置内固定；
- 候选角变化期间 hash 不变；
- Tseq*Cseq*Tseq' 白化误差通过；
- 阵元 permutation 与阶段 5 一致；
- 阶段 5 和 Step11 冻结结果未改变。

B. 导数

- 一阶导数最大相对误差 <=1e-6；
- 一阶流形/J 与阶段 5完整流形函数一致；
- 二阶方向导数 <=1e-4；
- 三阶方向导数 <=1e-3，或将 null 高阶部分判为 PARTIAL；
- 导数单位全部为 per-radian。

C. 投影几何

- P Hermitian/idempotent；
- P*g 接近 0；
- T 对称；
- T 的负特征值仅机器精度量级；
- q_direction 与 norm(P*J*v)^2 一致。

D. 精确恒等式

- normalized Gram 与 rho 精确恒等式相对误差 <=1e-10；
- 左酉换基、固定复尺度和 angle-dependent phase gauge 测试通过。

E. 非退化渐近式

对所有预注册 primary nondegenerate cases：

- 至少存在 3 个有效 asymptotic-tail 点；
- sigma2 ratio tail 误差 <=2%；
- coherence ratio tail 误差 <=2%；
- normalized Gram ratio tail 误差 <=5%；
- Taylor 中间残差随 r 减小；
- 不使用经验常数修正；
- 不删除未通过 case。

F. null 边界

- synthetic null 的 slope 接近 6；
- synthetic null 六阶 ratio 通过；
- 物理配置没有 exact null 时明确报告，而不是制造 null；
- near-null 不被误写成 exact null；
- 不使用 denominator floor。

G. prior-art 和论文边界

- 理论主张定位为场景化显式推论；
- 几何公式和有限样本性能明确分开；
- 不用相干弱目标失败验证/否定纯几何公式；
- prior-art 增量报告完成。

============================================================
二十四、否决或降级条件
============================================================

出现以下任一项必须 FAIL、PARTIAL 或降级：

1. 一阶解析导数不通过；
2. 固定 measurement hash 随候选角变化；
3. 非退化 ratio 只有通过重新拟合常数才接近 1；
4. 只有删除部分中心/方向后结果才成立；
5. 只有手工选择 separation 点后结果才成立；
6. normalized Gram 使用未归一化列却套用等范数公式；
7. coherence 明显超过 1 后被静默裁剪；
8. exact null 和 near-null 被混淆；
9. null 样本被删除；
10. 三阶导数未验证却声称六阶定理成立；
11. 使用条件方位 Gphi 替代最终完整 Gseq；
12. 随候选角重建波束或白化器；
13. prior-art 找到完全同式工作后仍声称首次提出；
14. Step11、阶段 4 或阶段 5 结果被覆盖；
15. 为通过测试重新引入 ridge、floor、topK、gap 或场景规则。

若：

- 非退化三式通过；
- exact-null 高阶部分未通过或物理流形无 exact null；

可以判：

THEORY_PARTIALLY_SUPPORTED

并保留非退化主定理，不得强行把 null 扩展包装成已完成贡献。

============================================================
二十五、论文与文档修改
============================================================

只有阶段 6 验收通过后，才更新：

1. beamspace_ml_v18/paper/full_manuscript_v0.19_sequential_dbf_revision.md
2. beamspace_ml_v18/review/supporting_notes/sequential_revision_scope.md
3. beamspace_ml_v18/source/stepwise_signal_model/README.md
4. innovation-mining/11_sequential_beamspace_ml_innovations_theory.md
5. innovation-mining/12_experiment_system_code_structure_roadmap.md
6. innovation-mining/13_next_step_execution_prompts.md

另新增：

innovation-mining/15_stage6_tangent_theory_validation_audit.md

该审计文档必须包含：

- 最终通过的公式；
- 未通过或降级的公式；
- 正式假设；
- 单位；
- 固定 measurement contract；
- prior-art 标签；
- exact-null 是否存在；
- 六阶扩展是否通过；
- 不适用范围；
- 全部结果文件路径和 hash。

若常数或公式被验证为错误：

- 必须修正编号 11；
- 保留原式和修正原因的审计记录；
- 不允许只改代码、不改理论文档。

论文中不得写：

- 已证明有限样本可分辨；
- 已解决低 SNR threshold；
- 已解决强相干；
- 已完成 K1/K2 判定；
- 已证明所有方向可辨；
- 首次提出经典投影 FIM。

============================================================
二十六、运行与复现
============================================================

统一入口：

run_step12_4_tangent_asymptotics_validation.m

建议 MATLAB 命令：

matlab -batch "cd('E:/bs_innovation'); run('beamspace_ml_v18/source/stepwise_signal_model/steps/step_12_4_near_pair_tangent_asymptotics/run_step12_4_tangent_asymptotics_validation.m');"

必须运行：

- 统一 runner；
- MATLAB Code Analyzer；
- stage6 scope scan；
- CSV schema scan；
- measurement hash consistency scan；
- stage5 result hash/关键数值复核；
- Step11 冻结 SHA-256 复核；
- git diff --check。

不得仅运行单个正面 case 便宣布通过。

============================================================
二十七、最终 A–J 报告
============================================================

最终回答必须包含：

A. 阶段结论

- PASS / PARTIAL / FAIL
- theory status
- 非退化三式是否通过
- exact-null 六阶扩展是否通过
- 是否允许进入阶段 7

B. 阅读范围和 prior-art 边界

- 检查过的文献/公式
- 每项 prior-art 标签
- 是否发现直接同式工作

C. 文件清单

- public
- private
- test-only
- results
- figures
- 文档修改

D. 公式到代码映射

- g/J
- T
- sigma2
- coherence
- normalized Gram
- exact-null v3_eff
- fixed measurement hash

E. 维度、单位和固定对象

- Wseq
- Cseq
- Tseq
- g
- Jg
- G2
- T
- radian/degree
- measurement configs

F. 测试和命令

- MATLAB 命令
- Code Analyzer
- hash 检查
- scope 检查
- frozen evidence 检查

G. 关键结果

- derivative errors
- T eigenvalues
- primary ratios
- asymptotic-tail point counts
- exact identity errors
- invariance errors
- synthetic null slope
- physical null status
- 不提供不存在的统计置信区间

H. 复杂度

- 流形评价次数
- SVD 次数
- eig 次数
- derivative evaluations
- runtime
- memory
- figure/data volume

I. 风险和未完成项

- exact null 是否存在
- near-null 数值范围
- 有限样本性能不在本阶段
- prior-art 检索边界
- FIM 波束选择未开始

J. 下一阶段判定

只有满足：

- 固定 measurement contract；
- 非退化三式通过；
- prior-art 边界正确；
- null 边界未被掩盖；

才能写：

“技术上允许后续单独授权进入阶段 7。”

无论 PASS、PARTIAL 还是 FAIL，本轮必须停止。
```

# 阶段 7：系统特化设计——相关顺序波束 exact-subset FIM 与最小局部波束集

> **执行完成（2026-07-18）：`PASS_SYSTEM_ANALYSIS_ONLY`。** 冻结计划 hash 为 `e630a084e68108a1604527afe7a81db7150b045454b3f54b05e6cfd389259a3b`。961/961 个矩形子集和 1184 个 FIM 场景已完整评估；`eta0=0.80` 的 exact 解为 `RECT_E14_A31`，但与最强固定 `FIXED_RECT_3X5` 是同一物理子集。`eta0=0.90/0.95` 不可行，有限样本 Pareto 为 0/3。下面的提示词保留为历史执行合同，不得直接重跑或据此进入阶段 8。

## 目标

用 exact subset covariance/FIM 替换旧三项 W-score，明确已有 prior art，并通过有限样本风险二阶段验收。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.5：相关顺序规则波束库的 FIM 保真最小局部波束集设计。

前置：阶段 6 非退化方向理论验证通过；否则停止。

必读：
- 11 文档第 8、9、12 节
- 12 文档 Step12.5
- 06_formula_prior_art.md 的 F09–F13
- 06_algorithm_prior_art.md 的 A06–A08 和 threshold failure
- 06_closest_work_matrix.md 的 W2–W5
- Chepuri–Leus arXiv:1310.5251
- Pakrooh 2015 arXiv:1504.01081
- Pakrooh 2016 arXiv:1505.07431
- 刘旗等 2026 DOI 10.12000/JR25173

先生成 results/fim_prior_art_difference.md，明确：
- 归一化 FIM 已有；
- 最少选择 + FIM 约束已有；
- CRB 保真 BML 已有；
- 当前差异是相关噪声、实际顺序规则波束、结构化成本和近双目标风险验证。

实现：
1. build_sequential_beam_candidate_pool.m
2. select_physical_beam_subset.m
3. build_subset_noise_covariance.m
4. whiten_subset_manifold.m
5. effective_deterministic_fim.m
6. compute_element_domain_fim.m
7. relative_fim_retention.m
8. sequential_dbf_cost.m
9. enumerate_exact_subset_design.m
10. greedy_exchange_exact_subset_design.m

强制公式：
z0=W0'*y
C0=W0'*Rn*W0
zI=SI*z0
CI=SI*C0*SI'
GI=SI*W0'*A
TI=pinv_sqrt(CI)
GwI=TI*GI

每个子集变化必须重新计算 CI、rank、TI、Gw、derivatives 和 FIM。
禁止假设 F(I)=sum Fm，除非另行证明当前物理成本与固定白化坐标下满足可加条件。

设计：
eta(I)=min_scenario lambda_min_plus(Felem^(dagger/2)*FI*Felem^(dagger/2))
min cost(I_e,I_a) s.t. eta>=eta0

成本分别报告：
- B_e*Nphi*Nz；
- B_e*B_a*Nphi；
- B_e*B_a outputs；
- memory/data movement；
- measured runtime。
不要用人工权重重新构造综合评分。

求解：
- 小池穷举；
- 大池 exact-FIM greedy add/drop/pair-swap；
- 连续 SVD 仅上界；
- Chepuri–Leus 仅独立观测参考，未证明等价时不能称下界或可行解。

Baselines：
固定 3/5/7/... 波束、old B7、刘旗 2026、Chepuri–Leus 参考、exact greedy、exchange、穷举、连续上界。

二阶段验收：
A. eta/FIM/CRB/rank/cost；
B. oracle-K success、Wilson/配对区间、threshold SNR、wrong local peak、unconditional error、weak/coherent subgroup、mismatch、runtime/memory/bandwidth。

本阶段不执行 K1/K2 模型阶数、bootstrap、false split、missed split、false resolved 或 resolved/unresolved 指标。

数据严格分为 design、validation、normal_holdout、threshold_holdout、mismatch_holdout。

输出：
results/subset_covariance_validation.csv
results/fim_subset_enumeration.csv
results/fim_subset_validation.csv
results/finite_sample_normal_holdout.csv
results/finite_sample_threshold_holdout.csv
results/finite_sample_mismatch_holdout.csv
results/finite_sample_stress_holdout.csv
results/fim_vs_finite_sample_risk.csv
results/fim_subset_pareto.csv
results/fim_baseline_reproduction_status.csv
results/stage7_keypoints.csv
results/stage7_fim_beam_design_report.md

否决：
- 只有逐束可加假设下有效；
- eta holdout 不稳定；
- 相同 eta 的有限样本风险严重不同且无法筛别；
- 相比固定相邻波束无收益；
- 只能重复已有 CRB 保真 BML；
- 失败后不得恢复 alpha/beta/gamma 或 C05；
- 完成后停止。
```

# 阶段 7.1A：Stage7 收束审计工具（code-only）

> **执行状态（2026-07-18）：Stage7.1 code tools implemented, closure rerun pending。**

本子阶段只修复 Stage7 可复现合同并实现隔离的只读收束工具：历史 baseline
改为祖先约束，正式运行入口增加干净工作树门，source/dependency 使用 Git
`mode/blob/path` manifest，runtime HEAD 不进入稳定 hash。另实现顺序 3/5
通道语义、物理子集 alias、`eta0=0.80` 最小成本可行族、既有有限样本 Pareto
敏感性、修正复杂度记账和固定边缘诊断计划。

本状态没有重跑 Stage7 长流程，没有生成新 trial、CSV 或 PNG，没有改变
Stage7 exact operating point、tie-break、FIM/DML/有限样本公式或
`PASS_SYSTEM_ANALYSIS_ONLY` 主结论。Stage7.1B closure rerun 只能在后续单独
授权下执行；本状态不授权阶段 8。

# 阶段 8：K1/K2 bootstrap、`K2_UNRESOLVED` 与 false-resolved 控制

> **当前状态：`NOT_AUTHORIZED_BY_STAGE7_RESULT`。** 阶段 7 没有通过有限样本 Pareto 门；本阶段不得自动执行。

## 目标

实现已有 bootstrap/source-resolution 机制在新顺序 DML 链上的校准，控制 false split 和 false resolved；不做 K3。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.6：K1/K2 parametric-bootstrap DML 阶数判定和 resolved/unresolved 状态。

必读：
- 11 文档第 10、12 节
- 12 文档 Step12.6
- 06_formula_prior_art.md 的 F14/F15
- 06_algorithm_prior_art.md 的 A09/A10 和失败机制
- bootstrap source enumeration 2013
- Self & Liang 1987
- GLRT statistical resolution-limit 文献

实现：
1. fit_local_model_k.m
2. nested_dml_likelihood_ratio.m
3. calibrate_parametric_bootstrap_lrt.m
4. lookup_locked_lrt_threshold.m
5. bootstrap_separation_confidence.m
6. classify_local_cluster_state.m

K1/K2 每个 bootstrap 样本必须完整重拟合，不能只在固定真值或原估计处评分。

优先离线 calibration：
- 在锁定配置网格上执行 Bboot；
- validation 后冻结 threshold table；
- holdout/online 只查表；
- 若逐样本 bootstrap，单独报告延迟。

主状态仅允许：
K1
K2_RESOLVED
K2_UNRESOLVED
GROUP_UNIDENTIFIABLE
OUT_OF_LOCAL_CELL
SEARCH_NOT_CONVERGED
MODEL_MISMATCH
NUMERIC_RANK_DEFICIENT

数据：
K1 calibration/validation/independent holdout；
K2 validation/independent holdout；
threshold holdout；
mismatch holdout。

指标必须包括：
- false_split_rate_K1 和上置信界；
- missed_split_rate_K2；
- false_resolved_rate；
- resolved/unresolved rate；
- K1 vs K2_UNRESOLVED confusion；
- separation CI coverage；
- unconditional penalized error；
- conditional RMSE only as secondary；
- mismatch wrong-confidence；
- runtime/bootstrap refits。

Baselines：
AIC、MDL、bootstrap source enumeration、nested DML bootstrap、known-K oracle、GLRT/Rao resolution reference、no-unresolved ablation。

禁止：
- 按场景设置多个 score-gap 阈值；
- 在 holdout 调阈值；
- 用 unresolved 排除困难样本后只报告 resolved RMSE；
- 恢复 C05 或旧 W/B 停机。

验收：
- K1 false split 及其上界受 alpha 控制；
- false resolved 受控；
- K2_UNRESOLVED 不与 K1 大量混淆；
- 模型失配不频繁输出错误 K2_RESOLVED；
- 计算成本透明；
- 完成后停止。
```

# 阶段 9：K1/K2 全链集成、配置锁定与 prior-art-aware 论文重写

## 目标

整合已经独立通过的模块，锁定配置，在独立 holdout 上形成最终证据，并按修订后的贡献层级重写论文。任何未通过模块不得靠集成掩盖。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.7/Step12.9 K1/K2 全链集成和最终证据汇总。

前置：阶段 1–8 的对应通过项必须有独立报告。列出未通过项；未通过时不要强行整合为正面主张。

统一入口建议：
run_step12_sequential_grouped_bml.m

主链：
receive factor=1
→ sequential DBF
→ local conventional cell
→ elevation group identifiability/order
→ conditional azimuth DML
→ full sequential joint refinement
→ K1/K2 calibrated decision
→ resolved/unresolved/status
→ selected fixed beam set

配置锁定：
- beam set；
- local cell definition；
- DML tolerances；
- rank tolerances；
- AP/PR/multi-start budget；
- bootstrap threshold table；
- resolved criterion；
- all seeds/splits。

最终比较：
- conventional DBF；
- local full DML；
- AP-DML；
- PR-DML；
- old controlled pair2d；
- grouped-only/no-refine；
- direct coordinate ascent；
- gridless/SBL；
- required beam-selection baselines；
- model-order baselines。

必须输出完整复杂度：
sequential DBF ops/channels；
score calls；
SVD dimensions；
iterations；
multi-start；
K1/K2 fits；
bootstrap calibration cost；
FIM design cost；
runtime/memory。

论文重写时贡献只能写为：
1. 实际顺序 DBF 接口下的可辨俯仰组—条件方位 DML—完整顺序流形修正组合；
2. 固定白化顺序二维流形的 sigma2–correlation–normalized-condition 显式局部推论；
3. 已有 FIM 框架在相关规则顺序波束和结构化成本下的系统特化设计；
4. bootstrap/unresolved 作为风险控制支撑机制。

主动引用并说明：
DML、AP、PR-DML、归一化 FIM、Chepuri–Leus、刘旗 2026、bootstrap source enumeration、statistical resolution limit 均已有。

输出：
results/final_normal_holdout.csv
results/final_threshold_holdout.csv
results/final_mismatch_holdout.csv
results/final_method_budget_pareto.csv
results/final_status_confusion.csv
results/final_keypoints.csv
results/final_claim_formula_code_data_mapping.md
results/final_prior_art_difference_matrix.md
results/final_report.md
paper/v0.19_draft_or_revision_notes.md

停止条件：
- 同预算不优于 AP/PR/local full；
- 主要收益来自真值泄漏；
- 多初值抵消复杂度；
- FIM 设计无有限样本收益；
- false split/false resolved 失控；
- unresolved 隐藏主失败；
- 最终只能说明已有模块串联且无系统收益。

完成后停止，不自动做 K3、cache、提交或推送。
```

# 阶段 10A：可选 K3 有限扩展

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

仅在 K1/K2 主线正式通过后执行 Step12.8 K3 有限扩展。

目标不是任意多目标，而是验证分组结构对 K=3 可运行。

场景固定为：
1. three_distinct_elevation_groups
2. two_same_el_one_different
3. same_el_three_azimuths
4. one_weak_target
5. two_coherent_plus_one

实现：
- max_k=3；
- Q 与 Kq 的组合；
- K2→K3 bootstrap 可先作为探索；
- PR-DML/AP-DML/gridless baseline；
- 小网格 local full K3 仅用于可承受子集。

必须区分：
- 代码能运行；
- 估计成功；
- 模型阶数成功；
- 是否有理论保证。

不得把探索结果直接写成“支持任意多目标”。完成后停止。
```

---

# 阶段 10B：cache、运行时间与硬件映射

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

仅在算法冻结后执行 Step12.9 cache/runtime。cache 不得影响估计公式和创新主张。

缓存候选：
- g(az,el)
- dg/daz
- dg/del
- fixed Wseq whiteners
- FIM 基础项

必须在 cache key 中包含：
phase_factor
lambda
geometry_hash
element_order_hash
window_hash
beam_set_id
noise_model_id
grid/interpolation version

验证：
- direct/cache manifold；
- derivatives；
- DML score/RSS；
- FIM；
- final estimate/state；
- cache build amortization；
- memory；
- runtime。

配置变化必须触发 cache invalidation。

cache 只写成软件实现贡献。完成后停止。
```

---

# 11. 用于审查某个阶段结果的统一复核提示词

```text
默认仓库 makabaka165/bs_innovation。

请作为独立审查者，只审查刚完成的 Step12 阶段，不修改代码。

必须阅读：
- 10_current_paper_innovation_audit.md
- 11_sequential_beamspace_ml_innovations_theory.md
- 12_experiment_system_code_structure_roadmap.md
- 对应阶段 README、源码、测试、CSV、报告
- 上一阶段报告

逐项检查：
1. 公式是否被准确实现；
2. degree/radian 是否混用；
3. 阵元顺序和数据维度是否一致；
4. phase factor 是否全部为 1；
5. 是否偷偷调用旧 ridge、C05、topK 或旧 B7；
6. 是否存在真值泄漏；
7. 是否在 holdout 调参；
8. 结果图是否硬编码；
9. 失败子组是否被隐藏；
10. 是否超过当前阶段范围；
11. 与文献已有方法是否重叠；
12. 是否满足进入下一阶段的硬条件。

输出：
- Pass/Risk/Fail 总结；
- 公式–代码–测试–数据映射表；
- blocking issues；
- 非阻塞改进；
- 是否允许进入下一阶段。

不要因为结果“看起来不错”而放宽验收标准。
```

---

# 12. 用于防止 AI 一次性过度修改的约束提示词

当 AI 倾向于一次改完所有内容时，追加：

```text
本次只允许完成当前阶段。禁止：
- 提前实现后续创新；
- 删除旧路线；
- 重写整个仓库；
- 大规模移动文件；
- 在没有测试时把 common 函数提升到 core；
- 同时修改算法、实验、论文和 cache；
- 通过新增阈值或分支解决失败；
- 自动提交、推送或创建 PR。

如果发现后续阶段所需问题，只记录到 current_stage_open_issues.md，不实现。
```

---

# 13. 最终使用顺序

在正式执行阶段 0 前，先确认仓库中的 11、12、13 已替换为本修订版，并保留 06 三份 prior-art 文档。每个阶段只在上一个阶段明确“可以进入下一阶段”后继续。阶段 4、6、7、8 是四个强制否决门，不允许跳过。

推荐逐个执行：

```text
阶段 0  仓库盘点和冻结
阶段 1  factor=1 与术语
阶段 2  顺序 DBF
阶段 3  稳定 DML
阶段 4  俯仰组 DML
阶段 5  条件方位 + 联合修正
阶段 6  切向定理
阶段 7  FIM 波束预算
阶段 8  K1/K2 bootstrap
阶段 9  集成与论文
阶段 10 K3/cache（可选）
```

截至 2026-07-18，执行已停在阶段 7。阶段 7 的技术实现通过，但算法贡献门未通过，状态为 `PASS_SYSTEM_ANALYSIS_ONLY`；阶段 8 及以后不是当前允许的下一步。

核心停止点：

- 阶段 2 不通过：顺序工程模型不成立，停止算法创新；
- 阶段 3 不通过：评分器不可信，停止；
- 阶段 5 不通过：创新点 1 不成立或需重新定义；
- 阶段 6 不通过：创新点 2 的理论基础不成立，停止 FIM 路线；
- 阶段 7 不优于最强固定矩形：记录 FIM 路线边界并降级为系统分析，不恢复经验 W-score；该条件已触发；
- 阶段 8 false split 不受控：不能宣称未知目标数能力；
- 阶段 9 不具 Pareto 优势：重新定位为工程模型/负结果，不叠加规则。

该执行顺序的目的，是让每个创新点都有独立可否证证据，而不是再次形成规则、缓存和工程包装串联起来的主张。
