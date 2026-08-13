# Stage8-K2-SNR1：Tangent 三层 SNR 审计与白化波束域 SNR 重参数化验证（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、Git 和 GitHub 推送的执行 AI。
>
> 本协议直接在长期 Tangent 分支上执行，不创建新分支：
>
> ```text
> experiment/stage8-k2-tangent
> ```
>
> 本轮不进行大规模蒙特卡洛，不修改 Tangent 核心算法，不修改白化、流形、
> profile likelihood、safe fallback、P1–P4 或既有 31_*–40_* 证据。
>
> 本轮依次完成：
>
> ```text
> Phase A：
> 对原 72 个 element-SNR 控制 trial 做三层 SNR 审计；
>
> Phase B：
> 使用相同 P1–P4、noise、L、source/noise seed，
> 把 -6/0/+6 dB 重新定义为
> “白化后顺序 Beamspace 的期望总能量 SNR”，
> 再运行同规模 72-trial 的 Core-Lite / Core-Plus / Tangent 比较；
>
> Phase C：
> 对比两种 SNR 口径并形成论文可用的工程解释。
> ```
>
> 协议：
>
> ```text
> STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_SNR_DOMAIN_AUDIT_AND_DIRECT_TANGENT_BRANCH_EXECUTION_V1
> ```

---

## 0. 当前状态与执行起点

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
dcde540e3f3af793c0b8beb18e41a798af64739a
docs(stage8-k2): record subspace baseline comparison
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

当前默认 K2：

```text
TANGENT_PROFILE_SAFE
```

当前 Tangent 算法状态：

```text
FROZEN
```

本协议对“直接在 Tangent 分支增加 SNR 验证工具、运行结果和文档”提供单独授权，
但不授权修改 Tangent 科学实现。

---

## 1. Git Preflight

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
HEAD == dcde540e3f3af793c0b8beb18e41a798af64739a

origin/main
== 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
== a7139204d717923cb89d0d629b67f1b3ab7ae94d

$status 为空
```

若 HEAD 是 `dcde540e` 的用户授权 docs-only 后代：

```text
停止；
报告实际 SHA 与 diff；
不得自行 reset 或选择新起点。
```

本协议：

```text
不创建 work 分支
不创建 research 分支
不修改 main
不 force push
```

---

## 2. 冻结边界

相对起点 `dcde540e`，以下必须保持字节不变：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**

beamspace_ml_v18/**

innovation-mining/31_*
innovation-mining/32_*
innovation-mining/33_*
innovation-mining/34_*
innovation-mining/39_*
innovation-mining/40_*
```

特别禁止修改：

```text
stage8_k2_tp_evaluate_trial.m
stage8_k2_tp_fit_safe.m
stage8_k2_tp_profile_scale.m
stage8_k2_tp_constants.m

estimate_stage8_known_k_local_cell.m
build_stage8_full_data_from_element.m
build_stage8_measurement_model.m
build_exact_subset_model.m

W_I
C_I
T_I
白化 rank
P1–P4
source/noise seeds
rho_min
scan nodes
safe likelihood selection
```

只允许新增：

```text
tools/stage8_k2_snr_validation/**

innovation-mining/41_*
innovation-mining/42_*

prompt 018
文档索引、active README、prompt archive manifest
```

---

## 3. 当前 SNR 的精确定义

### 3.1 阵元域模型

对一个 trial：

\[
Y_e=X_e+N_e,
\]

\[
X_e=A(\Theta)S.
\]

阵元噪声每 snapshot 的协方差：

\[
\operatorname{cov}(N_e)=R_e,
\]

当前 noise generator 使用：

\[
\sigma^2=1.
\]

当前注册白噪声和相关噪声均满足：

\[
\operatorname{diag}(R_e)=\mathbf 1,
\]

因此：

\[
\operatorname{tr}(R_e)=N_e.
\]

### 3.2 当前 31_* trial 的 element-SNR 控制

原 generator 将 signal 缩放到：

\[
\|X_e\|_F^2
=
10^{\gamma_e/10}N_eL.
\]

更一般地：

