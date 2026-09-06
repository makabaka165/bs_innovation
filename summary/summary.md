# Raw Tangent Core 两场景 L8 原生域 SNR 实验

本分支算法为 `TANGENT_PROFILE_CORE`。父提交固定为 `f1b13422a91540073ecf417c3b25f5cac552b9d6`，新分支为 `experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1`。场景仅 SC_A/SC_B，L=8，五种方法，每格20次。生产集成未授权。

本轮共280个场景、40个基础 realization、560个原生域观测与checkpoint、1400行方法结果。[当前结果](../innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_results.md)在计算完成后生成，最终完整性以 [runtime manifest](../innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_runtime_manifest.json) 的独立审计状态为准。未审计前不宣称最终PASS。

SC_A/SC_B几何相同：中心[8,10]度，分离0.45度，轴角30度；SC_A次源功率0 dB、相关幅度0，SC_B为-3 dB和0.7。相关相位沿用source seed生成。这是查看父实验结果后设计的代表场景验证，并非盲holdout；SC_B同时改变功率与相关性，不能单独解释任一因素的因果作用。不预先保证Tangent更优。

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

注册SNR为-6、0、6、10、14、18、22 dB；L仅为8；SC_A/SC_B每格20次。40个基础realization在七个SNR点复用同一源矩阵和各域标准噪声，只缩放噪声方差。

## 评价与公平性

各 Profile 中心的方位/俯仰 3 dB 宽度由现有 analyze_reference_beam 和 measure_scan_3db_width 机械测量，保存在 [波束宽度合同](../innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_beamwidth_contract.csv)。波束宽度只用于离线评价。

d_max_bw 分别评价两个端点排列，再取最大端点误差的最小值。它不复用最小平方误差排列。定位成功要求 d_max_bw <= 0.1；严格分辨成功要求 d_max_bw <= min(0.1, 0.4 rho_true_bw)。因此两个估计都塌缩到中心不能算分辨成功。

三种Beamspace方法共用同一Z，两种Element方法共用同一Y_e。跨域仅作各原生域等标称SNR参考，使用不同观测，不计算跨域逐trial胜负。

五种方法在两场景全部结构适用。每个精确条件的分母固定20；无有效峰、根或rho仍算算法失败。误差分位数仅用valid样本并旁列有效数。一次样本对应5个百分点。valid>=0.90且strict resolution>=0.80仅为按场景描述规则；单个达标SNR点不构成连续稳定区间，也不是在线阈值或实验有效性门。

## 代码与证据

活跃入口为 [工具README](../tools/stage8_k2_raw_tangent_core_native_snr/README.md)。[59协议](../innovation-mining/59_stage8_k2_raw_tangent_two_scenarios_l8_protocol.md)是本轮执行合同，[删除清单](../innovation-mining/59_stage8_k2_raw_tangent_two_scenarios_deletions.tsv)仅记录path/reason/preserved_at_parent_commit。

本轮删除旧57/58输出、旧四场景入口、事故恢复专用脚本、退役方法与关联旧测试。它们均保留在父提交f1b1342，不创建额外归档树或bundle。保留方法的共享内核不变。

43-44 为 LEGACY_SAFE_WHITE_SNR_REFERENCE；45-46 为 LEGACY_SAFE_CLASSICAL_REFERENCE；47-48 为 LEGACY_SAFE_ALL_CLASSICAL_REFERENCE。其文件字节保持不变，不进入新 Core 合并结果。

正式运行使用MATLAB R2022b、-singleCompThread和一个核实的计算worker。新Windows任务每15分钟依次接续Beamspace、Element、finalize、独立只读audit和结果commit/push。Git失败复用已有结果提交，完成后注销任务，保留worktree/runtime并等待USER_REVIEW。
