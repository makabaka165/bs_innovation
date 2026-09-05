# Stage8-K2 Raw Tangent Core：原生域 SNR、分辨成功率与旧路线剪枝执行提示词（V1）

> 将本文件完整交给负责本地 `E:\bs_innovation`、MATLAB R2022b、Git worktree 和 GitHub 推送的执行 AI。
>
> 本协议不是在 `main` 上继续修改，也不是复用旧 Tangent Safe runtime。  
> 它从当前 `main` 的精确提交建立一个独立实验分支和独立 worktree，在新分支内完成：
>
> 1. 将 Tangent Safe 拆成纯 `Tangent Core`；
> 2. 删除 Tangent 流程中的固定注册网格双目标兜底；
> 3. 删除 Tangent 的 canonical/fixed-backbone/multicenter cache 构建和使用路径；
> 4. 直接在白化 Beamspace 中按照目标 SNR 生成复高斯噪声；
> 5. 只使用白化 Beamspace IID 复高斯噪声，不再使用 Toeplitz 相关噪声；
> 6. 新增基于 3 dB 波束宽度的、标签无关的双目标定位成功率与严格分辨成功率；
> 7. 在新分支中物理删除旧 72-trial Tangent 路线及对应提示词；
> 8. 保留并调用 Beamspace 与 Element-domain 经典算法科学内核；
> 9. 以“各原生观测域相同标称 SNR、相同目标场景、相同快拍条件”进行两层比较；
> 10. 保存完整 plot-ready 数据，后续画图不重新运行算法。
>
> 本轮是**独立科学分支**，不是生产集成。完成后只推送该新分支，不合并回 `main`。
>
> 协议 ID：
>
> ```text
> STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_V1
> ```
>
> 授权 ID：
>
> ```text
> AUTHORIZE_STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_V1
> ```

---

# 0. 不可混淆的科学定位

## 0.1 本轮研究对象

本轮研究对象是：

```text
TANGENT_PROFILE_CORE
```

而不是：

```text
TANGENT_PROFILE_SAFE
```

`Tangent Core` 只包含：

```text
白化 Beamspace 观测
→ 单目标等效中心
→ 投影残差
→ 有效角度导数
→ Fisher 归一化分离轴
→ 一维完整双目标流形 DML 尺度搜索
→ Raw Tangent 两个角度或明确失败
```

它不包含：

```text
固定注册网格 K=2 候选
Tangent 与 fixed-K2 likelihood selector
fallback
cache provider
canonical cache
fixed-backbone cache
multicenter cache
```

## 0.2 “删除 K2 兜底”不等于删除双目标模型

本轮不得调用独立的固定注册网格双目标基线作为兜底。

但 Tangent Core 的每个尺度候选仍然必须构造：

\[
G_\rho
=
\left[
g\left(\widehat c-\frac{\rho}{2}\widehat u\right),
g\left(\widehat c+\frac{\rho}{2}\widehat u\right)
\right]
\]

并以请求秩 2 计算完整双目标集中 DML。

因此：

```text
删除的是 fixed-K2 fallback；
保留的是 K=2 双目标统计模型。
```

## 0.3 本轮结果不覆盖 `main` 的既有结论

当前 `main` 中的历史证据继续存在于 `main` 的 Git 历史。

本新分支中的删除、剪枝与新实验不得被解释为：

```text
原 Tangent Safe 证据无效；
原 white-SNR Monte Carlo 被撤回；
原经典算法对比被否定；
原缓存实验数据被篡改。
```

本轮回答的是一个新的、更窄的问题：

> 当 Tangent 只保留核心算法、直接接收白化 Beamspace 观测且不使用 fixed-K2 兜底时，在不同原生域标称 SNR 下，其数值有效率、端点定位成功率、严格分辨成功率和角度误差怎样变化？

---

# 1. 当前 Git 锚点

仓库：

```text
E:\bs_innovation
makabaka165/bs_innovation
```

当前远端主分支必须为：

```text
origin/main
=
644fc6e0041e400b6500579bba93d49f45e46990
```

提交标题：

```text
docs: add tangent summaries and remove legacy code
```

该提交的父提交为：

```text
c5a76f19824bdbc2d34dd80f107bdf0050874da3
```

目标新分支：

```text
experiment/stage8-k2-raw-tangent-core-native-snr-v1
```

目标 worktree：

```text
E:\bs_innovation_worktrees\raw-tangent
```

目标 runtime：

```text
E:\bs_innovation_runtime\
experiment_stage8-k2-raw-tangent-core-native-snr-v1
```

Windows Scheduled Task：

```text
BSInnovation-Stage8K2-RawTangentCore-NativeSNR-V1
```

---

# 2. 主仓库 Preflight

在原仓库执行：

```powershell
Set-Location E:\bs_innovation

git fetch origin --prune --tags
git switch main
git pull --ff-only origin main

$localMain  = (git rev-parse HEAD).Trim()
$remoteMain = (git rev-parse origin/main).Trim()
$status     = @(git status --porcelain=v1 --untracked-files=all)
$worktrees  = git worktree list --porcelain
```

硬要求：

```text
$localMain == $remoteMain
$localMain == 644fc6e0041e400b6500579bba93d49f45e46990
$status 为空
```

确认本地和远端均不存在：

```text
experiment/stage8-k2-raw-tangent-core-native-snr-v1
```

确认以下目录不存在：

```text
E:\bs_innovation_worktrees\raw-tangent
E:\bs_innovation_runtime\
experiment_stage8-k2-raw-tangent-core-native-snr-v1
```

若分支、worktree 或 runtime 任一已存在：

```text
硬停止；
只报告实际内容；
不得自动删除、覆盖、worktree prune、reset 或复用旧 runtime。
```

确认：

```text
MATLAB = 0
mwpython = 0
与 raw-tangent 协议相关的 coordinator = 0
同名 Windows Scheduled Task = 0
```

---

# 3. 建立本地备份、分支和 worktree

## 3.1 本地备份

在：

```text
E:\bs_innovation_runtime\
experiment_stage8-k2-raw-tangent-core-native-snr-v1\
backup
```

创建：

```text
bs_innovation_main_644fc6e_before_raw_tangent.bundle
```

执行：

```powershell
git bundle create <bundle_path> `
  main `
  research/stage8-k2-vincent-anchored `
  --tags

git bundle verify <bundle_path>
```

若 research 分支本地不存在，可以只对存在的 refs 创建 bundle，但必须包含：

```text
main@644fc6e
全部 tags
```

## 3.2 创建 worktree 分支

在原仓库执行：

```powershell
git worktree add `
  -b experiment/stage8-k2-raw-tangent-core-native-snr-v1 `
  E:\bs_innovation_worktrees\raw-tangent `
  644fc6e0041e400b6500579bba93d49f45e46990
```

