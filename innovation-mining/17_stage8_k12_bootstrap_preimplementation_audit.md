# Stage8.1A / Step12.6B-pre calibration 执行合同审计

> 日期：2026-07-19
> 仓库：`makabaka165/bs_innovation`
> 基线：`8899023cd608f53c271b5ca429ad41b17d8e0f22`
> 分支：`main`
> MATLAB：R2022b
> 活跃相位：`phase_factor=1`
> 当前状态：`AUTHORIZED_STAGE8_1A_CODE_ONLY`
> 性能状态：`STAGE8_1A_CODE_ONLY_NO_PERFORMANCE_RESULTS`

## A. 审计结论边界

Stage8.1A 只修订并冻结可执行代码合同，使用小型 deterministic/synthetic fixture
验证接口。它不执行 59,700 个正式 K1 calibration bootstrap 样本，不执行
validation 或 independent holdout，不生成正式阈值、CSV、PNG、Monte Carlo
结果或论文性能数字，也不进入 Stage8.1B。

Stage8 只能定位为：将已有非正则 K1/K2 bootstrap 与可分辨/不可分辨风险状态
接入 factor=1 实际顺序 DBF、稳定白化 DML 和 Stage5 分组条件初始化链，去除
oracle-K 假设并形成工程风险接口。它不挽救 Stage7 波束选择贡献，不改变
`RECT_E14_A31`，不创造新统计理论，也不声称一般多目标模型阶数保证。

## B. Prior art

以下均为已有方法或统计思想，不作为 Stage8 创新声明：K1/K2 LRT、集中似然、
parametric bootstrap、source enumeration、AIC/MDL、GLRT/Rao statistical
resolution limit、bootstrap confidence region、abstention/unresolved、
false-split 控制和 false-resolved 控制。

直接边界包括 Self 与 Liang 1987（非标准条件下的 LRT，DOI
`10.1080/01621459.1987.10478472`）、Zhang、Hu 与 Ye 2013（bootstrap source
enumeration，DOI `10.1016/j.sigpro.2012.11.007`）以及 Liu 与 Nehorai 2007
（statistical angular resolution limit，DOI `10.1109/TSP.2007.898789`）。
普通 Wilks 卡方极限不能直接用于 K1 原假设下幅度边界和未识别新增角度。

## C. 固定测量与 provenance

主配置 `PRIMARY_RECT_E14_A31` 从 Stage7 frozen pool 读取
`RECT_E14_A31`，即 3 个俯仰中间通道、每通道 5 个条件方位输出、共 15 个
输出。敏感性配置 `SENSITIVITY_FULL_PARENT_5X5` 读取 `RECT_E31_A31`。
每个配置和噪声 profile 独立重建 `W_I/C_I/T_I`，候选搜索期间保持固定；
Stage8 不重新选择波束。

stable identity 只散列排序的 Git `mode/blob/path` manifest 中 Stage8 tracked
`.m` 和稳定 README，排除 calibration/results/figures，runtime HEAD 只作
metadata。dependency scope 覆盖 Stage3 DML/RSS、Stage4/5 初始化与联合细化、
Stage6 projected metric、Stage7 两个物理子集、Stage7.1 evidence identity、
`sim_cfg.m` 和 `arr_cyl.m`。

## D. 统计公式与 K1/K2 start set

对白化数据 `Z_white [r_C,L]`：

\[
n_C=r_CL,\qquad
\widehat\sigma_K^2=RSS_K/n_C,
\]

\[
\ell_K=-n_C[\log(\pi\widehat\sigma_K^2)+1],\qquad
\Lambda_{12}=2n_C\log(RSS_1/RSS_2).
\]

K1 固定运行 `K1_GROUPED_Q1_KQ1` 和
`K1_CONVENTIONAL_SINGLETON_PEAK`。K2 固定运行
`K2_GROUPED_Q1_KQ2`、`K2_GROUPED_Q2_KQ1_PLUS_KQ1` 和
`K2_K1_EMBEDDED_NESTED_START`。Q/Kq 只提供初始化结构；全部有效 start 返回
相同 full sequential joint DML，按最大集中似然选择。grouped start 失败只记录，
不阻断其他 start，也不增加第四个补救 start。

embedded start 的第一列严格使用最优 K1 流形列；第二列在固定局部注册网格中
选择 projected-Fisher 距离最大、lexicographically first 的 full-rank anchor。
初始 K2 RSS 必须在机器精度容差内不大于 K1 RSS。系数恢复使用相对秩规则的
economy-SVD pseudoinverse，不计算 `inv(G'*G)`，不使用固定 ridge 或 RSS floor。

## E. Bootstrap 与 threshold 合同

K1/K2 bootstrap 在阵元坐标生成

\[
Y_{boot}=A_{element}(\widehat\theta_K)\widehat S_K+N_{element},
\quad N_{element}\sim\mathcal{CN}(0,\widehat\sigma_K^2R_{n,element}),
\]

随后固定执行 `Z_raw=W_I'Y_boot` 和 `Z_white=T_IZ_raw`。阵元数据保留到
bootstrap bundle，且每个样本重新运行真实 Stage4/5 initialization factory，
再完整重拟合 K1 和 K2；不在原估计角度直接评分，不固定 K2 角度。
阈值策略固定为每个物理 measurement config 一个 `q_global`：

\[
q_{global}=\max_{150\ cells}q_{cell,0.95}.
\]

固定 `alpha=0.05`、`Bboot_per_cell=199`、
`TYPE1_ORDER_STATISTIC`。lookup 只接受 measurement config ID 和 locked
artifact，禁止场景、真值、estimated separation、score gap 或难度标签输入。
普通卡方只作 diagnostic。

