# Parameter Table

| 参数 | 符号 | 代码变量名 | 论文位置 | 数值/范围 | 单位 | 备注 |
|---|---|---|---|---|---|---|
| 载频 | `f_c` | `cfg.arr.fc` | 第2章/实验设置 | `10e9` | Hz | 来源：`core/config/sim_cfg.m`；需核对论文是否显式写出 |
| 光速 | `c` | `cfg.arr.c` | 第2章 | `3e8` | m/s | 来源：`sim_cfg.m` |
| 波长 | `lambda` | `cfg.arr.lambda` | 第2章 | `cfg.arr.c / cfg.arr.fc = 0.03` | m | Step11 代码主要使用 `lambda` |
| 圆柱阵方位列数 | `N_az` | `cfg.arr.Naz` | 第2章 | `192` | 列 | 全阵参数 |
| 圆柱阵垂直层数 | `N_el` | `cfg.arr.Nel` | 第2章 | `32` | 层 | 全阵参数 |
| 全阵阵元数 | `M_all` | `cfg.arr.Naz * cfg.arr.Nel` | 第2章 | `6144` | 个 | 论文主要图示常讨论工作子阵 |
| 工作子阵方位列数 | `N_az,sub` | `cfg.beam.subNaz` | 第2/6章 | `65` | 列 | 由 `sectorHalf=60` 与 `dPhi=360/192=1.875` 得到 |
| 工作子阵阵元数 | `M` 或 `N_elem` | `cfg.beam.subNaz * cfg.arr.Nel`、`arrInfo.nAct` | 第2/6章 | `2080` | 个 | 论文图中 `W in C^{2080 x 7}` 与此一致，待核对全文符号是否统一 |
| 圆柱半径 | `R` | `cfg.arr.R` | 第2章 | `0.4` | m | 来源：`sim_cfg.m` |
| 垂直间距 | `d_z` | `cfg.arr.dz` | 第2章 | `17e-3` | m | 来源：`sim_cfg.m` |
| 方位列间隔 | `Delta phi` | `cfg.arr.dPhi` | 第2章 | `1.875` | deg | `360 / cfg.arr.Naz` |
| 工作扇区中心方位 | `az_c` | `cfg.beam.azSectorCenter` | 第2/实验设置 | `8` | deg | 用作代表场景中心；前端粗中心假设需与论文边界一致 |
| 工作扇区中心俯仰 | `el_c` | `cfg.beam.elSectorCenter` | 第2/实验设置 | `10` | deg | 同上 |
| 双程相位因子 | - | `cfg.beam.spatialPhaseFactor` | 第2章公式 | `2` | - | 代码注释：双程传播模型；需核对论文公式是否体现该因子 |
| 快拍数 | `L` | `cfg_eval.L` | 第6章 | `64` | 个 | Step11.5/6/7 评估配置中明确出现 |
| Monte Carlo 次数 | `Metkl` | `cfg_eval.Metkl` / `params.Metkl` | 第6章 | 常用 `10`，补充复验 `30` | 次 | Step11.5 Metkl=30 多 seed 复验共 450 trials |
| 推荐 beamspace 维度 | `B` | `w_info.B`、`cfg_eval.B` | 第4/6章 | `7` | 维/束 | greedy_combined_B7 |
| 推荐 W 策略 | `W` | `w_info.criterion='combined'`、`params.W_method` | 第4/6章 | `greedy_combined_B7` | - | Step11.2/5/6/7 共同使用 |
| SNR 场景 | `SNR` | `snr_db` | 第6章 | 主比较常见 `30`；代表场景含 `20`、`30` | dB | 需逐脚本列出完整 sweep 范围 |
| 低 SNR 困难场景 | - | `make_scenario_local(..., snr_db=20)` | 第6章案例 | `20` | dB | Step11.5/6/7 representative scenario |
| strong coherent rho | `rho` | `rho` | 第6章边界/案例 | `1.00` 等 | - | 强相干 stress 有 worst-case 成功率为 0 的记录 |
| coarse 方位半宽 | - | `coarse_search_cfg.az_half_width` | 第5/6章 | `1.5` | deg | Step11.5/6 配置 |
| coarse 俯仰半宽 | - | `coarse_search_cfg.el_half_width` | 第5/6章 | `1.2` | deg | Step11.5/6 配置 |
| coarse 方位步长 | - | `coarse_search_cfg.az_step` | 第5/6章 | `0.16` | deg | Step11.3 recommended config |
| coarse 俯仰步长 | - | `coarse_search_cfg.el_step` | 第5/6章 | `0.24` | deg | Step11.3 recommended config |
| coarse el_sep 列表 | - | `coarse_el_sep_deg_list` | 第5/6章 | `[0, 0.36, 0.72]` | deg | Step11.3/5/6 配置 |
| fine 方位步长 | - | `fine_az_step` | 第5/6章 | `0.08` | deg | Step11.3 recommended config |
| fine 俯仰步长 | - | `fine_el_step` | 第5/6章 | `0.12` | deg | Step11.3 recommended config |
| fine el_sep 列表 | - | `fine_el_sep_deg_list` | 第5/6章 | `[0, 0.24, 0.36, 0.48, 0.60, 0.72]` | deg | Step11.3/5/6 配置 |
| fixed topK | `K` | `recommended_topK` | 第5/6章 | `3` | 个 | fixed topK3 |
| C05 topK max | `K_max` | `topK_max` | 第5/6章 | `7` | 个 | C05 粗候选上限 |
| C05 policy 名称 | - | `policy_cfg.config_name` | 第5/6章 | `C05_easy_very_aggressive` | - | 摘要/第6章需核对是否降调 |
| cache 内存 | - | `cache.cache_memory_MB` | 第5/6章 | 约 `2.08` | MB | 论文图/表使用，需回溯 Step11.6 metadata |

## 待补项

- 完整 SNR sweep 范围：目前只定位到主比较 `30 dB` 和代表场景 `20/30 dB`，需汇总所有 stage trial CSV。
- pair2d 角分离范围：需从各 stage 的 scenario builder 和 search grid 代码中统一抽取。
- C05 policy 阈值表：需从 Step11.5 policy config table 导入。
- 所有容差指标：joint success 的 az/el tolerance 尚未在本表中确认。

