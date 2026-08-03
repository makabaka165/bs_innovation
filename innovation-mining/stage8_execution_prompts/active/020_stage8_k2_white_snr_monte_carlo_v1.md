# Stage8-K2-MC1：Tangent 白化顺序波束域 SNR 工作区间蒙特卡洛与 K2 最终收束（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、Git 和 GitHub 推送的执行 AI。
>
> 本协议直接在长期 Tangent 分支执行：
>
> ```text
> experiment/stage8-k2-tangent
> ```
>
> 本轮不修改 Tangent、Core、白化、measurement、流形、P1–P4、SNR 公式或既有
> `31_*–42_*` 证据。
>
> 本轮只做一件事：
>
> ```text
> 以“白化后顺序 Beamspace 的期望总能量 SNR”为控制变量，
> 对低—中—高 SNR 区间执行重复随机试验，
> 统计 Tangent 从 fallback 主导到稳定相对获益的工作区间。
> ```
>
> 本轮完成后关闭 Stage8-K2 算法开发路线，不自动修改算法、生产接口或在线判据。
>
> 协议：
>
> ```text
> STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_AND_CLOSURE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_AND_CLOSURE_V1
> ```

---

## 0. 当前状态

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

唯一执行分支：

```text
experiment/stage8-k2-tangent
```

预期当前 HEAD：

```text
5753cd706d139dcc4904ff20b3cef205f5954e7d
docs(stage8-k2): complete corrected SNR domain validation
```

不可变分支：

```text
origin/main
=
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
=
a7139204d717923cb89d0d629b67f1b3ab7ae94d
```

当前已完成：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_V2_COMPLETE
```

已知事实：

```text
原 element -6/0/+6 dB
约映射为 white-beamspace 16/22/28 dB；

直接控制 white-beamspace -6/0/+6 dB 的 72-trial 已完成；

每个 factor cell 仍只有一个 source/noise realization；

42_* 明确建议后续 Monte Carlo，
但尚未授权和执行。
```

默认 K2：

```text
TANGENT_PROFILE_SAFE
```

Tangent 状态：

```text
FROZEN
```

---

## 1. Git 与环境 Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git switch experiment/stage8-k2-tangent

$head = (git rev-parse HEAD).Trim()
$remote = (git rev-parse origin/experiment/stage8-k2-tangent).Trim()
$main = (git rev-parse origin/main).Trim()
$research = (git rev-parse origin/research/stage8-k2-vincent-anchored).Trim()
$status = @(git status --porcelain=v1 --untracked-files=all)
```

要求：

```text
HEAD == origin/experiment/stage8-k2-tangent
HEAD == 5753cd706d139dcc4904ff20b3cef205f5954e7d

origin/main
== 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
== a7139204d717923cb89d0d629b67f1b3ab7ae94d

$status 为空
```

确认：

```text
MATLAB = 0
mwpython = 0
coordinator = 0
active lock = 0
```

若 HEAD 不是预期提交：

```text
硬停止；
打印实际 HEAD、远端 HEAD 和 diff；
不得自行 reset、rebase 或选择新起点。
```

本协议：

```text
不创建新分支
不 force push
不修改 main
不修改 research
```

---

## 2. 冻结科学边界

相对：

```text
5753cd706d139dcc4904ff20b3cef205f5954e7d
```