\[
\boxed{
\mathrm{SNR}_{e,\mathrm{exp}}
=
\frac{\|X_e\|_F^2}
{L\,\operatorname{tr}(R_e)}
}
\]

原 `snr_db` 对应：

\[
10\log_{10}\mathrm{SNR}_{e,\mathrm{exp}}.
\]

原始 `-6/0/+6 dB` 是阵元输入端的期望总能量 SNR，不是 Beamspace SNR。

---

## 4. 原始顺序 Beamspace 和白化 Beamspace SNR

### 4.1 原始顺序 Beamspace

固定 measurement：

\[
Y_b=W_I^HY_e.
\]

信号：

\[
X_b=W_I^HX_e.
\]

噪声协方差：

\[
\boxed{
C_b=W_I^HR_eW_I=C_I
}
\]

期望总能量 SNR：

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{raw,exp}}
=
\frac{\|X_b\|_F^2}
{L\,\operatorname{tr}(C_b)}
}
\]

实际 realization SNR：

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{raw,real}}
=
\frac{\|X_b\|_F^2}
{\|W_I^HN_e\|_F^2}
}
\]

### 4.2 白化顺序 Beamspace

\[
Y_w=T_IY_b=T_IW_I^HY_e.
\]

\[
X_w=T_IW_I^HX_e.
\]

白化噪声协方差：

\[
C_w=T_IC_bT_I^H.
\]

理论上：

\[
C_w=I_r,
\]

其中：

\[
r=\operatorname{rank}(C_b)
=
\texttt{model.whitening_rank}.
\]

但所有计算必须使用实际：

\[
\operatorname{tr}(C_w)
\]

而不是硬编码 \(r\)。

期望总能量 SNR：

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{white,exp}}
=
\frac{\|X_w\|_F^2}
{L\,\operatorname{tr}(C_w)}
}
\]

实际 realization SNR：

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{white,real}}
=
\frac{\|X_w\|_F^2}
{\|T_IW_I^HN_e\|_F^2}
}
\]

### 4.3 接收域 SNR 映射

定义：

\[
G_{\mathrm{raw,dB}}
=
\mathrm{SNR}_{b,\mathrm{raw,exp,dB}}
-
\mathrm{SNR}_{e,\mathrm{exp,dB}},
\]

\[
G_{\mathrm{white,dB}}
=
\mathrm{SNR}_{b,\mathrm{white,exp,dB}}
-
\mathrm{SNR}_{e,\mathrm{exp,dB}}.
\]

这些是当前固定 measurement 下的接收域 SNR 映射，不等同于完整雷达方程中的
发射增益、传播损耗或 CPI 积累增益。

---

## 5. 注册原始波束的峰值通道 SNR

用户关心“阵元相干叠加后某一工作波束的 SNR 是否已经很高”。

对原始注册 beam \(j\)：

\[
x_{b,j}
=
\mathbf w_j^HX_e.
\]

\[
\sigma_{b,j}^2
=
[C_b]_{jj}.
\]

定义：

\[
\boxed{
\mathrm{SNR}_{b,j,\mathrm{exp}}
=
\frac{\|x_{b,j}\|_2^2}
{L[C_b]_{jj}}
}
\]

以及：

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{peak,exp}}
=
\max_j
\mathrm{SNR}_{b,j,\mathrm{exp}}
}
\]

输出：

```text
peak beam index
peak expected raw-beam SNR
median beam SNR
```

这只用于说明实际注册工作波束的相干积累，不作为 Tangent 拟合的 SNR 控制量。

---

## 6. K2 特异的投影残差 SNR

总 Beamspace SNR 不足以描述两个近目标是否可分。

使用 truth-only 描述性诊断：

真实目标中心：

\[
c_{\rm true}
=
\frac{\xi_1+\xi_2}{2}.
\]

在白化顺序流形上：

\[
g_c=g(c_{\rm true}).
\]

\[
P_c^\perp
=
I-\frac{g_cg_c^H}{g_c^Hg_c}.
\]

定义真实中心投影后的 K2 信号：

\[
X_{\perp}
=
P_c^\perp X_w.
\]

