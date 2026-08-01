# Stage8-K2-VA1A：Vincent-Anchored AML 适用区间分析与路线最终收束（V1）

> 将本文件完整交给负责 `E:\bs_innovation`、MATLAB R2022b 和 Git 的执行 AI。
>
> 本协议只使用已经提交到 Git 的 `36_*` 结果做离线适用性分析，不重新生成
> `Y_element`，不重新运行任何 K1/K2/CML/MUSIC 拟合，不修改算法，也不增加
> holdout、bootstrap、阈值选择器或 V2。
>
> 本轮完成后，无论结果是“存在有限适用区间”还是“未确认稳定适用区间”，
> 都必须关闭 Vincent-Anchored AML 路线，并完成当前 K2 创新范围的分支内收束。
>
> 唯一执行分支：
>
> ```text
> experiment/stage8-k2-vincent-anchored-aml-v1
> ```
>
> 协议：
>
> ```text
> STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_AND_CLOSURE_V1
> ```
>
> 授权：
>
> ```text
> AUTHORIZE_STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_AND_CLOSURE_V1
> ```

---

## 0. 当前科学状态

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

预期当前分支：

```text
experiment/stage8-k2-vincent-anchored-aml-v1
```

预期当前 HEAD：

```text
33ce9238fa09d4ec5b4de865fb41a98710621b8b
docs(stage8-k2): record Vincent anchored AML result
```

不可变上游：

```text
origin/experiment/stage8-k2-classical-baselines-v1
=
bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b

origin/experiment/stage8-k2-tangent-profile-v1
=
721c30aa96f1687c757004613c23e9fb6a814afd
```

若远端 Tangent ref 已被删除，只要求 commit object：

```text
721c30aa96f1687c757004613c23e9fb6a814afd
```

可由：

```powershell
git cat-file -e 721c30aa96f1687c757004613c23e9fb6a814afd^{commit}
```

验证。

其余冻结基线：

```text
origin/experiment/stage8-core-v2
=
9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7

origin/main
=
247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

已有结论：

```text
STAGE8_K2_VINCENT_ANCHORED_AML_NOT_RETAINED

Production integration authorized:
false
```

已有核心结果：

```text
Tangent median/p90 joint RMSE:
0.089727 / 0.185165 deg

Anchored median/p90:
0.107947 / 0.240686 deg

Anchored vs Tangent:
23 wins / 8 ties / 41 losses

P1:
Anchored 明显改善 endpoint 和 separation 指标

P2:
中位数略改善，但 P90 和中心误差恶化

P3:
separation 指标有部分改善，但 endpoint RMSE 恶化

P4:
Anchored 明显不适用
```

---

## 1. 工作树中的特殊未跟踪文件

当前允许存在且必须原样保留的唯一未跟踪文件：

```text
innovation-mining/stage8_execution_prompts/
stage8_k2_vincent_anchored_projector_aml_prompt_v1.md
```

该文件：

```text
不得读取为正式执行合同
不得暂存
不得提交
不得移动
不得删除
不得加入 .gitignore
不得改写
```

Preflight 时允许 `git status --porcelain=v1 --untracked-files=all` 精确包含该一项。

除该文件之外：

```text
不得存在其他 tracked diff
不得存在其他 untracked 文件
```

最终状态同样允许它继续作为唯一未跟踪文件存在，因此最终报告使用：

```text
tracked_worktree_clean = true
allowed_untracked_original_prompt_preserved = true
```

而不是伪称整个工作树绝对 clean。

---

## 2. Git Preflight

执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git switch experiment/stage8-k2-vincent-anchored-aml-v1

$head = (git rev-parse HEAD).Trim()
$remote = (git rev-parse origin/experiment/stage8-k2-vincent-anchored-aml-v1).Trim()
$base = (git rev-parse origin/experiment/stage8-k2-classical-baselines-v1).Trim()
$core = (git rev-parse origin/experiment/stage8-core-v2).Trim()
$main = (git rev-parse origin/main).Trim()
$status = @(git status --porcelain=v1 --untracked-files=all)
```

