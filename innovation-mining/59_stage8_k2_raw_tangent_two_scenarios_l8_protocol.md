# Raw Tangent Core：两场景、L=8、五方法精简验证执行提示词 V1

> **交给本地 Codex 完整执行。**从已完成的 Raw Tangent 实验分支新建独立分支和 worktree，只改变场景、快拍数和对比方法集合，并删除新分支中的旧四场景实验入口及结果。父分支、main、research 及原 runtime 均不修改。
>
> 本轮不是重新开发 Tangent，也不是改成功率门限。沿用父分支的 Raw Tangent Core、原生域加噪公式、波束宽度归一化评价和已有运行控制器。
>
> **保持每个精确条件 20 次重复。**用户要求“其余不做修改”，所以不得自行增加到 50/100 次，不得增加 L=24，不得增加第三个场景。
>
> 新结果无论是否支持 Tangent，都原样报告。不得改变参数、删掉失败样本或追加新方法，直到 Tangent 获胜为止。

协议 ID：`STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_V1`  
最终完整性状态：`STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_COMPLETE`  
结束状态：`USER_REVIEW / MERGE_BACK_NOT_AUTHORIZED`

---

## 1. 精确起点与本地隔离

### 1.1 Git 锚点

```text
Repository:
makabaka165/bs_innovation

父分支：
experiment/stage8-k2-raw-tangent-core-native-snr-v1

父分支精确 HEAD：
f1b13422a91540073ecf417c3b25f5cac552b9d6

main：
644fc6e0041e400b6500579bba93d49f45e46990

research/stage8-k2-vincent-anchored：
a7139204d717923cb89d0d629b67f1b3ab7ae94d

新分支：
experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1

原 main 工作树：
E:\bs_innovation

父实验工作树：
E:\bs_innovation_worktrees\raw-tangent

新工作树：
E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8

新 runtime：
E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1

新 Windows 定时任务：
BSInnovation-Stage8K2-RawTangent-TwoScenarios-L8-V1
```

### 1.2 创建方式

用 `git worktree add -b` 从父提交创建，不用文件系统复制 `.git`，不切换或重置父工作树：

```powershell
$Repo = 'E:\bs_innovation'
$ParentBranch = 'experiment/stage8-k2-raw-tangent-core-native-snr-v1'
$Base = 'f1b13422a91540073ecf417c3b25f5cac552b9d6'
$NewBranch = 'experiment/stage8-k2-raw-tangent-two-scenarios-l8-v1'
$NewWorktree = 'E:\bs_innovation_worktrees\raw-tangent-two-scenarios-l8'
$NewRuntime = 'E:\bs_innovation_runtime\experiment_stage8-k2-raw-tangent-two-scenarios-l8-v1'

git -C $Repo fetch origin --prune --tags
if ($LASTEXITCODE -ne 0) { throw 'Fetch failed.' }
$ActualParent = (git -C $Repo rev-parse "origin/$ParentBranch").Trim()
if ($LASTEXITCODE -ne 0 -or $ActualParent -ne $Base) {
    throw "Parent differs from the specified source: $ActualParent"
}

git -C $Repo worktree list --porcelain
# 先确认新分支、新 worktree 和新 runtime 不存在，再创建。
git -C $Repo worktree add -b $NewBranch $NewWorktree $Base
if ($LASTEXITCODE -ne 0) { throw 'Worktree creation failed.' }
```

同名分支或目录若已存在，不得覆盖、删除或自动改用另一个起点。只有确认它确实属于本协议的同一次执行，才按现有状态继续；身份不同则报告冲突并停止写入。

父分支已经是备份，不另建大体积 bundle，不复制旧 runtime，不将旧 checkpoint 搬到新 runtime，不修改旧 checkpoint 的身份以复用。

本轮只推送新分支。禁止 merge、rebase、force-push、删除旧分支、自动集成到 main。GitHub 用于读取定位和正常 fetch/push；所有源码修改和 MATLAB 运算在新本地 worktree 内完成。

---

## 2. 科学变更边界

本轮只允许以下实验变化：

1. 原 P1–P4 改为下述 `SC_A`、`SC_B`。
2. 快拍集合由 `[1 4 8]` 改为 `8`。
3. 八种方法缩减为五种。
4. 为适配两场景、五方法，修改 registry、分派、计数、输出、绘图、scope 和控制器身份。
5. 删除本分支的旧四场景入口、旧 57/58 实验输出以及被剔除方法的独占实现与测试；保留五种方法必需的共享代码。

**以下内容不能改：**

