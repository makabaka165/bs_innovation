# Claim Table

| 主张ID | 论文主张 | 论文位置 | 支撑公式/算法 | 支撑图表 | 支撑代码 | 状态 |
|---|---|---|---|---|---|---|
| C1 | 本文研究对象限定为前端检测后的局部未分辨双目标 beamspace ML 后端，不覆盖完整前端闭环/全空域盲搜/自动单双目标选择 | 摘要/第1章/第6章边界 | 问题设定、local window | 图 1-1、图 2-1、表 6-9 | Step11.7 backend input contract | 已定位，待核对全文是否无越界表述 |
| C2 | 使用真实圆柱阵流形构造 `a_cyl(az,el)` 和 `G(Theta)=W^H A_cyl(Theta)` | 第2章 | 圆柱阵 steering vector、beamspace projection | 图 2-1 | `build_cyl_steering_vec.m`、`build_cyl_pair_manifold_*.m` | 待审 |
| C3 | controlled pair2d 降低局部双目标搜索维度，同时保留小俯仰分离建模能力 | 摘要/第3章 | pair2d 参数化、DML score | 图 3-1、图 3-2、图 6-1 | `search_pair_grid_el_separation_precomputed.m`、`beamspace_dml_score.m` | 待审 |
| C4 | common-el 只作为 baseline，full4D 只作为 local upper-bound reference | 第3/6章 | common-el / pair2d / full4D 对照 | 图 6-1、表 6-3 | `search_pair_grid_common_el_precomputed.m`、`search_pair_grid_full4d_precomputed.m` | 已定位，待复算 |
| C5 | recorded scenarios 中 controlled pair2d 与 full4D 上界取得相同最佳 joint success，full4D/pair2d complexity proxy 约 3.96 | 摘要/第6章 | Stage6 full4D comparison | 图 6-1、表 6-3 | Step11.1 final key metrics | 已定位，待复算 |
| C6 | greedy_combined_B7 是当前后端推荐 W，且 beam 数不是越多越好 | 摘要/第4/6章 | W selection / B-budget | 图 4-1、图 6-2、表 6-4 | `select_w_greedy_from_pool.m`、Step11.2 B-budget CSV | 已定位，待复算 |
| C7 | fixed topK3 coarse-to-fine 在保持 full fine 一致性的同时降低候选评分数 | 第5/6章 | coarse topK + local refine | 图 5-1、图 6-3、表 6-5 | `search_pair2d_coarse_to_fine.m`、Step11.3 final metrics | 已定位，待复算 |
| C8 | fixed topK3 将候选数从 131461 降到平均 19161.9，约 6.86 倍 | 摘要/第6章 | Step11.3 evidence summary | 图 6-3、表 6-5 | `step11_3_final_key_metrics.csv` | 已定位 |
| C9 | C05 只调配搜索预算，不改变 DML score、W 或候选评分准则 | 第5/6章 | likelihood landscape features + policy | 图 5-2、图 6-4 | Step11.5 common/policy functions | 待审 |
| C10 | C05 相对 fixed topK3 进一步降低候选数，同时 full-grid match=1、topK miss=0、boundary hit=0 | 摘要/第6章 | Step11.5 Stage2/Stage3 validation | 图 6-4、表 6-6 | Step11.5 policy summary、Metkl=30 recheck | 已定位，待复算 |
| C11 | Metkl=30 多 seed 复验 450 trials 保持 full-grid match=1、topK miss=0、boundary hit=0，最大 candidate ratio 约 0.7151 | 摘要/第6章 | Step11.5 supplementary rechecks | 表 6-6 | `run_step11_5_stage3_supplementary_rechecks.m` | 已定位，待复算 |
| C12 | shared-center canonical cache 与 direct manifold 构造在估计、score、policy 上保持一致 | 第5/6章 | rotational equivalence、exact-grid lookup | 图 5-5、图 6-7、表 6-7 | Step11.6 cache validation | 待审 |
| C13 | Step11.6 cache 达到 max_rel_G_error 约 3.23e-14、same_estimate_rate=1、same_policy_rate=1、cache_miss_count=0 | 摘要/第6章 | Step11.6 summary | 图 6-7、表 6-7 | Step11.6 result CSV/MAT | 已定位，待复算 |
| C14 | Step11.7 final cached backend 与 direct C05 backend 在 estimate/policy/score 上一致，并降低 runtime | 摘要/第5/6章 | final cached backend integration | 图 5-6、图 6-7、表 6-7 | `step11_7_final_cached_c05_beamspace_ml_backend.m` | 待审 |
| C15 | strong-coherence worst cases 和 false-high-like risks 没有完全解决，结论必须保留边界 | 摘要/第6/7章 | coherence stress | 图 6-6/边界图、表 6-9 | Step11.1 Stage5 coherence stress metrics | 已定位，需确认正文降调 |
| C16 | ILL_CONDITIONED 真实搜索未自然触发，仅 guard probe 通过 | 摘要/第6/7章 | C05 guard probe | 表 6-6/6-9 | Step11.5 Stage3 supplementary rechecks | 已定位，需核对是否全篇一致 |
| C17 | 本文不宣称 FPGA 下板或完整实时系统闭环完成 | 摘要/第6/7章 | 边界声明 | 表 6-9 | 无直接算法代码支撑，属于论文边界 | 已定位，需核对全文 |

## 初步降调建议

| 主张ID | 需要降调/精确化的点 |
|---|---|
| C5 | “达到 full4D 上界”应限定为 recorded scenarios / main comparison subset，不应写成普遍等价。 |
| C6 | “B7 最优”应限定为当前 beam pool、代表场景和当前 backend ML estimator，不应写成通用最优。 |
| C10 | “C05 安全”应写成当前验证集 full-grid match/topK/boundary 指标通过，不应写成所有场景保证。 |
| C12 | cache 等价应限定 exact-grid lookup、shared-center canonical local order、W 排列匹配。 |
| C14 | runtime 降低应说明 MATLAB runtime 包含函数调度和 DML scoring，收益来源是 repeated manifold construction/cache path。 |