要求：

```text
HEAD == origin/experiment/stage8-k2-vincent-anchored-aml-v1
HEAD == 33ce9238fa09d4ec5b4de865fb41a98710621b8b
base == bdb2a5186b7ee0c889a3d7563b4e15a3bbc07c7b
core == 9bcb4f7e0d4ec314e5a822deb0ea02216c10c8f7
main == 247fad2208e77b04f7062e22b0fd3fd8a81bfc1f
```

`$status` 只允许：

```text
?? innovation-mining/stage8_execution_prompts/stage8_k2_vincent_anchored_projector_aml_prompt_v1.md
```

若 HEAD 是 `33ce9238` 的明确 docs-only 后代，停止并报告实际 SHA，不自行选择新起点。

本轮不创建新分支。

---

## 3. 不可修改边界

以下全部必须保持相对 `33ce9238` 字节不变：

```text
tools/stage8_k2_vincent_anchored_aml/matlab/**
tools/stage8_k2_vincent_anchored_aml/tests/**

tools/stage8_k2_tangent_profile/**
tools/stage8_k2_classical_baselines/**

beamspace_ml_v18/**

innovation-mining/31_*
innovation-mining/32_*
innovation-mining/33_*
innovation-mining/34_*
innovation-mining/35_*
innovation-mining/36_*
```

不得：

```text
重新运行 72-trial
重新运行任何 fit
修改 source/noise seed
修改 P1–P4
修改 Tangent
修改 Anchored
修改 Full4D
修改 safe selection
新增 selector
新增 online threshold
实现 V2
```

---

## 4. 本轮数据来源

只读取 Git 中以下两个正式文件：

```text
innovation-mining/
36_stage8_k2_vincent_anchored_aml_trials.csv

innovation-mining/
36_stage8_k2_vincent_anchored_aml_diagnostics.csv
```

并只读核对：

```text
36_stage8_k2_vincent_anchored_aml_summary.csv
36_stage8_k2_vincent_anchored_aml_profile_summary.csv
36_stage8_k2_vincent_anchored_aml_complexity.csv
36_stage8_k2_vincent_anchored_aml_experiment.md
```

不读取仓库外 runtime。

不需要：

```text
complete_run.mat
Y_element
MATLAB checkpoint
运行日志
```

---

## 5. 新分析代码路径

只允许新增：

```text
tools/stage8_k2_vincent_anchored_aml/analysis/
```

建议：

```text
analysis/
├── stage8_k2_va_applicability_analysis.m
├── stage8_k2_va_parse_numeric_vector.m
└── test_stage8_k2_va_applicability_analysis.m
```

分析代码只能：

```text
readtable
解析已提交字符串字段
重算描述性指标
写表格和 Markdown
```

禁止调用：

```text
estimate_stage8_known_k_local_cell
stage8_k2_va_fit_safe
stage8_k2_va_run
stage8_k2_tp_fit_safe
stage8_k2_cb_full4d_cml
stage8_k2_va_generate_trial
generate_stage8_element_noise
rng
```

输出中必须记录：

```text
analysis_only_flag = true
fitting_rerun = false
new_trial_count = 0
new_seed_count = 0
```

---

## 6. 数据完整性合同

### 6.1 Trials

`36_*_trials.csv` 必须满足：

```text
288 rows
72 unique trial_id
每个 trial 恰有 4 个方法：

CORE_LITE
TANGENT_PROFILE_SAFE
VINCENT_ANCHORED_PROJECTOR_AML_SAFE
FULL4D_BEAMSPACE_CML_MULTISTART

每个 trial 的 4 行 element_trial_hash 唯一且相同
truth_used_in_fit_flag 全部 false
```

### 6.2 Diagnostics

`36_*_diagnostics.csv` 必须满足：

```text
72 rows
72 unique trial_id
每个 trial 与 trials 的 element_trial_hash 一致
truth_used_in_fit_flag 全部 false
```

