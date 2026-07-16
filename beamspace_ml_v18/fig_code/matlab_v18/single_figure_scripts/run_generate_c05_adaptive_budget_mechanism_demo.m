%% Generate C05 adaptive search-budget mechanism figure for Chapter 5
% This script reads existing Step11.5 C05 result tables and redraws a
% publication-style mechanism figure. It does not modify manuscript files.

clear; clc; close all;

scriptDir = fileparts(mfilename('fullpath'));
figureCodeRoot = fileparts(scriptDir);
packageRoot = fileparts(fileparts(figureCodeRoot));
stepRoot = fullfile(packageRoot, 'source', 'stepwise_signal_model');
step115Root = fullfile(stepRoot, 'steps', ...
    'step_11_5_likelihood_uncertainty_adaptive_beamspace_ml_search');
resultRoot = fullfile(step115Root, 'results_step11_5_stage2_policy_tuning');
trialCsv = fullfile(resultRoot, 'step11_5_stage2_trial.csv');

localFigureRoot = fullfile(figureCodeRoot, 'outputs', 'figures');
ensure_dir(localFigureRoot);

if exist(trialCsv, 'file') ~= 2
    error('Missing Step11.5 Stage2 trial CSV: %s', trialCsv);
end

opts = detectImportOptions(trialCsv, 'TextType', 'string');
T = readtable(trialCsv, opts);

% C05 selected configuration. Include both zero-bias config_scan samples and
% selected_bias samples so that the mechanism view covers EASY, NORMAL, and
% SCORE_AMBIGUOUS branches observed in the recorded MATLAB runs.
T = T(T.config_id == 5, :);
T = T(strcmp(T.config_name, "C05_easy_very_aggressive"), :);
T = T(strcmp(T.run_phase, "config_scan") | strcmp(T.run_phase, "selected_bias"), :);

if isempty(T)
    error('No C05 selected-config rows were found in %s.', trialCsv);
end

pal = blue_gray_palette();
fontName = get_cn_font();

ambiguousGap = 0.0008;
easyGap = 0.0020;
gapScale = 0.0030;
xMax = max([max(T.gap_13) * 1.05, gapScale * 1.35, easyGap * 1.55]);
xMax = ceil(xMax * 10000) / 10000;

fig = figure('Color', pal.white, 'Units', 'pixels', ...
    'Position', [60, 80, 2100, 980], 'Visible', 'off');
tl = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

axA = nexttile(tl, 1);
plot_policy_feature_panel(axA, T, ambiguousGap, easyGap, gapScale, xMax, pal, fontName);

axB = nexttile(tl, 2);
plot_candidate_ratio_panel(axB, T, ambiguousGap, easyGap, gapScale, xMax, pal, fontName);

outPng = fullfile(localFigureRoot, 'fig_5_c05_adaptive_budget_mechanism_cn.png');
outPdf = fullfile(localFigureRoot, 'fig_5_c05_adaptive_budget_mechanism_cn.pdf');
exportgraphics(fig, outPng, 'Resolution', 300);
exportgraphics(fig, outPdf, 'ContentType', 'vector');
close(fig);

fprintf('Generated C05 adaptive budget mechanism figure:\n');
fprintf('  PNG: %s\n', outPng);
fprintf('  PDF: %s\n', outPdf);
fprintf('Rows: total=%d, config_scan=%d, selected_bias=%d\n', height(T), ...
    sum(strcmp(T.run_phase, "config_scan")), sum(strcmp(T.run_phase, "selected_bias")));
print_policy_summary(T);

function plot_policy_feature_panel(ax, T, ambiguousGap, easyGap, gapScale, xMax, pal, fontName)
hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');
draw_policy_bands(ax, ambiguousGap, easyGap, xMax, pal);

plot_c05_points(ax, T, 'U_search', pal);
draw_gap_thresholds(ax, ambiguousGap, easyGap, gapScale, pal, fontName);

ylim(ax, [0, 0.70]);
xlim(ax, [0, xMax]);
xlabel(ax, '粗搜索评分间隔 gap_{13}', 'FontName', fontName, 'Interpreter', 'tex');
ylabel(ax, '搜索预算不确定度 U_{search}', 'FontName', fontName, 'Interpreter', 'tex');
title(ax, 'A  C05 策略分区与似然地形特征', 'FontName', fontName, 'FontWeight', 'bold');

