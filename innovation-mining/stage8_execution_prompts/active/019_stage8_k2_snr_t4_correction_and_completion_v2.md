# Stage8-K2-SNR2：冻结白化器数值质量门修订与 SNR 域验证续跑（V2）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b、Git 和 GitHub 推送的执行 AI。
>
> 本协议是对已经执行并在 T4 停止的：
>
> ```text
> STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V1
> ```
>
> 的最小纠偏和完整续跑授权。
>
> 本协议不修改任何 SNR 定义，不修改冻结 whitener，不修改 Tangent、Core、
> measurement、流形、P1–P4、source/noise seed 或既有科学证据。
>
> 唯一科学修订是：
>
> ```text
> T4 whitening normalized Frobenius residual tolerance:
> 1e-10 → 1e-8
> ```
>
> 原因：
>
> ```text
> 冻结模型的实际残差为：
> WHITE      5.7966605659e-9
> CORRELATED 3.1070711917e-9
>
> 重新调用冻结 build_psd_whitener 后 Tdiff=0，
> 说明该残差来自冻结模型与双精度数值条件，
> 不是新 SNR 工具计算错误，也不是 whitener 被修改。
> ```
>
> 本轮完成：
>
> ```text
> 1. 保存并归档 V1 的 T4 停止记录；
> 2. 修改 T4 为冻结 whitener 数值质量验收；
> 3. 重跑全部 10 项固定测试；
> 4. 完成 Phase A 原 72-trial 三层 SNR 审计；
> 5. 完成 Phase B 4-trial smoke；
> 6. 完成 Phase B 72-trial 白化波束域 SNR 控制试验；
> 7. 完成 Phase C 两种 SNR 口径比较；
> 8. 提交 42_* 证据并关闭本路线；
> 9. 不启动更大规模 Monte Carlo。
> ```
>
> 协议：
>
> ```text
> STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V2
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_SNR_T4_NUMERIC_QUALITY_CORRECTION_AND_COMPLETION_V2
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
6bc40af7deed09a56683b8c1e4a6398166855336
analysis(stage8-k2): add beamspace SNR audit and control
```

V1 文档提交：

```text
654b634a1bc19f127aeaa070d844bf2e19156b41
docs(stage8-k2): define SNR domain validation
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

当前已确认：

```text
T1 original hash: 72/72 PASS
T2 element SNR: PASS
T3 raw covariance: PASS
T4 whitening numeric gate: FAIL only because 1e-10 is too strict

Phase A formal audit: NOT_EXECUTED
Phase B smoke: NOT_EXECUTED
Phase B 72-trial: NOT_EXECUTED
216 method rows: NOT_CREATED
Monte Carlo: NOT_EXECUTED
formal runtime: ABSENT
```

当前 Tangent 决策继续保持：

```text
STAGE8_K2_TANGENT_PROFILE_RETAIN
DEFAULT_K2 = TANGENT_PROFILE_SAFE
```

---

## 1. Git 与现场 Preflight

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
HEAD == 6bc40af7deed09a56683b8c1e4a6398166855336

origin/main
== 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored
== a7139204d717923cb89d0d629b67f1b3ab7ae94d

$status 为空
```

同时确认：

```text
MATLAB process = 0
mwpython process = 0
coordinator process = 0
active lock = 0
```

正式 V2 runtime：

```text
E:\bs_innovation_runtime\
stage8_k2_snr_domain_validation_v2
```

必须不存在。

若 V1 runtime 或诊断日志存在：

```text
不得删除
不得覆盖
不得复用
只读记录其路径
```

若 V2 runtime 已存在：

```text
硬停止
不得覆盖
不得自动删除
```

本协议：

```text
不创建新分支
不 reset 到旧提交
不 force push
不修改 main
不修改 research
```

---

## 2. 冻结科学边界

相对：

```text
dcde540e3f3af793c0b8beb18e41a798af64739a
```

以下必须保持字节不变：

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

不得修改：

```text
W_I
C_I
T_I
whitening rank
build_psd_whitener
measurement registry
noise covariance
Tangent profile likelihood
Tangent axis calculation
safe fallback
Core-Lite
Core-Plus
P1–P4
source seeds
noise seeds
rho_min
local domain
```

本次允许修改：

```text
tools/stage8_k2_snr_validation/**

innovation-mining/
41A_stage8_k2_snr_t4_numeric_quality_correction.md

innovation-mining/stage8_execution_prompts/**
innovation-mining/00_DOCUMENT_STATUS_INDEX.md

最终新增 42_*
```

