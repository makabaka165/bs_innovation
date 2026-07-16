%% 圆柱阵波束级ML——目标
% 圆柱阵阵元坐标建模，生成无噪声阵元域接收信号，
% 再通过白化波束投影得到波束域输入，并在波束域按指定 SNR 加噪，用
% J(Theta)=tr(P_G Z Z^H) 完成ML


clear; clc; close all;
rng(7);

%% 1. 基本参数
cfg.fc = 8e9;                     % 载频
cfg.c = 3e8;                      % 光速
cfg.lambda = cfg.c / cfg.fc;      % 波长

cfg.Naz = 144;                    % 每层方位列数
cfg.Nel = 32;                     % 垂直层数
cfg.Rc = 0.4;                     % 半径，单位 m
cfg.dz = 16e-3;                   % 垂直层间距，单位 m
cfg.subNaz = 49;                  % 工作子阵方位列数

cfg.az0 = 8;                      % 局部方位中心
cfg.el0 = 10;                     % 局部俯仰中心
cfg.snapshots = 1;                % 快拍数
cfg.snr_dB = 18;                  % 白化波束域输入信噪比
cfg.mc_num = 300;                 % 每个目标间隔下的蒙特卡洛
cfg.num_el_beam = 10;             % 固定方位下选取的俯仰波束数
cfg.el_beam_step_ratio = 0.5;     % 相邻俯仰波束中心间隔0.5倍 3 dB 波束宽度
cfg.success_tol_bw_ratio = 0.1;   % 分辨成功的单目标测角误差容限0.1倍 3 dB 波束宽度
cfg.peak_min_power_ratio = 0.3;   % 波束扫描结果中有效峰的最低归一化功率
cfg.snr_list = -10:5:20;          % SNR-波束数对比实验的白化波束域输入 SNR 范围
cfg.snr_beam_counts = [10, 8, 6, 4, 2]; % SNR-波束数对比实验比较的波束数
cfg.snr_mc_num = 300;             % SNR-波束数对比实验的蒙特卡洛次数
cfg.snr_sep_ratio = 0.8;          % 实验二的目标间隔固定为0.8倍 3 dB 波束宽度
cfg.w_score_alpha = 12 / 25;      % 波束选择综合评分中的投影损失权重
cfg.w_score_beta = 12 / 25;       % 波束选择综合评分中的相关性权重
cfg.w_score_gamma = 1 / 25;       % 波束选择综合评分中的条件数权重
cfg.w_score_beam_counts = [10, 8, 6, 4, 2]; % 波束选择评分中比较的俯仰波束数
cfg.w_score_sep_ratio_list = 0.1:0.1:1.0; % 波束选择评分中比较的目标俯仰间隔
cfg.w_opt_beam_counts = cfg.w_score_beam_counts; % 候选池评分最优搜索中比较的波束数
cfg.w_opt_pool_step_ratio = 0.5;  % 候选波束池的俯仰间隔，单位为 3 dB 波束宽度
cfg.w_opt_pool_half_count = 6;    % 候选池在 el0 两侧各取的波束个数

cfg.result_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(cfg.result_dir, 'dir')
    mkdir(cfg.result_dir);
end

%% 2. 圆柱阵工作子阵建模
arr = build_cylindrical_work_array(cfg);
x = arr.xAct(:);
y = arr.yAct(:);
z = arr.zAct(:);
M = numel(x);

fprintf('圆柱阵全阵阵元数: %d x %d = %d\n', cfg.Naz, cfg.Nel, cfg.Naz * cfg.Nel);
fprintf('工作子阵阵元数: %d x %d = %d\n', cfg.subNaz, cfg.Nel, M);

%% 3. 测量工作子阵的俯仰向 3 dB 波束宽度
bw3dB_el = estimate_el_3db_width(x, y, z, cfg.az0, cfg.el0, cfg);
fprintf('工作子阵在 el0=%.2f deg 附近的俯仰向 3 dB 波束宽度约为 %.4f deg\n', cfg.el0, bw3dB_el);

%% 4. 构造固定方位下的 10 个俯仰波束矩阵 W
beam_az = cfg.az0;
% 构造俯仰方向的波束中心
beam_el = cfg.el0 + ((1:cfg.num_el_beam) - (cfg.num_el_beam + 1) / 2) ...
    * cfg.el_beam_step_ratio * bw3dB_el;
W = build_beam_matrix(x, y, z, beam_az, beam_el, cfg);
B = size(W, 2);

%白化
[beam_whitener, whiten_info] = build_beamspace_whitener(W);

fprintf('固定方位 az=%.2f deg，俯仰向选取 %d 个真实波束\n', beam_az, B);
fprintf('俯仰波束中心范围: %.4f deg 到 %.4f deg，间隔 %.2f BW3dB\n', ...
    min(beam_el), max(beam_el), cfg.el_beam_step_ratio);
fprintf('波束域输入维数: Z 为 %d x L，白化前 cond(W^H W)=%.3e\n', ...
    B, whiten_info.cond_Cb);

%% 5. 固定方位下的候选波束域流形 G(el)=W^H a_cyl(az0,el)
%固定方位 az0，在 el0 附近生成 161 个俯仰候选角

