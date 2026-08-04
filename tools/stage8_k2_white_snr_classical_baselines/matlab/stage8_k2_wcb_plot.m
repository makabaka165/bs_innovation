function paths = stage8_k2_wcb_plot( ...
    data, summary, music, element, figure_dir, ~)
%STAGE8_K2_WCB_PLOT Generate the six registered comparison figures.

if ~isfolder(figure_dir) && ~mkdir(figure_dir)
    error('stage8_k2_wcb_plot:Directory', ...
        'Unable to create the registered figure directory.');
end
paths = [ ...
    string(fullfile(figure_dir, '46_white_snr_tangent_full4d_rmse.png')); ...
    string(fullfile(figure_dir, '46_white_snr_tangent_full4d_pairwise.png')); ...
    string(fullfile(figure_dir, '46_white_snr_full4d_numerical_status.png')); ...
    string(fullfile(figure_dir, '46_white_snr_music_two_peak_rate.png')); ...
    string(fullfile(figure_dir, '46_white_snr_element_reference.png')); ...
    string(fullfile(figure_dir, '46_white_snr_complexity.png'))];

full = sortrows(summary(summary.method_id == ...
    "FULL4D_BEAMSPACE_CML_MULTISTART", :), 'white_snr_db');
tangent = sortrows(summary(summary.method_id == ...
    "TANGENT_PROFILE_SAFE", :), 'white_snr_db');
snr = full.white_snr_db;