---

## 3. SNR 定义全部保持不变

### 3.1 Element expected SNR

\[
\boxed{
\mathrm{SNR}_{e,\mathrm{exp}}
=
\frac{\|X_e\|_F^2}
{L\,\mathrm{tr}(R_e)}
}
\]

原 31_* 的 `-6/0/+6 dB` 是：

```text
ELEMENT_INPUT_EXPECTED_TOTAL_ENERGY_SNR
```

### 3.2 Raw sequential-beamspace expected SNR

\[
X_b=W_I^HX_e
\]

\[
C_b=W_I^HR_eW_I=C_I
\]

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{raw,exp}}
=
\frac{\|X_b\|_F^2}
{L\,\mathrm{tr}(C_b)}
}
\]

### 3.3 Whitened sequential-beamspace expected SNR

\[
X_w=T_IW_I^HX_e
\]

\[
C_w=T_IC_IT_I^H
\]

\[
\boxed{
\mathrm{SNR}_{b,\mathrm{white,exp}}
=
\frac{\|X_w\|_F^2}
{L\,\mathrm{tr}(C_w)}
}
\]

必须继续使用实际：

\[
\operatorname{tr}(C_w)
\]

不得改为硬编码：

\[
r=\texttt{whitening\_rank}.
\]

### 3.4 Expected 与 realized 分离

\[
\mathrm{SNR}_{b,\mathrm{white,real}}
=
\frac{\|X_w\|_F^2}
{\|T_IW_I^HN_e\|_F^2}
\]

信号缩放只允许使用 expected covariance，不得使用 realized noise。

### 3.5 White-control scaling

\[
\boxed{
\alpha
=
\sqrt{
\frac{
10^{\gamma_w^\star/10}
L\,\mathrm{tr}(C_w)
}{
\|T_IW_I^HA(\Theta)S_0\|_F^2
}
}
}
\]

该公式不得修改。

---

## 4. 为什么 T4 改为 `1e-8`

T4 定义：

\[
\delta_w
=
\frac{
\|T_IC_IT_I^H-I_r\|_F
}{
\sqrt r
}.
\]

冻结值：

```text
WHITE:
5.7966605659e-9

STAGE5_TOEPLITZ_CORRELATED:
3.1070711917e-9
```

V2 数值质量门：

\[
\boxed{
\delta_w \le 10^{-8}
}
\]

该门仍比实际残差严格，且允许的白化总噪声能量相对偏差最多为 \(10^{-8}\)
量级。

对应 dB 影响上界约为：

\[
\frac{10}{\ln 10}\,10^{-8}
\approx
4.34\times10^{-8}\ {\rm dB}.
\]

相对于：

```text
-6 / 0 / +6 dB
```

的试验尺度可忽略。

因此：

```text
1e-8 不是放松科学模型；
它只是使验收门与冻结双精度 whitener 的实际数值质量一致。
```

禁止：

```text
把 tolerance 调到大于 1e-8
按结果继续调整 tolerance
重建或替换 T_I
修改 C_I
重新选择有效 rank
```

---

# Part A：协议纠偏文档

## 5. 归档 V1 prompt

当前 V1 prompt：

```text
innovation-mining/stage8_execution_prompts/active/
018_stage8_k2_snr_domain_validation_v1.md
```

移动到：

```text
innovation-mining/stage8_execution_prompts/archive/superseded/
018_stage8_k2_snr_domain_validation_v1.md
```

使用：

```powershell
git mv
```

归档状态：

```text
SUPERSEDED_BY_019
V1_STOPPED_AT_T4
PHASE_B_NOT_EXECUTED
NO_SCIENTIFIC_RESULT
NO_EXECUTION_AUTHORITY
```

移动前后 SHA-256 和字节数必须一致。

---

## 6. 新增 V2 prompt

新增：

```text
innovation-mining/stage8_execution_prompts/active/
019_stage8_k2_snr_t4_correction_and_completion_v2.md
```

内容为本协议全文。

---

## 7. 新增纠偏说明

新增：

```text
innovation-mining/
41A_stage8_k2_snr_t4_numeric_quality_correction.md
```

必须写明：

```text
V1 status:
STAGE8_K2_SNR_DOMAIN_VALIDATION_INVALID

Failure stage:
T4 only

WHITE residual:
5.7966605659e-9

CORRELATED residual:
3.1070711917e-9

V1 threshold:
1e-10

V2 threshold:
1e-8

Tdiff after frozen reconstruction:
0

SNR formulas changed:
false

Tangent changed:
false

Whitener changed:
false

Phase B executed under V1:
false

Scientific interpretation:
V1 gate too strict, not a whitening or SNR formulation failure
```