- 圆柱阵物理模型、当前工作子阵、15 通道 `PRIMARY_RECT_E14_A31`、WHITE measurement context；
- 原生域 SNR 定义、独立圆对称复高斯噪声生成、信号固定而噪声缩放；
- 原始干净源矩阵的构造规律，包括按 source seed 生成的相关相位；
- K1 中心估计器、Raw Core 的观测范数归一化及 RSS/loglik 尺度恢复；
- 投影 Jacobian、方向广义特征求解、对称端点、一维完整流形 profile；
- 所有保留方法的优化预算、rank 规则、MUSIC 峰值规则、Root-MUSIC 选根规则；
- 3 dB 宽度测量方法、`d_max` 定义、定位与严格分辨成功判据；
- SNR 数字网格 `[-6 0 6 10 14 18 22]`、每格重复数 `20`；
- 单 CPI、同一距离–多普勒单元、known K=2、局部角域；
- 无 fixed-K2 fallback、无跨 trial 流形 cache、无 Toeplitz 噪声；
- 新旧结果不得混用，正式结果不得用于调参。

“其余不改”不要求继续保留错误的旧计数、旧输出前缀或旧任务名。这些执行元数据必须随新实验同步更新。

---

## 3. 两个新场景：精确参数

两个场景使用相同几何，仅改变源功率比和相关幅度。

| 字段 | SC_A | SC_B |
|---|---:|---:|
| 名称 | 等功率、非相关近双目标 | 中等功率差、部分相关近双目标 |
| center az / deg | 8.0 | 8.0 |
| center el / deg | 10.0 | 10.0 |
| separation rho / deg | 0.45 | 0.45 |
| separation-axis angle / deg | 30 | 30 |
| secondary power / dB | 0 | -3 |
| source correlation magnitude | 0 | 0.7 |
| L | 8 | 8 |
| replicates per SNR | 20 | 20 |

建议在原 `stage8_k2_rtc_constants.m` 中改为：

```matlab
c.profile_ids = ["SC_A"; "SC_B"];
c.profile_values = [ ...
    8.0 10.0 0.45 30  0 0.0; ...
    8.0 10.0 0.45 30 -3 0.7];
c.snapshot_counts = 8;
c.snr_db_values = [-6 0 6 10 14 18 22];
c.replicates = 20;
```

源构造仍由父分支 `stage8_k2_rtc_build_source` 及其已有依赖实现。`0.7` 是相关系数幅度，不得擅自把原随机相关相位改为固定同相，不得替换成另一种随机波形生成器。

### 3.1 真值端点

$$
\mathbf u_{\rm true}=\begin{bmatrix}\cos30^\circ\\\sin30^\circ\end{bmatrix},\qquad
\boldsymbol\xi_{1,2}=\begin{bmatrix}8\\10\end{bmatrix}
\mp\frac{0.45}{2}\mathbf u_{\rm true}.
$$

两个场景的端点相同，约为：

```text
目标 1：[7.8051442841485°,  9.8875°]
目标 2：[8.1948557158515°, 10.1125°]
```

它们都在原连续域内：

```text
azimuth：[7.4°, 8.6°]
elevation：[9.8°, 10.2°]
```

所以不得扩大搜索域。原 7×3 的 21 点粗搜索网格也保持不变。真值位于网格之间是正常 off-grid 场景，不能把真值加入搜索字典或用它初始化估计器。

两个场景的真实俯仰差为 `0.225°`，Root-MUSIC 的“两个俯仰不同”结构条件成立。此判断是预先给定的场景适用性，不是向拟合器输入真实俯仰。

### 3.2 对新实验的正确说明

这是在已看到父实验结果后设计的、更清楚的代表性场景验证。不得称为从未查看过结果的盲 holdout，也不得声称 SC_B 单独隔离了功率或相关性的因果作用：SC_B 同时改变了这两个源参数。

不预先保证 Tangent 更好。不能因 Full4D 或 Root-MUSIC 更好而再改场景。

---

## 4. 保留五种方法，物理删除其余独占路线

### 4.1 主比较：同一个白化波束观测 Z

```text
TANGENT_PROFILE_CORE
FULL4D_BEAMSPACE_CML_MULTISTART
BEAMSPACE_MUSIC_K2
```

### 4.2 参考比较：同一个阵元观测 Y_e

```text
FULL4D_ELEMENT_CML_MULTISTART
ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML
```

选择的 FBSS 方法是 **FBSS Root-MUSIC + 条件方位 CML**，不是另造一种 FBSS 算法，也不是保留 GFBSS-MUSIC 的谱搜索。

方法表建议：

```matlab
c.method_ids = [ ...
    "TANGENT_PROFILE_CORE"; ...
    "FULL4D_BEAMSPACE_CML_MULTISTART"; ...
    "BEAMSPACE_MUSIC_K2"; ...
    "FULL4D_ELEMENT_CML_MULTISTART"; ...
    "ELEMENT_VERTICAL_FBSS_ROOT_MUSIC_AZ_CML"];
c.beamspace_method_ids = c.method_ids(1:3);
c.element_method_ids = c.method_ids(4:5);
```