search_half_width = 0.80 * bw3dB_el;
el_grid = linspace(cfg.el0 - search_half_width, cfg.el0 + search_half_width, 161);
%阵元域导向矩阵
A_el_grid = build_steering_matrix(x, y, z, cfg.az0 * ones(size(el_grid)), el_grid, cfg);
%阵元域到波束域，并进行白化
G_el_grid = beam_whitener * (W' * A_el_grid);

%% 6. 以 0.1 到 1.0 倍 3 dB 波束宽度设置目标俯仰间隔
%0.1 到 1.0 倍
sep_ratio_list = 0.1:0.1:1.0;
%结果数组，分别保存：波束级 ML 的 RMSE；波束级 ML 的分辨成功率；波束扫描结果的分辨成功率
rmse_ml = zeros(size(sep_ratio_list));
resolution_ml = zeros(size(sep_ratio_list));
resolution_amp = zeros(size(sep_ratio_list));

single_case = struct();

for iSep = 1:numel(sep_ratio_list)
    sep_ratio = sep_ratio_list(iSep);
    %真是角度间隔
    el_sep = sep_ratio * bw3dB_el;
    %真实目标
    true_az = [cfg.az0, cfg.az0];
    true_el = [cfg.el0 - el_sep / 2, cfg.el0 + el_sep / 2];

    err_ml = zeros(cfg.mc_num, 1);
    resolve_ml = false(cfg.mc_num, 1);
    resolve_amp = false(cfg.mc_num, 1);

    %300次
    for iMc = 1:cfg.mc_num
        %无噪声阵元域接收信号
        Y_clean = simulate_two_target_clean_snapshots(x, y, z, true_az, true_el, cfg);
        %阵元域到白化波束域，并加指定 SNR 的复高斯噪声
        Zb = add_beamspace_noise(Y_clean, W, beam_whitener, cfg.snr_dB);

        %波束级最大似然搜索两个俯仰角
        %est_ml 是估计的两个俯仰角，score_map 是二维候选估计J(θ)
        [est_ml, score_map] = beamspace_ml_pair_el_search(Zb, G_el_grid, el_grid);

        %波束扫描结果
        %输出：
        % est_amp：波束扫描结果检测到的有效峰位置，可能少于两个
        % amp_curve：一维扫描功率曲线
        % amp_has_two_peaks：是否检测到两个有效峰
        [est_amp, amp_curve, amp_has_two_peaks] = beamspace_peak_pair_estimator(Zb, G_el_grid, el_grid, cfg);

        err_ml(iMc) = pair_rmse_deg(est_ml, true_el);
        resolve_ml(iMc) = is_resolution_success(est_ml, true_el, bw3dB_el, true, cfg.success_tol_bw_ratio);
        resolve_amp(iMc) = is_resolution_success(est_amp, true_el, bw3dB_el, amp_has_two_peaks, cfg.success_tol_bw_ratio);

        % 半个 3 dB 波束宽度，用于画图4
        if abs(sep_ratio - 0.5) < 1e-12 && iMc == 1
            single_case.true_el = true_el;
            single_case.est_ml = est_ml;
            single_case.est_amp = est_amp;
            single_case.score_map = score_map;
            single_case.amp_curve = amp_curve;
            single_case.el_grid = el_grid;
        end
    end

    rmse_ml(iSep) = sqrt(mean(err_ml.^2));
    resolution_ml(iSep) = mean(resolve_ml);
    resolution_amp(iSep) = mean(resolve_amp);

    fprintf('目标间隔 %.1f BW3dB: 波束级ML RMSE=%.4f deg, 分辨成功率=%.2f\n', ...
        sep_ratio, rmse_ml(iSep), resolution_ml(iSep));
end

%% 7. 不同 SNR、不同波束数 B 下，波束级 ML 的测角性能
rng(17);
snr_table = run_snr_beam_experiment(x, y, z, bw3dB_el, cfg);

%% 8. 评价不同 W 的选择评分
%比较规则排布波束，B=10、8、6、4、2，目标间隔为 0.2、0.4、0.6、0.8、1.0 BW
w_score_table = run_w_selection_score_experiment(x, y, z, bw3dB_el, cfg);
%穷举 B 个波束，找到评分最优的 W
w_opt_table = run_w_score_optimal_experiment(x, y, z, bw3dB_el, cfg);

%% 9. 绘图
plot_single_case(single_case, cfg);
plot_rmse_curve(sep_ratio_list, rmse_ml, resolution_ml, resolution_amp, cfg);
plot_snr_beam_result(snr_table, cfg);
plot_w_selection_score_result(w_score_table, cfg);
plot_w_score_optimal_metric_result(w_opt_table, cfg);
plot_w_score_optimal_beam_layout(w_opt_table, cfg);

fprintf('\n图像已保存到: %s\n', cfg.result_dir);

%% 局部函数：圆柱阵建模与波束域变换

function arr = build_cylindrical_work_array(cfg)
% 生成圆柱阵全阵坐标，并围绕 az0 选取连续 cfg.subNaz 个方位列作为工作子阵。
phi_col = (0:cfg.Naz-1) / cfg.Naz * 360;
z_row = (0:cfg.Nel-1) * cfg.dz;

X = zeros(cfg.Naz, cfg.Nel);
Y = zeros(cfg.Naz, cfg.Nel);
Z = zeros(cfg.Naz, cfg.Nel);
for iAz = 1:cfg.Naz
    X(iAz, :) = cfg.Rc * cosd(phi_col(iAz));
    Y(iAz, :) = cfg.Rc * sind(phi_col(iAz));
    Z(iAz, :) = z_row;
end

phi_rel = wrap180_local(phi_col - cfg.az0);
[~, col_ctr] = min(abs(phi_rel));
half_span = (cfg.subNaz - 1) / 2;
cols_act = mod((col_ctr-half_span-1):(col_ctr+half_span-1), cfg.Naz) + 1;

arr = struct();
arr.xAct = X(cols_act, :);
arr.yAct = Y(cols_act, :);
arr.zAct = Z(cols_act, :);
end

function bw3dB = estimate_el_3db_width(x, y, z, az0, el0, cfg)
% 半功率点定义当前工作子阵的俯仰向 3 dB 波束宽度。
el_axis = el0 + (-6:0.005:6);
a0 = steering_vec_cyl(x, y, z, az0, el0, cfg);
pattern = zeros(size(el_axis));
for i = 1:numel(el_axis)
    ai = steering_vec_cyl(x, y, z, az0, el_axis(i), cfg);
    pattern(i) = abs(a0' * ai).^2 / (norm(a0)^2 * norm(ai)^2);
end
pattern = pattern / max(pattern);

[~, i0] = min(abs(el_axis - el0));
i_left = find(pattern(1:i0) <= 0.5, 1, 'last');
i_right = i0 - 1 + find(pattern(i0:end) <= 0.5, 1, 'first');

el_left = interp_half_power(el_axis(i_left), pattern(i_left), el_axis(i_left+1), pattern(i_left+1));
el_right = interp_half_power(el_axis(i_right-1), pattern(i_right-1), el_axis(i_right), pattern(i_right));
bw3dB = el_right - el_left;
end

function x_half = interp_half_power(x1, y1, x2, y2)
% 在两个采样点之间线性插值得到 0.5 功率位置。
x_half = x1 + (0.5 - y1) * (x2 - x1) / (y2 - y1);
end

function W = build_beam_matrix(x, y, z, beam_az, beam_el, cfg)
% 构造固定方位下的真实俯仰波束矩阵。
% W 的每一列就是一个物理波束输出权向量。
W = zeros(numel(x), numel(beam_el));
for iEl = 1:numel(beam_el)
    a = steering_vec_cyl(x, y, z, beam_az, beam_el(iEl), cfg);
    W(:, iEl) = a / norm(a);
end
end

function [W, beam_whitener] = setup_el_beamspace(x, y, z, bw3dB_el, num_el_beam, cfg, step_ratio)
% 按指定俯仰波束数生成 W 以及对应的白化矩阵。
beam_az = cfg.az0;
beam_el = cfg.el0 + ((1:num_el_beam) - (num_el_beam + 1) / 2) ...
    * step_ratio * bw3dB_el;
W = build_beam_matrix(x, y, z, beam_az, beam_el, cfg);
beam_whitener = build_beamspace_whitener(W);
end

function [W_pool, pool_el, pool_offset] = build_fixed_el_beam_pool(x, y, z, bw3dB_el, cfg)
% 按固定 0.5 BW3dB 间隔生成局部俯仰候选波束池。
pool_offset = (-cfg.w_opt_pool_half_count:cfg.w_opt_pool_half_count) * cfg.w_opt_pool_step_ratio;
pool_el = cfg.el0 + pool_offset * bw3dB_el;
W_pool = build_beam_matrix(x, y, z, cfg.az0, pool_el, cfg);
end

function idx = centered_pool_indices(pool_offset, num_beam)
% 从固定候选池中围绕 el0 连续居中选取 num_beam 个波束（num_beam 为偶数）。
half_num = num_beam / 2;
neg_idx = find(pool_offset < 0);
pos_idx = find(pool_offset > 0);
idx = [neg_idx(end-half_num+1:end), pos_idx(1:half_num)];
end

function [T, info] = build_beamspace_whitener(W)
% 基于 C_b=W^H W 构造波束域白化矩阵。
% 原始波束域噪声协方差正比于 W^H W，因此令 Z_tilde=T W^H Y、G_tilde=T W^H A 
Cb0 = W' * W;
Cb = (Cb0 + Cb0') / 2;
[U, D] = eig(Cb);
d = real(diag(D));
d = max(d, 1e-12 * max(d));
T = diag(1 ./ sqrt(d)) * U';

info = struct();
info.cond_Cb = cond(Cb);
end

function A = build_steering_matrix(x, y, z, az_list, el_list, cfg)
% 按列生成圆柱阵导向矩阵。
az_list = az_list(:).';
el_list = el_list(:).';

A = zeros(numel(x), numel(az_list));
for i = 1:numel(az_list)
    A(:, i) = steering_vec_cyl(x, y, z, az_list(i), el_list(i), cfg);
end
end

function a = steering_vec_cyl(x, y, z, az_deg, el_deg, cfg)
% 圆柱阵真实导向矢量。
% u=[cos(el)cos(az), cos(el)sin(az), sin(el)]^T。
ux = cosd(el_deg) * cosd(az_deg);
uy = cosd(el_deg) * sind(az_deg);
uz = sind(el_deg);
phase = x(:) * ux + y(:) * uy + z(:) * uz;
a = exp(1j * 2*pi/cfg.lambda * phase);
end

%% 局部函数：信号生成与最大似然估计

function Y_clean = simulate_two_target_clean_snapshots(x, y, z, true_az, true_el, cfg)
% 生成无噪声阵元域目标接收信号 Y_clean=A_cyl(Theta)S。
A = [steering_vec_cyl(x, y, z, true_az(1), true_el(1), cfg), ...
     steering_vec_cyl(x, y, z, true_az(2), true_el(2), cfg)];

S = (randn(2, cfg.snapshots) + 1j * randn(2, cfg.snapshots)) / sqrt(2);
Y_clean = A * S;
end

function Zb = add_beamspace_noise(Y_clean, W, T, snr_dB)
% 在白化波束域输入 Z=T W^H Y 上按指定 SNR 加噪。
Z_clean = T * (W' * Y_clean);
signal_power = mean(abs(Z_clean(:)).^2);
noise_power = signal_power / (10^(snr_dB / 10));
Nb = sqrt(noise_power / 2) * (randn(size(Z_clean)) + 1j * randn(size(Z_clean)));
Zb = Z_clean + Nb;
end

function [est_el, score_map] = beamspace_ml_pair_el_search(Zb, G_grid, el_grid)
% 固定方位下的目标波束级最大似然估计。
% 对任意满足 i~=j 的候选 (el_i, el_j)，构造 G=[g_i,g_j]，
% 并计算 J=tr(G(G^HG)^(-1)G^H Z Z^H)。
% 不限定 el_i 与 el_j 的大小关系，两个目标标签交换对应的候选均参与搜索。
Rz = Zb * Zb';
S = G_grid' * G_grid;
Q = G_grid' * Rz * G_grid;
s_diag = real(diag(S));
q_diag = real(diag(Q));

den = s_diag * s_diag.' - abs(S).^2;
num = q_diag * s_diag.' + s_diag * q_diag.' - S .* Q.' - conj(S) .* Q;
score_map = real(num ./ max(den, eps));

mask = ~eye(numel(el_grid));
score_map(~mask) = NaN;
[~, idx] = max(score_map(:), [], 'omitnan');
[i1, i2] = ind2sub(size(score_map), idx);
est_el = [el_grid(i1), el_grid(i2)];
end

%% 局部函数：实验统计

function snr_table = run_snr_beam_experiment(x, y, z, bw3dB_el, cfg)
% 模型匹配条件下，比较不同 SNR 和不同俯仰波束数的波束级 ML 性能。
%0.8倍 3 dB 波束宽度
el_sep = cfg.snr_sep_ratio * bw3dB_el;
true_el = [cfg.el0 - el_sep / 2, cfg.el0 + el_sep / 2];
true_az = [cfg.az0, cfg.az0];

%构造俯仰搜索网格
search_half_width = 0.80 * bw3dB_el;
el_grid = linspace(cfg.el0 - search_half_width, cfg.el0 + search_half_width, 161);
A_el_grid = build_steering_matrix(x, y, z, cfg.az0 * ones(size(el_grid)), el_grid, cfg);

num_beams = numel(cfg.snr_beam_counts);
num_snrs = numel(cfg.snr_list);
num_rows = num_beams * num_snrs;

snr_col = zeros(num_rows, 1);
beam_col = zeros(num_rows, 1);
rmse_col = zeros(num_rows, 1);
resolution_col = zeros(num_rows, 1);

row = 0;
%外循环遍历波束数B=10,8,6,4,2
for iBeam = 1:num_beams
    num_beam = cfg.snr_beam_counts(iBeam);
    %重新构造对应的波束矩阵
    [W_now, T_now] = setup_el_beamspace(x, y, z, bw3dB_el, num_beam, cfg, cfg.el_beam_step_ratio);
    G_grid_now = T_now * (W_now' * A_el_grid);

    %遍历SNR
    for iSnr = 1:num_snrs
        snr_now = cfg.snr_list(iSnr);
        err = zeros(cfg.snr_mc_num, 1);
        resolve = false(cfg.snr_mc_num, 1);

        for iMc = 1:cfg.snr_mc_num
            Y_clean = simulate_two_target_clean_snapshots(x, y, z, true_az, true_el, cfg);
            Zb = add_beamspace_noise(Y_clean, W_now, T_now, snr_now);
            est_ml = beamspace_ml_pair_el_search(Zb, G_grid_now, el_grid);

            err(iMc) = pair_rmse_deg(est_ml, true_el);
            resolve(iMc) = is_resolution_success(est_ml, true_el, bw3dB_el, true, cfg.success_tol_bw_ratio);
        end

        row = row + 1;
        snr_col(row) = snr_now;
        beam_col(row) = num_beam;
        rmse_col(row) = sqrt(mean(err.^2));
        resolution_col(row) = mean(resolve);

        fprintf('模型匹配目标: SNR=%g dB, %d波束, RMSE=%.4f deg, 分辨成功率=%.2f\n', ...
            snr_now, num_beam, rmse_col(row), resolution_col(row));
    end
end

snr_table = table(snr_col, beam_col, rmse_col, resolution_col, ...
    'VariableNames', {'snr_dB', 'num_el_beam', 'rmse_beamspace_ml_deg', ...
    'resolution_beamspace_ml'});
end

function score_table = run_w_selection_score_experiment(x, y, z, bw3dB_el, cfg)
% 固定候选波束池间隔0.5BW，比较连续规则波束时不同目标间隔下的评分。
[W_pool, ~, pool_offset] = build_fixed_el_beam_pool(x, y, z, bw3dB_el, cfg);

num_schemes = numel(cfg.w_score_beam_counts) * numel(cfg.w_score_sep_ratio_list);
beam_col = zeros(num_schemes, 1);
sep_col = zeros(num_schemes, 1);
proj_col = zeros(num_schemes, 1);
corr_col = zeros(num_schemes, 1);
cond_col = zeros(num_schemes, 1);
score_col = zeros(num_schemes, 1);

row = 0;
%遍历波束数——w_score_beam_counts = [10, 8, 6, 4, 2]
for iBeam = 1:numel(cfg.w_score_beam_counts)
    num_beam = cfg.w_score_beam_counts(iBeam);
    %候选池里选出连续居中的 B 个波束
    pool_idx = centered_pool_indices(pool_offset, num_beam);
    W_now = W_pool(:, pool_idx);
    %计算白化矩阵
    T_now = build_beamspace_whitener(W_now);

    %遍历不同目标间隔——0.1:0.1:1.0;
    for iSep = 1:numel(cfg.w_score_sep_ratio_list)
        sep_ratio = cfg.w_score_sep_ratio_list(iSep);
        A_pair = build_target_pair_steering(x, y, z, sep_ratio, bw3dB_el, cfg);
        %计算三个指标
        metrics = evaluate_w_selection_metrics(W_now, T_now, A_pair);
        %评分
        score_value = cfg.w_score_alpha * metrics.proj_loss ...
            + cfg.w_score_beta * metrics.max_corr ...
            + cfg.w_score_gamma * metrics.cond_metric;

        row = row + 1;
        beam_col(row) = num_beam;
        sep_col(row) = sep_ratio;
        proj_col(row) = metrics.proj_loss;
        corr_col(row) = metrics.max_corr;
        cond_col(row) = metrics.cond_metric;
        score_col(row) = score_value;

        fprintf('连续波束评分: B=%d, 目标间隔=%.1fBW, 投影损失=%.4f, 相关性=%.4f, 条件数指标=%.4f, 综合评分=%.4f\n', ...
            num_beam, sep_ratio, proj_col(row), corr_col(row), cond_col(row), score_col(row));
    end
end

score_table = table(beam_col, sep_col, proj_col, corr_col, cond_col, score_col, ...
    'VariableNames', {'num_el_beam', 'sep_ratio_bw', 'proj_loss', ...
    'max_corr', 'cond_metric', 'score'});
end

function opt_table = run_w_score_optimal_experiment(x, y, z, bw3dB_el, cfg)
% 从固定候选波束池中穷举选取 W，得到平均综合评分最优的 W*_B。
[W_pool, pool_el, pool_offset] = build_fixed_el_beam_pool(x, y, z, bw3dB_el, cfg);
num_pool = size(W_pool, 2);

num_cases = numel(cfg.w_opt_beam_counts);
beam_col = zeros(num_cases, 1);
proj_col = zeros(num_cases, 1);
corr_col = zeros(num_cases, 1);
cond_col = zeros(num_cases, 1);
score_col = zeros(num_cases, 1);
comb_col = cell(num_cases, 1);
beam_el_col = cell(num_cases, 1);
beam_offset_col = cell(num_cases, 1);

for iCase = 1:num_cases
    num_beam = cfg.w_opt_beam_counts(iCase);

    %对于每个波束数 B，生成所有可能的组合
    comb_set = nchoosek(1:num_pool, num_beam);
    best_score = inf;
    best_metrics = struct('proj_loss', NaN, 'max_corr', NaN, 'cond_metric', NaN);
    best_idx = [];

    %对每种组合，通过波束矩阵——白化矩阵——W评分
    for iComb = 1:size(comb_set, 1)
        idx = comb_set(iComb, :);
        W_now = W_pool(:, idx);
        T_now = build_beamspace_whitener(W_now);
        %对多个目标间隔的评分取平均
        metrics = evaluate_w_metrics_over_separations(W_now, T_now, x, y, z, bw3dB_el, cfg);
        score_value = cfg.w_score_alpha * metrics.proj_loss ...
            + cfg.w_score_beta * metrics.max_corr ...
            + cfg.w_score_gamma * metrics.cond_metric;

        %找出最小的评分（最优的）
        if score_value < best_score
            best_score = score_value;
            best_metrics = metrics;
            best_idx = idx;
        end
    end

    beam_col(iCase) = num_beam;
    proj_col(iCase) = best_metrics.proj_loss;
    corr_col(iCase) = best_metrics.max_corr;
    cond_col(iCase) = best_metrics.cond_metric;
    score_col(iCase) = best_score;
    comb_col{iCase} = best_idx;
    beam_el_col{iCase} = pool_el(best_idx);
    beam_offset_col{iCase} = pool_offset(best_idx);

    fprintf('候选池最优: B=%d, 组合数=%d, 综合评分=%.4f, 投影损失=%.4f, 最大相关=%.4f, 条件数指标=%.4f\n', ...
        num_beam, size(comb_set, 1), best_score, proj_col(iCase), corr_col(iCase), cond_col(iCase));
end

opt_table = table(beam_col, proj_col, corr_col, cond_col, score_col, comb_col, ...
    beam_el_col, beam_offset_col, ...
    'VariableNames', {'num_el_beam', 'proj_loss', 'max_corr', 'cond_metric', ...
    'score', 'pool_index', 'beam_el_deg', 'beam_offset_bw'});
end

%% 局部函数：波束选择评分

function A_pair = build_target_pair_steering(x, y, z, sep_ratio, bw3dB_el, cfg)
% 按目标俯仰间隔生成固定方位下的目标阵元域导向矩阵。
el_sep = sep_ratio * bw3dB_el;
pair_el = [cfg.el0 - el_sep / 2, cfg.el0 + el_sep / 2];
A_pair = build_steering_matrix(x, y, z, cfg.az0 * ones(size(pair_el)), pair_el, cfg);
end

function metrics = evaluate_w_metrics_over_separations(W, T, x, y, z, bw3dB_el, cfg)
% 对多个目标间隔的评分取平均，作为候选池最优搜索的综合诊断量。
num_sep = numel(cfg.w_score_sep_ratio_list);
proj_loss = zeros(num_sep, 1);
max_corr = zeros(num_sep, 1);

%循环目标间隔
for iSep = 1:num_sep
    A_pair = build_target_pair_steering(x, y, z, cfg.w_score_sep_ratio_list(iSep), bw3dB_el, cfg);
    metrics_now = evaluate_w_selection_metrics(W, T, A_pair);
    proj_loss(iSep) = metrics_now.proj_loss;
    max_corr(iSep) = metrics_now.max_corr;
end

metrics = struct();
metrics.proj_loss = mean(proj_loss);
metrics.max_corr = mean(max_corr);
metrics.cond_metric = metrics_now.cond_metric;
end

function metrics = evaluate_w_selection_metrics(W, T, A_eval)
% 计算指定目标导向矩阵的投影损失、波束域相关性和波束格拉姆矩阵条件数。
%投影损失
Cb = W' * W;
PW_A = W * (pinv(Cb) * (W' * A_eval));
proj_loss = 1 - real(norm(PW_A, 'fro')^2 / norm(A_eval, 'fro')^2);
proj_loss = min(max(proj_loss, 0), 1);

%波束域目标相关性
G_pair = T * (W' * A_eval);
G_pair = G_pair ./ max(vecnorm(G_pair), eps);
max_corr = abs(G_pair(:, 1)' * G_pair(:, 2));

%波束矩阵条件数
cond_metric = log10(max(cond(Cb), 1));

metrics = struct();
metrics.proj_loss = proj_loss;
metrics.max_corr = max_corr;
metrics.cond_metric = cond_metric;
end

function [est_el, power_curve, has_two_peaks] = beamspace_peak_pair_estimator(Zb, G_grid, el_grid, cfg)
% 波束扫描结果
% 在同一白化波束域输入 Zb 上进行一维波束扫描，并返回检测到的有效局部峰。
% 若有效峰不足两个，则 has_two_peaks=false，分辨成功率统计中直接判为失败。
beam_out = G_grid' * Zb / sqrt(size(G_grid, 1));
power_curve = mean(abs(beam_out).^2, 2).';
power_curve = power_curve / max(power_curve);

is_peak = false(size(power_curve));
for i = 2:numel(power_curve)-1
    is_peak(i) = power_curve(i) >= cfg.peak_min_power_ratio ...
        && power_curve(i) >= power_curve(i-1) && power_curve(i) >= power_curve(i+1);
end
peak_idx = find(is_peak);
has_two_peaks = numel(peak_idx) >= 2;

if has_two_peaks
    [~, order] = sort(power_curve(peak_idx), 'descend');
    pick = sort(peak_idx(order(1:2)));
    est_el = sort(el_grid(pick));
else
    est_el = el_grid(peak_idx);
end
end

function err = pair_rmse_deg(est_el, true_el)
% 俯仰向目标配对后的均方根误差。
est_el = sort(est_el(:).');
true_el = sort(true_el(:).');
err = sqrt(mean((est_el - true_el).^2));
end

function ok = is_resolution_success(est_el, true_el, bw3dB_el, has_two_results, tol_bw_ratio)
% 分辨成功判据：先要求检测出两个结果，再要求两个配对误差均小于容差。
if ~has_two_results
    ok = false;
    return;
end

est_el = sort(est_el(:).');
true_el = sort(true_el(:).');
angle_tol = tol_bw_ratio * bw3dB_el;
ok = all(abs(est_el(1:2) - true_el(1:2)) <= angle_tol);
end

%% 局部函数：绘图

function plot_single_case(single_case, cfg)
% 0.5倍 3 dB 波束宽度的波束扫描结果和最大似然估计图
fig = figure('Color', 'w', 'Position', [100, 100, 1100, 430]);

subplot(1, 2, 1);
h_scan = plot(single_case.el_grid, single_case.amp_curve, 'LineWidth', 1.8); hold on; grid on;
h_true = xline(single_case.true_el(1), 'k--', 'LineWidth', 1.2);
xline(single_case.true_el(2), 'k--', 'LineWidth', 1.2);
h_amp = plot(single_case.est_amp, interp1(single_case.el_grid, single_case.amp_curve, single_case.est_amp, 'linear'), 'rx', ...
    'MarkerSize', 9, 'LineWidth', 1.8);
xlabel('俯仰角 / deg');
ylabel('归一化扫描功率');
title('波束扫描结果');
legend([h_scan, h_true, h_amp], {'扫描功率', '真实目标', '波束扫描结果'}, 'Location', 'best');

subplot(1, 2, 2);
score = single_case.score_map;
score_min = min(score(:), [], 'omitnan');
score_max = max(score(:), [], 'omitnan');
score = (score - score_min) / (score_max - score_min);
imagesc(single_case.el_grid, single_case.el_grid, score); axis xy; colorbar; hold on;
%真值和估计值
true_x = [single_case.true_el(2), single_case.true_el(1)];
true_y = [single_case.true_el(1), single_case.true_el(2)];
est_xy = [single_case.est_ml(2), single_case.est_ml(1)];
h_true_ml = plot(true_x, true_y, 'ko', 'MarkerSize', 10, 'LineWidth', 2.0);
h_est_ml = plot(est_xy(1), est_xy(2), 'rx', 'MarkerSize', 11, 'LineWidth', 2.0);
xlabel('候选目标2俯仰角 / deg');
ylabel('候选目标1俯仰角 / deg');
title('归一化波束级最大似然估计 J(\Theta)');
legend([h_true_ml, h_est_ml], {'真实位置', 'ML估计'}, 'Location', 'southoutside');

exportgraphics(fig, fullfile(cfg.result_dir, 'fig_single_case_half_bw.png'), 'Resolution', 220);
end

function plot_rmse_curve(sep_ratio_list, rmse_ml, resolution_ml, resolution_amp, cfg)
% 10 个波束的测角精度和分辨成功率对比。
% 波束扫描结果只包含混合峰位置，不再与目标 RMSE 直接比较；
% 其失效情况通过右图分辨成功率体现。
fig = figure('Color', 'w', 'Position', [120, 120, 1000, 420]);

subplot(1, 2, 1);
plot(sep_ratio_list, rmse_ml, 'o-', 'LineWidth', 1.8); grid on;
xlabel('目标俯仰间隔 / 3 dB波束宽度');
ylabel('俯仰角 RMSE / deg');
legend({'波束级最大似然估计'}, 'Location', 'best');

subplot(1, 2, 2);
plot(sep_ratio_list, resolution_ml, 'o-', 'LineWidth', 1.8); hold on; grid on;
plot(sep_ratio_list, resolution_amp, 's--', 'LineWidth', 1.8);
xlabel('目标俯仰间隔 / 3 dB波束宽度');
ylabel('分辨成功率');
ylim([0, 1.05]);
legend({'波束级最大似然估计', '波束扫描结果'}, 'Location', 'best');

exportgraphics(fig, fullfile(cfg.result_dir, 'fig_rmse_resolution_vs_separation.png'), 'Resolution', 220);
end

function plot_snr_beam_result(snr_table, cfg)
% 不同 SNR 和不同俯仰波束数的对比结果。
fig = figure('Color', 'w', 'Position', [140, 140, 1100, 430]);
beam_counts = unique(snr_table.num_el_beam(:)).';
line_styles = {'o-', 's--', 'd-.', '^-', 'v:'};

subplot(1, 2, 1);
hold on; grid on;
for i = 1:numel(beam_counts)
    nBeam = beam_counts(i);
    %在 snr_table 里找出所有"波束数等于 B”的行。
    rows = find(snr_table.num_el_beam == nBeam);
    %把当前这些行里的 SNR 从小到大排序
    [snr_sorted, order] = sort(snr_table.snr_dB(rows));
    rmse_sorted = snr_table.rmse_beamspace_ml_deg(rows(order));
    plot(snr_sorted, rmse_sorted, line_styles{i}, ...
        'LineWidth', 1.8, 'DisplayName', sprintf('%d个波束', nBeam));
end
xlabel('波束域输入 SNR / dB');
ylabel('俯仰角 RMSE / deg');
legend('Location', 'best');

subplot(1, 2, 2);
hold on; grid on;
for i = 1:numel(beam_counts)
    nBeam = beam_counts(i);
    rows = find(snr_table.num_el_beam == nBeam);
    [snr_sorted, order] = sort(snr_table.snr_dB(rows));
    res_sorted = snr_table.resolution_beamspace_ml(rows(order));
    plot(snr_sorted, res_sorted, line_styles{i}, ...
        'LineWidth', 1.8, 'DisplayName', sprintf('%d个波束', nBeam));
end
xlabel('波束域输入 SNR / dB');
ylabel('分辨成功率');
ylim([0, 1.05]);
legend('Location', 'best');

exportgraphics(fig, fullfile(cfg.result_dir, 'fig_snr_beam_comparison.png'), 'Resolution', 220);
end

function plot_w_selection_score_result(score_table, cfg)
% 固定方位，不同规则波束布设的三项诊断量和综合评分。
fig = figure('Color', 'w', 'Position', [120, 120, 1120, 760]);
%提取不重复的波束数[10, 8, 6, 4, 2]
beam_counts = unique(score_table.num_el_beam(:), 'stable').';
line_styles = {'o-', 's--', 'd-.', '^-', 'v:'};

tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
%给定指标名 metric_name，画出不同 B 下该指标随目标间隔变化的曲线
plot_metric_by_sep(score_table, beam_counts, 'proj_loss', line_styles);
ylabel('投影损失');
title('局部流形投影损失');
xlabel('目标俯仰间隔 / 3 dB 波束宽度');
legend('Location', 'best');

nexttile;
plot_metric_by_sep(score_table, beam_counts, 'max_corr', line_styles);
ylabel('最大相关系数');
title('波束域候选相关性');
ylim([0, 1.05]);
xlabel('目标俯仰间隔 / 3 dB 波束宽度');
legend('Location', 'best');

nexttile;
plot_metric_by_sep(score_table, beam_counts, 'cond_metric', line_styles);
ylabel('log_{10}(cond(W^H W))');
title('波束格拉姆矩阵条件数');
xlabel('目标俯仰间隔 / 3 dB 波束宽度');
legend('Location', 'best');

nexttile;
plot_metric_by_sep(score_table, beam_counts, 'score', line_styles);
ylabel('综合评分');
title(sprintf('综合评分  \\alpha=%.2f, \\beta=%.2f, \\gamma=%.2f', ...
    cfg.w_score_alpha, cfg.w_score_beta, cfg.w_score_gamma));
xlabel('目标俯仰间隔 / 3 dB 波束宽度');
legend('Location', 'best');

exportgraphics(fig, fullfile(cfg.result_dir, 'fig_w_selection_score.png'), 'Resolution', 220);
end

function plot_metric_by_sep(score_table, beam_counts, metric_name, line_styles)
%通用绘图函数，给定指标名 metric_name，画出不同 B 下该指标随目标间隔变化的曲线
hold on; grid on;
for i = 1:numel(beam_counts)
    nBeam = beam_counts(i);
    rows = find(score_table.num_el_beam == nBeam);
    [sep_sorted, order] = sort(score_table.sep_ratio_bw(rows));
    metric_values = score_table.(metric_name);
    y_sorted = metric_values(rows(order));
    plot(sep_sorted, y_sorted, line_styles{i}, ...
        'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', sprintf('B=%d', nBeam));
end
xlim([min(score_table.sep_ratio_bw) - 0.05, max(score_table.sep_ratio_bw) + 0.05]);
xticks(unique(score_table.sep_ratio_bw));
end

function plot_w_score_optimal_metric_result(opt_table, cfg)
% 候选波束池内穷举搜索得到的 W*_B 评分指标。
fig = figure('Color', 'w', 'Position', [140, 140, 1120, 760]);
[beam_sorted, order] = sort(opt_table.num_el_beam);

tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
plot(beam_sorted, opt_table.proj_loss(order), 'o-', 'LineWidth', 1.8, 'MarkerSize', 7); grid on;
xlabel('波束数 B');
ylabel('投影损失');
title('局部流形投影损失');
xticks(beam_sorted);

nexttile;
plot(beam_sorted, opt_table.max_corr(order), 's-', 'LineWidth', 1.8, 'MarkerSize', 7); grid on;
xlabel('波束数 B');
ylabel('最大相关系数');
title('波束域候选相关性');
ylim([0, 1.05]);
xticks(beam_sorted);

nexttile;
plot(beam_sorted, opt_table.cond_metric(order), 'd-', 'LineWidth', 1.8, 'MarkerSize', 7); grid on;
xlabel('波束数 B');
ylabel('log_{10}(cond(W^H W))');
title('波束格拉姆矩阵条件数');
xticks(beam_sorted);

nexttile;
plot(beam_sorted, opt_table.score(order), '^-', 'LineWidth', 1.8, 'MarkerSize', 7); grid on;
xlabel('波束数 B');
ylabel('综合评分');
title(sprintf('候选池内最优评分  \\alpha=%.2f, \\beta=%.2f, \\gamma=%.2f', ...
    cfg.w_score_alpha, cfg.w_score_beta, cfg.w_score_gamma));
xticks(beam_sorted);

exportgraphics(fig, fullfile(cfg.result_dir, 'fig_w_score_optimal_metrics_vs_B.png'), 'Resolution', 220);
end

function plot_w_score_optimal_beam_layout(opt_table, cfg)
% 展示候选池内评分最优 W*_B 对应的俯仰波束中心。
fig = figure('Color', 'w', 'Position', [180, 180, 980, 520]);
hold on; grid on;
%波束数从小到大排序
[beam_sorted, order] = sort(opt_table.num_el_beam);
colors = lines(height(opt_table));
%候选波束池的俯仰偏移位置
pool_offsets = (-cfg.w_opt_pool_half_count:cfg.w_opt_pool_half_count).' * cfg.w_opt_pool_step_ratio;

%循环每个B
for iPlot = 1:numel(order)
    iRow = order(iPlot);
    nBeam = opt_table.num_el_beam(iRow);
    %当前B下得到的评分最高的全部W相比波束中心的偏移量
    offsets = opt_table.beam_offset_bw{iRow};

    selected_mask = false(size(pool_offsets));
    for iOffset = 1:numel(offsets)
        %被选中的波束标记
        selected_mask = selected_mask | abs(pool_offsets - offsets(iOffset)) < 1e-10;
    end
    %未被选中的
    unselected_offsets = pool_offsets(~selected_mask);
    scatter(nBeam * ones(size(unselected_offsets)), unselected_offsets, 42, ...
        [0.78, 0.78, 0.78], 'filled', 'MarkerFaceAlpha', 0.45, ...
        'HandleVisibility', 'off');

    x_pos = nBeam * ones(size(offsets));
    scatter(x_pos, offsets, 70, colors(iPlot, :), 'filled', ...
        'DisplayName', sprintf('B=%d', nBeam));
    text(nBeam, max(offsets) + 0.25, sprintf('B=%d', nBeam), ...
        'HorizontalAlignment', 'center', 'Color', colors(iPlot, :), 'FontWeight', 'bold');
end

yline(0, 'k--', '\theta_0', 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
scatter(nan, nan, 42, [0.78, 0.78, 0.78], 'filled', ...
    'MarkerFaceAlpha', 0.45, 'DisplayName', '候选波束');
xlabel('波束数 B');
ylabel('波束中心相对 \theta_0 / 3 dB 波束宽度');
title('候选池内评分最优 W^*_B 的俯仰波束中心');
xticks(beam_sorted);
xlim([min(beam_sorted) - 0.8, max(beam_sorted) + 0.8]);
ylim([min(pool_offsets) - 0.45, max(pool_offsets) + 0.55]);
yticks(min(pool_offsets):0.5:max(pool_offsets));
legend('Location', 'eastoutside');

exportgraphics(fig, fullfile(cfg.result_dir, 'fig_w_score_optimal_beam_layout.png'), 'Resolution', 220);
end

function ang = wrap180_local(ang)
% 将角度映射到 [-180, 180)。
ang = mod(ang + 180, 360) - 180;
end
