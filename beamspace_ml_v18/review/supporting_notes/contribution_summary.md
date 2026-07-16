# 核心创新点总结

## 创新点 1：圆柱阵真实流形驱动的 controlled pair2d beamspace ML 建模

- 问题：beam-index smoothing MUSIC 依赖波束索引域平滑，对圆柱阵真实阵列流形与双目标局部未分辨结构的表达有限。
- 方法：在波束域中保留圆柱阵物理导向矢量，构造受控二维参数化的双目标 ML 搜索模型。
- 关键公式：

$$
G(\Theta)=W^{H}A_{\mathrm{cyl}}(\Theta)
$$

$$
J(\Theta)=\mathrm{tr}\left(P_GZZ^{H}\right)
$$

- 关键实验结果：Step11.1 中 controlled pair2d 在关键场景下达到与 full4D 接近的成功率，同时候选数明显低于 full4D。
- 局限性：该建模仍依赖前端粗中心与受控分离参数，不能宣称解决所有强相干边界场景。

## 创新点 2：基于已有二维波束池的 greedy_combined_B7 波束矩阵选择

- 问题：高维波束输入可提升信息保持能力，但会增加后端计算负担；过少波束又可能损失目标可分辨信息。
- 方法：在已有二维波束池中综合投影损失与相关性指标，选择 greedy_combined_B7 作为后端 ML 输入。
- 关键公式：

$$
Z=W^{H}Y
$$

- 关键实验结果：Step11.2 的 B-budget 与 robustness 结果支持 B=7 greedy_combined 作为复杂度与性能之间的折中方案。
- 局限性：SVD 只作为信息保持上界，不写成工程可直接实现波束；推荐 W 仍需结合硬件波束池约束复核。

## 创新点 3：低复杂度搜索 + 流形缓存工程链

- 问题：full fine 网格候选数高，直接用于后端 ML 会造成较大搜索代价；同时 repeated steering / manifold construction 会增加工程运行开销。
- 方法：将 degree-based fixed topK3 coarse-to-fine、C05 似然地形感知自适应搜索预算预估、shared-center canonical manifold cache 合并为一条低复杂度后端工程链；Step11.7 final backend 只作为接口闭合与集成验证，不单列为独立创新点。
- 关键公式：

$$
\widehat{\Theta}=\arg\max_{\Theta\in\Omega_{\mathrm{local}}}J(\Theta)
$$

- 关键实验结果：Step11.3 中候选数由 full fine 的 131461 降到约 19161.9；Step11.5 中 C05 validation 候选数比例约 0.7136；Step11.6/Step11.7 中 cache 与 final backend runtime reduction 分别约 0.8604 / 0.6184。
- 局限性：coarse-to-fine 不能写成 AP；C05 和 cache 不能宣称完整前端工程闭环已经完成，也不能宣称 FPGA 下板或全空域盲搜索已经完成。