以下必须保持字节不变：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**
tools/stage8_k2_snr_validation/**

beamspace_ml_v18/**

innovation-mining/31_*
innovation-mining/32_*
innovation-mining/33_*
innovation-mining/34_*
innovation-mining/39_*
innovation-mining/40_*
innovation-mining/41_*
innovation-mining/41A_*
innovation-mining/42_*
```

禁止修改：

```text
W_I / C_I / T_I
whitening rank
build_psd_whitener
Tangent axis
Tangent scale profile
safe fallback
Core-Lite / Core-Plus
P1–P4
local domain
source statistics
noise model
SNR definition
white-SNR scaling formula
```

只允许新增：

```text
tools/stage8_k2_white_snr_monte_carlo/**

innovation-mining/43_*
innovation-mining/44_*

prompt 020
00_DOCUMENT_STATUS_INDEX.md
active README
prompt archive manifest
```

---

## 3. SNR 控制定义

本轮唯一控制变量为：

```text
WHITENED_SEQUENTIAL_BEAMSPACE_EXPECTED_TOTAL_SNR
```

对一个 trial：

\[
X_{e,0}=A(\Theta)S_0,
\]

\[
X_{w,0}=T_IW_I^HX_{e,0},
\]

\[
C_w=T_IC_IT_I^H.
\]

目标 white SNR：

\[
\gamma_w^\star
=
10^{\gamma_{w,\mathrm{dB}}^\star/10}.
\]

公共信号缩放：

\[
\boxed{
\alpha
=
\sqrt{
\frac{
\gamma_w^\star L\,\operatorname{tr}(C_w)
}{
\|X_{w,0}\|_F^2
}
}
}
\]

然后：

\[
S=\alpha S_0,
\qquad
X_e=A(\Theta)S.
\]

必须继续使用实际：

\[
\operatorname{tr}(C_w),
\]

不得硬编码 whitening rank。

不得使用 realized noise energy 决定 \(\alpha\)。

---

## 4. Monte Carlo 因子设计

### 4.1 White-SNR 网格

固定：

```text
-6 / 0 / +6 / +10 / +14 / +18 / +22 dB
```

理由：

```text
-6 / 0 / +6：
与 42_* 单 realization 结果重叠；

+10 / +14：
填补 Tangent 由低增益进入明显增益的关键空白区；

+18：
接近原 element -6 dB 对应的最低 white-SNR 区间；

+22：
接近原 element 0 dB 的典型 white-SNR 工作点。
```

不得根据中间结果增删 SNR 点。

### 4.2 其他因素

保持：

```text
noise ∈ {
  WHITE,
  STAGE5_TOEPLITZ_CORRELATED
}

L ∈ {1,4,8}

profile ∈ {P1,P2,P3,P4}
```

P1–P4 与 31/42 号证据完全相同。

### 4.3 重复数

每个精确 factor cell：

```text
10 independent replicates
```

总 trial 数：

\[
7
\times2
\times3
\times4
\times10
=
\boxed{1680}
\]

方法：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

总 method rows：

\[
1680\times3
=
\boxed{5040}
\]

---

## 5. Common-random-number 配对

为获得平滑、可配对的 SNR 曲线，同一个：

```text
noise × L × profile × replicate
```

在 7 个 SNR 点上使用：

```text
同一个 source seed
同一个 source phase
同一个归一化 source matrix
同一个 noise seed
同一个 noise realization
```

只有公共 signal scale \(\alpha\) 随 SNR 改变。

### 5.1 基础 realization 数

独立基础 realization：

\[
2\times3\times4\times10
=
240.
\]

每个基础 realization 在 7 个 SNR 点重复使用。

### 5.2 固定 seed 方案

令：

```text
noise_index   = 1..2
L_index       = 1..3
profile_index = 1..4
replicate_id  = 1..10
```

定义：

```text
base_realization_index =
((((noise_index-1)*3 + (L_index-1))*4
  + (profile_index-1))*10
  + (replicate_id-1))
```

固定：

```text
source_seed = 430100000 + base_realization_index
noise_seed  = 430200000 + base_realization_index
```

这些 seeds 在不同 SNR 点有意重复，但在 240 个基础 realization 间唯一。

不得根据结果修改 seed。

### 5.3 L=1

继续执行冻结合同：

```text
L=1:
fully coherent sources by contract
```

不得改变为人工低相关。

---

## 6. Trial ID 和 registry

Trial ID：

```text
MC1_K2_N<noise>_L<L>_S<snr_token>_<profile>_R<replicate>
```

例如：

```text
MC1_K2_N1_L4_SP14_P2_R07
MC1_K2_N2_L1_SM6_P4_R10
```

Registry 每行至少包含：

```text
trial_id
global_trial_index

noise_profile_id
noise_index
L
L_index
profile_id
profile_index

white_beamspace_snr_target_db
snr_index

replicate_id
base_realization_index
source_seed
noise_seed

snr_control_domain
protocol_id
```

总计：

```text
1680 rows
1680 unique trial IDs
240 unique source seeds
240 unique noise seeds
```

---

## 7. Trial 生成合同

新增工具必须复用或机械对齐 42 号 SNR 验证中的：

```text
truth construction
source phase construction
construct_deterministic_source_matrix
measurement resolution
white-SNR expected scaling
element noise generation
SNR metrics
geometry metrics
method evaluation
```

每个 trial：

1. 构造冻结 truth；
2. 生成归一化 source matrix；
3. 生成未缩放阵元信号；
4. 使用 white-SNR expected scale；
5. 使用固定 noise seed 生成 `sigma2=1` 噪声；
6. 构造 `Y_element`；
7. 计算 element/raw/white/projected SNR；
8. 运行三种冻结方法。

### 7.1 White target 合同

每个 trial 必须满足：

\[
\left|
\mathrm{SNR}_{w,\mathrm{exp,dB}}
-
\mathrm{SNR}_{w,\mathrm{target,dB}}
\right|
\le10^{-10}\ {\rm dB}.
\]

### 7.2 Trial hash

每个 trial hash 至少绑定：

```text
protocol
trial_id
Y_element
truth
white SNR target
resulting element SNR
source seed
noise seed
noise profile
L
profile
replicate
measurement hash
```

要求：

```text
1680/1680 unique hashes
```

---

## 8. 方法

### M0：CORE_LITE

冻结调用，不修改。

### M1：CORE_PLUS

冻结调用，不修改。

### M2：TANGENT_PROFILE_SAFE

冻结调用，不修改。

三方法必须使用同一：

```text
Y_element
truth-independent fit input
measurement
noise model
local domain
```

禁止运行：

```text
Full4D
MUSIC
Root-MUSIC
ESPRIT
Vincent
automatic K
bootstrap
threshold validation
```

---

## 9. Truth isolation

以下字段只能在拟合完成后用于评价：

```text
truth angles
joint RMSE
center error
axis error
rho error
separation-vector error
projected K2 SNR
profile label
replicate outcome
```

方法入口和初始化不得读取：

```text
truth
profile ID
white target
projected K2 SNR
previous SNR result
other method result
```

允许 SNR target 仅用于构造公共 signal scale，不得进入估计器。

---

## 10. 轻量可恢复执行

本轮不建立并发控制面，不使用多个 MATLAB worker。

使用：

```text
MATLAB R2022b
-singleCompThread
1 MATLAB process
```

原因：

```text
避免再次引入并发、资源门和结果合并复杂度；
42_* 实测推算 1680 trial 约为数小时级；
逐 trial checkpoint 已足以支持关机后续跑。
```

### 10.1 Runtime

```text
E:\bs_innovation_runtime\
stage8_k2_white_snr_monte_carlo_v1
```

### 10.2 Checkpoint

每完成一个 trial，写：

```text
checkpoints/
trial_<global_trial_index>_<trial_id>.mat
```

每个 checkpoint 包含：

```text
registry row
trial hash
SNR metrics row
3 method rows
checkpoint scientific hash
code identity
registry hash
completed UTC
runtime sec
```

写入方式：

```text
先写 .tmp
验证可加载和内容 hash
原子 rename 为 .mat
```

启动或恢复时：

```text
扫描已有 checkpoints
验证 schema/hash/code/registry
有效 checkpoint 跳过
.tmp 忽略
无效 checkpoint 硬停止，不自动覆盖
```

### 10.3 状态

每完成一个 trial，原子更新：

```text
status/latest_status.json
status/latest_status.txt
```

至少包括：

```text
completed / 1680
remaining
current trial
elapsed active sec
median trial sec
ETA sec
current SNR/profile/noise/L/replicate
fallback counts
last update UTC
```

每完成 25 个 trial，在控制台打印一次状态。

### 10.4 中断恢复

用户可在 trial 边界后结束 MATLAB 或关机。

重新运行同一命令时：

```text
从已验证 checkpoint 继续；
不得重新计算已完成 trial；
不得修改 registry。
```

如果在单个 trial 中途终止：

```text
该 trial 只有 .tmp 或无 checkpoint；
恢复时仅重跑该 trial。
```

不实现：

```text
PowerShell coordinator
scheduled task
parallel worker
复杂 lock hierarchy
```

---

## 11. 最小测试

### T1：42 号公式一致性

对 4 个代表 trial，比较新工具和冻结 42 工具的：

```text
source phase
normalized source
signal scale
noise
Y_element
element/raw/white/projected SNR
```

在相同 spec 下必须一致。

### T2：White target

对：

```text
P1–P4
WHITE/CORRELATED
L=1/4/8
全部 7 个 SNR
```

选择至少 24 个 fixture，white target error：

```text
<= 1e-10 dB
```

### T3：Common-random-number

同一基础 realization 的 7 个 SNR trial：

```text
source seed 相同
noise seed 相同
source phase 相同
normalized source 相同
noise matrix 相同
只有公共 signal scale 不同
```

### T4：Seed 唯一性

```text
240 unique source seeds
240 unique noise seeds
```

且不同基础 realization 的噪声矩阵不同。

### T5：Trial hash

```text
1680 unique trial hashes
```

### T6：Truth isolation

拟合入口不接收 truth/projected-SNR/其他方法结果。

### T7：Checkpoint round trip

写入、加载、hash 验证、重复启动 skip 均通过。

### T8：Interrupted checkpoint

人工 fixture 只保留 `.tmp`，恢复时该 trial 被重跑，已有 valid checkpoint 不变。

### T9：Four-trial smoke

固定：

```text
P1 WHITE L=4 +6 dB R01
P2 WHITE L=4 +14 dB R01
P3 CORRELATED L=4 +14 dB R01
P4 CORRELATED L=4 +22 dB R01
```

三方法必须给出明确结果，Tangent safe result 有效。

### T10：Summary fixture

人工小表验证：

```text
median/P90
wins/ties/losses
fallback
transition classification
```

---

## 12. 正式执行顺序

1. Git/env preflight；
2. 运行 T1–T10；
3. 构建并冻结 1680-row registry；
4. 写 registry hash；
5. 运行/恢复 1680 trials；
6. 验证 1680 checkpoints；
7. 合并为 SNR/trial/method 表；
8. 生成汇总与图；
9. 独立只读复核；
10. 写 Git evidence；
11. 提交并关闭路线。

若任一固定测试失败：

```text
硬停止；
不得正式运行。
```

---

## 13. 原始结果字段

### 13.1 Trial/SNR 表

每个 trial 一行：

```text
trial_id
global_trial_index
element_trial_hash

noise_profile_id
L
profile_id
white_beamspace_snr_target_db
replicate_id
base_realization_index
source_seed
noise_seed

element_snr_expected_db
element_snr_realized_db

raw_beam_snr_expected_db
raw_beam_snr_realized_db

white_beam_snr_expected_db
white_beam_snr_realized_db

raw_peak_beam_snr_expected_db

k2_projected_snr_expected_db
k2_projected_snr_realized_db

white_receive_gain_db
whitening_residual
```

### 13.2 Method 表

每 trial/method 一行：

```text
trial_id
method_id

fit_valid
fit_status
selected_source

angles_hat_deg
RSS
loglik
effective_rank

joint_RMSE_deg
azimuth_RMSE_deg
elevation_RMSE_deg
center_error_deg
direction_axis_error_deg
rho_error_deg
rho_relative_error
separation_vector_error_deg

upgrade_flag
fallback_flag
fallback_reason

score_call_count
SVD_call_count
runtime_sec

truth_used_in_fit_flag
```

总计：

```text
5040 rows
```

---

## 14. 汇总层级

### 14.1 SNR overall

每个 SNR、每个方法：

```text
N = 240
```

报告：

```text
valid rate
median/P90 joint RMSE
center/axis/rho/vector median/P90
upgrade/fallback rate
runtime
score/SVD
```

### 14.2 SNR × profile

每组：

```text
N = 60
```

这是论文中识别 P1–P4 工作区间的主要层级。

### 14.3 SNR × noise

每组：

```text
N = 120
```

### 14.4 SNR × L

每组：

```text
N = 80
```

### 14.5 Exact factor cell

```text
SNR × profile × noise × L
N = 10
```

只报告：

```text
valid
median
fallback
wins/ties/losses
```

不对 N=10 单元报告“稳定 P90”或置信区间。

---

## 15. 配对比较

使用同一个 trial：

```text
Tangent vs Core-Lite
Tangent vs Core-Plus
```

定义：

\[
\Delta
=
RMSE_{\rm Tangent}
-
RMSE_{\rm baseline}.
\]

tie：

```text
abs(delta) <= 1e-6 deg
```

报告：

```text
wins
ties
losses
win rate among non-ties
median paired delta
P90 paired delta
```

只比较两方法均 valid 的行。

---

## 16. 工作区间分类

该分类只用于论文描述，不形成在线 threshold。

### 16.1 `FALLBACK_DOMINATED`

```text
Tangent fallback rate >= 0.50
```

### 16.2 `RELATIVE_GAIN_UNSTABLE`

满足：

```text
Tangent fallback rate < 0.50
且
Tangent median joint RMSE 优于至少一个 baseline
```

但未满足稳定条件。

### 16.3 `STABLE_RELATIVE_GAIN`

同时满足：

```text
Tangent valid rate = 1

Tangent fallback rate < 0.50

Tangent median joint RMSE
<= Core-Lite 且 <= Core-Plus

Tangent P90 joint RMSE
<= Core-Lite 且 <= Core-Plus

Tangent wins > losses
vs Core-Lite 且 vs Core-Plus
```

### 16.4 `NO_RELATIVE_GAIN`

不满足上述三类。

### 16.5 最低稳定 SNR

在 SNR overall 和每个 profile 中，报告第一个达到：

```text
STABLE_RELATIVE_GAIN
```

的 SNR 点。

如果后续更高 SNR 点又失去稳定条件：

```text
不得宣称单调阈值；
报告 NON_MONOTONIC_EMPIRICAL_REGION。
```

---

## 17. K2 projected SNR 解释

`K2 projected SNR` 是 truth-only 描述变量。

按固定 bins 汇总：

```text
(-Inf, -10)
[-10, -5)
[-5, 0)
[0, 5)
[5, 10)
[10, +Inf)
```

每个 bin 报告：

```text
N
profile composition
white-SNR composition
Tangent fallback
Tangent median/P90 RMSE
Tangent vs baseline wins/losses
```

禁止：

```text
把 projected SNR bin 边界用作在线 selector
或生产 threshold。
```

---

## 18. 与 42 号单 realization 的一致性

对 white SNR：

```text
-6 / 0 / +6 dB
```

将 42 号单 realization 结果作为单独参考行。

只回答：

```text
其结果是否落在本次 MC 分布的合理范围内。
```

不得要求数值完全一致，也不得用其作为 pass/fail 门。

---

## 19. 图表

生成以下论文可用图，禁止依赖运行时私有数据：

### F1

```text
Tangent / Core-Lite / Core-Plus
joint RMSE median 与 P90 vs white SNR
```

### F2

```text
Tangent fallback rate 与 raw-upgrade rate vs white SNR
```

### F3

```text
Tangent vs Core-Lite/Core-Plus
wins/ties/losses vs white SNR
```

### F4

```text
P1–P4 的 Tangent median/P90 RMSE vs white SNR
```

### F5

```text
K2 projected SNR distribution by P1–P4
```

使用：

```text
MATLAB 默认配色
清晰坐标轴
白化波束域 SNR 单位 dB
```

不制作复杂 dashboard。

---

## 20. 有效终态

### 20.1 完成

```text
STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_COMPLETE
```

### 20.2 完成并找到稳定区间

```text
STAGE8_K2_TANGENT_WHITE_SNR_WORKING_REGION_IDENTIFIED
```

### 20.3 完成但未找到稳定区间

```text
STAGE8_K2_TANGENT_WHITE_SNR_NO_STABLE_REGION_IDENTIFIED
```

`20.2` 和 `20.3` 都是科学有效结果。

### 20.4 无效

仅用于：

```text
registry/hash/count 失败
SNR target 失败
seed pairing 失败
truth leakage
checkpoint identity 失败
冻结路径改变
结果表不完整
```

状态：

```text
STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_INVALID
```

不得因为 Tangent 性能不好而判 INVALID。

---

## 21. 路线关闭规则

无论找到或未找到稳定区间：

```text
DEFAULT_K2 = TANGENT_PROFILE_SAFE

Tangent algorithm modified = false

Production interface modified = false

New online SNR threshold = false

Automatic selector = false

Further Stage8-K2 algorithm development =
NOT_AUTHORIZED
```

本轮后只允许：

```text
论文公式整理
实验图表整理
适用范围和限制写作
```

---

## 22. 新工具路径

只允许新增：

```text
tools/stage8_k2_white_snr_monte_carlo/
```

建议：

```text
tools/stage8_k2_white_snr_monte_carlo/
├── README.md
├── matlab/
│   ├── stage8_k2_mc_constants.m
│   ├── stage8_k2_mc_add_paths.m
│   ├── stage8_k2_mc_build_context.m
│   ├── stage8_k2_mc_build_registry.m
│   ├── stage8_k2_mc_generate_trial.m
│   ├── stage8_k2_mc_evaluate_trial.m
│   ├── stage8_k2_mc_checkpoint_write.m
│   ├── stage8_k2_mc_checkpoint_load.m
│   ├── stage8_k2_mc_checkpoint_validate.m
│   ├── stage8_k2_mc_status_write.m
│   ├── stage8_k2_mc_merge.m
│   ├── stage8_k2_mc_summarize.m
│   ├── stage8_k2_mc_plot.m
│   ├── stage8_k2_mc_run.m
│   └── stage8_k2_mc_file_sha256.m
└── tests/
    ├── test_42_formula_equivalence.m
    ├── test_white_target_contract.m
    ├── test_common_random_numbers.m
    ├── test_seed_uniqueness.m
    ├── test_trial_hash_uniqueness.m
    ├── test_truth_isolation.m
    ├── test_checkpoint_roundtrip.m
    ├── test_interrupted_checkpoint_resume.m
    ├── test_four_trial_smoke.m
    └── test_summary_fixture.m
```

---

## 23. Runtime 命令

正式 runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_white_snr_monte_carlo_v1
```

第一次启动或恢复：

```powershell
& 'E:\MATLABR2022b\bin\matlab.exe' `
  -singleCompThread `
  -batch "
  addpath('E:\bs_innovation\tools\stage8_k2_white_snr_monte_carlo\matlab');
  out = stage8_k2_mc_run( ...
      'E:\bs_innovation', ...
      'E:\bs_innovation_runtime\stage8_k2_white_snr_monte_carlo_v1');
  disp(out.status);
  "
```

若 runtime 已存在：

```text
runner 必须进入 RESUME；
不得覆盖；
不得要求删除。
```

预计 active runtime：

```text
约 4–7 小时
```

该值只用于资源规划，不是完成门。

---

## 24. 输出文件

新增：

```text
innovation-mining/
43_stage8_k2_white_snr_monte_carlo_theory_and_protocol.md

44_stage8_k2_white_snr_monte_carlo_registry.csv

44_stage8_k2_white_snr_monte_carlo_snr_trials.csv

44_stage8_k2_white_snr_monte_carlo_method_results.csv

44_stage8_k2_white_snr_monte_carlo_summary.csv

44_stage8_k2_white_snr_monte_carlo_profile_summary.csv

44_stage8_k2_white_snr_monte_carlo_exact_cell_summary.csv

44_stage8_k2_white_snr_monte_carlo_transition_summary.csv

44_stage8_k2_white_snr_monte_carlo_projected_snr_analysis.csv

44_stage8_k2_white_snr_monte_carlo_42_consistency.csv

44_stage8_k2_white_snr_monte_carlo_runtime_manifest.json

44_stage8_k2_white_snr_monte_carlo_and_route_closure.md
```

图：

```text
innovation-mining/figures/
44_white_snr_rmse_curve.png

44_white_snr_fallback_curve.png

44_white_snr_pairwise_curve.png

44_white_snr_profile_curve.png

44_projected_snr_profile_distribution.png
```

Prompt：

```text
innovation-mining/stage8_execution_prompts/active/
020_stage8_k2_white_snr_monte_carlo_v1.md
```

---

## 25. 提交顺序

### 25.1 Prompt / theory commit

新增：

```text
43_*
020 prompt
active README
```

active README：

```text
STAGE8_K2_WHITE_SNR_MONTE_CARLO_ACTIVE

DIRECT_TANGENT_BRANCH_EXECUTION
TANGENT_FROZEN
WHITE_SNR_CONTROL
1680_TRIALS
RESUMABLE_SINGLE_PROCESS
NO_PRODUCTION_CHANGE
```

提交：

```text
docs(stage8-k2): define white-SNR Monte Carlo closure
```

推送 Tangent 分支。

### 25.2 Tool commit

只提交：

```text
tools/stage8_k2_white_snr_monte_carlo/
```

提交：

```text
analysis(stage8-k2): add resumable white-SNR Monte Carlo
```

推送后要求：

```text
HEAD == origin Tangent
Git clean
```

正式运行只允许从该 clean pushed HEAD 启动。

### 25.3 Result commit

正式运行、独立复核完成后提交：

```text
44_*
44 figures
020 归档
active README
prompt manifest
00_DOCUMENT_STATUS_INDEX.md
```

提交：

```text
docs(stage8-k2): close Tangent white-SNR working region
```

推送当前分支。

---

## 26. 独立只读复核

正式 runner 完成后，使用一个全新的 MATLAB R2022b 单线程会话只读检查：

```text
registry 1680/1680
checkpoints 1680/1680
SNR rows 1680/1680
method rows 5040/5040
unique hashes 1680/1680
truth leakage 0
white target max error <= 1e-10 dB
runtime/Git artifact byte identity
manifest SHA-256
summary reconstruction
```

不得重新运行拟合。

若 runner 打印完成 marker 后在 MATLAB 退出阶段出现 shutdown anomaly：

```text
只有 artifacts 完整、hash 一致、独立复核通过，
才能记录为 POST_COMPUTATION_SHUTDOWN_ANOMALY；
否则按 INVALID。
```

---

## 27. 最终 active README

最终写为：

```text
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_COMPLETED

FINAL_WORKING_REGION_STATE:
<IDENTIFIED / NOT_IDENTIFIED>

DEFAULT_K2:
TANGENT_PROFILE_SAFE

TANGENT:
FROZEN

SNR CONTROL:
WHITENED_SEQUENTIAL_BEAMSPACE_EXPECTED_TOTAL_SNR

MONTE_CARLO:
1680 TRIALS
10 REPLICATES PER EXACT CELL

PRODUCTION:
UNCHANGED

ONLINE SNR THRESHOLD:
NOT_CREATED

FURTHER STAGE8-K2 ALGORITHM WORK:
NOT_AUTHORIZED

NEXT:
THESIS_DOCUMENTATION_ONLY
```

---

## 28. 最终 scope 审计

从：

```text
5753cd706d139dcc4904ff20b3cef205f5954e7d
```

到最终 HEAD，只允许：

```text
tools/stage8_k2_white_snr_monte_carlo/**
43_*
44_*
44 figures
020 新增和归档
00_DOCUMENT_STATUS_INDEX.md
active README
prompt archive manifest
```

必须零 diff：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**
tools/stage8_k2_snr_validation/**
beamspace_ml_v18/**
31_*–42_*
```

确认：

```text
origin/main unchanged
origin/research unchanged
HEAD == origin/experiment/stage8-k2-tangent
Git clean
untracked = 0
MATLAB / mwpython / coordinator / lock = 0 / 0 / 0 / 0
```

---

## 29. 最终报告格式

```text
STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_COMPLETE / INVALID

Branch:
Starting HEAD:
Prompt commit:
Tool commit:
Result commit:
Push:
Git clean:

Frozen Tangent changed:
false

42 evidence changed:
false

Registry:
- 1680/1680
- 7 SNR
- 240 base realizations
- 10 replicates
- seed pairing
- unique hashes

Execution:
- checkpoints
- resumes
- total active runtime
- median trial runtime
- shutdown anomaly

Integrity:
- SNR rows 1680
- method rows 5040
- truth leakage
- target error
- manifest identity

Overall by white SNR:
- Core-Lite
- Core-Plus
- Tangent
- median/P90
- fallback
- wins/ties/losses

By profile:
- P1
- P2
- P3
- P4
- first stable SNR or none

By noise:
- WHITE
- CORRELATED

By L:
- 1
- 4
- 8

Projected K2 SNR:
- fixed-bin analysis
- explanatory only

42 consistency:
- -6/0/+6 single-realization position in MC distribution

Final working-region state:
- IDENTIFIED / NOT_IDENTIFIED
- overall
- P1–P4

Paper-authorized statement:

Default K2:
TANGENT_PROFILE_SAFE

Algorithm modified:
false

Production modified:
false

Online threshold created:
false

Further algorithm work:
NOT_AUTHORIZED

Next:
THESIS_DOCUMENTATION_ONLY
```

完成后停止。