期望投影噪声能量：

\[
E_{n,\perp}
=
L\operatorname{tr}
\left(
P_c^\perp C_w P_c^\perp
\right).
\]

定义：

\[
\boxed{
\mathrm{SNR}_{K2,\perp,\mathrm{exp}}
=
\frac{\|X_\perp\|_F^2}
{E_{n,\perp}}
}
\]

实际 realization：

\[
\boxed{
\mathrm{SNR}_{K2,\perp,\mathrm{real}}
=
\frac{\|X_\perp\|_F^2}
{\|P_c^\perp T_IW_I^HN_e\|_F^2}
}
\]

该指标：

```text
truth-only
analysis-only
不是在线 threshold
不进入拟合
不进入 safe selection
```

并继续保留已有：

```text
Gamma_K2_proxy
```

作为几何和差模信息描述。

---

# Phase A：原 72-trial 三层 SNR 审计

## 7. 原 trial 机械重建

只读使用：

```text
stage8_k2_tp_constants
stage8_k2_tp_build_registry
stage8_k2_tp_build_context
resolve_stage8_measurement_model
build_stage8_element_manifold
construct_deterministic_source_matrix
generate_stage8_element_noise
```

新增独立 generator，机械复制原 `generate_trial_local`：

1. 从原 registry 读取：
   ```text
   truth
   L
   element SNR label
   secondary power
   correlation
   source seed
   noise seed
   ```
2. 用同一 source seed 生成 `source_phase_rad`；
3. 构造同一未缩放 source matrix；
4. 采用原 element-SNR 缩放：
   \[
   \|X_e\|_F^2
   =
   10^{\mathrm{snr\_db}/10}N_eL;
   \]
5. 使用：
   ```text
   sigma2 = 1
   same noise seed
   ```
   生成噪声；
6. 构造同一：
   ```text
   Y_element
   element_trial_hash
   ```

必须满足：

```text
72/72 element_trial_hash
==
31_stage8_k2_tangent_profile_trials.csv
```

任一 hash 不同：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_INVALID
硬停止
不得执行 Phase B
```

### 7.1 Phase A 不运行任何拟合

禁止调用：

```text
estimate_stage8_known_k_local_cell
stage8_k2_tp_fit_safe
stage8_k2_cb_full4d_cml
任何 MUSIC / ESPRIT
```

Phase A 只重建：

```text
signal
noise
Y_element
```

并计算 SNR。

---

## 8. Phase A 输出字段

每个原 trial 一行，至少包含：

```text
trial_id
element_trial_hash
noise_profile_id
L
profile_id
original_element_snr_label_db

N_element
raw_beam_count
whitening_rank

element_signal_energy
element_noise_expected_energy
element_noise_realized_energy
element_snr_expected_db
element_snr_realized_db

raw_beam_signal_energy
raw_beam_noise_expected_energy
raw_beam_noise_realized_energy
raw_beam_snr_expected_db
raw_beam_snr_realized_db

white_beam_signal_energy
white_beam_noise_expected_energy
white_beam_noise_realized_energy
white_beam_snr_expected_db
white_beam_snr_realized_db

raw_receive_gain_db
white_receive_gain_db

raw_peak_beam_index
raw_peak_beam_snr_expected_db
raw_median_beam_snr_expected_db

true_center_projected_signal_energy
true_center_projected_noise_expected_energy
true_center_projected_noise_realized_energy
k2_projected_snr_expected_db
k2_projected_snr_realized_db

