%% Generate controlled pair2d parameterization and DML-score demo figure
% This script is located in the paper project. It reads Step11.1 helper
% functions but does not modify the engineering code or manuscript files.

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
figureCodeRoot = fileparts(scriptDir);
packageRoot = fileparts(fileparts(figureCodeRoot));
stepRoot = fullfile(packageRoot, 'source', 'stepwise_signal_model');
step11Root = fullfile(stepRoot, 'steps', 'step_11_1_beamspace_ml_validation');
step11Common = fullfile(step11Root, 'common');

localFigureRoot = fullfile(figureCodeRoot, 'outputs', 'figures');
figureRoot = fullfile(figureCodeRoot, 'outputs', 'paper_candidates');
ensure_dir(localFigureRoot);
ensure_dir(figureRoot);

addpath(step11Common);
addpath(fullfile(stepRoot, 'core', 'config'));
addpath(fullfile(stepRoot, 'core', 'array'));

cfg = sim_cfg();
arrInfo = arr_cyl(cfg, cfg.beam.azSectorCenter);
x = arrInfo.xActVec;
y = arrInfo.yActVec;
z = arrInfo.zActVec;

lambda = cfg.arr.lambda;
phaseFactor = cfg.beam.spatialPhaseFactor;
phaseSign = 1;

% Representative Stage4 sample:
% white + az5_el5 + zero center bias + SNR=30 dB + trial_id=1.
baseSeed = 20260614;
L = 64;
azCenterTrue = cfg.beam.azSectorCenter;
elCenterNominal = cfg.beam.elSectorCenter;
azSep = 1.21;
elSepTrue = 0.57;
elCenterOffset = -0.27;
snrDb = 30;
trialId = 1;
sourceMode = 'noncoherent';
whiteningMode = 'white';

azTrue = [azCenterTrue - azSep/2, azCenterTrue + azSep/2];
elCenterTrue = elCenterNominal + elCenterOffset;
elTrue = [elCenterTrue - elSepTrue/2, elCenterTrue + elSepTrue/2];

seedNow = baseSeed + 100000*1 + 10000*2 + 1000*3 + 100*1 + 10*2 + trialId;
[Y, ~] = make_cyl_el_separation_snapshots(x, y, z, azTrue, elTrue, lambda, L, snrDb, sourceMode, ...
    'PhaseFactor', phaseFactor, 'PhaseSign', phaseSign, 'Seed', seedNow);

azSearchHalfWidth = 1.4;
elSearchHalfWidth = 1.1;
azBeamSpan = 2.0;
elBeamSpan = 1.5;
azGridStepDeg = 0.07;
elGridStepDeg = 0.15;
elSepIndexList = [0, 1, 2];
searchOrientations = [1, -1];
reg = 1e-10;

azBeamCenter = azCenterTrue;
elBeamCenter = elCenterNominal;
azBounds = [azBeamCenter - azSearchHalfWidth, azBeamCenter + azSearchHalfWidth];
elBounds = [elBeamCenter - elSearchHalfWidth, elBeamCenter + elSearchHalfWidth];
azGrid = azBounds(1):azGridStepDeg:azBounds(2);
elGrid = elBounds(1):elGridStepDeg:elBounds(2);

beamAz = linspace(azBeamCenter - azBeamSpan, azBeamCenter + azBeamSpan, 5);
beamEl = linspace(elBeamCenter - elBeamSpan, elBeamCenter + elBeamSpan, 5);
[W, ~] = build_cyl_azel_beam_transform(x, y, z, beamAz, beamEl, lambda, ...
    'PhaseFactor', phaseFactor, 'PhaseSign', phaseSign);
grid = precompute_beamspace_azel_grid(W, x, y, z, azGrid, elGrid, lambda, ...
    'PhaseFactor', phaseFactor, 'PhaseSign', phaseSign);
Z = W' * Y;