进入新 worktree：

```powershell
Set-Location E:\bs_innovation_worktrees\raw-tangent
```

要求：

```text
HEAD == 644fc6e0041e400b6500579bba93d49f45e46990
当前分支 == experiment/stage8-k2-raw-tangent-core-native-snr-v1
Git clean
```

首次推送：

```powershell
git push -u origin experiment/stage8-k2-raw-tangent-core-native-snr-v1
```

从此之后：

```text
所有编辑、MATLAB、测试、提交和 push 均在新 worktree 执行；
原 E:\bs_innovation 的 main 不再切换、不修改；
GitHub 只用于 fetch/push 和定位旧代码，不直接在线改文件。
```

---

# 4. 提交与阶段顺序

必须按以下顺序执行，禁止在新 Core 通过测试前先删除旧代码。

## Commit A：设计、删除清单和分支状态

提交：

```text
docs(stage8-k2): define raw Tangent native-SNR pruning
```

内容：

```text
新协议文档
删除前路径与 blob SHA 清单
新架构说明
active README
```

## Commit B：先实现新 Core、新 SNR 和新评价工具

提交：

```text
feat(stage8-k2): add cache-free raw Tangent native-SNR core
```

只有当全部固定测试通过后才允许进入剪枝。

## Commit C：物理删除旧 72、Safe runner 和 cache

提交：

```text
refactor(stage8-k2): prune legacy Safe, 72-trial and cache routes
```

## Commit D：正式结果

提交：

```text
docs(stage8-k2): record raw Tangent native-SNR results
```

每个提交均推送当前新分支。

---

# 5. 删除前清单

新增：

```text
innovation-mining/
57_stage8_k2_raw_tangent_pruning_manifest.csv
```

字段：

```text
path
blob_sha
bytes
category
action
reason
retained_in_main_flag
```

`retained_in_main_flag` 全部为：

```text
true
```

因为所有删除内容仍由 `main@644fc6e` 和 Git 历史保存。

删除清单必须在任何 `git rm` 前生成并提交。

---

# 6. 新 Core 工具目录

新增唯一活跃目录：

```text
tools/stage8_k2_raw_tangent_core_native_snr/
```

建议结构：

```text
tools/stage8_k2_raw_tangent_core_native_snr/
├── README.md
├── matlab/
│   ├── stage8_k2_rtc_constants.m
│   ├── stage8_k2_rtc_add_paths.m
│   ├── stage8_k2_rtc_build_context.m
│   ├── stage8_k2_rtc_build_registry.m
│   ├── stage8_k2_rtc_build_truth.m
│   ├── stage8_k2_rtc_build_source.m
│   ├── stage8_k2_rtc_build_clean_signals.m
│   ├── stage8_k2_rtc_generate_beamspace_observation.m
│   ├── stage8_k2_rtc_generate_element_observation.m
│   ├── stage8_k2_rtc_measure_beamwidths.m
│   ├── stage8_k2_rtc_fit_k1_white.m
│   ├── stage8_k2_rtc_fit_core.m
│   ├── stage8_k2_rtc_projected_direction.m
│   ├── stage8_k2_rtc_profile_scale_direct.m
│   ├── stage8_k2_rtc_fit_beamspace_methods.m
│   ├── stage8_k2_rtc_fit_element_methods.m
│   ├── stage8_k2_rtc_resolution_metrics.m
│   ├── stage8_k2_rtc_result_row.m
│   ├── stage8_k2_rtc_diagnostic_row.m
│   ├── stage8_k2_rtc_checkpoint_write.m
│   ├── stage8_k2_rtc_checkpoint_validate.m
│   ├── stage8_k2_rtc_status_write.m
│   ├── stage8_k2_rtc_run.m
│   ├── stage8_k2_rtc_finalize.m
│   ├── stage8_k2_rtc_verify.m
│   └── stage8_k2_rtc_file_sha256.m
├── plotting/
│   └── stage8_k2_rtc_plot_from_committed_data.m
├── powershell/
│   ├── Stage8K2RTCController.ps1
│   └── Stage8K2RTCCloseout.ps1
└── tests/
    ├── test_native_snr_formula.m
    ├── test_scale_equivalence.m
    ├── test_no_toeplitz_active_route.m
    ├── test_beamwidth_contract.m
    ├── test_resolution_metric_swap_invariance.m
    ├── test_resolution_metric_collapse_rejection.m
    ├── test_k1_white_solver.m
    ├── test_core_has_no_fixed_k2.m
    ├── test_core_has_no_cache_provider.m
    ├── test_direct_profile_full_manifold.m
    ├── test_baseline_direct_calls.m
    ├── test_truth_isolation.m
    ├── test_checkpoint_resume.m
    ├── test_plot_only_regeneration.m
    └── test_scheduled_controller.ps1
```

---

# 7. 本轮唯一噪声模型

只允许：

```text
WHITENED_BEAMSPACE_IID_CIRCULAR_COMPLEX_GAUSSIAN
```

和阵元域参考组对应的：

```text
ELEMENT_DOMAIN_IID_CIRCULAR_COMPLEX_GAUSSIAN
```

禁止：

```text
STAGE5_TOEPLITZ_CORRELATED
R_az Toeplitz
R_el Toeplitz
colored-noise branch
相关噪声白化实验因子
```

说明：

- Beamspace 组在当前 WHITE measurement context 下构造干净白化流形；
- Beamspace 噪声直接在白化后 15 维空间生成；
- Element 组独立生成 IID 阵元白噪声；
- 两个组使用相同目标、源、快拍、SNR 数字和 replicate，但不是同一个观测 realization；
- 跨域结果属于 `SCENARIO_MATCHED_NATIVE_DOMAIN_SNR_REFERENCE`。

---

# 8. 固定 measurement context

只构造：

```text
PRIMARY_RECT_E14_A31
WHITE
```

对应的 measurement model。

要求：

```text
W_I 列数 = 15
T_I 尺寸 = 15×15
effective whitening rank = 15
phase factor = 1
```

干净阵元信号仍使用当前圆柱阵工作子阵和完整流形：

\[
X_e=A(\Theta)S.
\]

干净白化 Beamspace 信号为：

\[
\boxed{
X_w=T_IW_I^HX_e.
}
\]

不得在新 Core 中：

```text
从 Z 逆重建 Y_element；
使用伪逆制造阵元观测；
把 15 维噪声映射回 2080 维；
使用目标真值构造估计器初始化。
```

---

# 9. Beamspace 原生 SNR 定义

