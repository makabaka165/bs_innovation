%% Generate W-selection mechanism figure for Chapter 4
% This script reads existing Step11.2 W-design results and redraws a
% publication-style mechanism figure. It does not modify manuscript files.

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
figureCodeRoot = fileparts(scriptDir);
packageRoot = fileparts(fileparts(figureCodeRoot));
stepRoot = fullfile(packageRoot, 'source', 'stepwise_signal_model');
step112Root = fullfile(stepRoot, 'steps', 'step_11_2_beamspace_w_design');
resultRoot = fullfile(step112Root, 'results_step11_2_b_budget_strategy_tradeoff');
matPath = fullfile(resultRoot, 'step11_2_b_budget_result.mat');

localFigureRoot = fullfile(figureCodeRoot, 'outputs', 'figures');
ensure_dir(localFigureRoot);

if exist(matPath, 'file') ~= 2
    error('Missing Step11.2 result MAT. Run Stage3 first: %s', matPath);
end

data = load(matPath, 'pool_info', 'params', 'W_cases', 'diagnostics_table');
poolInfo = data.pool_info;
params = data.params;
WCases = data.W_cases;
diagnosticsTable = data.diagnostics_table;

caseRegularB7 = find_w_case(WCases, 'regular_3dB_grid', 7);
caseProjB7 = find_w_case(WCases, 'greedy_projection', 7);
caseLowcorrB7 = find_w_case(WCases, 'greedy_lowcorr', 7);
caseCombinedB7 = find_w_case(WCases, 'greedy_combined', 7);

pal = blue_gray_palette();
fontName = get_cn_font();