本轮五种方法在两个场景中都**结构适用**。某次谱只有一个峰、根无效或无可行 rho 属于算法无效，不得改成 structural N/A 来缩小分母。

### 4.3 剔除方法

新分支不再运行或展示：

```text
ELEMENT_MUSIC_K2
ELEMENT_VERTICAL_GFBSS_MUSIC_AZ_CML
ELEMENT_VERTICAL_FBSS_LS_ESPRIT_AZ_CML
```

删除它们在当前 runner 的分支、结果占位行、专属绘图、独占单测，以及确认无共享依赖的独占实现。至少核对并删除：

```text
tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_gfbss_music.m
tools/stage8_k2_subspace_baselines/matlab/stage8_k2_sb_ls_esprit.m
```

只调用这些退役方法的旧 runner、旧 tests 和旧适用性配置，也应移除。不能留下指向已删除函数的可执行入口。

**不能整目录删除 `stage8_k2_subspace_baselines` 或 `stage8_k2_classical_baselines`。**必须保留 Root-MUSIC/Full4D/Beamspace MUSIC 的共享依赖，尤其：

```text
stage8_k2_sb_vertical_covariance
stage8_k2_sb_fbss_covariance
stage8_k2_sb_root_music
stage8_k2_sb_conditional_az_cml
stage8_k2_cb_full4d_cml
stage8_k2_cb_music
stage8_k2_cb_peak_picker
完整流形、阵元流形与集中 DML 内核
```

`stage8_k2_cb_music.m` 是 Beamspace/Element 共用内核。为保持保留方法的科学实现不变，可以保留它内部不可达的通用 Element 兼容分支；但必须删除新实验的 Element MUSIC 调用、资源准备和结果行。这不是继续保留 Element MUSIC 作为实验方法。不要为了全仓关键字为零而破坏共享函数。

### 4.4 实际 Element wrapper 的改法

父分支 `stage8_k2_rtc_fit_element_methods.m` 当前返回五项，使用三路 switch 分别运行 GFBSS/Root/ESPRIT。本轮改成返回两项，显式调用：

```text
1. Full4D Element CML
2. vertical covariance → FBSS covariance → Root-MUSIC
   → 仅俯仰有效时运行 conditional azimuth CML
```

从旧 `case 2` 机械提取 Root 路径。保持 `whitening = I`、垂直/平滑公式、选根、条件方位搜索和计数规则不变。保留 Root 的中间诊断，不再分配 GFBSS/ESPRIT 占位。

不再根据 `profile_id ~= "P2"` 分派。本轮 Root 对两个场景都适用，可由运行器传入 `true`；真值、profile 名称和成功门限仍不进入估计器。

---

## 5. 实验总数与随机样本：固定，不自动扩大

保持每格 20 次：

$$
N_{\rm scenario}=7\times1\times2\times20=280,
\qquad N_{\rm base}=1\times2\times20=40.
$$

```text
场景实现数：280
每个 SNR：40（SC_A 20 + SC_B 20）
基础 realization：40
每个场景两种原生域观测：共 560
Beamspace checkpoints：280
Element checkpoints：280
总 checkpoints：560
Beamspace method rows：280×3=840
Element method rows：280×2=560
总 method rows：1400
Raw Tangent diagnostics：280
每种方法 applicable：280
replicate=1 的代表性 Tangent traces：7×2=14
```

计数由场景和方法表推导，不继续多处写死，也不构建额外实验配置框架。

### 5.1 保持随机数设计

保留父分支的 seed 基数与源/噪声独立关系：

```text
source_seed_base        = 580100000
beam_noise_seed_base    = 580200000
element_noise_seed_base = 580300000
```

新 base index：`base = (profile_index-1)*20 + replicate_id`，范围 1–40。

七个 SNR 点共享同一 base 的源矩阵和各域标准噪声底样本，只改变噪声方差；不同 base 按现有 seed 规则独立生成。保留生成器实现，不额外设置随机相位或波形规则。

新 scenario ID 使用独立前缀，例如：

```text
RTC2L8_S01_B001
```

使用 `SC_A`、`SC_B`，不把原 `P1`、`P2` ID 改名后冒充同一批 trial。

**新几何和源条件产生新观测，因此所有保留的五种方法必须在新数据上运行。**不得复用旧 58 的角度、统计、checkpoint；不是重跑退役算法，也不是重新验证旧四场景。

---

## 6. SNR 与成功率：原样保留

### 6.1 原生域加噪

由同一干净阵元信号：

