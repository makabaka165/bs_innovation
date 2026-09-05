# Raw Tangent Core 原生域 SNR 实验

本分支的科学算法为 `TANGENT_PROFILE_CORE`。源主线固定在 `644fc6e0041e400b6500579bba93d49f45e46990`；实验分支为 `experiment/stage8-k2-raw-tangent-core-native-snr-v1`。生产集成未授权。

本轮研究纯核心算法在各原生观测域相同标称 SNR 下的表现。旧 Safe 的有效率与优越性结论不能直接转用于 Core。正式数值以 `58_stage8_k2_raw_tangent_core_native_snr_results.md`（正式 finalize 后生成） 和 runtime manifest 的独立审计状态为准；正式文件产生前，不宣称实验完成或存在高可靠工作区。

## 活跃算法

固定 WHITE measurement context 使用当前圆柱工作子阵、Taylor 加窗和 phase factor = 1。W_I 为 2080 x 15，T_I 为 15 x 15，有效白化秩为 15。干净观测为：

$$
X_e=A(\Theta)S,\qquad X_w=T_IW_I^HX_e.
$$

Core 接收白化 Beamspace 观测 Z。先在 21 个注册单目标点上计算完整流形 K1 集中 DML，再按冻结的连续坐标精化合同寻找等效中心。它不需要阵元观测，不采用 grouped initialization。

以中心完整流形 g 和解析 Jacobian J_g 构造：

$$
P_g^\perp=I-\frac{gg^H}{g^Hg},\quad
R=P_g^\perp Z,\quad B=P_g^\perp J_g,
$$

$$
T=\operatorname{Re}(B^HB),\quad
C_t=\operatorname{Re}\left(B^H\frac{RR^H}{L}B\right).
$$

最大广义特征向量给出单位分离轴 u。随后在可行局部域内，以 33 个扫描节点和 fminbnd 搜索 rho。每个节点都构造两个端点的完整流形，按 requested_rank = 2 计算 DML。最小分离为 0.001 度。

算法输出两个 Raw Tangent 角度或明确 invalid。固定注册 K2 兜底、最终 Safe selector、canonical/fixed-backbone/multicenter cache 均不在活跃路径中。双目标统计模型仍然保留。

## 原生域 SNR

对任一域的干净矩阵 X，令 n 为复样本数，gamma 为线性标称 SNR：

$$
P_s=\|X\|_F^2/n,\qquad
\sigma^2=P_s/\gamma,\qquad
N=\sqrt{\sigma^2/2}(E_R+jE_I).
$$

Beamspace 的 n=15L，Element 的 n=2080L。E_R 和 E_I 为 IID 标准实高斯样本。每次实际 SNR 为 clean energy / noise energy，不按当次噪声范数重新归一化。

注册 SNR 为 -6、0、6、10、14、18、22 dB；L 为 1、4、8；Profile 为 P1-P4；每格 20 次重复。总计 1680 个场景、240 个基础 realization、3360 个原生域观测及 13440 个方法结果行。每个基础 realization 在七个 SNR 点上复用源矩阵及两域各自的标准噪声样本。

## 评价与公平性

各 Profile 中心的方位/俯仰 3 dB 宽度由现有 analyze_reference_beam 和 measure_scan_3db_width 机械测量，保存在 [波束宽度合同](../innovation-mining/58_stage8_k2_raw_tangent_beamwidth_contract.csv)。波束宽度只用于离线评价。

d_max_bw 分别评价两个端点排列，再取最大端点误差的最小值。它不复用最小平方误差排列。定位成功要求 d_max_bw <= 0.1；严格分辨成功要求 d_max_bw <= min(0.1, 0.4 rho_true_bw)。因此两个估计都塌缩到中心不能算分辨成功。

三种 Beamspace 方法共用相同 Z，五种 Element 方法共用相同 Y_e。跨域比较仅为 SCENARIO_MATCHED_NATIVE_DOMAIN_SNR_REFERENCE，不计算跨域逐 trial 胜负，也不声称观测或物理噪声 realization 相同。

有效率与成功率以 applicable trial 为分母；误差分位数只计算 valid 子集。N/A 与算法失败分开统计。每个 exact cell 的 N=20，只作描述，不宣称稳健尾部置信界。若 valid rate >= 0.90 且 resolution success rate >= 0.80，可报告描述性高可靠区域；未达到也属于有效科学结果。

## 代码与证据

活跃入口位于 [新工具目录](../tools/stage8_k2_raw_tangent_core_native_snr/README.md)。[57 协议](../innovation-mining/57_stage8_k2_raw_tangent_core_native_snr_theory_and_protocol.md) 是执行合同，[删除清单](../innovation-mining/57_stage8_k2_raw_tangent_pruning_manifest.csv) 保存旧文件路径、blob SHA 和大小。

本分支物理删除旧 72-trial Tangent 证据、对应提示词、Safe/SNR runner 以及 cache 路线。所有删除文件仍保存在 main@644fc6e、Git 历史和本地备份 bundle 中。

43-44 为 LEGACY_SAFE_WHITE_SNR_REFERENCE；45-46 为 LEGACY_SAFE_CLASSICAL_REFERENCE；47-48 为 LEGACY_SAFE_ALL_CLASSICAL_REFERENCE。其文件字节保持不变，不进入新 Core 合并结果。

正式运行使用单进程 MATLAB R2022b 和每 15 分钟一次的 Windows 计划任务。按 Beamspace、Element、finalize、独立只读 audit、结果 commit/push 的顺序推进。错误保留现场并 HARD_STOPPED，完成后注销任务，仅推送实验分支，等待 USER_REVIEW。
