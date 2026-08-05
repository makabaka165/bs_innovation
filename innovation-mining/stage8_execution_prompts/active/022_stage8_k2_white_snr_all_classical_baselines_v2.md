# Stage8-K2-ACB2：统一白化顺序波束域 SNR 的全经典算法比较、定时续接与可复绘数据冻结（V2）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、Git 和 GitHub 推送的执行 AI。
>
> 本协议从当前已经完成的 white-SNR 经典基线分支继续，但创建新的子 work 分支，保证当前分支、长期 Tangent 分支和旧 subspace 分支均不被修改。
>
> 本轮只运行尚未在 `44_*` white-SNR Monte Carlo trial 集合上执行的经典算法：
>
> ```text
> ELEMENT_MUSIC_K2
> ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
> ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
> ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
> ```
>
> 已经存在的下列结果一律从已提交证据读取，不重新拟合：
>
> ```text
> CORE_LITE
> CORE_PLUS
> TANGENT_PROFILE_SAFE
> FULL4D_BEAMSPACE_CML_MULTISTART
> BEAMSPACE_MUSIC_K2
> FULL4D_ELEMENT_CML_MULTISTART
> ```
>
> 最终生成一个覆盖 10 种方法、1680 个完全相同 trial、统一 white-SNR 横轴的长表，以及足够完整的诊断、汇总和代表性谱数据，使后续修改论文图表时无需重新运行估计算法。
>
>
> 长时间计算必须采用：
>
> ```text
> 后台单 MATLAB runner
> + Windows Task Scheduler 每 15 分钟一次的轻量控制 Tick
> + 自动恢复、finalization、独立审计和 Git 收束
> ```
>
> 执行 AI 在成功注册定时任务并完成一次启动确认后，必须结束交互式持续监控：
>
> ```text
> 禁止 while/sleep 轮询；
> 禁止每隔数分钟反复 Get-Process；
> 禁止持续读取 checkpoint 并在对话中输出阶段；
> 禁止为了“看进度”不断消耗 Codex 会话。
> ```
>
> 定时任务只在本机 runtime 中写入每 15 分钟一次的状态与 ETA；计算结束后由同一控制状态机自动启动 fresh-session finalization、fresh-session independent audit、结果归档、提交和推送，最后注销自身。
>
> 协议：
>
> ```text
> STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_V2
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_WORK_BRANCH_V2
> ```

---

## 0. 执行目标和边界

### 0.1 源分支

```text
work/stage8-k2-white-snr-classical-baselines-v1
```

预期精确 HEAD：

```text
224eedb8282b64fec210e77081bc4fc7748c1fc1
```

该提交已经完成：

```text
44_*：1680-trial white-SNR Monte Carlo；
46_*：Full4D Beamspace CML、Beamspace MUSIC、Element CML 比较；
Tangent / Core 结果和全部 44 trial 身份；
独立审计与 artifact hashes。
```

### 0.2 新 work 分支

从 `224eedb8282b64fec210e77081bc4fc7748c1fc1` 创建：

```text
work/stage8-k2-white-snr-all-classical-baselines-v1
```

### 0.3 不允许自动合并

完成后禁止：

```text
git merge
git merge --ff-only
git rebase
git cherry-pick
git push experiment/stage8-k2-tangent
git push work/stage8-k2-white-snr-classical-baselines-v1
git push main
删除任何旧分支
```

所有新增代码和结果只推送到：

```text
work/stage8-k2-white-snr-all-classical-baselines-v1
```

最终状态：

```text
USER_REVIEW
MERGE_BACK_NOT_AUTHORIZED
```

---

# Part A：Git 和证据身份

## 1. Git Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git switch work/stage8-k2-white-snr-classical-baselines-v1

$head = (git rev-parse HEAD).Trim()
$remote = (git rev-parse origin/work/stage8-k2-white-snr-classical-baselines-v1).Trim()
$tangent = (git rev-parse origin/experiment/stage8-k2-tangent).Trim()
$main = (git rev-parse origin/main).Trim()
$research = (git rev-parse origin/research/stage8-k2-vincent-anchored).Trim()
$oldSubspace = (git rev-parse origin/work/stage8-k2-subspace-baselines-v1).Trim()
$status = @(git status --porcelain=v1 --untracked-files=all)
```

要求：

```text
$head == $remote
$head == 224eedb8282b64fec210e77081bc4fc7748c1fc1

$tangent == d2d59fe550d8999dc8589aa76e52e89736539b66
$main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
$research == a7139204d717923cb89d0d629b67f1b3ab7ae94d
$oldSubspace == dcde540e3f3af793c0b8beb18e41a798af64739a
$status 为空
```

若任一 ref 不一致：

```text
硬停止；
打印实际 ref；
不得 reset、force-push 或自行选择新起点。
```

确认本地和远端均不存在：

```text
work/stage8-k2-white-snr-all-classical-baselines-v1
```

创建：

```powershell
git switch -c work/stage8-k2-white-snr-all-classical-baselines-v1 `
  224eedb8282b64fec210e77081bc4fc7748c1fc1
```

---

## 2. 冻结路径

