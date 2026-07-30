# Stage8-K2-CB1：Tangent-Profile 与经典 MUSIC / 完整 Known-K CML 的同条件比较（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b 与 Git 的执行 AI。
>
> 本协议只做经典基线比较，不修改 Tangent-Profile、Core-Lite、Core-Plus、Step12.7、既有 31/32 证据或原实验分支。它从当前诊断修正后的 K2 分支精确分叉，建立独立比较分支。
>
> 本轮只回答：
>
> ```text
> 1. Tangent-Profile 相对同一 beamspace 上更自由的完整 K2 CML，损失或保留了多少性能？
> 2. P2/P4 的尺度退化主要来自 Tangent 的固定中心/固定轴约束，还是 beamspace 观测本身？
> 3. 在标准 MUSIC 可以适用的多快拍子集上，Tangent/ML 与 MUSIC 的差异如何？
> ```
>
> 不回答：
>
> ```text
> automatic K
> resolved/unresolved 二元判决
> bootstrap
> 新 Tangent 算法
> α-ρ 修正实现
> 生产接口集成
> ```
>
> 协议：
>
> ```text
> STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_V1
> ```

---

## 0. 当前基线状态

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

当前 Tangent 分支：

```text
experiment/stage8-k2-tangent-profile-v1
```

精确基线提交：

```text
721c30aa96f1687c757004613c23e9fb6a814afd
fix(stage8-k2): correct axis diagnostics and preserve raw evidence
```

不可变上游：

```text
origin/experiment/stage8-core-v2
=
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/main
=
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

已有冻结证据：

```text
31_stage8_k2_tangent_profile_*
32_stage8_k2_tangent_profile_*
```

已有方法：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

已有 Tangent 结果：

```text
72/72 safe valid
raw tangent candidate 70/72
59 upgrades / 13 fallbacks

joint RMSE median/p90:
0.077518689 / 0.252820120 deg

axis error median/p90:
6.571882 / 27.970319 deg

rho relative error median/p90:
0.937832 / 1.447578

rho lower-bound hits:
23/72
```

原结论继续保持：

```text
STAGE8_K2_TANGENT_PROFILE_RETAIN
```

本轮不重新判定或覆盖该历史结论。

---

## 1. 新分支隔离

### 1.1 Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git status --porcelain=v1 --untracked-files=all
git rev-parse origin/experiment/stage8-k2-tangent-profile-v1
git rev-parse origin/experiment/stage8-core-v2
git rev-parse origin/main
```

要求：