## 9.1 平均干净信号功率

令：

```text
r = 15
L = 快拍数
```

定义：

\[
\boxed{
P_{s,w}
=
\frac{\|X_w\|_F^2}{rL}.
}
\]

## 9.2 标称 SNR

目标标称 SNR：

\[
\gamma
=
10^{\gamma_{\rm dB}/10}.
\]

每个复噪声样本的方差：

\[
\boxed{
\sigma_w^2
=
\frac{P_{s,w}}{\gamma}
=
\frac{\|X_w\|_F^2}{\gamma rL}.
}
\]

## 9.3 复高斯噪声

生成：

\[
E_R,E_I
\overset{\rm iid}{\sim}
\mathcal N(0,1),
\]

\[
\boxed{
N_w
=
\sqrt{\frac{\sigma_w^2}{2}}
(E_R+jE_I).
}
\]

最终 Beamspace 观测：

\[
\boxed{
Z=X_w+N_w.
}
\]

## 9.4 标称与 realized SNR

标称：

\[
\boxed{
\gamma_{w,\rm nominal}
=
\frac{\|X_w\|_F^2}{rL\sigma_w^2}.
}
\]

每个 trial 实际值：

\[
\boxed{
\gamma_{w,\rm realized}
=
\frac{\|X_w\|_F^2}{\|N_w\|_F^2}.
}
\]

要求：

```text
nominal target error <= 1e-12 dB
realized SNR 不被强行归一化，允许自然波动
```

禁止使用：

\[
\sigma_w^2
=
\frac{\|X_w\|_F^2}
{\gamma\|E\|_F^2}
\]

这种按当次 realized noise norm 固定实际 SNR 的方案。

---

# 10. Element 原生 SNR 定义

使用相同的：

```text
truth
source matrix S
L
profile
nominal SNR number
replicate ID
```

但独立生成 Element-domain 噪声。

令：

```text
M = 2080
```

平均干净阵元信号功率：

\[
\boxed{
P_{s,e}
=
\frac{\|X_e\|_F^2}{ML}.
}
\]

噪声方差：

\[
\boxed{
\sigma_e^2
=
\frac{P_{s,e}}{\gamma}
=
\frac{\|X_e\|_F^2}{\gamma ML}.
}
\]

生成：

\[
\boxed{
N_e
=
\sqrt{\frac{\sigma_e^2}{2}}
(E_{e,R}+jE_{e,I}),
}
\]

\[
\boxed{
Y_e=X_e+N_e.
}
\]

记录：

\[
\gamma_{e,\rm realized}
=
\frac{\|X_e\|_F^2}{\|N_e\|_F^2}.
\]

Beamspace 噪声和 Element 噪声使用不同 seed，但均由同一 `base_realization_index` 确定。

---

# 11. 两类公平性必须分别声明

## 11.1 Beamspace 组内严格配对

以下方法共用完全相同的 \(Z\)：

```text
TANGENT_PROFILE_CORE
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
```

允许：

```text
逐 trial 配对差值
wins / ties / losses
共同有效子集比较
```

## 11.2 Element 组内严格配对

以下方法共用完全相同的 \(Y_e\)：

```text
FULL4D_ELEMENT_CML_MULTISTART
ELEMENT_MUSIC_K2
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

允许组内逐 trial 配对。

## 11.3 跨域只作场景匹配参考

Beamspace 和 Element 组：

```text
相同 truth
相同 source matrix
相同 nominal SNR 数字
相同 L
相同 profile
相同 replicate
```

但噪声 realization 与观测维数不同。

因此跨域只允许比较：

```text
success-rate 曲线
valid-rate 曲线
median/P90 RMSE
failure composition
runtime/复杂度
Profile/L 趋势
```

禁止跨域输出：

```text
逐 trial wins/ties/losses
same-observation superiority
same-physical-realization
```

图标题必须明确：

```text
Native-domain nominal-SNR comparison
```

---

# 12. 注册实验因子

只保留一个噪声条件。

固定：

```text
nominal SNR:
-6 / 0 / +6 / +10 / +14 / +18 / +22 dB

L:
1 / 4 / 8

Profile:
P1 / P2 / P3 / P4