相对起点 `224eedb8282b64fec210e77081bc4fc7748c1fc1`，以下必须保持字节不变：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**
tools/stage8_k2_snr_validation/**
tools/stage8_k2_white_snr_monte_carlo/**
tools/stage8_k2_white_snr_classical_baselines/**

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
innovation-mining/43_*
innovation-mining/44_*
innovation-mining/45_*
innovation-mining/46_*
```

禁止修改：

```text
Tangent / Core / Full4D / MUSIC / subspace 科学实现；
W_I / C_I / T_I；
白化 rank；
P1–P4；
44 registry、seeds 和 trial hash；
white-SNR 定义与缩放公式；
旧 subspace 方法的 smoothing、root 和 ESPRIT 常量；
生产接口。
```

只允许新增或修改：

```text
tools/stage8_k2_white_snr_all_classical_baselines/**

innovation-mining/47_*
innovation-mining/48_*
innovation-mining/figures/48_*

innovation-mining/stage8_execution_prompts/active/
022_stage8_k2_white_snr_all_classical_baselines_v2.md

本新 work 分支内的：
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
innovation-mining/stage8_execution_prompts/active/README.md
innovation-mining/stage8_execution_prompts/archive/PROMPT_ARCHIVE_MANIFEST.csv
```

---

## 3. 只读证据 44 和 46

必须读取并验证：

```text
44_stage8_k2_white_snr_monte_carlo_registry.csv
44_stage8_k2_white_snr_monte_carlo_snr_trials.csv
44_stage8_k2_white_snr_monte_carlo_method_results.csv
44_stage8_k2_white_snr_monte_carlo_runtime_manifest.json

46_stage8_k2_white_snr_classical_baseline_registry_audit.csv
46_stage8_k2_white_snr_classical_baseline_results.csv
46_stage8_k2_white_snr_classical_baseline_runtime_manifest.json
```

### 3.1 Evidence 44 要求

```text
status = STAGE8_K2_TANGENT_WHITE_SNR_MONTE_CARLO_COMPLETE
registry = 1680
SNR rows = 1680
method rows = 5040
unique trial hashes = 1680
base realizations = 240
truth leakage = 0
artifact SHA-256 全部匹配
```

每个 trial 恰有：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

### 3.2 Evidence 46 要求

```text
status = STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPARISON_COMPLETE
independent audit = PASS
baseline rows = 5040
checkpoints = 1680
artifact SHA-256 = 15/15
truth/profile/Tangent/Core start leakage = 0
merge_back = false
```

每个 trial 恰有：

```text
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
FULL4D_ELEMENT_CML_MULTISTART
```

### 3.3 Evidence identity

新工具 constants 必须冻结：

```text
44 manifest SHA-256
44 registry hash
46 manifest SHA-256
46 artifact inventory hash
源提交 224eedb...
```

任一 evidence 文件或 hash 不一致：

```text
STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_INVALID
不得运行新方法。
```

---

# Part B：统一 trial 设计

## 4. 完全复用 44 号 1680 个 trial

不创建新 seed，不改变任何因子：

```text
white SNR = -6 / 0 / +6 / +10 / +14 / +18 / +22 dB
noise = WHITE / STAGE5_TOEPLITZ_CORRELATED
L = 1 / 4 / 8
profile = P1 / P2 / P3 / P4
replicate = 1..10
```

总数：

\[
7\times2\times3\times4\times10=1680.
\]

对每个 registry row：

1. 调用冻结的 `stage8_k2_mc_generate_trial` 或其冻结下游；
2. 重建完全相同的 `Y_element`；
3. 检查：
   ```text
   trial_id
   measurement_hash
   element_trial_hash
   source seed
   noise seed
   white-SNR target
   ```
4. white-SNR target error：
   ```text
   <= 1e-10 dB
   ```

要求：

```text
1680/1680 element_trial_hash exact
```

已经存在的方法不得重新拟合。

---

## 5. SNR 口径

所有图表默认横轴：

```text
WHITENED_SEQUENTIAL_BEAMSPACE_EXPECTED_TOTAL_SNR
```

但新方法使用完整阵元域，因此必须同时把 44 号已经保存的以下字段 join 到每个方法 row：

```text
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
```

这样后续可在不重跑算法的情况下改用：

```text
white-SNR
resulting element-SNR
K2 projected-SNR
```

重新绘图。

必须在报告中说明：

> 对阵元域算法而言，white-SNR 是统一 trial 的实验控制坐标，不是其内部估计器显式读取的 SNR 参数。

---

# Part C：最终方法集合和比较层级

## 6. 最终 10 种方法

### Tier A：同 15 维白化顺序 Beamspace

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
```

### Tier B：完整阵元域二维真实流形

```text
FULL4D_ELEMENT_CML_MULTISTART
ELEMENT_MUSIC_K2
```

### Tier C：垂直 ULA 子结构 + 条件方位 CML

```text
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

最终统一长表必须为：

```text
1680 trials × 10 methods = 16800 rows
```

每个 trial-method 即使 N/A 也保留一行。

---

## 7. 本轮只运行的 4 种方法

```text
ELEMENT_MUSIC_K2
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

固定新方法行数：

```text
1680 × 4 = 6720 rows
```

已存在的 6 种方法只从 `44_* / 46_*` 读取。

正式 manifest 必须记录：

```text
existing_method_rerun_count = 0
Tangent rerun count = 0
Core rerun count = 0
Full4D rerun count = 0
Beamspace MUSIC rerun count = 0
```

---

# Part D：新方法理论和冻结实现

## 8. Element MUSIC

方法 ID：

```text
ELEMENT_MUSIC_K2
```

### 8.1 数据域

完整阵元数据精确白化：

\[
Y_{e,w}=R_e^{-1/2}Y_e.
\]

完整二维圆柱阵字典：

\[
A_w(\phi,\theta)=R_e^{-1/2}a(\phi,\theta).
\]

### 8.2 MUSIC 谱

\[
\widehat R_e=\frac1L Y_{e,w}Y_{e,w}^H.
\]

known \(K=2\)，噪声投影：

\[
P_n=I-E_sE_s^H.
\]

\[
P_{\rm MUSIC}(\phi,\theta)
=\frac1{a_w^H(\phi,\theta)P_n a_w(\phi,\theta)}.
\]

### 8.3 冻结接口

必须直接调用：

```text
stage8_k2_cb_music(..., "ELEMENT", ...)
stage8_k2_cb_peak_picker
stage8_k2_cb_prepare_resources 或等价单噪声资源构造
```

固定：

```text
二维网格步长 = 0.005°
chunk size = 2048
known K = 2
```

### 8.4 Applicability

```text
L=1：
NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK

L=4/8：
APPLICABLE
```

固定计数：

```text
1120 applicable
560 structural N/A
```

只有两个独立二维局部峰时才输出 K2。

禁止：

```text
强制选择两个最大网格点；
按 SNR 改峰值门；
truth-based peak separation；
把单峰/N/A 计为 Tangent 胜利。
```

### 8.5 预计算内存

为避免同时保存两个约 2080×19521 的复数字典：

```text
按 noise profile 顺序处理；
一次只保留一个 A_element_white；
完成该 noise 的 840 trial 后释放；
不得同时常驻两套完整阵元字典。
```

Element MUSIC 字典预计算时间应除以该 noise 下实际适用行数：

```text
2 L values × 7 SNR × 4 profiles × 10 replicates = 560
```

不得沿用未计 replicate 的 56-row 摊销。

---

## 9. 圆柱阵垂直结构

对第 \(n\) 层、第 \(q\) 个方位列：

\[
a_{n,q}(\phi,\theta)
=
\exp\left\{jk_0\left[
R\cos\theta\cos(\phi-\varphi_q)
+n d_z\sin\theta
\right]\right\}.
\]

精确分解：

\[
a(\phi,\theta)=b(\phi,\theta)\otimes v(\theta),
\]

\[
v_n(\theta)=e^{jnk_0d_z\sin\theta}.
\]

垂直移位不变性：

\[
J_2v(\theta)=e^{jk_0d_z\sin\theta}J_1v(\theta).
\]

本轮不得把整个圆柱阵错误描述为 ULA；只在真实垂直维使用 ULA 子空间算法，方位由完整圆柱阵条件 CML 估计。

---

## 10. 垂直 covariance 和 FBSS

复用冻结函数：

```text
stage8_k2_sb_noise_factors
stage8_k2_sb_vertical_covariance
stage8_k2_sb_fbss_covariance
```

固定：

```text
N_el = 32
N_az = 65
K = 2
smoothing length M_s = 31
subarray count P = 2
```

构造：

\[
\widehat R_v
=
\frac1{LN_{az}}
\sum_{\ell=1}^L X_{\ell,azw}X_{\ell,azw}^H.
\]

Forward smoothing：

\[
R_F=\frac1P\sum_{p=0}^{P-1}J_p\widehat R_vJ_p^H.
\]

Forward/backward：

\[
R_{FB}=\frac12(R_F+\Pi R_F^*\Pi).
\]

不得修改 smoothing length 或根据 SNR/profile 调参。

---

## 11. Generalized FBSS-MUSIC + 条件方位 CML

方法 ID：

```text
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
```

复用：

```text
stage8_k2_sb_gfbss_music
stage8_k2_sb_conditional_az_cml
```

### 11.1 Generalized vertical MUSIC

\[
R_{n,s}=J_0R_{el}J_0^H=L_sL_s^H,
\]

\[
C_s=L_s^{-1},
\qquad
\overline R=C_sR_{FB}C_s^H.
\]

\[
P_{GFBSS}(\theta)
=
\frac1{\|E_n^HC_sv_s(\theta)\|_2^2}.
\]

固定俯仰网格：

```text
9.8° : 0.001° : 10.2°
```

### 11.2 Applicability

```text
P1/P3/P4：适用
P2：NOT_APPLICABLE_EQUAL_ELEVATION_MULTIPLICITY
WHITE/CORRELATED：均适用
L=1/4/8：均适用
```

固定计数：

```text
1260 applicable
420 structural N/A
```

---

## 12. FBSS Root-MUSIC + 条件方位 CML

方法 ID：

```text
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
```

复用：

```text
stage8_k2_sb_root_music
stage8_k2_sb_conditional_az_cml
```

### 12.1 Root polynomial

\[
Q_n=E_nE_n^H,
\]

\[
D(z)=v^T(z^{-1})Q_nv(z).
\]

系数：

\[
c_\ell=\sum_{m-n=\ell}[Q_n]_{mn}.
\]

选取：

```text
单位圆内或数值容差内；
映射到注册俯仰域；
最接近单位圆；
两个不同俯仰。
```

固定：

```text
root_unit_circle_tolerance = 1e-7
root_duplicate_tolerance_deg = 1e-5
```

### 12.2 Applicability

```text
WHITE + P1/P3/P4 + L=1/4/8：适用
P2：结构性 N/A
CORRELATED：标准 Root-MUSIC 结构性 N/A
```

固定计数：

```text
630 applicable
1050 structural N/A
```

---

## 13. FBSS LS-ESPRIT + 条件方位 CML

方法 ID：

```text
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

复用：

```text
stage8_k2_sb_ls_esprit
stage8_k2_sb_conditional_az_cml
```

\[
S_1=U_s(1:M_s-1,:),
\qquad
S_2=U_s(2:M_s,:),
\]

\[
\Psi=S_1^\dagger S_2.
\]

\[
\widehat\theta_k
=
\arcsin\left(\frac{\arg\lambda_k}{k_0d_z}\right).
\]

Applicability 与 Root-MUSIC 相同：

```text
630 applicable
1050 structural N/A
```

本轮不增加：

```text
TLS-ESPRIT
Unitary ESPRIT
colored-noise generalized ESPRIT
```

---

## 14. 共同条件方位 CML

只有垂直阶段输出两个有效俯仰后，才运行：

```text
stage8_k2_sb_conditional_az_cml
```

给定：

\[
\widehat\theta_1,\widehat\theta_2,
\]

使用完整阵元白化数据和真实圆柱阵流形：

\[
A_w(\phi_1,\phi_2)
=
R_e^{-1/2}
[a(\phi_1,\widehat\theta_1),a(\phi_2,\widehat\theta_2)].
\]

\[
(\widehat\phi_1,\widehat\phi_2)
=
\arg\min_{\phi_1,\phi_2}
\|\Pi_{A_w}^\perp Y_{e,w}\|_F^2.
\]

固定：

```text
azimuth grid = 7.4° : 0.02° : 8.6°
ordered coarse pairs = 61×61 = 3721
top starts = 4
max sweeps = 8
scan nodes = 9
TolX = 1e-4°
MaxFunEvals = 80
```

不得使用 Tangent、Core 或 truth 作为 start。

---

# Part E：Applicability 与 truth isolation

## 15. Applicability 规则

Applicability 是实验结构分类，不允许改进估计器输出。

记录两个不同字段：

```text
applicability_uses_registered_scenario_flag
profile_used_in_fit_flag
```

要求：

```text
P2 structural N/A 可由注册 profile 识别；
applicability_uses_registered_scenario_flag = true；
profile_used_in_fit_flag = false；
估计器本身不接收 profile_id 或 truth angles。
```

Root/ESPRIT 的 colored-noise N/A 由已知噪声模型决定，不属于 truth leakage。

Element MUSIC 的 L=1 N/A 由样本数决定。

---

## 16. Fit 输入禁止字段

所有新方法正式 fit 入口必须拒绝：

```text
truth
truth_angles_deg
profile_id
profile_label
Tangent result
Core result
Full4D result
RMSE
working-region label
K2 projected SNR
white-SNR threshold
其他方法估计角度
```

允许：

```text
Y_element
measurement/noise model
L
固定 local domain
固定 algorithm constants
预计算字典/whitener/noise factors
结构 applicability 状态
```

正式 manifest 必须为：

```text
truth leakage = 0
profile leakage into fit = 0
Tangent/Core/Full4D initializer use = 0
```

---

# Part F：新结果和完整画图数据

## 17. 新方法原始结果表

新增：

```text
48_stage8_k2_white_snr_new_classical_method_results.csv
```

固定：

```text
6720 rows
1680 trials × 4 methods
```

每行至少包含：

```text
trial_id
global_trial_index
element_trial_hash
measurement_hash

method_id
method_family
observation_domain
comparison_tier
same_hardware_interface_to_tangent
uses_full_2d_cylinder_manifold
uses_vertical_ula_stage

white_beamspace_snr_target_db
element_snr_expected_db
element_snr_realized_db
raw_beam_snr_expected_db
raw_beam_snr_realized_db
white_beam_snr_expected_db
white_beam_snr_realized_db
k2_projected_snr_expected_db
k2_projected_snr_realized_db

noise_profile_id
L
profile_id
replicate_id
base_realization_index
source_seed
noise_seed

applicable
applicability_status
applicability_uses_registered_scenario_flag
fit_valid
fit_status
failure_stage

angles_hat_deg
azimuths_hat_deg
elevations_hat_deg
RSS
loglik
effective_rank

joint_RMSE_deg
azimuth_RMSE_deg
elevation_RMSE_deg
center_error_deg
axis_error_deg
rho_error_deg
rho_relative_error
separation_vector_error_deg

score_call_count
SVD_call_count
eig_call_count
runtime_sec
preprocess_runtime_sec
elevation_runtime_sec
conditional_az_runtime_sec

truth_used_in_fit_flag
profile_used_in_fit_flag
tangent_used_in_start_flag
core_used_in_start_flag
```

Truth metrics 只能在拟合完成后填入。

---

## 18. 新方法诊断表

新增：

```text
48_stage8_k2_white_snr_new_classical_diagnostics.csv
```

固定：

```text
6720 rows
```

保存：

```text
raw vertical eigenvalues top 6
FBSS eigenvalues top 6
raw signal/noise eigengap
FBSS signal/noise eigengap
vertical covariance condition proxy
FBSS condition proxy

vertical Hermitian residual
FBSS Hermitian residual
FB structure residual
noise whitening residual

Element MUSIC sample rank
Element MUSIC rank threshold
Element MUSIC local peak count
Element MUSIC top-10 peak az/el/value

GFBSS candidate count
GFBSS top-10 elevation peak angles/values
GFBSS selected elevations

Root polynomial degree
all root count
registered root count
top-10 registered root elevations
root moduli
root phases
selected roots

ESPRIT shift matrix rank
S1 singular values
ESPRIT eigenvalue real/imag/modulus/phase
estimated elevations

conditional az CML executed
conditional az CML valid
conditional status
coarse candidate count
continuous start count
best coarse loglik
selected start
sweep count
```

大型向量使用可解析的 JSON 字符串或 MATLAB `mat2str(...,17)`，禁止丢失数值精度。

---

## 19. 统一 10 方法 plot-ready 长表

新增：

```text
48_stage8_k2_white_snr_all_method_plot_data.csv
```

固定：

```text
16800 rows
1680 trials × 10 methods
```

来源：

```text
44 method rows：3 methods
46 baseline rows：3 methods
48 new rows：4 methods
```

每个 trial 必须恰有以下 10 个 method ID：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
FULL4D_ELEMENT_CML_MULTISTART
ELEMENT_MUSIC_K2
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

统一列至少包括：

```text
trial identity
全部 SNR 坐标
profile/noise/L/replicate
method/interface labels
applicable/valid/status/failure stage
angles and all error metrics
runtime/score/SVD/eig
local peak/root/elevation/conditional-CML status
```

这张表是后续性能曲线的主要数据源。

---

## 20. 汇总表

新增：

```text
48_stage8_k2_white_snr_all_method_summary.csv
48_stage8_k2_white_snr_all_method_profile_summary.csv
48_stage8_k2_white_snr_all_method_noise_summary.csv
48_stage8_k2_white_snr_all_method_snapshot_summary.csv
48_stage8_k2_white_snr_all_method_exact_cell_summary.csv
48_stage8_k2_white_snr_all_method_applicability_summary.csv
48_stage8_k2_white_snr_all_method_failure_summary.csv
48_stage8_k2_white_snr_all_method_pairwise_vs_tangent.csv
48_stage8_k2_white_snr_all_method_complexity_summary.csv
48_stage8_k2_white_snr_subspace_eigenstructure_summary.csv
```

### 20.1 SNR overall

每方法、每 SNR：

```text
N = 240 total trial rows
```

报告：

```text
applicable count
valid count
valid rate
structural N/A count
algorithmic invalid count
median/P90 RMSE（仅 valid）
median/P90 az/el/center/axis/rho/vector
runtime
score/SVD/eig
```

### 20.2 SNR × profile

每方法每组：

```text
N = 60
```

### 20.3 SNR × noise

每方法每组：

```text
N = 120
```

### 20.4 SNR × L

每方法每组：

```text
N = 80
```

### 20.5 Exact cell

每方法：

```text
SNR × noise × L × profile
10 replicates
```

exact cell 只报告描述性 median、valid rate 和 failure reason；不得把 N=10 的 P90 当作稳定尾部统计。

---

# Part G：代表性谱数据冻结

## 21. 代表性 trial 集合

为以后绘制谱图而不重新运行，预注册：

```text
white SNR = 全部 7 点
profile = P1/P2/P3/P4
noise = WHITE/CORRELATED
L = 8
replicate = 1
```

总计：

```text
56 representative trials
```

该集合只由因子值选择，不读取算法结果。

---

## 22. 代表性谱文件

新增：

```text
48_stage8_k2_white_snr_representative_spectra.mat
48_stage8_k2_white_snr_representative_spectra_index.csv
```

MAT 文件使用：

```text
-v7.3
```

至少保存：

### 22.1 Element MUSIC

对全部 56 trial 保存：

```text
az_grid_deg
el_grid_deg
normalized_spectrum_db
sample eigenvalues
sample rank
local peak mask 或 local peak indices
top-10 peak values/angles
selected peaks/status
```

谱以每 trial 最大值归一化为 0 dB。

### 22.2 GFBSS-MUSIC

对 P1/P3/P4 的适用 trial 保存：

```text
elevation_grid_deg
normalized_elevation_spectrum_db
signal eigenvalues
candidate peaks
selected elevations/status
```

P2 保存明确 N/A index，不伪造谱。

### 22.3 Root-MUSIC

对 WHITE、P1/P3/P4 保存：

```text
polynomial coefficients
all roots
registered roots
selected roots
root-derived elevations
```

### 22.4 ESPRIT

对 WHITE、P1/P3/P4 保存：

```text
S1 singular values
Psi eigenvalues
moduli/phases
estimated elevations/status
```

### 22.5 一致性

保存的诊断谱重新执行峰值/root/eigenvalue选择后，必须与正式 method row 完全一致。

不得保存全部 1680 trial 的完整二维 MUSIC 谱，避免无必要的仓库膨胀。

---

## 23. 画图 manifest

新增：

```text
48_stage8_k2_white_snr_plot_data_manifest.json
```

记录：

```text
method labels
method display order
comparison tiers
column names and units
valid-rate denominator definition
RMSE denominator definition
N/A handling
SNR coordinate definitions
representative spectrum indices
all plot-data SHA-256
recommended plot recipes
```

---

# Part H：可离线复绘脚本

## 24. 不运行估计器的绘图入口

新增：

```text
tools/stage8_k2_white_snr_all_classical_baselines/plotting/
stage8_k2_wacb_plot_from_committed_data.m
```

该脚本只允许读取：

```text
48_* CSV
48_* representative_spectra.mat
48_* plot manifest
```

禁止调用：

```text
trial generator
Tangent/Core
Full4D
MUSIC fit
FBSS/Root/ESPRIT fit
conditional CML
```

脚本必须能够在没有 runtime 目录的情况下重新生成全部 `48_*` 图。

新增测试：

```text
TEST_PLOT_FROM_COMMITTED_DATA_WITHOUT_FIT_PATHS
```

---

# Part I：统计解释规则

## 25. Invalid 和 N/A 不得混入 RMSE

对每个方法必须分别报告：

```text
total count
applicable count
valid count
structural N/A count
algorithmic invalid count
```

RMSE 只在：

```text
applicable && fit_valid
```

的行上计算。

禁止：

```text
把 invalid RMSE 设为 Inf；
把 N/A 当作 Tangent win；
只报告成功子集 RMSE而不同时报告有效率。
```

---

## 26. 与 Tangent 的配对

只在同 trial 且新方法 valid 时比较：

\[
\Delta=RMSE_{\rm new}-RMSE_{\rm Tangent}.
\]

定义：

```text
Delta < -1e-6°：new method win
abs(Delta) <= 1e-6°：tie
Delta > +1e-6°：Tangent win
```

输出字段建议始终从 Tangent 视角同时给出：

```text
new_wins
ties
tangent_wins
```

避免方向歧义。

---

## 27. 可比较性分类

每个方法、每个 white-SNR：

### `ROBUSTLY_COMPARABLE`

同时满足：

```text
applicable count >= 30
valid count >= 30
valid rate >= 0.50
```

才允许讨论 median/P90 和 wins/losses 的稳定性能排序。

### `APPLICABILITY_LIMITED`

```text
valid count > 0
但未达到 ROBUSTLY_COMPARABLE
```

只报告成功条件和条件 RMSE，不宣称总体优劣。

### `NO_VALID_OUTPUT`

```text
valid count = 0
```

### `STRUCTURAL_NA`

该方法在该组全部结构性不适用。

这些分类只用于论文解释，不形成在线 selector。

---

## 28. 两阶段方法分解

对 GFBSS / Root / ESPRIT 必须分开报告：

```text
elevation-stage valid rate
conditional az CML execution rate
conditional az CML valid rate
end-to-end valid rate
```

如果 elevation 有效但条件方位 CML 失败，必须独立计数。

这样可以区分：

```text
俯仰提取瓶颈
方位条件 ML 瓶颈
```

---

# Part J：固定测试

## 29. T1：Evidence 44/46 identity

验证：

```text
44：1680/1680/5040，全部 hashes；
46：1680 checkpoints、5040 rows、15 artifacts、audit PASS；
existing method rerun count = 0。
```

## 30. T2：1680 trial reconstruction

```text
1680/1680 element_trial_hash exact
white target max error <= 1e-10 dB
```

不运行新方法。

## 31. T3：Frozen constants identity

新 constants 中下列字段必须与冻结 old tools 完全一致：

```text
Element MUSIC grid/chunk/applicable L
N_el/N_az/K
smoothing length/subarray count
elevation grid/domain
azimuth grid/domain
conditional CML starts/sweeps/nodes/TolX
Root tolerances
rank and tie tolerances
```

## 32. T4：Element MUSIC direct-call equivalence

选择 4 个代表 trial，新 adapter 输出必须与直接调用：

```text
stage8_k2_cb_music(..., "ELEMENT", ...)
```

在以下字段一致：

```text
applicable
fit_valid
fit_status
sample rank
local peak count
selected endpoints
```

## 33. T5：Structured-method direct-call equivalence

分别对：

```text
GFBSS-MUSIC
Root-MUSIC
LS-ESPRIT
conditional az CML
```

验证新 orchestration 与冻结函数直接调用一致。

## 34. T6：Applicability count

必须精确为：

```text
Element MUSIC applicable = 1120
GFBSS applicable = 1260
Root-MUSIC applicable = 630
LS-ESPRIT applicable = 630
new rows = 6720
```

## 35. T7：Truth isolation

```text
truth/profile/Tangent/Core/Full4D result 不进入 fit input
```

## 36. T8：Representative spectra consistency

保存谱重新做峰值/root/eigenvalue选择，结果与 method row 一致。

## 37. T9：Checkpoint round trip

验证：

```text
.tmp 写入
schema/hash 校验
原子 rename
resume skip
invalid final checkpoint hard stop
```

## 38. T10：All-method plot table fixture

人工小 fixture 验证：

```text
10 methods per trial
N/A/invalid/valid 分类
16800-row 目标 schema
pairwise 方向
summary counts
```

## 39. T11：Plot-only regeneration

在不添加任何 fit 路径、没有 runtime 的 fresh MATLAB 会话中，从 committed data 重新生成测试图。

## 40. T12：Eight-trial smoke

预注册：

```text
P1 WHITE L=8 +10 dB R01
P2 WHITE L=8 +14 dB R01
P3 WHITE L=4 +18 dB R01
P4 WHITE L=1 +22 dB R01
P1 CORRELATED L=8 +10 dB R01
P2 CORRELATED L=4 +14 dB R01
P3 CORRELATED L=8 +18 dB R01
P4 CORRELATED L=1 +22 dB R01
```

要求所有四种新方法给出明确：

```text
VALID / INVALID / STRUCTURAL_NA
```

不设性能门。

## 40A. T13：定时任务与控制状态机

使用临时 runtime 和临时任务名验证：

```text
任务注册成功；
触发间隔精确为 15 分钟；
MultipleInstances = IgnoreNew；
StartWhenAvailable = true；
Tick 不包含 while/sleep 轮询；
同一 Tick 只读取一次进程/状态快照；
命名 mutex 能阻止重入；
PREPARED → TRIALS_RUNNING；
无活动 MATLAB 且 checkpoint 未完成 → 只启动一次 RESUME；
READY_TO_FINALIZE → fresh-session finalization；
FINALIZED_AWAITING_AUDIT → fresh-session verify；
AUDIT PASS → READY_FOR_GIT_CLOSEOUT；
Git closeout dry-run 的 allowed-path 审计；
重复 Tick 幂等；
COMPLETE 后任务注销；
HARD_STOPPED 后不得继续启动 MATLAB 或 Git 操作。
```

测试不得运行正式 1680-trial，也不得修改真实 work 分支。

正式执行前必须：

```text
13/13 PASS
```

---

# Part K：后台执行、定时监控与自动续接

## 41. 新工具目录

只新增：

```text
tools/stage8_k2_white_snr_all_classical_baselines/
```

建议结构：

```text
tools/stage8_k2_white_snr_all_classical_baselines/
├── README.md
├── matlab/
│   ├── stage8_k2_wacb_constants.m
│   ├── stage8_k2_wacb_add_paths.m
│   ├── stage8_k2_wacb_build_context.m
│   ├── stage8_k2_wacb_load_evidence44.m
│   ├── stage8_k2_wacb_load_evidence46.m
│   ├── stage8_k2_wacb_build_registry.m
│   ├── stage8_k2_wacb_reconstruct_trial.m
│   ├── stage8_k2_wacb_prepare_noise_resources.m
│   ├── stage8_k2_wacb_fit_new_methods.m
│   ├── stage8_k2_wacb_element_music_diagnostics.m
│   ├── stage8_k2_wacb_subspace_diagnostics.m
│   ├── stage8_k2_wacb_result_row.m
│   ├── stage8_k2_wacb_diagnostic_row.m
│   ├── stage8_k2_wacb_representative_spectra.m
│   ├── stage8_k2_wacb_checkpoint_write.m
│   ├── stage8_k2_wacb_checkpoint_load.m
│   ├── stage8_k2_wacb_checkpoint_validate.m
│   ├── stage8_k2_wacb_scan_checkpoints.m
│   ├── stage8_k2_wacb_status_write.m
│   ├── stage8_k2_wacb_merge.m
│   ├── stage8_k2_wacb_summarize.m
│   ├── stage8_k2_wacb_run.m
│   ├── stage8_k2_wacb_verify.m
│   └── stage8_k2_wacb_file_sha256.m
├── powershell/
│   ├── Stage8K2WACBController.ps1
│   └── Stage8K2WACBCloseout.ps1
├── plotting/
│   └── stage8_k2_wacb_plot_from_committed_data.m
└── tests/
    ├── test_evidence44_46_identity.m
    ├── test_1680_trial_reconstruction.m
    ├── test_frozen_constants_identity.m
    ├── test_element_music_direct_equivalence.m
    ├── test_structured_direct_equivalence.m
    ├── test_applicability_counts.m
    ├── test_truth_isolation.m
    ├── test_representative_spectra_consistency.m
    ├── test_checkpoint_roundtrip.m
    ├── test_all_method_plot_fixture.m
    ├── test_plot_only_regeneration.m
    ├── test_eight_trial_smoke.m
    └── test_scheduled_controller_state_machine.ps1
```

PowerShell 控制脚本属于执行控制面，不得包含或复制科学估计公式。

---

## 42. Runtime、任务名与控制状态

正式 runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_white_snr_all_classical_baselines_v2
```

固定任务名：

```text
BSInnovation-Stage8K2-WACB-V2
```

固定控制脚本：

```text
E:\bs_innovation\
tools\stage8_k2_white_snr_all_classical_baselines\
powershell\Stage8K2WACBController.ps1
```

固定 closeout 脚本：

```text
E:\bs_innovation\
tools\stage8_k2_white_snr_all_classical_baselines\
powershell\Stage8K2WACBCloseout.ps1
```

控制状态写在 runtime：

```text
controller/controller_state.json
controller/latest_tick.json
controller/latest_tick.txt
controller/tick_history.jsonl
controller/final_status.json
controller/final_status.txt
controller/controller.log
```

`controller_state.json` 至少包含：

```text
protocol
branch
formal_head
code_identity
registry_hash
evidence44_identity
evidence46_identity

state
last_transition_utc
last_tick_utc
task_name
task_interval_minutes

trial_launch_count
resume_launch_count
finalization_launch_count
audit_launch_count
git_closeout_attempt_count

active_matlab_pid
completed_checkpoints
remaining_checkpoints
median_trial_runtime_sec
ETA_sec

last_error
hard_stop_reason
result_commit
push_status
```

允许状态：

```text
PREPARED
TRIALS_RUNNING
READY_TO_FINALIZE
FINALIZATION_RUNNING
READY_FOR_AUDIT
AUDIT_RUNNING
READY_FOR_GIT_CLOSEOUT
GIT_PUSH_PENDING
COMPLETE
HARD_STOPPED
```

状态迁移必须原子写入；禁止依靠聊天上下文保存状态。

---

## 43. Trial checkpoint

每个 trial 一个 checkpoint：

```text
checkpoints/
trial_<global_index>_<trial_id>.mat
```

包含：

```text
44 registry row
44 trial hash
4 new method rows
4 diagnostic rows
representative-spectrum payload 或引用（若属于代表集合）
scientific hash
code identity
registry hash
completed UTC
runtime
```

写入：

```text
.tmp
→ load/schema/hash 验证
→ atomic rename
→ final validation
```

恢复：

```text
valid checkpoint 跳过
.tmp 对应 trial 重跑
invalid final checkpoint 硬停止
不得自动覆盖
```

每个 trial 完成后，由 MATLAB runner 原子更新：

```text
status/latest_status.json
status/latest_status.txt
```

状态至少包含：

```text
completed / 1680
remaining
current trial
current noise/SNR/L/profile/replicate
elapsed active sec
median trial sec
ETA sec

Element MUSIC valid/single-peak/N/A
GFBSS elevation-valid/end-to-end-valid
Root elevation-valid/end-to-end-valid
ESPRIT elevation-valid/end-to-end-valid
conditional az CML valid count
last update UTC
```

MATLAB runner 可以每 25 trial 写一次自身 logfile，但执行 AI 不得持续读取并转述。

---

## 44. 按 noise 分组与后台 MATLAB 启动

为限制 Element MUSIC 字典内存：

```text
先处理全部 WHITE trial；
释放 WHITE element dictionary；
再处理全部 CORRELATED trial。
```

合并时按 `global_trial_index` 恢复原 44 顺序。

使用：

```text
MATLAB R2022b
-singleCompThread
1 MATLAB process
无 parpool/parfor
```

后台启动必须使用 `Start-Process`，将 stdout/stderr 写入固定 logfile；控制脚本启动后立即返回，不占用定时任务进程。

试验/恢复命令的语义等价于：

```powershell
Start-Process `
  -FilePath 'E:\MATLABR2022b\bin\matlab.exe' `
  -ArgumentList @(
    '-singleCompThread',
    '-batch',
    "<调用 stage8_k2_wacb_run 的表达式>"
  ) `
  -RedirectStandardOutput '<runtime>\logs\trial_or_resume.log' `
  -RedirectStandardError '<runtime>\logs\trial_or_resume.err.log' `
  -PassThru
```

必须记录实际 PID 和完整启动身份。

控制器只能把命令行同时匹配以下内容的 MATLAB 视为本协议进程：

```text
stage8_k2_wacb_run 或 stage8_k2_wacb_verify
精确 repo path
精确 runtime path
-singleCompThread
```

禁止仅按进程名 `MATLAB.exe` 计数。

---

## 45. Windows 定时任务与“禁止 Codex 持续轮询”

### 45.1 注册合同

在 Prompt/theory 和 Tool commit 均已推送、Git clean、13/13 测试通过后，执行：

```powershell
& 'E:\bs_innovation\tools\stage8_k2_white_snr_all_classical_baselines\powershell\Stage8K2WACBController.ps1' `
  -Action InstallAndStart `
  -RepoDir 'E:\bs_innovation' `
  -RuntimeRoot 'E:\bs_innovation_runtime\stage8_k2_white_snr_all_classical_baselines_v2' `
  -MatlabExe 'E:\MATLABR2022b\bin\matlab.exe' `
  -TaskName 'BSInnovation-Stage8K2-WACB-V2' `
  -IntervalMinutes 15
```

`InstallAndStart` 必须：

1. 验证当前分支、HEAD、origin、Git clean 和固定证据；
2. 确认没有同名任务，或同名任务的 action/参数与本协议完全相同；
3. 注册当前登录用户上下文中的 Windows Scheduled Task；
4. 固定每 15 分钟触发一次 `-Action Tick`；
5. 设置：
   ```text
   StartWhenAvailable = true
   MultipleInstances = IgnoreNew
   ```
6. 先执行一次立即 Tick，启动正式 MATLAB；
7. 验证任务已注册、后台 MATLAB 身份正确、controller state 为 `TRIALS_RUNNING`；
8. 返回：
   ```text
   SCHEDULED_CONTROLLER_INSTALLED_AND_STARTED
   ```

定时任务使用当前登录用户的交互令牌，不要求在提示词中保存明文密码。

计算机关机或错过触发后，在下次开机登录时应通过 `StartWhenAvailable` 继续 Tick；MATLAB runner 从有效 checkpoint 恢复。

### 45.2 Tick 合同

每个 15 分钟 Tick 必须：

```text
获得命名 mutex；
只执行一次状态快照；
最多执行一次状态迁移或一次后台进程启动；
写 controller 状态；
立即退出。
```

禁止在 Tick 中：

```text
while 循环
do/for 等待循环
Start-Sleep
连续 Get-Process 轮询
等待 MATLAB 退出
重复打印大量 checkpoint
```

如果上一个 Tick 尚未结束：

```text
本 Tick 因 MultipleInstances=IgnoreNew 或 mutex 直接退出。
```

### 45.3 执行 AI 的交互边界

`InstallAndStart` 成功后，执行 AI 只允许进行一次只读确认：

```text
Scheduled Task exists
controller state = TRIALS_RUNNING
active MATLAB identity = exact
```

随后必须停止交互式监控并结束当前执行会话。

明确禁止：

```text
每 5/10/15 分钟由 Codex 主动检查；
反复运行 Get-Process；
反复读取 latest_status；
在对话中持续输出“仍在运行”；
使用长时间 sleep 占住 Codex 会话。
```

之后的状态由 Windows Scheduled Task 写入 runtime；只有用户明确另行询问时，才允许人工执行一次：

```powershell
Stage8K2WACBController.ps1 -Action Status
```

---

## 46. 定时控制状态机、自动 finalization、审计与 Git 收束

### 46.1 `PREPARED`

满足：

```text
正式 tool HEAD 已推送；
Git clean；
13/13 测试 PASS；
runtime identity 已冻结；
0 个正式 checkpoint。
```

Tick 启动第一阶段 trial MATLAB，转为：

```text
TRIALS_RUNNING
```

### 46.2 `TRIALS_RUNNING`

若精确匹配的 trial MATLAB 仍在运行：

```text
读取一次 status/latest_status.json；
更新 completed/remaining/ETA；
退出。
```

若没有活动 trial MATLAB：

- `completed < 1680` 且没有 hard-stop marker：
  ```text
  启动同一 runner 的 RESUME；
  resume_launch_count += 1；
  保持 TRIALS_RUNNING。
  ```
- `completed == 1680` 且 `READY_TO_FINALIZE` 已写入：
  ```text
  转 READY_TO_FINALIZE。
  ```
- checkpoint 无效、身份错误或 runner 明确失败：
  ```text
  转 HARD_STOPPED；
  不得重启。
  ```

一次 Tick 最多启动一个 MATLAB。

### 46.3 `READY_TO_FINALIZE`

只有：

```text
1680/1680 checkpoints valid
.tmp = 0
trial MATLAB = 0
```

时，启动一个全新 `-singleCompThread` MATLAB 会话，再次调用 runner 完成：

```text
merge
48 CSV/MAT/JSON
figures
report
runtime manifest
```

状态转：

```text
FINALIZATION_RUNNING
```

### 46.4 `FINALIZATION_RUNNING`

若 finalization MATLAB 在运行，Tick 只记录状态并退出。

若进程结束：

- manifest 状态为：
  ```text
  FINALIZED_AWAITING_INDEPENDENT_AUDIT
  ```
  则转：
  ```text
  READY_FOR_AUDIT
  ```
- 否则：
  ```text
  HARD_STOPPED
  ```

### 46.5 `READY_FOR_AUDIT`

启动一个全新 `-singleCompThread` MATLAB：

```text
stage8_k2_wacb_verify
```

该会话只读复核，不重新运行任何方法。

状态转：

```text
AUDIT_RUNNING
```

### 46.6 `AUDIT_RUNNING`

若 audit MATLAB 在运行，Tick 只记录状态并退出。

若进程结束且满足：

```text
independent audit = PASS
1680 checkpoints
6720 new rows
6720 diagnostic rows
16800 all-method rows
representative spectra identity
artifact SHA-256 PASS
existing_method_rerun_count = 0
```

则转：

```text
READY_FOR_GIT_CLOSEOUT
```

否则：

```text
HARD_STOPPED
```

### 46.7 `READY_FOR_GIT_CLOSEOUT`

控制器同步调用：

```text
Stage8K2WACBCloseout.ps1
```

Closeout 必须：

1. 验证没有本协议 MATLAB、mwpython、lock 或 `.tmp`；
2. 验证源 white-classic、Tangent、old subspace、main、research refs 未移动；
3. 验证 worktree diff 只在本协议允许路径；
4. 将：
   ```text
   active/022_stage8_k2_white_snr_all_classical_baselines_v2.md
   ```
   原字节移动到：
   ```text
   archive/completed/
   ```
5. 更新：
   ```text
   active README
   PROMPT_ARCHIVE_MANIFEST.csv
   00_DOCUMENT_STATUS_INDEX.md
   ```
6. `git add` 只允许路径；
7. 运行：
   ```text
   git diff --cached --check
   ```
8. 提交：
   ```text
   docs(stage8-k2): record unified white-SNR all-classical comparison
   ```
9. 只推送：
   ```text
   work/stage8-k2-white-snr-all-classical-baselines-v1
   ```
10. 验证：
    ```text
    HEAD == origin/new-work
    Git clean
    ```
11. 写入 `result_commit` 和 `push_status`。

若本地已经有同标题结果提交，Closeout 必须幂等验证，不得创建重复提交。

若 commit 已成功但 push 因网络失败：

```text
状态转 GIT_PUSH_PENDING；
下一次 15 分钟 Tick 只重试 push；
不得重复 finalization、audit 或 commit。
```

### 46.8 `COMPLETE`

推送成功后：

```text
写 controller/final_status.json 和 .txt；
确认 Next = USER_REVIEW；
注销 BSInnovation-Stage8K2-WACB-V2；
验证任务已不存在；
状态保持 COMPLETE。
```

任务注销失败时，必须先把 task action 改为只读 `Status`，再标记：

```text
MANUAL_TASK_REMOVAL_REQUIRED
```

不得让完成后的任务再次启动 MATLAB。

### 46.9 `HARD_STOPPED`

出现任何身份、checkpoint、artifact、truth isolation、scope 或 Git 边界错误时：

```text
记录 hard_stop_reason；
不再启动 MATLAB；
不执行 Git closeout；
注销定时任务；
保留 runtime 和日志；
等待用户检查。
```

禁止自动删除、自动修复或放宽门限。

### 46.10 每 15 分钟状态内容

每个 Tick 的 `latest_tick.txt/json` 至少记录：

```text
state
completed / 1680
remaining
last valid checkpoint
active MATLAB PID / role
elapsed active runtime
median trial runtime
ETA
Element MUSIC valid/single-peak/N/A
GFBSS elevation/end-to-end valid
Root elevation/end-to-end valid
ESPRIT elevation/end-to-end valid
conditional az CML valid
last error
next automatic action
last tick UTC
```

这些文件只存在 runtime，不进入 Git 科学证据。

---

# Part L：图表

## 47. 必须生成的图

```text
48_white_snr_all_method_valid_rate.png
48_white_snr_all_method_joint_rmse_median.png
48_white_snr_all_method_joint_rmse_p90.png
48_white_snr_subspace_elevation_valid_rate.png
48_white_snr_conditional_az_cml_valid_rate.png
48_white_snr_failure_reason_stack.png
48_white_snr_runtime_complexity.png
48_white_snr_pairwise_vs_tangent.png
48_white_snr_profile_valid_rate.png
48_white_snr_element_music_representative_spectra.png
48_white_snr_gfbss_representative_spectra.png
48_white_snr_root_esprit_diagnostics.png
```

图中必须：

```text
把三种 comparison tier 分开标识；
不把 N/A 画成失败；
RMSE 曲线同时标注 valid rate 或使用明显的有效样本说明；
Element/vertical methods 标明不是 Tangent 的同硬件接口。
```

所有图必须能由 committed `48_*` 数据离线重建。

---

# Part M：输出文件

## 48. 理论与协议

```text
innovation-mining/
47_stage8_k2_white_snr_all_classical_baseline_theory_and_protocol.md
```

## 49. 结果数据

```text
48_stage8_k2_white_snr_all_classical_registry_audit.csv
48_stage8_k2_white_snr_new_classical_method_results.csv
48_stage8_k2_white_snr_new_classical_diagnostics.csv
48_stage8_k2_white_snr_all_method_plot_data.csv
48_stage8_k2_white_snr_all_method_summary.csv
48_stage8_k2_white_snr_all_method_profile_summary.csv
48_stage8_k2_white_snr_all_method_noise_summary.csv
48_stage8_k2_white_snr_all_method_snapshot_summary.csv
48_stage8_k2_white_snr_all_method_exact_cell_summary.csv
48_stage8_k2_white_snr_all_method_applicability_summary.csv
48_stage8_k2_white_snr_all_method_failure_summary.csv
48_stage8_k2_white_snr_all_method_pairwise_vs_tangent.csv
48_stage8_k2_white_snr_all_method_complexity_summary.csv
48_stage8_k2_white_snr_subspace_eigenstructure_summary.csv
48_stage8_k2_white_snr_representative_spectra.mat
48_stage8_k2_white_snr_representative_spectra_index.csv
48_stage8_k2_white_snr_plot_data_manifest.json
48_stage8_k2_white_snr_all_classical_runtime_manifest.json
48_stage8_k2_white_snr_all_classical_comparison.md
```

图放在：

```text
innovation-mining/figures/48_*
```

---

# Part N：最终解释状态

## 50. 完整性终态

成功：

```text
STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE
```

无效：

```text
STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_INVALID
```

INVALID 仅用于：

```text
44/46 evidence identity 失败
1680 trial hash 失败
white-SNR target 失败
冻结算法或常量改变
truth leakage
checkpoint/schema/hash 失败
6720/16800 行数不完整
代表性谱与正式结果不一致
artifact hash 失败
```

不得因为经典算法有效率低或性能差而判 INVALID。

---

## 51. 科学解释状态

对每个新方法输出：

```text
ROBUST_REGION_IDENTIFIED
APPLICABILITY_LIMITED
NO_VALID_REGION
STRUCTURAL_REFERENCE_ONLY
```

并给出：

```text
首个 valid-rate >= 0.50 的 white-SNR（若存在）
首个 ROBUSTLY_COMPARABLE white-SNR（若存在）
各 P1/P3/P4 的有效区间
P2 structural N/A
WHITE/CORRELATED 边界
L 依赖性
```

不得建立在线 SNR threshold 或自动方法选择器。

---

# Part O：提交顺序

## 52. Prompt / theory commit

新增：

```text
47_*
active/022_stage8_k2_white_snr_all_classical_baselines_v2.md
active README
```

active README：

```text
STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_ACTIVE

BRANCH:
work/stage8-k2-white-snr-all-classical-baselines-v1

SOURCE:
work/stage8-k2-white-snr-classical-baselines-v1@224eedb

EXISTING METHODS:
READ_ONLY_NOT_RERUN

NEW METHODS:
ELEMENT_MUSIC
GFBSS_MUSIC_AZ_CML
FBSS_ROOT_MUSIC_AZ_CML
FBSS_LS_ESPRIT_AZ_CML

EXECUTION_CONTROL:
WINDOWS_SCHEDULED_TASK
15_MINUTE_TICK
NO_CODEX_POLLING

MERGE_BACK:
NOT_AUTHORIZED
```

提交：

```text
docs(stage8-k2): define unified white-SNR classical comparison
```

首次推送：

```powershell
git push -u origin work/stage8-k2-white-snr-all-classical-baselines-v1
```

---

## 53. Tool commit、测试与定时启动

只提交：

```text
tools/stage8_k2_white_snr_all_classical_baselines/**
```

其中必须包含：

```text
MATLAB runner / verify
PowerShell scheduled controller
PowerShell closeout
plot-only regeneration
13 项测试
```

提交：

```text
analysis(stage8-k2): add unified white-SNR subspace baseline runner
```

推送后要求：

```text
HEAD == origin/new-work
Git clean
13/13 tests PASS
MATLAB / mwpython / coordinator / lock = 0 / 0 / 0 / 0
```

然后只执行一次：

```powershell
Stage8K2WACBController.ps1 -Action InstallAndStart ...
```

成功标志：

```text
SCHEDULED_CONTROLLER_INSTALLED_AND_STARTED
task interval = 15 minutes
controller state = TRIALS_RUNNING
exact MATLAB process = 1
```

执行 AI 完成这一确认后必须停止持续轮询并结束交互式执行。后续 trial、resume、finalization、audit、Git closeout 和 push 由定时控制状态机完成。

---

## 54. 自动 Result commit 与最终状态

正式运行和独立审计通过后，scheduled controller 自动执行 closeout，提交：

```text
48_*
48 figures
022 归档
active README
prompt manifest
00_DOCUMENT_STATUS_INDEX.md
```

将 022 移到：

```text
archive/completed/
```

最终 active README：

```text
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE

BRANCH:
work/stage8-k2-white-snr-all-classical-baselines-v1

SOURCE_WHITE_CLASSIC_BRANCH_CHANGED:
false

LONG_TERM_TANGENT_CHANGED:
false

EXISTING_METHOD_RERUN_COUNT:
0

EXECUTION_CONTROL:
SCHEDULED_TASK_COMPLETED_AND_UNREGISTERED

MERGE_BACK:
NOT_AUTHORIZED

NEXT:
USER_REVIEW
```

固定结果提交标题：

```text
docs(stage8-k2): record unified white-SNR all-classical comparison
```

只推送新 work 分支。

如果自动 closeout 进入 `GIT_PUSH_PENDING`，定时任务每 15 分钟最多重试一次 push；不得重复计算或重复提交。

完成后必须：

```text
controller state = COMPLETE
scheduled task = absent
HEAD == origin/new-work
Git clean
Next = USER_REVIEW
```

---

# Part P：最终审计

## 55. 行数与身份

必须确认：

```text
registry = 1680
new checkpoints = 1680
new method rows = 6720
new diagnostic rows = 6720
all-method plot rows = 16800
unique trial IDs = 1680
10 methods per trial
truth leakage = 0
existing method rerun = 0
```

Applicability 精确计数：

```text
Element MUSIC = 1120
GFBSS-MUSIC = 1260
Root-MUSIC = 630
LS-ESPRIT = 630
```

---

## 56. Branch audit

确认：

```text
origin/work/stage8-k2-white-snr-classical-baselines-v1
== 224eedb8282b64fec210e77081bc4fc7748c1fc1

origin/experiment/stage8-k2-tangent
== d2d59fe550d8999dc8589aa76e52e89736539b66

origin/work/stage8-k2-subspace-baselines-v1
== dcde540e3f3af793c0b8beb18e41a798af64739a

origin/main
== 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
== a7139204d717923cb89d0d629b67f1b3ab7ae94d

HEAD
== origin/work/stage8-k2-white-snr-all-classical-baselines-v1

Git clean
untracked = 0
MATLAB / mwpython / coordinator / lock / tmp = 0 / 0 / 0 / 0 / 0
```

---

## 57. Scope diff

从 `224eedb...` 到最终 HEAD，只允许：

```text
tools/stage8_k2_white_snr_all_classical_baselines/**
47_*
48_*
figures/48_*
022 新增和归档
00_DOCUMENT_STATUS_INDEX.md
active README
prompt manifest
```

所有冻结路径必须零 diff。

---

## 58. 最终报告格式

```text
STAGE8_K2_WHITE_SNR_ALL_CLASSICAL_BASELINE_COMPARISON_COMPLETE / INVALID

Branch:
Source branch:
Source HEAD:
Prompt commit:
Tool commit:
Result commit:
Push:
Git clean:

Source white-classic branch unchanged:
Long-term Tangent unchanged:
Old subspace branch unchanged:
Main/research unchanged:

Evidence 44:
- manifest/artifact identity
- registry 1680
- existing rows 5040

Evidence 46:
- manifest/artifact identity
- baseline rows 5040
- audit PASS

Execution control:
- task name
- task interval = 15 minutes
- scheduled task registration PASS
- no interactive Codex polling
- trial launch count
- resume launch count
- finalization launch count
- audit launch count
- Git closeout attempt count
- task unregistered after completion
- controller terminal state

New execution:
- checkpoints 1680
- new rows 6720
- diagnostics 6720
- all-method rows 16800
- representative spectra count
- artifact hashes
- existing method rerun count 0

Element MUSIC:
- applicable/valid/single-peak
- valid rate by white SNR
- conditional RMSE where valid

GFBSS-MUSIC:
- applicable/elevation-valid/end-to-end-valid
- white-SNR/profile/noise/L
- failure reasons

Root-MUSIC:
- applicable/root-valid/end-to-end-valid
- registered roots
- white-SNR/profile/L

LS-ESPRIT:
- applicable/eigenvalue-valid/end-to-end-valid
- shift rank/eigenvalue diagnostics

Conditional azimuth CML:
- executions
- valid count
- failure count
- whether it is the principal bottleneck

All-method plot data:
- 10 methods
- 16800 rows
- plotting without rerun PASS

Scientific boundaries:
- comparison tiers
- N/A handling
- common-valid subset only
- no global superiority claim

Tangent modified:
false

Production modified:
false

Online selector/threshold created:
false

Merge back:
false

Next:
USER_REVIEW
```

定时控制器完成推送并注销自身后停止；不自动合并、删除分支或运行新的算法实验。