```text
工作树 clean

origin/experiment/stage8-k2-tangent-profile-v1
==
721c30aa96f1687c757004613c23e9fb6a814afd

origin/experiment/stage8-core-v2
==
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/main
==
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

若 Tangent 分支已由用户明确推进为 `721c30a` 的后代，停止并报告实际 SHA；不得自行选择新起点。

### 1.2 创建独立分支

新分支：

```text
experiment/stage8-k2-classical-baselines-v1
```

要求本地和远端均不存在该分支，否则硬停止。

执行：

```powershell
git switch --detach 721c30aa96f1687c757004613c23e9fb6a814afd
git switch -c experiment/stage8-k2-classical-baselines-v1
```

确认初始 HEAD 精确为 `721c30a`。

### 1.3 永久边界

禁止：

```text
push main
push experiment/stage8-core-v2
push experiment/stage8-k2-tangent-profile-v1
merge 回上述分支
force push
```

所有提交只推送：

```text
experiment/stage8-k2-classical-baselines-v1
```

---

## 2. 文献和公平性边界

必须在设计文档中讨论：

### MUSIC

R. O. Schmidt,

“Multiple Emitter Location and Signal Parameter Estimation,”

IEEE Transactions on Antennas and Propagation, 1986.

DOI:

```text
10.1109/TAP.1986.1143830
```

MUSIC 依赖样本协方差的信号/噪声子空间分解。当前 registry 中 `L=1` 时样本协方差秩不超过 1，无法为 known `K=2` 稳定构造二维信号子空间。因此标准 MUSIC：

```text
只在 L ∈ {4,8} 的 48 个 trial 上比较
```

`L=1` 标记：

```text
NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK
```

不得把该状态计为 MUSIC failure。

本轮不实现空间平滑，因为：

```text
当前是实际圆柱阵 / 顺序 beamspace，
没有预注册的平移不变 ULA 子阵合同；
空间平滑会改变阵列孔径和 measurement，
不再是同条件比较。
```

### 完整 Conditional ML / DML

P. Stoica and K. C. Sharman,

“Maximum Likelihood Methods for Direction-of-Arrival Estimation,”

IEEE TASSP, 1990.

DOI:

```text
10.1109/29.57542
```

I. Ziskind and M. Wax,

“Maximum Likelihood Localization of Multiple Sources by Alternating Projection,”

IEEE TASSP, 1988.

DOI:

```text
10.1109/29.7543
```

已知 `K=2`、固定精确白化下：

\[
Z = G(\Theta)S + N,
\qquad N\sim\mathcal{CN}(0,I).
\]

集中掉未知确定性源系数：

\[
\widehat S(\Theta)=G^\dagger(\Theta)Z.
\]

\[
RSS(\Theta)
=
\|
\Pi_{G(\Theta)}^\perp Z
\|_F^2.
\]

完整 known-K CML/DML：

\[
\boxed{
\widehat\Theta_{\rm CML}
=
\arg\min_{\Theta\in\Omega^2,\ \operatorname{rank}G=2}
RSS(\Theta)
}
\]

它在理论上允许两个 endpoint 独立变化，不固定 K1 中心或 Tangent 轴。

本轮的数值实现必须称为：

```text
FULL4D_BEAMSPACE_CML_MULTISTART
FULL4D_ELEMENT_CML_MULTISTART
```

不得称为：

```text
已证明全局最优的 exact ML
```

原因是采用有限多起点的确定性数值优化。

### 近双源 Approximate ML

F. Vincent, O. Besson, E. Chaumette,

“Approximate Maximum Likelihood Estimation of Two Closely Spaced Sources,”

Signal Processing, 2014.

DOI:

```text
10.1016/j.sigpro.2013.10.017
```

D. Bonacci, F. Vincent, B. Gigleux,

“Robust DoA Estimation in Case of Multipath Environment for a Sense and Avoid Airborne Radar,”

IET Radar, Sonar & Navigation, 2017.

DOI:

```text
10.1049/iet-rsn.2016.0446
```

这些方法主要针对一维 ULA/NULA 近双源，使用第一角/差分或直接两 DoA 参数化，并依靠特定 Taylor 公式把二维搜索约化为一维。当前系统是：

```text
二维 az/el
圆柱阵
固定白化顺序 beamspace
```

直接移植会同时改变阵列、参数化和算法，不是干净 baseline。

因此本轮：

```text
只做文献定位
不实现一个伪等价 Vincent/Bonacci baseline
```

### Partial Relaxation

M. Trinh-Hoang, M. Viberg, M. Pesavento,

“Partial Relaxation Approach: An Eigenvalue-Based DOA Estimator Framework,”

arXiv:

```text
1711.01982
```

PR-DML 适用于一般阵列，但在当前二维局部流形上实现、峰值配对和 `L=1` 可辨识性需要单独协议。本轮不同时加入，以免比较阶段重新变成算法开发阶段。

---

## 3. 本轮方法集合

所有方法必须使用同一个注册 `Y_element`，并逐 trial 验证：

```text
element_trial_hash
```

与 `31_stage8_k2_tangent_profile_trials.csv` 一致。

### F0：冻结已有方法

直接读取已提交证据，不重新拟合：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

来源：

```text
innovation-mining/
31_stage8_k2_tangent_profile_trials.csv

