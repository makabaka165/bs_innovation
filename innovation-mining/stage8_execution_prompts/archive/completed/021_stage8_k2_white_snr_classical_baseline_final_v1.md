# Stage8-K2-CB2：白化顺序波束域 SNR 下的经典 CML/MUSIC 最终补强比较（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、Git 和 GitHub 推送的执行 AI。
>
> 本协议只做“最终经典基线补强”，不开发新算法，不修改 Tangent，不移动长期
> Tangent 分支。
>
> 执行拓扑：
>
> ```text
> experiment/stage8-k2-tangent
> d2d59fe550d8999dc8589aa76e52e89736539b66
>           \
>            work/stage8-k2-white-snr-classical-baselines-v1
> ```
>
> 本协议明确禁止在完成后自动 fast-forward、merge、rebase 或 cherry-pick 回
> `experiment/stage8-k2-tangent`。所有新增代码和结果只推送到新的 work 分支，
> 用户检查后再决定是否保留、合并文档或删除。
>
> 本轮使用已经冻结的 `44_*` white-SNR Monte Carlo trial 集合，只新增：
>
> ```text
> 1. 全 1680 trial 的 Full4D Beamspace CML；
> 2. 全 1680 trial 的标准 Beamspace MUSIC；
> 3. 160-trial 预注册子集的 Full4D Element CML；
> 4. 与现有 Tangent/Core 结果的同 trial、同 white-SNR 配对比较。
> ```
>
> 协议：
>
> ```text
> STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_FINAL_COMPARISON_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_WORK_BRANCH_V1
> ```

---

## 0. 为什么新建 work 分支，而不继续旧 work baseline 分支

当前长期 Tangent 分支已经包含：

```text
31_*–34_*：
Tangent 与第一轮 Full4D CML/MUSIC 比较；

39_*–40_*：
结构化 FBSS/Root-MUSIC/ESPRIT 参考；

41_*–42_*：
SNR 定义与 white-SNR 重参数化；

43_*–44_*：
1680-trial white-SNR Monte Carlo 和工作区间收束。
```

现有旧 work 分支：

```text
work/stage8-k2-subspace-baselines-v1
```

主要承载垂直 ULA 子结构上的 FBSS-MUSIC、Root-MUSIC 和 ESPRIT，比 `44_*`
white-SNR Monte Carlo 更早，也不包含当前最新 trial registry 和结果。

因此本轮：

```text
不从旧 work 分支继续；
不把旧 work 分支合并进当前 Tangent；
只把现有经典基线工具和公式作为只读实现来源。
```

新 work 分支必须从当前 Tangent 精确 HEAD 创建，以确保：

```text
44 registry
44 method rows
white-SNR 定义
Tangent 工作区间
经典基线工具
```

全部位于同一祖先历史中。

---

## 1. 当前 Git 锚点

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

源分支：

```text
experiment/stage8-k2-tangent
```

精确源提交：

```text
d2d59fe550d8999dc8589aa76e52e89736539b66
docs(stage8-k2): close Tangent white-SNR working region
```

不可变分支：

```text
origin/main
=
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
=
a7139204d717923cb89d0d629b67f1b3ab7ae94d

origin/experiment/stage8-k2-tangent
=
d2d59fe550d8999dc8589aa76e52e89736539b66
```

现有审计分支：

```text
origin/work/stage8-k2-subspace-baselines-v1
```

必须保持不变。

---

## 2. Git Preflight 与新分支

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
$head == $remote
$head == d2d59fe550d8999dc8589aa76e52e89736539b66

$main
== 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

$research
== a7139204d717923cb89d0d629b67f1b3ab7ae94d

$status 为空
```

确认本地和远端均不存在：

```text
work/stage8-k2-white-snr-classical-baselines-v1
```

若存在：

```text
硬停止；
不得覆盖、reset、force-push 或复用。
```

创建：

```powershell
git switch -c work/stage8-k2-white-snr-classical-baselines-v1 `
  d2d59fe550d8999dc8589aa76e52e89736539b66
```

创建后：

```text
HEAD 精确为 d2d59fe
Tangent 远端 ref 不移动
```

---

## 3. 冻结边界

相对：

```text
d2d59fe550d8999dc8589aa76e52e89736539b66
```

