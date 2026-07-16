# 符号表

| 符号 | 含义 | 备注 |
| --- | --- | --- |
| $Y$ | 阵元域观测矩阵 | 多快拍接收数据 |
| $Z$ | 波束域观测矩阵 | $Z=W^{H}Y$ |
| $W$ | 波束矩阵 | 后端 ML 的波束输入选择矩阵 |
| $A_{\mathrm{cyl}}$ | 圆柱阵导向矩阵 | 由真实阵列流形构造 |
| $G(\Theta)$ | 波束域导向矩阵 | $G(\Theta)=W^{H}A_{\mathrm{cyl}}(\Theta)$ |
| $P_G$ | $G$ 的列空间投影矩阵 | $P_G=G(G^{H}G)^{-1}G^{H}$ |
| $\Theta$ | 双目标角度参数集合 | 包含方位角、俯仰角与分离参数 |
| az | 方位角 | 单位通常为度 |
| el | 俯仰角 | 单位通常为度 |
| $az_c$ / $el_c$ | 局部中心方位角 / 俯仰角 | controlled pair2d 局部中心 |
| $\Delta_{az}$ / $\Delta_{el}$ | 双目标方位 / 俯仰分离 | 与局部窗口半宽区分 |
| $\Delta_{az}^{\mathrm{win}}$ | 局部搜索窗口方位半宽 | 限定 $az_i$ 搜索范围 |
| $\Delta_{el}^{\mathrm{win}}$ | 局部搜索窗口俯仰半宽 | 限定 $el_i$ 搜索范围 |
| $q\in\{+1,-1\}$ | controlled pair2d 方向变量 | 表示方位排序下俯仰分离方向 |
| el_sep | 俯仰分离参数 | Step11.3 使用 degree-based 形式 |
| topK | 粗搜索保留候选数 | coarse-to-fine 的筛选参数 |
| $B$ | 选取波束数 | Step11.2 推荐 $B=7$ |
| $J(\Theta)$ | DML 搜索准则 | 越大表示拟合越优 |
| $U_{\mathrm{search}}$ | 搜索预算不确定度 | C05 自适应搜索预算指标 |
| $U_{\mathrm{confidence}}$ | 置信度不确定度 | 与 $U_{\mathrm{search}}$ 解耦 |
| $G_{\mathrm{cache}}(\delta_{az},el)$ | canonical beamspace manifold cache | exact-grid lookup，不插值 |
| candidate ratio | 候选压缩比 | adaptive / fixed 或 coarse / full 的候选数比例 |
| RMSE | 均方根误差 | 用于测角误差评价 |
| boundary hit | 边界命中率 | 用于判断搜索窗口是否触边 |
