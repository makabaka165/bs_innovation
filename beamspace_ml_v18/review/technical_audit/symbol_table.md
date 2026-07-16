# Symbol Table

| 符号 | 含义 | 维度 | 代码变量 | 首次定义位置 | 是否一致 |
|---|---|---|---|---|---|
| `az` | 方位角 | scalar | `az_deg`、`az_pair_deg`、`az_center_true` | 第2章 | 待审 |
| `el` | 俯仰角 | scalar | `el_deg`、`el_pair_deg`、`el_center_nominal` | 第2章 | 待审 |
| `p_m` | 第 m 个阵元坐标 | `3 x 1` | `x`,`y`,`z` 或 `arrInfo.xActVec` 等 | 第2章 | 待审 |
| `u(az,el)` | 入射方向单位向量 | `3 x 1` | 在 `build_cyl_steering_vec.m` 内隐式计算 | 第2章 | 待审 |
| `a_cyl(az,el)` | 圆柱阵导向矢量 | `M x 1` | `a`、`build_cyl_steering_vec` 输出 | 第2章 | 待审 |
| `A_cyl(Theta)` | 双目标导向矩阵 | `M x 2` | `A_pair` | 第2章 | 待审 |
| `Theta` | 双目标角度参数集合 | pair2d 或 full4D 参数集 | `az_pair_deg`、`el_pair_deg`、candidate structs | 第2/3章 | 待审 |
| `Y` | 阵元域观测矩阵 | `M x L` | `Y`、`Y_work` | 第2章 | 待审 |
| `S` | 双目标源信号矩阵 | `2 x L` | `S` 或 snapshot generator 内部变量 | 第2章 | 待审 |
| `N` | 噪声矩阵 | `M x L` | noise variables | 第2章 | 待审 |
| `W` | beamspace 投影矩阵 | 论文应统一为 `M x B` | `W` | 第2/4章 | 待审：确认是否全篇写成 `W^H Y` |
| `Z` | beamspace 观测 | `B x L` | `Z` | 第2/3章 | 待审 |
| `G(Theta)` | beamspace 流形 | `B x 2` | `G`、`G_grid`、`G_cache` | 第2/3章 | 待审 |
| `P_G` | DML 投影矩阵 | `B x B` | `beamspace_dml_score.m` 内部投影/score | 第3章 | 待审 |
| `J(Theta)` | DML 评分函数 | scalar | `score` | 第3章 | 待审 |
| `az_c` | 局部中心方位 | scalar | `az_center_true`、`coarseAz`、`selectedCenterAz` | 第3/5章 | 待审 |
| `el_c` | 局部中心俯仰 | scalar | `el_center_nominal`、`coarseEl` | 第3/5章 | 待审 |
| `Delta az` | 双目标方位分离 | scalar | `az_sep_deg` | 第3章 | 待审 |
| `Delta el` | 双目标俯仰分离 | scalar | `el_sep_deg` | 第3章 | 待审 |
| `q` | pair2d orientation/sign | `+1/-1` | `search_orientations` 或 orientation 字段 | 第3章 | 待审 |
| `B` | beamspace 维度/波束数 | scalar | `B`、`w_info.B` | 第4章 | 待审 |
| `K` | topK 数 | scalar | `topK`、`recommended_topK` | 第5章 | 待审 |
| `K_max` | C05 coarse topK 上限 | scalar | `topK_max` | 第5章 | 待审 |
| `U_search` | 搜索预算不确定度 | scalar | `U_search` 或 feature/policy 字段 | 第5章 | 待审 |
| `U_confidence` | 置信度不确定度 | scalar | `U_confidence` 或 feature/policy 字段 | 第5章 | 待审 |
| `G_cache(delta_az,el)` | canonical beamspace manifold cache | indexed tensor/table | `cache`、`G_cache` | 第5章 | 待审 |
| `lambda` | 波长 | scalar | `cfg.arr.lambda` | 第2章 | 待审 |
| `rho` | 目标相干系数 | scalar | `rho` | 第6章 | 待审 |
| `Metkl` | Monte Carlo 次数 | scalar | `Metkl` | 第6章 | 待审 |

## 符号高风险项

| 项 | 风险 | 核查动作 |
|---|---|---|
| `W` 维度 | 论文可能同时出现 `M x B` / `B x M` 口径 | 全文搜索 `W`、`W^H`、`Z=`，统一描述 |
| `M` | 有全阵 `6144` 和工作子阵 `2080` 两个口径 | 明确第2章 `M` 指当前工作子阵还是全阵 |
| `Theta` | common-el、pair2d、full4D 的参数维度不同 | 在第3章表格中分模型列出 |
| `U_search` / `U_confidence` | 可能是概念名，不一定与代码字段完全同名 | 对照 Step11.5 policy feature code |
| `q` orientation | 论文图示 q 与代码 orientation 枚举需一致 | 对照 `search_pair_grid_el_separation_precomputed.m` 和 Step11.3 search code |