replicates per exact cell:
20
```

总 scenario 数：

\[
7\times3\times4\times20
=
\boxed{1680}.
\]

每个 scenario 同时生成：

```text
1 个 Beamspace-native observation
1 个 Element-native observation
```

---

# 13. Profile 保持不变

保留当前四个场景，不重新调参：

| Profile | 中心 `[az,el]` | 分离 | 轴角 | 次目标功率 | \(L>1\) 源相关幅度 |
|---|---:|---:|---:|---:|---:|
| P1 | `[8.00,10.00]°` | `0.30°` | `45°` | `0 dB` | `0` |
| P2 | `[8.20,10.00]°` | `0.20°` | `0°` | `-6 dB` | `0` |
| P3 | `[7.90,10.10]°` | `0.15°` | `90°` | `0 dB` | `0.9` |
| P4 | `[8.10,9.95]°` | `0.10°` | `135°` | `-6 dB` | `0.9` |

当：

```text
L = 1
```

源相关幅度按单快拍合同为 1，但次目标功率比仍按 Profile 保持。

---

# 14. Common-random-number 设计

同一个：

```text
L × Profile × replicate
```

定义一个基础 realization。

基础数：

\[
3\times4\times20=240.
\]

在七个 SNR 点上复用：

```text
相同 source matrix
相同 Beamspace 标准复高斯底样本
相同 Element 标准复高斯底样本
```

只改变：

```text
sigma_w
sigma_e
```

这样得到平滑、严格可重复的 SNR 曲线。

建议 seed：

```text
source_seed_base       = 580100000
beam_noise_seed_base   = 580200000
element_noise_seed_base= 580300000
```

基础 realization index 必须在 240 组内唯一。

---

# 15. 3 dB 波束宽度合同

## 15.1 不硬编码近似波束宽度

不得直接写：

```text
az BW = 2.51°
el BW = 3.60°
```

必须使用当前：

```text
sim_cfg
当前工作子阵
当前 Taylor taper
phase factor = 1
```

通过：

```text
analyze_reference_beam
measure_scan_3db_width
```

机械测量。

## 15.2 每个 Profile 中心测量一次

对每个 Profile 的注册中心：

\[
c_p=[c_{\phi,p},c_{\theta,p}]
\]

分别测量：

\[
BW_{\phi,p,3{\rm dB}},
\qquad
BW_{\theta,p,3{\rm dB}}.
\]

新增：

```text
innovation-mining/
58_stage8_k2_raw_tangent_beamwidth_contract.csv
```

字段：

```text
profile_id
center_az_deg
center_el_deg
az_bw_3db_deg
el_bw_3db_deg
az_left_cross_deg
az_right_cross_deg
el_left_cross_deg
el_right_cross_deg
configuration_hash
beamwidth_contract_hash
```

要求：

```text
全部宽度有限且 > 0
左右 3 dB crossing 均存在
同一配置重复计算逐位或数值等价
```

这些宽度只用于离线评价，不进入任何估计器。

---

# 16. 标签无关端点误差

对估计：

\[
\widehat\Xi
=
\{\widehat\xi_1,\widehat\xi_2\}
\]

和真值：

\[
\Xi
=
\{\xi_1,\xi_2\}
\]

分别检查两个排列。

对排列 \(\pi\) 和端点 \(k\)，定义 Beamwidth-normalized 误差：

\[
\boxed{
e_{k,\pi}^{({\rm BW})}
=
\sqrt{
\left(
\frac{
\widehat\phi_{\pi(k)}-\phi_k
}{
BW_{\phi,p,3{\rm dB}}
}
\right)^2
+
\left(
\frac{
\widehat\theta_{\pi(k)}-\theta_k
}{
BW_{\theta,p,3{\rm dB}}
}
\right)^2
}.
}
\]

定义：

\[
\boxed{
d_{\max}^{({\rm BW})}
=
\min_{\pi\in S_2}
\max_{k=1,2}
e_{k,\pi}^{({\rm BW})}.
}
\]

同时保存普通角度单位：

\[
\boxed{
d_{\max}^{({\rm deg})}
=
\min_{\pi\in S_2}
\max_{k=1,2}
\|
\widehat\xi_{\pi(k)}-\xi_k
\|_2.
}
\]

`d_max` 的排列必须直接针对最大端点误差优化，不能复用“最小总平方误差”的排列并默认二者等价。

---

# 17. 工程化定位成功率

定义：

\[
\boxed{
I_{\rm localization}
=
\mathbb I
\left[
\text{fit valid}
\land
d_{\max}^{({\rm BW})}\le0.1
\right].
}
\]

这里：

```text
0.1
```

表示端点误差不超过相应二维 3 dB 参考波束宽度尺度的 10%。

这就是对原：

```text
0.1°
```

的工程化替换。

---

# 18. 严格分辨成功率

## 18.1 真实分离的 Beamwidth-normalized 尺度

令：

\[
\Delta\phi_{\rm true}
=
\phi_2-\phi_1,
\]

\[
\Delta\theta_{\rm true}
=
\theta_2-\theta_1.
\]

定义：

\[
\boxed{
\rho_{\rm true}^{({\rm BW})}
=
\sqrt{
\left(
\frac{\Delta\phi_{\rm true}}
{BW_{\phi,p,3{\rm dB}}}
\right)^2
+
\left(
\frac{\Delta\theta_{\rm true}}
{BW_{\theta,p,3{\rm dB}}}
\right)^2
}.
}
\]

## 18.2 Trial 相关门限

\[
\boxed{
\tau_{\rm trial}^{({\rm BW})}
=
\min
\left(
0.1,\,
0.4\rho_{\rm true}^{({\rm BW})}
\right).
}
\]

## 18.3 最终定义

\[
\boxed{
I_{\rm resolution}
=
\mathbb I
\left[
\text{fit valid}
\land
d_{\max}^{({\rm BW})}
\le
\tau_{\rm trial}^{({\rm BW})}
\right].
}
\]

由于：

\[
0.4<0.5,
\]

两个估计端点必须分别进入两个不重叠真值邻域，可避免“两个估计都塌缩在中心”被误判为双目标分辨成功。

不得根据正式结果调整：

```text
0.1
0.4
```

---

# 19. 所有方法共同评价指标

每个方法、每个 scenario 保存：

```text
fit_valid
fit_status
angles_hat_deg
best_permutation_id

d_max_deg
d_max_bw

localization_success_01bw
resolution_success

joint_RMSE_deg
azimuth_RMSE_deg
elevation_RMSE_deg
center_error_deg
axis_error_deg
rho_hat_deg
rho_error_deg
rho_relative_error
separation_vector_error_deg