$$
X_e=A(\Theta)S,\qquad X_w=T_IW_I^HX_e
$$

生成 Beamspace 观测：

$$
\sigma_w^2=\frac{\|X_w\|_F^2}{15L\gamma},\qquad
N_w=\sqrt{\frac{\sigma_w^2}{2}}(E_R+jE_I),\qquad Z=X_w+N_w.
$$

独立生成 Element 观测：

$$
\sigma_e^2=\frac{\|X_e\|_F^2}{2080L\gamma},\qquad
Y_e=X_e+\sqrt{\frac{\sigma_e^2}{2}}(E_{e,R}+jE_{e,I}).
$$

$\gamma=10^{\mathrm{SNR}_{\rm dB}/10}$，所有标准实高斯底样本的定义与父分支一致。

标称 SNR 控制期望噪声能量，实际 SNR 自然波动。不得用本次随机噪声的范数强制归一化，不得改为阵元噪声投影给 Beamspace，不得从 Z 逆构造阵元观测。

Beamspace 三方法共用同一个 Z；Element 两方法共用同一个 Y_e。跨域仅作同场景、原生域等标称 SNR 参考，不做跨域逐 trial 胜负或同物理观测结论。

### 6.2 宽度归一化指标

仍使用现有 `stage8_k2_rtc_measure_beamwidths` 和 `stage8_k2_rtc_resolution_metrics` 的数学规则。两个场景中心相同，应得到相同的参考宽度，但由现有函数实测，不写死 `2.48/3.55`。

$$
e_{k,\pi}^{(BW)}=
\sqrt{\left(\frac{\widehat\phi_{\pi(k)}-\phi_k}{BW_\phi}\right)^2+
\left(\frac{\widehat\theta_{\pi(k)}-\theta_k}{BW_\theta}\right)^2},
\qquad d_{\max}^{(BW)}=\min_{\pi\in S_2}\max_k e_{k,\pi}^{(BW)}.
$$

$$
\rho_{\rm true}^{(BW)}=
\sqrt{\left(\frac{\phi_2-\phi_1}{BW_\phi}\right)^2+
\left(\frac{\theta_2-\theta_1}{BW_\theta}\right)^2}.
$$

定位成功：

$$
I_{\rm localization}=\mathbb I[\text{fit valid}\land d_{\max}^{(BW)}\le0.1].
$$

严格分辨成功：

$$
I_{\rm resolution}=\mathbb I[\text{fit valid}\land
 d_{\max}^{(BW)}\le\min(0.1,0.4\rho_{\rm true}^{(BW)})].
$$

不改变 `0.1`、`0.4`；不改变标签匹配；RMSE 继续使用最小总平方误差匹配，`d_max` 继续独立使用最小最大误差匹配。数值无效作为成功率失败，误差填 NaN。

本轮每个精确条件的分母都是 20，每 SNR 各方法的总分母都是 40。RMSE 分位数仅对有效结果计算，必须旁列有效数。

---

## 7. 对现有源码逐文件修改，不另起一套算法

继续使用目录：

```text
tools/stage8_k2_raw_tangent_core_native_snr/
```

不复制出第二套 Tangent 数学实现，不批量重命名全部函数。仅更新本分支的实验配置、分派和元数据。

### 7.1 需要逐项修正的硬编码

