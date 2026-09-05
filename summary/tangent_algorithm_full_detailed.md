# Raw Tangent Core 算法与评价合同详解

本页解释本实验分支的 `TANGENT_PROFILE_CORE`。权威执行合同为 [57 协议](../innovation-mining/57_stage8_k2_raw_tangent_core_native_snr_theory_and_protocol.md)，活跃实现为 [Raw Tangent 工具](../tools/stage8_k2_raw_tangent_core_native_snr/README.md)。旧 Safe 的历史证据保留在 43-48；已删除路线的详细旧说明仍可在 main@644fc6e 的 Git 历史查看。

## 1. 观测与科学问题

已知同一个 CPI、同一个距离-多普勒单元含两个目标，估计各自的 [azimuth, elevation]。本轮不估计 K，不使用跨 CPI 跟踪，不引入在线成功门限。

物理阵元工作子阵含 M=2080 个阵元。当前完整流形 A、固定波束矩阵 W_I 和白化矩阵 T_I 的数学不变：

$$
X_e=A(\Theta)S,\quad X_w=T_IW_I^HX_e,\quad Z=X_w+N_w.
$$

只有 PRIMARY_RECT_E14_A31 + WHITE 被构造。W_I 列数为 15，T_I 尺寸为 15 x 15，白化秩为 15，phase factor 为 1。Element 参考组独立构造 Y_e=X_e+N_e。不得从 Z 逆重建或伪造阵元观测。

## 2. 原生域噪声

$$
\gamma=10^{\gamma_{dB}/10},\qquad
\sigma_w^2=\frac{\|X_w\|_F^2}{15L\gamma},\qquad
\sigma_e^2=\frac{\|X_e\|_F^2}{2080L\gamma}.
$$

两域分别生成 IID circular complex Gaussian 噪声，每个复样本的总方差为 sigma^2。标称 SNR 的最大误差要求不超过 1e-12 dB。实际 SNR 由信号与当次噪声能量之比得出，自然波动。

每个 L x Profile x replicate 具有唯一 base_realization_index。source、Beamspace noise、Element noise 使用不同 seed base，跨七个 SNR 点复用相同底样本。源相关幅度与次目标功率保持 P1-P4 合同；L=1 的相关幅度为 1。

## 3. 完整流形集中 DML

对请求秩 K 的白化流形 G：

$$
\operatorname{RSS}(G)=\|P_G^\perp Z\|_F^2,\quad
\widehat\sigma^2=\operatorname{RSS}/(15L),
$$

$$
\ell_c(G)=-15L\left[\log(\pi\widehat\sigma^2)+1\right].
$$

稳定 SVD 与秩判定由现有 concentrated_dml_rss 内核完成。只有满足请求秩、有限 RSS 和有限 likelihood 的候选有效。真实目标角度、Profile、SNR、波束宽度和成功阈值都不参与候选生成或评分。

Core 内部将 Z 除以其 Frobenius 范数，使浮点优化比较更稳定；返回时把 RSS 和 trace score 乘回尺度平方，把集中 likelihood 减去对应常数。此整体变换不改变精确 DML 极值点，不归一化当次生成噪声的实际 SNR。

## 4. 白化域 K1 中心

stage8_k2_rtc_fit_k1_white 完整扫描公共 7 x 3 注册点。每个点直接调用 build_full_sequential_local_manifold，并以 requested_rank=1 评分。最大有效 likelihood 对应 coarse center。

连续细化使用未修改的 refine_stage8_k1_continuous：最多 8 sweeps，坐标半径 0.20 度，9 个扫描点，fminbnd TolX=1e-4 度、MaxFunEvals=80，relative score tolerance=1e-9，angle update tolerance=1e-3 度，依次更新方位与俯仰。

该内核只获得真实 Zseq_white；不构造 Y_element。最终在有效 coarse 与 continuous 中按集中 likelihood 选中心。它是新 Core 的自包含单目标中心估计器，不要求复刻旧 Safe 依赖阵元数据的 grouped initialization。

## 5. 投影残差与 Fisher 方向

在中心 c 构造完整 g 和解析 Jacobian J_g：

$$
P_g^\perp=I-gg^H/(g^Hg),\quad R=P_g^\perp Z,\quad B=P_g^\perp J_g,
$$

$$
S_R=RR^H/L,\quad T=\operatorname{Re}(B^HB),\quad C_t=\operatorname{Re}(B^HS_RB).
$$

方向解为：

$$
\widehat u=\arg\max_{u\ne0}\frac{u^TC_tu}{u^TTu}.
$$

将 T 对称化并特征分解，检查其数值秩为 2。以 T 的逆平方根变换为普通对称特征问题，选择最大特征向量，再单位化并固定符号。轴的正负不影响无标签双目标输出。秩不足或方向数值无效时返回明确失败，不调用其他估计器。

## 6. 完整双目标尺度搜索

在注册矩形域内计算 c +/- rho*u/2 两个端点同时可行的 rho_max。rho_min=0.001 度。每个 rho 的评分流形是：

$$
G_\rho=\left[g(c-\rho u/2),\ g(c+\rho u/2)\right].
$$

使用 33 个扫描节点，以最佳节点相邻区间进行 fminbnd 精化，再比较扫描最优、区间端点和优化器候选。所有评分均直接构造完整流形并请求 rank 2；Jacobian 只用于求方向，不替代最终统计模型。