nominal_snr_db
realized_snr_db
observation_domain
runtime_sec
score_call_count
SVD_call_count
eig_call_count
```

对于 invalid/N/A：

```text
误差为 NaN
success = false
同时保留 applicable 和 failure reason
```

N/A 与 algorithmic invalid 必须分开计数。

---

# 20. Raw Tangent Core 的 K1 中心

直接白化 Beamspace 输入没有 `Y_element`，因此不得伪造或逆重建阵元数据以调用旧 grouped initialization。

新增自包含白化域 K1：

```text
stage8_k2_rtc_fit_k1_white
```

## 20.1 粗搜索

在当前公共 21 点注册网格：

```text
7 个方位 × 3 个俯仰
```

逐点构造完整白化单目标流形并计算 K=1 集中 DML。

选择 likelihood 最大的有效点：

\[
\widehat c_{\rm coarse}.
\]

## 20.2 连续精化

从 \(\widehat c_{\rm coarse}\) 启动现有 K1 连续坐标精化合同：

```text
max sweeps = 8
coordinate radius = 0.20°
scan points = 9
fminbnd TolX = 1e-4°
fminbnd MaxFunEvals = 80
relative score tolerance = 1e-9
angle update tolerance = 1e-3°
update order = azimuth then elevation
```

可以机械调用：

```text
refine_stage8_k1_continuous
```

其 `full_data` 只提供真实的：

```text
Zseq_white = Z
```

不得提供假的 `Y_element`。

## 20.3 K1 最终选择

在 coarse 与 continuous 都有效时选择集中 likelihood 较高者。

没有：

```text
grouped Stage4/5 initialization
fixed registered manifold provider
cache
K=2 helper
```

输出名称：

```text
K1_WHITE_SINGLE_TARGET_DML_CENTER
```

必须在报告中说明：

> 这是新 Raw Tangent Core 的自包含白化域单目标中心估计器；它不要求复刻旧 Safe 路线中依赖阵元数据的 grouped initialization。

---

# 21. Raw Tangent Core 实现

新增：

```text
stage8_k2_rtc_fit_core
```

函数输入：

```text
Z_white
model
local_domain
constants
```

禁止输入：

```text
Y_element
truth
profile ID
nominal SNR
realized SNR
beamwidth
fixed K2 candidate
baseline result
cache provider
```

流程：

1. 调用 `stage8_k2_rtc_fit_k1_white`；
2. 在 K1 中心构造完整流形和解析 Jacobian；
3. 计算
   \[
   P_g^\perp,\ R,\ B,\ T,\ S_R,\ C_t;
   \]
4. 调用无缓存方向求解；
5. 调用无缓存 direct profile；
6. profile 有效则返回 Raw Tangent；
7. 任一环节失败则返回明确 invalid 状态。

结果：

```text
mode = TANGENT_PROFILE_CORE
selected_source = RAW_TANGENT_CORE
K = 2
fallback_flag 字段不存在
upgrade_flag 字段不存在
```

---

# 22. Raw Tangent Core 公式

\[
P_g^\perp
=
I-\frac{gg^H}{g^Hg},
\]

\[
R=P_g^\perp Z,
\]

\[
B=P_g^\perp J_g,
\]

\[
S_R=\frac1LRR^H,
\]

\[
T=\operatorname{Re}(B^HB),
\]

\[
C_t=\operatorname{Re}(B^HS_RB).
\]

方向：

\[
\boxed{
\widehat u
=
\arg\max_{u\ne0}
\frac{u^TC_tu}{u^TTu}
}
\]

等价于：

\[
\boxed{
C_t\widehat u
=
\mu_{\max}T\widehat u.
}
\]

尺度：

\[
\boxed{
\widehat\rho
=
\arg\min_{\rho\in[\rho_{\min},\rho_{\max}]}
\left\|
P_{G_\rho}^{\perp}Z
\right\|_F^2.
}
\]

输出：

\[
\boxed{
\widehat\xi_{1,2}
=
\widehat c
\mp
\frac{\widehat\rho}{2}\widehat u.
}
\]

---

# 23. Direct profile：禁止 cache 与 fallback

新增：

```text
stage8_k2_rtc_profile_scale_direct
```

从当前 profile 科学逻辑机械复制：

```text
rho_min = 0.001°
scan node count = 33
fminbnd TolX = 1e-4°
fminbnd MaxFunEvals = 80
rank multiplier = 1
```

每个 \(\rho\)：

1. 构造两个端点；
2. 检查局部域；
3. 直接调用：
   ```text
   build_full_sequential_local_manifold
   ```
4. 请求秩 2；
5. 调用：
   ```text
   concentrated_dml_rss
   ```
6. 保存 score/RSS/loglik/rank。

禁止出现：

```text
manifold_provider
t4_manifold_provider
fixed_registered_manifold_provider
fixed_registered_center_adapter
stage8_k2_tcc_*
stage8_k2_tfbc_*
stage8_k2_mc_*
cache_hit_count
cache_miss_count
direct_fallback_count
identity_rejection_count
```

允许保留同一次函数调用内部的：

```text
相同 rho 重复评价去重
```

但它只能是局部临时变量，不得跨 trial、跨函数或写入 persistent cache。

---

# 24. Raw Tangent invalid 状态

至少包括：

```text
K1_NO_VALID_GRID_POINT
K1_CONTINUOUS_INVALID
K1_CENTER_INVALID
CENTER_MANIFOLD_INVALID
TANGENT_METRIC_RANK_DEFICIENT
TANGENT_DIRECTION_NUMERIC_INVALID
TANGENT_PROFILE_NO_FEASIBLE_SCALE
TANGENT_PROFILE_NO_VALID_SCAN_NODE
TANGENT_PROFILE_FINAL_CANDIDATE_INVALID
RAW_TANGENT_CORE_VALID
```

不得把 invalid 自动替换为任何其他算法结果。

---

# 25. Beamspace 经典算法

直接复用已验证科学内核，不重新设计。

## 25.1 Full4D Beamspace CML

方法 ID：

```text
FULL4D_BEAMSPACE_CML_MULTISTART
```

输入：

```text
同一个 Z
```

保持现有有限预算：

```text
完整 210 个注册网格无序双目标粗对
top starts = 6
max sweeps = 12
scan nodes per coordinate = 9
fminbnd TolX = 1e-4°
MaxFunEvals = 80
minimum separation = 0.001°
```

## 25.2 Beamspace MUSIC

方法 ID：

```text
BEAMSPACE_MUSIC_K2
```

输入：

```text
同一个 Z
```

保持：

```text
known K=2
2D grid step = 0.005°
L=1 structural N/A
必须找到两个独立局部峰
不得强制取两个最大格点
```

---

# 26. Element-domain 经典算法

使用同一个 Element-native \(Y_e\)。

方法：

```text
FULL4D_ELEMENT_CML_MULTISTART
ELEMENT_MUSIC_K2
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

要求：

```text
只使用 IID white element noise
不构造 Toeplitz covariance
不读取 Beamspace noise realization
不读取 Tangent 输出作 start
```

适用性：

```text
Element MUSIC:
    L=1 structural N/A

Vertical GFBSS/Root/ESPRIT:
    P2 等俯仰 structural N/A

Root/ESPRIT:
    本轮只有白噪声，不再因 colored noise N/A
```

预期 applicable 计数：

```text
Tangent Core:             1680
Full4D Beamspace CML:     1680
Beamspace MUSIC:          1120
Full4D Element CML:       1680
Element MUSIC:            1120
GFBSS-MUSIC + az CML:     1260
Root-MUSIC + az CML:      1260
LS-ESPRIT + az CML:       1260
```

---

# 27. 方法总数与结果行数

8 种方法：

```text
1. TANGENT_PROFILE_CORE
2. FULL4D_BEAMSPACE_CML_MULTISTART
3. BEAMSPACE_MUSIC_K2
4. FULL4D_ELEMENT_CML_MULTISTART
5. ELEMENT_MUSIC_K2
6. ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
7. ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
8. ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

固定：

\[
1680\times8
=
\boxed{13440\ \text{method rows}}.
\]

即使 N/A 或 invalid，每个 scenario-method 也必须保留一行。

---

# 28. 本轮不包含的方法

不运行：

```text
CORE_LITE(K=2)
CORE_PLUS
TANGENT_PROFILE_SAFE
Vincent-Anchored
Toeplitz/colored-noise variants
automatic K
bootstrap
unknown-K LRT
cache variants
```

K1 单目标中心是 Tangent Core 内部步骤，不作为独立对比方法。

---

# 29. 72-trial 路线的物理删除

在新 Core Commit B 的固定测试通过后，使用 `git rm` 物理删除。

## 29.1 Evidence 删除

必须删除所有匹配：

```text
innovation-mining/30_stage8_k2_tangent_profile_*
innovation-mining/31_stage8_k2_tangent_profile_*
innovation-mining/32_stage8_k2_tangent_profile_*
innovation-mining/33_stage8_k2_classical_baseline_*
innovation-mining/34_stage8_k2_classical_baseline_*
innovation-mining/39_stage8_k2_subspace_baseline_*
innovation-mining/40_stage8_k2_subspace_baseline_*
```

若某个 glob 无匹配：

```text
在 pruning manifest 中记录 ABSENT_AT_BASE；
不得把无关文件补入删除。
```

## 29.2 72-trial prompts 删除

删除：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
013_stage8_k2_tangent_profile_decisive_v1.md

innovation-mining/stage8_execution_prompts/archive/completed/
014_stage8_k2_classical_baseline_comparison_v1.md

innovation-mining/stage8_execution_prompts/archive/completed/
017_stage8_k2_subspace_baseline_comparison_v1.md
```