| 文件/位置 | 父分支现状 | 本轮要求 |
|---|---|---|
| `stage8_k2_rtc_constants.m` | 四场景、三种 L、八方法、旧身份/路径 | 两场景、L=8、五方法、新身份/路径；核心预算不变 |
| `stage8_k2_rtc_build_registry.m` | `for p=1:4`、base 公式里的 `4`、`"P"+p`、1680/240断言 | 使用 profile_ids 与实际数量，280/40，独立场景 ID |
| `stage8_k2_rtc_measure_beamwidths.m` | `cell(4,1)`、`for p=1:4`、`repmat(...,4,1)` | 两行，SC_A/SC_B，测量算法不改 |
| `stage8_k2_rtc_run.m` | `ids(4:8)`、三路 applicability、五个 Element fits | 三个 Beamspace、两个 Element fits；Root 全适用 |
| `stage8_k2_rtc_fit_element_methods.m` | Element MUSIC + GFBSS/Root/ESPRIT | 只保留 Element CML + FBSS Root/条件方位 |
| `stage8_k2_rtc_prepare_resources.m` | 两域均预计算二维 MUSIC 大字典 | 仅 Beamspace 构建原二维字典；Element 不再分配不用的 MUSIC 大字典 |
| `stage8_k2_rtc_music.m` | 预计算耗时除以 1120 | 只调 BEAMSPACE，摊销分母改为本轮实际 applicable 数 280 |
| `stage8_k2_rtc_prepare.m` / `dispatch` | 旧 registry、测试和输出前缀 | 新身份，新 59/60 输出，不读 57/58 旧结果 |
| `stage8_k2_rtc_checkpoint_validate.m` | 可能固定 3/5 方法行及旧 IDs | 由域的方法列表验证 3/2 行，新 registry 身份 |
| `stage8_k2_rtc_finalize.m` | `cell(3360)`、`cell(1680)`、`for 1:1680`、8方法、13440行、旧58文件名 | 从 c/registry推导 560/280/5/1400，写60结果 |
| `stage8_k2_rtc_verify.m` | 旧计数、8方法、旧58路径、旧scope | 新计数/方法/输出；保留只重建数据和重算指标、不重跑估计器 |
| `stage8_k2_rtc_summarize.m` / plotting | 四 Profile、多个 L、退役方法图例 | SC_A/SC_B、仅 L8、五方法；删除空图和旧标签 |
| `stage8_k2_rtc_source_paths.m` | 枚举部分已删文件 | 依据保留的实际文件建立本轮 source identity |
| PowerShell Controller / Scope / Closeout | 旧工作树、分支、任务、57/58前缀、旧base、旧删除清单 | 同步更新到本协议，不再校验旧429文件删除任务 |
| tests/fixtures | P1–P4、L1/4/8、8方法、旧计数 | 清除退役实验fixture；复用仍适用测试，仅更新配置依赖部分 |

**不能只把常量中的 1680 改成 280。**必须检查 registry、checkpoint、finalize、verify、绘图、控制器和最终报告是否一致。也不能对数字 `58`、`4`、`8` 做全仓盲替换：seed 基数、L=8、优化预算等都有不同含义。

### 7.2 保持字节不变的科学核心

相对父提交，原则上以下文件不需要改动，并应保留其字节：

```text
stage8_k2_rtc_fit_core.m
stage8_k2_rtc_fit_k1_white.m
stage8_k2_rtc_projected_direction.m
stage8_k2_rtc_profile_scale_direct.m
stage8_k2_rtc_generate_observation.m
stage8_k2_rtc_generate_beamspace_observation.m
stage8_k2_rtc_generate_element_observation.m
stage8_k2_rtc_build_source.m
stage8_k2_rtc_build_truth.m
stage8_k2_rtc_resolution_metrics.m
```

同样保留 Full4D、Beamspace MUSIC、Root/FBSS/条件方位及物理流形/DML 的科学内核。不要借本轮消除旧代码、改风格或改容差来改写科学核心。

确有非数学元数据耦合时，只做必要适配并在报告写明；不得用“适配”名义改变其搜索策略。

### 7.3 保持预算

- Raw Core：rho 最小值 `0.001°`，粗扫 `33`，TolX `1e-4°`，MaxFunEvals `80`；K1及方向规则保持父实现。
- Full4D：原 `6` 起点、`12` sweeps、每坐标 `9` 节点、原连续容差和停止规则。
- 二维 MUSIC：原 `0.005°` 网格、相同完整白化流形、原局部峰规则。
- FBSS Root：`N_el=32`、`M_s=31`、`P=2`；单位圆/去重门不改。
- 条件方位 CML：原 `7.4:0.02:8.6` 粗轴、`4` 起点、`8` sweeps、`9` 节点和连续精化预算。

本轮允许删除 Element MUSIC 专属的大字典准备，这不改变保留方法的估计公式。MUSIC 字典是该基线的固定谱评价资源，不是重新引入 Tangent 跨 trial 流形 cache。

---

## 8. 旧四场景数据和文档的删除范围

用户已明确允许在新分支删除，不需要另建归档树；父分支保留原样即可。

### 8.1 删除当前旧实验输出

在新 worktree 中列出精确文件后 `git rm`：

```text
innovation-mining/57_stage8_k2_raw_tangent_*
innovation-mining/58_stage8_k2_raw_tangent_*
innovation-mining/figures/58_*.png   # 仅确认属于原 Raw Tangent 实验的文件
```

还要删掉当前旧四场景的专用 prompt 副本、旧 fixtures、过往事故专用恢复脚本/说明，尤其只处理 `d4e2517`、`7c4b95a` 历史事故的入口。不能让新控制器触发旧 incident 恢复任务。

删除前只记录一份轻量清单：

```text
59_stage8_k2_raw_tangent_two_scenarios_deletions.tsv
```

字段只需 `path / reason / preserved_at_parent_commit`。不用再次给几百个历史文件创建多层 hash、bundle 或重复归档。

### 8.2 其他历史证据

`43_*–48_*` 等更早的历史证据不是这次 58 实验，不扩大删除范围；不读入新汇总、不复制进新主结果、不作为当前入口。它们在新索引中降到一个历史链接区或直接链接父分支。

