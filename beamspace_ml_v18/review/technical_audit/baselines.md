# Baselines

| 方法 | 论文名称 | 代码实现 | 是否公平 | 备注 |
|---|---|---|---|---|
| common-elevation ML | common-el baseline | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/search_pair_grid_common_el_precomputed.m` | 待审 | 低复杂度 baseline；受共俯仰约束限制 |
| controlled pair2d beamspace ML | 本文主算法 | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/search_pair_grid_el_separation_precomputed.m`；后续 Step11.3/5/6/7 search/backend | 主方法 | 需确认候选集合、网格、whitening、W 与 baseline 匹配 |
| local full4D beamspace ML | full4D upper-bound reference | `E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_11_1_beamspace_ml_validation/common/search_pair_grid_full4d_precomputed.m` | 待审 | 只作局部上界参考，不作默认工程算法 |
| beam-index smoothing MUSIC | 旧 baseline / 前期路线 | Step7 相关目录：`E:/matlab_code/bishe_quanxi/stepwise_signal_model/steps/step_07_5_space_smooth_beamspace_MUSIC_monte_carlo`；论文中还引用 Step11.1 final docs 的 Step7 comparison | 待审 | 需确认窗口、SNR、目标条件是否与 Step11 对比公平 |
| regular 3dB beam grid | W selection fallback/reference | `build_existing_2d_beam_pool.m`、`select_regular_center_beams_from_pool.m` | 待审 | 论文表述应为 fallback/reference，不应与 greedy/SVD 混淆 |
| greedy_projection | W selection candidate | `select_w_greedy_from_pool.m` | 待审 | 需确认 projection loss 指标定义 |
| greedy_lowcorr | W selection candidate | `select_w_greedy_from_pool.m` | 待审 | 需确认 max corr 指标定义 |
| greedy_combined | W selection candidate/recommended | `select_w_greedy_from_pool.m` | 待审 | 推荐为 `greedy_combined_B7`；需限定当前 beam pool 和场景 |
| SVD upper bound | W design upper-bound/reference | `build_svd_beamspace_basis.m` | 待审 | 只应作为上界参考，不应写成工程可直接替代 |
| full fine search | fixed topK3 的 reference | `search_pair2d_full_fine_grid.m` | 待审 | Step11.3 用于验证 coarse-to-fine 一致性 |
| fixed topK3 | C05 baseline/control | `search_pair2d_coarse_to_fine.m`；Step11.5 C01 control config | 待审 | C05 的直接对比对象 |
| C05 adaptive | adaptive budget policy | Step11.5 policy tuning / backend | 待审 | 不改变 DML score，只改变 topK/window |
| direct manifold construction | cache reference | Step11.6/7 direct backend | 待审 | 与 cached lookup 对照估计/score/policy 一致性 |
| cached lookup/backend | 工程加速方法 | Step11.6 cache + Step11.7 final backend | 待审 | 只在 exact-grid/shared-center/canonical order 条件下成立 |

## 公平性核查清单

- common-el、pair2d、full4D 是否使用同一 `Y`、同一 `W`、同一 whitening/regularization、同一局部窗口。
- W selection 对比是否使用相同 scenario set、SNR、Metkl、success tolerance。
- fixed topK3 与 full fine 是否使用相同 DML score 和 W。
- C05 与 fixed topK3 是否只改变 topK/window，未改变 score、W、candidate scoring criterion。
- cache 与 direct 是否只改变 manifold construction path，未改变 candidate grid、score 和 policy。
- 代表性案例图是否明确不是主统计证据。

