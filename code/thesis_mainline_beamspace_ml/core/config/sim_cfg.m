function cfg = sim_cfg()
%SIM_CFG 波束域 ML 主线所需的阵列与局部波束配置。

cfg = struct();

% 阵列参数。
cfg.arr = struct();
cfg.arr.fc = 10e9;
cfg.arr.c = 3e8;
cfg.arr.lambda = cfg.arr.c / cfg.arr.fc;
cfg.arr.Naz = 192;
cfg.arr.Nel = 32;
cfg.arr.R = 0.4;
cfg.arr.dz = 17e-3;
cfg.arr.dPhi = 360 / cfg.arr.Naz;

% 波束形成参数。
cfg.beam = struct();
cfg.beam.sectorHalf = 60;
cfg.beam.subNaz = 2 * floor(cfg.beam.sectorHalf / cfg.arr.dPhi) + 1;
cfg.beam.elBeamMinDeg = -5;
cfg.beam.elBeamMaxDeg = 60;
% phaseFactor = 2 表示导向相位按双程传播模型构造。
cfg.beam.spatialPhaseFactor = 2;

% 默认局部搜索中心；运行时由前端粗中心覆盖方位值。
cfg.beam.azSectorCenter = 8;
cfg.beam.elSectorCenter = 10;

end