searchCfg = struct();
searchCfg.whitening_mode = whiteningMode;
searchCfg.reg = reg;
searchCfg.el_sep_index_list = elSepIndexList;
searchCfg.search_orientations = searchOrientations;
searchCfg.keep_score_cube = true;

[estPair2d, scoreInfo, debugPair2d] = search_pair_grid_el_separation_precomputed(Z, W, grid, searchCfg);

scoreMat = build_profiled_score_matrix(scoreInfo.score_records, elSepIndexList, numel(elGrid));
deltaElGrid = 2 * elSepIndexList * abs(elGrid(2) - elGrid(1));
scoreNorm = normalize_score_matrix(scoreMat);

pal = blue_gray_palette();
fig = figure('Color', pal.white, 'Units', 'pixels', 'Position', [80, 80, 1900, 960], 'Visible', 'off');
tiledlayout(fig, 1, 2, 'Padding', 'loose', 'TileSpacing', 'compact');

plot_geometry_panel(azBounds, elBounds, azCenterTrue, elCenterTrue, azTrue, elTrue, estPair2d);
plot_score_panel(elGrid, deltaElGrid, scoreNorm, elCenterTrue, elSepTrue, estPair2d);

fileName = 'fig_alg_pair2d_parameterization_dml_case_cn.png';
localPath = fullfile(localFigureRoot, fileName);
figurePath = fullfile(figureRoot, fileName);
exportgraphics(fig, localPath, 'Resolution', 300);
copyfile(localPath, figurePath);
close(fig);

fprintf('Generated pair2d parameterization demo figure:\n');
fprintf('  %s\n', figurePath);
fprintf('Representative case: az_sep=%.2f deg, el_sep_true=%.2f deg, SNR=%.1f dB, seed=%d\n', ...
    azSep, elSepTrue, snrDb, seedNow);
fprintf('Pair2d estimate: az=[%.3f, %.3f] deg, el=[%.3f, %.3f] deg, Delta_el_hat=%.3f deg, orientation=%+.0f\n', ...
    estPair2d.az_hat(1), estPair2d.az_hat(2), estPair2d.el_hat(1), estPair2d.el_hat(2), ...
    estPair2d.el_sep_hat, estPair2d.orientation_hat);
fprintf('Original max DML score: %.12g, candidate count=%d\n', debugPair2d.max_score, debugPair2d.num_pairs);

function plot_geometry_panel(azBounds, elBounds, azCenterTrue, elCenterTrue, azTrue, elTrue, estPair2d)
fontName = get_cn_font();
pal = blue_gray_palette();
ax = nexttile;
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
rectangle(ax, 'Position', [azBounds(1), elBounds(1), diff(azBounds), diff(elBounds)], ...
    'EdgeColor', pal.neutral, 'LineWidth', 1.3, 'LineStyle', '-');
plot(ax, azBounds, [elCenterTrue, elCenterTrue], '--', 'Color', pal.reference, 'LineWidth', 1.8, ...
    'DisplayName', '\Delta el=0 参考线');
plot(ax, azTrue, elTrue, '-', 'Color', pal.highlight, 'LineWidth', 1.8, 'HandleVisibility', 'off');
scatter(ax, azTrue, elTrue, 110, pal.highlight, 'filled', 'MarkerEdgeColor', pal.text, ...
    'DisplayName', '真实双目标');
plot(ax, estPair2d.az_hat, estPair2d.el_hat, '--', 'Color', pal.primary, 'LineWidth', 1.8, ...
    'HandleVisibility', 'off');
scatter(ax, estPair2d.az_hat, estPair2d.el_hat, 150, 'x', 'LineWidth', 2.5, ...
    'MarkerEdgeColor', pal.primary, 'DisplayName', 'pair2d 估计');
scatter(ax, azCenterTrue, elCenterTrue, 100, '+', 'LineWidth', 2.5, ...
    'MarkerEdgeColor', pal.neutral, 'DisplayName', '局部中心');