whitening_covariance_residual
whitening_trace
truth_only_diagnostic_flag
fitting_rerun_flag
```

固定：

```text
truth_only_diagnostic_flag = true
fitting_rerun_flag = false
```

---

## 9. Phase A 汇总

按以下层级汇总：

```text
ALL
original element-SNR label
P1–P4
noise
L
element-SNR label × profile
element-SNR label × noise
```

至少报告：

```text
N
element expected SNR median/min/max
element realized SNR median/p90
raw expected SNR median/min/max
white expected SNR median/min/max
raw peak-beam SNR median/p90
white receive gain median/min/max
K2 projected expected SNR median/p90
```

同时输出：

```text
原 -6/0/+6 dB element 标签
分别映射到多大的 whitened-beamspace SNR 区间。
```

禁止根据 Phase A 结果修改 Phase B 的 SNR 点。

---

# Phase B：白化 Beamspace SNR 重参数化试验

## 10. 新 SNR 控制口径

新 trial 的 SNR 目标固定为：

```text
-6 dB
0 dB
+6 dB
```

但其含义改为：

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{white,exp}}
}
\]

而不是 element SNR。

控制类型：

```text
WHITENED_SEQUENTIAL_BEAMSPACE_EXPECTED_TOTAL_SNR
```

---

## 11. 保持不变的因子

继续使用原 72 个因子组合：

```text
2 noise
× 3 L
× 3 white-beamspace SNR target
× 4 profiles
=
72 trials
```

保持：

```text
P1–P4 truth
secondary power
correlation
L=1 coherent contract
source seed
noise seed
measurement model
W_I / C_I / T_I
local angular domain
```

新 trial 与原 trial 一一配对：

```text
same profile
same noise
same L
same numeric SNR label
same source seed
same noise seed
same source phase
same normalized source matrix
same noise realization

only common signal amplitude scale changes
```

---

## 12. 白化 Beamspace SNR 的缩放公式

对未缩放 source matrix \(S_0\)：

\[
X_{e,0}
=
A(\Theta)S_0.
\]

\[
X_{w,0}
=
T_IW_I^HX_{e,0}.
\]

目标线性 SNR：

\[
\gamma_w^\star
=
10^{\mathrm{snr\_target\_db}/10}.
\]

白化噪声期望总能量：

\[
E_{n,w}
=
L\operatorname{tr}(C_w).
\]

公共 source scale：

\[
\boxed{
\alpha
=
\sqrt{
\frac{
\gamma_w^\star
L\operatorname{tr}(C_w)
}{
\|X_{w,0}\|_F^2
}
}
}
\]

然后：

\[
S=\alpha S_0,
\]

\[
X_e=A(\Theta)S.
\]

必须验证：

\[
\frac{
\left|
\mathrm{SNR}_{b,\mathrm{white,exp}}
-
\gamma_w^\star
\right|
}{
\max(1,\gamma_w^\star)
}
\le10^{-12}.
\]

### 12.1 禁止 realization normalization

不得使用：

\[
\|T_IW_I^HN_e\|_F^2
\]

来决定 \(\alpha\)。

也就是说：

```text
只控制 expected whitened-beamspace SNR；
不把每个随机噪声 realization 强行归一化到同一实际 SNR。
```

否则会消除有限样本噪声能量波动，破坏后续蒙特卡洛口径。

---

## 13. 新 registry

新增 registry 字段：

```text
trial_id
paired_original_trial_id
global_trial_index

snr_control_domain
white_beamspace_snr_target_db

resulting_element_snr_expected_db
resulting_raw_beamspace_snr_expected_db
resulting_white_beamspace_snr_expected_db

noise_profile_id
L
profile_id
source_seed
noise_seed
```

新 trial ID 前缀：

```text
SW1_
```

例如：

```text
SW1_K2_N1_L4_SM6_P1
```

新 `element_trial_hash` 必须包含：

```text
协议 ID
新 trial_id
Y_element
truth
white SNR target
computed element SNR
source/noise seeds
noise profile
```

72 个 hash 必须唯一。

---

## 14. Phase B 方法

同一个新 `Y_element` 上只运行：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

调用冻结接口：

```text
estimate_stage8_known_k_local_cell
stage8_k2_tp_fit_safe
```

不得运行：

```text
Full4D
MUSIC
Root-MUSIC
ESPRIT
Vincent
bootstrap
automatic K
```

---

## 15. Phase B 结果字段

每方法每 trial 一行：

```text
trial_id
paired_original_trial_id
method_id

noise_profile_id
L
profile_id

snr_control_domain
white_beamspace_snr_target_db

element_snr_expected_db
element_snr_realized_db

raw_beam_snr_expected_db
raw_beam_snr_realized_db