更新 prompt manifest，删除对应记录，不保留悬空索引。

## 29.3 Tangent 72/Safe 工具删除

在新 Core 已经通过等价与科学测试后，删除整个旧目录：

```text
tools/stage8_k2_tangent_profile/
```

因为新分支唯一活跃 Tangent 已迁移到：

```text
tools/stage8_k2_raw_tangent_core_native_snr/
```

## 29.4 旧 SNR/Safe execution runner 删除

删除：

```text
tools/stage8_k2_snr_validation/
tools/stage8_k2_white_snr_monte_carlo/
tools/stage8_k2_white_snr_classical_baselines/
tools/stage8_k2_white_snr_all_classical_baselines/
```

说明：

- 这些旧 runner 仍由 `main` 与 Git 历史保存；
- 新分支保留其已提交结果文档作为历史 Safe 参考；
- 新分支不再允许执行旧 Safe pipeline。

---

# 30. Cache 的物理删除

删除：

```text
tools/stage8_k2_tangent_canonical_cache/
tools/stage8_k2_tangent_exact_cache_stack/
tools/stage8_k2_tangent_fixed_backbone_cache/
tools/stage8_k2_cylindrical_multicenter_cache/
```

删除：

```text
innovation-mining/50_*
innovation-mining/51_*
innovation-mining/52_*
innovation-mining/53_*
innovation-mining/54_*
innovation-mining/55_*
innovation-mining/56_*
```

删除：

```text
innovation-mining/stage8_execution_prompts/archive/completed/
stage8_k2_cache/
```

更新所有索引和 summary，禁止留下不存在路径的链接。

## 30.1 不应误删的内容

不得删除：

```text
build_full_sequential_local_manifold
concentrated_dml_rss
refine_stage8_k1_continuous
圆柱阵流形
波束矩阵 W_I
白化矩阵 T_I
Full4D CML 科学内核
MUSIC 科学内核
GFBSS/Root/ESPRIT 科学内核
```

## 30.2 Active call graph 要求

新 runner 到 Tangent Core 的可达调用图中，以下符号出现次数必须为 0：

```text
stage8_k2_tcc_
stage8_k2_tfbc_
fixed_registered_manifold_provider
fixed_registered_center_adapter
t4_manifold_provider
manifold_provider
FIXED_GRID_FALLBACK
FINAL_SAFE_SELECTOR
```

共享历史 common 文件中若仍保留不可达的通用 cache 兼容字段，不得为了“全仓 grep 为零”进行危险的无关重写；必须在报告中区分：

```text
ACTIVE_ROUTE_ZERO
DORMANT_SHARED_COMPATIBILITY_NOT_REACHED
```

科学要求是：

```text
新 Core 活跃路径无 cache。
```

---

# 31. 保留的历史证据

保留但重新标记：

```text
innovation-mining/43_* 和 44_*：
LEGACY_SAFE_WHITE_SNR_REFERENCE

innovation-mining/45_* 和 46_*：
LEGACY_SAFE_CLASSICAL_REFERENCE

innovation-mining/47_* 和 48_*：
LEGACY_SAFE_ALL_CLASSICAL_REFERENCE
```

它们不得进入新 Core 主结果的合并表。

不得把旧：

```text
TANGENT_PROFILE_SAFE 100% valid
```

写成新：

```text
TANGENT_PROFILE_CORE 100% valid
```

---

# 32. 固定测试

正式运行前必须全部通过。

## T1：Git/worktree identity

```text
branch/head/origin 正确
main 未修改
worktree 独立
runtime 独立
```

## T2：Beamspace SNR 公式

对全部 Profile、全部 L、全部 SNR 的 fixtures：

```text
nominal target error <= 1e-12 dB
noise sample variance formula 正确
realized SNR 有自然波动
```

## T3：Element SNR 公式

同上。

## T4：旧缩放信号与新缩放噪声的尺度等价

使用相同标准高斯底样本：

\[
Z_{\rm old}=\alpha X+E,
\]

\[
Z_{\rm new}=X+E/\alpha.
\]

验证：

\[
Z_{\rm old}
=
\alpha Z_{\rm new}
\]

相对误差：

```text
<= 1e-12
```

在至少 8 个 fixture 上，Raw Tangent Core：

```text
K1 center
direction axis
rho
angles
valid status
```

在数值容差内一致。

## T5：无 Toeplitz active route

新工具 active code 不得构造或调用 Toeplitz 噪声。

## T6：Beamwidth contract

四个 Profile 的 az/el 3 dB 宽度可重复、有限、正值。

## T7：标签交换不变性

交换 truth 或 estimate 两个端点：

```text
d_max_bw 不变
localization success 不变
resolution success 不变
```

## T8：中心塌缩拒绝

把两个 estimate 都置于真实几何中心。

要求：

```text
对于 P1–P4：
严格 resolution_success = false
```

## T9：真值输入成功

estimate 等于 truth 时：

```text
d_max_bw = 0
localization_success = true
resolution_success = true
```

## T10：K1 white solver

验证：

```text
21 个 coarse points 完整
连续精化不降低 likelihood
输出在注册域内
不读取 truth/profile/SNR
```

## T11：Core 无 fixed K2

静态与运行时验证：

```text
K=2 public fixed fit call count = 0
fallback count field不存在
selector count = 0
```

## T12：Core 无 cache

所有 active Core 查询均由：

```text
build_full_sequential_local_manifold
```

直接完成。

## T13：Profile 使用完整双目标流形

至少验证：

```text
rho scan 每个有效节点 requested_rank = 2
Taylor/Jacobian 不用于最终 score
```

## T14：Baseline direct-call equivalence

新 wrapper 与现有科学内核在代表 fixture 上一致。

## T15：Truth isolation

所有 estimator 输入中：

```text
truth/profile/SNR/beamwidth/success threshold = 0
```

真值只在 fit 结束后进入评价器。

## T16：Checkpoint/resume

```text
原子 tmp→mat
valid checkpoint 跳过
invalid checkpoint 硬停止
```