### 6.3 历史汇总重算

从 trials 重新计算：

```text
overall
P1–P4
L
SNR
noise
```

的：

```text
median/p90 joint RMSE
median/p90 center error
median/p90 axis error
median/p90 rho error
median/p90 separation-vector error
mean score/SVD
median/p90 runtime
```

与现有 `36_*_summary.csv` 对比。

只允许：

```text
abs(recomputed - serialized_summary) <= 1e-10
```

该容差仅用于 CSV 十进制序列化核对，不是算法误差门。

---

## 7. 逐 trial 配对表

新增：

```text
innovation-mining/
37_stage8_k2_vincent_anchored_applicability_trials.csv
```

每个 trial 只保留一行，至少包含：

### 场景字段

```text
trial_id
element_trial_hash
profile_id
noise_profile_id
L
SNR
secondary_power_db
correlation_magnitude_registered
effective_correlation_magnitude
rho_true_deg
direction_true_deg
```

其中：

```text
L=1：
effective_correlation_magnitude = 1
```

### Tangent 与 Anchored 指标

```text
tangent_joint_RMSE_deg
anchored_joint_RMSE_deg
delta_joint_RMSE_deg

tangent_center_error_deg
anchored_center_error_deg
delta_center_error_deg

tangent_axis_error_deg
anchored_axis_error_deg
delta_axis_error_deg

tangent_rho_error_deg
anchored_rho_error_deg
delta_rho_error_deg

tangent_vector_error_deg
anchored_vector_error_deg
delta_vector_error_deg

tangent_runtime_sec
anchored_runtime_sec
```

定义：

\[
\Delta e
=
e_{\rm Anchored}
-
e_{\rm Tangent}.
\]

因此：

```text
delta < 0：
Anchored 改善

delta > 0：
Anchored 变差
```

配对标签：

```text
WIN:
delta_joint_RMSE_deg < -1e-6

TIE:
abs(delta_joint_RMSE_deg) <= 1e-6

LOSS:
delta_joint_RMSE_deg > 1e-6
```

该 `1e-6 deg` 只复用原报告显示容差，不产生在线门。

---

## 8. K1 中心偏移的可解释分解

从 diagnostics 解析：

```text
K1_center_deg
tangent_axis_hat
selected_alpha_deg
selected_rho_deg
q0
q1
q2
raw_anchor_valid_count
anchor_scan_node_count
conditional_invalid_count
q2_nonconcave_count
rho_out_of_contract_count
raw_candidate_valid
upgrade_flag
fallback_flag
```

从已冻结 profile 常量重建真实中心：

\[
\mathbf c_{\rm true}.
\]

定义：

\[
\mathbf e_0
=
\mathbf c_{\rm true}
-
\widehat{\mathbf c}_{K1}.
\]

令估计轴单位向量为：

\[
\widehat{\mathbf u}.
\]

### 8.1 沿轴真实中心偏移

\[
\boxed{
\alpha_{\rm true}
=
\widehat{\mathbf u}^T\mathbf e_0
}
\]

### 8.2 归一化沿轴偏移

\[
\boxed{
b_\parallel
=
\frac{|\alpha_{\rm true}|}{\rho_{\rm true}}
}
\]

### 8.3 垂直于轴的中心误差

\[
\boxed{
b_\perp
=
\frac{
\|
\mathbf e_0
-
\alpha_{\rm true}\widehat{\mathbf u}
\|_2
}{
\rho_{\rm true}
}
}
\]

### 8.4 锚点修正误差

当 `selected_alpha_deg` 有限：

\[
\boxed{
e_\alpha
=
\frac{
|\widehat\alpha-\alpha_{\rm true}|
}{
\rho_{\rm true}
}
}
\]

否则记为 `NaN`，不得填充。

---

## 9. 条件近似可用性指标

### 9.1 Anchor 有效比例

\[
\boxed{
r_{\rm anchor}
=
\frac{
N_{\rm valid\ anchor}
}{
N_{\rm scan\ anchor}
}
}
\]