允许同一次函数调用内部复用完全相同 rho 的重复评价，函数返回后不保留任何 provider、persistent 对象或跨 trial cache。

结果 mode=TANGENT_PROFILE_CORE、selected_source=RAW_TANGENT_CORE、K=2。没有 fallback_flag、upgrade_flag 或 Safe selector。

## 7. 失败组成

K1_NO_VALID_GRID_POINT、K1_CONTINUOUS_INVALID、K1_CENTER_INVALID、CENTER_MANIFOLD_INVALID、TANGENT_METRIC_RANK_DEFICIENT、TANGENT_DIRECTION_NUMERIC_INVALID、TANGENT_PROFILE_NO_FEASIBLE_SCALE、TANGENT_PROFILE_NO_VALID_SCAN_NODE 和 TANGENT_PROFILE_FINAL_CANDIDATE_INVALID 分别保留其含义。

K1 连续候选无效仍允许按协议选择有效 coarse K1 中心，这不构成双目标兜底。Core 自身无效时误差为 NaN，成功标志为 false，原始失败原因保留。

## 8. 无标签定位和分辨指标

各 Profile 中心的两个 3 dB 宽度由当前 sim_cfg、工作子阵和 Taylor 窗机械测量；左右 crossing 必须存在且宽度有限、正值。机械宽度与哈希保存在 58 beamwidth contract。

对于两个排列 pi：

$$
e_{k,\pi}^{BW}=\sqrt{\left(\frac{\widehat\phi_{\pi(k)}-\phi_k}{BW_\phi}\right)^2+
\left(\frac{\widehat\theta_{\pi(k)}-\theta_k}{BW_\theta}\right)^2},\qquad
d_{max}^{BW}=\min_\pi\max_k e_{k,\pi}^{BW}.
$$

角度单位 d_max_deg 也独立最小化最大端点误差。Joint RMSE 的排列独立最小化平方误差总和：

$$
RMSE_{joint}=\sqrt{\frac12\min_\pi\sum_{k=1}^2\|\widehat\xi_{\pi(k)}-\xi_k\|_2^2}.
$$

定位成功为 fit_valid 且 d_max_bw <= 0.1。严格分辨成功为：

$$
fit\_valid\ \land\
d_{max}^{BW}\le\min(0.1,0.4\rho_{true}^{BW}).
$$

0.4 小于 0.5，因此中心塌缩不能进入两个互不重叠的真值邻域。宽度、真值和这两个阈值仅进入 fit 后的评价器。轴误差忽略方向正负；rho 误差为分离长度绝对误差；另存相对 rho、中心及分离向量误差。

## 9. 经典方法及适用性

Beamspace 组：Core、Full4D Beamspace CML、Beamspace MUSIC。Element 组：Full4D Element CML、Element MUSIC、Vertical GFBSS-MUSIC + azimuth CML、FBSS Root-MUSIC + azimuth CML、FBSS LS-ESPRIT + azimuth CML。

Full4D 保留完整 210 个无序 coarse pair、top 6 starts、12 sweeps、每坐标 9 个扫描点及现有 fminbnd 合同。MUSIC 采用 0.005 度二维网格，必须找到两个独立局部峰。MUSIC 在 L=1 为结构 N/A。三个垂直结构方法在 P2 等俯仰为结构 N/A，本轮不再有 colored-noise N/A。

经典科学内核保持字节不变。新 wrapper 只调用内核，不读取旧证据或 Tangent 输出。旧 MUSIC 的两个 cardinality 元数据字段填字面零，仅为未修改内核的运行时摊销兼容，不包含 Profile 身份或 SNR 数值；新 wrapper 按 1120 个 applicable trial 重新摊销字典构造时间。

组内共享相同 observation hash，允许严格逐 trial 配对。跨域只比较相同 nominal native-domain SNR 下的曲线、分位数、失败组成和计算量，不计算跨域逐 trial 胜负。

## 10. 验证、剪枝与交付

T1-T18 覆盖 Git 身份、两域 SNR、八个尺度等价样本、WHITE-only 路径、波束宽度、标签交换、中心塌缩、真值输入成功、K1、无 fixed K2、无 cache、完整 K2 profile、基线直接调用、真值隔离、checkpoint、plot-only 与计划任务。

T4 的矩阵尺度恒等式误差 <=1e-12；中心容差为1e-4度，方向向量1e-6，rho/端点1e-3度。它们对应既有求解器内外精度，开发阶段失败日志保留，正式运行不再调整。

429 个旧文件按 [剪枝清单](../innovation-mining/57_stage8_k2_raw_tangent_pruning_manifest.csv) 删除，前提是工具提交前18项门检通过。main/research refs、EI_paper、物理流形、完整流形 builder、DML 数学、经典科学内核及43-48结果字节保持不变。

单个 MATLAB R2022b 进程按两个观测域依次运行。每个场景两个原子 checkpoint，共3360个；有效 checkpoint 可跳过，损坏或遗留临时 checkpoint 硬停止。全部结果表和代表 rho traces 提交后，12张图可在无runtime和无fit路径情况下重画。

科学审计不以算法成功率高低为实验有效性条件。计划任务在完整审计通过后提交结果、仅推送实验分支并注销，保留 worktree 与 runtime，等待 USER_REVIEW。