## T17：Plot-only regeneration

没有 runtime 和 fit 路径时，只依靠提交数据可以重画全部图。

## T18：Scheduled controller

验证 15 分钟 Tick、IgnoreNew、resume、finalize、audit、closeout 和自动注销。

正式运行门：

```text
18/18 PASS
```

---

# 33. 正式 runtime 与 checkpoint

Runtime：

```text
E:\bs_innovation_runtime\
experiment_stage8-k2-raw-tangent-core-native-snr-v1
```

目录：

```text
registry/
beamwidth/
checkpoints/beamspace/
checkpoints/element/
status/
logs/
artifacts/
controller/
backup/
```

每个 scenario 两个 checkpoint：

```text
beamspace/trial_<index>_<id>.mat
element/trial_<index>_<id>.mat
```

Beamspace checkpoint 包含：

```text
registry row
truth/source identity
beam noise seed/hash
clean Xw hash
Z hash
nominal/realized SNR
3 method rows
Raw Tangent diagnostics
success metrics
code identity
```

Element checkpoint 包含：

```text
registry row
truth/source identity
element noise seed/hash
clean Xe hash
Y_element hash
nominal/realized SNR
5 method rows
success metrics
code identity
```

---

# 34. 执行顺序

1. 创建 registry；
2. 测量并冻结四个 Profile 的 3 dB beamwidth；
3. 运行 18 项固定测试；
4. 提交并推送 Tool commit；
5. 启动 Beamspace 1680 scenarios；
6. 完成后启动 Element 1680 scenarios；
7. 合并 13440 method rows；
8. 生成统计、图表和 manifest；
9. fresh MATLAB 会话独立只读审计；
10. closeout commit；
11. 只推送新分支；
12. 注销定时任务。

---

# 35. 长时执行控制

使用：

```text
MATLAB R2022b
-singleCompThread
单 MATLAB 进程
```

不得同时常驻两个大型 Element MUSIC dictionary 或两个 MATLAB worker。

使用每 15 分钟一次的 Windows Scheduled Task：

```text
BSInnovation-Stage8K2-RawTangentCore-NativeSNR-V1
```

控制器每次 Tick：

```text
获取 mutex
读取一次状态
最多启动一次 MATLAB 或执行一次状态迁移
立即退出
```

禁止：

```text
while/sleep 轮询
Codex 持续检查
每几分钟反复输出进度
并发 MATLAB worker
```

状态机：

```text
PREPARED
→ BEAMSPACE_RUNNING
→ ELEMENT_RUNNING
→ READY_TO_FINALIZE
→ FINALIZATION_RUNNING
→ READY_FOR_AUDIT
→ AUDIT_RUNNING
→ READY_FOR_GIT_CLOSEOUT
→ COMPLETE
```

错误进入：

```text
HARD_STOPPED
```

并保留现场，不自动删除或放宽条件。

---

# 36. 输出文件

新增：

```text
innovation-mining/
57_stage8_k2_raw_tangent_core_native_snr_theory_and_protocol.md
57_stage8_k2_raw_tangent_pruning_manifest.csv

58_stage8_k2_raw_tangent_beamwidth_contract.csv
58_stage8_k2_raw_tangent_registry.csv
58_stage8_k2_raw_tangent_domain_snr_trials.csv
58_stage8_k2_raw_tangent_method_results.csv
58_stage8_k2_raw_tangent_core_diagnostics.csv
58_stage8_k2_raw_tangent_rho_trace_representatives.mat

58_stage8_k2_raw_tangent_snr_summary.csv
58_stage8_k2_raw_tangent_profile_summary.csv
58_stage8_k2_raw_tangent_snapshot_summary.csv
58_stage8_k2_raw_tangent_exact_cell_summary.csv
58_stage8_k2_raw_tangent_success_summary.csv
58_stage8_k2_raw_tangent_failure_summary.csv
58_stage8_k2_raw_tangent_native_domain_comparison.csv
58_stage8_k2_raw_tangent_complexity_summary.csv

58_stage8_k2_raw_tangent_plot_data.csv
58_stage8_k2_raw_tangent_plot_manifest.json
58_stage8_k2_raw_tangent_runtime_manifest.json
58_stage8_k2_raw_tangent_core_native_snr_results.md
```

图：

```text
innovation-mining/figures/
58_raw_tangent_valid_rate_vs_beam_snr.png
58_raw_tangent_localization_success_vs_beam_snr.png
58_raw_tangent_resolution_success_vs_beam_snr.png
58_raw_tangent_rmse_vs_beam_snr.png
58_raw_tangent_success_by_profile.png
58_raw_tangent_success_by_L.png
58_beamspace_native_methods_success.png
58_element_native_methods_success.png
58_native_domain_rmse_comparison.png
58_raw_tangent_failure_reasons.png
58_raw_tangent_axis_rho_errors.png
58_raw_tangent_representative_profiles.png
```

---

# 37. Plot-ready 数据合同

`58_stage8_k2_raw_tangent_plot_data.csv` 必须至少包含：

```text
scenario_id
base_realization_index
domain
method_id
profile_id
L
replicate_id

nominal_snr_db
realized_snr_db
signal_average_power
noise_variance
signal_energy
noise_energy

applicable
fit_valid
fit_status

angles_hat_deg
d_max_deg
d_max_bw
tau_trial_bw
localization_success_01bw
resolution_success

joint_RMSE_deg
azimuth_RMSE_deg
elevation_RMSE_deg
center_error_deg
axis_error_deg
rho_true_deg
rho_hat_deg
rho_error_deg
rho_relative_error
separation_vector_error_deg

runtime_sec
score_call_count
SVD_call_count
eig_call_count
```

后续画图不得重新运行算法。

---

# 38. 汇总规则

按以下层级汇总：

```text
SNR overall
SNR × Profile
SNR × L
SNR × Profile × L
method × native domain
```

每组报告：

```text
total
applicable
valid
valid rate
localization success rate
resolution success rate
median/P90 d_max_bw
median/P90 joint RMSE
median/P90 axis error
median/P90 rho error
failure reasons
runtime
```

Exact cell：

```text
N=20
```

只作描述，不宣称稳定尾部置信界。

---

# 39. 性能结果不作为实验有效性门

实验是否有效只看：

```text
代码身份
SNR 公式
trial/seed/hash
truth isolation
row count
checkpoint
artifact hash
scope
```

不得因为：

```text
Raw Tangent 成功率低
某经典算法更好
某 Profile 无稳健区域
```

而判实验 INVALID。

结果必须原样报告。

---

# 40. 描述性工作区

可以报告第一个满足：