add_policy_legend(ax, pal, fontName, 'northeast');
style_axis(ax, pal, fontName);
end

function plot_candidate_ratio_panel(ax, T, ambiguousGap, easyGap, gapScale, xMax, pal, fontName)
hold(ax, 'on'); box(ax, 'on'); grid(ax, 'on');
draw_policy_bands(ax, ambiguousGap, easyGap, xMax, pal);

plot_c05_points(ax, T, 'adaptive_vs_fixed_pair_count_ratio', pal);
draw_gap_thresholds(ax, ambiguousGap, easyGap, gapScale, pal, fontName);

hRef = yline(ax, 1.0, '--', 'Color', pal.neutral, 'LineWidth', 1.35, ...
    'DisplayName', 'fixed TopK3 参考');

ylim(ax, [0.45, 1.25]);
xlim(ax, [0, xMax]);
xlabel(ax, '粗搜索评分间隔 gap_{13}', 'FontName', fontName, 'Interpreter', 'tex');
ylabel(ax, 'adaptive/fixed 候选数比例', 'FontName', fontName);
title(ax, 'B  预算响应对应的候选数变化', 'FontName', fontName, 'FontWeight', 'bold');

add_ratio_legend(ax, pal, fontName, hRef);
style_axis(ax, pal, fontName);
end

function draw_policy_bands(ax, ambiguousGap, easyGap, xMax, pal)
yl = [-10, 10];
patch(ax, [0, ambiguousGap, ambiguousGap, 0], [yl(1), yl(1), yl(2), yl(2)], ...
    pal.very_pale, 'FaceAlpha', 0.55, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax, [ambiguousGap, easyGap, easyGap, ambiguousGap], [yl(1), yl(1), yl(2), yl(2)], ...
    pal.band_mid, 'FaceAlpha', 0.42, 'EdgeColor', 'none', 'HandleVisibility', 'off');
patch(ax, [easyGap, xMax, xMax, easyGap], [yl(1), yl(1), yl(2), yl(2)], ...
    pal.band_easy, 'FaceAlpha', 0.34, 'EdgeColor', 'none', 'HandleVisibility', 'off');
end