innovation-mining/
32_stage8_k2_tangent_profile_corrected_diagnostics.csv
```

### B1：完整 Beamspace K2 CML

方法 ID：

```text
FULL4D_BEAMSPACE_CML_MULTISTART
```

运行全部：

```text
72/72 trials
```

数据：

```text
Z_white = T_I * W_I' * Y_element
```

流形：

```text
build_full_sequential_local_manifold
```

评分：

```text
concentrated_dml_rss
requested_rank = 2
```

### B2：完整阵元域 K2 CML

方法 ID：

```text
FULL4D_ELEMENT_CML_MULTISTART
```

只运行预注册的 24-trial reference subset：

```text
L = 4
noise ∈ {WHITE, CORRELATED}
SNR ∈ {-6,0,+6}
profile ∈ {P1,P2,P3,P4}

2 × 3 × 4 = 24
```

该 subset 同时覆盖：

```text
P1–P4
两种噪声
三个 SNR
多快拍
```

阵元白化：

\[
Y_{\rm elem,w}
=
R_{n,\rm elem}^{-1/2}Y_{\rm element}.
\]

阵元白化流形：

\[
A_{\rm elem,w}(\Theta)
=
R_{n,\rm elem}^{-1/2}A_{\rm elem}(\Theta).
\]

使用 `model.Rn_elem`，通过 Cholesky 或稳定 eig whitening；不得假设阵元白噪声。

### B3：Beamspace MUSIC

方法 ID：

```text
BEAMSPACE_MUSIC_K2
```

仅运行：

```text
L ∈ {4,8}
共 48 trials
```

使用同一：

```text
Z_white
g(az,el)
```

### B4：Element MUSIC

方法 ID：

```text
ELEMENT_MUSIC_K2
```

仅运行同一 48-trial MUSIC subset。

使用：

```text
Y_elem_white
A_elem_white
```

---

## 4. 新代码路径

只允许新增：

```text
tools/stage8_k2_classical_baselines/
```

建议：

```text
tools/stage8_k2_classical_baselines/
├── README.md
├── matlab/
│   ├── stage8_k2_cb_constants.m
│   ├── stage8_k2_cb_add_paths.m
│   ├── stage8_k2_cb_build_context.m
│   ├── stage8_k2_cb_build_registry.m
│   ├── stage8_k2_cb_generate_trial.m
│   ├── stage8_k2_cb_whiten_element_data.m
│   ├── stage8_k2_cb_build_element_manifold.m
│   ├── stage8_k2_cb_full4d_cml.m
│   ├── stage8_k2_cb_music.m
│   ├── stage8_k2_cb_peak_picker.m
│   ├── stage8_k2_cb_evaluate_trial.m
│   ├── stage8_k2_cb_summarize.m
│   └── stage8_k2_cb_run.m
└── tests/
    ├── test_trial_reconstruction_hash.m
    ├── test_beamspace_cml_contains_fixed_grid.m
    ├── test_element_whitening_contract.m
    ├── test_music_two_peak_fixture.m
    └── test_music_l1_not_applicable.m