white_beam_snr_expected_db
white_beam_snr_realized_db

k2_projected_snr_expected_db
k2_projected_snr_realized_db

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

truth metrics 只能在拟合完成后计算。

---

## 16. Phase B 汇总

按：

```text
ALL
white SNR target
P1–P4
noise
L
white SNR × profile
white SNR × noise
```

报告：

```text
valid rate
median/p90 joint RMSE
median/p90 center error
median/p90 axis error
median/p90 rho error
median/p90 separation-vector error
upgrade/fallback rate
mean score/SVD
median/p90 runtime
resulting element SNR median/min/max
realized white SNR median/p90
```

配对：

```text
Tangent vs Core-Lite
Tangent vs Core-Plus
```

tie：

```text
1e-6 deg
```

仅用于展示。

---

## 17. 原口径与新口径的比较

将原 `31_*` 结果与 Phase A 的 SNR audit join：

```text
原 element-controlled performance
+
其实际 expected whitened-beamspace SNR
```

将 Phase B 结果作为：

```text
white-beamspace-controlled performance
```

输出两个不同层次的比较。

### 17.1 允许的比较

```text
原 element 标签映射到的实际 white SNR；
在同一 white SNR target 下新试验的性能；
达到某一 white SNR 需要的 element input SNR；
不同 profile/noise 下 receive-gain 的变化。
```

### 17.2 禁止的表述

不得仅按相同 `-6/0/+6` 数字标签直接宣称：

```text
新定义提高/降低了算法性能。
```

因为两种标签控制的不是同一个输入能量域。

---

## 18. 本轮不是蒙特卡洛

必须在报告中写明：

```text
每个 factor cell 仍只有一个 source/noise realization；
本轮是 SNR 口径验证和配对重参数化试验；
不是统计充分的 Monte Carlo；
不能由本轮估计置信区间、稳定 P90 或 outlier 概率。
```

本轮完成后：

```text
不自动启动 800/1200-trial Monte Carlo；
后续 Monte Carlo 需要用户单独授权。
```

---

## 19. 工程解释边界

报告必须明确：

### 全息凝视/同时多波束接口

```text
W_I 的全部注册复合波束来自同一个 Y_element；
本实验不是时间扫描；
Tangent 是检测后的单单元 known-K=2 局部精化后端。
```

### 当前不包含

```text
宽波束发射增益损失
RCS / range / radar equation
CFAR
range-Doppler detection
CPI pulse integration model
unknown K
tracking
```

因此 element SNR 和 white-beamspace SNR 都是接收估计模块内部口径。

---

## 20. 白化保持不变

不得因为 Tangent 沿二维轴做一维 profile 而删除白化。

本轮必须验证：

\[
C_b=W_I^HR_eW_I,
\]

\[
C_w=T_IC_bT_I^H\approx I_r.
\]

白化作用是：

```text
修正非正交波束和相关阵元噪声；
把 generalized weighted CML 转换为 Euclidean CML；
定义 Tangent 投影和 Fisher metric 的正确噪声几何。
```

白化与：

```text
是否先搜索 azimuth
是否先搜索 elevation
是否沿 Tangent 轴搜索 rho
```

无关。

---

## 21. 新工具路径

只允许新增：

```text
tools/stage8_k2_snr_validation/
```

建议：

```text
tools/stage8_k2_snr_validation/
├── README.md
├── matlab/
│   ├── stage8_k2_snr_constants.m
│   ├── stage8_k2_snr_add_paths.m
│   ├── stage8_k2_snr_build_context.m
│   ├── stage8_k2_snr_rebuild_original_trial.m
│   ├── stage8_k2_snr_build_white_control_registry.m
│   ├── stage8_k2_snr_generate_white_control_trial.m
│   ├── stage8_k2_snr_compute_metrics.m
│   ├── stage8_k2_snr_projected_k2_metric.m
│   ├── stage8_k2_snr_evaluate_trial.m
│   ├── stage8_k2_snr_summarize.m
│   ├── stage8_k2_snr_run.m
│   └── stage8_k2_snr_stable_hash.m
└── tests/
    ├── test_original_72_hash_identity.m
    ├── test_element_snr_definition.m
    ├── test_raw_beam_covariance_identity.m
    ├── test_whitening_identity.m
    ├── test_white_snr_scaling_contract.m
    ├── test_expected_vs_realized_noise_contract.m
    ├── test_paired_seed_and_source_shape.m
    ├── test_projected_k2_snr_fixture.m
    ├── test_no_truth_leakage.m
    └── test_four_trial_smoke.m
```