function draw_gap_thresholds(ax, ambiguousGap, easyGap, gapScale, pal, fontName)
xline(ax, ambiguousGap, '-', 'Color', pal.secondary, 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(ax, easyGap, '-', 'Color', pal.primary, 'LineWidth', 1.1, 'HandleVisibility', 'off');
xline(ax, gapScale, ':', 'Color', pal.neutral, 'LineWidth', 1.15, 'HandleVisibility', 'off');

yl = ylim(ax);
text(ax, ambiguousGap * 1.02, yl(1) + 0.055 * diff(yl), '0.0008', ...
    'Rotation', 90, 'FontName', fontName, 'FontSize', 8.5, 'Color', pal.secondary);
text(ax, easyGap * 1.02, yl(1) + 0.055 * diff(yl), '0.002', ...
    'Rotation', 90, 'FontName', fontName, 'FontSize', 8.5, 'Color', pal.primary);
text(ax, gapScale * 1.02, yl(1) + 0.055 * diff(yl), 'gap\_scale=0.003', ...
    'Rotation', 90, 'FontName', fontName, 'FontSize', 8.5, ...
    'Color', pal.neutral, 'Interpreter', 'tex');
end

function plot_c05_points(ax, T, yField, pal)
policies = ["SCORE_AMBIGUOUS", "NORMAL", "EASY"];
rng(20260630);
for iPolicy = 1:numel(policies)
    policy = policies(iPolicy);
    color = policy_color(policy, pal);
    mask = strcmp(T.adaptive_policy_name, policy);
    if ~any(mask)
        continue;
    end
    xJitter = (rand(sum(mask), 1) - 0.5) * 0.000035;
    scatter(ax, T.gap_13(mask) + xJitter, T.(yField)(mask), 66, 'o', ...
        'MarkerFaceColor', color, 'MarkerEdgeColor', pal.white, ...
        'MarkerFaceAlpha', 0.66, 'MarkerEdgeAlpha', 0.86, ...
        'LineWidth', 0.62, 'HandleVisibility', 'off');
end
end

function add_policy_legend(ax, pal, fontName, locationText)
hold(ax, 'on');
h1 = plot(ax, NaN, NaN, 'o', 'MarkerSize', 18, ...
    'MarkerFaceColor', pal.secondary, 'MarkerEdgeColor', pal.text, ...
    'LineWidth', 1.05, 'DisplayName', 'SCORE\_AMBIGUOUS');
h2 = plot(ax, NaN, NaN, 'o', 'MarkerSize', 18, ...
    'MarkerFaceColor', pal.neutral, 'MarkerEdgeColor', pal.text, ...
    'LineWidth', 1.05, 'DisplayName', 'NORMAL');
h3 = plot(ax, NaN, NaN, 'o', 'MarkerSize', 18, ...
    'MarkerFaceColor', pal.primary, 'MarkerEdgeColor', pal.text, ...
    'LineWidth', 1.05, 'DisplayName', 'EASY');
lgd = legend(ax, [h1, h2, h3], 'Location', locationText);
set(lgd, 'FontName', fontName, 'FontSize', 14, 'Box', 'off', ...
    'Color', pal.white, 'Interpreter', 'tex');
end

function add_ratio_legend(ax, pal, fontName, hRef)
hold(ax, 'on');
h1 = plot(ax, NaN, NaN, 'o', 'MarkerSize', 18, ...
    'MarkerFaceColor', pal.secondary, 'MarkerEdgeColor', pal.text, ...
    'LineWidth', 1.05, 'DisplayName', 'SCORE\_AMBIGUOUS');
h2 = plot(ax, NaN, NaN, 'o', 'MarkerSize', 18, ...
    'MarkerFaceColor', pal.neutral, 'MarkerEdgeColor', pal.text, ...
    'LineWidth', 1.05, 'DisplayName', 'NORMAL');
h3 = plot(ax, NaN, NaN, 'o', 'MarkerSize', 18, ...
    'MarkerFaceColor', pal.primary, 'MarkerEdgeColor', pal.text, ...
    'LineWidth', 1.05, 'DisplayName', 'EASY');
lgd = legend(ax, [h1, h2, h3, hRef], 'Location', 'northeast');
set(lgd, 'FontName', fontName, 'FontSize', 14, 'Box', 'off', ...
    'Color', pal.white, 'Interpreter', 'tex');
end

function color = policy_color(policy, pal)
switch char(policy)
    case 'EASY'
        color = pal.primary;
    case 'NORMAL'
        color = pal.neutral;
    case 'SCORE_AMBIGUOUS'
        color = pal.secondary;
    otherwise
        color = pal.tertiary;
end
end

function print_policy_summary(T)
policies = ["EASY", "NORMAL", "SCORE_AMBIGUOUS", "BOUNDARY", "ILL_CONDITIONED"];
for iPolicy = 1:numel(policies)
    mask = strcmp(T.adaptive_policy_name, policies(iPolicy));
    if ~any(mask)
        fprintf('  %-17s n=%d\n', policies(iPolicy), 0);
        continue;
    end
    fprintf('  %-17s n=%d, mean ratio=%.4f, gap range=[%.6g, %.6g]\n', ...
        policies(iPolicy), sum(mask), ...
        mean(T.adaptive_vs_fixed_pair_count_ratio(mask), 'omitnan'), ...
        min(T.gap_13(mask)), max(T.gap_13(mask)));
end
end

function style_axis(ax, pal, fontName)
set(ax, 'FontName', fontName, 'FontSize', 11.2, 'LineWidth', 0.95, ...
    'XColor', pal.text, 'YColor', pal.text, ...
    'GridColor', pal.grid, 'MinorGridColor', pal.grid);
ax.GridAlpha = 0.52;
ax.Layer = 'top';
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
pal.band_mid = hex2rgb_local('#EEF4F8');
pal.band_easy = hex2rgb_local('#E3EEF5');
pal.neutral = hex2rgb_local('#5A6772');
pal.grid = hex2rgb_local('#D8DEE6');
pal.text = hex2rgb_local('#111111');
pal.white = [1 1 1];
end

function rgb = hex2rgb_local(hexText)
hexText = char(hexText);
if startsWith(hexText, '#')
    hexText = hexText(2:end);
end
rgb = [hex2dec(hexText(1:2)), hex2dec(hexText(3:4)), hex2dec(hexText(5:6))] / 255;
end