```

只读调用：

```text
Step12.7
tools/stage8_k2_tangent_profile
Stage8/Stage7 frozen manifold/noise functions
```

不得修改它们。

---

## 5. Trial 重建

机械复制现有 TP1 trial generator 的数据生成逻辑：

```text
same registry
same source seeds
same noise seeds
same profiles
same source matrix construction
same SNR scaling
same element noise
```

每个重建 trial 必须满足：

```text
element_trial_hash
==
31_* 中对应 trial 的 hash
```

72/72 必须精确匹配，才允许运行 baseline。

不保存完整 `Y_element` 到 Git。

---

## 6. Full4D CML Multistart

### 6.1 粗网格

使用当前冻结 local grid 的全部二维角节点。

枚举所有：

```text
unordered distinct angle pairs
```

对每个 pair 使用目标域对应的完整流形和 concentrated DML 评分。

不得用：

```text
truth
Tangent 结果
Core-Plus 结果
profile ID
```

生成 start。

按 loglik 排序，选：

```text
top_start_count = 6
```

若相同 pair 重复，只保留一次。

### 6.2 连续参数

每个 start 使用四个独立连续角坐标，或等价的完整：

```text
c_az, c_el, d_az, d_el
```

参数化。

必须允许：

```text
中心变化
方向变化
分离大小变化
```

不得固定：

```text
K1 center
Tangent axis
对称 profile 的 alpha=0
```

### 6.3 优化器

实现确定性的 bounded multistart local optimization。

允许：

```text
坐标 profile + fminbnd
或
带确定性 bounds transform 的 fminsearch
```

禁止：

```text
truth start
随机 start
particleswarm
genetic algorithm
并行 toolbox
```

固定预算建议：

```text
top starts = 6
max sweeps = 12
scan nodes per coordinate = 9
fminbnd TolX = 1e-4 deg
fminbnd MaxFunEvals = 80
```

每个候选必须：

```text
两个 endpoint 在 local domain
角分离 >= 1e-3 deg
full manifold rank = 2
RSS/loglik finite
```

最终选择所有有效 starts 中 loglik 最大者。

即使未满足严格 stationary 条件，只要：

```text
最终候选有效
完整流形 rank=2
loglik finite
```

也可作为数值 baseline 输出；但必须记录：

```text
optimizer_status
sweep_count
start_id
```

不要因为严格 solver status 把有效 baseline 人为判无效。

### 6.4 重要解释

因为这是有限 multistart：

```text
其结果是对完整 CML 最优值的数值近似，
不是全局最优证明。
```

同一 beamspace 内：

```text
full4D CML 的搜索集合包含 Tangent 的受限候选集合。
```

若数值优化充分，full4D loglik 应不低于 Tangent raw candidate；若低于，记录：

```text
NUMERICAL_OPTIMIZATION_INCOMPLETE
```

但不自动重调预算。

---

## 7. MUSIC 实现

### 7.1 样本协方差

Beamspace：

\[
\widehat R_b
=
\frac1L Z_w Z_w^H.
\]

Element：

\[
\widehat R_e
=
\frac1L Y_{e,w}Y_{e,w}^H.
\]

使用 Hermitian eig，特征值降序。

Known `K=2`：

```text
两维 signal subspace
其余 noise subspace
```

若数值 rank 小于 2：

```text
MUSIC_SIGNAL_SUBSPACE_RANK_DEFICIENT
```

### 7.2 适用性

`L=1`：

```text
applicable = false
status = NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK
```

不计算两个峰，不计入 wins/losses。

`L=4,8`：

```text
applicable = true
```

### 7.3 谱搜索

在同一 frozen local domain 上构造固定 fine grid：

```text
az step = 0.005 deg
el step = 0.005 deg
```

Beamspace：

\[
P_{\rm MUSIC}(\xi)
=
\frac{1}{
\|E_n^H g(\xi)\|_2^2
}.
\]

Element：

\[
P_{\rm MUSIC,elem}(\xi)
=
\frac{1}{
\|E_{n,e}^H a_w(\xi)\|_2^2
}.
\]

### 7.4 Peak picking

只使用数据谱，不用 truth。

1. 查找二维 8-neighbor strict/local maxima；
2. plateau 用谱值、再用 az、el 字典序确定唯一代表；
3. 按谱值降序；
4. 选择最高两个不同局部峰；
5. 少于两个峰则 invalid；
6. 不设置基于真实 separation 的最小峰距。

不做：

```text
truth matching before estimation
空间平滑
前后向平滑
root-MUSIC
```

这些都需要额外结构假设。

---

## 8. 评价指标

对所有输出，完成后才做最优 target permutation matching。

### 8.1 两个 individual angles 的集合误差

\[
RMSE_{\rm joint}
=
\sqrt{
\frac{
\|\widehat\xi_{\pi(1)}-\xi_1\|^2+
\|\widehat\xi_{\pi(2)}-\xi_2\|^2
}{2}
}.
\]

### 8.2 中心误差

\[
e_c
=
\left\|
\frac{\widehat\xi_1+\widehat\xi_2}{2}
-
\frac{\xi_1+\xi_2}{2}
\right\|_2.
\]

### 8.3 无向轴误差

\[
e_{\rm axis}
=
\arccos
\left(
\left|
\widehat u^Tu
\right|
\right).
\]

当估计 separation 为数值零时，axis error 记为 `NaN`，不得伪造方向。

### 8.4 角分离大小误差

\[
e_\rho
=
\left|
\|\widehat\xi_2-\widehat\xi_1\|_2
-
\|\xi_2-\xi_1\|_2
\right|.
\]

### 8.5 角分离向量误差

\[
e_d
=
\|
\widehat d-d
\|_2,
\]

使用最优目标匹配后的方向。

### 8.6 计算指标

```text
score calls
SVD/eig calls
runtime
coarse candidates
continuous starts
```

Element 和 beamspace 的 loglik 数值不可直接横向比较，因为观测维数不同。

---

## 9. 公平比较集合

### 9.1 全 72 trial

比较：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART
```