### 9.2 条件无效率

\[
r_{\rm invalid}
=
\frac{
N_{\rm conditional\ invalid}
}{
N_{\rm scan\ anchor}
}.
\]

### 9.3 非凹比例

\[
r_{\rm nonconcave}
=
\frac{
N_{q_2\ge0}
}{
N_{\rm scan\ anchor}
}.
\]

### 9.4 超合同比例

\[
r_{\rm out}
=
\frac{
N_{\rho\ out\ of\ contract}
}{
N_{\rm scan\ anchor}
}.
\]

### 9.5 选中锚点曲率代理

当：

```text
q0/q2 finite
q2 < 0
```

时定义：

\[
\boxed{
\kappa_{\rho,\rm selected}
=
\frac{
-q_2\rho_{\rm true}^2
}{
\max(|q_0|,\epsilon)
}
}
\]

否则为 `NaN`。

这些指标只用于论文解释，不能形成在线模式选择器。

---

## 10. 适用区间分析层级

### 10.1 一级：预注册 profile 层，N=18

分别分析：

```text
P1
P2
P3
P4
```

这是允许形成正式论文适用性结论的主要层级。

每个 profile 输出：

```text
Anchored/Tangent median/p90 joint RMSE
median center/axis/rho/vector error
wins/ties/losses
raw valid
upgrades/fallbacks
median b_parallel
median b_perp
median e_alpha
median r_anchor
median kappa_rho_selected
```

### 10.2 二级：宽因子层

分别分析：

```text
L = 1 / 4 / 8
SNR = -6 / 0 / +6
noise = WHITE / CORRELATED
```

每组 N 至少 24 或 36。

该层用于判断是否存在：

```text
只由快拍数
只由 SNR
只由噪声类别
```

即可描述的宽适用区间。

### 10.3 三级：交互单元，N=6

只做描述：

```text
profile × L
profile × SNR
profile × noise
```

禁止把 N=6 交互单元单独写成已确认的普遍适用区间。

### 10.4 四级：连续诊断四分位

分别按以下字段的有效值做经验四分位：

```text
b_parallel
b_perp
K1_center_error_deg / rho_true_deg
axis_error_deg
r_anchor
kappa_rho_selected
```

每个四分位报告：

```text
N
Anchored wins/ties/losses
median delta_joint_RMSE
p90 delta_joint_RMSE
median delta_center
median delta_rho
median delta_vector
raw candidate valid rate
fallback rate
```

四分位只用于解释机制，不能生成自动 threshold。

---

## 11. 适用性分类规则

### 11.1 `SUPPORTED_ENDPOINT_AND_SEPARATION`

一个一级或二级组同时满足：

```text
N >= 18
Anchored valid = N
median joint RMSE Anchored <= Tangent
p90 joint RMSE Anchored <= Tangent
wins > losses
median separation-vector error Anchored <= Tangent
```

### 11.2 `MEDIAN_GAIN_BUT_TAIL_UNSTABLE`

同时满足：

```text
median joint RMSE Anchored < Tangent
```

但以下任一成立：

```text
p90 Anchored > Tangent
或
wins <= losses
```

### 11.3 `SEPARATION_STRUCTURE_ONLY`

同时满足：

```text
median joint RMSE Anchored > Tangent
median rho error Anchored < Tangent
median separation-vector error Anchored < Tangent
```

### 11.4 `NOT_SUPPORTED`

不满足以上三类。

### 11.5 交互和四分位

只允许：

```text
DESCRIPTIVE_ONLY
```

不得以 N=6 或 post-hoc quartile 单独提升正式适用性主张。

---

## 12. 最终路线状态

只允许以下状态：

### A. 广泛适用

```text
STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_CLOSED_BROADER_REGIME_SUPPORTED
```

条件：

```text
至少两个 profile 为 SUPPORTED_ENDPOINT_AND_SEPARATION
或
至少一个 L/SNR/noise 宽因子组为 SUPPORTED_ENDPOINT_AND_SEPARATION
```