删除“当前实验的旧 P1–P4 配置、结果和入口”，不意味着要在全仓算法理论中消灭所有字符串 `P1`，也不要求删除无关项目内容。不得修改 EI 论文、其他算法、旧 runtime 或 main。

### 8.3 新主入口必须直观

更新本工具 README、`summary/` 当前算法说明、`00_DOCUMENT_STATUS_INDEX.md` 和 active prompt 索引：主页面只介绍 SC_A/SC_B、L8 和五方法，主结果只指向新 60 文件。

不要把新结果仍命名成 `58_*`，不要修改旧 58 表后继续使用其旧 manifest/hash。删除记录链接到父提交即可。

---

## 9. 只做必要的执行前检查

不增加多轮大 pilot、历史 1680 复现、bootstrap、worker 竞争测试或新的数值精度研究。复用父工具已经具备的测试，把与旧配置绑定的部分修正为新配置。

将准备工作合并为四组，全部在正式运行前完成：

### A. 配置和依赖

- 280 行 registry、40 个 base；两场景参数与第3节完全一致；L 全为8。
- 五个 method ID 正确，全部 applicable；真值端点在原域内。
- 新 worktree 中 `which ... -all` 确认核心函数未从父工作树或 main 路径加载。
- 删除独占旧算法后，保留方法无缺失依赖，无调用旧四场景入口。
- 新源码无活动 cache、fixed-K2 fallback、Toeplitz 路径。

### B. SNR 与评价

- 复用父分支 SNR 测试及原有数值容差，不再收紧。
- 两域 source/truth 一致、噪声 seed 分离；七 SNR 共用底样本规则不变。
- 成功指标标签交换不变；真值输入成功；中心双端点塌缩失败。
- 两场景的实测波束宽度有限且为正；不硬编码预期近似值。

### C. 小 smoke 和输出接线

只选 `SC_A/SC_B × SNR{-6,22} × replicate1` 的4个新场景，运行保留五方法检查接线。

无论输出 VALID 或 INVALID，只要符合原算法数值合同都可通过。不能把 smoke 中 Tangent 不分辨当作工具失败。

检查每场景五行、域3/2分派正确、trace可导出。smoke写单独测试目录，不并入正式checkpoint、不据此调参。

### D. 运行控制接线

复用父分支已经修正的 launcher/engine 身份识别与 UTC 时间处理。只做一次隔离任务名的短启动检查，验证新路径、单 worker、状态迁移和完成后续接；不重复旧阶段的多轮 preflight。

正式启动前须已提交并推送工具和删除修改，源码身份冻结。进入正式计算后不得改算法或覆盖已有 checkpoint。

---

## 10. 定时运行、恢复和 Git 收尾

复用现有：

```text
Stage8K2RTCController.ps1
Stage8K2RTCScope.ps1
Stage8K2RTCCloseout.ps1
stage8_k2_rtc_prepare / dispatch / run / finalize / verify
```

更新常量、默认参数和身份检查中的分支、worktree、runtime、task、输出59/60前缀。scope 的对比基准必须改成父提交 `f1b1342...`，不能仍与 `main@644fc6e` 比较并要求旧429个删除文件清单。

保留以下行为：

```text
MATLAB R2022b
-singleCompThread
同一时刻一个计算 worker
Beamspace → Element → Finalize → 独立只读审计 → Git closeout
每15分钟一次 Windows Scheduled Task Tick
mutex / IgnoreNew 防重入
逐域逐scenario checkpoint
```

MATLAB launcher 及其被核实的 engine 子进程属于一个 worker，不能再次按两个进程误判重复。异常时先将一次进程快照（PID/PPID/路径/命令/创建时间）写入 runtime，再记录停止原因；不因只有 PID 不同就盲目终止其他 MATLAB。

定时 Tick 应快速读取一次状态并退出；不在 Tick 或 Codex 会话中循环等候。脚本完成数据计算后自动推进 finalization、独立审计、结果提交、推送和注销任务，不需要 Codex 一直监视。

任务使用父实现的当前用户交互登录方式；不要承诺注销登录后仍会持续计算。离线或未登录期间不保证触发，下次符合运行条件时按有效 checkpoint 继续。

### 10.1 仅新 runtime 可写

```text
registry/prepared.mat
controller/formal_identity.json
checkpoints/beamspace/*
checkpoints/element/*
status/*
logs/*
artifacts/*
```

560个 checkpoint 均绑定本轮 registry/source/code identity。保留父工具的完整性检查；不接受父实验 checkpoint、不重写它们的 code identity、不将结果手工改为新场景。