---

## 22. 固定测试

### T1：原 72 hash

```text
72/72 exact
```

### T2：Element SNR

对原 trial：

\[
\mathrm{SNR}_{e,\mathrm{exp,dB}}
=
\text{original label}
\]

误差：

```text
<= 1e-10 dB
```

### T3：Raw Beam covariance

\[
\frac{
\|C_I-W_I^HR_eW_I\|_F
}{
\max(1,\|C_I\|_F)
}
\le10^{-12}.
\]

### T4：Whitening

\[
\frac{
\|T_IC_IT_I^H-I_r\|_F
}{
\sqrt r
}
\le10^{-10}.
\]

同时：

```text
size(T_I,1) == model.whitening_rank
```

### T5：White SNR scaling

对 4 个 smoke trial 和三个 target：

```text
-6 / 0 / +6 dB
```

缩放后 expected white SNR 误差：

```text
<= 1e-10 dB
```

### T6：Expected 与 realized 分离

验证：

```text
scale factor 不读取 realized noise；
改变 noise seed 不改变 alpha；
改变 noise realization 会改变 realized SNR。
```

### T7：配对 source

原和新 trial：

```text
source seed 相同
noise seed 相同
source phase 相同
归一化 source matrix 相同
noise matrix 相同
只有公共 signal scale 不同
```

### T8：Projected K2 SNR

合成 fixture 中：

```text
单目标退化/零分离 → projected signal 接近 0
非零双目标分离 → projected signal 非负有限
```

只检查数学行为，不设性能门。

### T9：Truth isolation

拟合入口不接收：

```text
truth
SNR audit metric
profile ID
expected gain
projected K2 SNR
```

### T10：4-trial smoke

固定：

```text
P1 WHITE L=4 target 0 dB
P2 WHITE L=4 target 0 dB
P3 CORRELATED L=4 target 0 dB
P4 CORRELATED L=4 target 0 dB
```

要求三方法均有明确 valid/invalid 输出，Tangent safe result 可用。

---

## 23. 正式执行方式

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
scheduler
checkpoint framework
bootstrap
```

Runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_snr_domain_validation_v1
```

执行顺序：

```text
1. 测试
2. Phase A 72-trial SNR audit
3. Phase A 完整性检查
4. Phase B 4-trial smoke
5. Phase B 72-trial formal run
6. 汇总
7. 写 Git evidence
```

若中断：

```text
删除本轮未提交 runtime；
从头执行；
不建立恢复系统。
```

---

## 24. 输出文件

新增：

```text
innovation-mining/
41_stage8_k2_snr_domain_theory_and_protocol.md

42_stage8_k2_original_snr_audit_trials.csv

42_stage8_k2_original_snr_audit_summary.csv

42_stage8_k2_white_beamspace_control_registry.csv

42_stage8_k2_white_beamspace_control_snr_trials.csv

42_stage8_k2_white_beamspace_control_method_results.csv

42_stage8_k2_white_beamspace_control_summary.csv

42_stage8_k2_snr_control_comparison.csv

42_stage8_k2_snr_domain_validation.md

42_stage8_k2_snr_runtime_manifest.json
```

Prompt：

```text
innovation-mining/stage8_execution_prompts/active/
018_stage8_k2_snr_domain_validation_v1.md
```

---

## 25. 终态

有效完成：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_COMPLETE
```

仅以下情况为无效：

```text
原 72 hash 不匹配
source/noise pairing 不一致
SNR 公式合同失败
whitening identity 失败
truth leakage
冻结路径改变
结果行数不完整
非有限值未按 NaN/invalid 合同处理
```

终态：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_INVALID
```