不得改写原：

```text
41_stage8_k2_snr_domain_theory_and_protocol.md
```

该文档保留为 V1 原始协议；`41A_*` 作为唯一纠偏 addendum。

---

## 8. 更新 active README 和 prompt manifest

active README 写为：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_V2_ACTIVE

V1:
STOPPED_AT_T4_NUMERIC_GATE
SUPERSEDED_BY_019

V2:
T4_TOLERANCE_1E_8

EXECUTION:
DIRECT_TANGENT_BRANCH

TANGENT:
FROZEN

MONTE_CARLO:
NOT_AUTHORIZED
```

更新：

```text
archive/PROMPT_ARCHIVE_MANIFEST.csv
```

为 018 和 019 写入正确状态。

---

## 9. 文档纠偏提交

只暂存：

```text
41A_*
018 的归档移动
019
active README
prompt archive manifest
```

提交：

```text
docs(stage8-k2): authorize SNR whitener tolerance correction
```

推送：

```powershell
git push origin experiment/stage8-k2-tangent
```

确认：

```text
HEAD == origin/experiment/stage8-k2-tangent
tracked worktree clean
```

---

# Part B：工具最小修改

## 10. 修改 constants

文件：

```text
tools/stage8_k2_snr_validation/matlab/
stage8_k2_snr_constants.m
```

修改：

```matlab
constants.protocol = ...
'STAGE8_K2_SNR_DOMAIN_AUDIT_AND_WHITE_BEAMSPACE_REPARAMETERIZATION_V2';

constants.authorization = ...
'AUTHORIZE_STAGE8_K2_SNR_T4_NUMERIC_QUALITY_CORRECTION_AND_COMPLETION_V2';

constants.starting_commit = ...
'6bc40af7deed09a56683b8c1e4a6398166855336';

constants.whitening_tolerance = 1e-8;

constants.runtime_root = ...
'E:\bs_innovation_runtime\stage8_k2_snr_domain_validation_v2';
```

保持不变：

```matlab
snr_db_tolerance = 1e-10;
raw_covariance_tolerance = 1e-12;
white_scale_relative_tolerance = 1e-12;
source_scale_relative_tolerance = 1e-12;
paired_tie_tolerance_deg = 1e-6;
```

特别禁止把：

```text
white SNR target tolerance
element SNR identity tolerance
raw covariance tolerance
```

一起放宽。

---

## 11. 修改 T4 测试语义

文件保留原名：

```text
test_whitening_identity.m
```

避免无意义重命名。

修改注释为：

```matlab
% Verify frozen whitener rank and registered numerical quality.
```

保持计算：

```matlab
C_w = model.T_I * model.C_I * model.T_I';
residual = norm(C_w - eye(model.whitening_rank), 'fro') / ...
    sqrt(model.whitening_rank);
```

必须检查：

```text
size(T_I,1) == whitening_rank
residual finite
residual <= 1e-8
```

错误消息改为：

```text
A frozen whitener exceeds the registered numerical-quality tolerance.
```

打印：

```text
noise id
rank
residual
tolerance
trace(C_w)
```

不得把测试改成：

```text
只比较 trace
只检查 finite
直接跳过 T4
```

---

## 12. 更新测试显示名称

在：

```text
stage8_k2_snr_run_tests.m
```

把：

```text
T4_WHITENING
```

改为：

```text
T4_FROZEN_WHITENER_NUMERIC_QUALITY
```

仍运行同一个：

```matlab
test_whitening_identity(context)
```

最终仍要求：

```text
10/10 PASS
```

---

## 13. 更新工具 README

明确记录：

```text
Protocol V2
V1 T4 tolerance was too strict
whitener unchanged
SNR formulas unchanged
formal runtime uses v2 path
```

---

## 14. 更新 runtime manifest 审计字段

在：

```text
stage8_k2_snr_summarize.m
```

保留原：

```text
prompt_commit = 654b...
tool_commit = 6bc...
```

并新增：

```text
v1_status = STAGE8_K2_SNR_DOMAIN_VALIDATION_INVALID
v1_failure_stage = T4_WHITENING_NUMERIC_GATE
v1_phase_b_executed = false

v2_correction_prompt_commit =
git log -1 --grep="docs(stage8-k2): authorize SNR whitener tolerance correction"

