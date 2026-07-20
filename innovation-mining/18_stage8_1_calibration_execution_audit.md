# Stage8.1A2 calibration / primary K1 validation 执行审计合同

> 日期：2026-07-19
> 仓库：`makabaka165/bs_innovation`
> MATLAB：R2022b
> 活跃相位：`phase_factor=1`
> 当前门：`AUTHORIZED_STAGE8_1A2_CODE_ONLY`
> 正式执行：未授权、未执行

## A. 分层边界

Stage8.1A2 只冻结可执行代码、miniature/synthetic tests、checkpoint、writer 和 manifest
合同。Stage8.1B 才允许在后续单独授权下执行 59,700 个 calibration bootstrap
样本和 12,000 个 K1 validation method rows。Stage8.2 必须等待 Stage8.1B
threshold evidence 锁定且 validation gate 通过，并再次单独授权。

### Stage8.1A3 calibration-evidence addendum (2026-07-20)

The code-only calibration boundary now ends at
`run_stage8_1_freeze_threshold_evidence`. It collects and verifies the full
checkpoint set, builds V3 threshold artifacts, and writes only the calibration
registry. The committed-threshold loader recomputes the deterministic manifest
and bundle, requires tracked artifacts in formal mode, restores doubles from
hex, and rejects stale or tampered evidence. No formal cell, bootstrap sample,
or threshold was generated here.

## B. Seed registry

Calibration data seed 为 `2026072100 + c - 1`，`c=1,...,300`。Bootstrap
block start 为 `2126072100 + 1000*(c-1)`，cell 内第 `b` 个 seed 为 block
start 加 `b-1`，`b=1,...,199`。Validation seed base 为 `2226072200`；六个
`L × noise` stratum 各占一个不重叠的 3000-seed block，其中前 1000 个只生成
center/SNR 参数，中间 1000 个只生成阵元噪声，后 1000 个注册 separation
auxiliary seed；separation bootstrap 以 auxiliary seed 加 199 个固定
RandStream substream 生成。两个 measurement configs 对同一 common trial 共享
三种 seed 角色。所有 split 必须在写证据
前重新验证唯一性和互斥性。

## C. Measurement registry

正式 registry 只有四个对象：PRIMARY/FULL_PARENT × WHITE/CORRELATED。每个
对象保存 model key、fixed measurement hash、`W_I/C_I/T_I`、whitening rank、
`Rn_elem`、噪声分解、subset、array/lambda/order 和 factorized V/U metadata。
Calibration cell 的 data hash 必须与按 config+noise 解析的模型 hash 相同。

## D. Bootstrap 与初始化

Formal bootstrap 在阵元域按拟合 K1 或 K2 生成数据，再经过固定 `W_I/T_I`
测量链。输出保留 `Y_element/Zseq_raw/Zseq_white`。每个 sample 从自己的阵元
数据重建 conventional singleton、Stage4 Q1/Q2 recovery 和 Stage5 Kq1/Kq2
初始化；不读取 simulation metadata，不增加第四个 rescue start。

## E. Fit-validity

所有 LRT 入口使用同一门：estimate returned、search converged、effective rank
不小于 K、RSS 和 variance 有限非负、concentrated log-likelihood 有限、fixed
identities 一致。Calibration 不允许删除失败 bootstrap 后继续取分位数；任一
失败令完整 cell 失败，并禁止生成 locked threshold。

## F. Checkpoint 与 aggregate

最小 checkpoint 单位为一个 calibration cell。已有 checkpoint 只有在 source、
plan、model 和 cell-input hash 全匹配时才复用；不匹配立即失败且不得覆盖。
Formal 模式必须显式指定 Git 仓库外 checkpoint root；`FORMAL_SHARD` 只物化
`cell_indices`，cell-input hash 不依赖 shard 顺序或大小。manifest loader 和
collector 必须拒绝缺失、重复、malformed 或 stale checkpoint。
Aggregate 必须看到 300 个 PASS cell、59,700 个唯一 seed 和每配置跨两个 noise
profile 的 150 个 cell，才可各输出一个 `q_global=max(q_cell_0p95)`。

## G. K1 validation

六个 stratum 各生成 1000 个公共 K1 阵元 realization；PRIMARY 和 FULL_PARENT
只改变固定测量投影，形成严格配对的 12,000 行。Validation 只能调用 locked
threshold lookup，且在第一行 trial 前 exact 校验 stable source、Stage8 plan、
calibration plan、measurement registry 和 threshold artifact hash；不能调用
calibration，也不能修改 `q_global`。summary 按 config × overall/stratum 固定
14 行。PRIMARY overall/stratum 的 Wilson 样本数分别为 6000/1000，且只有
PRIMARY 进入授权门；FULL_PARENT 只输出
`SENSITIVITY_ONLY_NOT_USED_FOR_STAGE8_2_AUTHORIZATION` 和 paired discordance。
报告 false
split、false resolved、K2_UNRESOLVED、search/rank failure、decision availability
及 Wilson interval。任何冻结 gate 失败都禁止进入 Stage8.2。

## H. Evidence writer

Artifact registry 固定 calibration/results 的计划、模型、cell、seed、Lambda、
threshold、complexity、provenance、source/evidence manifest、validation trials、
summary、paired sensitivity、keypoints、report 和 runtime diagnostics 路径。
threshold table 显式保存 source/plan/calibration-plan/measurement-registry identity
与 threshold artifact hash，finalize 要求 validation 使用的 threshold-set hash
完全一致。确定性 bundle 排除
runtime、manifest 自身和 checkpoint 临时文件，并以逐文件 SHA-256 生成身份。

## I. Stage8.1B 执行顺序

1. 从干净、已提交的 Stage8.1A2 code identity 启动 calibration。
2. 在 Git 仓库外完成并审计 300 个 cell checkpoint。
3. 聚合两个 config-level threshold 并创建
   `docs(stage8.1): freeze k1 bootstrap thresholds`。
4. 从该干净 threshold evidence commit 重建 frozen plan，完成 provenance preflight，
   再启动 paired K1 validation。
5. Finalize primary/sensitivity evidence，不回写或调整 threshold，并创建
   `docs(stage8.1): validate k1 false-split control`。
6. 停止并报告 gate；Stage8.2 仍需单独授权。

## J. 当前未完成

没有正式 cell、Lambda、threshold、validation row、性能数字或 PNG；没有执行
Stage8.1B/8.2，也没有修改 Stage5/6/7/7.1 冻结证据。本文只定义未来执行和
审计顺序。
