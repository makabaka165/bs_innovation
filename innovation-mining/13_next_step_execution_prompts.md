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
```

---

# 阶段 4：核心创新点 1A——俯仰目标组 DML 与可辨识性

## 目标

在 Q 已知的 oracle 条件下验证俯仰分组估计和组数据恢复。当前阶段不自动选择 Q，不进入 FIM。

## 可直接复制的提示词

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

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.3 子阶段 D/E：条件方位单/多目标 DML和完整顺序流形联合修正。Q 与每组 Kq 已知，不做模型阶数。

必读：
- 11 文档第 5.6、6、12 节
- 12 文档 Step12.3 和复杂度要求
- 06_algorithm_prior_art.md 的 A03–A05、复杂度和失败机制
- Ziskind–Wax AP 与 PR-DML 最近工作说明
- 阶段 4 全部结果

实现：

1. common/build_conditional_azimuth_manifold.m
   方位流形必须包含 cos(eta)，并使用固定物理方位波束与固定白化器。

2. common/estimate_conditional_azimuth_dml.m
   function [est,debug] = estimate_conditional_azimuth_dml(...)
   - Kq=1 一维 DML；
   - Kq=2 小局部 full reference/AP；
   - SVD score/RSS；
   - 输出 num_score_eval、num_svd、rank、runtime。

3. common/estimate_conditional_azimuth_prdml.m
   准确复现 PR-DML 或明确记录无法复现的公式/接口缺口，不能使用自定义简化版冒充。

4. common/build_full_sequential_local_manifold.m
   直接使用固定 Wseq' * a(az,el) 和固定 whitener，不使用独立一维近似。

5. common/refine_joint_sequential_dml.m
   - 目标 canonical order；
   - 逐目标、逐维最大化；
   - 每步 score 不下降；
   - 记录 angle update、score/RSS、候选数；
   - relative-score + max-angle 双停止条件；
   - max_iter 未收敛返回 SEARCH_NOT_CONVERGED；
   - 不按场景扩窗；
   - 多初值 R 全部计入成本。

6. common/match_target_sets.m
   使用 Hungarian/最小总角度代价，评价和搜索分离。

必须比较：
- local full DML；
- AP-DML；
- PR-DML；
- 不分组直接二维坐标上升；
- 仅分组条件估计、不联合修正；
- old controlled pair2d；
- common-el；
- 常规 DBF；
- Kim 2012 准确实现或明确缺口。

公平预算：
- 同一物理角域；
- 相同 K 先验；
- 相同 score-call 或 wall-time；
- 记录 SVD 次数、矩阵尺寸、迭代、多初值；
- 不允许分组方法获得更窄且包含真值的候选域。

场景：
Q2/K1+K1、Q1/K2 同俯仰、两维均近、初值偏差、功率失衡、相干、边界、模型失配。

输出：
results/conditional_azimuth_trial.csv
results/joint_refinement_history.csv
results/method_budget_comparison.csv
results/method_score_gap.csv
results/wrong_local_peak_summary.csv
results/grouped_conditional_dml_keypoints.csv
results/grouped_conditional_dml_report.md

验收：
- 单调性违规为 0；
- 函数值收敛、角度收敛、正确解收敛分别报告；
- 同俯仰 K2 由条件方位处理；
- 同预算下接近或优于 local full/AP/PR 的 Pareto 前沿；
- 大量多初值导致成本不低于 full DML 时，降级为初始化方法；
- 收益来自真值泄漏候选域时否决；
- 完成后停止，不进入切向理论或 FIM。
```

# 阶段 6：核心创新点 2——固定白化顺序流形的近双目标渐近验证

## 目标

验证显式近双目标推论、正式假设和零方向边界；不选择波束，不把经典投影 FIM 改名为新理论。

## 可直接复制的提示词