v2_tool_correction_commit =
git log -1 --grep="fix(stage8-k2): align SNR audit with frozen whitener quality"

whitening_tolerance = 1e-8
max_observed_whitening_residual
whitener_modified = false
snr_formula_modified = false
```

报告中增加一节：

```text
V1 gate correction
```

不得改变性能汇总或方法选择逻辑。

---

## 15. 工具修改范围审计

本次工具提交只允许修改：

```text
tools/stage8_k2_snr_validation/README.md

tools/stage8_k2_snr_validation/matlab/
stage8_k2_snr_constants.m
stage8_k2_snr_run_tests.m
stage8_k2_snr_summarize.m

tools/stage8_k2_snr_validation/tests/
test_whitening_identity.m
```

如果执行 AI 认为还必须修改其他 SNR tool 文件：

```text
先停止并报告原因；
不得自行扩展范围。
```

---

## 16. 工具纠偏提交

运行：

```powershell
git diff --check
git diff --name-status
```

确认冻结科学路径零 diff。

提交：

```text
fix(stage8-k2): align SNR audit with frozen whitener quality
```

推送：

```powershell
git push origin experiment/stage8-k2-tangent
```

正式执行前必须满足：

```text
HEAD == origin/experiment/stage8-k2-tangent
Git clean
MATLAB / mwpython / coordinator / lock = 0 / 0 / 0 / 0
```

---

# Part C：重跑全部固定测试

## 17. 运行命令

使用一个 MATLAB R2022b 单线程会话：

```powershell
& 'E:\MATLABR2022b\bin\matlab.exe' `
  -singleCompThread `
  -batch "
  addpath('E:\bs_innovation\tools\stage8_k2_snr_validation\matlab');
  r = stage8_k2_snr_run_tests('E:\bs_innovation');
  disp(r);
  "
```

禁止：

```text
parpool
parfor
第二个 MATLAB
修改 threshold
跳过 T1–T3
只运行 T4
```

---

## 18. 必须得到的测试结果

```text
T1_ORIGINAL_72_HASH PASS
T2_ELEMENT_SNR PASS
T3_RAW_BEAM_COVARIANCE PASS
T4_FROZEN_WHITENER_NUMERIC_QUALITY PASS
T5_WHITE_SNR_SCALING PASS
T6_EXPECTED_VS_REALIZED PASS
T7_PAIRED_SOURCE_NOISE PASS
T8_PROJECTED_K2_SNR PASS
T9_TRUTH_ISOLATION PASS
T10_FOUR_TRIAL_SMOKE PASS

STAGE8_K2_SNR_DOMAIN_VALIDATION_TESTS_PASS 10/10
```

T4 报告必须记录实际值，不得只打印 PASS。

若除 T4 之外的任一测试失败：

```text
硬停止
不得执行 formal run
不得继续修阈值
```

若 T4 在 `1e-8` 下仍失败：

```text
硬停止
不得再放宽
```

---

# Part D：正式 Phase A、Phase B、Phase C

## 19. 正式运行命令

确认 V2 runtime 不存在后：

```powershell
& 'E:\MATLABR2022b\bin\matlab.exe' `
  -singleCompThread `
  -batch "
  addpath('E:\bs_innovation\tools\stage8_k2_snr_validation\matlab');
  out = stage8_k2_snr_run( ...
      'E:\bs_innovation', ...
      'E:\bs_innovation_runtime\stage8_k2_snr_domain_validation_v2');
  disp(out.status);
  "