### 25.1 不设新的性能保留门

无论结果如何：

```text
原 STAGE8_K2_TANGENT_PROFILE_RETAIN 不变
默认 K2 仍为 TANGENT_PROFILE_SAFE
不修改生产接口
不修改算法
```

本轮只改变论文和工程上的 SNR 解释。

---

## 26. 提交顺序：直接提交到 Tangent 分支

### 26.1 Prompt / theory commit

新增：

```text
41 theory/protocol
018 prompt
active README
```

active README：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_ACTIVE

DIRECT_TANGENT_BRANCH_EXECUTION
TANGENT_ALGORITHM_FROZEN
NO_MONTE_CARLO
NO_PRODUCTION_CHANGE
```

提交：

```text
docs(stage8-k2): define SNR domain validation
```

推送：

```powershell
git push origin experiment/stage8-k2-tangent
```

### 26.2 Tool commit

只提交：

```text
tools/stage8_k2_snr_validation/
```

提交：

```text
analysis(stage8-k2): add beamspace SNR audit and control
```

推送 Tangent 分支。

### 26.3 Result commit

提交：

```text
42_*
```

归档：

```text
018_stage8_k2_snr_domain_validation_v1.md
→ archive/completed/
```

更新：

```text
archive/PROMPT_ARCHIVE_MANIFEST.csv
00_DOCUMENT_STATUS_INDEX.md
active/README.md
```

active README 终态：

```text
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_SNR_DOMAIN_VALIDATION_COMPLETED

DEFAULT_K2:
TANGENT_PROFILE_SAFE

SNR REPORTING:
ELEMENT_INPUT
RAW_SEQUENTIAL_BEAMSPACE
WHITENED_SEQUENTIAL_BEAMSPACE
K2_PROJECTED_DIAGNOSTIC

TANGENT ALGORITHM:
FROZEN

MONTE_CARLO:
NOT_EXECUTED
REQUIRES_SEPARATE AUTHORIZATION
```

提交：

```text
docs(stage8-k2): record SNR domain validation
```

推送当前分支。

---

## 27. 最终 scope 审计

从起点：

```text
dcde540e3f3af793c0b8beb18e41a798af64739a
```

到最终 HEAD，只允许：

```text
tools/stage8_k2_snr_validation/**
41_*
42_*
018 prompt 新增和归档
00_DOCUMENT_STATUS_INDEX.md
active README
prompt archive manifest
```

以下必须零 diff：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**
beamspace_ml_v18/**
31_*–40_*
```

确认：

```text
origin/main unchanged
origin/research/stage8-k2-vincent-anchored unchanged

HEAD == origin/experiment/stage8-k2-tangent
Git clean

MATLAB / mwpython / coordinator / lock:
0 / 0 / 0 / 0
```

---

## 28. 最终报告格式

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_COMPLETE / INVALID

Branch:
Starting HEAD:
Prompt commit:
Tool commit:
Result commit:
Push:
Git clean:

Frozen Tangent changed:
false

Existing evidence changed:
false

Phase A integrity:
- original hashes 72/72
- source/noise pairing
- element SNR identity
- raw covariance identity
- whitening identity

Original SNR mapping:
- element label -6 dB → white SNR range
- element label 0 dB → white SNR range
- element label +6 dB → white SNR range
- raw peak-beam SNR
- receive gain
- projected K2 SNR

Phase B integrity:
- registry 72/72
- method rows 216/216
- truth leakage 0
- target white SNR error
- paired seeds/noise

White-beamspace-controlled results:
- Core-Lite
- Core-Plus
- Tangent
- -6 / 0 / +6 dB
- P1–P4
- noise
- L
- valid/fallback
- joint/center/axis/rho/vector metrics
- runtime

Element-SNR vs white-SNR interpretation:

Default K2:
TANGENT_PROFILE_SAFE

Tangent algorithm modified:
false

Whitening removed:
false

Monte Carlo executed:
false

Next Monte Carlo authorized:
false
```

完成后停止，不自动启动更大规模蒙特卡洛。