### 9.2 24-trial element reference subset

比较：

```text
TANGENT_PROFILE_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART
FULL4D_ELEMENT_CML_MULTISTART
```

### 9.3 48-trial MUSIC subset

比较：

```text
TANGENT_PROFILE_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
ELEMENT_MUSIC_K2
```

Core-Lite/Core-Plus 可作为附表保留。

---

## 10. 汇总方式

不使用 bootstrap，不建立新的 pass/fail 门。

每种适用方法报告：

```text
valid/applicable count
joint RMSE median/p90
center error median/p90
axis error median/p90
separation magnitude error median/p90
separation-vector error median/p90
runtime median/p90
```

按：

```text
P1–P4
SNR
L
noise
```

分层。

配对 wins/ties/losses：

```text
tie tolerance = 1e-6 deg
```

仅用于展示，不是算法门。

---

## 11. 结果解释矩阵

报告必须按以下逻辑解释，不自动修改算法。

### 情形 A

```text
Full4D beamspace CML 在 P2/P4 的 separation/endpoint 指标
显著优于 Tangent
```

结论：

```text
Tangent 的固定 K1 中心 / 固定轴约束是主要限制。
α-ρ 或完整中心修正具有理论动机。
```

### 情形 B

```text
Full4D beamspace CML 也无法恢复 P2/P4，
但 element CML 明显更好
```

结论：

```text
固定 3×5 beamspace measurement 存在 K2 信息损失。
```

### 情形 C

```text
beamspace CML 和 element CML 均出现尺度塌缩/outlier
```

结论：

```text
当前低 SNR、相关、弱次目标和小分离场景
处于 ML threshold / statistical ambiguity 区。
```

### 情形 D

```text
Tangent 接近 Full4D beamspace CML，
但调用量明显更低
```

结论：

```text
Tangent 是有效的系统特定降维近似。
```

### MUSIC

只在适用子集解释：

```text
不得把 L=1 的 N/A 当成 Tangent 胜利。
```

---

## 12. α-ρ 修正只作理论附录

设计文档中记录：

\[
\xi_1
=
\widehat c+\alpha\widehat u-\frac{\rho}{2}\widehat u,
\]

\[
\xi_2
=
\widehat c+\alpha\widehat u+\frac{\rho}{2}\widehat u.
\]

说明：

```text
α=0 是当前 Tangent；
自由 α 可修正沿轴的 K1 中心偏移；
该二维搜索是完整 CML 在固定 Tangent 轴上的受限参数化。
```

但本轮：

