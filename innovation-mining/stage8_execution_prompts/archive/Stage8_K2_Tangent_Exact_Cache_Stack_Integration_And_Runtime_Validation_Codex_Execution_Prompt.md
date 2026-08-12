# Stage8 K2 Tangent Exact Cache Stack Integration & Runtime Validation

> **Codex 完整执行提示词**
>
> 本文档可直接交给执行 AI。除硬停止条件外，执行 AI 不得只输出计划；必须完成预检、实现、验证、证据归档、提交和非 force-push 推送。
>
> 本阶段是受控的 **exact cache-only experimental integration study**。它不是算法重构，不是 G-only production replacement，不是 Level-B，不是插值/近邻阶段，也不是 deployment。

---

# 0. 执行身份、分支与不可变锚点

## 0.1 Repository

```text
Repository:
makabaka165/bs_innovation

Local repository:
E:\bs_innovation
```

## 0.2 当前工作分支

本阶段不创建新分支，继续在：

```text
experiment/stage8-k2-tangent-canonical-cache-v1
```

上 fast-forward 推进。

禁止：

```text
new branch
merge
rebase
amend
history rewrite
force-push
push to main
push to experiment/stage8-k2-tangent
```

## 0.3 历史锚点

永久冻结以下语义：

```text
LEVEL_A_CLOSURE_COMMIT
cf35e37a74366a8d9829de3a1f8b740a788bade1

PLACEMENT_AUDIT_CODE_COMMIT
354109c80203c7100f255aaf54aef4150b436ea6

PLACEMENT_AUDIT_EVIDENCE_COMMIT
efd040c7c9936eb40b08e9eef60f57b80dbfda65

EXACT_CACHE_STACK_BASELINE_COMMIT
efd040c7c9936eb40b08e9eef60f57b80dbfda65
```

语义分别是：

- `LEVEL_A_CLOSURE_COMMIT`：canonical cache Level-A 数值闭包；
- `PLACEMENT_AUDIT_CODE_COMMIT`：placement instrumentation 和 audit code；
- `PLACEMENT_AUDIT_EVIDENCE_COMMIT`：52_* placement/runtime/economics 证据闭包；
- `EXACT_CACHE_STACK_BASELINE_COMMIT`：本阶段 CACHE_OFF 的算法和 runtime 基线。

不得用未来 HEAD 替换上述历史语义。

## 0.4 首次执行起点与 resume 身份

固定 runtime identity 文件：

```text
E:\bs_innovation_runtime\stage8_k2_tangent_exact_cache_stack_v1\run_identity.json
E:\bs_innovation_runtime\stage8_k2_tangent_exact_cache_stack_v1\stage_commit_ledger.json
```

### Fresh run：`run_identity.json` 不存在

在任何 source/test edit 前定义并原子写入：

```text
INITIAL_EXECUTION_START_COMMIT = git rev-parse HEAD
EXECUTION_START_COMMIT = INITIAL_EXECUTION_START_COMMIT  # evidence 兼容字段
EXECUTION_PROMPT_HASH = SHA-256 of exact prompt bytes
CURRENT_RESUME_HEAD = INITIAL_EXECUTION_START_COMMIT
RUN_ID = SHA-256(stage_id | initial commit | prompt hash | registry hash)
```

要求：

```text
EXACT_CACHE_STACK_BASELINE_COMMIT is ancestor of INITIAL_EXECUTION_START_COMMIT
```

若两者不同，`efd040c..INITIAL_EXECUTION_START_COMMIT` 只允许本阶段 prompt/
archive/docs 变更。任何先于 fresh run 存在的 source、test、runtime code 或
evidence 改动触发：

```text
UNEXPECTED_POST_BASELINE_CODE_CHANGE_STOP
```

### Resume：`run_identity.json` 已存在

不得把当前 HEAD 重新命名为 execution start。必须读取并保持首次写入的：

```text
RUN_ID
INITIAL_EXECUTION_START_COMMIT
EXECUTION_PROMPT_HASH
```

定义 `CURRENT_RESUME_HEAD = git rev-parse HEAD`，并要求：

1. initial start 是 current resume HEAD 的 ancestor；
2. initial start 之后的每个 commit 都存在于 `stage_commit_ledger.json`；
3. ledger 对每个 commit 固定 parent/tree/phase/exact changed paths/result hashes；
4. changed paths 只落在第 29 节允许范围和 Pass 0 冻结的 hook allowlist；
5. integration/timing 已开始时，checkpoint 中的 integration commit、cache
   code hash、timing protocol hash 与当前 ledger 完全匹配；
6. prompt bytes/hash、baseline anchors、registry hash 均未改变。

任一不满足触发 `RESUME_PROVENANCE_MISMATCH_STOP`。本阶段自己已记录且
验证通过的 code/test/evidence commit 是合法 resume 历史，不得被误判为
`UNEXPECTED_POST_BASELINE_CODE_CHANGE_STOP`。ledger 每次只在 commit 成功后
原子 append；不得重写既有 entry。

## 0.5 本阶段执行身份

```text
STAGE_ID
STAGE8_K2_TANGENT_EXACT_CACHE_STACK_V1

STAGE_ROLE
EXACT_CACHE_ONLY_EXPERIMENTAL_INTEGRATION_AND_MEASURED_RUNTIME_VALIDATION

BASELINE_ALGORITHM
TANGENT_PROFILE_SAFE

DEFAULT_PRODUCTION_CACHE_SETTING
CACHE_OFF
```

本阶段只允许在实验 runner 中显式启用 cache。即使最终所有 hard gates
通过，也不得在本阶段把 production default 改为 CACHE_ON；robust-positive
结果只能进入 productionization study。

## 0.6 执行资源上限

```text
max concurrent child processes = 4
max total active processes including coordinator = 5
max AI/tool request rate = 14 requests per minute
formal MATLAB timing processes = 1
parallel pool = disabled
singleCompThread = true
```

实现/只读审计可在上述上限内并行；所有 screening/final/lifecycle timing
必须串行，且不得让后台测试或另一个 MATLAB job 与其重叠。每个 formal
timing pass 前记录活跃相关进程并证明满足上限。

---

# 1. 本阶段目标与必须回答的问题

本阶段目标是在不修改 G、score、rank、搜索和 Tangent 数学核心的前提
下，以 additive exact cache stack 尽可能获得真实端到端加速，并确定
cache-only 路线的实测上限。

必须回答：

1. 当前冻结算法中哪些函数调用存在 complete-key exact duplicate？
2. 每个 cache layer 的合法 key、scope、lifetime 和依赖是否完整？
3. 既有 21-key dictionary 相对当前 legacy baseline 的真实边际是多少？
4. full-data/context、initialization、helper K1 能否通过 exact memoization
   实现已建模的 structural saving？
5. registered rank、dynamic manifold、score/full-result 是否存在可盈利的
   exact reuse？
6. 每层 isolated、cumulative、cold-build、cold-load、warm 的 measured
   saving 是多少？
7. 最终 stack 的 paired lower bound 是否大于 0？
8. 当前 cache-only 路线是否达到：

```text
< 1%
1% to 2%
2% to 3%
3% to 4%
>= 4%
```

9. 若未达到 4%，限制来自 exposure、lookup/guard、copy/hash、lifecycle、
   memory 还是不可 cache 的 off-grid/score 主体？
10. 是否应保留实验实现、继续生产化，或判定 exact cache-only 路线到达
    上限？

---

# 2. “算法和代码不变”的可执行定义

“算法不变”严格定义为：

```text
same mathematical functions
same inputs
same registered/off-grid candidate set
same score values under the frozen numeric contract
same rank/tie/best-index rules
same accepted-update sequence
same trajectory
same selected start
same nested decision
same final selector
same truth isolation
```

“核心代码不变”严格定义为：

- 不改 G/derivative 公式和生产 builder 的函数体；
- 不改 DML score、RSS、projector、SVD/rank 数学实现；
- 不改 initialization 候选、grid、search budget 或顺序；
- 不改 continuous refinement、T4 direction/profile；
- 不改 tolerance、tie rule、rank multiplier；
- 不改 final safe selector；
- 不改 frozen trials、measurement identities、seeds、SNR/profile；
- 不使用 MEX/GPU/parallel 作为本阶段收益来源。

允许：

- 新增 cache wrapper/provider/session/registry；
- 新增 feature flags；
- 新增 exposure、purity、correctness 和 timing runner；
- 在已有 orchestrator/provider seam 上增加最小 dependency-injection hook；
- 在 exact hit 时跳过冻结函数并返回已认证或由该冻结函数生成的缓存
  输出；
- cache miss 调用原冻结函数并记录/插入结果。

关键语义：

> 如果 exact hit 仍强制执行原函数，cache 不可能产生计算加速。因此
> “核心不变”不等于“hit 也必须执行原函数”；它等于 hit 返回与原函数
> 语义等价的完整输出，miss 始终走原路径。

禁止：

```text
rounded key
quantized key
nearest-neighbor hit
interpolation
approximate score reuse
partial dependency key
truth-derived key
cross-observation data-result reuse
cross-identity measurement-result reuse
path shadowing
global/persistent monkey patch
silent fallback to a different algorithm
```

---

# 3. 两类 cache 输出必须分开

## 3.1 Certified canonical dictionary

```text
CERTIFIED_CANONICAL_DICTIONARY_OUTPUT
```

21-key dictionary 的 G 输出已按 Level-A tolerance 认证，并且离散路径在
72 trials 中 exact match；它不宣称与 legacy 浮点输出 bitwise identical。

继续使用冻结合同：

```text
exact key error                <= 1e-11 deg
legacy vs direct G-only rel G  <= 1e-12
legacy vs direct G-only abs G  <= 1e-12 * scale
direct vs dictionary rel G     <= 1e-10
singular-value error           <= 1e-10 * scale
rank-threshold difference      <= 1e-12
rank decision                  exact match
```

## 3.2 Memoized original output

```text
EXACT_MEMOIZED_ORIGINAL_OUTPUT
```

full-data/context、initialization、helper、rank、score/full-result cache 的
miss 必须调用冻结原函数，并存储完整语义输出。hit 返回该原始输出。

除明确排除的 runtime/cache diagnostic 字段外，要求：

```text
isequaln(cached_semantic_output, original_semantic_output) == true
```

若输出包含 mutable handle、隐式 session 状态、RNG/state side effect，且
无法证明或复现完整语义，则该函数不允许进入 result cache。

对 C2-C7，每个 producer 在 Pass 0/A 必须生成并冻结
`E:\bs_innovation_runtime\stage8_k2_tangent_exact_cache_stack_v1\freeze\semantic_output_projection.csv`，
并将聚合 rows 写入 `53_*_freeze.csv`。至少包含：

```text
cache_layer
producer_function_path/hash
requested_output_index/name
included_field_path
excluded_field_path
exclusion_reason
caller_read_evidence
projection_hash
```

默认所有输出/字段都属于 semantic output。只有明确的 wall-clock
`runtime_sec`、cache physical counters、stage timer tokens/raw audit buffers
可在静态 caller-read audit 证明不参与任何决定/返回合同后排除。logical
`score_call_count`、`svd_call_count`、status、rank、threshold、candidate/tie/
trajectory 字段不得排除。不同 layer 不得共用未逐项证明的 projection。
无法冻结完整 projection 时，该 layer 记录
`REJECTED_SEMANTIC_OUTPUT_PROJECTION_INCOMPLETE`。

---

# 4. 基线理论与已有证据

## 4.1 顺序反事实模型

上一轮 evidence 的模型为：

\[
T_0=364.872219\ {\rm s}.
\]

\[
T_S=T_0-\Delta_S,
\qquad
\Delta_S=8.24150815\ {\rm s}=2.258738\%.
\]

\[
T_{SG}=T_S-\Delta_{G\mid S},
\qquad
\Delta_{G\mid S}=5.4201188\ {\rm s}=1.485484\%.
\]

\[
T_{SGC}=T_{SG}-\Delta_{C\mid S,G},
\qquad
\Delta_{C\mid S,G}=2.192184\ {\rm s}=0.600809\%.
\]

其中：

```text
Delta_S       = structural counterfactual
Delta_G|S     = legacy -> direct G-only + rank, after structural
Delta_C|S,G   = direct G-only -> dictionary lookup, after structural and G-only
```

必须冻结：

> `0.600809%` 是完成 G-only 后的条件 cache 增量，不是 cache 相对当前
> legacy baseline 的独立总收益。

## 4.2 Structural 组成

已有 structural point estimate：

```text
full-data duplicate cost      = 0.454790 s
initialization duplicate cost = 3.500453 s
helper-K1 duplicate cost      = 4.286265 s
total                         = 8.241508 s
```

已有 correctness evidence：

```text
K1/K2 full-data and initialization identity = CERTIFIED 72/72
public K1 vs K2 helper-K1 reuse             = CERTIFIED 72/72
```

这些是 integration candidate 的证据，不是已实测 cache saving。

## 4.3 Structural 后 registered exposure

冻结的 registered exposure：

| Identity | Single | Pair |
|---|---:|---:|
| `208ac1cfafa1...` | 1620 | 3780 |
| `e965700fc8d3...` | 1640 | 3980 |
| Total | 3260 | 7760 |

对 identity \(q\)，令 \(n_{q,s}\)、\(n_{q,p}\) 为 structural elimination
后的 registered single/pair counts；\(l\)、\(g\)、\(r\)、\(h\) 分别为
legacy primitive、direct G、rank、certified lookup 的 frozen median unit
cost，则：

\[
C_{q,\rm legacy}=n_{q,s}l_{q,s}+n_{q,p}l_{q,p},
\]

\[
C_{q,G}=n_{q,s}g_{q,s}+n_{q,p}g_{q,p},
\qquad
C_{q,\rm rank}=n_{q,s}r_{q,s}+n_{q,p}r_{q,p},
\]

\[
C_{q,\rm lookup}=n_{q,s}h_{q,s}+n_{q,p}h_{q,p}.
\]

由 `52_*` query audit 和 placement report 的 microbenchmark 表独立复算：

| Identity | Legacy s | Direct G s | Rank s | Lookup s | Legacy-(G+rank) s | G-lookup s |
|---|---:|---:|---:|---:|---:|---:|
| `208ac1cfafa1...` | 3.124521 | 1.842480 | 0.114507 | 0.523449 | 1.167534 | 1.319031 |
| `e965700fc8d3...` | 3.235052 | 1.212776 | 0.066342 | 0.339623 | 1.955934 | 0.873153 |
| Total | 6.359573 | 3.055256 | 0.180849 | 0.863072 | 3.123468 | 2.192184 |

`Legacy-(G+rank)` 才是 registered G-only delta。`Legacy-G=3.304317 s`
忽略了仍需执行的 `0.180849 s` rank，禁止把它当作 G-only saving。

对应 microbenchmark 汇总：

```text
registered legacy primitive total = 6.359573 s
registered direct G total          = 3.055256 s
registered rank total              = 0.180849 s
registered lookup total            = 0.863072 s
registered G-only delta            = 3.123468 s
direct G -> lookup delta            = 2.192184 s
```

恒等式：

\[
6.359573
=
3.123468+3.055256+0.180849.
\]

\[
3.055256-0.863072=2.192184.
\]

## 4.4 Cache-only 的四个不同数值边界

### A. 当前 G-dictionary + structural 模型点

当前 dictionary 只缓存 G；rank 仍执行：

\[
\Delta_{\rm Gdict+S}
=
\Delta_S
+\Delta_{G,\rm registered\mid S}
+\Delta_{C\mid S,G}.
\]

\[
=8.24150815+3.123468+2.192184
=13.55716015\ {\rm s}.
\]

\[
R_{\rm Gdict+S}
=
\frac{13.55716015}{364.872219}
=3.715591\%.
\]

状态：

```text
GROSS_ZERO_INCREMENTAL_C2_C4_CACHE_OVERHEAD_HYPOTHESIS_NOT_MEASURED
```

### B. 新增 registered rank result cache 的零增量 hit-cost hypothesis

若 C5R 叠加于 C1，在 hit 时仍执行现有 G dictionary lookup、但跳过 rank，
令 \(C_{\rm C5R,hit}\) 为 11,020 次 exposure 上新增的 rank-result
lookup/copy 总成本：

\[
\Delta_{\rm C1+C5R+S}
=
13.55716015+0.180849-C_{\rm C5R,hit}
=13.73800915-C_{\rm C5R,hit}\ {\rm s}.
\]

只有在未实现层的增量 hit/copy 成本被理想化为零时：