fig = new_figure_local();
plot(snr, tangent.median_joint_RMSE_deg, '-o', ...
    'Color', [0.08 0.38 0.55], 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(snr, full.median_joint_RMSE_deg, '-s', ...
    'Color', [0.72 0.24 0.18], 'LineWidth', 2, 'MarkerSize', 6);
plot(snr, tangent.p90_joint_RMSE_deg, '--o', ...
    'Color', [0.08 0.38 0.55], 'LineWidth', 1.4, 'MarkerSize', 5);
plot(snr, full.p90_joint_RMSE_deg, '--s', ...
    'Color', [0.72 0.24 0.18], 'LineWidth', 1.4, 'MarkerSize', 5);
grid on; xlabel('Expected whitened beamspace SNR (dB)');
ylabel('Joint endpoint RMSE (deg)');
title({'Tangent vs Full4D Beamspace CML', ...
    'Full4D is a finite-budget numerical CML baseline'});
legend({'Tangent median','Full4D median','Tangent P90','Full4D P90'}, ...
    'Location', 'northeast');
export_local(fig, paths(1));

fig = new_figure_local();
values = [full.tangent_wins, full.ties, full.tangent_losses];
bar(snr, values, 'stacked');
colororder([0.12 0.50 0.36; 0.55 0.57 0.60; 0.76 0.28 0.20]);
grid on; xlabel('Expected whitened beamspace SNR (dB)');
ylabel('Paired valid trial count');
title({'Paired Tangent vs Full4D outcomes', ...
    'Tie tolerance = 1e-6 deg'});
legend({'Tangent win','Tie','Tangent loss'}, 'Location', 'northwest');
export_local(fig, paths(2));

fig = new_figure_local();
complete = full.fit_valid_count - full.numerical_incomplete_count;
invalid = full.total_count - full.fit_valid_count;
bar(snr, [complete, full.numerical_incomplete_count, invalid], 'stacked');
colororder([0.12 0.50 0.36; 0.90 0.61 0.17; 0.55 0.57 0.60]);
grid on; xlabel('Expected whitened beamspace SNR (dB)');
ylabel('Trial count');
title({'Full4D Beamspace numerical status', ...
    'Incomplete rows remain finite-budget outputs'});
legend({'Complete likelihood','Optimization incomplete','Invalid'}, ...
    'Location', 'best');
export_local(fig, paths(3));

fig = new_figure_local();
valid_rate = music.valid_k2_output_count ./ music.applicable_count;
single_rate = music.single_peak_count ./ music.applicable_count;
rank_rate = music.sample_rank_valid_count ./ music.applicable_count;
plot(music.white_snr_db, valid_rate, '-o', ...
    'Color', [0.12 0.50 0.36], 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(music.white_snr_db, single_rate, '-s', ...
    'Color', [0.76 0.28 0.20], 'LineWidth', 2, 'MarkerSize', 6);
plot(music.white_snr_db, rank_rate, '--^', ...
    'Color', [0.35 0.38 0.43], 'LineWidth', 1.5, 'MarkerSize', 6);
yline(0.5, ':', 'Identified threshold', 'LineWidth', 1.2);
ylim([0 1.05]); grid on;
xlabel('Expected whitened beamspace SNR (dB)'); ylabel('Applicable-trial rate');
title({'Beamspace MUSIC two-peak applicability', ...
    'N/A and single peak are not Tangent wins'});
legend({'Valid two-peak K2','Single peak','Sample rank >= 2'}, ...
    'Location', 'best');
export_local(fig, paths(4));

fig = new_figure_local();
methods = ["TANGENT_PROFILE_SAFE"; ...
    "FULL4D_BEAMSPACE_CML_MULTISTART"; ...
    "FULL4D_ELEMENT_CML_MULTISTART"];
labels = {'Tangent','Beamspace Full4D','Element Full4D'};
colors = [0.08 0.38 0.55; 0.72 0.24 0.18; 0.28 0.48 0.22];
hold on;
for index = 1:numel(methods)
    rows = element(element.scope_type == "SNR" & ...
        element.method_id == methods(index), :);
    x = str2double(rows.scope_value);
    [x, order] = sort(x);
    plot(x, rows.median_joint_RMSE_deg(order), '-o', ...
        'Color', colors(index, :), 'LineWidth', 2, 'MarkerSize', 6);
end
grid on; xlabel('Expected whitened beamspace SNR (dB)');
ylabel('Median joint endpoint RMSE (deg)');
title({'Preregistered 160-trial Element reference', ...
    'Element CML is more informative and not the same hardware interface'});
legend(labels, 'Location', 'best');
export_local(fig, paths(5));

fig = new_figure_local();
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
runtime_values = nan(numel(methods) + 1, 1);
call_values = nan(numel(methods) + 1, 1);
complexity_methods = [methods; "BEAMSPACE_MUSIC_K2"];
complexity_labels = {'Tangent','Beam Full4D','Element Full4D','Beam MUSIC'};
for index = 1:numel(complexity_methods)
    rows = data(data.method_id == complexity_methods(index) & ...
        data.applicable, :);
    runtime_values(index) = finite_median_local(rows.runtime_sec);
    call_values(index) = finite_median_local(rows.score_call_count + ...
        rows.SVD_call_count + rows.eig_call_count);
end
nexttile;
bar(runtime_values, 'FaceColor', [0.22 0.48 0.60]);
set(gca, 'YScale', 'log', 'XTick', 1:numel(complexity_labels), ...
    'XTickLabel', complexity_labels, 'XTickLabelRotation', 25);
ylabel('Median runtime (s, log scale)'); grid on;
nexttile;
bar(call_values, 'FaceColor', [0.72 0.40 0.18]);
set(gca, 'YScale', 'log', 'XTick', 1:numel(complexity_labels), ...
    'XTickLabel', complexity_labels, 'XTickLabelRotation', 25);
ylabel('Median registered calls (log scale)'); grid on;
sgtitle({'Registered computational cost', ...
    'MUSIC includes amortized fixed-dictionary precompute'});
export_local(fig, paths(6));

if ~all(arrayfun(@isfile, paths))
    error('stage8_k2_wcb_plot:Artifact', ...
        'One or more registered figures were not created.');
end
end

function fig = new_figure_local()
fig = figure('Visible', 'off', 'Color', 'white', ...
    'Position', [100, 100, 1100, 650]);
end

function export_local(fig, path_now)
exportgraphics(fig, path_now, 'Resolution', 160);
close(fig);
end

function value = finite_median_local(values)
values = double(values(isfinite(values)));
if isempty(values)
    value = NaN;
else
    value = median(values);
end
end