```text
NOT_IMPLEMENTED
NOT_TUNED
NOT_VALIDATED
```

只有情形 A 出现时，后续才有理由单独授权。

---

## 13. 输出路径

新增：

```text
innovation-mining/
33_stage8_k2_classical_baseline_theory_and_protocol.md

34_stage8_k2_classical_baseline_comparison.md

34_stage8_k2_classical_baseline_trials.csv

34_stage8_k2_classical_baseline_summary.csv

34_stage8_k2_classical_baseline_profile_summary.csv

34_stage8_k2_classical_baseline_applicability.csv

34_stage8_k2_classical_baseline_complexity.csv
```

新增 prompt：

```text
innovation-mining/stage8_execution_prompts/active/
014_stage8_k2_classical_baseline_comparison_v1.md
```

---

## 14. 执行方式

使用：

```text
MATLAB R2022b
-singleCompThread
1 MATLAB process
```

禁止：

```text
parpool
parfor
coordinator
scheduled task
bootstrap
复杂 checkpoint/protocol
```

Runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_classical_baselines_v1
```

先运行 4 个 smoke cases：

```text
P1 L=4 SNR=0 WHITE
P2 L=4 SNR=0 WHITE
P3 L=4 SNR=0 CORRELATED
P4 L=4 SNR=0 CORRELATED
```

只检查：

```text
finite result
same element hash
no truth leakage
MUSIC applicability
full CML search runs
```

不设性能门。

然后一次运行正式比较。

若中断，删除本轮未提交 runtime 后从头执行；不建立恢复框架。

---

## 15. 提交顺序

### 15.1 设计提交

提交：

```text
33_stage8_k2_classical_baseline_theory_and_protocol.md
014 prompt
active README
```

标题：

```text
docs(stage8-k2): define classical baseline comparison
```

首次推送：

```powershell
git push -u origin experiment/stage8-k2-classical-baselines-v1
```

### 15.2 工具提交

只提交：

```text
tools/stage8_k2_classical_baselines/
```

标题：

```text
feat(stage8-k2): add full CML and MUSIC baselines
```

### 15.3 结果提交

提交：

```text
34_stage8_k2_classical_baseline_*
```

归档 014，active README 恢复：

```text
NO_ACTIVE_STAGE8_EXECUTION
STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_COMPLETED
```

标题：

```text
docs(stage8-k2): record classical baseline comparison
```

---

## 16. 最终边界

本轮完成后不得自动：

```text
实现 α-ρ
修改 Tangent
扩大 trial
加入更多 MUSIC 变体
加入深度学习
加入 automatic K
合并回原分支
```

最终报告只给出：

```text
相对完整 beamspace CML 的定位
beamspace 与 element 信息差异
MUSIC 可适用子集结果
P2/P4 问题来源
α-ρ 是否具有后续理论动机
```

---

## 17. 最终报告格式

```text
STAGE8_K2_CLASSICAL_BASELINE_COMPARISON_COMPLETE

Branch:
Base:
Design commit:
Tool commit:
Result commit:
Push:
Git clean:

Original Tangent branch unchanged:
Core-V2 unchanged:
Main unchanged:

Trial reconstruction:
- 72/72 element hashes

Full beamspace CML:
- 72/72
- valid
- joint/center/axis/rho/vector metrics
- P1–P4
- runtime

Element CML:
- 24/24 reference subset
- same metrics
- comparison with beamspace

Beamspace MUSIC:
- applicable 48
- N/A 24
- valid peaks
- same metrics

Element MUSIC:
- applicable 48
- N/A 24
- valid peaks
- same metrics

Tangent comparison:
- vs full beamspace CML
- vs element CML subset
- vs MUSIC applicable subset

P2/P4 diagnosis:
- center restriction
- beamspace information loss
- ML threshold/ambiguity

Alpha-rho motivation:
YES / NO / INCONCLUSIVE

No algorithm change:
true
```