正式中断仅从有效 checkpoint 恢复；无效最终 checkpoint 或来源不明的 `.tmp` 保留现场并停止写入。开发阶段的非正式工具问题可在正式启动前修好，不引出新的算法验证阶段。

### 10.2 不引入更严格的浮点门

nominal SNR、重算指标等检查继续使用父分支已经接受的容差。以现有模型量级允许正常舍入，不重新出现“CSV 作为内存逐位 oracle”或“白化残差因为重设容差而硬停”。

### 10.3 固定三次提交

建议：

```text
A. docs(stage8-k2): define two-scenario L8 comparison
B. refactor(stage8-k2): retain five methods and replace legacy profiles
C. docs(stage8-k2): record two-scenario L8 results
```

A保存新协议、删除计划和分支说明；B包含实现适配、实际删除及测试记录。B之后冻结正式计算身份。C由审计通过后的closeout生成。

只 stage 本轮明确允许路径，不用 `git add -A` 把其他用户文件带入提交。提交/push失败时保留已生成结果，不重算算法；恢复closeout应识别已存在的结果提交，不能生成重复提交。

结果收尾时归档本轮活动提示词，并将该分支 active README 更新为 `NO_ACTIVE_STAGE8_EXECUTION / NEXT=USER_REVIEW`。这些文档路径应明确加入本轮 closeout 白名单，不能被误判为结果之外的非法改动。

推送目标只允许新分支。最终 source parent / main / research 的 refs 仍保持初始值，不做任何集成。

---

## 11. 本轮数据与图表

### 11.1 新协议和结果前缀

```text
innovation-mining/59_stage8_k2_raw_tangent_two_scenarios_l8_protocol.md
innovation-mining/59_stage8_k2_raw_tangent_two_scenarios_deletions.tsv

innovation-mining/60_stage8_k2_raw_tangent_two_scenarios_*
innovation-mining/figures/60_*
```

别名可以缩短，但整条 prepare/run/finalize/verify/plot/closeout必须一致。不要同时生成两套等价文件名。

### 11.2 必需数据

```text
60_..._registry.csv                        280行
60_..._beamwidth_contract.csv              2行
60_..._domain_snr_trials.csv               560行
60_..._method_results.csv                  1400行
60_..._plot_data.csv                       1400行，可与method_results同内容
60_..._core_diagnostics.csv                280行
60_..._rho_trace_representatives.mat       14个Tangent代表trace
60_..._snr_summary.csv
60_..._scenario_summary.csv
60_..._failure_summary.csv
60_..._within_domain_pairing.csv
60_..._complexity_summary.csv
60_..._plot_manifest.json
60_..._runtime_manifest.json
60_..._results.md
```

保留父分支逐 trial 的角度、SNR、误差、成功标志、失败原因、score/SVD/eig/runtime及观测hash字段。SC_A/SC_B 不能用“easy/hard已验证”这样的结果性名称。

Core diagnostics继续保存K1中心、轴、rho/rho_max、profile节点数、valid/status；Root保留俯仰阶段和条件方位阶段各自valid/status，便于区分失败环节。

不再生成 L1/L4 分层表或 P1–P4、ESPRIT、Element MUSIC 图。所有图只读本轮提交CSV/MAT即可重绘，无需runtime和任何估计器调用。

### 11.3 统计重点

**按场景分别报告**，等权合并两场景的总体表仅为补充：

- valid count/rate；
- localization success count/rate；
- strict resolution success count/rate；
- 有效结果的 joint RMSE median/P90；
- d_max、axis/rho误差和rho下界命中；
- failure stages；
- score/SVD/eig计数和描述性runtime。

同域比较输出成功/失败交叉计数（两者都成功、仅A成功、仅B成功、两者都失败）。RMSE胜负只在共同有效结果上统计，并同时给出共同有效数。沿用父阶段的数值并列约定；不得跨域输出逐trial胜负。

每个格子只有20次，一次结果对应5个百分点。报告必须同时给出 `18/20` 一类计数，不能只写“成功率90%”并外推成总体真实概率。无需增加显著性检验、bootstrap或置信度门禁。

现有 `valid>=0.90 且 strict resolution>=0.80` 可继续作为离线描述规则，分别按SC_A/SC_B注明；不是实验有效性门，也不是在线启用阈值。单个SNR点达标不自动叫连续稳定区间。

### 11.4 图表保持精简

建议每个场景分别生成以下四张图，所有图的L固定写明8：

1. Beamspace三方法的有效率、定位率、分辨率（可分图或清楚分面）；
2. Beamspace三方法的joint RMSE median/P90，附有效样本数；
3. Element两方法的成功率与误差参考，横轴明确为Element-native SNR；
4. Tangent轴/rho与失败构成，或代表rho profile。