以下全部必须保持字节不变：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**
tools/stage8_k2_snr_validation/**
tools/stage8_k2_white_snr_monte_carlo/**

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
```

不得修改：

```text
Tangent 算法
Core-Lite
Core-Plus
Full4D CML 既有实现
MUSIC 既有实现
W_I / C_I / T_I
白化 rank
P1–P4
44 registry
44 seeds
44 method results
white-SNR 公式
44 工作区分类
生产接口
```

只允许新增或修改：

```text
tools/stage8_k2_white_snr_classical_baselines/**

innovation-mining/45_*
innovation-mining/46_*

innovation-mining/figures/46_*

innovation-mining/stage8_execution_prompts/active/
021_stage8_k2_white_snr_classical_baseline_final_v1.md

本 work 分支中的：
00_DOCUMENT_STATUS_INDEX.md
active/README.md
PROMPT_ARCHIVE_MANIFEST.csv
```

---

# Part A：理论与公平性

## 4. 共同物理试验

全部方法共享：

```text
同一个 Y_element
同一个 source seed
同一个 noise seed
同一个 white-SNR target
同一个 P1–P4 truth
同一个 L
同一个 noise model
同一个 known K=2
同一个单 CPI / 同一距离–多普勒单元
同一个局部角域
```

新 baseline 不允许重新选择：

```text
truth
profile
SNR
replicate
seed
trial 子集（Element CML 预注册子集除外）
```

---

## 5. 同域主基线：Full4D Beamspace CML

### 5.1 观测模型

从同一个阵元观测：

\[
Y_e=X_e+N_e
\]

形成白化顺序 Beamspace：

\[
\boxed{
Z_w=T_IW_I^HY_e
}
\]

对两个二维角度：

\[
\Theta=\{\xi_1,\xi_2\},
\qquad
\xi_k=[\phi_k,\theta_k]^T,
\]

构造完整白化顺序流形：

\[
\boxed{
G(\Theta)
=
T_IW_I^H
[
a(\xi_1),a(\xi_2)
]
}
\]

其中 `a` 是当前真实活动圆柱阵流形。

### 5.2 Concentrated deterministic ML

\[
P_G
=
G(G^HG)^{-1}G^H
\]

\[
\boxed{
RSS(\Theta)
=
\|
(I-P_G)Z_w
\|_F^2
}
\]

等价最大化：

\[
\ell^\star(\Theta)
=
-\text{const}
-
rL\log
\left(
\frac{RSS(\Theta)}{rL}
\right).
\]

实现必须继续调用：

```text
build_full_sequential_local_manifold
concentrated_dml_rss
```

### 5.3 四维参数化

复用既有 center-difference 参数化：

\[
c=\frac{\xi_1+\xi_2}{2},
\qquad
d=\xi_2-\xi_1,
\]

\[
\xi_1=c-\frac d2,
\qquad
\xi_2=c+\frac d2.
\]

参数：

\[
[c_{\rm az},c_{\rm el},d_{\rm az},d_{\rm el}]
\]

与直接优化：

\[
[\phi_1,\theta_1,\phi_2,\theta_2]
\]

完全可逆等价。

### 5.4 冻结数值预算

必须原样复用 `stage8_k2_cb_full4d_cml` 的算法和以下预算：

```text
top_start_count = 6
max_sweeps = 12
scan_nodes_per_coordinate = 9
fminbnd TolX = 1e-4 deg
fminbnd MaxFunEvals = 80
minimum separation = 1e-3 deg
relative score tolerance = 1e-8
endpoint update tolerance = 1e-3 deg
rank multiplier = 1
```

不得：

```text
根据 SNR 增加 starts
根据结果增加 sweeps
使用 Tangent 作为 start
使用 Core 作为 start
使用 truth 作为 start
根据失败 trial 单独提高预算
```

方法 ID：

```text
FULL4D_BEAMSPACE_CML_MULTISTART
```

它是：

```text
确定性有限预算 numerical CML baseline
```

不是：

```text
全局 ML 最优证明。
```

---

## 6. 同域子空间基线：Beamspace MUSIC

### 6.1 协方差与子空间

\[
\widehat R_z
=
\frac1L Z_wZ_w^H.
\]

known \(K=2\)，取两个主特征向量：

\[
E_s=[e_1,e_2].
\]

噪声投影可写为：

\[
P_n=I-E_sE_s^H.
\]

对二维候选角：

\[
g(\phi,\theta)
=
T_IW_I^Ha(\phi,\theta),
\]

MUSIC 谱：

\[
\boxed{
P_{\rm MUSIC}(\phi,\theta)
=
\frac1{
g^H(\phi,\theta)P_ng(\phi,\theta)
}
}
\]

### 6.2 固定实现

复用：

```text
stage8_k2_cb_music
stage8_k2_cb_peak_picker
既有二维白化顺序流形 dictionary
```

固定：

```text
music grid step = 0.005 deg
music grid chunk size = 2048
known K = 2
```

### 6.3 适用性

```text
L=1：
NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK

L=4/8：
APPLICABLE
```

全 1680 registry 都保留一行：

```text
L=1 → N/A row
L=4/8 → 实际谱计算
```

适用行数：

\[
7\times2\times2\times4\times10
=
1120.
\]

### 6.4 两峰合同

只有二维谱中存在两个独立 8-neighbor 局部峰时，才输出 K2 角度。

禁止：

```text
把两个最大网格点强行当作两个目标
truth-based peak separation
事后 prominence threshold
根据 SNR 调峰值门
把单峰/N/A 计为 Tangent 胜利
```

方法 ID：

```text
BEAMSPACE_MUSIC_K2
```

---

## 7. 更多信息量参考：Full4D Element CML

### 7.1 角色

Element CML 使用完整活动阵元观测和精确阵元噪声白化：

\[
Y_{e,w}=R_e^{-1/2}Y_e.
\]

候选流形：

\[
A_w(\Theta)
=
R_e^{-1/2}
[
a(\xi_1),a(\xi_2)
].
\]

目标：

\[
\boxed{
RSS_e(\Theta)
=
\|
\Pi_{A_w(\Theta)}^\perp
Y_{e,w}
\|_F^2
}
\]

复用：

```text
stage8_k2_cb_whiten_element_data
stage8_k2_cb_full4d_cml(..., "ELEMENT", ...)
```

### 7.2 公平性定位

Element CML 使用：

```text
2080 个活动阵元
```

而 Tangent 使用：

```text
15 维白化顺序 Beamspace
```

因此必须标记：

```text
MORE_INFORMATIVE_ELEMENT_DOMAIN_REFERENCE
NOT_SAME_HARDWARE_INTERFACE
```

不允许直接比较 element-domain likelihood 与 beamspace likelihood 的绝对数值。

### 7.3 预注册 160-trial 子集

只运行：

```text
white SNR ∈ {+10,+14,+18,+22 dB}
L = 4
profile ∈ {P1,P2,P3,P4}
noise ∈ {WHITE,CORRELATED}
replicate ∈ {1,2,3,4,5}
```

总计：

\[
4\times1\times4\times2\times5
=
160.
\]

该子集由因子值机械确定，禁止根据 44 的 RMSE 或 Tangent 结果选择。

方法 ID：

```text
FULL4D_ELEMENT_CML_MULTISTART
```

---

## 8. 本轮明确不运行

```text
Element MUSIC
GFBSS-MUSIC
Root-MUSIC
ESPRIT
Vincent-Anchored
Core-Lite/Core-Plus 重新拟合
Tangent 重新拟合
automatic K
bootstrap
新算法
稀疏 Bayesian 算法
```

原因：

```text
Element MUSIC 已有高 white-SNR 参考且不是同接口；
垂直子空间方法属于结构适用性分支；
Vincent 路线已关闭；
本轮目标是补齐同 white-SNR 横轴上的经典 CML/MUSIC 证据。
```

---

# Part B：复用 44 号 Monte Carlo 身份

## 9. 只读 44 号输入

必须读取并验证：

```text
innovation-mining/
44_stage8_k2_white_snr_monte_carlo_registry.csv

44_stage8_k2_white_snr_monte_carlo_snr_trials.csv

44_stage8_k2_white_snr_monte_carlo_method_results.csv

44_stage8_k2_white_snr_monte_carlo_runtime_manifest.json
```

要求：

```text
registry = 1680
SNR rows = 1680
method rows = 5040
unique trial hashes = 1680
base realizations = 240
truth leakage = 0
status = COMPLETE
working region = IDENTIFIED
```

逐项验证 manifest 中 15 个 artifacts 的 SHA-256。

任一身份不一致：

```text
EXPERIMENT_INVALID
不得运行 baseline。
```

---

## 10. Trial 重建

对 44 registry 每一行调用冻结的 white-SNR trial 构造：

```text
stage8_k2_mc_generate_trial
或其冻结下游：
stage8_k2_snr_generate_white_control_trial
```

要求：

```text
trial_id 完全相同
measurement hash 完全相同
element_trial_hash 完全相同
white target error <= 1e-10 dB
```

必须重建：

```text
Y_element
model
signal/noise metrics
```

但不得重新运行：

```text
Core-Lite
Core-Plus
Tangent
```

已有方法结果直接从 `44_*_method_results.csv` 读取。

---

## 11. 44 method rows 的使用

从现有 44 方法表读取：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

必须验证每个 trial 恰有三行。

新增 baseline 结果只与同 trial 的既有行 join。

禁止修改或覆盖 `44_*`。

---

# Part C：数值审计

## 12. Full4D numerical-completeness 标记

因为 Full4D 可行集合包含 Tangent 最终输出和 fixed-grid 输出，若：

\[
\ell_{\rm Full4D}
<
\ell_{\rm Tangent,final}
-
\tau_\ell,
\]

则该行标记：

```text
NUMERICAL_OPTIMIZATION_INCOMPLETE
```

其中：

\[
\tau_\ell
=
64\epsilon
\max(1,|\ell_{\rm Tangent,final}|).
\]

该行仍可保留为有限预算数值输出，但必须分别报告：

```text
all finite Full4D rows
complete-likelihood subset
optimization-incomplete rows
```

不得：

```text
事后增加 starts/sweeps
用 Tangent 重新初始化
删除不利结果
```

### 12.1 Complete-likelihood subset

定义：

```text
Full4D valid
且
Full4D loglik >= Tangent final loglik - tolerance
```

在该子集上再次计算：

```text
Tangent vs Full4D median/P90
wins/ties/losses
```

用于区分：

```text
Tangent 的有限样本正则化收益
与
Full4D solver 未充分优化的影响。
```

---

## 13. MUSIC 状态

每个适用 MUSIC trial 输出：

```text
sample rank
local peak count
fit_valid
fit_status
peak values
runtime
```

状态至少包括：

```text
MUSIC_K2_VALID
MUSIC_FEWER_THAN_TWO_PEAKS
MUSIC_SIGNAL_SUBSPACE_RANK_DEFICIENT
NOT_APPLICABLE_INSUFFICIENT_SAMPLE_SUBSPACE_RANK
```

N/A、rank-deficient 和 single-peak 不进入 RMSE 配对。

---

# Part D：执行工具与恢复

## 14. 新工具路径

只允许新增：

```text
tools/stage8_k2_white_snr_classical_baselines/
```

建议结构：

```text
tools/stage8_k2_white_snr_classical_baselines/
├── README.md
├── matlab/
│   ├── stage8_k2_wcb_constants.m
│   ├── stage8_k2_wcb_add_paths.m
│   ├── stage8_k2_wcb_build_context.m
│   ├── stage8_k2_wcb_load_evidence44.m
│   ├── stage8_k2_wcb_build_registry.m
│   ├── stage8_k2_wcb_reconstruct_trial.m
│   ├── stage8_k2_wcb_prepare_music_resources.m
│   ├── stage8_k2_wcb_evaluate_trial.m
│   ├── stage8_k2_wcb_checkpoint_write.m
│   ├── stage8_k2_wcb_checkpoint_load.m
│   ├── stage8_k2_wcb_checkpoint_validate.m
│   ├── stage8_k2_wcb_checkpoint_hash.m
│   ├── stage8_k2_wcb_checkpoint_path.m
│   ├── stage8_k2_wcb_scan_checkpoints.m
│   ├── stage8_k2_wcb_status_write.m
│   ├── stage8_k2_wcb_merge.m
│   ├── stage8_k2_wcb_summarize.m
│   ├── stage8_k2_wcb_plot.m
│   ├── stage8_k2_wcb_run.m
│   └── stage8_k2_wcb_file_sha256.m
└── tests/
    ├── test_evidence44_identity.m
    ├── test_1680_trial_hash_reconstruction.m
    ├── test_classical_budget_identity.m
    ├── test_full4d_contains_frozen_candidate.m
    ├── test_music_l1_not_applicable.m
    ├── test_music_two_peak_fixture.m
    ├── test_element_subset_cardinality.m
    ├── test_truth_isolation.m
    ├── test_checkpoint_roundtrip_resume.m
    └── test_four_trial_smoke.m
```

---

## 15. 新 constants

新 constants 必须记录：

```text
protocol
authorization
branch
starting commit
44 evidence identity

trial count = 1680
beamspace Full4D count = 1680
Beamspace MUSIC row count = 1680
Beamspace MUSIC applicable count = 1120
Element CML count = 160

white SNR = [-6,0,6,10,14,18,22]
noise = [WHITE,CORRELATED]
L = [1,4,8]
profiles = [P1,P2,P3,P4]
replicates = 10

Element subset:
SNR = [10,14,18,22]
L = 4
replicate = [1,2,3,4,5]
```

经典算法预算必须复制并验证为第 5、6 节冻结值。

---

## 16. Checkpoint

正式 runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_white_snr_classical_baselines_v1
```

每个 trial 一个 checkpoint：

```text
checkpoints/
trial_<global_index>_<trial_id>.mat
```

checkpoint 包含：

```text
44 registry row
44 trial hash
reconstructed trial identity
Full4D Beamspace CML row
Beamspace MUSIC row
Element CML row 或 NOT_IN_SUBSET
scientific hash
code identity
registry hash
completed UTC
runtime
```

写入方式：

```text
写 .tmp
加载校验
计算 scientific hash
原子 rename
再次校验
```

恢复时：

```text
验证 protocol/code/registry/trial hash/schema
valid checkpoint 跳过
.tmp 对应 trial 重跑
invalid final checkpoint 硬停止
不得自动覆盖
```

---

## 17. 状态和断点续跑

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
多 worker
复杂资源 Gate
```

每完成 25 个 trial：

```text
打印 completed / 1680
当前 trial
median runtime
ETA
Full4D valid/incomplete count
MUSIC valid/single-peak count
Element CML completed count
```

原子写：

```text
status/latest_status.json
status/latest_status.txt
```

重新运行相同命令：

```text
自动 RESUME
不删除 runtime
不重新计算 valid checkpoint
```

---

## 18. 两阶段终结

考虑 MATLAB R2022b 长时会话可能在退出阶段异常：

### 第一会话

```text
完成 1680 checkpoints
写 READY_TO_FINALIZE
返回
```

### 第二个全新单线程会话

```text
只读合并 checkpoints
生成 summary/figures/report
写 runtime manifest
```

### 第三个全新单线程会话

```text
独立只读复核
不重跑任何 baseline
```

只有：

```text
1680 checkpoints 完整
artifact hash 一致
独立复核通过
```

时，完成后的 MATLAB shutdown anomaly 才可记录为：

```text
POST_COMPUTATION_SHUTDOWN_ANOMALY
```

---

# Part E：固定测试

## 19. T1：44 evidence identity

验证：

```text
manifest status
1680/1680 registry
1680/1680 SNR
5040/5040 methods
15 artifact SHA-256
truth leakage 0
```

## 20. T2：1680 trial hash

重建全部 1680 trial 的 scientific identity：

```text
1680/1680 element_trial_hash exact
```

该测试只构建 trial，不运行 baseline。

## 21. T3：经典预算身份

验证新 constants 与既有 `stage8_k2_cb_constants` 中：

```text
top starts
sweeps
scan nodes
fminbnd
minimum separation
rank multiplier
MUSIC grid
```

完全一致。

## 22. T4：Full4D 包含冻结候选

使用既有测试逻辑，验证：

```text
fixed-grid candidate 属于 Full4D 可行集合
Tangent final candidate 属于 Full4D 可行集合
```

至少覆盖：

```text
一个 Tangent upgrade trial
一个 Tangent fallback trial
```

## 23. T5：MUSIC L1 N/A

验证：

```text
L=1 → N/A
不运行 EVD/峰值搜索
不计 invalid
```

## 24. T6：MUSIC 两峰 fixture

在理想高 SNR、足够分离 fixture 上验证：

```text
二维 dictionary 正确
两个局部峰可提取
峰排序和 endpoint 输出正确
```

## 25. T7：Element subset

验证：

```text
160 rows exact
4 SNR
2 noise
4 profile
L=4
5 replicates
```

## 26. T8：Truth isolation

Baseline 入口不得接收：

```text
truth
profile label
Tangent result
Core result
RMSE
working-region label
```

## 27. T9：Checkpoint round trip

验证：

```text
.tmp → validation → atomic final
resume skip
scientific hash
invalid checkpoint hard stop
```

## 28. T10：四 trial smoke

固定：

```text
P1 WHITE L=4 +10 dB R01
P2 CORRELATED L=4 +14 dB R01
P3 WHITE L=8 +18 dB R01
P4 CORRELATED L=1 +22 dB R01
```

要求：

```text
Full4D Beamspace 有明确 finite/invalid 输出
MUSIC 有明确 valid/single-peak/N/A 输出
Element CML 仅对前两个 L=4 且 replicate<=5 行运行
truth leakage = 0
```

---

# Part F：正式执行

## 29. 执行顺序

1. Git/environment preflight；
2. T1–T10；
3. 读取并冻结 44 registry；
4. 构建新 baseline registry hash；
5. 预计算两种 noise 的 Beamspace MUSIC dictionary；
6. 运行/恢复 1680 trial；
7. 验证 1680 checkpoints；
8. 第二会话合并；
9. 汇总和画图；
10. 第三会话独立复核；
11. 写 Git 证据；
12. 提交并推送 work 分支；
13. 停止，不修改 Tangent 分支。

---

## 30. 正式运行命令

第一次运行或恢复：

```powershell
& 'E:\MATLABR2022b\bin\matlab.exe' `
  -singleCompThread `
  -batch "
  addpath('E:\bs_innovation\tools\stage8_k2_white_snr_classical_baselines\matlab');
  out = stage8_k2_wcb_run( ...
      'E:\bs_innovation', ...
      'E:\bs_innovation_runtime\stage8_k2_white_snr_classical_baselines_v1');
  disp(out.status);
  "
```

若输出：

```text
READY_TO_FINALIZE
```

在全新的 MATLAB 会话中重新运行同一命令。

---

# Part G：结果表

## 31. 新 baseline 原始表

每 trial 固定三行：

```text
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
FULL4D_ELEMENT_CML_MULTISTART
```

其中 Element CML 非子集行：

```text
applicable = false
applicability_status = NOT_IN_REGISTERED_ELEMENT_REFERENCE_SUBSET
```

总 baseline rows：

\[
1680\times3
=
5040.
\]

这样保持固定 schema。

---

## 32. 字段

至少包括：

```text
trial_id
element_trial_hash

method_id
observation_domain

white_beamspace_snr_target_db
noise_profile_id
L
profile_id
replicate_id

applicable
applicability_status
fit_valid
fit_status
optimizer_status

angles_hat_deg
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

coarse_candidate_count
continuous_start_count
sweep_count

local_peak_count
sample_rank

numerical_optimization_incomplete_flag

truth_used_in_fit_flag
profile_used_in_fit_flag
tangent_used_in_start_flag
core_used_in_start_flag
```

---

# Part H：统计比较

## 33. Full4D Beamspace CML 主比较

按：

```text
white SNR overall（N=240）
white SNR × profile（N=60）
white SNR × noise（N=120）
white SNR × L（N=80）
exact cell（N=10，仅描述）
```

报告：

```text
valid rate
converged/stationary/max-sweep-valid
numerical-incomplete count
median/P90 joint RMSE
center/axis/rho/vector
score/SVD/runtime
```

### 33.1 配对

```text
Tangent vs Full4D Beamspace CML
```

只在两者 valid 的同 trial 上：

```text
wins
ties
losses
non-tie win rate
median paired delta
P90 paired delta
```

tie：

```text
1e-6 deg
```

### 33.2 Complete-likelihood subset

重复报告上述比较，但排除：

```text
numerical_optimization_incomplete_flag = true
```

---

## 34. Beamspace MUSIC

按 white SNR 报告：

```text
total count
applicable count
sample-rank-valid count
single-peak count
two-or-more-local-peaks count
valid K2 output count
valid-output RMSE
runtime
```

配对：

```text
Tangent vs MUSIC
```

仅在 MUSIC valid 两峰输出的同 trial 子集。

N/A、single-peak 不计作 Tangent win。

---

## 35. Element CML 子集

在 160 个预注册 trial 上报告：

```text
Tangent
Full4D Beamspace CML
Full4D Element CML
```

按：

```text
SNR
profile
noise
```

报告：

```text
median/P90
wins/ties/losses
runtime
数值状态
```

Element 和 Beamspace likelihood 绝对值不直接比较。

---

# Part I：预注册解释状态

## 36. 主要 white-SNR 工作区

主要判断区间：

```text
+10 / +14 / +18 / +22 dB
```

这是 `44_*` 已识别的总体相对收益区间。

### 36.1 `SUPPORTED`

结论：

```text
STAGE8_K2_TANGENT_ADVANTAGE_OVER_NUMERICAL_BEAMSPACE_CML_SUPPORTED
```

仅当四个 SNR 点全部满足：

```text
Tangent median joint RMSE <= Full4D
Tangent P90 joint RMSE <= Full4D
Tangent wins > losses
```

并且 complete-likelihood 合并子集满足：

```text
Tangent median <= Full4D
Tangent P90 <= Full4D
Tangent wins > losses
```

### 36.2 `PARTIAL`

结论：

```text
STAGE8_K2_TANGENT_ADVANTAGE_OVER_NUMERICAL_BEAMSPACE_CML_PARTIAL
```

当四个 SNR 点中至少两个满足完整条件，但未满足 `SUPPORTED`。

### 36.3 `NOT_SUPPORTED`

结论：

```text
STAGE8_K2_TANGENT_ADVANTAGE_OVER_NUMERICAL_BEAMSPACE_CML_NOT_SUPPORTED
```

当少于两个 SNR 点满足，或 complete-likelihood 合并子集由 Full4D 占优。

这些状态只评价：

```text
当前冻结预算的 numerical Beamspace CML
```

不得推广为：

```text
Tangent 理论上优于全局 ML。
```

---

## 37. MUSIC 状态

只作描述：

```text
MUSIC_TWO_PEAK_REGION_IDENTIFIED
MUSIC_TWO_PEAK_REGION_NOT_IDENTIFIED
```

若某个 white-SNR 的适用行中：

```text
valid two-peak rate >= 0.50
```

则标记 identified。

这不是 Tangent 的 pass/fail 门。

---

## 38. Element CML 状态

只允许：

```text
ELEMENT_REFERENCE_DESCRIPTIVE
```

不建立生产或算法门。

---

# Part J：输出与图

## 39. 文档

新增：

```text
innovation-mining/
45_stage8_k2_white_snr_classical_baseline_theory_and_protocol.md

46_stage8_k2_white_snr_classical_baseline_registry_audit.csv

46_stage8_k2_white_snr_classical_baseline_results.csv

46_stage8_k2_white_snr_classical_baseline_summary.csv

46_stage8_k2_white_snr_classical_baseline_profile_summary.csv

46_stage8_k2_white_snr_classical_baseline_exact_cell_summary.csv

46_stage8_k2_white_snr_classical_baseline_numerical_audit.csv

46_stage8_k2_white_snr_music_applicability.csv

46_stage8_k2_white_snr_element_reference_summary.csv

46_stage8_k2_white_snr_classical_baseline_runtime_manifest.json

46_stage8_k2_white_snr_classical_baseline_comparison.md
```

## 40. 图

```text
innovation-mining/figures/
46_white_snr_tangent_full4d_rmse.png

46_white_snr_tangent_full4d_pairwise.png

46_white_snr_full4d_numerical_status.png

46_white_snr_music_two_peak_rate.png

46_white_snr_element_reference.png

46_white_snr_complexity.png
```

图必须明确标注：

```text
Full4D = finite-budget numerical CML
Element CML = more-informative reference
MUSIC N/A/single-peak != Tangent win
```

---

# Part K：提交与分支保护

## 41. Prompt / theory commit

新增：

```text
45_*
active/021_stage8_k2_white_snr_classical_baseline_final_v1.md
active README
```

active README：

```text
STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_ACTIVE

BRANCH:
work/stage8-k2-white-snr-classical-baselines-v1

SOURCE_TANGENT:
d2d59fe550d8999dc8589aa76e52e89736539b66

TANGENT:
FROZEN
NOT_MODIFIED

WORK:
CLASSICAL_BASELINE_ONLY

MERGE_BACK:
NOT_AUTHORIZED
```

提交：

```text
docs(stage8-k2): define white-SNR classical baseline comparison
```

首次推送：

```powershell
git push -u origin work/stage8-k2-white-snr-classical-baselines-v1
```

---

## 42. Tool commit

只提交：

```text
tools/stage8_k2_white_snr_classical_baselines/
```

提交：

```text
analysis(stage8-k2): add white-SNR classical baseline runner
```

推送 work 分支。

正式运行必须从：

```text
clean
pushed
HEAD == origin/work/...
```

启动。

---

## 43. Result commit

完成、独立复核后提交：

```text
46_*
46 figures
021 归档
active README
prompt manifest
00_DOCUMENT_STATUS_INDEX.md
```

021 移动到：

```text
archive/completed/
```

work 分支 active README 终态：

```text
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPLETE

SOURCE_TANGENT:
d2d59fe550d8999dc8589aa76e52e89736539b66

TANGENT_BRANCH_CHANGED:
false

MAIN_CHANGED:
false

RESEARCH_CHANGED:
false

WORK_BRANCH_ONLY:
true

MERGE_BACK:
NOT_AUTHORIZED

NEXT:
USER_REVIEW
```

提交：

```text
docs(stage8-k2): record white-SNR classical baseline comparison
```

只推送 work 分支。

---

## 44. 禁止自动集成

完成后禁止：

```text
git merge
git merge --ff-only
git rebase
git cherry-pick
git push experiment/stage8-k2-tangent
git push main
删除 work 分支
删除 runtime
```

最终长期 Tangent 必须仍指向：

```text
d2d59fe550d8999dc8589aa76e52e89736539b66
```

是否将 `45_*–46_*` 合并回 Tangent，由用户另行授权。

---

# Part L：最终审计

## 45. Scope diff

从 work 分支起点：

```text
d2d59fe550d8999dc8589aa76e52e89736539b66
```

到 work HEAD，只允许：

```text
tools/stage8_k2_white_snr_classical_baselines/**
45_*
46_*
46 figures
021 新增与归档
00_DOCUMENT_STATUS_INDEX.md
active README
prompt manifest
```

以下必须零 diff：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**
tools/stage8_k2_snr_validation/**
tools/stage8_k2_white_snr_monte_carlo/**
beamspace_ml_v18/**
31_*–44_*
```

---

## 46. Branch audit

确认：

```text
origin/experiment/stage8-k2-tangent
== d2d59fe550d8999dc8589aa76e52e89736539b66

origin/main
== 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
== a7139204d717923cb89d0d629b67f1b3ab7ae94d

origin/work/stage8-k2-subspace-baselines-v1
unchanged

HEAD
== origin/work/stage8-k2-white-snr-classical-baselines-v1

Git clean
untracked = 0

MATLAB / mwpython / coordinator / lock / tmp:
0 / 0 / 0 / 0 / 0
```

---

## 47. 有效终态

完整结果：

```text
STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPARISON_COMPLETE
```

性能解释状态为第 36 节之一。

无效：

```text
STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPARISON_INVALID
```

仅用于：

```text
44 evidence identity 失败
1680 hash 失败
white-SNR target 失败
baseline budget 改变
truth leakage
checkpoint identity 失败
结果行数不完整
冻结路径改变
artifact identity 失败
```

不得因 Full4D 或 MUSIC 性能优于 Tangent 而判 invalid。

---

## 48. 最终报告格式

```text
STAGE8_K2_WHITE_SNR_CLASSICAL_BASELINE_COMPARISON_COMPLETE / INVALID

Branch:
Source Tangent HEAD:
Prompt commit:
Tool commit:
Result commit:
Push:
Git clean:

Long-term Tangent unchanged:
Main unchanged:
Research unchanged:
Old work branch unchanged:

Evidence 44:
- manifest identity
- registry 1680
- trial hashes
- existing method rows 5040

New baseline:
- rows 5040
- checkpoints 1680
- Full4D beamspace 1680
- MUSIC 1680 / applicable 1120
- Element CML 160

Full4D by white SNR:
- valid
- converged/stationary/max-sweep
- optimization incomplete
- median/P90
- score/SVD/runtime

Tangent vs Full4D:
- all finite rows
- complete-likelihood subset
- +10/+14/+18/+22
- wins/ties/losses
- final interpretation state

MUSIC:
- applicable
- single peak
- valid two peak
- first two-peak region or none
- valid-output RMSE only

Element reference:
- 160 subset
- Tangent / Beamspace CML / Element CML
- descriptive only

Scientific statement:
- same white-SNR
- same 15-D beamspace for Tangent vs Full4D/MUSIC
- Element CML more informative
- numerical CML not global proof

Tangent algorithm modified:
false

Production modified:
false

Merge back:
false

Next:
USER_REVIEW
```

完成后停止。