azMid = mean(estPair2d.az_hat);
elHatCenter = mean(estPair2d.el_hat);
plot(ax, [azMid, azMid], sort(estPair2d.el_hat), '-', 'Color', pal.primary, 'LineWidth', 1.5, ...
    'HandleVisibility', 'off');
plot(ax, azBounds, [elHatCenter, elHatCenter], ':', 'Color', pal.primary, 'LineWidth', 1.2, ...
    'HandleVisibility', 'off');
text(ax, azMid + 0.05, elHatCenter, '\Delta el', 'Color', pal.primary, ...
    'FontSize', 12, 'VerticalAlignment', 'middle', 'FontName', fontName);
text(ax, azBounds(1) + 0.08, elHatCenter + 0.03, '估计 el_c', 'Color', pal.primary, ...
    'FontSize', 11, 'VerticalAlignment', 'bottom', 'FontName', fontName);

xlim(ax, azBounds + [-0.08, 0.08]);
ylim(ax, elBounds + [-0.08, 0.08]);
axis(ax, 'equal');
xlabel(ax, '方位角 az (deg)');
ylabel(ax, '俯仰角 el (deg)');
title(ax, 'A  局部双目标几何');
lgd = legend(ax, 'Location', 'southoutside', 'NumColumns', 2);
set(lgd, 'FontName', fontName);
set(ax, 'FontName', fontName, 'FontSize', 12, 'LineWidth', 1.0, ...
    'XColor', pal.text, 'YColor', pal.text, 'GridColor', pal.grid, 'MinorGridColor', pal.grid);
end

function plot_score_panel(elGrid, deltaElGrid, scoreNorm, elCenterTrue, elSepTrue, estPair2d)
fontName = get_cn_font();
pal = blue_gray_palette();
ax = nexttile;
h = imagesc(ax, elGrid, deltaElGrid, scoreNorm);
set(ax, 'YDir', 'normal');
set(h, 'AlphaData', isfinite(scoreNorm));
set(ax, 'Color', pal.missing);
hold(ax, 'on'); box(ax, 'on');
colormap(ax, blue_sequential_colormap(256));
cb = colorbar(ax);
cb.Label.String = '归一化剖面 DML 评分';
cb.Label.FontName = fontName;
cb.Color = pal.text;
hRef = plot(ax, [elGrid(1), elGrid(end)], [0, 0], '--', 'Color', pal.reference, ...
    'LineWidth', 1.8, 'DisplayName', '\Delta el=0 参考线');
hTruth = scatter(ax, elCenterTrue, elSepTrue, 115, pal.highlight, 'filled', ...
    'MarkerEdgeColor', pal.text, 'DisplayName', '真实参数剖面');
scatter(ax, estPair2d.el_center_hat, estPair2d.el_sep_hat, 210, 'x', 'LineWidth', 4.2, ...
    'MarkerEdgeColor', pal.white, 'HandleVisibility', 'off');
hPeak = scatter(ax, estPair2d.el_center_hat, estPair2d.el_sep_hat, 150, 'x', 'LineWidth', 2.6, ...
    'MarkerEdgeColor', pal.primary, 'DisplayName', 'ML 峰值');
xlabel(ax, '俯仰中心 el_c (deg)');
ylabel(ax, '\Delta el (deg)');
title(ax, 'B  pair2d 剖面 DML 评分');
xlim(ax, [elGrid(1), elGrid(end)]);
ylim(ax, [min(deltaElGrid), max(deltaElGrid)]);
ylim(ax, [min(deltaElGrid) - 0.03, max(deltaElGrid) + 0.08]);
set(ax, 'FontName', fontName, 'FontSize', 12, 'LineWidth', 1.0, ...
    'XColor', pal.text, 'YColor', pal.text);