## F. Separation confidence 与状态机

固定 `beta=0.05`、`Bsep=199`、minimum valid fraction `0.90`。K2 separation
bootstrap 在拟合 K2 下生成白化数据、完整重拟合 K2，并以原 K2 拟合而非 truth
作为二维最小代价标签匹配参考。对差向量误差 `e_b` 使用 Stage6 在拟合中心的
projected metric `T_hat`，以 type-1 0.95 order statistic 得到 `r_conf^2`。
只有 `d_hat' T_hat d_hat > r_conf^2` 才排除零；方位和俯仰 simultaneous
half-width 均必须不超过 0.21 degree。

主状态仅为 `K1`、`K2_RESOLVED`、`K2_UNRESOLVED`、
`OUT_OF_LOCAL_CELL`、`SEARCH_NOT_CONVERGED`、
`NUMERIC_RANK_DEFICIENT`。`MODEL_MISMATCH_STATE_DISABLED_UNTIL_CALIBRATED_GOF`；
hidden truth 不能激活 mismatch 状态，wrong-confidence resolved 输出必须进入
mismatch 风险。

## G. Calibration、validation 与 holdout 冻结

- Calibration：2 configs，各 150 cells，199 samples/cell，共 59,700；300 个
  data seed 从 `2026072100` 连续分配，bootstrap block 从 `2126072100` 开始、
  stride 1000。本阶段不执行。
- K1 validation：6 个 `L × noise` strata，各 1000 个公共阵元 trial；两个
  measurement config 共享阵元 realization，形成 6000 个公共 trial 和 12,000
  个 method rows。seed base 为 `2226072200`，每 stratum 占一个 2000-seed block。
- K1 independent holdout：同分布 6000 trials/config，seed 20260723。
- K2 validation：主配置 1200 trials，seed 20260724，分离 log-uniform
  `[0.05,0.40]` degree，其余生成规则按 locked plan。
- K2 independent holdout：主配置 2000 trials，seed 20260725。
- Full-parent sensitivity：从 independent holdout 配对抽取 600 K1 和 600 K2。
- Mismatch：M0--M3 各 200，seed 20260726。
- Stage5 coherent-weak boundary：200 个配对 realization，不能删除 unresolved。

holdout 不允许重校准 `q_global`。Stage8.2 的 Wilson 门、normal/easy subgroup
定义、unconditional penalized error 和 mismatch wrong-confidence 门均在
Stage8.0 冻结；不通过时不得增加 score-gap、场景阈值或重新调 alpha/beta。

## H. Baseline、复杂度和 scope

后续比较包括 proposed global-threshold bootstrap LRT、公开参数数
`p_K=2K+2KL+1` 的 DML-AIC 与 DML-BIC/MDL、no-unresolved ablation、known-K
oracle、ordinary chi-square diagnostic、可精确复现时的 2013 bootstrap source
enumeration，以及只作理论参考的 GLRT/Rao resolution limit。

离线复杂度必须报告 cells、samples、K1/K2 fits、score/SVD calls、runtime、
memory 和 artifact size；在线复杂度必须报告固定 starts、lookup、separation
触发率、Bsep refits、平均与最坏 latency。离线成本不能隐藏为“预计算”。

active Stage8 common code禁止 factor 2、固定 ridge、C05/topK/gap、经验难度状态、
truth/holdout-dependent threshold、candidate-dependent measurement、hidden-truth
mismatch、bootstrap 固定点评分、只重拟合 K2 的 calibration，或从主风险删除
unresolved。

## I. Stage8.1A 未完成项

- 正式 bootstrap threshold 未生成；
- validation/holdout 未执行；
- `MODEL_MISMATCH` 数据可见 GOF 未校准；
- K3 未执行；
- cache、硬件、定点、FPGA 均未执行。

## J. 下一阶段门

只有 Stage8.1A 全部 code-only 测试、Code Analyzer、scope、upstream freeze、
identity 和 `git diff --check` 门通过后，才可判定“技术上允许后续单独授权
Stage8.1B”。该判定本身不执行 Stage8.1B，也不授权 Stage8.2。

## K. Stage8.1A 合同修订

Stage8.1A 将 Stage8.0 的实验计划改成可审计执行合同，但不运行正式实验：

- calibration plan 删除 active `seed`，显式保存 global cell index、data seed、
  bootstrap block start/end、stride 和公式；59,700 个 active bootstrap seed
  全局唯一，并与 data/validation/holdout 空间隔离；
- measurement registry 固定 PRIMARY/FULL_PARENT × WHITE/CORRELATED 四个对象，
  每个 cell 按 config+noise 解析自己的 fixed hash，不允许一个模型跨噪声复用；
- 初始化从同一 `Y_element` 实际执行 conventional singleton、Q1/Kq1、
  Q1/Kq2 和 Q2/Kq1+Kq1；grouped failure 只使对应 start unavailable；
- `validate_stage8_fit_for_lrt` 统一 returned、converged、rank、RSS、variance、
  log-likelihood 和 fixed identity 门；formal calibration 任一 refit 失败即令
  整个 cell 为 `CALIBRATION_CELL_REFIT_FAILURE`，不删除样本；
- cell/shard/aggregate runner 以 source/plan/model/cell 四类 hash 管理 checkpoint，
  只有 300 个 PASS cell 和全部唯一 seed 才能锁定两个 config-level threshold；
- K1 validation 只查 locked threshold，不重新校准；writer 的确定性 identity
  排除 runtime、manifest 自身和 checkpoint 临时文件；所有 Stage8.1 runner
  在 Stage8.2 边界停止。