```

该 runner 会再次从 T1 开始运行 10 项测试，这是预期行为。

---

## 20. Phase A：原 72-trial SNR 审计

Phase A 必须：

```text
重建原 72 trials
72/72 element hash 与 31_* 一致
不运行任何拟合
```

输出：

```text
phase_a_original_snr_audit.csv
phase_a_complete.mat
```

必须报告：

### 20.1 原标签映射

对原 element label：

```text
-6 dB
0 dB
+6 dB
```

分别报告：

```text
element expected SNR
element realized SNR
raw beamspace expected/realized SNR
white beamspace expected/realized SNR
peak raw beam SNR
white receive-domain mapping
K2 projected SNR
```

### 20.2 分层

```text
ALL
P1–P4
noise
L
element label
element label × profile
element label × noise
```

### 20.3 解释

回答：

```text
原 element -6/0/+6 dB
进入 Tangent 的 white beamspace 后实际对应什么区间。
```

不得在 Phase A 后根据结果修改 Phase B 的：

```text
-6/0/+6 dB target
P1–P4
seed
L
noise
```

---

## 21. Phase B smoke

使用：

```text
P1 WHITE L=4 0 dB white
P2 WHITE L=4 0 dB white
P3 CORRELATED L=4 0 dB white
P4 CORRELATED L=4 0 dB white
```

每个 smoke 运行：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

要求：

```text
Tangent safe result valid
RSS/loglik finite
truth leakage = 0
white SNR target error <= 1e-10 dB
```

输出：

```text
phase_b_smoke_method_rows.csv
phase_b_smoke_snr_rows.csv
```

Smoke 不设性能门。

---

## 22. Phase B 72-trial white-control

固定：

```text
2 noise
× 3 L
× 3 white SNR target
× 4 profiles
= 72 trials
```

方法：

```text
CORE_LITE
CORE_PLUS
TANGENT_PROFILE_SAFE
```

输出：

```text
white_control_registry.csv
white_control_snr_trials.csv
white_control_method_rows.csv
phase_b_complete.mat
```

完整性：

```text
registry 72/72
white SNR rows 72/72
method rows 216/216
unique hashes 72/72
truth leakage 0
```

---

## 23. Phase C：两种 SNR 口径比较

Phase C 必须明确区分：

```text
原 element-SNR-controlled trials
新 white-beamspace-SNR-controlled trials
```

允许比较：

```text
原 element 标签映射到的 white SNR；
达到 white -6/0/+6 dB 所需的 element input SNR；
两种控制方式下各 profile 的性能；
receive-domain mapping 的 profile/noise 依赖性。
```

禁止：

```text
仅因为数字标签相同，
就把原 0 dB 与新 0 dB 当成同一物理输入条件。
```

---

# Part E：结果解释要求

## 24. 必须回答的问题

最终报告必须回答：

1. 原 `snr_db` 是否确实是 element expected total-energy SNR；
2. 原 element `-6/0/+6 dB` 分别映射到何种 white-beamspace SNR；
3. 峰值注册工作波束的 SNR 比 element SNR 高多少；
4. raw beamspace 和 white beamspace 总能量 SNR 的差异；
5. 白噪声和相关噪声的映射是否不同；
6. P1–P4 的 receive mapping 是否不同；
7. white-beamspace `-6/0/+6 dB` 下 Tangent 的 joint/center/axis/rho/vector 结果；
8. white-SNR 控制下 Tangent 相对 Core-Lite/Core-Plus 的配对结果；
9. K2 projected SNR 与总 white SNR 是否表现出不同的场景排序；
10. 当前是否有必要启动更大规模 Monte Carlo。

第 10 项只能给出：

```text
RECOMMENDED / NOT_YET_NEEDED
```

不得自动执行。

---

## 25. 不改变 Tangent RETAIN

本轮没有新保留门。

无论 Phase B 性能如何：

```text
原 STAGE8_K2_TANGENT_PROFILE_RETAIN 不变
DEFAULT_K2 = TANGENT_PROFILE_SAFE
Tangent production integration unchanged
```

本轮只修正：

```text
SNR 报告坐标
工程解释
后续 Monte Carlo 的控制变量
```

---

## 26. 本轮仍不是 Monte Carlo

报告必须写明：

```text
每个 factor cell 仍只有一个 source/noise realization；
V2 是配对 SNR 重参数化实验；
不是统计充分 Monte Carlo；
P90 仅是当前有限集合的描述值；
不提供置信区间或 outlier probability。
```

禁止启动：

```text
800 trial
1200 trial
6000 trial
bootstrap
unknown K
```

---

# Part F：Git evidence 与最终收束

## 27. 预期 Git 输出

新增：

```text
innovation-mining/
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

---

## 28. 正式结果复核

完成 marker：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_COMPLETE
```

后，使用一个全新的 MATLAB R2022b `-singleCompThread` 会话只读复核：

```text
42_* 行数
72/72 hashes
216/216 method rows
white SNR target error
truth leakage
manifest SHA-256
runtime/Git artifact byte identity
```

复核会话不得重新运行拟合。

若正式 runner 在完成 marker 后、MATLAB 退出阶段出现 Windows shutdown anomaly：

```text
只有当 artifacts 已完整写入、
SHA-256 一致且独立只读复核通过时，
才记录为 POST_COMPUTATION_SHUTDOWN_ANOMALY；
否则按 INVALID 处理。
```

---

## 29. 归档 019

将：

```text
innovation-mining/stage8_execution_prompts/active/
019_stage8_k2_snr_t4_correction_and_completion_v2.md
```

移动到：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
019_stage8_k2_snr_t4_correction_and_completion_v2.md
```