lgd = legend(ax, [hRef, hTruth, hPeak], 'Location', 'southoutside', ...
    'Orientation', 'horizontal', 'NumColumns', 3);
set(lgd, 'FontName', fontName, 'Color', pal.white, 'Box', 'on', ...
    'EdgeColor', pal.grid);
end

function scoreMat = build_profiled_score_matrix(scoreRecords, elSepIndexList, nEl)
scoreMat = NaN(numel(elSepIndexList), nEl);
for idx = 1:size(scoreRecords, 1)
    iElCenter = scoreRecords(idx, 1);
    sepIndex = scoreRecords(idx, 2);
    scoreVal = scoreRecords(idx, 4);
    rowIdx = find(elSepIndexList == sepIndex, 1);
    if isempty(rowIdx) || iElCenter < 1 || iElCenter > nEl
        continue;
    end
    if ~isfinite(scoreMat(rowIdx, iElCenter)) || scoreVal > scoreMat(rowIdx, iElCenter)
        scoreMat(rowIdx, iElCenter) = scoreVal;
    end
end
end

function scoreNorm = normalize_score_matrix(scoreMat)
finiteVals = scoreMat(isfinite(scoreMat));
if isempty(finiteVals)
    error('No finite DML score is available for visualization.');
end
vMin = min(finiteVals);
vMax = max(finiteVals);
if abs(vMax - vMin) < eps(max(abs(vMax), 1))
    scoreNorm = zeros(size(scoreMat));
    scoreNorm(isnan(scoreMat)) = NaN;
else
    scoreNorm = (scoreMat - vMin) ./ (vMax - vMin);
end
end

function ensure_dir(pathText)
if ~exist(pathText, 'dir')
    mkdir(pathText);
end
end

function fontName = get_cn_font()
availableFonts = listfonts;
preferredFonts = {'Microsoft YaHei UI', 'Microsoft JhengHei UI', 'Microsoft JhengHei', 'SimSun-ExtB', 'Arial'};
fontName = 'Arial';
for idx = 1:numel(preferredFonts)
    if any(strcmpi(availableFonts, preferredFonts{idx}))
        fontName = preferredFonts{idx};
        return;
    end
end
end

function pal = blue_gray_palette()
pal.primary = hex2rgb_local('#1F4E79');
pal.secondary = hex2rgb_local('#3B75AF');
pal.tertiary = hex2rgb_local('#6EA6CD');
pal.pale = hex2rgb_local('#A9CFE5');
pal.very_pale = hex2rgb_local('#D9E6EF');
pal.neutral = hex2rgb_local('#5A6772');
pal.reference = hex2rgb_local('#8F9AA5');
pal.grid = hex2rgb_local('#D8DEE6');
pal.text = hex2rgb_local('#111111');
pal.missing = hex2rgb_local('#D9D9D9');
pal.highlight = hex2rgb_local('#D55E00');
pal.white = [1 1 1];
end

function cmap = blue_sequential_colormap(n)
if nargin < 1
    n = 256;
end
anchors = [
    hex2rgb_local('#F7FBFF')
    hex2rgb_local('#DEEBF7')
    hex2rgb_local('#C6DBEF')
    hex2rgb_local('#9ECAE1')
    hex2rgb_local('#6BAED6')
    hex2rgb_local('#4292C6')
    hex2rgb_local('#2171B5')
    hex2rgb_local('#084594')
];
x0 = linspace(0, 1, size(anchors, 1));
xq = linspace(0, 1, n);
cmap = zeros(n, 3);
for c = 1:3
    cmap(:, c) = interp1(x0, anchors(:, c), xq, 'linear');
end
end

function rgb = hex2rgb_local(hexText)
hexText = char(hexText);
if startsWith(hexText, '#')
    hexText = hexText(2:end);
end
rgb = [hex2dec(hexText(1:2)), hex2dec(hexText(3:4)), hex2dec(hexText(5:6))] / 255;
end