```text
[附上“所有阶段共同使用的总约束”]

执行 Step12.4：解析导数、投影 Jacobian 几何量和近双目标 sigma2/coherence/normalized-Gram 统一渐近式验证。

必读：
- 11 文档第 7 节
- 12 文档 Step12.4
- 06_formula_prior_art.md 的 F04–F08 和第 4 节
- array-manifold differential geometry、near-source CRB、statistical resolution limit 的已定位文献

固定条件：
- 每个配置固定 Wseq、beam indices、noise covariance、whitener 和 whitening rank；
- 候选角变化不能重建观测或白化器；
- 保存这些对象的 hash。

实现：
1. build_receive_cyl_manifold_derivatives.m
2. build_fixed_whitened_sequential_derivatives.m
3. compute_projected_jacobian_metric.m
4. evaluate_secant_tangent_case.m
5. analyze_tangent_null_directions.m

非退化方向 q=d'*T*d>0 计算：
- sigma2_ratio；
- coherence_ratio；
- normalized_gram_ratio；
- raw Gram condition；
- column norm ratio；
- Taylor residual。

零方向专项：
- 扫描 T 最小特征向量；
- q 近零时禁止使用二次 ratio；
- log-log 拟合 sigma2^2 高阶斜率；
- 检查二阶/三阶导数；
- 不删除零方向样本；
- 不使用 denominator floor 或经验常数修复。

场景：
至少 9 个中心；纯方位、纯俯仰、正/负斜方向；多个规则波束集；分离尺度逐次减半；factor=1；避开浮点噪声区。

必须区分：
- G2 的几何定理；
- 含 S、功率比、相干性和有限 L 的有效 FIM/估计性能。

输出：
results/derivative_validation.csv
results/tangent_eigenvalues.csv
results/secant_tangent_nonzero_direction.csv
results/secant_tangent_null_direction.csv
results/column_norm_asymmetry.csv
results/tangent_theory_keypoints.csv
results/tangent_theory_prior_art_mapping.md
results/tangent_theory_validation.md
figures/*.png

验收：
- 导数相对误差 <=1e-6；
- T 负特征值仅机器精度；
- 非退化方向三个 ratio 在明确小量区趋于 1；
- 零方向边界和高阶行为被报告；
- 若常数只能经验拟合或固定白化条件不成立，停止并否决当前定理形式；
- 完成后停止。
```

# 阶段 7：系统特化设计——相关顺序波束 exact-subset FIM 与最小局部波束集

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
B. threshold SNR、wrong local peak、K1 false split、K2 missed split、false resolved、unconditional error、weak/coherent subgroup、runtime/memory/bandwidth。

数据严格分为 design、validation、normal_holdout、threshold_holdout、mismatch_holdout。

输出：
results/subset_covariance_validation.csv
results/fim_subset_design.csv
results/fim_subset_validation.csv
results/fim_subset_normal_holdout.csv
results/fim_subset_threshold_holdout.csv
results/fim_subset_mismatch_holdout.csv
results/fim_vs_finite_sample_risk.csv
results/beam_cost_pareto.csv
results/fim_baseline_comparison.csv
results/fim_beam_budget_keypoints.csv
results/fim_beam_budget_report.md

否决：
- 只有逐束可加假设下有效；
- eta holdout 不稳定；
- 相同 eta 的有限样本风险严重不同且无法筛别；
- 相比固定相邻波束无收益；
- 只能重复已有 CRB 保真 BML；
- 失败后不得恢复 alpha/beta/gamma 或 C05；
- 完成后停止。
```

# 阶段 8：K1/K2 bootstrap、`K2_UNRESOLVED` 与 false-resolved 控制

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

核心停止点：

- 阶段 2 不通过：顺序工程模型不成立，停止算法创新；
- 阶段 3 不通过：评分器不可信，停止；
- 阶段 5 不通过：创新点 1 不成立或需重新定义；
- 阶段 6 不通过：创新点 2 的理论基础不成立，停止 FIM 路线；
- 阶段 7 holdout 不通过：记录 FIM 路线边界，不恢复经验 W-score；
- 阶段 8 false split 不受控：不能宣称未知目标数能力；
- 阶段 9 不具 Pareto 优势：重新定位为工程模型/负结果，不叠加规则。

该执行顺序的目的，是让每个创新点都有独立可否证证据，而不是再次形成规则、缓存和工程包装串联起来的主张。