更新 manifest：

```text
execution_authority = false
status = COMPLETED
related_evidence = 41A_*;42_*
```

---

## 30. 更新 active README

最终写为：

```text
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_SNR_DOMAIN_VALIDATION_V2_COMPLETED

V1:
STOPPED_AT_TOO_STRICT_T4_GATE

V2:
COMPLETE

DEFAULT_K2:
TANGENT_PROFILE_SAFE

SNR REPORTING:
ELEMENT_INPUT
RAW_SEQUENTIAL_BEAMSPACE
WHITENED_SEQUENTIAL_BEAMSPACE
K2_PROJECTED_TRUTH_ONLY_DIAGNOSTIC

TANGENT:
FROZEN

WHITENER:
UNCHANGED

MONTE_CARLO:
NOT_EXECUTED
REQUIRES_SEPARATE AUTHORIZATION
```

更新：

```text
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
```

---

## 31. 结果提交

只暂存：

```text
42_*
019 归档
active README
prompt manifest
00_DOCUMENT_STATUS_INDEX.md
```

提交：

```text
docs(stage8-k2): complete corrected SNR domain validation
```

推送：

```powershell
git push origin experiment/stage8-k2-tangent
```

---

# Part G：最终 scope 审计

## 32. 允许的最终 diff

从：

```text
6bc40af7deed09a56683b8c1e4a6398166855336
```

到最终 HEAD，只允许：

```text
41A_*

tools/stage8_k2_snr_validation/README.md
tools/stage8_k2_snr_validation/matlab/stage8_k2_snr_constants.m
tools/stage8_k2_snr_validation/matlab/stage8_k2_snr_run_tests.m
tools/stage8_k2_snr_validation/matlab/stage8_k2_snr_summarize.m
tools/stage8_k2_snr_validation/tests/test_whitening_identity.m

018 归档
019 新增和归档
prompt README / manifest
00_DOCUMENT_STATUS_INDEX.md

42_*
```

必须零 diff：

```text
tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**
tools/stage8_k2_subspace_baselines/**
beamspace_ml_v18/**
31_*–40_*
```

---

## 33. 最终状态

确认：

```text
HEAD == origin/experiment/stage8-k2-tangent

origin/main unchanged:
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f

origin/research/stage8-k2-vincent-anchored unchanged:
a7139204d717923cb89d0d629b67f1b3ab7ae94d

Git clean
untracked files = 0

MATLAB / mwpython / coordinator / lock:
0 / 0 / 0 / 0
```

---

## 34. 有效终态

完整成功：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_V2_COMPLETE
```

失败：

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_V2_INVALID
```

仅用于：

```text
T1–T10 任一仍失败
T4 > 1e-8
原 72 hash 不匹配
white SNR scaling 失败
source/noise pairing 失败
truth leakage
Phase A/B 行数不完整
冻结路径改变
artifact identity 失败
```

不得根据性能高低判 INVALID。

---

## 35. 最终报告格式

```text
STAGE8_K2_SNR_DOMAIN_VALIDATION_V2_COMPLETE / INVALID

Branch:
Starting HEAD:
V1 prompt commit:
V1 tool commit:
V2 correction prompt commit:
V2 tool correction commit:
Result commit:
Push:
Git clean:

V1:
- status
- failure stage
- Phase B executed

T4:
- V1 tolerance
- V2 tolerance
- WHITE residual
- CORRELATED residual
- whitener rebuilt Tdiff
- whitener modified
- SNR formula modified

Tests:
- 10/10
- max whitening residual

Phase A:
- 72/72 hashes
- element labels
- raw SNR mapping
- white SNR mapping
- peak beam SNR
- receive-domain mapping
- K2 projected SNR

Phase B:
- registry 72/72
- SNR rows 72/72
- methods 216/216
- truth leakage 0
- target error
- Core-Lite results
- Core-Plus results
- Tangent results
- Tangent vs Core paired comparisons

Interpretation:
- element label to white SNR mapping
- required element SNR for white targets
- profile/noise dependence
- total white SNR vs projected K2 SNR

Default K2:
TANGENT_PROFILE_SAFE

Tangent changed:
false

Whitener changed:
false

Existing evidence changed:
false

Monte Carlo executed:
false

Next Monte Carlo authorized:
false
```

完成后停止，不自动启动更大规模 Monte Carlo。