% Word-friendly full-width layout: top row explains the selected W, bottom
% row shows the three diagnostics. The aspect ratio avoids excessive
% shrinking when inserted into a portrait manuscript page.
fig = figure('Color', pal.white, 'Units', 'pixels', 'Position', [60, 60, 2200, 1450], 'Visible', 'off');
tl = tiledlayout(fig, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

axA = nexttile(tl, 1, [1, 2]);
plot_pool_selection_panel(axA, poolInfo, params, caseRegularB7, caseProjB7, caseLowcorrB7, caseCombinedB7, pal, fontName);

axC = nexttile(tl, 3);
plot_gram_panel(axC, caseCombinedB7.W, pal, fontName);

axB1 = nexttile(tl, 4);
plot_metric_panel(axB1, diagnosticsTable, 'projection_loss', '投影损失', pal, fontName, false, false);

axB2 = nexttile(tl, 5);
plot_metric_panel(axB2, diagnosticsTable, 'max_corr', '最大流形相关', pal, fontName, false, true);

axB3 = nexttile(tl, 6);
plot_metric_panel(axB3, diagnosticsTable, 'cond_WHW', 'log_{10} cond(W^H W)', pal, fontName, true, false);

outPng = fullfile(localFigureRoot, 'fig_4_2_w_selection_mechanism_cn.png');
outPdf = fullfile(localFigureRoot, 'fig_4_2_w_selection_mechanism_cn.pdf');
exportgraphics(fig, outPng, 'Resolution', 300);
exportgraphics(fig, outPdf, 'ContentType', 'vector');
close(fig);

fprintf('Generated W-selection mechanism figure:\n');
fprintf('  PNG: %s\n', outPng);
fprintf('  PDF: %s\n', outPdf);
fprintf('Recommended display case: greedy_combined_B7, selected_idx=%s\n', mat2str(caseCombinedB7.selected_idx));

function plot_pool_selection_panel(ax, poolInfo, params, regularCase, projCase, lowcorrCase, combinedCase, pal, fontName)
hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');

azPool = poolInfo.beam_az_col(:);
elPool = poolInfo.beam_el_col(:);
scatter(ax, azPool, elPool, 28, 'o', ...
    'MarkerFaceColor', pal.very_pale, 'MarkerEdgeColor', pal.grid, ...
    'MarkerFaceAlpha', 0.85, 'DisplayName', '候选波束池');

if isfield(params, 'az_patch') && isfield(params, 'el_patch')
    azPatch = params.az_patch(:);
    elPatch = params.el_patch(:);
    rectangle(ax, 'Position', [min(azPatch), min(elPatch), max(azPatch)-min(azPatch), max(elPatch)-min(elPatch)], ...
        'EdgeColor', pal.neutral, 'LineStyle', '--', 'LineWidth', 1.2);
    plot(ax, NaN, NaN, '--', 'Color', pal.neutral, 'LineWidth', 1.2, ...
        'DisplayName', '局部流形窗口');
end

plot_selected(ax, poolInfo, projCase.selected_idx, '^', pal.tertiary, 'greedy\_projection B=7', 70, false);
plot_selected(ax, poolInfo, lowcorrCase.selected_idx, 'd', pal.pale, 'greedy\_lowcorr B=7', 70, false);
plot_selected(ax, poolInfo, regularCase.selected_idx, 's', pal.neutral, 'regular 3dB B=7', 90, true);
plot_selected(ax, poolInfo, combinedCase.selected_idx, 'o', pal.primary, 'greedy\_combined B=7', 115, true);

centerAz = poolInfo.cfg_beam_center(1);
centerEl = poolInfo.cfg_beam_center(2);
plot(ax, centerAz, centerEl, '+', 'Color', pal.highlight, 'MarkerSize', 14, 'LineWidth', 2.2, ...
    'DisplayName', '局部中心');

xlim(ax, [min(azPool)-0.2, max(azPool)+0.2]);
ylim(ax, [min(elPool)-0.2, max(elPool)+0.2]);
xlabel(ax, '波束方位中心 az (deg)', 'FontName', fontName);
ylabel(ax, '波束俯仰中心 el (deg)', 'FontName', fontName);
title(ax, 'A  候选波束池与选中波束', 'FontName', fontName, 'FontWeight', 'bold');
lgd = legend(ax, 'Location', 'northwest', 'NumColumns', 1);
set(lgd, 'FontName', fontName, 'FontSize', 8.5, 'Box', 'off', 'Color', pal.white);
style_axis(ax, pal, fontName);
end

function plot_selected(ax, poolInfo, idx, marker, color, labelText, markerSize, emphasize)
az = poolInfo.beam_az_col(idx);
el = poolInfo.beam_el_col(idx);
if emphasize
    scatter(ax, az, el, markerSize, marker, 'MarkerFaceColor', color, ...
        'MarkerEdgeColor', [0.08 0.08 0.08], 'LineWidth', 1.0, 'DisplayName', labelText);
else
    scatter(ax, az, el, markerSize, marker, 'MarkerFaceColor', 'none', ...
        'MarkerEdgeColor', color, 'LineWidth', 1.2, 'DisplayName', labelText);
end
end

function plot_metric_panel(ax, T, metricName, yLabelText, pal, fontName, useLog10, showGroupTitle)
hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');

methods = {'regular_3dB_grid', 'greedy_projection', 'greedy_lowcorr', 'greedy_combined', 'svd_upper_bound'};
labels = {'regular 3dB', 'greedy projection', 'greedy lowcorr', 'greedy combined', 'SVD upper bound'};
colors = {pal.neutral, pal.secondary, pal.tertiary, pal.primary, pal.reference};
lineStyles = {'-', '-', '-', '-', '--'};
markers = {'s', '^', 'd', 'o', 'none'};

for iMethod = 1:numel(methods)
    mask = strcmp(cellstr(T.method_name), methods{iMethod});
    sub = T(mask, :);
    if isempty(sub)
        continue;
    end
    [BVals, order] = sort(sub.B);
    vals = sub.(metricName);
    vals = vals(order);
    if useLog10
        vals = log10(max(vals, 1));
    end
    plot(ax, BVals, vals, 'Color', colors{iMethod}, 'LineStyle', lineStyles{iMethod}, ...
        'Marker', markers{iMethod}, 'LineWidth', 1.55, 'MarkerSize', 5.8, ...
        'DisplayName', labels{iMethod});
end

xline(ax, 7, ':', 'Color', pal.highlight, 'LineWidth', 1.2, 'HandleVisibility', 'off');
text(ax, 7.25, ax.YLim(1) + 0.87 * diff(ax.YLim), 'B=7', ...
    'Color', pal.highlight, 'FontName', fontName, 'FontSize', 9, 'FontWeight', 'bold');

xlabel(ax, '波束数 B', 'FontName', fontName);
ylabel(ax, yLabelText, 'FontName', fontName);
if showGroupTitle
    title(ax, 'B  选择准则诊断量', 'FontName', fontName, 'FontWeight', 'bold');
end
if strcmp(metricName, 'projection_loss')
    lgd = legend(ax, 'Location', 'northeast');
    set(lgd, 'FontName', fontName, 'FontSize', 8.5, 'Box', 'off');
end
style_axis(ax, pal, fontName);
end

function plot_gram_panel(ax, W, pal, fontName)
G = abs(W' * W);
normVec = sqrt(max(real(diag(W' * W)), eps));
GNorm = G ./ (normVec * normVec.');
imagesc(ax, GNorm);
axis(ax, 'image');
colormap(ax, blue_sequential_colormap(256));
clim(ax, [0, 1]);
cb = colorbar(ax);
cb.Label.String = '归一化相关幅度';
cb.Label.FontName = fontName;
cb.Color = pal.text;

B = size(W, 2);
set(ax, 'XTick', 1:B, 'YTick', 1:B);
xlabel(ax, '选中波束序号', 'FontName', fontName);
ylabel(ax, '选中波束序号', 'FontName', fontName);
title(ax, 'C  greedy\_combined B=7 的归一化 |W^H W|', 'FontName', fontName, 'FontWeight', 'bold');

for ii = 1:B
    for jj = 1:B
        value = GNorm(ii, jj);
        if value > 0.72
            textColor = pal.white;
        else
            textColor = pal.text;
        end
        text(ax, jj, ii, sprintf('%.2f', value), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'Color', textColor, 'FontName', fontName, 'FontSize', 9);
    end
end
style_axis(ax, pal, fontName);
end

function caseEntry = find_w_case(WCases, methodName, B)
names = {WCases.name};
mask = strcmp(names, methodName) & [WCases.B] == B;
if ~any(mask)
    error('Missing W case: %s B=%d', methodName, B);
end
caseEntry = WCases(find(mask, 1));
end

function style_axis(ax, pal, fontName)
set(ax, 'FontName', fontName, 'FontSize', 10.5, 'LineWidth', 0.95, ...
    'XColor', pal.text, 'YColor', pal.text, ...
    'GridColor', pal.grid, 'MinorGridColor', pal.grid);
ax.GridAlpha = 0.55;
end

function ensure_dir(pathText)
if ~exist(pathText, 'dir')
    mkdir(pathText);
end
end

function fontName = get_cn_font()
availableFonts = listfonts;
preferredFonts = {'Microsoft YaHei UI', 'Microsoft YaHei', 'SimHei', 'SimSun', 'Arial'};
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
pal.reference = hex2rgb_local('#9AA6B2');
pal.grid = hex2rgb_local('#D8DEE6');
pal.text = hex2rgb_local('#111111');
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