\[
R_{\rm C1+C5R+S,zero\ incremental\ hit}=3.765156\%.
\]

状态必须写为：

```text
ZERO_INCREMENTAL_C5R_HIT_COST_GROSS_HYPOTHESIS_NOT_EXPECTED_MODEL
```

这比 A 多出的约 `0.049565` 个百分点不是当前 M1 已有收益。C5R admission
不等于其 hit 成本为零；Pass B 必须代入实测 \(C_{\rm C5R,hit}\)。

### C. G dictionary 的 additive known-exposure zero-lookup ceiling

即使 G lookup 变成零成本，rank 仍执行：

\[
R_{\rm Gdict,zero\ lookup+S}
=
\frac{8.24150815+6.359573-0.180849}{364.872219}
=3.952132\%.
\]

### D. Full primitive 的 additive known-exposure zero-hit-cost ceiling

若 C5P 直接缓存完整 legacy primitive 原始输出、在 registered hit 上
supersede C1，并将 full-primitive lookup/copy 成本理想化为零：

\[
R_{\rm primitive,zero\ lookup+S}
=
\frac{8.24150815+6.359573}{364.872219}
=4.001697\%.
\]

必须明确：

- A/B 是 point hypothesis，不是 measured result；
- B 明确是 C5R incremental hit cost 为零的 gross hypothesis；
- C/D 是 `ADDITIVE_KNOWN_EXPOSURE_ZERO_HIT_COST_CEILING`，不是无条件的
  measured-speedup 数学上限，也不是 performance target；
- 在 additive、zero-runtime-interaction exposure model 内，超过 D 需要新发现
  的 exact duplicate exposure；实测超过 D 也可能来自正的
  `CACHE_STACK_RUNTIME_INTERACTION_RESIDUAL` 或 timing uncertainty，不得自动
  解释为新 exposure，更不得称 causal synergy；
- off-grid G-only 的剩余收益不属于当前 21-key dictionary；
- 本阶段禁止把上一轮 `4.345031%` 直接当作 cache-only 目标。

已知 exposure 的可分解 headroom：

```text
C1 lookup -> zero lookup, rank still runs:
    3.952132% - 3.715591% = 0.236541 percentage points

zero-incremental-cost C5R rank result:
    3.765156% - 3.715591% = 0.049565 percentage points

current gross A -> full-primitive zero-hit ceiling:
    4.001697% - 3.715591% = 0.286106 percentage points
```

因此只打磨当前 registered lookup 无法把已知 exposure 提升到显著高于 4%。
在 additive、zero-runtime-interaction model 内，超过 `4.001697%` 只能来自
C6/C7 或其他 Pass A 新发现的 exact duplicate；实际 measured point 超过该值
还可能由 runtime interaction residual 或 timing uncertainty 导致，必须按
第 24.2 节分解，不得预设原因。

## 4.5 已知 lifecycle 成本

仅 M1 已有：

```text
build total          = 0.65622540 s
load total           = 0.00595120 s
validate-once total  = 0.02874685 s
setup total          = 0.02694715 s
known build-inclusive sum = 0.71787060 s  # build+load+validate+setup
```

C2-C7 的 hash/store/copy/memory/lifecycle 未知，禁止沿用 M1 数字。

---

# 5. Exact memoization 一般理论

对 cache layer \(\ell\)，合法生命周期内完整 key 集合为 \(K_\ell\)。
key \(k\) 出现 \(n_k\) 次，冻结原函数成本为 \(c_k\)，miss lookup 成本
为 \(l_k^m\)，insert/store 成本为 \(u_k\)，hit lookup/copy 成本为
\(l_k^h\)。online memo 的固定 session/reset 成本记为
\(B_{\ell,\rm setup}\)；prebuilt artifact 的 build 或 load、validate、setup
合计另记为 \(B_{\ell,X}^{\rm prebuilt}\)，二者不得重复计数。

这里 \(c_k\) 只表示 hit 真正绕过的 frozen producer 成本；OFF/ON 都会执行
的 downstream residual 必须从两边同时消去。例如 C1 hit 后 rank 仍执行，
因此不能把 rank 计入 C1 的 bypassed cost。

无 cache：

\[
C_{\ell,\rm off}
=
\sum_{k\in K_\ell}n_kc_k.
\]

Lazy online memoization：每个 unique key 首次 miss 并由冻结 producer 生成：

\[
C_{\ell,\rm lazy\ on}
=
B_{\ell,\rm setup}
+
\sum_{k\in K_\ell}
\left[
c_k+l_k^m+u_k+(n_k-1)l_k^h
\right].
\]

其净收益：

\[
\Delta_{\ell,\rm lazy}
=
\sum_{k\in K_\ell}
\left[
(n_k-1)(c_k-l_k^h)-l_k^m-u_k
\right]
-B_{\ell,\rm setup}.
\]

定义：

\[
N_\ell=\sum_k n_k,\qquad
U_\ell=|K_\ell|,\qquad
H_\ell=N_\ell-U_\ell.
\]

\[
\rho_\ell=\frac{H_\ell}{N_\ell}.
\]

只报告 hit ratio 不足以证明性能；必须报告 cost-weighted saving。

Lazy online memo 正收益必要条件：

\[
\sum_k(n_k-1)(c_k-l_k^h)
>
\sum_k(l_k^m+u_k)+B_{\ell,\rm setup}.
\]

对 C1 一类 prebuilt exact dictionary，若 workload 中 key 已全部由合法
artifact 覆盖，\(X\in\{\mathrm{COLD\_BUILD},\mathrm{COLD\_LOAD}\}\)：

\[
C_{\ell,\rm on}^{\rm prebuilt}
=
B_{\ell,X}^{\rm prebuilt}+\sum_kn_kl_k^h,
\]

\[
\Delta_{\ell,X}^{\rm prebuilt}
=
\sum_kn_k(c_k-l_k^h)-B_{\ell,X}^{\rm prebuilt}.
\]

WARM prebuilt 口径只在 artifact preparation 明确位于 root timer 外时令该
\(B=0\)。online memoization 的 \(H=N-U\) 与 prebuilt dictionary 的 covered
lookup count 是不同 exposure，CSV 必须分别记录，不得用 \(H/N\) 低估或
冒充 prebuilt hit coverage。

对于 heterogeneous single/pair keys，禁止使用未加权 hit ratio 代入 Amdahl。
定义 cost-weighted repeat exposure：

\[
\rho_\ell^{(c)}
=
\frac{\sum_k(n_k-1)c_k}{\sum_kn_kc_k},
\qquad
\eta_\ell
=
\frac{\sum_k(n_k-1)l_k^h}{\sum_k(n_k-1)c_k}.
\]

该定义只在 \(\sum_k(n_k-1)c_k>0\) 时使用；否则 online reuse exposure 为
零，layer 直接记录 `NO_EXACT_REUSE_EXPOSURE`。

若 \(p_\ell=\sum_kn_kc_k/T_0\)，忽略 miss/store/setup 时：

\[
R_{\ell,\rm gross}
=
p_\ell\rho_\ell^{(c)}(1-\eta_\ell)
=
\frac{\sum_k(n_k-1)(c_k-l_k^h)}{T_0}.
\]

prebuilt dictionary 将上式的 \((n_k-1)\) 替换为 covered call count。最终
net saving 必须使用完整成本公式或累计 mode 实测，不能用这个 gross 式
替代。

若 layer 成本重叠，禁止相加 isolated microbenchmark；只能使用累计
mode 的 telescoping measured delta。

---

# 6. Cache layers、累计 modes 与合法 scope

## 6.1 Required integration layer

### C1 — REGISTERED_G_DICTIONARY

```text
scope:
MEASUREMENT_IDENTITY_SESSION

output class:
CERTIFIED_CANONICAL_DICTIONARY_OUTPUT

coverage:
registered non-derivative G only
```

每 identity 21 keys。允许跨同一 identity 的 36 trials 复用。

C1 是唯一 `REQUIRED_TO_INTEGRATE` layer。其既有 Level-A contract 若无法
通过本阶段 CACHE_OFF/shadow/static qualification，则整个阶段 hard stop。

## 6.2 Required-to-audit、integration-gated layers

### C2 — FULL_DATA_CONTEXT_EXACT

```text
scope:
TRIAL_INVOCATION

output class:
EXACT_MEMOIZED_ORIGINAL_OUTPUT

candidate stages:
K2_FULL_DATA
TAIL_FULL_DATA
shared immutable known-K context components
```

只能复用 complete input key 完全相同的输出。generic context 是否可缓存
必须在 Pass A 证明，不得由名称相似推断。

### C3 — INITIALIZATION_EXACT

```text
scope:
TRIAL_INVOCATION

output class:
EXACT_MEMOIZED_ORIGINAL_OUTPUT

candidate stage:
K2_INITIALIZATION_TOTAL
```

observation-bound，不得跨 trial。

### C4 — HELPER_K1_EXACT

```text
scope:
TRIAL_INVOCATION

output class:
EXACT_MEMOIZED_ORIGINAL_OUTPUT

candidate stage:
K2_HELPER_K1
```

只有 public K1 与 helper K1 complete key 完全相同且完整输出通过 shadow
比较时才允许 hit。

上述 C2-C4 均为：

```text
AUDIT_REQUIRED = true
INTEGRATION_REQUIRES_PASS_A_AND_PASS_B_ADMISSION = true
```

出现 `H=0`、依赖不完整、不可消除 side effect、memory infeasible 或 component
net saving 非正时，必须记录 layer rejection，不得强行实现，也不使整个阶段
失败。

## 6.3 Optional exposure-gated layers

### C5R — REGISTERED_RANK_RESULT_EXACT

叠加于 C1，缓存 frozen rank 的完整输出，不修改 rank 函数；C1 G lookup
仍执行。增量 hit/copy 成本必须实测。

```text
scope = MEASUREMENT_IDENTITY_SESSION
population = PREBUILT_FINITE_DOMAIN
output class = EXACT_MEMOIZED_ORIGINAL_OUTPUT
```

### C5P — REGISTERED_FULL_PRIMITIVE_EXACT

缓存 frozen legacy primitive 的完整原始输出。registered hit 时 C5P 的
dispatch 优先于 C1，因此 C5P 与 C5R 互斥；miss 回落到冻结 legacy path。
它不得返回 canonical G 冒充 original primitive output。

```text
scope = MEASUREMENT_IDENTITY_SESSION
population = PREBUILT_FINITE_DOMAIN
output class = EXACT_MEMOIZED_ORIGINAL_OUTPUT
```

### C6 — DYNAMIC_MANIFOLD_EXACT

只允许 exact IEEE-754 ordered angle tuple hit。本阶段 scope 冻结为
`TRIAL_INVOCATION`，不得跨 trial。Pass A 可另报跨 trial exact duplicate
count 作为未来研究信号，但不得用于本阶段 admission、hit 或 performance。

### C7 — SCORE_OR_FULL_RESULT_EXACT

```text
scope:
TRIAL_INVOCATION

required dependency:
observation hash
complete G or angle key
requested rank
rank multiplier
complete score options
requested output contract
```

不得仅凭 `dml_score_count` 推断 score reuse。必须由 Pass A 的 complete
score key unique/repeat 数据决定。

## 6.4 累计 modes 与 rejected-layer alias

```text
M0 = CACHE_OFF
M1 = M0 + C1
M2 = M1 + C2
M3 = M2 + C3
M4 = M3 + C4
```

Optional screening modes：

```text
M5R = M4 + C5R
M5P = M4 with C5P superseding C1 on registered hits
M5G = M4 + C6
M5S = M4 + C7
M6O = M4 + admitted C6/C7
M6R = M4 + C5R + admitted C6/C7
M6P = M4 with C5P superseding C1 + admitted C6/C7
```

C5R/C5P 必须分别 prototype、
correctness 和 screening；同一 mode 不得同时启用二者。

`M5P` 的 canonical enabled set 严格为
`(enabled(M4) - {C1}) union {C5P}`；该 mode 中 C1 feature flag 为 OFF，
C5P miss 直接调用 frozen legacy primitive。S5P/S6P 使用同一规则。不得把
C1 作为隐藏 fallback 又计入/不计入 layer count。

若 C2、C3 或 C4 被拒绝，对应 cumulative mode 保留确定性 alias：

```text
M2 = M1 when C2 rejected
M3 = unique enabled-layer set after considering C3
M4 = unique enabled-layer set after considering C4
```

alias 的 layer delta 固定为 `0`，状态必须取第 14.3 节封闭
`integration_status` enum 中对应的 `NOT_INTEGRATED_*` 值，不重复
执行相同 enabled-layer set 的 timing。所有 mode 先按 enabled layer IDs 形成
canonical set；相同 set 只测一次，其他 mode row 引用同一 comparison ID。

所有 `M*`、`S*`、`CM*`、`BLOO*`、`OLOO*` 名称都只是
`variant_alias_id`。在 `TIMING_FREEZE` 前必须生成唯一 mode registry；每个
alias 映射到：

```text
candidate_canonical_mode_id = "MODE_" + SHA256(canonical semantic payload)
ordered_enabled_layer_set
enabled_layer_set_hash
scope/population per layer
precedence_hash
fallback_hash
alias_of_canonical_mode_id
representative_alias_id
```

canonical semantic payload 不含 alias 名称，必须包含 C5P supersede-C1 规则。
相同 payload 的 alias 只能共享同一 canonical mode、comparison 和 raw sample，
不得按不同显示名称重复计时。
对 canonical mode (c)，`representative_alias_id(c)` 固定为映射到 (c) 的
所有 alias 中 UTF-8 bytes 字典序最小者；禁止使用生成顺序、section 顺序或
runtime winner row 决定。该规则与完整映射共同计算
`representative_alias_rule_hash`，并写入 mode registry 和 `TIMING_FREEZE`。
若任一 alias 不能唯一解析到 canonical payload/hash，触发
`CANONICAL_MODE_REGISTRY_AMBIGUITY_STOP`。
所有 evidence/decision 中用于标识 algorithm/cache candidate 的 `_MODE` 字段
必须存 canonical mode ID；文中 `M0` 等伪代码先通过 registry 解析，不得把
显示 alias 直接写入该字段。WARM/COLD 或 CACHE_OFF/CACHE_ON 这类运行设置
必须使用后缀 `_SETTING`，不得写入 candidate-mode 字段。

真实边际：

\[
\Delta_1=T(M0)-T(M1),
\]

\[
\Delta_2=T(M1)-T(M2),
\]

\[
\Delta_3=T(M2)-T(M3),
\]

\[
\Delta_4=T(M3)-T(M4).
\]

\[
\Delta_{\rm M4}=T(M0)-T(M4)=\sum_{j=1}^{4}\Delta_j.
\]

Optional layer 使用相同定义。该 telescoping 恒等式允许存在 runtime
interaction；禁止把不同顺序下的 isolated delta 直接相加。

---

# 7. Complete key 与 collision contract

每个 key 至少绑定：

```text
cache_schema_version
baseline_commit
frozen_function_hash
function_role
producer_stage
consumer_stage
fixed_measurement_hash
measurement_config_id
noise_profile_id
observation_bytes_hash             # all data-dependent outputs
local_domain_hash
stage5_locked_hash
complete_options_hash
K
requested_rank
rank_multiplier
ordered_angle_tuple_IEEE754_bytes
pair_ordering
numeric_class
shape
device_backend
MATLAB_release
requested_output_contract
```

完整性条件：