允许额外一张计算量汇总图。不为凑固定图数生成重复或空白图。跨域汇总图必须写清“各原生域同标称SNR、不同观测”，不写 same-observation。

---

## 12. 最后复核与结束条件

完成560个checkpoint后，在新MATLAB会话中复核本轮registry、方法集合、SNR、观测hash、已保存端点的成功指标和文件hash，不重跑保留的五个估计器。

同时检查：

```text
SC_A / SC_B only
L=8 only
7 SNR values
20 replicates per exact cell
280 scenarios / 40 bases
560 observations / 560 checkpoints
5 methods / 1400 rows
all methods applicable=280 each
280 Core diagnostics
same observation within each domain
no cross-domain paired wins/losses
no active fixed-K2 fallback / Tangent cache / Toeplitz
no active old P1–P4 runner / retired method dispatch
source parent、main、research unchanged
```

把源码与父提交对照，确认场景与分派修改没有顺带改变保留科学核心。运行期间若出现进程隔离不明或停机异常，记录事实，runtime只能作描述，不能据此宣称受控加速；不要为了补计时重跑全部科学实验。

结果报告不要在审计前写成最终PASS。可先标记 `COMPUTED_PENDING_AUDIT`；审计后由manifest及一段明确的终态说明记录PASS。若修改已hash的报告，必须同步刷新其artifact hash并复核，不能保留互相矛盾的状态。

完整性通过不要求Tangent赢，也不要求出现高可靠区。结果至少清楚回答：

1. SC_A、SC_B分别从哪些SNR开始数值可用、定位成功和严格分辨成功？
2. 同一个Z上，Tangent相对Full4D/MUSIC，成功率与误差是否存在收益、持平或劣势？
3. Tangent评分次数是否更少？计时条件是否足以谈速度？
4. 原生阵元参考方法如何表现？跨域结论的范围是什么？
5. 限定场景下可以支持什么，不可以支持什么？

最终状态：

```text
STAGE8_K2_RAW_TANGENT_TWO_SCENARIOS_L8_COMPLETE
INDEPENDENT_AUDIT = PASS
NEXT = USER_REVIEW
MERGE_BACK = NOT_AUTHORIZED
```

只在数据身份、科学公式、文件完整性或越权改动确实出错时标记实验无效。性能差不是INVALID。

closeout完成结果提交和推送，注销新任务，写入最终controller状态。保留新worktree和runtime，不自动合并、不再追加实验。

---

## 13. 给用户的最终回报格式

```text
完整性终态：
父分支 / 精确起点：
新分支 / worktree / runtime：
设计提交 / 实现剪枝提交 / 正式计算身份 / 结果提交：
Push / Git clean：
父分支、main、research是否未改：

场景：SC_A / SC_B
L：8
重复：20
场景数 / base数 / checkpoint数 / 方法行数：280 / 40 / 560 / 1400
五方法清单：
退役方法及旧57/58结果删除情况：

SC_A：按SNR列出Tangent valid、localization、resolution、median/P90
SC_B：同上
同域Full4D/MUSIC对比：
Element CML / FBSS Root参考：
计算量与runtime可信范围：

成功判据改变：false
SNR公式改变：false
Tangent数学/求解预算改变：false
cache / fixed-K2 fallback / Toeplitz引入：false

独立审计：
图表能否只靠提交数据重绘：
任务/进程/锁终态：
Next：USER_REVIEW
```

---

## 附：本提示词的仓库定位依据

以下是制定本轮修改位置时实际核对的父提交文件。它们用于定位，不是要求重跑旧实验：

- [父分支常量与原方法集合](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/matlab/stage8_k2_rtc_constants.m)
- [registry中的固定四场景循环及计数](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/matlab/stage8_k2_rtc_build_registry.m)
- [原Element五方法分派](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/matlab/stage8_k2_rtc_fit_element_methods.m)
- [逐域runner及方法索引](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/matlab/stage8_k2_rtc_run.m)
- [finalization与旧58输出](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/matlab/stage8_k2_rtc_finalize.m)
- [只读科学复核](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/matlab/stage8_k2_rtc_verify.m)
- [控制器与进程身份逻辑](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/powershell/Stage8K2RTCController.ps1)
- [原scope与旧删除清单绑定](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/powershell/Stage8K2RTCScope.ps1)
- [closeout路径、artifact和Git收尾](https://github.com/makabaka165/bs_innovation/blob/f1b13422a91540073ecf417c3b25f5cac552b9d6/tools/stage8_k2_raw_tangent_core_native_snr/powershell/Stage8K2RTCCloseout.ps1)

**执行边界再次确认：只在新worktree落实本提示词，旧父实验不重算、不改写；新实验完成后等待用户审查。**