### B. 仅 P1-like 有利场景

```text
STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_CLOSED_P1_LIKE_ONLY
```

条件：

```text
P1 为 SUPPORTED_ENDPOINT_AND_SEPARATION
且
不满足 BROADER_REGIME_SUPPORTED
```

### C. 没有稳定适用区间

```text
STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_CLOSED_NO_ROBUST_REGIME
```

条件：

```text
没有任何 profile 为 SUPPORTED_ENDPOINT_AND_SEPARATION
```

### D. 分析无效

```text
STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_ANALYSIS_INVALID
```

仅用于：

```text
CSV 计数/方法/hash 不一致
truth leakage
历史汇总无法重算
已有算法/证据被修改
分析输出非有限且未按 NaN 合同处理
```

无论 A/B/C 哪个状态成立：

```text
Vincent-Anchored 不成为默认算法
不进入生产接口
Tangent-Profile 保持默认 K2 候选
不实现 V2
不建立自动 selector
路线永久关闭
```

---

## 13. 输出文件

新增：

```text
innovation-mining/
37_stage8_k2_vincent_anchored_applicability_trials.csv

37_stage8_k2_vincent_anchored_applicability_group_summary.csv

37_stage8_k2_vincent_anchored_applicability_diagnostic_quartiles.csv

37_stage8_k2_vincent_anchored_applicability_claim_matrix.csv

37_stage8_k2_vincent_anchored_applicability_and_route_closure.md
```

### 13.1 Claim matrix

至少包含：

```text
scope_type
scope_value
N
classification
median_joint_tangent
median_joint_anchored
p90_joint_tangent
p90_joint_anchored
wins
ties
losses
median_rho_tangent
median_rho_anchored
median_vector_tangent
median_vector_anchored
claim_authorized
```

规则：

```text
profile / L / SNR / noise：
可以按规则授权正式 claim

interaction / quartile：
claim_authorized = false
```

---

## 14. 论文中的最终表述边界

最终 closure report 必须明确区分：

### 已支持

```text
Vincent/Bonacci 式移动锚点推广在当前圆柱阵顺序 Beamspace 上
理论和实现可运行；

在部分有利注册场景中，它可改善 separation 结构和 endpoint RMSE；

它显著优于 Core-Lite，且比当前 Full4D 数值基线使用更少核心调用。
```

### 未支持

```text
作为 Tangent 的统一替代方法；
适用于全部功率差、相关性、SNR 和快拍条件；
稳定改善 P2/P3/P4；
在线根据 b_parallel、axis error 或 curvature 自动切换；
优于理论全局 ML；
生产集成。
```

### 默认 K2 路线

```text
TANGENT_PROFILE_SAFE
```

### Vincent-Anchored 定位

根据最终状态写为：

```text
BROAD RESEARCH OPTION
或
P1-LIKE FAVORABLE-REGIME RESEARCH VARIANT
或
NO ROBUST APPLICABILITY REGIME
```

但始终：

```text
NOT_DEFAULT
NOT_PRODUCTION
NO_V2
```

---

## 15. 分析测试

新增：

```text
tools/stage8_k2_vincent_anchored_aml/analysis/
test_stage8_k2_va_applicability_analysis.m
```

至少检查：

1. `288/72` count contract；
2. 每 trial 四方法同 hash；
3. paired delta 方向正确；
4. `WIN/TIE/LOSS` 人工 fixture；
5. `alpha_true / b_parallel / b_perp` 几何恒等式；
6. 轴符号翻转时：
   ```text
   b_parallel_abs
   b_perp
   ```
   不变；
7. fallback 行的 selected alpha 保留 `NaN`；
8. profile-level 分类 fixture；
9. interaction 始终 `DESCRIPTIVE_ONLY`；
10. 重算 `36_*` 汇总误差不超过 `1e-10`。

MATLAB：

```text
R2022b
-singleCompThread
```

不启动任何拟合函数。

---

## 16. 提交顺序