```text
Raw Tangent valid rate >= 0.90
且
resolution success rate >= 0.80
```

的 nominal white-SNR 点。

它只称为：

```text
DESCRIPTIVE_RAW_TANGENT_HIGH_RELIABILITY_REGION
```

不得成为在线门限或 selector。

若没有达到：

```text
NO_HIGH_RELIABILITY_REGION_IDENTIFIED
```

也属于有效科学结果。

---

# 41. 文档状态更新

更新：

```text
innovation-mining/00_DOCUMENT_STATUS_INDEX.md
summary/summary.md
summary/tangent_algorithm_full_detailed.md
innovation-mining/stage8_execution_prompts/README.md
```

新分支最终权威定位：

```text
PRIMARY SCIENTIFIC ALGORITHM:
TANGENT_PROFILE_CORE

SNR:
NATIVE WHITENED-BEAMSPACE NOMINAL SNR

NOISE:
IID CIRCULAR COMPLEX GAUSSIAN ONLY

FIXED-K2 FALLBACK:
REMOVED

CACHE:
REMOVED FROM ACTIVE ROUTE

72-TRIAL:
DELETED FROM THIS BRANCH
RETAINED IN MAIN HISTORY

OLD SAFE 1680:
HISTORICAL REFERENCE ONLY

PRODUCTION:
NOT AUTHORIZED
```

---

# 42. 最终 Scope 审计

最终相对：

```text
644fc6e0041e400b6500579bba93d49f45e46990
```

允许：

```text
新增 Raw Tangent Core 工具
新增 57/58 证据
更新 summary/index/prompt manifest
删除 72-trial 路线
删除旧 Safe runner
删除 cache 工具和 50–56 文档
```

必须不变：

```text
main ref
research ref
EI_paper
通用圆柱阵物理流形
通用完整流形 builder 的数学
concentrated_dml_rss 的数学
经典算法科学内核
现有 43–48 结果文件的字节
```

确认：

```text
origin/main == 644fc6e...
origin/experiment/stage8-k2-raw-tangent-core-native-snr-v1 == HEAD
Git clean
untracked = 0
scheduled task = absent
MATLAB/mwpython/coordinator/lock/tmp = 0
```

---

# 43. 最终状态

成功：

```text
STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_COMPLETE
```

并给出：

```text
RAW_TANGENT_HIGH_RELIABILITY_REGION_IDENTIFIED
```

或：

```text
RAW_TANGENT_NO_HIGH_RELIABILITY_REGION_IDENTIFIED
```

无效仅用于：

```text
main/worktree identity 错误
SNR nominal formula 错误
Toeplitz 进入 active route
固定 K2 调用仍存在
cache 进入 active route
beamwidth contract 错误
success metric 不具标签不变性
中心塌缩被误判成功
truth leakage
结果行数不完整
artifact hash 错误
跨域错误使用逐 trial 胜负
```

---

# 44. 最终报告格式

```text
STAGE8_K2_RAW_TANGENT_CORE_NATIVE_SNR_PRUNING_COMPLETE / INVALID

Git:
- source main SHA
- new branch
- worktree path
- runtime path
- design commit
- tool commit
- pruning commit
- result commit
- push
- clean

Pruning:
- 72-trial deleted paths
- Safe runner deleted paths
- cache deleted paths
- retained-in-main confirmation
- active call graph cache count
- active fixed-K2 call count

SNR:
- beamspace formula
- element formula
- nominal target max error
- realized SNR distribution
- Toeplitz count = 0

Beamwidth:
- P1–P4 az/el 3 dB widths
- contract hash

Registry:
- 1680 scenarios
- 240 base realizations
- 20 replicates per exact cell
- 2 native observations per scenario

Methods:
- 3 Beamspace
- 5 Element
- 13440 rows

Raw Tangent:
- valid rate vs SNR
- localization success vs SNR
- resolution success vs SNR
- Profile/L breakdown
- RMSE
- axis/rho
- failure reasons
- first descriptive high-reliability SNR or none

Beamspace native comparison:
- same Z
- valid/success/RMSE
- within-domain pairing

Element native comparison:
- same Y_element
- valid/success/RMSE
- within-domain pairing

Cross-domain:
- scenario matched
- equal nominal native-domain SNR
- no same-observation claim
- no cross-domain per-trial win/loss

Historical evidence:
- 72 removed from branch, retained in main
- 43–48 retained read-only
- Safe not used

Production:
- not modified
- no online threshold
- no fallback
- no cache

Next:
USER_REVIEW
```

完成后停止。不得自动合并回 `main`，不得删除 worktree 或 runtime，等待用户审查。



## Execution Design Record

Preflight passed at main and origin/main `644fc6e0041e400b6500579bba93d49f45e46990`. Research ref is `a7139204d717923cb89d0d629b67f1b3ab7ae94d`. The verified bundle includes main, research and all 13 tags. The independent branch was initially pushed at the source commit.

Implementation boundary: native observation generators feed data-only estimators. Registry, truth, source identities and mechanically measured beamwidths belong to generation/evaluation only. The estimator contract contains numeric solver settings, model and registered domain. Existing classical scientific kernels remain byte-identical; new wrappers construct WHITE-only resources. The K1 refinement shared compatibility fields remain dormant and are never supplied by this route.

Numerical implementation registration: Core divides the observation by its Frobenius norm internally and restores likelihood/RSS/trace values to the input scale. This is a data-only homogeneous transformation. T4 uses the existing inner TolX for center comparison (1e-4 degrees), outer angle-update tolerance for rho and endpoint comparison (1e-3 degrees), and 1e-6 for the sign-invariant direction-vector difference. The matrix scaling identity remains <= 1e-12 relative error. Initial development checks used tighter, unspecified angle tolerances and exposed finite-precision behavior near the lower scale boundary; their logs remain in the new runtime. These explicit tolerances are frozen before any formal scenario executes.

Legacy MUSIC accounting compatibility: its unchanged kernel reads the lengths of two configuration fields for runtime amortization. The new adapter supplies literal zeros, with no scenario SNR or profile identity, and recomputes amortization using the registered 1120 applicable trials. Model input retains only array configuration and omits sim_cfg target fields. Structured applicability enters as booleans, with no profile name or target endpoints.

Commit sequence is A (this design and deletion manifest), B (implementation after 18 fixed gates pass), C (manifest-controlled pruning), D (audited results). No deletion has occurred at Commit A. Historical 43-48 files remain byte-identical and are labeled in indexes, not rewritten. Formal result generation is owned by a single MATLAB R2022b process and a 15-minute Scheduled Task state machine. Failures preserve checkpoints and enter HARD_STOPPED.