\[
key(x)=key(x')
\Longrightarrow
f(x)=f(x')
\]

在冻结语义输出合同下必须成立。

实现要求：

1. 使用 domain-separated stable hash；
2. hash bucket 中必须保存 canonical full-key payload；
3. hit 时先比 hash，再对 full-key payload 做 exact equality；
4. 任何 hash 相同但 payload 不同都触发 collision hard stop；
5. angles 使用 double 的 IEEE-754 bytes，不使用显示字符串；
6. NaN/Inf 输入按原函数合同处理，不得作为正常 cache key；
7. `+0`/`-0` 默认作为不同 bit key，除非静态证明并冻结统一语义；
8. ordered pair 不得擅自 canonicalize；
9. output request 不同必须是不同 key；
10. key 不得包含 truth、真实角度标签或未来信息。

## 7.1 Canonical full-key payload serialization

不得用 `num2str`、`mat2str`、显示精度、字段遍历偶然顺序或普通 JSON
浮点文本构造 key。若复用现有 stable-hash helper，Pass B 必须证明其满足
以下合同；否则只在本阶段新目录实现：

```text
payload header:
    schema version
    byte-order tag
    domain/function-role tag

numeric/logical value:
    MATLAB class tag
    rank and every dimension as fixed-width integers
    column-major raw bytes without numeric conversion

char/string:
    distinct type tag
    UTF-8 byte length and bytes
    missing string distinct from empty string

cell:
    ordered element count
    recursively length-prefixed element payloads

struct:
    shape
    field names sorted by UTF-8 byte order
    recursively length-prefixed values

unsupported handle/function/object:
    reject candidate; do not stringify
```

每个 component 均用 type tag + fixed-width length prefix，避免拼接歧义。
SHA-256 输入为 domain prefix 与完整 payload bytes；bucket 中保存这些原始
payload bytes，hit 的第二阶段 equality 比较 bytes。serializer version/hash
属于 key schema hash，任何变化使旧 artifact/checkpoint 无效。

---

# 8. Cache session、immutability 与 eviction

禁止 global/persistent cache。

显式 session interface 名称固定为：

```text
stage8_k2_tecs_cache_session
```

它必须：

- 由 runner/orchestrator 显式创建和传递；
- 有明确 identity/trial scope；
- entry insert 后 immutable；
- lookup 返回 value copy 或不可变值；
- 分开 logical call count 与 physical producer call count；
- 支持 deterministic reset；
- 支持 per-layer enable/disable；
- 支持 failure injection；
- 记录 bytes/current peak/entry count/hit/miss/eviction；
- 不影响 RNG；
- 不拥有 truth 数据。

若 output 包含 handle object，必须 deep semantic snapshot 或拒绝缓存。

默认不 eviction，先用 Pass A 证明 bounded memory。若必须 eviction：

- policy 必须预先冻结；
- eviction 只能改变性能，不能改变结果；
- 同一 timing mode/order 下确定性执行；
- 报告 eviction count；
- 不能通过扩大无界 cache 在 frozen 72 trials 上制造不可部署收益。

本研究阶段冻结 aggregate cache memory bound：

```text
CACHE_BYTES_PEAK_LIMIT_PER_MATLAB_PROCESS = 536870912 bytes  # 512 MiB
```

`bytes_peak` 是同一 MATLAB process 内所有 enabled cache layers 的 value、
full-key payload、hash/index metadata、copy buffer 和 eviction metadata 的
同时驻留峰值，不包括 frozen trial fixture 和 MATLAB 自身 runtime。不得只
统计 value payload。超过该值的 candidate 标记 `MEMORY_BOUND_FAIL`，不得
成为 final measurement candidate；这只是实验 admission bound，不是
production memory justification。

所有 `TRIAL_INVOCATION` scope 在 trial 结束后必须回到进入该 trial 前的
entry count/bytes；measurement-identity scope 的 entry count 必须在完成
其有限 key domain 后停止增长。任一未解释的跨 trial 单调增长触发
candidate rejection；若发生在 C1 或已 integration-admitted path，触发
`CACHE_SCOPE_GROWTH_STOP`。

---

# 9. Git 预检

执行以下命令：

```powershell
git rev-parse --show-toplevel
git branch --show-current
git status --porcelain=v1 --untracked-files=all
git remote -v
git fetch origin --prune
git rev-parse HEAD
git rev-parse origin/experiment/stage8-k2-tangent-canonical-cache-v1
git merge-base --is-ancestor efd040c7c9936eb40b08e9eef60f57b80dbfda65 HEAD
git diff --name-status efd040c7c9936eb40b08e9eef60f57b80dbfda65..HEAD
```

必须满足：

```text
repo == E:\bs_innovation
branch == experiment/stage8-k2-tangent-canonical-cache-v1
HEAD == origin/experiment/stage8-k2-tangent-canonical-cache-v1
efd040c is ancestor of HEAD
```

工作树可能包含用户自己的 prompt/archive 整理。执行 AI 必须：

- 读取并记录；
- 不 reset；
- 不 clean；
- 不 stash；
- 不 restore；
- 不覆盖；
- 不把无关文件加入本阶段 commit；
- 只按精确路径 stage 本阶段文件。

若未知修改与本阶段允许的 source/test 路径重叠：

```text
UNEXPECTED_DIRTY_OVERLAP_STOP
```

---

# 10. Freeze manifest 与 core protection

## 10.1 Freeze manifest

Freeze 是 append-only 四阶段，不得用后阶段覆盖前阶段。四阶段严格按
`DESIGN_FREEZE -> COMPONENT_FREEZE -> TIMING_FREEZE ->
FINAL_CANDIDATE_FREEZE` 闭合；每阶段使用独立文件和 hash，后阶段只能引用
前阶段 hash，不得改写前阶段 bytes。

每个 phase record 共同包含 `freeze_phase`、`parent_freeze_hash`、
`created_before_pass` 和 `freeze_payload_hash`。DESIGN 的 parent 固定为
`NONE`；其余 phase 的 parent 必须精确等于前一 phase 的 payload hash。
`freeze_payload_hash` 对不含该字段的 canonical payload bytes 计算，避免
self-reference；写入后重新验证一次。四个 phase 的具体路径和 chain hash
必须进入 Freeze CSV 与 manifest。
任何 phase hash/parent/order 不匹配触发 `FREEZE_CHAIN_MISMATCH_STOP`。

`DESIGN_FREEZE` 在任何实现前生成并保存：

```text
baseline_commit
execution_start_commit
initial_execution_start_commit
current_resume_head_at_design_freeze
run_id
stage_commit_ledger_hash_at_design_freeze
execution_prompt_hash
branch
MATLAB_release
singleCompThread
OS
CPU
numeric_class
trial_registry_hash
measurement_identity_hashes
baseline_snapshot_hash
semantic_output_projection_hash
hook_allowlist_hash
frozen_function_paths
frozen_function_hashes
allowed_hook_paths
allowed_new_paths
key_schema_hash
canonical_mode_construction_rule_hash
C5_precedence_fallback_rule_hash
checkpoint_schema_hash
timing_statistics_design_hash
schedule_generation_algorithm_hash
executable_profile_hash_schema_hash
```

semantic projection 的 producer、完整 output contract 和所有 candidate rows
必须在任何 source/test edit 前完整冻结。Pass A 只能消费该 projection；若
发现依赖或语义字段遗漏，输出 `DESIGN_FREEZE_INCOMPLETE_STOP`；不得原地
append、修改已闭合 `DESIGN_FREEZE` 或继续实现。上述
`current_resume_head_at_design_freeze` 与
`stage_commit_ledger_hash_at_design_freeze` 不得冒充最终当前值。

`COMPONENT_FREEZE` 必须在 Pass B prototype static tests 之后、
任何 component replay sample 之前 append：

```text
prototype_code_hash
component_prototype_commit
pass_a_event_stream_hash
component_schedule_hash
component_protocol_hash
pass_a_layer_disposition_hash
semantic_output_projection_hash
prototype_registry_hash
component_admission_rule_hash
```

`TIMING_FREEZE` 在 integration code commit、static/shadow correctness 之后且
任何 screening sample 之前 append：

```text
integration_code_commit
cache_code_hash
cache_state_reset_implementation_hash
timing_protocol_hash
screening_schedule_hash
screening_comparison_set_hash
formal_warmup_registry_hash
component_result_disposition_hash
component_implementation_hashes_at_replay
component_implementation_hashes_at_integration
canonical_mode_registry_hash
mode_alias_registry_hash
C5_precedence_fallback_hash
candidate_model_registry_hash
representative_alias_rule_hash
```

`FINAL_CANDIDATE_FREEZE` 在 screening 完成后、任何 final WARM/COLD sample
之前 append：

```text
final_measurement_candidate_alias_id
final_measurement_candidate_canonical_mode_id
final_measurement_candidate_hash
frozen_model_id
frozen_model_hash
frozen_model_status
final_warm_schedule_hash
cold_lifecycle_schedule_hash
screening_raw_hash
screening_summary_hash
screening_resolution_and_select_proof_hash
```

若没有 exact matched model，FINAL phase 必须写 canonical sentinel record：
`frozen_model_id=NONE`、`frozen_model_status=NOT_AVAILABLE_NO_MATCHED_FROZEN_MODEL`
及该 sentinel payload 的 hash；不得留空或省略字段。

## 10.2 冻结数学函数

至少 hash 并保护：

```text
build_full_sequential_local_manifold
stage8_k2_tcc_build_g_direct
beamspace_dml_score_svd
concentrated_dml_rss
stage8_k2_tcc_stable_matrix_rank
refine_joint_sequential_dml
stage8_k2_tp_projected_direction
stage8_k2_tp_profile_scale
final safe selector logic
```

执行 AI 必须用 `rg --files` 解析真实路径，不得根据名称创建 shadow
副本。

上述函数的正文 hash 在实现前后必须一致。

## 10.3 允许的最小 hook

Pass 0 必须在任何 source edit 前完成只读 call-graph/seam audit，并原子冻结：

```text
runtime: freeze/allowed_hook_paths.csv
repo aggregate: innovation-mining/53_stage8_k2_tangent_exact_cache_stack_freeze.csv
```

每行至少含 `exact_path`、function/symbol、baseline blob/hash、call-site
signature、allowed change kind、reason、CACHE_OFF statement hash。选择顺序固定：

1. 复用已有 explicit provider/context field；
2. 复用已有 opts/context 传递链；
3. 仅在前两者无法覆盖 admitted layer 时，在最窄的共同 orchestrator
   boundary 增加一个 optional `cache_session/cache_mode` 参数。

在同样文件数下选择路径字典序更小的方案；existing tracked hook files
总数不得超过 6。冻结后不得增删 allowlist row。只有 allowlist 中的
orchestrator/context 文件可增加：

```text
optional cache_session/cache_mode parameter
provider dispatch
logical/physical call counters
cache diagnostics plumbing
```

allowlist 不得包含第 10.2 节 frozen mathematical function body。每次测试/
commit 前自动检查 `git diff --name-only` 和每个 allowlist path 的 diff hunk；
出现未列路径、超出 allowed change kind 的 hunk 或 CACHE_OFF statement hash
变化，输出 `HOOK_ALLOWLIST_VIOLATION_STOP`。

CACHE_OFF 必须走原始语句、原始顺序和原始函数。

禁止为了接 cache 复制整套 estimator 或 Tangent 实现。

若 C2-C7 某 layer 没有 additive seam，记录
`NOT_INTEGRATED_NO_ADDITIVE_SEAM` 并继续其他 layers。只有 C1 也无法通过
additive seam 集成，或执行 AI 已发现必须修改数学函数/复制核心才能完成
任何合法 cache-on mode 时，触发：

```text
NO_ADDITIVE_CACHE_SEAM_STOP
```

---

# 11. 冻结的输入、实现与 evidence 路径

## 11.1 必须只读的既有输入

```text
innovation-mining/52_stage8_k2_tangent_pipeline_cache_placement_audit.md
innovation-mining/52_stage8_k2_tangent_pipeline_cache_placement_manifest.json
innovation-mining/52_stage8_k2_tangent_pipeline_cache_query_audit.csv
innovation-mining/52_stage8_k2_tangent_pipeline_cache_static_certification.csv
innovation-mining/52_stage8_k2_tangent_pipeline_runtime_summary.csv
innovation-mining/52_stage8_k2_tangent_pipeline_cache_economics.csv
tools/stage8_k2_tangent_canonical_cache/matlab/stage8_k2_tcc_build_provider.m
tools/stage8_k2_tangent_canonical_cache/matlab/stage8_k2_tcc_run_economics.m
tools/stage8_k2_tangent_canonical_cache/matlab/stage8_k2_tcc_audit_protocol.m
tools/stage8_k2_tangent_canonical_cache/matlab/stage8_k2_tcc_generate_frozen_trial.m
tools/stage8_k2_tangent_canonical_cache/matlab/stage8_k2_tcc_stable_hash.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_fit_safe.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_build_registry.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_build_context.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_constants.m
tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_evaluate_trial.m
```

执行 AI 必须在 Pass 0 用 `Test-Path` 和 Git blob/hash 验证上述输入。缺失、
内容不属于冻结 ancestry 或 hash 与 manifest 不一致时，不得猜测替代文件，
输出 `REQUIRED_INPUT_MISSING_OR_MISMATCH_STOP`。

## 11.2 固定实现与产物路径

新代码固定在：

```text
tools/stage8_k2_tangent_exact_cache_stack/**
```

runtime root 固定为：

```text
E:\bs_innovation_runtime\stage8_k2_tangent_exact_cache_stack_v1
```

repo 聚合 evidence 固定为：

```text
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_validation.md
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_manifest.json
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_freeze.csv
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_exposure.csv
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_correctness.csv
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_screening.csv
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_runtime_summary.csv
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_lifecycle.csv
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_economics.csv
```

不得修改或重写 51_* / 52_* evidence。

raw MAT、trajectory、per-repeat timing、profiler、checkpoint 和 large cache
artifact 必须留在 runtime root，不提交 Git。

---

# 12. Trial registry 与 truth isolation

冻结唯一 registry 来源：

```text
registry_builder = tools/stage8_k2_tangent_profile/matlab/stage8_k2_tp_build_registry.m
trial_generator = tools/stage8_k2_tangent_canonical_cache/matlab/stage8_k2_tcc_generate_frozen_trial.m
registry_hash_domain = PLACEMENT_AUDIT_REGISTRY
expected_registry_hash = 41af84fcc41fb3c820fd2d635064b03950367a78a36c15a94821c3bb9975f6fe

identity_1 = 208ac1cfafa1a4e0367aa0af9d46f0a362b14343fad97aaa06a7888e73a536fe
identity_2 = e965700fc8d335f6546924993f4e20988aa34b85d5e11899ed0fb3136c3a5c16
```

Pass 0 必须调用上述 builder，以 `stage8_k2_tcc_stable_hash(
'PLACEMENT_AUDIT_REGISTRY', registry)` 重建 hash，并将按
`global_trial_index` 升序的完整 72-row registry 写入 runtime root 的
immutable `frozen_registry.csv`。必须与 `52_*_query_audit.csv` 的 ordered
unique trial IDs、seeds、factor fields 逐项一致，且 hash 精确等于上述值。

继续使用：

```text
72 frozen Tangent trials
2 fixed measurement identities
36 trials per identity
same L/SNR/profile/noise seeds
same trial source
same singleCompThread
```

禁止新增或删除 trial。

## 12.1 Fresh-run immutable CACHE_OFF baseline snapshot

在任何 hook/source/test edit 前，使用 fresh-run HEAD 的冻结代码运行 72
trials，并在 runtime root 原子写入：

```text
baseline/cache_off_semantic_outputs.mat
baseline/cache_off_discrete_trajectory.mat
baseline/cache_off_logical_counts.csv
baseline/baseline_snapshot_manifest.json
```

snapshot 必须含第 13 节列出的所有 continuous/discrete/logical 字段、完整
ordered trial IDs、registry hash、initial execution start commit、producer
hashes 和每个 artifact 的 SHA-256。写完后设置只读并记录
`BASELINE_SNAPSHOT_STATUS=IMMUTABLE_COMPLETE`。

后续 CACHE_OFF qualification 与 cache-on correctness 只和该 snapshot 比较，
不得从 timing CSV 或重新聚合 median 反推 reference。Resume 时 snapshot
必须已存在且 hashes 全部匹配；若 source edit/integration commit 已存在但
snapshot 缺失，输出 `BASELINE_SNAPSHOT_MISSING_ON_RESUME_STOP`，不得用修改
后的 CACHE_OFF 重新生成 reference。

Truth 不得进入：

```text
cache key
cache value
cache admission
cache eviction
cache mode selection
initialization
score
rank
trajectory
final selector
```

每个 output 必须保留：

```text
truth_used_in_fit_flag = false
cache_truth_used_flag = false
cache_admission_truth_used_flag = false
```

---

# 13. Pass 0 — Preflight, Freeze, Seam & CACHE_OFF Qualification

Pass 0 必须完成：

1. Git/remote/worktree preflight；
2. fresh/resume run identity 与 stage commit ledger validation；
3. required inputs、historical anchors、prompt/code hashes validation；
4. exact registry reconstruction 与 identity/cardinality validation；
5. fresh-run immutable CACHE_OFF baseline snapshot；
6. read-only call-graph/seam audit 与 exact hook allowlist；
7. complete semantic output projection；
8. cache session scope、key schema、canonical mode construction 和 C5
   precedence/fallback rule；
9. timing/statistics estimand、所有 seeds、schedule generation algorithm 与
   checkpoint schema design；这里只冻结算法，不得预生成依赖 prototype、
   admitted mode 或 final candidate 的 phase schedule；
10. 所有字段齐备后原子闭合 immutable `DESIGN_FREEZE`；
11. pre-edit CACHE_OFF snapshot self-qualification。

严格顺序为：

```text
read-only prerequisites
-> DESIGN_FREEZE
-> Pass A / Pass B static prototype
-> commit 1 / ledger append / non-force push
-> COMPONENT_FREEZE
-> component replay and admission
-> Pass C / Pass D / post-hook correctness
-> commit 2 / ledger append / non-force push
-> TIMING_FREEZE
-> Pass E screening
-> FINAL_CANDIDATE_FREEZE
-> Pass F / lifecycle / Pass G
```

任何 source/test edit 必须发生在 `DESIGN_FREEZE` 闭合之后；任何 phase sample
必须发生在其对应 freeze 之后。不得提前生成依赖未来 disposition/candidate 的
schedule，也不得用后见数据重写既有 freeze。

CACHE_OFF 必须在 72 trials 中与第 12.1 节 fresh-run immutable baseline
snapshot 比较；该 snapshot 的 producer hashes 必须属于 `efd040c` 未变的
算法路径：

```text
angles
fit_valid
fit_status
selected_source
selected_start
rss
loglik
effective_rank
rank
tie set
best index
accepted update
trajectory
nested pass
final selector
logical score count
logical SVD count
```

除 runtime 和新增 cache diagnostics 外，必须满足原合同。

Pass 0 先做 pre-edit snapshot self-validation；Pass D 完成所有 hook/cache
plumbing 后，必须用 integration code 重新做同一 72-trial CACHE_OFF comparison。
后者才是进入 screening 的 `POST_HOOK_CACHE_OFF_QUALIFICATION`，不得省略。

任何 mismatch：

```text
CACHE_OFF_BASELINE_MISMATCH_STOP
```

Pass 0 未通过不得实现 cache-on timing。

---

# 14. Pass A — Read-Only Exact Reuse Exposure & Purity Audit

Pass A 不得让 cache 影响任何输出或决定。

对 C1-C7 每层记录 complete-key event：

```text
cache_layer
function_role
producer_stage
consumer_stage
legal_scope
fixed_measurement_hash
trial_id
complete_key_hash
full_key_payload_hash
call_index
original_compute_sec
output_bytes
RNG_before_hash
RNG_after_hash
global_state_before_hash
global_state_after_hash
```

按 layer/identity/trial 聚合：

```text
call_count N
unique_key_count U
hit_opportunity_count H = N - U
hit_ratio
cache_population_class = ONLINE_MEMO | PREBUILT_FINITE_DOMAIN
covered_lookup_count                  # prebuilt only
coverage_ratio                        # prebuilt only
cost_weighted_hit_ratio
reuse_distance median/p90/max
original_compute_sec
gross_avoidable_compute_upper_sec
lookup_sec = NaN, NOT_MEASURED_PRE_COMPONENT
store_sec = NaN, NOT_MEASURED_PRE_COMPONENT
copy_sec = NaN, NOT_MEASURED_PRE_COMPONENT
bytes_current
bytes_peak
key_collision_count
truth_leakage_count
```

## 14.1 Purity

对每个 candidate function 的代表 complete key：

1. 保存 RNG/global/persistent 可见状态；
2. 连续调用冻结函数两次；
3. 比较完整语义输出；
4. 比较状态 before/after；
5. 检查输出是否包含 mutable handle；
6. 检查调用方是否修改返回对象。

对 C2-C7，只有满足：

```text
semantic_output_repeatable = true
unmodeled_side_effect = false
complete_dependency_key = true
truth_leakage_count = 0
key_collision_count = 0
```

才允许成为 Pass B prototype candidate。C1 任一项失败是 hard stop；C2-C7
任一项失败只拒绝对应 layer 并记录精确原因，不得误停整个研究。

## 14.2 Pass A audit eligibility，不做 performance admission

C2-C4、C5R、C5P、C6、C7 只有同时满足：

```text
ONLINE_MEMO: H > 0
PREBUILT_FINITE_DOMAIN: covered_lookup_count > 0
purity PASS
key completeness PASS
collision count = 0
truth leakage count = 0
memory bound PASS
```

才进入 Pass B prototype。Pass A 没有实现 component，禁止凭尚不存在的
lookup/store/copy 估计做 performance admission。

无 exposure 是有效结论：

```text
EXPOSURE_STATUS = NO_EXACT_REUSE_EXPOSURE
INTEGRATION_STATUS = NOT_INTEGRATED_NO_EXACT_REUSE_EVIDENCE
```

不得为了提高 hit rate 放宽 key。

## 14.3 Layer disposition 封闭枚举

CSV/JSON 不得生成自由文本状态或动态拼接 `NOT_INTEGRATED_<REASON>`。
三个字段只能分别取以下值：

```text
exposure_status:
    EXACT_REUSE_EXPOSURE_PRESENT
    PREBUILT_COVERAGE_PRESENT
    NO_EXACT_REUSE_EXPOSURE

audit_eligibility_status:
    AUDIT_ELIGIBLE
    AUDIT_REJECTED_NO_EXACT_REUSE_EVIDENCE
    AUDIT_REJECTED_DEPENDENCY_INCOMPLETE
    AUDIT_REJECTED_PURITY_OR_SIDE_EFFECT
    AUDIT_REJECTED_COLLISION
    AUDIT_REJECTED_TRUTH_LEAKAGE
    AUDIT_REJECTED_MEMORY_INFEASIBLE
    AUDIT_REJECTED_NO_ADDITIVE_SEAM

integration_status:
    REQUIRED_C1_PENDING
    PROTOTYPE_PENDING
    NOT_INTEGRATED_NO_EXACT_REUSE_EVIDENCE
    NOT_INTEGRATED_DEPENDENCY_INCOMPLETE
    NOT_INTEGRATED_PURITY_OR_SIDE_EFFECT
    NOT_INTEGRATED_COLLISION
    NOT_INTEGRATED_TRUTH_LEAKAGE
    NOT_INTEGRATED_MEMORY_INFEASIBLE
    NOT_INTEGRATED_NO_ADDITIVE_SEAM
    NOT_INTEGRATED_STATIC_CERTIFICATION_FAILURE
    NOT_INTEGRATED_COMPONENT_NONPOSITIVE
    INTEGRATION_ADMITTED
    INTEGRATED
```

`PREDICTED_NET_NONPOSITIVE_LAYER` 是研究结论标签；对应唯一
`integration_status` 为 `NOT_INTEGRATED_COMPONENT_NONPOSITIVE`。C1 的 hard
failure 直接使用第 28 节 hard stop，不把 C1 伪装成 optional rejection。

---

# 15. Pass B — Cache Components & Static Certification

实现 C1；对通过 Pass A audit eligibility 的 C2-C4/C5R/C5P/C6/C7 实现
独立 prototype。未通过者不得创建空壳 hit path。

必须新增测试：

```text
exact key round-trip
hash collision payload rejection
identity rejection
observation rejection
options mutation rejection
ordered-pair distinction
near-miss rejection
signed-zero behavior
NaN/Inf behavior
wrong numeric class rejection
wrong output contract rejection
miss fallback
producer failure propagation
cache corruption rejection
immutable entry behavior
scope reset
memory accounting
deterministic eviction if enabled
truth isolation
```

C1 继续通过：

```text
42/42 singles
462/462 canonical unordered pairs
882/882 ordered nested assemblies
```

C5R/C5P 必须对相同有限集合分别新增：

```text
C5R cached rank == frozen rank exact
C5R cached threshold == stored original threshold exact
C5P full semantic output isequaln original primitive output
C5P hit bypasses C1 and frozen primitive exactly once
C5R and C5P mutual exclusion
ordered result contract exact
```

C1 static failure 触发 hard stop；C2-C7 prototype static failure 记录
`NOT_INTEGRATED_STATIC_CERTIFICATION_FAILURE` 并拒绝该 layer，不进入 Pass C。

## 15.1 Frozen component replay benchmark

在任何 component warmup 或 measured sample 前，必须先写完并冻结：

```text
runtime: freeze/component_protocol.json
runtime: freeze/component_schedule.csv

singleCompThread = true
timer = external tic/toc around one complete 36-trial identity event stream
component_pair_order_seed = 2026080906
warmup pairs per identity = 5
measured pairs per identity = 30
measured AB/BA per identity = 15/15
A = frozen producer replay OFF
B = exact-cache component prototype replay ON
```

`component_protocol.json` 必须覆盖 prototype code hash、Pass A event-stream
hash、scope/reset/state rule、timer boundary、instrumentation flags、pair sign、
aggregation formula 和 schedule algorithm。measured directions 先构造 15 AB +
15 BA，再按 `SHA256("COMPONENT_PAIR_ORDER" | seed | cache_layer | identity |
repeat_index | nominal_direction)` 的 bytes 字典序排列。5 个 warmup directions 对 identity 1
固定为 `AB,BA,AB,BA,AB`，对 identity 2 固定为
`BA,AB,BA,AB,BA`；warmup row 必须带 `included_in_statistics=false`。
两份文件全部写完后才闭合 `COMPONENT_FREEZE` 并记录各自 hash；任何 sample
产生后不得改 protocol、schedule、prototype code 或 event stream。

Static test 通过的每个 layer，在不运行完整 estimator 的独立 runner 中重放
Pass A 仓库外 raw event stream：

```text
component_warmup_pairs_per_identity = 5       # 不计入统计
component_measured_pairs_per_identity = 30
component_AB_per_identity = 15
component_BA_per_identity = 15
batch = one identity's ordered 36-trial event stream
timer = external tic/toc around the whole batch
```

OFF batch 对每个 event 调冻结 producer；ON batch 从同一 pristine state
按真实 scope 执行 lookup/miss/store/hit/copy。ONLINE_MEMO 在 batch 开始为空，
并在每个 trial 边界按 scope reset；PREBUILT_FINITE_DOMAIN artifact 在 timer
外准备，build/load/validate/setup 另进 lifecycle。pair 两边相邻，input event
bytes、顺序和 requested output 完全相同；不启用 per-call timer/logging。

定义：

\[
d_{\ell,q,r}^{\rm component}
=T_{{\rm OFF},\ell,q,r}-T_{{\rm ON},\ell,q,r},
\qquad
\widehat\Delta_{\ell,q}
=\operatorname{median}_{r=1}^{30}d_{\ell,q,r}^{\rm component}.
\]

C2-C4/C5R/C5P/C6/C7 只有同时满足以下条件才成为
`INTEGRATION_ADMITTED`：

```text
all static/correctness gates PASS
both identity component point >= 0
sum(identity component point) > 0
lookup/store/copy measured, not estimated
memory bound PASS
```

若 correctness/memory gates 已通过但 component performance 条件不满足，
记录 `PREDICTED_NET_NONPOSITIVE_LAYER`，并将 `integration_status` 固定为
`NOT_INTEGRATED_COMPONENT_NONPOSITIVE`；其他 gate failure 使用第 14.3 节唯一
对应状态。被拒绝层不进入 Pass C/D。C1 无论 component point 正负都完成
integration 和 correctness，
但非正时可在 screening/final candidate selection 中输给 M0/其他 set。

所有 admitted component 的原始 30 pairs 留在 runtime root；聚合结果写
exposure/economics CSV。完成 component performance admission 后才允许 Pass C。

---

# 16. Pass C — 72-Trial Shadow Cache Replay

Shadow 模式定义：

1. 正常执行冻结原函数；
2. 同时执行 cache lookup；
3. miss 插入原始输出；
4. hit 取得缓存输出；
5. 仍重新调用原函数作为 oracle；
6. 比较缓存输出与 oracle；
7. production decision 继续使用原始输出。

必须逐 trial 比较：

```text
key
G numeric contract
full-data/context
initialization
helper K1 complete result
rank
score
candidate order
tie set
best index
accepted update
trajectory
selected start
nested pass
fixed result
Tangent result
final selector
logical call counts
```

离散量必须 exact match。

允许不同的 operational diagnostics 只有：

```text
physical producer call count
cache hit/miss count
cache bytes
cache runtime
wall-clock runtime
```

72/72 全通过才允许真正让 hit 跳过原函数。

任一 mismatch：

```text
SHADOW_NUMERIC_OR_DECISION_MISMATCH_STOP
```

不得通过放宽 tolerance、改 key、改 rank/tie/grid 继续。

---

# 17. Pass D — Additive Experimental Integration

按固定顺序集成：

```text
M1: C1
M2: M1 + C2 only if Pass B integration-admitted; otherwise alias M1
M3: canonical predecessor + C3 only if Pass B integration-admitted
M4: canonical predecessor + C4 only if Pass B integration-admitted
optional: C5R/C5P/C6/C7 only after Pass B integration admission
```

C5R/C5P 分别 feature flag 且互斥；C5P hit precedence 高于 C1，miss 才进入
冻结 fallback。相同 enabled-layer set 不创建重复实现或重复 mode。

每层独立 feature flag。

Pass D 必须调用 Pass B 已 benchmark 的同一 component implementation，不得
复制或重写 lookup/store/copy 核心。`TIMING_FREEZE` 对每个 admitted layer
记录 `component_implementation_hash_at_replay` 与
`component_implementation_hash_at_integration`，二者必须相同；hook/dispatch
plumbing 另计入 integration code hash。若 component 核心确需修改，则已有
component samples/admission 全部失效，触发 `COMPONENT_FREEZE_INVALIDATED_STOP`
并停止本 run，不得用旧成本继续 screening。

完成所有 hooks 后先运行 `POST_HOOK_CACHE_OFF_QUALIFICATION`：CACHE_OFF 下
不得创建 session/key/hash、不得执行 provider dispatch，72 trials 必须与
immutable baseline snapshot 全部匹配。通过后才运行任何 cache-on hit-bypass
correctness 或 screening；若后续 source code 改变，qualification 与其后
timing 全部失效。

要求：

- miss 调原函数；
- invalid identity/observation/options 调原函数；
- cache corruption hard fail，不静默返回；
- CACHE_OFF 不创建/lookup/hash cache entry；
- cache-on 不改变 logical evaluation sequence；
- physical producer calls 单独计数；
- production default 仍为 OFF；
- experimental runner 显式传 mode/session。

每个 mode 先运行 72-trial correctness regression。任何 mode correctness
失败则该 mode 不得进入 timing。

---

# 18. Pass E — Screening Timing & Frozen Candidate Selection

## 18.1 Screening variants

至少评估：

```text
S0  = M0
S1  = C1 only
S2  = C2 only, if integration-admitted and independently runnable
S3  = C3 only, if integration-admitted and independently runnable
S4  = C4 only, if integration-admitted and independently runnable
CM1 = M1 cumulative = C1
CM2 = M2 canonical enabled-layer set after C2 disposition
CM3 = M3 canonical enabled-layer set after C3 disposition
CM4 = M4 canonical enabled-layer set after C4 disposition
BLOO-Cj = enabled(CM4) minus Cj, for every enabled and independently removable j
```

对已 admission 的 optional layer：

```text
S5R = M4 + C5R
S5P = M4 with C5P superseding C1 on registered hits
S5G = M4 + C6
S5S = M4 + C7
S6O = M4 + admitted C6/C7
S6R = M4 + C5R + admitted C6/C7
S6P = M4 with C5P superseding C1 + admitted C6/C7
OLOO-O-Cj = leave-one-out of every independently removable layer j in S6O
OLOO-R-Cj = substitution-aware leave-one-out of every independently removable layer j in S6R
OLOO-P-Cj = substitution-aware leave-one-out of every independently removable layer j in S6P
```

只保留 enabled-layer set 唯一且 integration-admitted 的 runnable rows；C5R
与 C5P 互斥。S6O branch 在 C6/C7 至少一层 admitted 时存在；S6R branch
只有在 C5R admitted 时存在，S6P branch 只有在 C5P
admitted 时存在；缺少 branch anchor 时整条 branch 不生成，绝不能通过删除
C5P 同时遗失 C1。对已存在 branch，未 admitted 的 C6/C7 从 canonical set
删除；由此与已有 candidate 重复时引用已有 comparison ID，不重复 timing。

Leave-one-out operator 必须冻结为：

```text
LOO_R(full,j) = enabled(full) - {j}
LOO_O(full,j) = enabled(full) - {j}
LOO_P(full,j) = enabled(full) - {j},                    j in {C2,C3,C4,C6,C7}
LOO_P(full,C5P) = (enabled(full) - {C5P}) union {C1}
```

最后一条恢复被 C5P supersede 的 C1，用来测量 C5P 相对 C1 的 substitution
边际；禁止把它解释成“同时关闭 C5P 和 C1”。若删除 j 会留下依赖不完整的
mode（例如保留 C5R 却删除其必需的 C1），该 LOO row 标为
`NOT_RUNNABLE_DEPENDENCY`，不计时且不得自动删除额外依赖层来伪造 j 的单层
边际。

每个 runnable `BLOO/OLOO` 必须有两类 comparison：

```text
TOTAL_LOO:       M0 vs LOO candidate
DIRECT_LOO:      LOO candidate vs its frozen full branch
```

对 `DIRECT_LOO`，固定 (A=LOO)、(B=full)，正收益定义为：

\[
\Delta_{{\rm LOO},j}
:=
\sum_i\operatorname{median}_r
\left(T_{{\rm LOO}(j),i,r}-T_{{\rm full},i,r}\right).
\]

若 \(\Delta_{{\rm LOO},j}\le0\)，只能结论为该层在该 full branch 中 measured
边际非正。禁止用两个独立 TOTAL point 相减替代 direct paired comparison。
无论结果如何，不事后创建任意 subset；winner 只能从本节在
`TIMING_FREEZE` 前枚举并 hash 的 isolated、cumulative、full 和 LOO sets 中
选择。这样保持搜索有界且不按 runtime 临时扩展模式。

若某 isolated mode 技术上依赖另一层，必须显式记录依赖，并比较最小
合法组合，不得伪造不可运行的 isolated mode。

Screening 必须同时形成两类不同用途的 comparison，二者不得混用：

```text
TOTAL comparison:
    M0 vs every runnable cache-on candidate
    用于比较 candidate 的总端到端收益和冻结 final measurement candidate

MARGINAL comparison:
    M0  vs M1
    M1  vs M2
    M2  vs M3
    M3  vs M4
    用于得到 Delta_j = T(M(j-1)) - T(Mj)

DIRECT_LOO comparison:
    frozen runnable LOO(j) vs its frozen full branch
    用于得到 direct paired Delta_LOO,j
```

对 admitted optional layers，先测 no-C5 chain `M4 -> C6 -> C7`；再分别对
C5R 与 C5P branch 按固定顺序 `M4 -> C5* -> C6 -> C7`，去掉未 admission
的 C6/C7。chain 中每加入或 substitution 一层，必须测量
`previous cumulative mode vs new cumulative mode`。同时仍须测量每个
optional candidate 及每条最终组合相对 M0 的 TOTAL comparison。

Isolated comparison 只用于诊断单层成本，不得把 isolated delta 相加冒充
cumulative stack 收益。若两个 comparison 使用同一对 canonical modes、同一
baseline/candidate 方向、同一 trial、同一 repeat 和同一 pair order，可复用
同一原始 pair；否则必须分别测量并记录 comparison ID。仅 alias 名不同不构成
新 comparison；TOTAL_LOO 与 DIRECT_LOO 的 baseline 不同，通常不得复用。

## 18.2 Screening repeats

```text
72 trials
6 paired repeats per comparison ID
same frozen trial data
same MATLAB process within pair; no cache-state carryover across pair edges
every trial: AB=3, BA=3
therefore each comparison has AB=216, BA=216 overall
singleCompThread
external root timer
```

对每个 comparison 固定 `A=baseline mode b(c)`、`B=candidate mode a(c)`；
AB 表示相邻执行 A 后 B，BA 表示相邻执行 B 后 A。无论执行顺序如何，paired
difference 始终存成 `time(A)-time(B)`，因此正号始终表示 candidate 更快。
两条 pair edge 位于同一 MATLAB process，但每条 edge 前必须恢复相同的
合法 pristine cache state，不得从第一条 edge 向第二条泄漏 memo/session。

Screening 使用与第 20 节完全相同的 primary state：

```text
PRIMARY_WARM_ARTIFACT_READY_ONLINE_MEMO_EMPTY
```

只有 Pass B 声明为 `PREBUILT_FINITE_DOMAIN`、仅依赖 measurement identity/
frozen options、且不读取 72-trial observation 的 certified artifact 可在 root
timer 外 load/validate/setup。所有 ONLINE_MEMO 与 observation-bound cache 在
每个合法 scope 开始时为空，miss/population/store 成本在 timed region 内。
每个 pair 两边前恢复同一 pristine state，CACHE_OFF 不得改变 session。

对 comparison \(c\)，baseline mode 为 \(b(c)\)，candidate mode 为
\(a(c)\)，正号定义为 candidate 更快：

\[
d_{c,i,r}=T_{b(c),i,r}-T_{a(c),i,r}.
\]

\[
m_{c,i}=\operatorname{median}_{r=1}^{6}d_{c,i,r},
\qquad
D_{c,q}=\sum_{i\in q}m_{c,i},
\qquad
D_c=\sum_{i=1}^{72}m_{c,i}.
\]

\[
R_c
=100\frac{D_c}
{\sum_{i=1}^{72}\operatorname{median}_{r=1}^{6}T_{b(c),i,r}}.
\]

TOTAL comparison 固定 \(b(c)=M0\)；MARGINAL comparison 固定
\(b(c)\) 为 canonical predecessor。禁止使用独立样本 median 相减或
`median_r(sum_i d)` 作为 screening point。

6 repeats 不报告可靠 p90/bootstrap conclusion，只报告：

```text
paired median
paired min/max
per-identity point
overall point
memory
hit/miss
physical-call reduction
```

在所有 candidate comparison 之前运行一个冻结的 no-op control：

```text
CONTROL_MODE_A = M0 through the frozen CACHE_OFF entry path
CONTROL_MODE_B = the same M0 path with a distinct label only
```

两边必须解析到相同函数、参数、语句顺序和 instrumentation；label 不得进入
timed region。按上述 72x6 和 AB/BA 规则测量：

\[
e_{i,r}=T_{{\rm M0A},i,r}-T_{{\rm M0B},i,r},
\qquad
E_r=\sum_{i=1}^{72}e_{i,r}.
\]

\[
E_{\rm med}=\sum_{i=1}^{72}\operatorname{median}_{r=1}^{6}e_{i,r}.
\]

冻结 screening timing resolution 为：

\[
\rho_{\rm screen}
=
\max\left(
|E_{\rm med}|,
\max_{r=1,\ldots,6}|E_r|
\right).
\]

`rho_screen` 的单位是完整 72-trial workload 的秒数。不得用单 trial 或
单 call 的 resolution 与 overall candidate point 比较。若 control A/B
产生任何逻辑输出差异，输出 `SCREENING_NOOP_CONTROL_MISMATCH_STOP`。

## 18.3 Final measurement candidate rule

Final measurement candidate 必须在看到 final 20-repeat 数据前冻结。
Selection pool 只读取 baseline 为 canonical M0 的 `TOTAL`/`TOTAL_LOO`
comparison overall point；`MARGINAL`、`DIRECT_LOO`、`NOOP_CONTROL` 永远不得
进入 `SELECT(pool)`。

候选必须：

```text
correctness PASS
truth isolation PASS
collision count = 0
both identity screening point >= 0
overall screening point > 0
memory bound PASS
```

对任意非空 selection pool，固定 `SELECT(pool)`：

1. 计算 \(D_{\max}=\max_{c\in pool}D_c\)；
2. 定义唯一 timing tie set
   \(\mathcal T=\{c:D_{\max}-D_c\le\rho_{\rm screen}\}\)；
3. 在 \(\mathcal T\) 中保留 enabled layer count 最小者；
4. 再保留 `bytes_peak` 最小者；
5. 若仍有多个，按 canonical mode ID 的 UTF-8 bytes 字典序取首个。

不得用 pairwise tolerance comparator 排序，因为它可能非传递。
`SELECT(pool)` 返回唯一 `candidate_canonical_mode_id`；人类可读 alias 另存为
`final_measurement_candidate_alias_id=representative_alias_id(c)`，不得任选同一
canonical mode 的其他 alias，也不得用 alias 替代 canonical ID/hash。

Fallback pool 明确定义为所有满足以下条件的 cache-on candidate：

```text
correctness PASS
truth isolation PASS
collision count = 0
memory bound PASS
```

它不要求 screening point 为正。若 fallback pool 非空，但没有 candidate
同时满足 identity/overall 正收益条件，则：

```text
SCREENING_STATUS = MEASURED_SAVING_NONPOSITIVE_SCREENING
RECOMMENDED_RUNTIME_MODE_AFTER_SCREENING = M0
FROZEN_FINAL_MEASUREMENT_CANDIDATE = SELECT(fallback pool)
```

仍须对该 cache-on candidate 完成 Pass F 72x20，避免 M0-vs-M0 退化比较，
并允许更高精度的 final 数据纠正 6-repeat screening noise。不得为追求正结果
改变 candidate 或规则。若没有任何通过 correctness/truth/collision/memory
的 cache-on candidate，输出 `NO_RUNNABLE_CACHE_ON_MODE_STOP`。

若存在正收益候选，则：

```text
SCREENING_STATUS = POSITIVE_CACHE_ON_CANDIDATE_SELECTED
FROZEN_FINAL_MEASUREMENT_CANDIDATE = SELECT(positive eligible pool)
RECOMMENDED_RUNTIME_MODE_AFTER_SCREENING = FROZEN_FINAL_MEASUREMENT_CANDIDATE
```

---

# 19. Timing Protocol Freeze

在产生任何 screening/final/lifecycle 正式 sample 前使用以下固定值生成
`freeze/timing_protocol.json`。在 screening 前生成并 hash
`freeze/screening_schedule.csv`。screening 按 SELECT rule 唯一确定 candidate
后，先生成并 hash `freeze/final_warm_schedule.csv` 与
`freeze/cold_lifecycle_schedule.csv`，再将 candidate、matched-model sentinel/
row、screening proof 和这两个 schedule hash 一起原子闭合
`FINAL_CANDIDATE_FREEZE`；只有随后才能产生 Pass F/lifecycle sample。三份
schedule append-only、不得互相覆盖。先计算 protocol hash，再计算各自
schedule hash：

```text
MATLAB release                         = R2022b
singleCompThread                       = true
root timer                             = MATLAB tic/toc around exactly one frozen root call
screening paired repeats               = 6 per trial/comparison
screening AB/BA                        = 3/3 per trial
final WARM paired repeats              = 20 per trial
final WARM AB/BA                       = 10/10 per trial
COLD_BUILD paired batch repeats        = 10 per identity, AB/BA=5/5
COLD_LOAD paired batch repeats         = 10 per identity, AB/BA=5/5
component warmup/measured pairs        = 5/30 per identity
lifecycle operation warmup/measured    = 5/30 per identity
formal root warmup pairs               = 2 per warmup-registry row, order AB then BA, not recorded
formal root warmup registry            = first global_trial_index per unique
                                         (measurement_identity_hash, executable_profile_hash)
trial_order_seed                       = 2026080902
screening_pair_order_seed              = 2026080903
final_pair_order_seed                  = 2026080904
cold_pair_order_seed                   = 2026080905
component_pair_order_seed              = 2026080906
lifecycle_operation_order_seed         = 2026080907
bootstrap_seed                         = 2026080901
bootstrap resamples                    = 10000
bootstrap lower order statistic        = sorted value index 500
descriptive p10                        = sorted value index ceil(0.10*n)
descriptive p90                        = sorted value index ceil(0.90*n)
median                                 = MATLAB median (even n: mean two centers)
memory bound                           = 536870912 bytes per MATLAB process
primary cache state                    = PRIMARY_WARM_ARTIFACT_READY_ONLINE_MEMO_EMPTY
```

其中 `component_*` 字段只是对已闭合 `component_protocol_hash` 的一致性引用；
Pass B component sample 的唯一 authority 仍是第 15.1 节的 component protocol/
schedule。`timing_protocol.json` 不得追溯性改变 component sample，且相同字段
若不一致触发 `FREEZE_CHAIN_MISMATCH_STOP`。

`executable_profile_hash` 必须在 `DESIGN_FREEZE` 中定义为 stable hash of the
complete frozen profile/options fields that select executable branches；不得用
truth、observed runtime 或 cache result 构造。按 frozen registry 的
`global_trial_index` 升序，在每个唯一 `(measurement_identity_hash,
executable_profile_hash)` group 取首行，形成 immutable
`freeze/formal_warmup_registry.csv`，并把 row count/hash 写入 timing protocol
和 `TIMING_FREEZE`。这样每个 identity/profile 路径至少完成一次 JIT warmup。

所有 paired protocol 共用以下语义：`A` 是 comparison 的 baseline，`B` 是
candidate；AB 执行 A 后 B，BA 执行 B 后 A，stored difference 始终为
`time(A)-time(B)`。component 中 A=producer OFF、B=prototype ON；TOTAL/
MARGINAL/DIRECT_LOO 中按 comparison registry 的 baseline/candidate；final 和
cold 中 A=CACHE_OFF、B=frozen candidate CACHE_ON。

Schedule 不得调用或改变 estimator RNG。使用 domain-separated SHA-256 key
生成稳定顺序：

```text
trial order key = SHA256("TRIAL_ORDER" | seed | pass | comparison_id |
                         repeat_index | trial_id)
pair shuffle key = SHA256("PAIR_ORDER" | seed | pass | comparison_id |
                          trial_id | local_repeat_index | nominal_direction)
```

每个 repeat round 按 trial order key bytes 升序。screening 每 trial 构造
3 AB + 3 BA，再按 pair shuffle key 排列 6 个方向；final 每 trial构造
10 AB + 10 BA 后排列；
cold 每 identity 构造 5 AB + 5 BA 后排列。所有 schedule 在任何 timing 前
按上述 phase 写完并 hash，不得根据已观察 runtime 调整。final/cold schedule
只使用已冻结 candidate ID；screening 数据只能决定 candidate，不能改变
seed、repeat count 或 schedule algorithm。

component 每 identity 构造 15 AB + 15 BA，使用 component seed 和相同
domain-separated pair shuffle；lifecycle operation 的 30 measured repeats 按
lifecycle seed 生成固定 operation/repeat order。

每个 comparison 正式计时前，对 `formal_warmup_registry` 的每一行运行一个
AB pair 和一个 BA pair。warmup 后丢弃所有 online memo/session/counters，重新 load
合法 immutable prebuilt artifact；warmup 产生的 entry 不得进入正式 state。
COLD warmup artifact 也必须丢弃。screening raw samples 不得并入 final 20
repeats；final 必须重新执行。

每个 timed call 的唯一计时实现：

```matlab
drawnow;                         % outside timed region
root_clock = tic;
[result, diagnostics] = frozen_root_entry(...);
elapsed_sec = toc(root_clock);
```

`frozen_root_entry` 在 protocol 中必须解析为调用
`stage8_k2_tp_fit_safe(Y_element, model, context)` 的实验 runner function
handle/path/hash；它不是另一个 estimator，也不得改变 root measurement
边界。

禁止 `timeit`、内部 `result.runtime_sec`、stage timer 或 profiler 代替
`elapsed_sec`。console/file output、checkpoint write、session restore 和 fixture
load 位于 timer 外；root call 生产语义必需的 trial-scope session create/reset、
key/hash/lookup/store/copy 必须留在 timer 内。

同一 `timing_protocol_hash` 还必须覆盖：cache state/reset implementation
hash、minimal counter list、no-op control hash、TOTAL/MARGINAL comparison IDs、
candidate selection rule、instrumentation flags、stage/summary schema hashes。
任何 timed sample 后的规则或实现 hash 修改都使旧 sample/checkpoint 失效。
所有 p10/p90 均使用上述 frozen order statistic，不调用默认插值 percentile。

---

# 20. Pass F — Final Paired Measured Validation

比较：

```text
M0 CACHE_OFF
vs
FROZEN_FINAL_MEASUREMENT_CANDIDATE
```

协议：

```text
lifecycle = WARM
72 trials
20 paired repeats
AB = 10 per trial
BA = 10 per trial
singleCompThread
same frozen trial data
same MATLAB process within each pair
no cache-state carryover across pair edges
randomized trial order per repeat round
formal warmup before samples
```

每个 WARM pair 开始前必须恢复同一 pristine warm state：final candidate 中
只有 Pass B 认证为 `PREBUILT_FINITE_DOMAIN` 且完全不依赖 72-trial observation
的 entries 在 timer 外 load/validate/setup；若 C1 enabled，其 21-key dictionary
保持只读。所有 `ONLINE_MEMO`、observation-bound、trial/invocation-scope layers
均为空，所有 scalar counters 清零。禁止用 72 个 evaluation trials、其 query
audit 或其完整 key exposure 预热 online memo。所有 miss/population/store 成本
留在 timed region。

pair 第一边结束后，在第二边开始前再次恢复相同合法 scope state。
CACHE_OFF 一边不得改变 cache state。state reset/restore 规则和实现 hash
必须在第 19 节冻结。

本节 72x20 是唯一用于 final `MEASURED_CACHE_STACK_SAVING`、bootstrap
lower bound 和 performance taxonomy 的 WARM 数据。正式 screening 与
final timed region 必须设置：

```text
shadow_mode = false
raw_query_logging = false
trajectory_capture = false
per_call_timing = false
stage_timing = false
cache_debug_logging = false
filesystem_write_inside_timed_region = false
```

timed region 内只允许 production-intended minimal measurement：

```text
one external root wall-clock timer
preallocated scalar cache hit count
preallocated scalar cache miss count
preallocated scalar physical producer-call count
preallocated scalar entry/current-bytes/peak-bytes counters
```

`entry_count` 与 `bytes_peak` 在 root timer 停止后读取。OFF/ON 使用同一套
最小 counter plumbing；CACHE_OFF 不构造 key、不 lookup、不 store。
correctness、shadow、raw exposure 和 stage reconciliation 必须在独立的
非 final-performance run 中完成，其带 instrumentation 的 runtime 不得写入
final performance CSV 的 point/lower 字段。

定义正收益：

\[
d_{i,r}
=
T_{{\rm OFF},i,r}
-
T_{{\rm ON},i,r}.
\]

每 trial：

\[
m_i=\operatorname{median}_{r=1}^{20}d_{i,r}.
\]

每 identity \(q\)：

\[
D_q=\sum_{i\in q}m_i.
\]

总体：

\[
D_{\rm total}=\sum_{i=1}^{72}m_i.
\]

\[
R_{\rm total}
=
100
\frac{D_{\rm total}}
{\sum_i\operatorname{median}_r T_{{\rm OFF},i,r}}.
\]

令 \(\mathcal R_{i,AB}\)、\(\mathcal R_{i,BA}\) 为 schedule 中各 10 个
repeat indices：

\[
D_{AB}
=
\sum_{i=1}^{72}
\operatorname{median}_{r\in\mathcal R_{i,AB}}d_{i,r},
\qquad
D_{BA}
=
\sum_{i=1}^{72}
\operatorname{median}_{r\in\mathcal R_{i,BA}}d_{i,r}.
\]

`AB-only point = D_AB`，`BA-only point = D_BA`。不得按方向 pooling 全部
trials/repeats。令
\(T_{\rm OFF,total}=\sum_i\operatorname{median}_rT_{{\rm OFF},i,r}\)，
则 speedup ratio 固定为：

\[
S_{\rm total}
=
\frac{T_{\rm OFF,total}}{T_{\rm OFF,total}-D_{\rm total}}.
\]

禁止：

```text
median(OFF) - median(ON) from independent samples
pooling all 1440 repeats as one homogeneous population
post-hoc removal of slow trials
post-hoc mode/final measurement candidate change
```

---

# 21. Fixed-Registry AB/BA-Stratified Paired Bootstrap

最终 one-sided 95% lower bound 使用冻结的：

```text
bootstrap_seed = 2026080901
resamples = 10000
lower_quantile = one-sided 5th percentile
quantile_algorithm = sort ascending and select 1-based index 500
```

每个 bootstrap replicate：

1. 固定全部 72 trial IDs、identity membership 和权重，不重采样 trial；
2. 对每个 trial \(i\)，从其 10 个 AB differences 有放回抽取 10 个；
3. 独立地从同一 trial 的 10 个 BA differences 有放回抽取 10 个；
4. 合并该 trial 的 20 个 stratified resamples 并求 median
   \(m_i^{(b)}\)；
5. 对每个固定 identity 的 36 个 \(m_i^{(b)}\) 求和得到
   \(D_q^{(b)}\)；
6. 对固定 72 trials 求和得到 \(D_{\rm total}^{(b)}\)。

该 lower bound 的 estimand 是 frozen 72-trial factorial workload 的 timing
uncertainty，与第 20 节 point 完全相同；不宣称 trial-superpopulation inference。
禁止跨 trial/identity pooling，禁止改变 AB/BA 10/10 权重。每个
trial/direction 的 PRNG stream 由 `bootstrap_seed | replicate | trial_id |
direction` 确定性派生，并把实现 hash 写入 manifest。

总体 lower bound：

\[
LB_{\rm total}
=
Q_{0.05}\left(D_{\rm total}^{(b)}\right).
\]

identity lower bound 同理。

实现时将 10,000 个 \(D^{(b)}\) 升序排序，lower bound 取第 500 个值；
不得调用可能随 MATLAB release 改变插值规则的默认 `prctile` 来替代该
order statistic。

同时报告：

```text
trial paired median/min/max/p10/p90
identity point/lower
overall point/lower
AB-only point
BA-only point
```

若 AB 与 BA 之一为负，不能判定 robust positive。

---

# 22. Cold Build、Cold Load 与 Warm 必须分开

固定三种 lifecycle：

\[
T_{\rm COLD\_BUILD}(N)
=
B_{\rm build}+B_{\rm load}+B_{\rm validate}+B_{\rm setup}
+\sum_{i=1}^N T_{{\rm on},i}.
\]

\[
T_{\rm COLD\_LOAD}(N)
=
B_{\rm load}+B_{\rm validate}+B_{\rm setup}
+\sum_{i=1}^N T_{{\rm on},i}.
\]

\[
T_{\rm WARM}(N)
=
\sum_{i=1}^N T_{{\rm on},i}.
\]

M1 measurement-identity dictionary 可跨同 identity trials。

C2-C4 默认每 trial/invocation 新建 scope，不得跨 observation。

C5R/C5P/C6/C7 按 Pass A dependency audit 与 Pass B admission 冻结 scope。

## 22.1 冻结的 measured lifecycle workloads

三种 lifecycle 必须使用互不混写的 raw samples 和 summary rows：

```text
WARM:
    72 trials x 20 paired repeats
    per trial AB=10, BA=10
    enabled identity-scope immutable entries 已按第 20 节在 root timer 前准备
    observation/trial/invocation-scope layers 按 frozen scope reset；reset 成本若
    生产路径需要，必须留在 timed region

COLD_BUILD:
    2 measurement-identity batches x 36 trials x 10 paired batch repeats
    per identity batch AB=5, BA=5
    each ON batch starts with no in-memory session and no reusable built artifact
    ON root timer includes build + load + validate + setup + all 36 trials
    OFF root timer includes the same frozen trial preparation and all 36 CACHE_OFF
    trials, but performs no fake cache work

COLD_LOAD:
    2 measurement-identity batches x 36 trials x 10 paired batch repeats
    per identity batch AB=5, BA=5
    each ON batch starts with no in-memory session and an immutable prebuilt artifact
    ON root timer includes load + validate + setup + all 36 trials
    OFF boundary is identical to COLD_BUILD OFF
```

每个 batch pair 必须在同一 MATLAB process、相邻执行；A/B 顺序随机但精确
满足 5/5。process startup、trial fixture loading 和与两边完全相同的 registry
materialization 位于两边 root timer 之外。cache-specific build/load/validate/
setup 不得移出 ON root timer。COLD_BUILD 必须先写 artifact，再通过与
COLD_LOAD 相同的 load path 构造 provider/session；不得直接复用 builder 的
in-memory object 绕过 load。每个 ON repeat 使用新的空 runtime
artifact directory；COLD_LOAD 使用 hash 已冻结且只读的 artifact。不得在仓库
内写 lifecycle 临时文件。

所有 COLD batch timed regions 使用第 20 节相同的 shadow/raw/stage/debug
禁用项和 minimal scalar counters。lifecycle operation 自身的外部 timer
可以计时，但不得在 operation 内启用 per-call logging。

WARM、COLD_BUILD、COLD_LOAD 分别计算 point estimate；只有 WARM 72x20
进入第 21 节 fixed-registry stratified bootstrap 和第 24.3 节 performance status。
COLD_BUILD/COLD_LOAD 用于 lifecycle status 与 break-even，不得与 WARM
samples 拼接或替代 WARM lower bound。

对 lifecycle \(L\in\{\mathrm{COLD\_BUILD},\mathrm{COLD\_LOAD}\}\)，
identity batch \(q\)、repeat \(r\) 定义：

\[
d^{L}_{q,r}
=
T^{L}_{{\rm OFF},q,r}
-
T^{L}_{{\rm ON},q,r}.
\]

\[
D^{L}_{q}=\operatorname{median}_{r=1}^{10}d^{L}_{q,r},
\qquad
D^{L}_{\rm total}=\sum_qD^{L}_{q}.
\]

\[
R^{L}_{\rm total}
=100\frac{D^{L}_{\rm total}}
{\sum_q\operatorname{median}_{r=1}^{10}T^{L}_{{\rm OFF},q,r}}.
\]

正号始终表示 cache-on 更快。禁止把 operation microbenchmark 中位数与
WARM point 简单相加来替代上述直接 batch measurement。

## 22.2 Lifecycle operation microbenchmarks

对 `FROZEN_FINAL_MEASUREMENT_CANDIDATE` 的每个 measurement identity，
冻结：

```text
lifecycle_micro_warmup_repeats = 5     # 不进入统计
lifecycle_micro_measured_repeats = 30
operations = build, load, validate, setup, reset
```

每次 build measured repeat 使用新的空 runtime subdirectory；每次 load 使用
同一 immutable、hash-matched artifact，并先清空 in-memory session；validate、
setup、reset 必须从其生产预期前置状态开始。报告每 operation/identity 的
median、p10、p90、min、max 和 30 个 raw samples 的仓库外路径。hash、lookup
hit、lookup miss、store、copy 另以 30 个 measured repeats 的批量 operation
microbenchmark 测量；不得用 per-call timer 污染 final WARM/COLD runtime。

Break-even 的 workload unit 冻结为“每个 measurement identity 各运行一个
trial”，即一个 balanced two-identity cycle 共 2 trials。令：

```text
BREAK_EVEN_MODEL_ID = BALANCED_TWO_IDENTITY_UNIFORM_FROZEN_REGISTRY_AVERAGE_MODEL
```

\[
\bar d_q=D_q^{\rm WARM}/36,
\]

其中 \(D_q^{\rm WARM}\) 使用第 20 节的 36 个 trial medians。对
\(X\in\{\mathrm{build},\mathrm{load}\}\)，令 \(B_{X,q}\) 为 30-repeat
operation microbenchmark 的 identity median，并把 validate/setup 的 median
计入：

\[
B^{\star}_{\rm build,q}
=B_{{\rm build},q}+B_{{\rm load},q}
+B_{{\rm validate},q}+B_{{\rm setup},q},
\]

\[
B^{\star}_{\rm load,q}
=B_{{\rm load},q}+B_{{\rm validate},q}+B_{{\rm setup},q}.
\]

则 balanced \(N\)-cycle curve 定义为：

\[
\operatorname{NetSaving}_{X}(N)
=
N(\bar d_1+\bar d_2)
-
\left(B^{\star}_{X,1}+B^{\star}_{X,2}\right).
\]

\[
N_{{\rm break-even},X}
=
\min\{N\in\mathbb N,\ N\ge1:\operatorname{NetSaving}_{X}(N)>0\}.
\]

若 \(\bar d_1+\bar d_2\le0\)，break-even 为 `Inf`。报告的
`N=1,2,5,10,20,36,72,100,1000` 均指 balanced cycles，不是单个 trial。
该曲线按每个 identity 的 frozen 36-trial empirical factorial distribution
平均收益外推，不是某个具体 trial 的确定性收益；只有 `N=36` 与完整 72-row
frozen registry workload 直接对应。任何真实 deployment mix 不同的 horizon
不得套用这条曲线。
用直接 COLD batch 在 `N=36` 处计算 lifecycle model residual；该 residual
只称 `LIFECYCLE_MODEL_RESIDUAL`，不得用它回填或修改实测 cold point。

必须报告：

```text
build sec
load sec
validate sec
setup sec
hash sec
lookup hit sec
lookup miss sec
store sec
copy sec
reset sec
bytes peak
entry count
break-even N
net saving at N=1,2,5,10,20,36,72,100,1000
```

没有真实 workload horizon 时：

```text
DEPLOYMENT_STATUS = NOT_ASSESSED_NO_WORKLOAD_HORIZON
```

---

# 23. Runtime stage reconciliation

复用上一轮 stage IDs 和 hierarchy，不另造同义 stage。

至少保留：

```text
ROOT_TANGENT_PROFILE_SAFE
K1_PUBLIC
K2_PUBLIC
TAIL_FULL_DATA
CENTER_MANIFOLD_DERIVATIVES
PROJECTED_DIRECTION
T4_PROFILE
FINAL_SAFE_SELECTOR
K1_CONTEXT
K1_FULL_DATA
K1_INITIALIZATION_TOTAL
K1_FIXED_REGISTERED_REFINEMENT
K1_CONTINUOUS
K2_CONTEXT
K2_FULL_DATA
K2_INITIALIZATION_TOTAL
K2_HELPER_K1
K2_NESTED_ANCHOR
K2_REGISTERED_REFINEMENT
K2_FINAL_CERTIFICATION
```

新增 cache stage：

```text
CACHE_SESSION_SETUP
CACHE_KEY_BUILD
CACHE_LOOKUP_HIT
CACHE_LOOKUP_MISS
CACHE_STORE
CACHE_COPY
CACHE_VALIDATE
CACHE_RESET
```

cache timer 不得改变 final external root measurement 口径。

stage reconciliation 使用独立 diagnostics run；其 mode、trial、counter 与
正式 WARM final measurement candidate 相同，但允许 stage timers。固定运行
`M0` 和 final candidate 各 `72 trials x 1 repeat`，使用同一 ordered registry，
不计算性能统计。diagnostics runtime 只验证 hierarchy/reconciliation，不得
代替或修正第 20 节的 final external timing。

必须保持 stage reconciliation；出现不可解释 negative exclusive time 或
reconciliation drift：

```text
STAGE_RECONCILIATION_FAILURE_STOP
```

---

# 24. Pass G — Economics、Interaction Residual 与决策

## 24.1 Measured stack

只允许从 final paired OFF/ON 得到：

```text
MEASURED_CACHE_STACK_SAVING
```

## 24.2 Model residual

Pass B component benchmark 后为所有 runnable candidate 生成 model registry，
并在任何 screening sample 前把完整 registry hash 写入 `TIMING_FREEZE`；Pass E
选出 final candidate 后、Pass F 前只能从该 immutable registry 冻结 exact
matched row。不得在看到 screening/final runtime 后新增、删除或重拟合 model
row。每个 row：

```text
model_id
exact ordered enabled-layer set
population class and scope per layer
matched_candidate_mode
component exposure counts
measured component lookup/miss/store/copy costs
overlap partition status
frozen_model_delta_sec
historical_baseline_model_percent = 100 * delta_sec / 364.872219
baseline_commit
baseline_semantic_snapshot_hash
trial_registry_hash
measurement_identity_hashes
timing_protocol_hash
model_status
model_hash
```

`model_status` 只能取：

```text
MATCHABLE_FROZEN_MODEL
NOT_MATCHABLE_INCOMPLETE_COMPONENT_COST
NOT_MATCHABLE_OVERLAP_UNPARTITIONED
NOT_MATCHABLE_BASELINE_SCOPE_OR_PRECEDENCE
```

只有 `MATCHABLE_FROZEN_MODEL` row 可在 final selection 后成为 matched row。

只有 enabled-layer set、precedence（尤其 C5P supersede C1）、scope、primary
WARM lifecycle 与 final candidate 完全一致，且 overlap partition 无重复计数，
才冻结：

```text
FROZEN_MODEL_ID
FROZEN_MODEL_DELTA_SEC
FROZEN_MODEL_HISTORICAL_BASELINE_PERCENT
MATCHED_FINAL_CANDIDATE = true
FROZEN_MODEL_STATUS = MATCHED
MODEL_RESIDUAL_STATUS = AVAILABLE
```

此时定义，且量纲均为秒：

\[
J_{\rm stack}
=
\Delta_{\rm measured,sec}
-
\Delta_{\rm frozen\ model,sec}.
\]

令第 20 节本轮实测 baseline 为
\(T_{\rm OFF,total}=\sum_i\operatorname{median}_rT_{{\rm OFF},i,r}\)。Pass F
之后才派生：

\[
R_{\rm frozen\ model\mid final\ baseline}
:=
100\frac{\Delta_{\rm frozen\ model,sec}}{T_{\rm OFF,total}},
\qquad
J_{\rm stack,pct\mid final\ baseline}
:=
100\frac{J_{\rm stack}}{T_{\rm OFF,total}}.
\]

历史 `364.872219 s` denominator 的值只允许命名为
`FROZEN_MODEL_HISTORICAL_BASELINE_PERCENT`。禁止把它与 final measured
percentage 相减。Economics 必须同时保存历史 denominator、final measured
denominator 和两个明确命名的 percentage。

只能称：

```text
CACHE_STACK_RUNTIME_INTERACTION_RESIDUAL
```

不得称 causal synergy。

若没有 exact matched model：

```text
J_stack = NaN
J_stack_pct_on_final_baseline = NaN
FROZEN_MODEL_ID = NONE
FROZEN_MODEL_STATUS = NOT_AVAILABLE_NO_MATCHED_FROZEN_MODEL
MODEL_RESIDUAL_STATUS = NOT_AVAILABLE_NO_MATCHED_FROZEN_MODEL
```

最终两个状态字段是封闭枚举：

```text
FROZEN_MODEL_STATUS:
    MATCHED
    NOT_AVAILABLE_NO_MATCHED_FROZEN_MODEL

MODEL_RESIDUAL_STATUS:
    AVAILABLE
    NOT_AVAILABLE_NO_MATCHED_FROZEN_MODEL
```

`FROZEN_MODEL_STATUS=MATCHED` 当且仅当
`MODEL_RESIDUAL_STATUS=AVAILABLE`；其他组合非法。

不得把以下 historical gross hypotheses 用作任意 candidate 的 matched model：

```text
3.715591% = C1 measured lookup + zero incremental C2-C4 cache overhead hypothesis
3.765156% = above + zero incremental C5R hit-cost hypothesis
3.952132% = additive known-exposure C1 zero-lookup + rank-still-runs ceiling
4.001697% = additive known-exposure C5P full-primitive zero-hit-cost ceiling
```

它们必须继续报告以解释理论 headroom，但都不是默认 expected model。C5R/P
仅 admission 不足以选择其中任何数值。

## 24.3 Performance status

### MEASURED_CACHE_STACK_ROBUST_POSITIVE

同时满足：

```text
all correctness gates PASS
collision count = 0
truth leakage count = 0
overall point > 0
overall 95% lower bound > 0
both identity point >= 0
AB-only point >= 0
BA-only point >= 0
memory bound PASS
```

### MEASURED_CACHE_STACK_INCONCLUSIVE

`overall point > 0`，但发生任一：lower bound 覆盖 0、任一 identity point
为负、AB-only 或 BA-only point 为负，或 memory robustness 不足。

Lifecycle status 独立报告；cold build/load 未 break even 不得把一个满足
上述 WARM robust-positive gates 的结果改成 INCONCLUSIVE。

### MEASURED_CACHE_STACK_NONPOSITIVE

```text
overall point <= 0
```

这是唯一的 final stack NONPOSITIVE 判据。若 overall point 为正，但某个
identity/AB/BA 为负，必须归入 INCONCLUSIVE，不得借助 screening resolution
改判。单层 lookup/store/copy 不快于原调用时，在 Pass B/E 将该层标为
`PREDICTED_NET_NONPOSITIVE_LAYER` 或 final-candidate-ineligible；它不覆盖
final stack 的上述三级 taxonomy。

Correctness failure 不归入上述三级；它是 hard stop。

## 24.4 Lifecycle status

独立报告：

```text
COLD_BUILD_72_TRIALS_POSITIVE
COLD_BUILD_72_TRIALS_NONPOSITIVE
COLD_LOAD_72_TRIALS_POSITIVE
COLD_LOAD_72_TRIALS_NONPOSITIVE
COLD_BUILD_BREAK_EVEN_FINITE
COLD_BUILD_NO_BREAK_EVEN
COLD_LOAD_BREAK_EVEN_FINITE
COLD_LOAD_NO_BREAK_EVEN
NOT_ASSESSED_NO_WORKLOAD_HORIZON
```

对 COLD_BUILD 和 COLD_LOAD 各选且只选一个 72-trial point status，并各选且
只选一个 break-even status。若对应 \(D^L_{\rm total}>0\) 则为 POSITIVE，
否则为 NONPOSITIVE；若第 22.2 节的 \(N_{\rm break-even,X}\) 有限则为
BREAK_EVEN_FINITE，否则为 NO_BREAK_EVEN。不得用 WARM point 替代 cold status。

本阶段不得输出：

```text
DEPLOYMENT_JUSTIFIED
PRODUCTION_DEFAULT_CACHE_ON
```

---

# 25. Checkpoint / Resume

runtime root：

```text
E:\bs_innovation_runtime\stage8_k2_tangent_exact_cache_stack_v1
```

最小原子单元：

```text
checkpoint_unit_kind
pass
cache_setting
cache_layer
variant_alias_id
comparison_id
comparison_kind
baseline_canonical_mode_id
candidate_canonical_mode_id
enabled_layer_set_hash
precedence_hash
fixed_measurement_hash
trial_id
repeat_index
pair_order
schedule_row_id
schedule_row_hash
lifecycle_setting
identity_batch_id
batch_repeat_index
lifecycle_operation
operation_repeat_index
```

`checkpoint_unit_kind` 是封闭枚举，必填字段固定为：

| unit kind | 除共同 provenance 外必须非 sentinel 的 key 字段 |
|---|---|
| `BASELINE_TRIAL` | `fixed_measurement_hash, trial_id, schedule_row_id/hash` |
| `AUDIT_TRIAL` | `cache_layer, fixed_measurement_hash, trial_id, schedule_row_id/hash` |
| `COMPONENT_PAIR` | `cache_setting=PAIRED_OFF_ON, cache_layer, fixed_measurement_hash, identity_batch_id, batch_repeat_index, pair_order, lifecycle_setting=WARM, schedule_row_id/hash` |
| `SHADOW_TRIAL` | `cache_layer, fixed_measurement_hash, trial_id, schedule_row_id/hash` |
| `CORRECTNESS_TRIAL` | `candidate_canonical_mode_id, enabled_layer_set_hash, precedence_hash, fixed_measurement_hash, trial_id, schedule_row_id/hash` |
| `SCREENING_PAIR` | `cache_setting=PAIRED_OFF_ON, variant_alias_id, comparison_id/kind, baseline/candidate canonical mode IDs, enabled_layer_set_hash, precedence_hash, fixed_measurement_hash, trial_id, repeat_index, pair_order, lifecycle_setting=WARM, schedule_row_id/hash` |
| `FINAL_TRIAL_PAIR` | `cache_setting=PAIRED_OFF_ON, comparison_id/kind, baseline/candidate canonical mode IDs, enabled_layer_set_hash, precedence_hash, fixed_measurement_hash, trial_id, repeat_index, pair_order, lifecycle_setting=WARM, schedule_row_id/hash` |
| `COLD_BATCH_PAIR` | `cache_setting=PAIRED_OFF_ON, comparison_id/kind, baseline/candidate canonical mode IDs, enabled_layer_set_hash, precedence_hash, fixed_measurement_hash, identity_batch_id, batch_repeat_index, pair_order, lifecycle_setting, schedule_row_id/hash` |
| `LIFECYCLE_OPERATION` | `candidate_canonical_mode_id, cache_layer, fixed_measurement_hash, identity_batch_id, lifecycle_operation, operation_repeat_index, schedule_row_id/hash` |
| `STAGE_DIAGNOSTIC_TRIAL` | `candidate_canonical_mode_id, enabled_layer_set_hash, precedence_hash, fixed_measurement_hash, trial_id, schedule_row_id/hash` |

`checkpoint_unit_kind` 与 `pass` 对所有 kind 必填。对 BASELINE/AUDIT/SHADOW/
CORRECTNESS/STAGE_DIAGNOSTIC，`schedule_row_id` 固定为 frozen registry 的
`global_trial_index`，`schedule_row_hash` 为该 immutable registry row 的 stable
hash。表中未列为该 kind 必填的所有 key 字段必须逐字写
`NOT_APPLICABLE`；禁止空字符串、JSON null、缺列或临时伪 mode。Freeze 字段另按
下文使用 `NOT_CLOSED` sentinel。`cache_setting` 只允许 `CACHE_OFF`、
`CACHE_ON`、`PAIRED_OFF_ON` 或 `NOT_APPLICABLE`；`lifecycle_setting` 只允许
`WARM`、`COLD_BUILD`、`COLD_LOAD` 或 `NOT_APPLICABLE`。
checkpoint `comparison_kind` 只能为 `TOTAL`、`MARGINAL`、`TOTAL_LOO`、
`DIRECT_LOO`、`NOOP_CONTROL`、`FINAL_TOTAL`、`COLD_BUILD_TOTAL`、
`COLD_LOAD_TOTAL` 或 `NOT_APPLICABLE`。FINAL/COLD 必须使用其专用值，不能
复用 screening `TOTAL` comparison ID。

每个 checkpoint 必须：

- 写临时文件；
- flush/close；
- 同文件系统 atomic rename；
- 记录 `unit_complete=true`；
- 记录 pair contiguous/complete；
- 不把跨进程 OFF/ON 拼成 paired sample。

恢复必须匹配：

```text
baseline commit
initial execution start commit
run ID
stage commit ledger hash
integration code commit
prompt hash
baseline snapshot hash
cache code hash
frozen function hashes
trial registry hash
key schema hash
semantic output projection hash
hook allowlist hash
timing protocol hash
phase schedule hash
final_measurement_candidate_hash
design_freeze_hash
component_freeze_hash_or_sentinel
timing_freeze_hash_or_sentinel
final_candidate_freeze_hash_or_sentinel
MATLAB release
singleCompThread
cache reset/lifecycle rule
```

Freeze sentinels 固定为：

```text
phase before COMPONENT_FREEZE: component/timing/final = NOT_CLOSED
component replay:              component = real hash; timing/final = NOT_CLOSED
integration before TIMING:     component = real hash; timing/final = NOT_CLOSED
Pass E:                        component/timing = real hash; final = NOT_CLOSED
Pass F/G/lifecycle:            all four = real hash
```

Pass B component checkpoint 的 phase schedule hash 是
`component_schedule_hash`。Pass E checkpoint 中
`final_measurement_candidate_hash=NOT_FROZEN_PASS_E`，并匹配
`screening_comparison_set_hash`；完成 `FINAL_CANDIDATE_FREEZE` 后的 Pass F/G
checkpoint 必须匹配真实 candidate hash，二者不得混用。Pass E 的 phase
schedule hash 是 `screening_schedule_hash`；Pass F/lifecycle 分别使用
final-warm/cold hash。checkpoint key 是上述字段的完整 tuple；不得只用
`cache_setting/trial/repeat` 覆盖 TOTAL、MARGINAL、DIRECT_LOO 或 alias。

任一不匹配：

```text
CHECKPOINT_IDENTITY_MISMATCH_STOP
```

---

# 26. Evidence schemas

## 26.1 Freeze CSV

至少：

```text
schema_version
freeze_phase
parent_freeze_hash
freeze_payload_hash
created_before_pass
path
role
baseline_hash
post_implementation_hash
frozen_flag
allowed_change_flag
status
```

## 26.2 Exposure CSV

至少：

```text
schema_version
cache_layer
function_role
producer_stage
consumer_stage
legal_scope
fixed_measurement_hash
trial_id
call_count
unique_key_count
hit_opportunity_count
hit_ratio
cache_population_class
covered_lookup_count
coverage_ratio
cost_weighted_hit_ratio
reuse_distance_median
reuse_distance_p90
original_compute_sec
gross_avoidable_compute_upper_sec
lookup_sec
store_sec
copy_sec
predicted_net_saving_sec
predicted_net_saving_source
component_repeat_count
component_AB_count
component_BA_count
component_point_sec
bytes_peak
key_collision_count
truth_leakage_count
purity_status
exposure_status
audit_eligibility_status
integration_status
```

## 26.3 Correctness CSV

至少：

```text
schema_version
cache_candidate_canonical_mode_id
cache_layer
fixed_measurement_hash
trial_id
continuous_numeric_pass
G_rel_error
rank_match
score_match
candidate_order_match
tie_match
best_index_match
accepted_update_match
trajectory_match
selected_start_match
nested_pass_match
final_selector_match
truth_isolation_pass
cache_off_baseline_match
correctness_pass
failure_reason
```

## 26.4 Screening CSV

至少：

```text
schema_version
aggregation_level
row_key
variant_alias_id
candidate_canonical_mode_id
baseline_canonical_mode_id
ordered_enabled_layer_set
enabled_layer_set_hash
alias_of_canonical_mode_id
alias_of_comparison_id
source_full_canonical_mode_id
precedence_hash
fallback_hash
comparison_id
comparison_kind
predecessor_canonical_mode_id
fixed_measurement_hash
trial_id
measurement_identity_hash
repeat_count
AB_count
BA_count
paired_median_sec
paired_min_sec
paired_max_sec
identity_point_sec
overall_point_sec
total_point_sec
marginal_point_sec
screening_resolution_sec
bytes_peak
physical_call_reduction
final_candidate_eligible
screening_comparison_set_hash
screening_schedule_hash
select_tie_set_member
select_rank_after_layer_count
select_rank_after_bytes_peak
screening_status
recommended_runtime_mode_after_screening
final_measurement_candidate_alias_id
final_measurement_candidate_canonical_mode_id
```

`aggregation_level` 只能为 `TRIAL`、`IDENTITY`、`OVERALL`、`MODE_ALIAS`、
`COMPARISON_ALIAS`：TRIAL row 的
唯一 key 是 `(comparison_id,trial_id)`，只填 trial statistics；IDENTITY row 的
唯一 key 是 `(comparison_id,measurement_identity_hash)`，`trial_id` 为空；
OVERALL row 的唯一 key 是 `comparison_id`，trial/identity 字段均为空。aggregate
值只写在其所属层级；不适用值必须为空/JSON null，不得写 `0`。`comparison_kind`
只能为 `TOTAL`、`MARGINAL`、`TOTAL_LOO`、`DIRECT_LOO` 或
`NOOP_CONTROL`。MODE_ALIAS row 的唯一 key 是 `variant_alias_id`，只引用
`alias_of_canonical_mode_id`，comparison/measured 字段为空。COMPARISON_ALIAS
row 的唯一 key 是 `(variant_alias_id,comparison_id,comparison_kind)`，引用
`alias_of_comparison_id`；因此同一个 LOO alias 必须分别有 TOTAL_LOO 和
DIRECT_LOO 两行。两类 alias row 的 measured 字段均为空，不得复制 raw 或
aggregate sample。

## 26.5 Runtime summary CSV

至少：

```text
schema_version
final_measurement_candidate_alias_id
final_measurement_candidate_canonical_mode_id
recommended_runtime_mode_after_screening
lifecycle_setting
aggregation_level
scenario_aggregate
fixed_measurement_hash
trial_id
repeat_count
AB_count
BA_count
paired_median_sec
paired_p10_sec
paired_p90_sec
paired_min_sec
paired_max_sec
point_saving_sec
bootstrap_lower_sec
baseline_runtime_sec
runtime_reduction_pct
speedup_ratio
AB_point_sec
BA_point_sec
bootstrap_resample_count
bootstrap_order_statistic_index
timing_protocol_hash
frozen_model_id
frozen_model_hash
frozen_model_status
model_residual_status
final_recommendation_status
layer_set_retention_status
final_recommended_experiment_mode
```

## 26.6 Lifecycle CSV

至少：

```text
schema_version
row_kind
cache_candidate_canonical_mode_id
cache_layer
fixed_measurement_hash
batch_trial_count
paired_repeat_count
AB_count
BA_count
micro_warmup_repeat_count
micro_measured_repeat_count
build_sec
load_sec
validate_sec
setup_sec
hash_sec
lookup_hit_sec
lookup_miss_sec
store_sec
copy_sec
reset_sec
entry_count
bytes_peak
break_even_model_id
break_even_N
N_balanced_cycles
net_saving_sec
lifecycle_model_residual_sec
cold_build_point_status
cold_load_point_status
cold_build_break_even_status
cold_load_break_even_status
```

`row_kind` 只能为 `OPERATION_SUMMARY`、`LIFECYCLE_POINT` 或
`BREAK_EVEN_CURVE`。每个 `BREAK_EVEN_CURVE` row 只保存一个
`N_balanced_cycles` 与一个 `net_saving_sec`；固定 N 集合必须产生 9 rows，
不得把曲线编码进未定义字符串。其他 row 中这两个字段为空而非 0。

## 26.7 Economics CSV

至少：

```text
schema_version
historical_baseline_T0
measured_cache_stack_runtime
measured_saving_sec
measured_runtime_reduction_pct
measured_speedup_ratio
bootstrap_lower_sec
identity_min_point_sec
AB_point_sec
BA_point_sec
frozen_model_point_sec
frozen_model_historical_baseline_pct
frozen_model_pct_on_final_baseline
final_measured_baseline_sec
runtime_interaction_residual_sec
runtime_interaction_residual_pct_on_final_baseline
frozen_model_id
frozen_model_hash
frozen_model_status
model_residual_status
performance_status
cold_build_point_status
cold_load_point_status
cold_build_break_even_status
cold_load_break_even_status
deployment_status
final_recommendation_status
layer_set_retention_status
final_recommended_experiment_mode
final_production_default_cache_setting
```

## 26.8 Manifest JSON

至少：

```text
branch
level_a_closure_commit
placement_audit_code_commit
placement_audit_evidence_commit
exact_cache_stack_baseline_commit
execution_start_commit
initial_execution_start_commit
current_head_at_evidence_write_base
run_id
stage_commit_ledger_hash_at_evidence_write_base
integration_code_commit
evidence_write_base_commit
prompt_hash
design_freeze_hash
component_freeze_hash
timing_freeze_hash
final_candidate_freeze_hash
freeze_chain_hash
baseline_snapshot_hash
semantic_output_projection_hash
hook_allowlist_hash
cache_code_hash
trial_registry_hash
key_schema_hash
component_protocol_hash
component_schedule_hash
timing_protocol_hash
screening_schedule_hash
final_warm_schedule_hash
cold_lifecycle_schedule_hash
formal_warmup_registry_hash
canonical_mode_registry_hash
mode_alias_registry_hash
precedence_hash
fallback_hash
candidate_model_registry_hash
representative_alias_rule_hash
final_measurement_candidate_hash
final_measurement_candidate_alias_id
final_measurement_candidate_canonical_mode_id
recommended_runtime_mode_after_screening
screening_status
MATLAB_release
single_comp_thread
trial_count
measurement_identity_count
canonical_cache_mode_ids
admitted_layers
rejected_layers
correctness_status
performance_status
cold_build_point_status
cold_load_point_status
cold_build_break_even_status
cold_load_break_even_status
frozen_model_id
frozen_model_hash
frozen_model_status
model_residual_status
deployment_status
final_recommendation_status
layer_set_retention_status
final_recommended_experiment_mode
final_production_default_cache_setting
final_enabled_layers
result_hashes
completion_status
```

Manifest 不得把 `integration_code_commit` 误命名为 evidence final commit。
包含自身内容的 evidence commit 无法无循环地写入自身 manifest；
`evidence_artifact_commit` 由 final response 和 Git 记录，不伪造在 manifest
中。同理，manifest 只保存 evidence write base 时的 ledger hash；append
final evidence commit 后得到的 `final_stage_commit_ledger_hash` 只在 final
response/runtime ledger 报告，不回写并 amend evidence commit。

result hashes 使用 domain-separated stable SHA-256。

---

# 27. Regression 与新增 test suite

必须运行既有：

```text
stage8_k2_tcc_run_tests
expected: 8/8 PASS
```

必须保留：

```text
42/42 singles
462/462 pairs
882/882 ordered nested
72/72 query/trajectory
```

必须新增以下 runner：

```text
stage8_k2_tecs_run_tests
stage8_k2_tecs_run_exposure_audit
stage8_k2_tecs_run_shadow_validation
stage8_k2_tecs_run_screening
stage8_k2_tecs_run_final_validation
stage8_k2_tecs_write_evidence
```

新增 suite 至少覆盖：

```text
key completeness
collision
identity invalidation
observation invalidation
scope isolation
miss fallback
failure injection
cache corruption
immutable value
logical vs physical counters
cold/warm reset
memory accounting
checkpoint corruption
resume mismatch
CACHE_OFF exact baseline
each cumulative mode correctness
```

---

# 28. Hard Stops

以下任一发生立即停止对应后续 pass：

```text
BASELINE_ANCESTRY_MISMATCH_STOP
REMOTE_DIVERGENCE_STOP
UNEXPECTED_POST_BASELINE_CODE_CHANGE_STOP
RESUME_PROVENANCE_MISMATCH_STOP
BASELINE_SNAPSHOT_MISSING_ON_RESUME_STOP
UNEXPECTED_DIRTY_OVERLAP_STOP
REQUIRED_INPUT_MISSING_OR_MISMATCH_STOP
DESIGN_FREEZE_INCOMPLETE_STOP
FREEZE_CHAIN_MISMATCH_STOP
COMPONENT_FREEZE_INVALIDATED_STOP
HOOK_ALLOWLIST_VIOLATION_STOP
FROZEN_CORE_HASH_DRIFT_STOP
NO_ADDITIVE_CACHE_SEAM_STOP
CACHE_OFF_BASELINE_MISMATCH_STOP
C1_KEY_DEPENDENCY_INCOMPLETE_STOP
INTEGRATED_KEY_COLLISION_STOP
C1_PURITY_OR_SIDE_EFFECT_FAILURE_STOP
INTEGRATED_TRUTH_LEAKAGE_STOP
C1_OR_INTEGRATED_STATIC_CERTIFICATION_FAILURE_STOP
SHADOW_NUMERIC_OR_DECISION_MISMATCH_STOP
SCREENING_NOOP_CONTROL_MISMATCH_STOP
TRIAL_IDENTITY_CARDINALITY_MISMATCH_STOP
CACHE_SCOPE_GROWTH_STOP
NO_RUNNABLE_CACHE_ON_MODE_STOP
CANONICAL_MODE_REGISTRY_AMBIGUITY_STOP
STAGE_RECONCILIATION_FAILURE_STOP
CHECKPOINT_IDENTITY_MISMATCH_STOP
RUNTIME_PAIR_INCOMPLETE_STOP
```

C2-C4/C5R/C5P/C6/C7 在 Pass A 的 dependency/purity/exposure failure 是
layer rejection；同一问题若发生在已 admission/integrated path，或任何实际
hit 出现 collision/truth leakage，则属于上述 integrated hard stop。

以下不是 hard stop，而是合法研究结论：

```text
NO_EXACT_REUSE_EXPOSURE
PREDICTED_NET_NONPOSITIVE_LAYER
MEASURED_CACHE_STACK_INCONCLUSIVE
MEASURED_CACHE_STACK_NONPOSITIVE
NO_BREAK_EVEN_IN_TESTED_HORIZON
```

Hard stop 后不得通过改算法、放宽 tolerance、改变 trial、删异常样本或
降低 key 严格性绕过。

---

# 29. Git 修改范围

允许新增：

```text
tools/stage8_k2_tangent_exact_cache_stack/**
innovation-mining/53_stage8_k2_tangent_exact_cache_stack_*
```

允许最小修改：

```text
only exact existing paths frozen in Pass 0 allowed_hook_paths.csv
tests under tools/stage8_k2_tangent_exact_cache_stack/**
```

`existing runner/provider/orchestrator/context` 不是通配许可。未出现在 frozen
hook CSV 的 existing path 一律禁止修改。

禁止：

```text
G/score/rank/search mathematical function edits
51_* evidence edits
52_* evidence edits
unrelated refactor
format-only churn
archive cleanup
README rewrite not required by this stage
```

每次提交前执行：

```powershell
git status --short
git diff --check
git diff --name-status
git diff --stat
```

只 stage 精确任务路径。

---

# 30. Commit 与 Push

固定逻辑提交：

```text
1. test(stage8-k2): audit exact cache stack exposure and contracts
2. feat(stage8-k2): integrate exact cache stack behind frozen flags
3. perf(stage8-k2): validate exact cache stack runtime and evidence
```

Phase-to-commit mapping 固定为：

```text
commit 1:
    after Pass A + Pass B prototype static certification
    before COMPONENT_FREEZE closes and before any component replay sample
    contains audit/prototype/test code only; no raw runtime

COMPONENT_FREEZE:
    records pushed commit 1 as component_prototype_commit

commit 2:
    after component admission + Pass C + Pass D
    after POST_HOOK_CACHE_OFF_QUALIFICATION and all integrated-mode correctness
    before TIMING_FREEZE and before any screening sample

commit 3:
    after Pass F/lifecycle/Pass G and all evidence checks
    contains final aggregate 53_* evidence; no raw runtime/checkpoint
```

Commit 1 必须先 push 且 local/remote 相等，才允许 component replay。Commit 2
必须先 push 且 local/remote 相等，才允许 screening/final/lifecycle runtime。
commit 1 后不得修改 benchmarked component core；commit 2 后不得修改任何
timed code。若修改，按 freeze invalidation hard stop 处理。

若 hard-gate 修复确有必要，可单独提交，并在 stage commit ledger 记录 reason；
不得 amend、squash 或重写 ledger 已记录 commit。

commit 1/2 成功后必须原子 append `stage_commit_ledger.json`，记录 parent/tree/
phase/exact paths/hashes，再以非 force-push 推送；长 runtime 只在 code/test
commit 已 push 且 local HEAD == origin branch 后开始。raw runtime 不提交。

最终：

```powershell
git push origin experiment/stage8-k2-tangent-canonical-cache-v1
```

禁止 force push。

每次 push 前 fetch。若 remote 不是 ledger 中最近一次 `pushed_commit`，且该
前移不是本 run 已记录的 commit：

```text
REMOTE_DIVERGENCE_STOP
```

不得自行 rebase/merge。

---

# 31. 最终报告必须包含

## A. Git

```text
branch
baseline commit
initial execution start commit
current resume/final HEAD
run ID and stage commit ledger hash
integration code commit
evidence write base commit
actual evidence artifact commit
remote/local equality
preserved unrelated worktree changes
```

## B. Theory

必须区分：

```text
0.600809% conditional direct-G -> lookup
3.715591% C1 + structural gross zero-C2-C4-overhead hypothesis
3.765156% above + zero-incremental-C5R-hit-cost gross hypothesis
3.952132% additive known-exposure G-dictionary zero-lookup ceiling
4.001697% additive known-exposure primitive zero-hit-cost ceiling
4.345031% prior structural+G-only+cache model, not cache-only target
```

## C. Exposure & Purity

每 layer 的 N/U/H、weighted reuse、scope、key completeness、purity、
admission/rejection。

## D. Correctness

static、72-trial trajectory、truth isolation、CACHE_OFF baseline、
各 mode 状态。

## E. Screening

所有 variants 的 isolated/cumulative point、memory、selection rule 和冻结
final measurement candidate；另列 screening 后 recommended runtime mode。

## F. Final measured runtime

paired 72x20、AB/BA、identity/overall point/lower、runtime reduction、
speedup ratio。

## G. Lifecycle

COLD_BUILD、COLD_LOAD、WARM、memory、break-even curves。

## H. Model residual

measured vs frozen model，以及非 causal 的 runtime interaction residual。

## I. Decision

```text
correctness status
performance status
cold build point/break-even status
cold load point/break-even status
deployment status
final recommendation status
layer set retention status
retained layers
rejected layers
final recommended experiment mode
final production default cache setting
recommended next action
```

---

# 32. 最终推荐 taxonomy

`FINAL_RECOMMENDATION_STATUS` 必须且只能取一个：

```text
RECOMMEND_PRODUCTIONIZATION_STUDY
RETAIN_EXPERIMENTAL_EXACT_CACHE_STACK
DO_NOT_RETAIN_NONPOSITIVE_LAYERS
```

唯一映射：

```text
MEASURED_CACHE_STACK_ROBUST_POSITIVE
    -> RECOMMEND_PRODUCTIONIZATION_STUDY

MEASURED_CACHE_STACK_INCONCLUSIVE
    -> RETAIN_EXPERIMENTAL_EXACT_CACHE_STACK

MEASURED_CACHE_STACK_NONPOSITIVE
    -> DO_NOT_RETAIN_NONPOSITIVE_LAYERS
```

`LAYER_SET_RETENTION_STATUS` 独立且只能取一个：

```text
RETAIN_ONLY_SUBSET_OF_LAYERS
RETAIN_ALL_LAYERS_IN_FROZEN_CANDIDATE
NO_RUNTIME_CACHE_LAYER_RETAINED
```

对 final candidate (c) 先构造唯一 branch-compatible maximum universe
`U(c)`：C5R branch 排除 C5P；C5P branch 排除 C1/C5R 并保留 C5P；无 C5
branch 排除 C5R/C5P。然后加入该 branch 中所有状态为 `INTEGRATED` 且依赖
完整的 C1-C4/C6/C7。若 robust-positive candidate 的 enabled set 是 `U(c)`
的严格子集，取 `RETAIN_ONLY_SUBSET_OF_LAYERS`；否则取
`RETAIN_ALL_LAYERS_IN_FROZEN_CANDIDATE`。INCONCLUSIVE/NONPOSITIVE 一律取
`NO_RUNTIME_CACHE_LAYER_RETAINED`。per-layer disposition 继续保留 admission/
rejection reason，不得用这个 summary 覆盖。

Final 数据覆盖 screening 推荐：

```text
if performance_status == MEASURED_CACHE_STACK_ROBUST_POSITIVE:
    FINAL_RECOMMENDATION_STATUS = RECOMMEND_PRODUCTIONIZATION_STUDY
    FINAL_RECOMMENDED_EXPERIMENT_MODE = FROZEN_FINAL_MEASUREMENT_CANDIDATE
elif performance_status == MEASURED_CACHE_STACK_INCONCLUSIVE:
    FINAL_RECOMMENDATION_STATUS = RETAIN_EXPERIMENTAL_EXACT_CACHE_STACK
    FINAL_RECOMMENDED_EXPERIMENT_MODE = M0
else:
    FINAL_RECOMMENDATION_STATUS = DO_NOT_RETAIN_NONPOSITIVE_LAYERS
    FINAL_RECOMMENDED_EXPERIMENT_MODE = M0

FINAL_PRODUCTION_DEFAULT_CACHE_SETTING = CACHE_OFF
```

INCONCLUSIVE 可以保留代码/证据供后续研究，但 runtime recommendation 仍为
M0。禁止继续输出没有数值判据的 `EXACT_CACHE_ONLY_ROUTE_NEAR_MEASURED_LIMIT`；
只报告 measured reduction、matched model（若有）和每层剩余 zero-cost
headroom。

仍不得直接输出：

```text
DEPLOYMENT_JUSTIFIED
PRODUCTION_DEFAULT_CACHE_ON
TANGENT_CONTINUOUS_CORE_ACCELERATED_BY_CANONICAL_CACHE
CAUSAL_CACHE_TANGENT_SYNERGY
```

---

# 33. Completion 状态

成功完成全部允许 pass：

```text
STAGE8_K2_TANGENT_EXACT_CACHE_STACK_VALIDATION_COMPLETE
```

若 C2-C4 或 optional layers 无 exposure/未通过 admission，只要每层完成
audit disposition、C1 完成 integration、所有 admitted modes 完成 correctness/
timing，不影响 completion。不得要求 rejected layer 伪装成已集成 M0-M4。

若 screening 后 recommended runtime mode 为 M0，仍须按第 18.3 节冻结最佳
可运行 cache-on candidate 并完成 final measurement；最终可完成并输出
NONPOSITIVE 或 INCONCLUSIVE。完成表示研究闭环，不表示 cache 成功。

Hard stop：

```text
STAGE8_K2_TANGENT_EXACT_CACHE_STACK_BLOCKED_<REASON>
```

必须附可复现诊断。

---

# 34. 最终执行原则

1. 先冻结，再测 exposure；
2. 先证明 complete key 与 purity，再实现 hit bypass；
3. 先 shadow，再 integration；
4. 先 screening 冻结 final measurement candidate，再跑 final；
5. 使用 paired measured runtime，不用 microbenchmark 冒充端到端；
6. cold/warm/build-inclusive 分开；
7. 不把 conditional 0.6008%、cache-only model point 和 zero-cost ceiling
   混为同一结论；
8. 不为追求 4% 放宽 exact key；
9. 不改 G、score、rank、search 和 Tangent 数学核心；
10. 只提交聚合证据，保留 raw runtime 在仓库外；
11. 保护用户已有工作树变更；
12. 除 hard stop 外，不得只交付计划，必须执行到测试、证据、commit 和
    非 force-push push 完成。