### 16.1 Prompt commit

新增：

```text
innovation-mining/stage8_execution_prompts/active/
016_stage8_k2_vincent_anchored_applicability_closure_v1.md
```

内容为本协议全文。

更新 active README：

```text
STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_ANALYSIS_ACTIVE
ANALYSIS_ONLY
NO_FITTING_RERUN
NO_NEW_TRIALS
```

只暂存这两个 tracked 文件，不触碰允许的原始未跟踪 prompt。

提交：

```text
docs(stage8-k2): define anchored applicability closure
```

推送当前分支。

### 16.2 Analysis tool commit

只提交：

```text
tools/stage8_k2_vincent_anchored_aml/analysis/
```

提交：

```text
analysis(stage8-k2): map anchored applicability regime
```

推送后要求：

```text
HEAD == origin current branch
tracked worktree clean
allowed untracked original prompt only
```

### 16.3 执行分析

运行：

```text
MATLAB R2022b
-singleCompThread
```

调用 analysis function。

不得运行：

```text
任何 fit
任何 trial generator
任何随机数
```

### 16.4 Closure commit

提交：

```text
37_*
```

将：

```text
016_stage8_k2_vincent_anchored_applicability_closure_v1.md
```

移到：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
```

更新 active README 为：

```text
NO_ACTIVE_STAGE8_EXECUTION

STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_CLOSED

Final applicability state:
<实际 A/B/C 状态>

Default K2:
TANGENT_PROFILE_SAFE

Vincent-Anchored:
NOT_DEFAULT
NOT_PRODUCTION
NO_V2

Further Stage8-K2 algorithm work:
NOT_AUTHORIZED
```

提交：

```text
docs(stage8-k2): close anchored applicability scope
```

只推送：

```powershell
git push origin experiment/stage8-k2-vincent-anchored-aml-v1
```

---

## 17. 最终冻结审计

执行：

```powershell
git diff --name-status `
  33ce9238fa09d4ec5b4de865fb41a98710621b8b..HEAD
```

只允许：

```text
新增 analysis/
新增 37_*
016 prompt 的新增和归档
active README 更新
```

以下必须无 diff：

```text
tools/stage8_k2_vincent_anchored_aml/matlab/**
tools/stage8_k2_vincent_anchored_aml/tests/**
31_* / 32_* / 33_* / 34_* / 35_* / 36_*
beamspace_ml_v18/**
```

确认：

```text
HEAD == origin/experiment/stage8-k2-vincent-anchored-aml-v1
origin/classical baseline unchanged
origin/core-v2 unchanged
origin/main unchanged

tracked_worktree_clean = true
allowed_untracked_original_prompt_preserved = true
MATLAB / mwpython / coordinator / lock = 0 / 0 / 0 / 0
```

---

## 18. 最终报告格式

```text
STAGE8_K2_VINCENT_ANCHORED_APPLICABILITY_CLOSURE_PASS / FAIL

Branch:
Starting HEAD:
Prompt commit:
Analysis tool commit:
Closure commit:
Push:
Tracked worktree clean:
Allowed untracked original prompt preserved:

Historical evidence unchanged:
- 31/32
- 33/34
- 35/36
- Step12.7

Analysis mode:
- fitting rerun = false
- new trials = 0
- new seeds = 0
- runtime required = false

Integrity:
- method rows 288/288
- trials 72/72
- diagnostics 72/72
- hashes
- truth isolation
- summary reconstruction

Profile classifications:
- P1
- P2
- P3
- P4

Broad-factor classifications:
- L
- SNR
- noise

Mechanism:
- b_parallel
- b_perp
- axis error
- anchor valid ratio
- curvature proxy
- alpha correction error

Final applicability state:

Paper-authorized applicability statement:

Default K2 method:
TANGENT_PROFILE_SAFE

Vincent-Anchored status:
NOT_DEFAULT / NOT_PRODUCTION / NO_V2

Further algorithm execution:
NOT_AUTHORIZED
```

完成后永久停止本路线。
